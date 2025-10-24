#[test_only]
#[allow(unused_const)]
module crowd_walrus::campaign_stats_tests;

use crowd_walrus::campaign::{Self as campaign, Campaign};
use crowd_walrus::campaign_stats::{Self as campaign_stats};
use crowd_walrus::crowd_walrus_tests;
use std::string::utf8;
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::object::{Self as sui_object};
use sui::test_scenario::{Self as ts, ctx};

const ADMIN: address = @0xA;
const USER1: address = @0xB;
const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;

#[test]
public fun test_create_for_campaign_happy_path() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Stats Ready"),
        utf8(b"Campaign stats creation"),
        b"stats-ready",
        vector::empty(),
        vector::empty(),
        1_000,
        USER1,
        0,
        U64_MAX,
    );

    scenario.next_tx(USER1);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let clock = scenario.take_shared<Clock>();

    assert_eq!(sui_object::id_to_address(&campaign::stats_id(&campaign_obj)), @0x0);

    let stats = campaign_stats::create_for_campaign(
        &mut campaign_obj,
        &clock,
        ctx(&mut scenario),
    );

    let stats_id = sui_object::id(&stats);
    assert_eq!(campaign::stats_id(&campaign_obj), stats_id);

    sui::transfer::public_share_object(stats);

    ts::return_shared(campaign_obj);
    ts::return_shared(clock);

    let effects = ts::end(scenario);

    assert_eq!(ts::num_user_events(&effects), 1);
    // NOTE: test_scenario currently exposes the user event count only.
    // Later tasks can decode BCS when helper lands in sui-framework.
}

#[test, expected_failure(
    abort_code = campaign_stats::E_STATS_ALREADY_EXISTS,
    location = 0x0::campaign_stats
)]
public fun test_create_for_campaign_twice_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Stats Twice"),
        utf8(b"Prevent duplicate stats"),
        b"stats-twice",
        vector::empty(),
        vector::empty(),
        10_000,
        USER1,
        0,
        U64_MAX,
    );

    scenario.next_tx(USER1);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let clock = scenario.take_shared<Clock>();

    let stats = campaign_stats::create_for_campaign(
        &mut campaign_obj,
        &clock,
        ctx(&mut scenario),
    );

    sui::transfer::public_share_object(stats);

    ts::return_shared(campaign_obj);
    ts::return_shared(clock);

    scenario.next_tx(USER1);
    let mut campaign_again = scenario.take_shared_by_id<Campaign>(campaign_id);
    let clock_again = scenario.take_shared<Clock>();

    // This call should abort because stats were already created.
    let stats_again = campaign_stats::create_for_campaign(
        &mut campaign_again,
        &clock_again,
        ctx(&mut scenario),
    );

    sui::transfer::public_share_object(stats_again);

    ts::return_shared(campaign_again);
    ts::return_shared(clock_again);
    scenario.end();
}
