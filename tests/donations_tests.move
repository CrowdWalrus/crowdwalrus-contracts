#[test_only]
module crowd_walrus::donations_tests;

use crowd_walrus::crowd_walrus::{Self as crowd_walrus};
use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::donations;
use crowd_walrus::token_registry::{Self as token_registry};
use std::string::{Self as string};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::test_scenario::{Self as ts};

const ADMIN: address = @0xA;

public struct TestCoin has drop, store {}

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
