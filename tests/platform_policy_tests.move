#[test_only]
module crowd_walrus::platform_policy_tests;

use crowd_walrus::crowd_walrus;
use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::platform_policy::{Self as platform_policy};
use crowd_walrus::campaign;
use std::string::{Self as string};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::test_scenario::{Self as ts};

const ADMIN: address = @0xA;
const OTHER: address = @0xB;

#[test]
fun test_add_policy_persists_enabled_state() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    let name = string::utf8(b"standard");
    crowd_walrus::add_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        500,
        ADMIN,
        &clock,
    );
    let policy = platform_policy::borrow_policy(&registry, &name);
    assert_eq!(platform_policy::policy_platform_bps(policy), 500);
    assert_eq!(platform_policy::policy_platform_address(policy), ADMIN);
    assert_eq!(platform_policy::policy_enabled(policy), true);

    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = campaign::E_INVALID_BPS, location = 0x0::platform_policy)]
fun test_add_policy_invalid_bps_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    // 10_001 > 10_000 so this should hit the shared campaign::E_INVALID_BPS code path.
    let name = string::utf8(b"invalid_bps");
    crowd_walrus::add_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        10_001,
        ADMIN,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = campaign::E_ZERO_ADDRESS, location = 0x0::platform_policy)]
fun test_add_policy_zero_address_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    let name = string::utf8(b"zero_address");
    crowd_walrus::add_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        500,
        @0x0,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = platform_policy::E_POLICY_EXISTS, location = 0x0::platform_policy)]
fun test_add_policy_duplicate_name_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    let name = string::utf8(b"dup");
    crowd_walrus::add_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        100,
        ADMIN,
        &clock,
    );
    crowd_walrus::add_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        200,
        ADMIN,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = platform_policy::E_POLICY_NOT_FOUND, location = 0x0::platform_policy)]
fun test_update_policy_missing_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_platform_policy_internal(
        &mut registry,
        &admin_cap,
        string::utf8(b"missing"),
        100,
        ADMIN,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    ts::end(scenario);
}

#[test]
fun test_update_and_enable_policy() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    let name = string::utf8(b"adjustable");
    crowd_walrus::add_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        100,
        ADMIN,
        &clock,
    );

    crowd_walrus::update_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        750,
        OTHER,
        &clock,
    );
    let policy_after_update = platform_policy::borrow_policy(&registry, &name);
    assert_eq!(platform_policy::policy_platform_bps(policy_after_update), 750);
    assert_eq!(platform_policy::policy_platform_address(policy_after_update), OTHER);
    assert_eq!(platform_policy::policy_enabled(policy_after_update), true);

    crowd_walrus::disable_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        &clock,
    );
    let policy_disabled = platform_policy::borrow_policy(&registry, &name);
    assert_eq!(platform_policy::policy_enabled(policy_disabled), false);

    crowd_walrus::enable_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        &clock,
    );
    let policy_reenabled = platform_policy::borrow_policy(&registry, &name);
    assert_eq!(platform_policy::policy_enabled(policy_reenabled), true);

    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = platform_policy::E_POLICY_NOT_FOUND, location = 0x0::platform_policy)]
fun test_disable_policy_missing_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::disable_platform_policy_internal(
        &mut registry,
        &admin_cap,
        string::utf8(b"missing"),
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = platform_policy::E_POLICY_DISABLED, location = 0x0::platform_policy)]
fun test_disable_policy_twice_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    let name = string::utf8(b"toggle");
    crowd_walrus::add_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        300,
        ADMIN,
        &clock,
    );
    crowd_walrus::disable_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        &clock,
    );
    crowd_walrus::disable_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = platform_policy::E_POLICY_DISABLED, location = 0x0::platform_policy)]
fun test_require_enabled_policy_rejects_disabled() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    let name = string::utf8(b"requires_enabled");
    crowd_walrus::add_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        100,
        ADMIN,
        &clock,
    );
    crowd_walrus::disable_platform_policy_internal(
        &mut registry,
        &admin_cap,
        copy name,
        &clock,
    );

    platform_policy::require_enabled_policy(&registry, &name);

    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    ts::end(scenario);
}
