module crowd_walrus::donations;

use crowd_walrus::badge_rewards;
use crowd_walrus::campaign::{Self as campaign};
use crowd_walrus::campaign_stats::{Self as campaign_stats};
use crowd_walrus::price_oracle;
use crowd_walrus::token_registry::{Self as token_registry};
use crowd_walrus::profiles::{Self as profiles};
use std::string::String;
use std::u64;
use sui::clock::{Self as clock, Clock};
use sui::coin::{Self as coin, Coin};
use sui::event;

const E_CAMPAIGN_INACTIVE: u64 = 1;
const E_CAMPAIGN_CLOSED: u64 = 2;
const E_TOKEN_DISABLED: u64 = 3;
const E_ZERO_DONATION: u64 = 4;
const E_COIN_NOT_FOUND: u64 = 5;
const E_INVALID_SPLIT: u64 = 6;
const E_SLIPPAGE_EXCEEDED: u64 = 7;
const E_STATS_MISMATCH: u64 = 8;

const BPS_DENOMINATOR: u64 = 10_000;

/// Canonical donation event emitted once per successful donation to power indexers and feeds.
public struct DonationReceived has copy, drop {
    campaign_id: sui::object::ID,
    donor: address,
    coin_type_canonical: String,
    coin_symbol: String,
    amount_raw: u64,
    amount_usd_micro: u64,
    platform_amount_raw: u64,
    recipient_amount_raw: u64,
    platform_amount_usd_micro: u64,
    recipient_amount_usd_micro: u64,
    platform_bps: u16,
    platform_address: address,
    recipient_address: address,
    timestamp_ms: u64,
}

/// Return payload for donation flows that handle badge minting.
public struct DonationAwardOutcome has copy, drop {
    usd_micro: u64,
    minted_levels: vector<u8>,
}

/// Returns the USD micro value recorded for the donation.
public fun outcome_usd_micro(outcome: &DonationAwardOutcome): u64 {
    outcome.usd_micro
}

/// Returns the badge levels minted during the donation, if any.
public fun outcome_minted_levels(outcome: &DonationAwardOutcome): &vector<u8> {
    &outcome.minted_levels
}

/// Helper returning all event fields for package-internal consumers and tests.
public(package) fun unpack_donation_received(
    event: &DonationReceived,
): (
    sui::object::ID,
    address,
    String,
    String,
    u64,
    u64,
    u64,
    u64,
    u64,
    u64,
    u16,
    address,
    address,
    u64,
) {
    (
        event.campaign_id,
        event.donor,
        copy event.coin_type_canonical,
        copy event.coin_symbol,
        event.amount_raw,
        event.amount_usd_micro,
        event.platform_amount_raw,
        event.recipient_amount_raw,
        event.platform_amount_usd_micro,
        event.recipient_amount_usd_micro,
        event.platform_bps,
        event.platform_address,
        event.recipient_address,
        event.timestamp_ms,
    )
}

/// Early validation ensuring campaign status, timing, and token availability before processing a donation.
public fun precheck<T>(
    campaign: &campaign::Campaign,
    registry: &token_registry::TokenRegistry,
    clock: &Clock,
) {
    campaign::assert_not_deleted(campaign);
    assert!(campaign::is_active(campaign), E_CAMPAIGN_INACTIVE);

    let now = clock::timestamp_ms(clock);
    let start = campaign::start_date(campaign);
    let end = campaign::end_date(campaign);
    assert!(now >= start, E_CAMPAIGN_CLOSED);
    assert!(now <= end, E_CAMPAIGN_CLOSED);

    assert!(token_registry::contains<T>(registry), E_TOKEN_DISABLED);
    assert!(token_registry::is_enabled<T>(registry), E_TOKEN_DISABLED);
}

/// Returns the effective staleness budget for a donation, honoring donor overrides when tighter than
/// the registry default. Tokens must exist and be enabled before we quote prices.
public fun effective_max_age_ms<T>(
    registry: &token_registry::TokenRegistry,
    override_ms: std::option::Option<u64>,
): u64 {
    token_registry::require_enabled<T>(registry);
    let registry_max = token_registry::max_age_ms<T>(registry);

    if (!std::option::is_some(&override_ms)) {
        registry_max
    } else {
        let override_value = std::option::destroy_some(override_ms);
        if (override_value == 0) {
            registry_max
        } else {
            u64::min(registry_max, override_value)
        }
    }
}

/// Splits a donation according to the campaign payout policy, routes funds directly to the
/// platform and recipient addresses, and returns the raw amounts sent to each party.
public fun split_and_transfer<T>(
    campaign: &campaign::Campaign,
    donation: Coin<T>,
    ctx: &mut sui::tx_context::TxContext,
): (u64, u64) {
    let total = coin::value(&donation);
    assert!(total > 0, E_ZERO_DONATION);

    let platform_bps = campaign::payout_platform_bps(campaign);
    let platform_amount =
        (((total as u128) * (platform_bps as u128)) / (BPS_DENOMINATOR as u128)) as u64;
    let recipient_amount = total - platform_amount;

    let platform_address = campaign::payout_platform_address(campaign);
    let recipient_address = campaign::payout_recipient_address(campaign);

    if (platform_amount == 0) {
        sui::transfer::public_transfer(donation, recipient_address);
        return (0, recipient_amount)
    };

    if (platform_amount == total) {
        sui::transfer::public_transfer(donation, platform_address);
        return (platform_amount, 0)
    };

    let mut remaining = donation;
    let platform_coin = coin::split(&mut remaining, platform_amount, ctx);
    sui::transfer::public_transfer(platform_coin, platform_address);
    sui::transfer::public_transfer(remaining, recipient_address);
    (platform_amount, recipient_amount)
}

/// Quotes the USD value of a donation using registry metadata and a verified PriceInfoObject.
public fun quote_usd_micro<T>(
    registry: &token_registry::TokenRegistry,
    clock: &Clock,
    amount_raw: u64,
    price_info_object: &pyth::price_info::PriceInfoObject,
    override_ms: std::option::Option<u64>,
): u64 {
    assert!(token_registry::contains<T>(registry), E_COIN_NOT_FOUND);
    assert!(token_registry::is_enabled<T>(registry), E_TOKEN_DISABLED);

    let decimals = token_registry::decimals<T>(registry);
    let feed_id = token_registry::pyth_feed_id<T>(registry);
    let max_age = effective_max_age_ms<T>(registry, override_ms);

    price_oracle::quote_usd<T>(
        (amount_raw as u128),
        decimals,
        feed_id,
        price_info_object,
        clock,
        max_age,
    )
}

/// Emits the DonationReceived event with canonical coin metadata and payout routing details.
public(package) fun emit_donation_received_event<T>(
    campaign: &campaign::Campaign,
    registry: &token_registry::TokenRegistry,
    donor: address,
    amount_raw: u64,
    amount_usd_micro: u64,
    platform_amount_raw: u64,
    recipient_amount_raw: u64,
    platform_amount_usd_micro: u64,
    recipient_amount_usd_micro: u64,
    clock: &Clock,
) {
    // Caller must forward the exact split outputs (raw + USD) so the event mirrors what was transferred on-chain.
    token_registry::require_enabled<T>(registry);
    assert!(
        amount_raw == platform_amount_raw + recipient_amount_raw,
        E_INVALID_SPLIT
    );
    assert!(
        amount_usd_micro == platform_amount_usd_micro + recipient_amount_usd_micro,
        E_INVALID_SPLIT
    );
    let timestamp_ms = clock::timestamp_ms(clock);
    event::emit(DonationReceived {
        campaign_id: sui::object::id(campaign),
        donor,
        coin_type_canonical: token_registry::coin_type_canonical<T>(),
        coin_symbol: token_registry::symbol<T>(registry),
        amount_raw,
        amount_usd_micro,
        platform_amount_raw,
        recipient_amount_raw,
        platform_amount_usd_micro,
        recipient_amount_usd_micro,
        platform_bps: campaign::payout_platform_bps(campaign),
        platform_address: campaign::payout_platform_address(campaign),
        recipient_address: campaign::payout_recipient_address(campaign),
        timestamp_ms,
    });
}

public(package) fun donate<T>(
    campaign: &mut campaign::Campaign,
    stats: &mut campaign_stats::CampaignStats,
    registry: &token_registry::TokenRegistry,
    clock: &Clock,
    donation: Coin<T>,
    price_info_object: &pyth::price_info::PriceInfoObject,
    expected_min_usd_micro: u64,
    opt_max_age_ms: std::option::Option<u64>,
    ctx: &mut sui::tx_context::TxContext,
): u64 {
    precheck<T>(campaign, registry, clock);

    assert!(
        campaign_stats::id(stats) == campaign::stats_id(campaign),
        E_STATS_MISMATCH,
    );

    let donor = sui::tx_context::sender(ctx);
    let raw_amount = coin::value(&donation);
    let amount_usd_micro = quote_usd_micro<T>(
        registry,
        clock,
        raw_amount,
        price_info_object,
        opt_max_age_ms,
    );
    assert!(amount_usd_micro >= expected_min_usd_micro, E_SLIPPAGE_EXCEEDED);

    let platform_bps = campaign::payout_platform_bps(campaign);
    let platform_amount_usd_micro =
        (((amount_usd_micro as u128) * (platform_bps as u128)) / (BPS_DENOMINATOR as u128)) as u64;
    let recipient_amount_usd_micro = amount_usd_micro - platform_amount_usd_micro;

    let (platform_amount_raw, recipient_amount_raw) =
        split_and_transfer<T>(campaign, donation, ctx);

    campaign_stats::add_donation<T>(stats, raw_amount as u128, amount_usd_micro);

    campaign::lock_parameters_if_unlocked(campaign, clock);

    emit_donation_received_event<T>(
        campaign,
        registry,
        donor,
        raw_amount,
        amount_usd_micro,
        platform_amount_raw,
        recipient_amount_raw,
        platform_amount_usd_micro,
        recipient_amount_usd_micro,
        clock,
    );

    amount_usd_micro
}

/// Processes a first-time donation by creating the donor's profile, executing the donation,
/// updating profile totals, minting any newly earned badges, and transferring the profile to
/// the sender. Aborts if the sender already has an existing profile registered.
///
/// # Flow
/// 1. Assert the sender has no profile (aborts with `profiles::profile_exists_error_code()`).
/// 2. Create and register a new profile for the sender via `profiles::create_for`.
/// 3. Call `donate<T>` to run all standard donation checks, USD valuation, splitting, and stats updates.
/// 4. Increment the newly created profile's totals with the USD value from the donation.
/// 5. Invoke `badge_rewards::maybe_award_badges` to mint any badge levels newly satisfied.
/// 6. Transfer the profile to the sender so they leave the PTB owning their profile object.
///
/// # Events Emitted
/// - `profiles::ProfileCreated` (once, when the profile is minted).
/// - `donations::DonationReceived` (once, via `donate<T>`).
/// - `badge_rewards::BadgeMinted` (zero or more per badge level awarded).
/// - `campaign::CampaignParametersLocked` (once if this is the first donation for the campaign).
///
/// # Returns
/// A `DonationAwardOutcome` containing:
/// - `usd_micro`: The floor-rounded USD micro-value of the donation.
/// - `minted_levels`: A vector of badge levels minted during this call (may be empty).
///
/// # Aborts
/// - `profiles::profile_exists_error_code()`: Sender already has a profile (use `donate_and_award` instead).
/// - All other abort paths surfaced by `donate<T>` (time window, token disabled, slippage, stale price, etc.).
public fun donate_and_award_first_time<T>(
    campaign: &mut campaign::Campaign,
    stats: &mut campaign_stats::CampaignStats,
    registry: &token_registry::TokenRegistry,
    badge_config: &badge_rewards::BadgeConfig,
    profiles_registry: &mut profiles::ProfilesRegistry,
    clock: &Clock,
    donation: Coin<T>,
    price_info_object: &pyth::price_info::PriceInfoObject,
    expected_min_usd_micro: u64,
    opt_max_age_ms: std::option::Option<u64>,
    ctx: &mut sui::tx_context::TxContext,
): DonationAwardOutcome {
    let sender = sui::tx_context::sender(ctx);
    assert!(
        !profiles::exists(profiles_registry, sender),
        profiles::profile_exists_error_code(),
    );

    let mut profile = profiles::create_for(profiles_registry, sender, clock, ctx);
    let old_amount = profiles::total_usd_micro(&profile);
    let old_count = profiles::total_donations_count(&profile);

    let usd_micro = donate<T>(
        campaign,
        stats,
        registry,
        clock,
        donation,
        price_info_object,
        expected_min_usd_micro,
        opt_max_age_ms,
        ctx,
    );

    profiles::add_contribution(&mut profile, usd_micro);

    let new_amount = profiles::total_usd_micro(&profile);
    let new_count = profiles::total_donations_count(&profile);

    let minted_levels = badge_rewards::maybe_award_badges(
        &mut profile,
        badge_config,
        old_amount,
        old_count,
        new_amount,
        new_count,
        clock,
        ctx,
    );

    profiles::transfer_to(profile, sender);

    DonationAwardOutcome {
        usd_micro,
        minted_levels,
    }
}

/// Processes a repeat donation for an existing profile holder. Requires callers to pass their
/// owned Profile by mutable reference so we can update cumulative contribution totals and evaluate
/// badge thresholds without another registry lookup.
///
/// # Flow
/// 1. Verify the sender owns the provided Profile (aborts with `profiles::E_NOT_PROFILE_OWNER` if not).
/// 2. Capture the profile's pre-donation USD total and donation count.
/// 3. Call `donate<T>` to perform all standard donation processing (prechecks, valuation, split, stats).
/// 4. Increment the profile's totals with the donation's USD value.
/// 5. Invoke `badge_rewards::maybe_award_badges` so newly satisfied badge levels are minted.
/// 6. Return the donation outcome, including the USD value and any minted badge levels.
///
/// # Events Emitted
/// - `donations::DonationReceived` (once, via `donate<T>`).
/// - `badge_rewards::BadgeMinted` (zero or more per new badge level).
/// - `campaign::CampaignParametersLocked` (once if this is the campaign's first donation).
///
/// # Returns
/// A `DonationAwardOutcome` containing:
/// - `usd_micro`: Floor-rounded USD micro-value of the donation.
/// - `minted_levels`: Vector of badge levels minted during this call (may be empty).
///
/// # Aborts
/// - `profiles::E_NOT_PROFILE_OWNER`: Sender does not own the provided profile.
/// - Any abort surfaced by `donate<T>` (campaign inactive/closed, token disabled, slippage, stale price, etc.).
public fun donate_and_award<T>(
    campaign: &mut campaign::Campaign,
    stats: &mut campaign_stats::CampaignStats,
    registry: &token_registry::TokenRegistry,
    badge_config: &badge_rewards::BadgeConfig,
    clock: &Clock,
    profile: &mut profiles::Profile,
    donation: Coin<T>,
    price_info_object: &pyth::price_info::PriceInfoObject,
    expected_min_usd_micro: u64,
    opt_max_age_ms: std::option::Option<u64>,
    ctx: &mut sui::tx_context::TxContext,
): DonationAwardOutcome {
    let sender = sui::tx_context::sender(ctx);
    assert!(
        profiles::owner(profile) == sender,
        profiles::not_profile_owner_error_code(),
    );

    let old_amount = profiles::total_usd_micro(profile);
    let old_count = profiles::total_donations_count(profile);

    let usd_micro = donate<T>(
        campaign,
        stats,
        registry,
        clock,
        donation,
        price_info_object,
        expected_min_usd_micro,
        opt_max_age_ms,
        ctx,
    );

    profiles::add_contribution(profile, usd_micro);

    let new_amount = profiles::total_usd_micro(profile);
    let new_count = profiles::total_donations_count(profile);

    let minted_levels = badge_rewards::maybe_award_badges(
        profile,
        badge_config,
        old_amount,
        old_count,
        new_amount,
        new_count,
        clock,
        ctx,
    );

    DonationAwardOutcome {
        usd_micro,
        minted_levels,
    }
}
