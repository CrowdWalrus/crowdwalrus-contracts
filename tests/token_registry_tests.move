#[test_only]
module crowd_walrus::token_registry_tests;

use crowd_walrus::crowd_walrus::{Self as crowd_walrus};
use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::token_registry::{Self as token_registry};
use std::string::{Self as string};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::test_scenario::{Self as ts};

const ADMIN: address = @0xA;

public struct TestCoin has drop, store {}
public struct SecondCoin has drop, store {}

#[test]
fun test_add_coin_registers_metadata() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::add_token_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"TEST"),
        string::utf8(b"Test Coin"),
        9,
        feed_id(1),
        1_000,
        &clock,
    );

    assert!(token_registry::contains<TestCoin>(&registry));
    assert_eq!(token_registry::symbol<TestCoin>(&registry), string::utf8(b"TEST"));
    assert_eq!(token_registry::name<TestCoin>(&registry), string::utf8(b"Test Coin"));
    assert_eq!(token_registry::decimals<TestCoin>(&registry), 9);
    assert_eq!(token_registry::pyth_feed_id<TestCoin>(&registry), feed_id(1));
    assert_eq!(token_registry::max_age_ms<TestCoin>(&registry), 1_000);
    assert!(!token_registry::is_enabled<TestCoin>(&registry));

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = token_registry::E_COIN_EXISTS, location = 0x0::token_registry)]
fun test_add_coin_duplicate_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::add_token_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"TEST"),
        string::utf8(b"Test Coin"),
        9,
        feed_id(2),
        1_000,
        &clock,
    );

    crowd_walrus::add_token_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"TEST2"),
        string::utf8(b"Test Coin 2"),
        9,
        feed_id(2),
        1_000,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test]
fun test_update_metadata_changes_fields() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::add_token_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"TEST"),
        string::utf8(b"Test Coin"),
        9,
        feed_id(3),
        5_000,
        &clock,
    );

    crowd_walrus::update_token_metadata_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"TNEW"),
        string::utf8(b"Test Coin Renamed"),
        6,
        feed_id(4),
        &clock,
    );

    assert_eq!(token_registry::symbol<TestCoin>(&registry), string::utf8(b"TNEW"));
    assert_eq!(token_registry::name<TestCoin>(&registry), string::utf8(b"Test Coin Renamed"));
    assert_eq!(token_registry::decimals<TestCoin>(&registry), 6);
    assert_eq!(token_registry::pyth_feed_id<TestCoin>(&registry), feed_id(4));
    assert_eq!(token_registry::max_age_ms<TestCoin>(&registry), 5_000);

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test]
fun test_set_enabled_toggles_flag() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::add_token_internal<SecondCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"SCND"),
        string::utf8(b"Second Coin"),
        6,
        feed_id(5),
        2_000,
        &clock,
    );

    crowd_walrus::set_token_enabled_internal<SecondCoin>(
        &mut registry,
        &admin_cap,
        true,
        &clock,
    );
    assert!(token_registry::is_enabled<SecondCoin>(&registry));

    crowd_walrus::set_token_enabled_internal<SecondCoin>(
        &mut registry,
        &admin_cap,
        false,
        &clock,
    );
    assert!(!token_registry::is_enabled<SecondCoin>(&registry));

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test]
fun test_set_max_age_updates_value() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::add_token_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"TEST"),
        string::utf8(b"Test Coin"),
        9,
        feed_id(6),
        1_000,
        &clock,
    );

    crowd_walrus::set_token_max_age_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        500,
        &clock,
    );
    assert_eq!(token_registry::max_age_ms<TestCoin>(&registry), 500);

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = token_registry::E_BAD_FEED_ID, location = 0x0::token_registry)]
fun test_add_coin_bad_feed_length_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::add_token_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"TEST"),
        string::utf8(b"Test Coin"),
        9,
        short_feed(),
        1_000,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = token_registry::E_BAD_DECIMALS, location = 0x0::token_registry)]
fun test_add_coin_bad_decimals_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::add_token_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"TEST"),
        string::utf8(b"Test Coin"),
        39,
        feed_id(7),
        1_000,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = token_registry::E_COIN_NOT_FOUND, location = 0x0::token_registry)]
fun test_set_enabled_missing_coin_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::set_token_enabled_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        true,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
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

fun short_feed(): vector<u8> {
    let mut bytes = vector::empty<u8>();
    vector::push_back(&mut bytes, 0);
    vector::push_back(&mut bytes, 1);
    bytes
}
