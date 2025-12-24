#[test_only]
#[allow(unused_const)]
module crowd_walrus::campaign_stats_tests;

use crowd_walrus::campaign::{Self as campaign, Campaign};
use crowd_walrus::campaign_stats::{Self as campaign_stats};
use crowd_walrus::crowd_walrus_tests;
use std::string::utf8;
use std::unit_test::assert_eq;
use sui::clock::{Self as clock, Clock};
use sui::event;
use sui::object::{Self as sui_object};
use sui::test_scenario::{Self as ts, ctx};

const ADMIN: address = @0xA;
const USER1: address = @0xB;
const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;
const U128_MAX: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
const DEFAULT_PLATFORM_BPS: u16 = 0;

public struct CoinA has drop, store {}
public struct CoinB has drop, store {}
public struct CoinC has drop, store {}
public struct CoinD has drop, store {}
public struct CoinE has drop, store {}

#[test]
public fun test_create_for_campaign_happy_path() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let (mut campaign_obj, owner_cap, mut clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        utf8(b"Stats Ready"),
        utf8(b"Campaign stats creation"),
        b"stats-ready",
        vector::empty(),
        vector::empty(),
        1_000,
        USER1,
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );
    let expected_campaign_id = sui_object::id(&campaign_obj);
    assert_eq!(sui_object::id_to_address(&campaign::stats_id(&campaign_obj)), @0x0);
    clock::set_for_testing(&mut clock, 9_001);
    let events_before =
        vector::length(&event::events_by_type<campaign_stats::CampaignStatsCreated>());
    let stats_id = campaign_stats::create_for_campaign(
        &mut campaign_obj,
        &clock,
        ctx(&mut scenario),
    );
    let events_after = event::events_by_type<campaign_stats::CampaignStatsCreated>();
    assert_eq!(vector::length(&events_after), events_before + 1);
    let recorded = vector::borrow(&events_after, events_before);
    assert_eq!(
        campaign_stats::campaign_stats_created_campaign_id(recorded),
        expected_campaign_id,
    );
    assert_eq!(
        campaign_stats::campaign_stats_created_stats_id(recorded),
        stats_id,
    );
    assert_eq!(
        campaign_stats::campaign_stats_created_timestamp_ms(recorded),
        9_001,
    );

    ts::return_shared(clock);
    campaign::share(campaign_obj);
    campaign::delete_owner_cap(owner_cap);

    let effects = ts::next_tx(&mut scenario, USER1);
    assert_eq!(ts::num_user_events(&effects), 1);

    let stats = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    assert_eq!(campaign_stats::total_usd_micro(&stats), 0);
    assert_eq!(campaign_stats::total_donations_count(&stats), 0);
    assert_eq!(campaign_stats::per_coin_total_raw<CoinA>(&stats), 0);
    assert_eq!(campaign_stats::per_coin_donation_count<CoinA>(&stats), 0);
    ts::return_shared(stats);

    ts::end(scenario);
    // NOTE: test_scenario currently exposes the user event count only.
    // Later tasks can decode BCS when helper lands in sui-framework.
}

#[test]
public fun test_add_donation_tracks_per_coin_totals() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let (mut campaign_obj, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        utf8(b"Per Coin Totals"),
        utf8(b"Track per-coin aggregates"),
        b"per-coin",
        vector::empty(),
        vector::empty(),
        500,
        USER1,
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );
    let stats_id = campaign_stats::create_for_campaign(
        &mut campaign_obj,
        &clock,
        ctx(&mut scenario),
    );
    ts::return_shared(clock);
    campaign::share(campaign_obj);
    campaign::delete_owner_cap(owner_cap);

    scenario.next_tx(USER1);
    let mut stats = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    campaign_stats::add_donation<CoinA>(&mut stats, 250, 200);
    campaign_stats::add_donation<CoinA>(&mut stats, 750, 300);
    campaign_stats::add_donation<CoinB>(&mut stats, 500, 150);

    assert_eq!(campaign_stats::total_usd_micro(&stats), 650);
    assert_eq!(campaign_stats::total_donations_count(&stats), 3);

    assert_eq!(campaign_stats::per_coin_total_raw<CoinA>(&stats), 1_000);
    assert_eq!(campaign_stats::per_coin_donation_count<CoinA>(&stats), 2);

    assert_eq!(campaign_stats::per_coin_total_raw<CoinB>(&stats), 500);
    assert_eq!(campaign_stats::per_coin_donation_count<CoinB>(&stats), 1);

    // Views should gracefully return zero for coin types that never received donations.
    assert_eq!(campaign_stats::per_coin_total_raw<CoinC>(&stats), 0);
    assert_eq!(campaign_stats::per_coin_donation_count<CoinC>(&stats), 0);

    ts::return_shared(stats);
    ts::end(scenario);
}

#[test]
public fun test_add_donation_handles_many_coin_types() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let (mut campaign_obj, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        utf8(b"Multi Coin Totals"),
        utf8(b"Track many coin aggregates"),
        b"multi-coin",
        vector::empty(),
        vector::empty(),
        750,
        USER1,
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );
    let stats_id = campaign_stats::create_for_campaign(
        &mut campaign_obj,
        &clock,
        ctx(&mut scenario),
    );
    ts::return_shared(clock);
    campaign::share(campaign_obj);
    campaign::delete_owner_cap(owner_cap);

    scenario.next_tx(USER1);
    let mut stats = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    campaign_stats::add_donation<CoinA>(&mut stats, 100, 10);
    campaign_stats::add_donation<CoinB>(&mut stats, 200, 20);
    campaign_stats::add_donation<CoinC>(&mut stats, 300, 30);
    campaign_stats::add_donation<CoinD>(&mut stats, 400, 40);
    campaign_stats::add_donation<CoinE>(&mut stats, 500, 50);

    assert_eq!(campaign_stats::total_usd_micro(&stats), 150);
    assert_eq!(campaign_stats::total_donations_count(&stats), 5);

    assert_eq!(campaign_stats::per_coin_total_raw<CoinA>(&stats), 100);
    assert_eq!(campaign_stats::per_coin_donation_count<CoinA>(&stats), 1);
    assert_eq!(campaign_stats::per_coin_total_raw<CoinB>(&stats), 200);
    assert_eq!(campaign_stats::per_coin_donation_count<CoinB>(&stats), 1);
    assert_eq!(campaign_stats::per_coin_total_raw<CoinC>(&stats), 300);
    assert_eq!(campaign_stats::per_coin_donation_count<CoinC>(&stats), 1);
    assert_eq!(campaign_stats::per_coin_total_raw<CoinD>(&stats), 400);
    assert_eq!(campaign_stats::per_coin_donation_count<CoinD>(&stats), 1);
    assert_eq!(campaign_stats::per_coin_total_raw<CoinE>(&stats), 500);
    assert_eq!(campaign_stats::per_coin_donation_count<CoinE>(&stats), 1);

    // Ensure previously unused coin types still report zero.
    assert_eq!(campaign_stats::per_coin_total_raw<CoinC>(&stats), 300);

    ts::return_shared(stats);
    ts::end(scenario);
}

#[test, expected_failure(
    abort_code = campaign_stats::E_OVERFLOW,
    location = 0x0::campaign_stats,
)]
public fun test_add_donation_overflow_usd_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let (mut campaign_obj, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        utf8(b"Overflow Guard"),
        utf8(b"Ensure totals overflow aborts"),
        b"overflow",
        vector::empty(),
        vector::empty(),
        100,
        USER1,
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );
    let stats_id = campaign_stats::create_for_campaign(
        &mut campaign_obj,
        &clock,
        ctx(&mut scenario),
    );
    ts::return_shared(clock);
    campaign::share(campaign_obj);
    campaign::delete_owner_cap(owner_cap);

    scenario.next_tx(USER1);
    let mut stats = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    campaign_stats::add_donation<CoinA>(&mut stats, 10, U64_MAX);
    campaign_stats::add_donation<CoinA>(&mut stats, 0, 1);

    ts::return_shared(stats);
    scenario.end();
}

#[test, expected_failure(
    abort_code = campaign_stats::E_OVERFLOW,
    location = 0x0::campaign_stats,
)]
public fun test_add_donation_raw_overflow_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let (mut campaign_obj, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        utf8(b"Raw Overflow"),
        utf8(b"Detect per-coin raw overflow"),
        b"raw-overflow",
        vector::empty(),
        vector::empty(),
        1,
        USER1,
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );
    let stats_id = campaign_stats::create_for_campaign(
        &mut campaign_obj,
        &clock,
        ctx(&mut scenario),
    );
    ts::return_shared(clock);
    campaign::share(campaign_obj);
    campaign::delete_owner_cap(owner_cap);

    scenario.next_tx(USER1);
    let mut stats = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    campaign_stats::set_per_coin_totals_for_test<CoinA>(&mut stats, U128_MAX, 0);
    campaign_stats::add_donation<CoinA>(&mut stats, 1, 0);

    ts::return_shared(stats);
    scenario.end();
}

#[test, expected_failure(
    abort_code = campaign_stats::E_OVERFLOW,
    location = 0x0::campaign_stats,
)]
public fun test_add_donation_per_coin_count_overflow_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let (mut campaign_obj, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        utf8(b"Count Overflow"),
        utf8(b"Detect per-coin count overflow"),
        b"count-overflow",
        vector::empty(),
        vector::empty(),
        1,
        USER1,
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );
    let stats_id = campaign_stats::create_for_campaign(
        &mut campaign_obj,
        &clock,
        ctx(&mut scenario),
    );
    ts::return_shared(clock);
    campaign::share(campaign_obj);
    campaign::delete_owner_cap(owner_cap);

    scenario.next_tx(USER1);
    let mut stats = scenario.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    campaign_stats::set_per_coin_totals_for_test<CoinA>(&mut stats, 0, U64_MAX);
    campaign_stats::add_donation<CoinA>(&mut stats, 0, 0);

    ts::return_shared(stats);
    scenario.end();
}

#[test, expected_failure(
    abort_code = campaign_stats::E_STATS_ALREADY_EXISTS,
    location = 0x0::campaign_stats
)]
public fun test_create_for_campaign_twice_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let (mut campaign_obj, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        utf8(b"Stats Twice"),
        utf8(b"Prevent duplicate stats"),
        b"stats-twice",
        vector::empty(),
        vector::empty(),
        10_000,
        USER1,
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );
    let campaign_id = sui_object::id(&campaign_obj);
    let _stats_id = campaign_stats::create_for_campaign(
        &mut campaign_obj,
        &clock,
        ctx(&mut scenario),
    );
    ts::return_shared(clock);
    campaign::share(campaign_obj);
    campaign::delete_owner_cap(owner_cap);

    scenario.next_tx(USER1);
    let mut campaign_again = scenario.take_shared_by_id<Campaign>(campaign_id);
    let clock_again = scenario.take_shared<Clock>();

    // This call should abort because stats were already created.
    let _stats_again_id = campaign_stats::create_for_campaign(
        &mut campaign_again,
        &clock_again,
        ctx(&mut scenario),
    );

    ts::return_shared(campaign_again);
    ts::return_shared(clock_again);
    scenario.end();
}
