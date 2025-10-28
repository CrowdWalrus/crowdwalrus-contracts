#[test_only]
module crowd_walrus::badge_rewards_tests;

use crowd_walrus::badge_rewards::{Self as badge_rewards};
use crowd_walrus::crowd_walrus;
use crowd_walrus::crowd_walrus_tests;
use std::string::{Self as string};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::object as sui_object;
use sui::test_scenario::{Self as ts, Scenario, ctx};

const ADMIN: address = @0xA;
const OTHER: address = @0xB;

#[test]
fun test_update_badge_config_sets_fields_and_emits_event() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        vector[
            100_000,
            250_000,
            500_000,
            1_000_000,
            2_000_000,
        ],
        vector[1, 5, 10, 20, 40],
        vector[
            string::utf8(b"walrus://badge1"),
            string::utf8(b"walrus://badge2"),
            string::utf8(b"walrus://badge3"),
            string::utf8(b"walrus://badge4"),
            string::utf8(b"walrus://badge5"),
        ],
        &clock,
    );

    let amounts = badge_rewards::amount_thresholds_micro(&config);
    assert_eq!(vector::length(amounts), badge_rewards::level_count());
    assert_eq!(*vector::borrow(amounts, 0), 100_000);
    assert_eq!(*vector::borrow(amounts, 4), 2_000_000);

    let payments = badge_rewards::payment_thresholds(&config);
    assert_eq!(*vector::borrow(payments, 0), 1);
    assert_eq!(*vector::borrow(payments, 2), 10);
    assert_eq!(*vector::borrow(payments, 4), 40);

    let uris = badge_rewards::image_uris(&config);
    assert_eq!(vector::length(uris), badge_rewards::level_count());
    assert_eq!(*vector::borrow(uris, 2), string::utf8(b"walrus://badge3"));

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);

    let effects = ts::end(scenario);
    assert_eq!(ts::num_user_events(&effects), 1);
}

#[test, expected_failure(
    abort_code = badge_rewards::E_BAD_LENGTH,
    location = 0x0::badge_rewards
)]
fun test_update_badge_config_requires_five_entries() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        vector[100, 200, 300],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"a"),
            string::utf8(b"b"),
            string::utf8(b"c"),
            string::utf8(b"d"),
            string::utf8(b"e"),
        ],
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
    abort 0
}

#[test, expected_failure(
    abort_code = badge_rewards::E_NOT_ASCENDING,
    location = 0x0::badge_rewards
)]
fun test_update_badge_config_amounts_must_increase() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        vector[100, 100, 200, 300, 400],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"a"),
            string::utf8(b"b"),
            string::utf8(b"c"),
            string::utf8(b"d"),
            string::utf8(b"e"),
        ],
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
    abort 0
}

#[test, expected_failure(
    abort_code = badge_rewards::E_NOT_ASCENDING,
    location = 0x0::badge_rewards
)]
fun test_update_badge_config_payments_must_increase() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        vector[100, 200, 300, 400, 500],
        vector[1, 1, 2, 3, 4],
        vector[
            string::utf8(b"a"),
            string::utf8(b"b"),
            string::utf8(b"c"),
            string::utf8(b"d"),
            string::utf8(b"e"),
        ],
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
    abort 0
}

#[test, expected_failure(
    abort_code = badge_rewards::E_EMPTY_URI,
    location = 0x0::badge_rewards
)]
fun test_update_badge_config_requires_non_empty_uris() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        vector[100, 200, 300, 400, 500],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"a"),
            string::utf8(b""),
            string::utf8(b"c"),
            string::utf8(b"d"),
            string::utf8(b"e"),
        ],
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
    abort 0
}

#[test, expected_failure(
    abort_code = crowd_walrus::E_NOT_AUTHORIZED,
    location = 0x0::crowd_walrus
)]
fun test_update_badge_config_requires_matching_admin_cap() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    // Create a separate CrowdWalrus deployment and admin cap for OTHER.
    scenario.next_tx(OTHER);
    let other_crowd_id = crowd_walrus::create_and_share_crowd_walrus(ctx(&mut scenario));
    crowd_walrus::create_admin_cap_for_user(other_crowd_id, OTHER, ctx(&mut scenario));

    scenario.next_tx(OTHER);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let wrong_admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &wrong_admin_cap,
        vector[100, 200, 300, 400, 500],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"a"),
            string::utf8(b"b"),
            string::utf8(b"c"),
            string::utf8(b"d"),
            string::utf8(b"e"),
        ],
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(wrong_admin_cap);
    ts::end(scenario);
    abort 0
}

fun bootstrap_badge_config(scenario: &mut Scenario) {
    scenario.next_tx(ADMIN);
    let crowd = scenario.take_shared<crowd_walrus::CrowdWalrus>();
    let config = badge_rewards::create_config_for_tests(
        sui_object::id(&crowd),
        ctx(scenario),
    );
    badge_rewards::share_config(config);
    ts::return_shared(crowd);
}
