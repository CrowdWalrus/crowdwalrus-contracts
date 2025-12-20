#[test_only]
module crowd_walrus::donations_tests;

use crowd_walrus::campaign::{Self as campaign};
use crowd_walrus::campaign_stats::{Self as campaign_stats};
use crowd_walrus::crowd_walrus::{Self as crowd_walrus};
use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::donations;
use crowd_walrus::badge_rewards;
use crowd_walrus::profiles::{Self as profiles};
use crowd_walrus::price_oracle;
use crowd_walrus::token_registry::{Self as token_registry};
use pyth::price::{Self as pyth_price};
use pyth::price_feed::{Self as price_feed};
use pyth::price_identifier::{Self as price_identifier};
use pyth::price_info::{Self as price_info, PriceInfoObject};
use pyth::pyth;
use pyth::pyth_tests::{Self as pyth_tests};
use std::string::{Self as string, String};
use std::unit_test::assert_eq;
use sui::coin::{Self as coin};
use sui::clock::{Self as clock, Clock};
use sui::event;
use sui::object::{Self as sui_object};
use sui::test_scenario::{Self as ts};
use sui::test_utils::{Self as tu};
use sui::vec_map::{Self as vec_map};
use wormhole::state::State as WormState;
use wormhole::vaa::{Self as vaa, VAA};

const ADMIN: address = @0xA;
const OWNER: address = @0xB;
const DONOR: address = @0xD;
const DEPLOYER: address = @0x1234;
const E_CAMPAIGN_DELETED: u64 = 11;
public struct TestCoin has drop, store {}
public struct DisabledCoin has drop, store {}
public struct UnlistedCoin has drop, store {}

#[test]
fun effective_max_age_without_override_uses_registry_value() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);

    let effective = donations::effective_max_age_ms<TestCoin>(&registry, std::option::none());
    assert_eq!(effective, 5_000);

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test]
fun effective_max_age_with_override_uses_minimum() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    add_enabled_token(&mut registry, &admin_cap, &clock, 8_000);

    let tighter = donations::effective_max_age_ms<TestCoin>(&registry, std::option::some(3_000));
    assert_eq!(tighter, 3_000);

    let looser = donations::effective_max_age_ms<TestCoin>(&registry, std::option::some(12_000));
    assert_eq!(looser, 8_000);

    let zero = donations::effective_max_age_ms<TestCoin>(&registry, std::option::some(0));
    assert_eq!(zero, 8_000);

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test]
fun precheck_allows_active_campaign() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, mut clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Donation Ready"),
        string::utf8(b"Active campaign"),
        b"precheck-ok",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        1_000,
        10_000,
    );
    clock.increment_for_testing(1_000);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
   let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
   add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
   donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test]
fun precheck_allows_at_exact_start_time() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, mut clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Start Boundary"),
        string::utf8(b""),
        b"start-boundary",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        5_000,
        15_000,
    );
    clock.increment_for_testing(5_000);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test]
fun precheck_allows_at_exact_end_time() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, mut clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"End Boundary"),
        string::utf8(b""),
        b"end-boundary",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        12_000,
    );
    clock.increment_for_testing(12_000);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = donations::E_CAMPAIGN_INACTIVE, location = 0x0::donations)]
fun precheck_fails_when_campaign_inactive() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (mut campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Inactive Campaign"),
        string::utf8(b"Inactive campaign"),
        b"inactive",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        10_000,
    );
    campaign::set_is_active(&mut campaign, &owner_cap, false);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = donations::E_CAMPAIGN_CLOSED, location = 0x0::donations)]
fun precheck_fails_when_before_start() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Future Campaign"),
        string::utf8(b"Future window"),
        b"future",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        10_000,
        20_000,
    );

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = E_CAMPAIGN_DELETED, location = 0x0::campaign)]
fun precheck_fails_when_campaign_deleted() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (mut campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Deleted Campaign"),
        string::utf8(b""),
        b"deleted",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        10_000,
    );
    campaign::mark_deleted(&mut campaign, &owner_cap, 1);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = donations::E_CAMPAIGN_CLOSED, location = 0x0::donations)]
fun precheck_fails_when_after_end() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, mut clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Expired Campaign"),
        string::utf8(b"Expired window"),
        b"expired",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        5_000,
    );

    clock.increment_for_testing(10_000);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = donations::E_TOKEN_DISABLED, location = 0x0::donations)]
fun precheck_fails_when_token_disabled() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"No Token"),
        string::utf8(b"Token disabled"),
        b"disabled-token",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        10_000,
    );

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    crowd_walrus::add_token_internal<DisabledCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"DIS"),
        string::utf8(b"Disabled Coin"),
        9,
        feed_id(9),
        5_000,
        &clock,
    );
    donations::precheck<DisabledCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = donations::E_TOKEN_DISABLED, location = 0x0::donations)]
fun precheck_fails_when_token_unregistered() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, _owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Unregistered Token"),
        string::utf8(b""),
        b"no-token",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        10_000,
    );

    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    donations::precheck<UnlistedCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    campaign::share(campaign);
    tu::destroy(_owner_cap);
    ts::end(scenario);
}

#[test]
fun split_and_transfer_routes_all_to_recipient_when_platform_zero() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(DONOR);
    let (campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Zero Fee"),
        string::utf8(b"All to recipient"),
        b"split-zero",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        10_000,
    );

    let donation = coin::mint_for_testing<TestCoin>(1_000, ts::ctx(&mut scenario));
    let (platform_sent, recipient_sent) = donations::split_and_transfer<TestCoin>(
        &campaign,
        donation,
        ts::ctx(&mut scenario),
    );

    assert_eq!(platform_sent, 0);
    assert_eq!(recipient_sent, 1_000);

    ts::return_shared(clock);
    campaign::share(campaign);
    tu::destroy(owner_cap);

    let _ = ts::next_tx(&mut scenario, DONOR);

    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    assert_eq!(coin::value(&recipient_coin), recipient_sent);
    ts::return_to_address(OWNER, recipient_coin);

    ts::end(scenario);
}

#[test]
fun split_and_transfer_applies_platform_fee_with_floor_and_remainder() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(DONOR);
    let (campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Five Percent"),
        string::utf8(b"Checks remainder"),
        b"split-five",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        500,
        ADMIN,
        0,
        10_000,
    );

    let donation = coin::mint_for_testing<TestCoin>(101, ts::ctx(&mut scenario));
    let (platform_sent, recipient_sent) = donations::split_and_transfer<TestCoin>(
        &campaign,
        donation,
        ts::ctx(&mut scenario),
    );

    assert_eq!(platform_sent, 5);
    assert_eq!(recipient_sent, 96);

    ts::return_shared(clock);
    campaign::share(campaign);
    tu::destroy(owner_cap);

    let _ = ts::next_tx(&mut scenario, DONOR);

    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    assert_eq!(coin::value(&platform_coin), platform_sent);
    ts::return_to_address(ADMIN, platform_coin);

    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    assert_eq!(coin::value(&recipient_coin), recipient_sent);
    ts::return_to_address(OWNER, recipient_coin);

    ts::end(scenario);
}

#[test]
fun split_and_transfer_routes_all_to_platform_when_fee_maximum() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(DONOR);
    let (campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"All Platform"),
        string::utf8(b"Full fee"),
        b"split-full",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        10_000,
        ADMIN,
        0,
        10_000,
    );

    let donation = coin::mint_for_testing<TestCoin>(250, ts::ctx(&mut scenario));
    let (platform_sent, recipient_sent) = donations::split_and_transfer<TestCoin>(
        &campaign,
        donation,
        ts::ctx(&mut scenario),
    );

    assert_eq!(platform_sent, 250);
    assert_eq!(recipient_sent, 0);

    ts::return_shared(clock);
    campaign::share(campaign);
    tu::destroy(owner_cap);

    let _ = ts::next_tx(&mut scenario, DONOR);

    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    assert_eq!(coin::value(&platform_coin), platform_sent);
    ts::return_to_address(ADMIN, platform_coin);
    assert_eq!(
        ts::has_most_recent_for_address<coin::Coin<TestCoin>>(OWNER),
        false
    );

    ts::end(scenario);
}

#[test]
fun donation_received_event_emits_expected_payload() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, mut clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Event Campaign"),
        string::utf8(b"Payload validation"),
        b"donation-event",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        750,
        ADMIN,
        0,
        20_000,
    );
    clock.increment_for_testing(2_500);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 6_000);

    let expected_campaign_id = sui::object::id(&campaign);
    let expected_platform_bps = campaign::payout_platform_bps(&campaign);
    let expected_platform_address = campaign::payout_platform_address(&campaign);
    let expected_recipient_address = campaign::payout_recipient_address(&campaign);
    let expected_coin_type = token_registry::coin_type_canonical<TestCoin>();
    let expected_coin_symbol = token_registry::symbol<TestCoin>(&registry);
    let expected_timestamp = clock::timestamp_ms(&clock);

    let amount_raw = 5_432;
    let amount_usd_micro = 987_654;
    let platform_bps = expected_platform_bps as u128;
    let denom = 10_000u128;
    let platform_amount_raw =
        (((amount_raw as u128) * platform_bps) / denom) as u64;
    let recipient_amount_raw = amount_raw - platform_amount_raw;
    let platform_amount_usd_micro =
        (((amount_usd_micro as u128) * platform_bps) / denom) as u64;
    let recipient_amount_usd_micro = amount_usd_micro - platform_amount_usd_micro;

    donations::emit_donation_received_event<TestCoin>(
        &campaign,
        &registry,
        DONOR,
        amount_raw,
        amount_usd_micro,
        platform_amount_raw,
        recipient_amount_raw,
        platform_amount_usd_micro,
        recipient_amount_usd_micro,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);

    let events = event::events_by_type<donations::DonationReceived>();
    assert_eq!(vector::length(&events), 1);
    let recorded = vector::borrow(&events, 0);
    let (
        recorded_campaign_id,
        recorded_donor,
        recorded_coin_type,
        recorded_coin_symbol,
        recorded_amount_raw,
        recorded_amount_usd_micro,
        recorded_platform_amount_raw,
        recorded_recipient_amount_raw,
        recorded_platform_amount_usd_micro,
        recorded_recipient_amount_usd_micro,
        recorded_platform_bps,
        recorded_platform_address,
        recorded_recipient_address,
        recorded_timestamp_ms,
    ) = donations::unpack_donation_received(recorded);
    assert_eq!(recorded_campaign_id, expected_campaign_id);
    assert_eq!(recorded_donor, DONOR);
    assert_eq!(recorded_coin_type, expected_coin_type);
    assert_eq!(recorded_coin_symbol, expected_coin_symbol);
    assert_eq!(recorded_amount_raw, amount_raw);
    assert_eq!(recorded_amount_usd_micro, amount_usd_micro);
    assert_eq!(recorded_platform_amount_raw, platform_amount_raw);
    assert_eq!(recorded_recipient_amount_raw, recipient_amount_raw);
    assert_eq!(
        recorded_platform_amount_usd_micro,
        platform_amount_usd_micro
    );
    assert_eq!(
        recorded_recipient_amount_usd_micro,
        recipient_amount_usd_micro
    );
    assert_eq!(recorded_platform_bps, expected_platform_bps);
    assert_eq!(recorded_platform_address, expected_platform_address);
    assert_eq!(recorded_recipient_address, expected_recipient_address);
    assert_eq!(recorded_timestamp_ms, expected_timestamp);

    ts::end(scenario);
}

#[test]
fun donate_locks_parameters_and_emits_events() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(500, 9, 5_000);

    let locked_count_before =
        vector::length(&event::events_by_type<campaign::CampaignParametersLocked>());
    let donation_count_before =
        vector::length(&event::events_by_type<donations::DonationReceived>());

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    let donation_coin = coin::mint_for_testing<TestCoin>(1_234_567_890, ts::ctx(&mut scenario));
    let raw_amount = coin::value(&donation_coin);
    let expected_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        raw_amount,
        &price_obj,
        std::option::none(),
    );
    let platform_bps = campaign::payout_platform_bps(&campaign_obj);
    let platform_amount_raw = (((raw_amount as u128) * (platform_bps as u128)) / 10_000u128) as u64;
    let recipient_amount_raw = raw_amount - platform_amount_raw;
    let expected_platform_usd =
        (((expected_usd as u128) * (platform_bps as u128)) / 10_000u128) as u64;
    let expected_recipient_usd = expected_usd - expected_platform_usd;

    let returned_usd = donations::donate<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    assert_eq!(returned_usd, expected_usd);

    let locked_events_after = event::events_by_type<campaign::CampaignParametersLocked>();
    let locked_count_after = vector::length(&locked_events_after);
    assert_eq!(locked_count_after, locked_count_before + 1);
    let new_locked_event = vector::borrow(&locked_events_after, locked_count_after - 1);
    let (locked_campaign_id, _) =
        campaign::unpack_parameters_locked_event(new_locked_event);
    assert_eq!(locked_campaign_id, campaign_id);

    let donation_events_after = event::events_by_type<donations::DonationReceived>();
    let donation_count_after = vector::length(&donation_events_after);
    assert_eq!(donation_count_after, donation_count_before + 1);
    let recorded = vector::borrow(&donation_events_after, donation_count_after - 1);
    let (
        recorded_campaign_id,
        recorded_donor,
        _recorded_canonical,
        _recorded_symbol,
        recorded_amount_raw,
        recorded_amount_usd,
        recorded_platform_raw,
        recorded_recipient_raw,
        recorded_platform_usd,
        recorded_recipient_usd,
        recorded_platform_bps,
        recorded_platform_address,
        recorded_recipient_address,
        _timestamp_ms,
    ) = donations::unpack_donation_received(recorded);
    assert_eq!(recorded_campaign_id, campaign_id);
    assert_eq!(recorded_donor, DONOR);
    assert_eq!(recorded_amount_raw, raw_amount);
    assert_eq!(recorded_amount_usd, expected_usd);
    assert_eq!(recorded_platform_raw, platform_amount_raw);
    assert_eq!(recorded_recipient_raw, recipient_amount_raw);
    assert_eq!(recorded_platform_usd, expected_platform_usd);
    assert_eq!(recorded_recipient_usd, expected_recipient_usd);
    assert_eq!(recorded_platform_bps, platform_bps);
    assert_eq!(recorded_platform_address, ADMIN);
    assert_eq!(recorded_recipient_address, OWNER);

    assert!(campaign::parameters_locked(&campaign_obj));
    assert_eq!(campaign_stats::total_usd_micro(&stats_obj), expected_usd);
    assert_eq!(campaign_stats::total_donations_count(&stats_obj), 1);
    let (per_coin_total, per_coin_count) =
        campaign_stats::per_coin_totals_for_test<TestCoin>(&stats_obj);
    assert_eq!(per_coin_total, raw_amount as u128);
    assert_eq!(per_coin_count, 1);

    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    let _ = ts::next_tx(&mut scenario, DONOR);
    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    assert_eq!(coin::value(&platform_coin), platform_amount_raw);
    coin::burn_for_testing(platform_coin);

    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    assert_eq!(coin::value(&recipient_coin), recipient_amount_raw);
    coin::burn_for_testing(recipient_coin);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun donate_and_award_first_time_creates_profile_and_mints_badge() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(250, 9, 5_000);

    configure_badge_config_for_donation_test(
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

    scenario.next_tx(DONOR);
    let profile_events_before =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());
    let badge_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());
    let donation_events_before =
        vector::length(&event::events_by_type<donations::DonationReceived>());

    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    assert!(!profiles::exists(&profiles_registry, DONOR));

    let donation_coin = coin::mint_for_testing<TestCoin>(2_000_000_000, ts::ctx(&mut scenario));
    let raw_amount = coin::value(&donation_coin);
    let expected_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        raw_amount,
        &price_obj,
        std::option::none(),
    );

    let outcome = donations::donate_and_award_first_time<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
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
        campaign_stats::per_coin_totals_for_test<TestCoin>(&stats_obj);
    assert_eq!(per_coin_total, raw_amount as u128);
    assert_eq!(per_coin_count, 1);

    assert!(profiles::exists(&profiles_registry, DONOR));

    let profile_events_after =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());
    let badge_events_after =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());
    let donation_events_after =
        vector::length(&event::events_by_type<donations::DonationReceived>());
    assert_eq!(profile_events_after, profile_events_before + 1);
    assert_eq!(badge_events_after, badge_events_before + 1);
    assert_eq!(donation_events_after, donation_events_before + 1);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    let _ = ts::next_tx(&mut scenario, DONOR);
    let profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR);
    assert_eq!(profiles::total_usd_micro(&profile), expected_usd);
    assert_eq!(profiles::total_donations_count(&profile), 1);
    assert!(profiles::has_badge_level(&profile, 1));
    ts::return_to_address(DONOR, profile);

    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    coin::burn_for_testing(platform_coin);
    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    coin::burn_for_testing(recipient_coin);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(
    abort_code = profiles::E_PROFILE_EXISTS,
    location = 0x0::donations
)]
fun donate_and_award_first_time_aborts_when_profile_exists() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(250, 9, 5_000);

    configure_badge_config_for_donation_test(
        &mut scenario,
        &clock_obj,
        vector[100, 200, 300, 400, 500],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"walrus://L1"),
            string::utf8(b"walrus://L2"),
            string::utf8(b"walrus://L3"),
            string::utf8(b"walrus://L4"),
            string::utf8(b"walrus://L5"),
        ],
    );

    scenario.next_tx(DONOR);
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_or_get_profile_for_sender(&mut registry, &clock_obj, ts::ctx(&mut scenario));
    ts::return_shared(registry);

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();
    let donation_coin = coin::mint_for_testing<TestCoin>(1_000_000, ts::ctx(&mut scenario));

    donations::donate_and_award_first_time<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun donate_and_award_first_time_without_badge() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(200, 9, 5_000);

    configure_badge_config_for_donation_test(
        &mut scenario,
        &clock_obj,
        vector[5_000_000_000, 10_000_000_000, 15_000_000_000, 20_000_000_000, 25_000_000_000],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"walrus://hi-1"),
            string::utf8(b"walrus://hi-2"),
            string::utf8(b"walrus://hi-3"),
            string::utf8(b"walrus://hi-4"),
            string::utf8(b"walrus://hi-5"),
        ],
    );

    scenario.next_tx(DONOR);
    let badge_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());

    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let donation_coin = coin::mint_for_testing<TestCoin>(1_000_000_000, ts::ctx(&mut scenario));
    let raw_amount = coin::value(&donation_coin);
    let expected_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        raw_amount,
        &price_obj,
        std::option::none(),
    );

    let outcome = donations::donate_and_award_first_time<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    assert_eq!(donations::outcome_usd_micro(&outcome), expected_usd);
    assert_eq!(vector::length(donations::outcome_minted_levels(&outcome)), 0);

    let badge_events_after =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());
    assert_eq!(badge_events_after, badge_events_before);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    let _ = ts::next_tx(&mut scenario, DONOR);
    let profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR);
    assert!(!profiles::has_badge_level(&profile, 1));
    assert_eq!(profiles::total_usd_micro(&profile), expected_usd);
    assert_eq!(profiles::total_donations_count(&profile), 1);
    ts::return_to_address(DONOR, profile);

    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    coin::burn_for_testing(platform_coin);
    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    coin::burn_for_testing(recipient_coin);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun donate_and_award_first_time_large_donation_awards_single_badge() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(150, 9, 5_000);

    configure_badge_config_for_donation_test(
        &mut scenario,
        &clock_obj,
        vector[1_000, 2_000, 3_000, 4_000, 5_000],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"walrus://stack-1"),
            string::utf8(b"walrus://stack-2"),
            string::utf8(b"walrus://stack-3"),
            string::utf8(b"walrus://stack-4"),
            string::utf8(b"walrus://stack-5"),
        ],
    );

    scenario.next_tx(DONOR);
    let badge_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());

    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let donation_coin = coin::mint_for_testing<TestCoin>(3_000_000_000, ts::ctx(&mut scenario));
    let raw_amount = coin::value(&donation_coin);
    let expected_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        raw_amount,
        &price_obj,
        std::option::none(),
    );

    let outcome = donations::donate_and_award_first_time<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    let minted_levels = donations::outcome_minted_levels(&outcome);
    assert_eq!(vector::length(minted_levels), 1);
    assert_eq!(*vector::borrow(minted_levels, 0), 1);

    let badge_events_after =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());
    assert_eq!(badge_events_after, badge_events_before + 1);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    let _ = ts::next_tx(&mut scenario, DONOR);
    let profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR);
    assert!(profiles::has_badge_level(&profile, 1));
    assert!(!profiles::has_badge_level(&profile, 2));
    assert!(!profiles::has_badge_level(&profile, 3));
    assert_eq!(profiles::total_usd_micro(&profile), expected_usd);
    assert_eq!(profiles::total_donations_count(&profile), 1);
    ts::return_to_address(DONOR, profile);

    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    coin::burn_for_testing(platform_coin);
    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    coin::burn_for_testing(recipient_coin);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun donate_and_award_repeat_donor_updates_profile_and_awards_next_badge() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(250, 9, 5_000);

    configure_badge_config_for_donation_test(
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

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let first_coin = coin::mint_for_testing<TestCoin>(2_000_000_000, ts::ctx(&mut scenario));
    let first_raw = coin::value(&first_coin);
    let first_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        first_raw,
        &price_obj,
        std::option::none(),
    );

    let first_outcome = donations::donate_and_award_first_time<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        first_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    assert_eq!(donations::outcome_usd_micro(&first_outcome), first_usd);
    let first_levels = donations::outcome_minted_levels(&first_outcome);
    assert_eq!(vector::length(first_levels), 1);
    assert_eq!(*vector::borrow(first_levels, 0), 1);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    scenario.next_tx(DONOR);
    let badge_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());
    let donation_events_before =
        vector::length(&event::events_by_type<donations::DonationReceived>());
    let profile_events_before =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());

    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR);
    assert_eq!(profiles::owner(&profile), DONOR);

    let second_coin = coin::mint_for_testing<TestCoin>(1_500_000_000, ts::ctx(&mut scenario));
    let second_raw = coin::value(&second_coin);
    let second_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        second_raw,
        &price_obj,
        std::option::none(),
    );
    let combined_usd = first_usd + second_usd;
    let combined_raw = (first_raw + second_raw) as u128;

    let outcome = donations::donate_and_award<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &clock_obj,
        &mut profile,
        second_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    assert_eq!(donations::outcome_usd_micro(&outcome), second_usd);
    let minted_levels = donations::outcome_minted_levels(&outcome);
    assert_eq!(vector::length(minted_levels), 1);
    assert_eq!(*vector::borrow(minted_levels, 0), 2);
    assert!(campaign::parameters_locked(&campaign_obj));

    assert_eq!(campaign_stats::total_usd_micro(&stats_obj), combined_usd);
    assert_eq!(campaign_stats::total_donations_count(&stats_obj), 2);
    let (per_coin_total, per_coin_count) =
        campaign_stats::per_coin_totals_for_test<TestCoin>(&stats_obj);
    assert_eq!(per_coin_total, combined_raw);
    assert_eq!(per_coin_count, 2);

    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    let badge_events_after =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());
    let donation_events_after =
        vector::length(&event::events_by_type<donations::DonationReceived>());
    let profile_events_after =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());
    assert_eq!(badge_events_after, badge_events_before + 1);
    assert_eq!(donation_events_after, donation_events_before + 1);
    assert_eq!(profile_events_after, profile_events_before);

    assert!(profiles::has_badge_level(&profile, 1));
    assert!(profiles::has_badge_level(&profile, 2));
    assert_eq!(profiles::total_usd_micro(&profile), combined_usd);
    assert_eq!(profiles::total_donations_count(&profile), 2);
    assert_eq!(profiles::owner(&profile), DONOR);
    ts::return_to_address(DONOR, profile);

    let _ = ts::next_tx(&mut scenario, DONOR);
    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    coin::burn_for_testing(platform_coin);
    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    coin::burn_for_testing(recipient_coin);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun donate_and_award_repeat_donor_awards_multiple_badges_in_single_donation() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(220, 9, 5_000);

    let first_raw: u64 = 400_000_000;
    let second_raw: u64 = 350_000_000;
    let third_raw: u64 = 5_000_000_000;

    scenario.next_tx(DONOR);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let first_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        first_raw,
        &price_obj,
        std::option::none(),
    );
    let second_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        second_raw,
        &price_obj,
        std::option::none(),
    );
    let third_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        third_raw,
        &price_obj,
        std::option::none(),
    );
    ts::return_shared(registry);

    let total_after_second = first_usd + second_usd;
    let total_after_third = total_after_second + third_usd;
    let level1_threshold = total_after_second + 1;
    let level2_threshold = level1_threshold + 1;
    let level3_threshold = level2_threshold + 1;
    let level4_threshold = total_after_third + 1;
    let level5_threshold = level4_threshold + 1;

    configure_badge_config_for_donation_test(
        &mut scenario,
        &clock_obj,
        vector[
            level1_threshold,
            level2_threshold,
            level3_threshold,
            level4_threshold,
            level5_threshold,
        ],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"walrus://multi-1"),
            string::utf8(b"walrus://multi-2"),
            string::utf8(b"walrus://multi-3"),
            string::utf8(b"walrus://multi-4"),
            string::utf8(b"walrus://multi-5"),
        ],
    );

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let first_coin = coin::mint_for_testing<TestCoin>(first_raw, ts::ctx(&mut scenario));
    let outcome_first = donations::donate_and_award_first_time<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        first_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );
    assert_eq!(vector::length(donations::outcome_minted_levels(&outcome_first)), 0);

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR);
    assert_eq!(profiles::owner(&profile), DONOR);

    let second_coin = coin::mint_for_testing<TestCoin>(second_raw, ts::ctx(&mut scenario));
    let outcome_second = donations::donate_and_award<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &clock_obj,
        &mut profile,
        second_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );
    assert_eq!(vector::length(donations::outcome_minted_levels(&outcome_second)), 0);

    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);
    ts::return_to_address(DONOR, profile);

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR);
    assert_eq!(profiles::owner(&profile), DONOR);

    let third_coin = coin::mint_for_testing<TestCoin>(third_raw, ts::ctx(&mut scenario));
    let outcome_third = donations::donate_and_award<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &clock_obj,
        &mut profile,
        third_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    let minted_levels = donations::outcome_minted_levels(&outcome_third);
    assert_eq!(vector::length(minted_levels), 3);
    assert_eq!(*vector::borrow(minted_levels, 0), 1);
    assert_eq!(*vector::borrow(minted_levels, 1), 2);
    assert_eq!(*vector::borrow(minted_levels, 2), 3);

    let expected_profile_usd = total_after_third;
    let expected_coin_total =
        (first_raw as u128) + (second_raw as u128) + (third_raw as u128);

    assert_eq!(campaign_stats::total_usd_micro(&stats_obj), expected_profile_usd);
    assert_eq!(campaign_stats::total_donations_count(&stats_obj), 3);
    let (per_coin_total, per_coin_count) =
        campaign_stats::per_coin_totals_for_test<TestCoin>(&stats_obj);
    assert_eq!(per_coin_total, expected_coin_total);
    assert_eq!(per_coin_count, 3);

    assert_eq!(profiles::total_usd_micro(&profile), expected_profile_usd);
    assert_eq!(profiles::total_donations_count(&profile), 3);
    assert!(profiles::has_badge_level(&profile, 1));
    assert!(profiles::has_badge_level(&profile, 2));
    assert!(profiles::has_badge_level(&profile, 3));
    assert!(!profiles::has_badge_level(&profile, 4));
    assert_eq!(profiles::owner(&profile), DONOR);

    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);
    ts::return_to_address(DONOR, profile);

    let _ = ts::next_tx(&mut scenario, DONOR);
    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    coin::burn_for_testing(platform_coin);
    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    coin::burn_for_testing(recipient_coin);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = profiles::E_NOT_PROFILE_OWNER, location = 0x0::donations)]
fun donate_and_award_aborts_when_profile_owner_mismatch() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(200, 9, 5_000);

    configure_badge_config_for_donation_test(
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

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();

    let first_coin = coin::mint_for_testing<TestCoin>(1_000_000_000, ts::ctx(&mut scenario));
    donations::donate_and_award_first_time<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &mut profiles_registry,
        &clock_obj,
        first_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    ts::return_shared(profiles_registry);
    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    scenario.next_tx(OWNER);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, DONOR);

    let donation_coin = coin::mint_for_testing<TestCoin>(500_000_000, ts::ctx(&mut scenario));

    donations::donate_and_award<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &badge_config,
        &clock_obj,
        &mut profile,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    ts::return_shared(badge_config);
    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);
    ts::return_to_address(DONOR, profile);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = donations::E_CAMPAIGN_CLOSED, location = 0x0::donations)]
fun donate_aborts_before_campaign_start() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario_with_offsets(100, 9, 5_000, 5_000, 1_000_000);

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    let donation_coin = coin::mint_for_testing<TestCoin>(10_000, ts::ctx(&mut scenario));
    donations::donate<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun donate_succeeds_at_campaign_end_boundary() {
    let (
        mut scenario,
        mut clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
) = setup_donation_scenario(250, 9, 1_500_000);

scenario.next_tx(DONOR);
let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
let mut stats_obj =
    scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
let registry = scenario.take_shared<token_registry::TokenRegistry>();

    let end_time = campaign::end_date(&campaign_obj);
    clock::set_for_testing(&mut clock_obj, end_time);

    let donation_coin = coin::mint_for_testing<TestCoin>(50_000, ts::ctx(&mut scenario));
    let raw_amount = coin::value(&donation_coin);
    let expected_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        raw_amount,
        &price_obj,
        std::option::none(),
    );

    let usd = donations::donate<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    assert_eq!(usd, expected_usd);

    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    let _ = ts::next_tx(&mut scenario, DONOR);
    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    coin::burn_for_testing(platform_coin);
    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    coin::burn_for_testing(recipient_coin);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun donate_succeeds_at_campaign_start_boundary() {
    let (
        mut scenario,
        mut clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario_with_offsets(300, 9, 15_000, 10_000, 1_000_000);

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    let start_time = campaign::start_date(&campaign_obj);

    let donation_coin = coin::mint_for_testing<TestCoin>(60_000, ts::ctx(&mut scenario));
    let raw_amount = coin::value(&donation_coin);
    clock::set_for_testing(&mut clock_obj, start_time);
    let expected_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        raw_amount,
        &price_obj,
        std::option::none(),
    );

    let usd = donations::donate<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    assert_eq!(usd, expected_usd);

    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    let _ = ts::next_tx(&mut scenario, DONOR);
    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    coin::burn_for_testing(platform_coin);
    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    coin::burn_for_testing(recipient_coin);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = donations::E_CAMPAIGN_CLOSED, location = 0x0::donations)]
fun donate_aborts_after_campaign_end() {
    let (
        mut scenario,
        mut clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(150, 9, 1_500_000);

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    let end_time = campaign::end_date(&campaign_obj);
    clock::set_for_testing(&mut clock_obj, end_time + 1);

    let donation_coin = coin::mint_for_testing<TestCoin>(75_000, ts::ctx(&mut scenario));

    donations::donate<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun donate_only_locks_once_across_multiple_donations() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(150, 9, 5_000);

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    let mut donation_coin = coin::mint_for_testing<TestCoin>(500_000, ts::ctx(&mut scenario));
    let mut usd = donations::donate<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );
    assert!(usd > 0);

    let lock_events_after_first = event::events_by_type<campaign::CampaignParametersLocked>();
    assert_eq!(vector::length(&lock_events_after_first), 1);

    donation_coin = coin::mint_for_testing<TestCoin>(700_000, ts::ctx(&mut scenario));
    usd = donations::donate<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );
    assert!(usd > 0);

    let lock_events_after_second = event::events_by_type<campaign::CampaignParametersLocked>();
    assert_eq!(vector::length(&lock_events_after_second), 1);

    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    let _ = ts::next_tx(&mut scenario, DONOR);
    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    coin::burn_for_testing(platform_coin);
    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    coin::burn_for_testing(recipient_coin);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = donations::E_SLIPPAGE_EXCEEDED, location = 0x0::donations)]
fun donate_aborts_when_slippage_exceeded() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    ) = setup_donation_scenario(200, 9, 5_000);

    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let mut stats_obj =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    let donation_coin = coin::mint_for_testing<TestCoin>(250_000, ts::ctx(&mut scenario));
    let raw_amount = coin::value(&donation_coin);
    let actual_usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        raw_amount,
        &price_obj,
        std::option::none(),
    );

    donations::donate<TestCoin>(
        &mut campaign_obj,
        &mut stats_obj,
        &registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        actual_usd + 1,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    ts::return_shared(registry);
    ts::return_shared(stats_obj);
    ts::return_shared(campaign_obj);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = donations::E_STATS_MISMATCH, location = 0x0::donations)]
fun donate_aborts_with_mismatched_stats() {
    let (
        mut scenario,
        clock_obj,
        price_obj,
        _feed_id,
        fee_coins,
        campaign_id,
        _stats_id,
    ) = setup_donation_scenario(175, 9, 5_000);

    scenario.next_tx(DONOR);
    // Create a second campaign manually to get wrong stats
    let crowd_walrus_obj = scenario.take_shared<crowd_walrus::CrowdWalrus>();
    let app = crowd_walrus::get_app();
    let current_time = clock::timestamp_ms(&clock_obj);
    let other_payout = campaign::new_payout_policy(0, ADMIN, OWNER);
    let other_metadata = vec_map::from_keys_values(vector::empty<String>(), vector::empty<String>());
    let (mut other_campaign, other_owner_cap) = campaign::new(
        &app,
        sui_object::id(&crowd_walrus_obj),
        string::utf8(b"Other Campaign"),
        string::utf8(b"wrong stats"),
        string::utf8(b"wrong-stats"),
        other_metadata,
        500_000,
        other_payout,
        current_time,
        current_time + 1_000_000,
        &clock_obj,
        ts::ctx(&mut scenario),
    );
    ts::return_shared(crowd_walrus_obj);

    let other_stats_id = campaign_stats::create_for_campaign(
        &mut other_campaign,
        &clock_obj,
        ts::ctx(&mut scenario),
    );
    campaign::share(other_campaign);
    campaign::delete_owner_cap(other_owner_cap);

    // Need to start a new transaction before taking the shared stats
    scenario.next_tx(DONOR);
    let mut campaign_obj = scenario.take_shared_by_id<campaign::Campaign>(campaign_id);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let mut wrong_stats =
        scenario.take_shared_by_id<campaign_stats::CampaignStats>(other_stats_id);

    let donation_coin = coin::mint_for_testing<TestCoin>(90_000, ts::ctx(&mut scenario));

    donations::donate<TestCoin>(
        &mut campaign_obj,
        &mut wrong_stats,
        &registry,
        &clock_obj,
        donation_coin,
        &price_obj,
        0,
        std::option::none(),
        ts::ctx(&mut scenario),
    );

    ts::return_shared(wrong_stats);
    ts::return_shared(registry);
    ts::return_shared(campaign_obj);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
fun quote_usd_micro_uses_registry_metadata_and_override() {
    let max_age_ms = 4_000;
    let override_ms = 1_000;
    let (mut scenario, clock_obj, price_obj, fee_coins) =
        setup_quote_scenario(6, max_age_ms, true);

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let amount = 1_234_567;
    let usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        amount,
        &price_obj,
        std::option::some(override_ms),
    );
    let decimals = token_registry::decimals<TestCoin>(&registry);
    assert_eq!(decimals, 6);
    let feed_id = token_registry::pyth_feed_id<TestCoin>(&registry);
    let expected = price_oracle::quote_usd<TestCoin>(
        (amount as u128),
        decimals,
        feed_id,
        &price_obj,
        &clock_obj,
        override_ms,
    );
    assert_eq!(usd, expected);

    ts::return_shared(registry);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = price_oracle::E_PRICE_STALE, location = 0x0::price_oracle)]
fun quote_usd_micro_aborts_when_price_stale() {
    let max_age_ms = 1_000;
    let (mut scenario, mut clock_obj, price_obj, fee_coins) =
        setup_quote_scenario(9, max_age_ms, true);

    let publish_time = publish_time_ms(&price_obj);
    clock::set_for_testing(&mut clock_obj, publish_time + max_age_ms + 1);

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        1,
        &price_obj,
        std::option::none(),
    );

    ts::return_shared(registry);
    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = donations::E_TOKEN_DISABLED, location = 0x0::donations)]
fun quote_usd_micro_aborts_when_token_disabled() {
    let max_age_ms = 2_000;
    let (mut scenario, clock_obj, price_obj, fee_coins) =
        setup_quote_scenario(8, max_age_ms, false);

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        10,
        &price_obj,
        std::option::none(),
    );

    ts::return_shared(registry);
    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = price_oracle::E_FEED_ID_MISMATCH, location = 0x0::price_oracle)]
fun quote_usd_micro_aborts_when_feed_id_mismatched() {
    let (mut scenario, clock_obj, price_obj, feed_id, fee_coins) = setup_verified_price_info();
    let mut wrong_feed = clone_bytes(&feed_id);
    let first_byte = vector::borrow_mut(&mut wrong_feed, 0);
    *first_byte = *first_byte ^ 0x1;

    register_test_coin_with_feed(
        &mut scenario,
        &clock_obj,
        wrong_feed,
        6,
        2_000,
        true,
    );

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        100,
        &price_obj,
        std::option::none(),
    );

    ts::return_shared(registry);
    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = donations::E_COIN_NOT_FOUND, location = 0x0::donations)]
fun quote_usd_micro_aborts_when_token_not_in_registry() {
    let max_age_ms = 3_000;
    let (mut scenario, clock_obj, price_obj, fee_coins) =
        setup_quote_scenario(6, max_age_ms, true);

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    donations::quote_usd_micro<UnlistedCoin>(
        &registry,
        &clock_obj,
        5,
        &price_obj,
        std::option::none(),
    );

    ts::return_shared(registry);
    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = price_oracle::E_ZERO_AMOUNT, location = 0x0::price_oracle)]
fun quote_usd_micro_aborts_on_zero_amount() {
    let max_age_ms = 4_000;
    let (mut scenario, clock_obj, price_obj, fee_coins) =
        setup_quote_scenario(6, max_age_ms, true);

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        0,
        &price_obj,
        std::option::none(),
    );

    ts::return_shared(registry);
    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

public(package) fun configure_badge_config_for_donation_test(
    scenario: &mut ts::Scenario,
    clock_obj: &Clock,
    amount_thresholds_micro: vector<u64>,
    payment_thresholds: vector<u64>,
    image_uris: vector<String>,
) {
    scenario.next_tx(ADMIN);
    let crowd = scenario.take_shared<crowd_walrus::CrowdWalrus>();
    let config = badge_rewards::create_config_for_tests(
        sui_object::id(&crowd),
        ts::ctx(scenario),
    );
    badge_rewards::share_config(config);
    ts::return_shared(crowd);

    scenario.next_tx(ADMIN);
    let mut config_shared = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    crowd_walrus::update_badge_config_internal(
        &mut config_shared,
        &admin_cap,
        amount_thresholds_micro,
        payment_thresholds,
        image_uris,
        clock_obj,
    );
    ts::return_shared(config_shared);
    scenario.return_to_sender(admin_cap);
}

fun add_enabled_token(
    registry: &mut token_registry::TokenRegistry,
    admin_cap: &crowd_walrus::AdminCap,
    clock: &Clock,
    max_age_ms: u64,
) {
    crowd_walrus::add_token_internal<TestCoin>(
        registry,
        admin_cap,
        string::utf8(b"TEST"),
        string::utf8(b"Test Coin"),
        9,
        feed_id(7),
        max_age_ms,
        clock,
    );
    crowd_walrus::set_token_enabled_internal<TestCoin>(
        registry,
        admin_cap,
        true,
        clock,
    );
}

fun feed_id(val: u8): vector<u8> {
    let mut bytes = vector::empty<u8>();
    let mut i = 0;
    while (i < 32) {
        vector::push_back(&mut bytes, val);
        i = i + 1;
    };
    bytes
}

fun setup_quote_scenario(
    decimals: u8,
    max_age_ms: u64,
    enable_token: bool,
): (ts::Scenario, Clock, PriceInfoObject, coin::Coin<sui::sui::SUI>) {
    let (mut scenario, clock_obj, price_obj, feed_id, fee_coins) = setup_verified_price_info();
    register_test_coin_with_feed(
        &mut scenario,
        &clock_obj,
        clone_bytes(&feed_id),
        decimals,
        max_age_ms,
        enable_token,
    );
    (scenario, clock_obj, price_obj, fee_coins)
}

fun register_test_coin_with_feed(
    scenario: &mut ts::Scenario,
    clock_obj: &Clock,
    feed_id: vector<u8>,
    decimals: u8,
    max_age_ms: u64,
    enable_token: bool,
) {
    ts::next_tx(scenario, ADMIN);
    let crowd_walrus_id = crowd_walrus::create_and_share_crowd_walrus(ts::ctx(scenario));
    crowd_walrus::create_admin_cap_for_user(crowd_walrus_id, ADMIN, ts::ctx(scenario));

    ts::next_tx(scenario, ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();

    crowd_walrus::add_token_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"TEST"),
        string::utf8(b"Test Coin"),
        decimals,
        feed_id,
        max_age_ms,
        clock_obj,
    );
    if (enable_token) {
        crowd_walrus::set_token_enabled_internal<TestCoin>(
            &mut registry,
            &admin_cap,
            true,
            clock_obj,
        );
    };

    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
}

public(package) fun setup_donation_scenario(
    platform_bps: u16,
    decimals: u8,
    max_age_ms: u64,
): (
    ts::Scenario,
    Clock,
    PriceInfoObject,
    vector<u8>,
    coin::Coin<sui::sui::SUI>,
    sui_object::ID,
    sui_object::ID,
) {
    setup_donation_scenario_with_offsets(
        platform_bps,
        decimals,
        max_age_ms,
        0,
        1_000_000,
    )
}

public(package) fun setup_donation_scenario_with_offsets(
    platform_bps: u16,
    decimals: u8,
    max_age_ms: u64,
    start_offset_ms: u64,
    duration_ms: u64,
): (
    ts::Scenario,
    Clock,
    PriceInfoObject,
    vector<u8>,
    coin::Coin<sui::sui::SUI>,
    sui_object::ID,
    sui_object::ID,
) {
    let (mut scenario, clock_obj, price_obj, feed_id, fee_coins) =
        setup_verified_price_info();
    register_test_coin_with_feed(
        &mut scenario,
        &clock_obj,
        clone_bytes(&feed_id),
        decimals,
        max_age_ms,
        true,
    );

    scenario.next_tx(OWNER);
    let crowd = scenario.take_shared<crowd_walrus::CrowdWalrus>();
    let app = crowd_walrus::get_app();
    let metadata_keys = vector::empty<String>();
    let metadata_values = vector::empty<String>();
    let metadata = vec_map::from_keys_values(metadata_keys, metadata_values);
    let now = clock::timestamp_ms(&clock_obj);
    let start_time = now + start_offset_ms;
    let end_time = start_time + duration_ms;
    let payout_policy = campaign::new_payout_policy(platform_bps, ADMIN, OWNER);
    let (mut campaign, owner_cap) = campaign::new(
        &app,
        sui_object::id(&crowd),
        string::utf8(b"Donations Flow"),
        string::utf8(b"Lock parameters"),
        string::utf8(b"donate-flow"),
        metadata,
        1_000_000,
        payout_policy,
        start_time,
        end_time,
        &clock_obj,
        ts::ctx(&mut scenario),
    );
    let campaign_id = sui_object::id(&campaign);
    let stats_id =
        campaign_stats::create_for_campaign(&mut campaign, &clock_obj, ts::ctx(&mut scenario));
    campaign::share(campaign);
    ts::return_shared(crowd);
    campaign::delete_owner_cap(owner_cap);

    (
        scenario,
        clock_obj,
        price_obj,
        feed_id,
        fee_coins,
        campaign_id,
        stats_id,
    )
}

fun clone_bytes(bytes: &vector<u8>): vector<u8> {
    let mut out = vector::empty<u8>();
    let len = vector::length(bytes);
    let mut i = 0;
    while (i < len) {
        vector::push_back(&mut out, *vector::borrow(bytes, i));
        i = i + 1;
    };
    out
}

public(package) fun cleanup_quote_scenario(
    scenario: ts::Scenario,
    clock_obj: Clock,
    price_obj: PriceInfoObject,
    fee_coins: coin::Coin<sui::sui::SUI>,
) {
    price_info::destroy(price_obj);
    clock::destroy_for_testing(clock_obj);
    coin::burn_for_testing(fee_coins);
    ts::end(scenario);
}

fun setup_verified_price_info(): (
    ts::Scenario,
    Clock,
    PriceInfoObject,
    vector<u8>,
    coin::Coin<sui::sui::SUI>,
) {
    let governance_emitter =
        x"5d1f252d5de865279b00c84bce362774c2804294ed53299bc4a0389a5defef92";
    let data_sources = pyth_tests::data_sources_for_test_vaa();
    let guardians = vector[x"beFA429d57cD18b7F8A4d91A2da9AB4AF05d0FBe"];

    let (mut scenario, fee_coins, mut clock_obj) =
        pyth_tests::setup_test(500, 23, governance_emitter, data_sources, guardians, 50, 0);

    ts::next_tx(&mut scenario, DEPLOYER);
    let (mut pyth_state, worm_state) = pyth_tests::take_wormhole_and_pyth_states(&scenario);
    let verified_vaas = verified_test_vaas(&worm_state, &clock_obj);

    pyth::create_price_feeds(
        &mut pyth_state,
        verified_vaas,
        &clock_obj,
        ts::ctx(&mut scenario),
    );

    ts::return_shared(pyth_state);
    ts::return_shared(worm_state);

    ts::next_tx(&mut scenario, DEPLOYER);
    let price_obj = ts::take_shared<PriceInfoObject>(&scenario);

    let price_info_data = price_info::get_price_info_from_price_info_object(&price_obj);
    let price_feed_ref = price_info::get_price_feed(&price_info_data);
    let spot_price = price_feed::get_price(price_feed_ref);
    let publish_time = pyth_price::get_timestamp(&spot_price);
    clock::set_for_testing(&mut clock_obj, publish_time_ms_from_secs(publish_time) + 500);

    let feed_id = price_identifier::get_bytes(&price_info::get_price_identifier(&price_info_data));

    (scenario, clock_obj, price_obj, feed_id, fee_coins)
}

fun publish_time_ms(price_obj: &PriceInfoObject): u64 {
    let price_info_data = price_info::get_price_info_from_price_info_object(price_obj);
    let price_feed_ref = price_info::get_price_feed(&price_info_data);
    let spot_price = price_feed::get_price(price_feed_ref);
    publish_time_ms_from_secs(pyth_price::get_timestamp(&spot_price))
}

fun publish_time_ms_from_secs(seconds: u64): u64 {
    seconds * 1_000
}

fun verified_test_vaas(worm_state: &WormState, clock_obj: &Clock): vector<VAA> {
    let mut vaa_bytes = test_vaa_bytes();
    let mut reversed = vector::empty<VAA>();
    while (!vector::is_empty(&vaa_bytes)) {
        let bytes = vector::pop_back(&mut vaa_bytes);
        let verified = vaa::parse_and_verify(worm_state, bytes, clock_obj);
        vector::push_back(&mut reversed, verified);
    };
    vector::destroy_empty(vaa_bytes);

    let mut verified = vector::empty<VAA>();
    while (!vector::is_empty(&reversed)) {
        let item = vector::pop_back(&mut reversed);
        vector::push_back(&mut verified, item);
    };
    vector::destroy_empty(reversed);
    verified
}

fun test_vaa_bytes(): vector<vector<u8>> {
    vector[
        x"0100000000010036eb563b80a24f4253bee6150eb8924e4bdf6e4fa1dfc759a6664d2e865b4b134651a7b021b7f1ce3bd078070b688b6f2e37ce2de0d9b48e6a78684561e49d5201527e4f9b00000001001171f8dcb863d176e2c420ad6610cf687359612b6fb392e0642b0ca6b1f186aa3b0000000000000001005032574800030000000102000400951436e0be37536be96f0896366089506a59763d036728332d3e3038047851aea7c6c75c89f14810ec1c54c03ab8f1864a4c4032791f05747f560faec380a695d1000000000000049a0000000000000008fffffffb00000000000005dc0000000000000003000000000100000001000000006329c0eb000000006329c0e9000000006329c0e400000000000006150000000000000007215258d81468614f6b7e194c5d145609394f67b041e93e6695dcc616faadd0603b9551a68d01d954d6387aff4df1529027ffb2fee413082e509feb29cc4904fe000000000000041a0000000000000003fffffffb00000000000005cb0000000000000003010000000100000001000000006329c0eb000000006329c0e9000000006329c0e4000000000000048600000000000000078ac9cf3ab299af710d735163726fdae0db8465280502eb9f801f74b3c1bd190333832fad6e36eb05a8972fe5f219b27b5b2bb2230a79ce79beb4c5c5e7ecc76d00000000000003f20000000000000002fffffffb00000000000005e70000000000000003010000000100000001000000006329c0eb000000006329c0e9000000006329c0e40000000000000685000000000000000861db714e9ff987b6fedf00d01f9fea6db7c30632d6fc83b7bc9459d7192bc44a21a28b4c6619968bd8c20e95b0aaed7df2187fd310275347e0376a2cd7427db800000000000006cb0000000000000001fffffffb00000000000005e40000000000000003010000000100000001000000006329c0eb000000006329c0e9000000006329c0e400000000000007970000000000000001"
    ]
}
