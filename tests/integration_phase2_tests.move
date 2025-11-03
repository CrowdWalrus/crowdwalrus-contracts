/// Integration scenarios for Phase 2 task K2 (see docs/phase2/PHASE_2_TASKS.md).
/// Each test maps to a numbered acceptance case in K2.
#[test_only]
module crowd_walrus::integration_phase2_tests;

use crowd_walrus::badge_rewards::{Self as badge_rewards};
use crowd_walrus::campaign::{Self as campaign};
use crowd_walrus::campaign_stats::{Self as campaign_stats};
use crowd_walrus::crowd_walrus::{Self as crowd_walrus};
use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::donations;
use crowd_walrus::donations_tests;
use crowd_walrus::profiles::{Self as profiles};
use crowd_walrus::token_registry::{Self as token_registry};
use std::string::{Self as string};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::coin::{Self as coin};
use sui::event;
use sui::object::{Self as sui_object};
use sui::test_scenario::{Self as ts};

const ADMIN: address = @0xA;
const CAMPAIGN_OWNER: address = @0xB;
const DONOR_ONE: address = @0xD;
const DONOR_TWO: address = @0xE;
const BPS_DENOMINATOR: u128 = 10_000;

public struct AltTestCoin has drop, store {}

fun clone_bytes(bytes: &vector<u8>): vector<u8> {
    let mut out = vector::empty<u8>();
    let mut i = 0;
    while (i < vector::length(bytes)) {
        vector::push_back(&mut out, *vector::borrow(bytes, i));
        i = i + 1;
    };
    out
}

fun register_alt_test_coin(
    scenario: &mut ts::Scenario,
    feed_id: &vector<u8>,
    clock_obj: &Clock,
    decimals: u8,
    max_age_ms: u64,
) {
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    crowd_walrus::add_token_internal<AltTestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"ALT"),
        string::utf8(b"Alternate Coin"),
        decimals,
        clone_bytes(feed_id),
        max_age_ms,
        clock_obj,
    );
    crowd_walrus::set_token_enabled_internal<AltTestCoin>(
        &mut registry,
        &admin_cap,
        true,
        clock_obj,
    );
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
}

// K2 scenario coverage:
// 1. Profile creation path (+ duplicate).
// 2. Profile metadata update permissions.
// 3. Campaign creation without existing profile (auto-create).
// 4. Campaign creation with existing profile.
// 5. First donation flow (profile auto-creation, stats, lock, badge).
// 6. Repeat donation flow (badge progression).
// 7. DonationReceived field validation (including canonical type & symbol).
// 8. Multi-token stats separation.
// 9. Parallel first donations (single lock event).
// 10. Slippage guard (success + failure).

#[test]
fun test_standalone_profile_creation_emits_event() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    let events_before =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());

    scenario.next_tx(DONOR_ONE);
    let clock_obj = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    assert!(!profiles::exists(&registry, DONOR_ONE));

    profiles::create_profile(&mut registry, &clock_obj, ts::ctx(&mut scenario));

    let events_after =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());
    assert_eq!(events_after, events_before + 1);

    ts::return_shared(registry);
    ts::return_shared(clock_obj);

    let effects = ts::next_tx(&mut scenario, DONOR_ONE);
    assert_eq!(ts::num_user_events(&effects), 1);

    scenario.next_tx(DONOR_ONE);
    let registry_after = scenario.take_shared<profiles::ProfilesRegistry>();
    assert!(profiles::exists(&registry_after, DONOR_ONE));
    let profile_id = profiles::id_of(&registry_after, DONOR_ONE);
    ts::return_shared(registry_after);

    scenario.next_tx(DONOR_ONE);
    let profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR_ONE);
    assert_eq!(profiles::owner(&profile), DONOR_ONE);
    assert_eq!(sui_object::id(&profile), profile_id);
    assert_eq!(profiles::total_usd_micro(&profile), 0);
    assert_eq!(profiles::total_donations_count(&profile), 0);
    ts::return_to_address(DONOR_ONE, profile);

    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_PROFILE_EXISTS, location = 0x0::profiles)]
fun test_standalone_profile_creation_duplicate_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(DONOR_ONE);
    let clock_obj = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_obj, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_obj);
    let _ = ts::next_tx(&mut scenario, DONOR_ONE);

    scenario.next_tx(DONOR_ONE);
    let clock_again = scenario.take_shared<Clock>();
    let mut registry_again = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry_again, &clock_again, ts::ctx(&mut scenario));
    ts::return_shared(registry_again);
    ts::return_shared(clock_again);
    let _ = ts::next_tx(&mut scenario, DONOR_ONE);

    ts::end(scenario);
}

#[test]
fun test_profile_metadata_update_emits_event() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(DONOR_ONE);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, DONOR_ONE);

    let metadata_events_before =
        vector::length(&event::events_by_type<profiles::ProfileMetadataUpdated>());

    scenario.next_tx(DONOR_ONE);
    let clock_update = scenario.take_shared<Clock>();
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR_ONE);
    profiles::update_profile_metadata(
        &mut profile,
        string::utf8(b"display_name"),
        string::utf8(b"Captain Walrus"),
        &clock_update,
        ts::ctx(&mut scenario),
    );
    ts::return_to_address(DONOR_ONE, profile);
    ts::return_shared(clock_update);

    let metadata_events_after =
        vector::length(&event::events_by_type<profiles::ProfileMetadataUpdated>());
    assert_eq!(metadata_events_after, metadata_events_before + 1);

    scenario.next_tx(DONOR_ONE);
    let profile_after = ts::take_from_address<profiles::Profile>(&scenario, DONOR_ONE);
    let metadata_view = profiles::metadata(&profile_after);
    assert_eq!(metadata_view.length(), 1);
    assert_eq!(
        *metadata_view.get(&string::utf8(b"display_name")),
        string::utf8(b"Captain Walrus"),
    );
    ts::return_to_address(DONOR_ONE, profile_after);

    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_NOT_PROFILE_OWNER, location = 0x0::profiles)]
fun test_profile_metadata_update_non_owner_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(DONOR_ONE);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, DONOR_ONE);

    scenario.next_tx(DONOR_TWO);
    let clock_update = scenario.take_shared<Clock>();
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR_ONE);
    profiles::update_profile_metadata(
        &mut profile,
        string::utf8(b"bio"),
        string::utf8(b"Unauthorized edit"),
        &clock_update,
        ts::ctx(&mut scenario),
    );
    ts::return_to_address(DONOR_ONE, profile);
    ts::return_shared(clock_update);

    ts::end(scenario);
}

#[test]
fun test_create_campaign_preset_auto_profile_and_stats() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(CAMPAIGN_OWNER);
    let registry_check = scenario.take_shared<profiles::ProfilesRegistry>();
    assert!(!profiles::exists(&registry_check, CAMPAIGN_OWNER));
    ts::return_shared(registry_check);
    ts::next_tx(&mut scenario, CAMPAIGN_OWNER);

    scenario.next_tx(CAMPAIGN_OWNER);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        string::utf8(b"Preset Campaign"),
        string::utf8(b"Auto profile and stats"),
        b"integration-preset",
        vector::empty(),
        vector::empty(),
        2_500_000,
        CAMPAIGN_OWNER,
        0,
        1_000_000,
    );
    let effects = ts::next_tx(&mut scenario, CAMPAIGN_OWNER);
    assert!(ts::num_user_events(&effects) >= 3);

    scenario.next_tx(CAMPAIGN_OWNER);
    let campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let stats_id = campaign::stats_id(&campaign_obj);
    assert_eq!(campaign::stats_id(&campaign_obj), stats_id);
    assert!(!campaign::parameters_locked(&campaign_obj));
    ts::return_shared(campaign_obj);

    let stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    assert_eq!(campaign_stats::total_usd_micro(&stats_obj), 0);
    assert_eq!(campaign_stats::total_donations_count(&stats_obj), 0);
    ts::return_shared(stats_obj);

    let registry_after = scenario.take_shared<profiles::ProfilesRegistry>();
    assert!(profiles::exists(&registry_after, CAMPAIGN_OWNER));
    let profile_id = profiles::id_of(&registry_after, CAMPAIGN_OWNER);
    ts::return_shared(registry_after);

    scenario.next_tx(CAMPAIGN_OWNER);
    let profile_obj = ts::take_from_address<profiles::Profile>(&scenario, CAMPAIGN_OWNER);
    assert_eq!(sui_object::id(&profile_obj), profile_id);
    ts::return_to_address(CAMPAIGN_OWNER, profile_obj);

    ts::end(scenario);
}

#[test]
fun test_create_campaign_with_existing_profile_skips_profile_event() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(CAMPAIGN_OWNER);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    let existing_profile_id = profiles::id_of(&registry, CAMPAIGN_OWNER);
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, CAMPAIGN_OWNER);

    let profile_events_before =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());

    scenario.next_tx(CAMPAIGN_OWNER);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        string::utf8(b"Existing Profile Campaign"),
        string::utf8(b"Should reuse profile"),
        b"reuse-profile-integration",
        vector::empty(),
        vector::empty(),
        3_000_000,
        CAMPAIGN_OWNER,
        0,
        1_000_000,
    );
    let effects = ts::next_tx(&mut scenario, CAMPAIGN_OWNER);
    assert!(ts::num_user_events(&effects) >= 2);

    let profile_events_after =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());
    assert_eq!(profile_events_after, profile_events_before);

    scenario.next_tx(CAMPAIGN_OWNER);
    let registry_after = scenario.take_shared<profiles::ProfilesRegistry>();
    assert_eq!(profiles::id_of(&registry_after, CAMPAIGN_OWNER), existing_profile_id);
    ts::return_shared(registry_after);

    let campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let stats_id = campaign::stats_id(&campaign_obj);
    assert_eq!(campaign::stats_id(&campaign_obj), stats_id);
    ts::return_shared(campaign_obj);

    let stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    assert_eq!(campaign_stats::total_usd_micro(&stats_obj), 0);
    assert_eq!(campaign_stats::total_donations_count(&stats_obj), 0);
    ts::return_shared(stats_obj);

    ts::end(scenario);
}

#[test]
fun test_first_time_donation_flow_emits_expected_events() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = donations_tests::setup_donation_scenario(250, 9, 5_000);

    donations_tests::configure_badge_config_for_donation_test(
        &mut scenario,
        &clock_obj,
        vector[1, 10, 100, 1_000, 10_000],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"walrus://level1"),
            string::utf8(b"walrus://level2"),
            string::utf8(b"walrus://level3"),
            string::utf8(b"walrus://level4"),
            string::utf8(b"walrus://level5"),
        ],
    );

    let locked_events_before =
        vector::length(&event::events_by_type<campaign::CampaignParametersLocked>());
    let profile_events_before =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());
    let donation_events_before =
        vector::length(&event::events_by_type<donations::DonationReceived>());
    let badge_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());

    scenario.next_tx(DONOR_ONE);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let platform_bps = campaign::payout_platform_bps(&campaign_obj);
    let platform_address = campaign::payout_platform_address(&campaign_obj);
    let recipient_address = campaign::payout_recipient_address(&campaign_obj);

    let donation_coin =
        coin::mint_for_testing<donations_tests::TestCoin>(1_500_000_000, ts::ctx(&mut scenario));
    let raw_amount = coin::value(&donation_coin);
    let expected_usd = donations::quote_usd_micro<donations_tests::TestCoin>(
        &registry,
        &clock_obj,
        raw_amount,
        &price_obj,
        option::none(),
    );
    let platform_amount_raw =
        (((raw_amount as u128) * (platform_bps as u128)) / BPS_DENOMINATOR) as u64;
    let recipient_amount_raw = raw_amount - platform_amount_raw;
    let expected_platform_usd =
        (((expected_usd as u128) * (platform_bps as u128)) / BPS_DENOMINATOR) as u64;
    let expected_recipient_usd = expected_usd - expected_platform_usd;
    let expected_coin_type =
        token_registry::coin_type_canonical<donations_tests::TestCoin>();
    let expected_coin_symbol = token_registry::symbol<donations_tests::TestCoin>(&registry);

    let outcome = donations::donate_and_award_first_time<donations_tests::TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        option::none(),
        ts::ctx(&mut scenario),
    );

    assert_eq!(donations::outcome_usd_micro(&outcome), expected_usd);
    let minted_levels = donations::outcome_minted_levels(&outcome);
    assert_eq!(vector::length(minted_levels), 1);
    assert_eq!(*vector::borrow(minted_levels, 0), 1);
    assert!(campaign::parameters_locked(&campaign_obj));
    assert_eq!(campaign_stats::total_usd_micro(&stats_obj), expected_usd);
    assert_eq!(campaign_stats::total_donations_count(&stats_obj), 1);
    let (per_coin_total, per_coin_count) =
        campaign_stats::per_coin_totals_for_test<donations_tests::TestCoin>(&stats_obj);
    assert_eq!(per_coin_total, raw_amount as u128);
    assert_eq!(per_coin_count, 1);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    let locked_events_after =
        vector::length(&event::events_by_type<campaign::CampaignParametersLocked>());
    assert_eq!(locked_events_after, locked_events_before + 1);

    let profile_events_after =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());
    assert_eq!(profile_events_after, profile_events_before + 1);

    let donation_events = event::events_by_type<donations::DonationReceived>();
    assert_eq!(vector::length(&donation_events), donation_events_before + 1);
    let latest_donation =
        vector::borrow(&donation_events, donation_events_before);
    let (
        recorded_campaign_id,
        recorded_donor,
        recorded_coin_type,
        recorded_coin_symbol,
        recorded_amount_raw,
        recorded_amount_usd,
        recorded_platform_raw,
        recorded_recipient_raw,
        recorded_platform_usd,
        recorded_recipient_usd,
        recorded_platform_bps,
        recorded_platform_address,
        recorded_recipient_address,
        _timestamp,
    ) = donations::unpack_donation_received(latest_donation);
    assert_eq!(recorded_campaign_id, campaign_id);
    assert_eq!(recorded_donor, DONOR_ONE);
    assert_eq!(recorded_coin_type, expected_coin_type);
    assert_eq!(recorded_coin_symbol, expected_coin_symbol);
    assert_eq!(recorded_amount_raw, raw_amount);
    assert_eq!(recorded_amount_usd, expected_usd);
    assert_eq!(recorded_platform_raw, platform_amount_raw);
    assert_eq!(recorded_recipient_raw, recipient_amount_raw);
    assert_eq!(recorded_platform_usd, expected_platform_usd);
    assert_eq!(recorded_recipient_usd, expected_recipient_usd);
    assert_eq!(recorded_platform_bps, platform_bps);
    assert_eq!(recorded_platform_address, platform_address);
    assert_eq!(recorded_recipient_address, recipient_address);

    let badge_events_after =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());
    assert_eq!(badge_events_after, badge_events_before + 1);

    scenario.next_tx(DONOR_ONE);
    let registry_after = scenario.take_shared<profiles::ProfilesRegistry>();
    assert!(profiles::exists(&registry_after, DONOR_ONE));
    let profile_id = profiles::id_of(&registry_after, DONOR_ONE);
    ts::return_shared(registry_after);

    let profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR_ONE);
    assert_eq!(profiles::total_usd_micro(&profile), expected_usd);
    assert_eq!(profiles::total_donations_count(&profile), 1);
    assert_eq!(sui_object::id(&profile), profile_id);
    assert!(profiles::has_badge_level(&profile, 1));
    ts::return_to_address(DONOR_ONE, profile);

    let platform_coin =
        ts::take_from_address<coin::Coin<donations_tests::TestCoin>>(&scenario, platform_address);
    assert_eq!(coin::value(&platform_coin), platform_amount_raw);
    coin::burn_for_testing(platform_coin);
    let recipient_coin =
        ts::take_from_address<coin::Coin<donations_tests::TestCoin>>(&scenario, recipient_address);
    assert_eq!(coin::value(&recipient_coin), recipient_amount_raw);
    coin::burn_for_testing(recipient_coin);

    donations_tests::cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun test_repeat_donation_flow_accumulates_totals_and_awards_next_badge() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = donations_tests::setup_donation_scenario(250, 9, 5_000);

    donations_tests::configure_badge_config_for_donation_test(
        &mut scenario,
        &clock_obj,
        vector[1, 10, 100, 1_000, 10_000],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"walrus://level1"),
            string::utf8(b"walrus://level2"),
            string::utf8(b"walrus://level3"),
            string::utf8(b"walrus://level4"),
            string::utf8(b"walrus://level5"),
        ],
    );

    scenario.next_tx(DONOR_ONE);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let first_coin =
        coin::mint_for_testing<donations_tests::TestCoin>(2_000_000_000, ts::ctx(&mut scenario));
    let first_raw = coin::value(&first_coin);
    let first_usd = donations::quote_usd_micro<donations_tests::TestCoin>(
        &registry,
        &clock_obj,
        first_raw,
        &price_obj,
        option::none(),
    );

    let first_outcome = donations::donate_and_award_first_time<donations_tests::TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        first_coin,
        &price_obj,
        0,
        option::none(),
        ts::ctx(&mut scenario),
    );
    let first_levels = donations::outcome_minted_levels(&first_outcome);
    assert_eq!(vector::length(first_levels), 1);
    assert_eq!(*vector::borrow(first_levels, 0), 1);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    scenario.next_tx(DONOR_ONE);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR_ONE);

    let second_coin =
        coin::mint_for_testing<donations_tests::TestCoin>(1_500_000_000, ts::ctx(&mut scenario));
    let second_raw = coin::value(&second_coin);
    let second_usd = donations::quote_usd_micro<donations_tests::TestCoin>(
        &registry,
        &clock_obj,
        second_raw,
        &price_obj,
        option::none(),
    );

    let outcome = donations::donate_and_award<donations_tests::TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &clock_obj,
        &mut profile,
        second_coin,
        &price_obj,
        0,
        option::none(),
        ts::ctx(&mut scenario),
    );

    assert_eq!(donations::outcome_usd_micro(&outcome), second_usd);
    let minted_levels = donations::outcome_minted_levels(&outcome);
    assert_eq!(vector::length(minted_levels), 1);
    assert_eq!(*vector::borrow(minted_levels, 0), 2);
    assert!(campaign::parameters_locked(&campaign_obj));

    let total_usd = first_usd + second_usd;
    let total_raw = (first_raw + second_raw) as u128;
    assert_eq!(campaign_stats::total_usd_micro(&stats_obj), total_usd);
    assert_eq!(campaign_stats::total_donations_count(&stats_obj), 2);
    let (per_coin_total, per_coin_count) =
        campaign_stats::per_coin_totals_for_test<donations_tests::TestCoin>(&stats_obj);
    assert_eq!(per_coin_total, total_raw);
    assert_eq!(per_coin_count, 2);

    let platform_address = campaign::payout_platform_address(&campaign_obj);
    let recipient_address = campaign::payout_recipient_address(&campaign_obj);

    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    assert!(profiles::has_badge_level(&profile, 1));
    assert!(profiles::has_badge_level(&profile, 2));
    assert_eq!(profiles::total_usd_micro(&profile), total_usd);
    assert_eq!(profiles::total_donations_count(&profile), 2);
    assert_eq!(profiles::owner(&profile), DONOR_ONE);
    ts::return_to_address(DONOR_ONE, profile);

    donations_tests::cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun test_multi_token_donations_track_per_coin_stats() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = donations_tests::setup_donation_scenario(200, 9, 5_000);

    register_alt_test_coin(&mut scenario, &feed_id, &clock_obj, 9, 5_000);

    donations_tests::configure_badge_config_for_donation_test(
        &mut scenario,
        &clock_obj,
        vector[1, 10, 100, 1_000, 10_000],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"walrus://level1"),
            string::utf8(b"walrus://level2"),
            string::utf8(b"walrus://level3"),
            string::utf8(b"walrus://level4"),
            string::utf8(b"walrus://level5"),
        ],
    );

    scenario.next_tx(DONOR_ONE);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let first_coin =
        coin::mint_for_testing<donations_tests::TestCoin>(1_200_000_000, ts::ctx(&mut scenario));
    let first_raw = coin::value(&first_coin);
    let first_usd = donations::quote_usd_micro<donations_tests::TestCoin>(
        &registry,
        &clock_obj,
        first_raw,
        &price_obj,
        option::none(),
    );

    let first_outcome = donations::donate_and_award_first_time<donations_tests::TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        first_coin,
        &price_obj,
        0,
        option::none(),
        ts::ctx(&mut scenario),
    );
    assert_eq!(donations::outcome_usd_micro(&first_outcome), first_usd);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    scenario.next_tx(DONOR_TWO);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let second_coin =
        coin::mint_for_testing<AltTestCoin>(2_000_000_000, ts::ctx(&mut scenario));
    let second_raw = coin::value(&second_coin);
    let second_usd = donations::quote_usd_micro<AltTestCoin>(
        &registry,
        &clock_obj,
        second_raw,
        &price_obj,
        option::none(),
    );
    let expected_canonical = token_registry::coin_type_canonical<AltTestCoin>();
    let expected_symbol = token_registry::symbol<AltTestCoin>(&registry);

    let second_outcome = donations::donate_and_award_first_time<AltTestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        second_coin,
        &price_obj,
        0,
        option::none(),
        ts::ctx(&mut scenario),
    );
    assert_eq!(donations::outcome_usd_micro(&second_outcome), second_usd);

    let (testcoin_raw, testcoin_count) =
        campaign_stats::per_coin_totals_for_test<donations_tests::TestCoin>(&stats_obj);
    let (altcoin_raw, altcoin_count) =
        campaign_stats::per_coin_totals_for_test<AltTestCoin>(&stats_obj);
    assert_eq!(testcoin_raw, first_raw as u128);
    assert_eq!(testcoin_count, 1);
    assert_eq!(altcoin_raw, second_raw as u128);
    assert_eq!(altcoin_count, 1);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    let donation_events = event::events_by_type<donations::DonationReceived>();
    let latest_donation = vector::borrow(&donation_events, vector::length(&donation_events) - 1);
    let (_, donor_address, canonical, coin_symbol, amount_raw, _, _, _, _, _, _, _, _, _) =
        donations::unpack_donation_received(latest_donation);
    assert_eq!(donor_address, DONOR_TWO);
    assert_eq!(canonical, expected_canonical);
    assert_eq!(coin_symbol, expected_symbol);
    assert_eq!(amount_raw, second_raw);

    donations_tests::cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun test_concurrent_first_time_donations_lock_once() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = donations_tests::setup_donation_scenario(200, 9, 5_000);

    donations_tests::configure_badge_config_for_donation_test(
        &mut scenario,
        &clock_obj,
        vector[1, 10, 100, 1_000, 10_000],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"walrus://level1"),
            string::utf8(b"walrus://level2"),
            string::utf8(b"walrus://level3"),
            string::utf8(b"walrus://level4"),
            string::utf8(b"walrus://level5"),
        ],
    );

    scenario.next_tx(DONOR_ONE);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let first_coin =
        coin::mint_for_testing<donations_tests::TestCoin>(1_000_000_000, ts::ctx(&mut scenario));
    let first_raw = coin::value(&first_coin);

    let _ = donations::donate_and_award_first_time<donations_tests::TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        first_coin,
        &price_obj,
        0,
        option::none(),
        ts::ctx(&mut scenario),
    );

    let platform_address = campaign::payout_platform_address(&campaign_obj);
    let recipient_address = campaign::payout_recipient_address(&campaign_obj);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    scenario.next_tx(DONOR_TWO);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let second_coin =
        coin::mint_for_testing<donations_tests::TestCoin>(800_000_000, ts::ctx(&mut scenario));
    let second_raw = coin::value(&second_coin);

    let _ = donations::donate_and_award_first_time<donations_tests::TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        second_coin,
        &price_obj,
        0,
        option::none(),
        ts::ctx(&mut scenario),
    );

    assert!(campaign::parameters_locked(&campaign_obj));
    let (per_coin_total, per_coin_count) =
        campaign_stats::per_coin_totals_for_test<donations_tests::TestCoin>(&stats_obj);
    assert_eq!(per_coin_total, (first_raw + second_raw) as u128);
    assert_eq!(per_coin_count, 2);
    assert_eq!(campaign_stats::total_donations_count(&stats_obj), 2);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    scenario.next_tx(DONOR_ONE);
    let registry_after = scenario.take_shared<profiles::ProfilesRegistry>();
    assert!(profiles::exists(&registry_after, DONOR_ONE));
    assert!(profiles::exists(&registry_after, DONOR_TWO));
    ts::return_shared(registry_after);

    let platform_coin =
        ts::take_from_address<coin::Coin<donations_tests::TestCoin>>(&scenario, platform_address);
    coin::burn_for_testing(platform_coin);
    let recipient_coin =
        ts::take_from_address<coin::Coin<donations_tests::TestCoin>>(&scenario, recipient_address);
    coin::burn_for_testing(recipient_coin);

    donations_tests::cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun test_donation_succeeds_when_slippage_floor_met() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = donations_tests::setup_donation_scenario(150, 9, 5_000);

    scenario.next_tx(DONOR_ONE);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let donation_coin =
        coin::mint_for_testing<donations_tests::TestCoin>(1_250_000_000, ts::ctx(&mut scenario));
    let raw_amount = coin::value(&donation_coin);
    let quoted_usd = donations::quote_usd_micro<donations_tests::TestCoin>(
        &registry,
        &clock_obj,
        raw_amount,
        &price_obj,
        option::none(),
    );
    let min_expected = if (quoted_usd > 0) { quoted_usd - 1 } else { 0 };

    let outcome = donations::donate_and_award_first_time<donations_tests::TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        min_expected,
        option::none(),
        ts::ctx(&mut scenario),
    );

    assert_eq!(donations::outcome_usd_micro(&outcome), quoted_usd);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    donations_tests::cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = donations::E_SLIPPAGE_EXCEEDED, location = 0x0::donations)]
fun test_donation_aborts_when_slippage_floor_not_met() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = donations_tests::setup_donation_scenario(150, 9, 5_000);

    scenario.next_tx(DONOR_ONE);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let donation_coin =
        coin::mint_for_testing<donations_tests::TestCoin>(1_250_000_000, ts::ctx(&mut scenario));
    let raw_amount = coin::value(&donation_coin);
    let quoted_usd = donations::quote_usd_micro<donations_tests::TestCoin>(
        &registry,
        &clock_obj,
        raw_amount,
        &price_obj,
        option::none(),
    );
    let min_expected = quoted_usd + 1;

    donations::donate_and_award_first_time<donations_tests::TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        min_expected,
        option::none(),
        ts::ctx(&mut scenario),
    );

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    donations_tests::cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}
