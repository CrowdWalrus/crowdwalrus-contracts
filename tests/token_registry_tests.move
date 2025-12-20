#[test_only]
module crowd_walrus::token_registry_tests;

use crowd_walrus::crowd_walrus::{Self as crowd_walrus};
use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::token_registry::{Self as token_registry};
use std::string::{Self as string};
use std::unit_test::assert_eq;
use sui::clock::{Self as clock, Clock};
use sui::event;
use sui::object::{Self as sui_object};
use sui::test_scenario::{Self as ts};

const ADMIN: address = @0xA;
const OTHER: address = @0xB;

public struct TestCoin has drop, store {}
public struct SecondCoin has drop, store {}

#[test]
fun test_add_coin_registers_metadata() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let mut clock = scenario.take_shared<Clock>();
    clock::set_for_testing(&mut clock, 1_111);
    let events_before =
        vector::length(&event::events_by_type<token_registry::TokenAdded>());

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

    let events_after = event::events_by_type<token_registry::TokenAdded>();
    assert_eq!(vector::length(&events_after), events_before + 1);
    let recorded = vector::borrow(&events_after, events_before);
    assert_eq!(
        token_registry::token_added_coin_type(recorded),
        token_registry::coin_type_canonical<TestCoin>(),
    );
    assert_eq!(
        token_registry::token_added_symbol(recorded),
        string::utf8(b"TEST"),
    );
    assert_eq!(
        token_registry::token_added_name(recorded),
        string::utf8(b"Test Coin"),
    );
    assert_eq!(token_registry::token_added_decimals(recorded), 9);
    assert_eq!(token_registry::token_added_pyth_feed_id(recorded), feed_id(1));
    assert_eq!(token_registry::token_added_max_age_ms(recorded), 1_000);
    assert!(!token_registry::token_added_enabled(recorded));
    assert_eq!(token_registry::token_added_timestamp_ms(recorded), 1_111);

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
    let mut clock = scenario.take_shared<Clock>();
    clock::set_for_testing(&mut clock, 2_000);

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

    clock::set_for_testing(&mut clock, 3_333);
    let before_updated =
        vector::length(&event::events_by_type<token_registry::TokenUpdated>());

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

    let updated_events = event::events_by_type<token_registry::TokenUpdated>();
    assert_eq!(vector::length(&updated_events), before_updated + 1);
    let recorded = vector::borrow(&updated_events, before_updated);
    assert_eq!(
        token_registry::token_updated_coin_type(recorded),
        token_registry::coin_type_canonical<TestCoin>(),
    );
    assert_eq!(
        token_registry::token_updated_symbol(recorded),
        string::utf8(b"TNEW"),
    );
    assert_eq!(
        token_registry::token_updated_name(recorded),
        string::utf8(b"Test Coin Renamed"),
    );
    assert_eq!(token_registry::token_updated_decimals(recorded), 6);
    assert_eq!(token_registry::token_updated_pyth_feed_id(recorded), feed_id(4));
    assert_eq!(token_registry::token_updated_max_age_ms(recorded), 5_000);
    assert_eq!(token_registry::token_updated_timestamp_ms(recorded), 3_333);

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
    let mut clock = scenario.take_shared<Clock>();
    clock::set_for_testing(&mut clock, 4_444);

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

    clock::set_for_testing(&mut clock, 5_555);
    let enabled_before =
        vector::length(&event::events_by_type<token_registry::TokenEnabled>());

    crowd_walrus::set_token_enabled_internal<SecondCoin>(
        &mut registry,
        &admin_cap,
        true,
        &clock,
    );
    assert!(token_registry::is_enabled<SecondCoin>(&registry));

    let enabled_events = event::events_by_type<token_registry::TokenEnabled>();
    assert_eq!(vector::length(&enabled_events), enabled_before + 1);
    let enabled_event = vector::borrow(&enabled_events, enabled_before);
    assert_eq!(
        token_registry::token_enabled_coin_type(enabled_event),
        token_registry::coin_type_canonical<SecondCoin>(),
    );
    assert_eq!(
        token_registry::token_enabled_symbol(enabled_event),
        string::utf8(b"SCND"),
    );
    assert_eq!(token_registry::token_enabled_timestamp_ms(enabled_event), 5_555);

    clock::set_for_testing(&mut clock, 6_666);
    let disabled_before =
        vector::length(&event::events_by_type<token_registry::TokenDisabled>());

    crowd_walrus::set_token_enabled_internal<SecondCoin>(
        &mut registry,
        &admin_cap,
        false,
        &clock,
    );
    assert!(!token_registry::is_enabled<SecondCoin>(&registry));

    let disabled_events = event::events_by_type<token_registry::TokenDisabled>();
    assert_eq!(vector::length(&disabled_events), disabled_before + 1);
    let disabled_event = vector::borrow(&disabled_events, disabled_before);
    assert_eq!(
        token_registry::token_disabled_coin_type(disabled_event),
        token_registry::coin_type_canonical<SecondCoin>(),
    );
    assert_eq!(
        token_registry::token_disabled_symbol(disabled_event),
        string::utf8(b"SCND"),
    );
    assert_eq!(token_registry::token_disabled_timestamp_ms(disabled_event), 6_666);

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
    let mut clock = scenario.take_shared<Clock>();
    clock::set_for_testing(&mut clock, 7_000);

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

    clock::set_for_testing(&mut clock, 8_000);
    let before_updated =
        vector::length(&event::events_by_type<token_registry::TokenUpdated>());

    crowd_walrus::set_token_max_age_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        500,
        &clock,
    );
    assert_eq!(token_registry::max_age_ms<TestCoin>(&registry), 500);

    let updated_events = event::events_by_type<token_registry::TokenUpdated>();
    assert_eq!(vector::length(&updated_events), before_updated + 1);
    let recorded = vector::borrow(&updated_events, before_updated);
    assert_eq!(
        token_registry::token_updated_coin_type(recorded),
        token_registry::coin_type_canonical<TestCoin>(),
    );
    assert_eq!(
        token_registry::token_updated_symbol(recorded),
        string::utf8(b"TEST"),
    );
    assert_eq!(
        token_registry::token_updated_name(recorded),
        string::utf8(b"Test Coin"),
    );
    assert_eq!(token_registry::token_updated_decimals(recorded), 9);
    assert_eq!(token_registry::token_updated_pyth_feed_id(recorded), feed_id(6));
    assert_eq!(token_registry::token_updated_max_age_ms(recorded), 500);
    assert_eq!(token_registry::token_updated_timestamp_ms(recorded), 8_000);

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

#[test, expected_failure(
    abort_code = crowd_walrus::E_NOT_AUTHORIZED,
    location = 0x0::crowd_walrus
)]
fun test_add_coin_requires_matching_admin_cap() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(ADMIN);
    let registry_handle = scenario.take_shared<token_registry::TokenRegistry>();
    let original_registry_id = sui_object::id(&registry_handle);
    ts::return_shared(registry_handle);

    // Mint an unrelated CrowdWalrus deployment and grant OTHER an AdminCap for it.
    scenario.next_tx(OTHER);
    let other_crowd_id = crowd_walrus::create_and_share_crowd_walrus(ts::ctx(&mut scenario));
    crowd_walrus::create_admin_cap_for_user(other_crowd_id, OTHER, ts::ctx(&mut scenario));

    scenario.next_tx(OTHER);
    let mut registry =
        scenario.take_shared_by_id<token_registry::TokenRegistry>(original_registry_id);
    let wrong_admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::add_token_internal<TestCoin>(
        &mut registry,
        &wrong_admin_cap,
        string::utf8(b"FAIL"),
        string::utf8(b"Should Fail"),
        9,
        feed_id(9),
        1_000,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(wrong_admin_cap);
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
