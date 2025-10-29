#[test_only]
module crowd_walrus::donations_tests;

use crowd_walrus::campaign::{Self as campaign};
use crowd_walrus::crowd_walrus::{Self as crowd_walrus};
use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::donations;
use crowd_walrus::token_registry::{Self as token_registry};
use std::string::{Self as string, String};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::test_scenario::{Self as ts};
use sui::test_utils::{Self as tu};

const ADMIN: address = @0xA;
const OWNER: address = @0xB;
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
