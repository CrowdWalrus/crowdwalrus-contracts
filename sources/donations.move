module crowd_walrus::donations;

use crowd_walrus::campaign::{Self as campaign};
use crowd_walrus::token_registry::{Self as token_registry};
use std::u64;
use sui::clock::{Self as clock, Clock};
use sui::coin::{Self as coin, Coin};

const E_CAMPAIGN_INACTIVE: u64 = 1;
const E_CAMPAIGN_CLOSED: u64 = 2;
const E_TOKEN_DISABLED: u64 = 3;
const E_ZERO_DONATION: u64 = 4;

const BPS_DENOMINATOR: u64 = 10_000;

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
        transfer::public_transfer(donation, recipient_address);
        return (0, recipient_amount)
    };

    if (platform_amount == total) {
        transfer::public_transfer(donation, platform_address);
        return (platform_amount, 0)
    };

    let mut remaining = donation;
    let platform_coin = coin::split(&mut remaining, platform_amount, ctx);
    transfer::public_transfer(platform_coin, platform_address);
    transfer::public_transfer(remaining, recipient_address);
    (platform_amount, recipient_amount)
}
