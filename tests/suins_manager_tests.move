#[test_only]
#[allow(unused_const)]
module crowd_walrus::suins_manager_tests;

use crowd_walrus::suins_manager::{Self as suins_manager, SuiNSManager};
use std::string::{utf8, String};
use std::unit_test::assert_eq;
use suins_subdomains::subdomain_tests as subdomain_tests;
use sui::clock::Clock;
use sui::test_scenario::{Self as ts, ctx, Scenario};
use suins::domain;
use suins::registry::Registry;
use suins::suins::SuiNS;

// Copied from subdomain_tests.move
const USER_ADDRESS: address = @0x01;
const TEST_ADDRESS: address = @0x02;
// crowd_walrus defined addresses
const ADMIN: address = @0xA;
const USER1: address = @0xB;
const USER2: address = @0xC;

const TEST_DOMAIN_NAME: vector<u8> = b"test.sui";

// === Appplicaiton Auth ===
public struct TestApp has drop {}

#[test]
fun test_register_subdomain() {
    let mut scenario = test_init(ADMIN);
    authorize_app(&mut scenario, ADMIN, TestApp {});

    scenario.next_tx(USER1);
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();
    let subdomain_name = get_test_subdomain_name(b"sub");
    suins_manager.register_subdomain(
        &TestApp {},
        &mut suins,
        &clock,
        subdomain_name,
        TEST_ADDRESS,
        ctx(&mut scenario),
    );

    let mut record = suins.registry<Registry>().lookup(domain::new(subdomain_name));
    assert!(record.is_some());
    let name_record = record.extract();
    assert_eq!(name_record.target_address(), option::some(TEST_ADDRESS));

    // clean up
    ts::return_shared(suins);
    ts::return_shared(clock);
    ts::return_shared(suins_manager);
    scenario.end();
}

#[test]
fun test_remove_subdomain() {
    let mut scenario = test_init(ADMIN);
    authorize_app(&mut scenario, ADMIN, TestApp {});

    scenario.next_tx(USER1);
    let subdomain_name = get_test_subdomain_name(b"sub");
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();

    // Create subdomain
    {
        suins_manager.register_subdomain(
            &TestApp {},
            &mut suins,
            &clock,
            subdomain_name,
            TEST_ADDRESS,
            ctx(&mut scenario),
        );

        let record = suins.registry<Registry>().lookup(domain::new(subdomain_name));
        assert!(record.is_some());
    };
    // Remove subdomain
    {
        scenario.next_tx(USER1);
        let admin_cap = scenario.take_from_address<suins_manager::AdminCap>(ADMIN);

        suins_manager::remove_subdomain(
            &suins_manager,
            &admin_cap,
            &mut suins,
            subdomain_name,
            &clock,
        );

        let record = suins.registry<Registry>().lookup(domain::new(subdomain_name));
        assert!(record.is_none());

        ts::return_to_address(ADMIN, admin_cap);
    };

    ts::return_shared(suins);
    ts::return_shared(clock);
    ts::return_shared(suins_manager);
    scenario.end();
}

#[test, expected_failure(abort_code = suins::registry::ERecordNotExpired)]
fun test_double_register_subdomain() {
    let mut scenario = test_init(ADMIN);
    authorize_app(&mut scenario, ADMIN, TestApp {});

    scenario.next_tx(USER1);

    let subdomain_name = get_test_subdomain_name(b"sub");
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();
    // Create subdomain
    {
        scenario.next_tx(USER1);
        suins_manager.register_subdomain(
            &TestApp {},
            &mut suins,
            &clock,
            subdomain_name,
            TEST_ADDRESS,
            ctx(&mut scenario),
        );

        let record = suins.registry<Registry>().lookup(domain::new(subdomain_name));
        assert!(record.is_some());
    };
    // Double register same subdomain
    {
        scenario.next_tx(USER1);
        suins_manager.register_subdomain(
            &TestApp {},
            &mut suins,
            &clock,
            subdomain_name,
            TEST_ADDRESS,
            ctx(&mut scenario),
        );
    };
    ts::return_shared(suins);
    ts::return_shared(clock);
    ts::return_shared(suins_manager);
    scenario.end();
}

#[test, expected_failure(abort_code = domain::EInvalidDomain)]
fun test_register_invalid_subdomain() {
    let mut scenario = test_init(ADMIN);
    authorize_app(&mut scenario, ADMIN, TestApp {});

    scenario.next_tx(USER1);

    // let subdomain_name = get_test_subdomain_name(b"sub");
    let subdomain_name = utf8(b"sub.invalid_domain.sui");
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();
    // Create subdomain
    {
        scenario.next_tx(USER1);
        suins_manager.register_subdomain(
            &TestApp {},
            &mut suins,
            &clock,
            subdomain_name,
            TEST_ADDRESS,
            ctx(&mut scenario),
        );

        let record = suins.registry<Registry>().lookup(domain::new(subdomain_name));
        assert!(record.is_some());
    };
    ts::return_shared(suins);
    ts::return_shared(clock);
    ts::return_shared(suins_manager);
    scenario.end();
}

public fun test_init(admin_address: address): Scenario {
    let mut scenario_val = subdomain_tests::test_init();
    let scenario = &mut scenario_val;
    let domain_name = get_test_domain_name();
    // Create suins manager
    let suins_manager_id = suins_manager::create_and_share_suins_manager(ctx(scenario));
    let admin_cap_id = suins_manager::create_admin_cap_for_user(
        suins_manager_id,
        admin_address,
        ctx(scenario),
    );
    {
        // Create main domain and set suins nft
        scenario.next_tx(admin_address);
        let mut suins_manager = scenario.take_shared_by_id<SuiNSManager>(suins_manager_id);
        let admin_cap = scenario.take_from_sender_by_id<suins_manager::AdminCap>(admin_cap_id);
        let parent = subdomain_tests::create_sld_name(domain_name, scenario);

        suins_manager.set_suins_nft(&admin_cap, parent);
        ts::return_shared(suins_manager);
        ts::return_to_address(admin_address, admin_cap);
    };
    {
        // Check if main domain is created
        scenario.next_tx(admin_address);
        let suins = scenario.take_shared<SuiNS>();
        let optional = suins.registry<Registry>().lookup(domain::new(domain_name));
        assert!(optional.is_some());
        ts::return_shared(suins);
    };
    scenario_val
}

public fun authorize_app<App: drop>(scenario: &mut ts::Scenario, admin_address: address, _: App) {
    scenario.next_tx(admin_address);
    let mut suins_manager = scenario.take_shared<SuiNSManager>();
    let admin_cap = scenario.take_from_sender<suins_manager::AdminCap>();
    suins_manager::authorize_app<TestApp>(&mut suins_manager, &admin_cap);
    ts::return_shared(suins_manager);
    ts::return_to_address(admin_address, admin_cap);
}

public fun get_test_domain_name(): String {
    utf8(TEST_DOMAIN_NAME)
}

public fun get_test_subdomain_name(subname_vec: vector<u8>): String {
    let mut subname_vec: vector<u8> = subname_vec;
    subname_vec.append(b".");
    subname_vec.append(TEST_DOMAIN_NAME);
    utf8(subname_vec)
}
