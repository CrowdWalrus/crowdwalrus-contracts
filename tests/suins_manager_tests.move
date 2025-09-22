#[test_only]
#[allow(unused_const)]
module crowd_walrus::suins_manager_tests;

use crowd_walrus::suins_manager::{Self as suins_manager, SuiNSManager};
use std::string::utf8;
use subdomains::subdomain_tests as subdomain_tests;
use sui::clock::Clock;
use sui::test_scenario::{Self as ts, ctx};
use sui::test_utils::assert_eq;
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

// === Appplicaiton Auth ===
public struct TestApp has drop {}

#[test]
fun test_register_subdomain() {
    let mut scenario = subdomain_tests::test_init();

    test_init(&mut scenario);

    scenario.next_tx(USER1);
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();
    let subdomain_name = utf8(b"sub.test.sui");
    suins_manager::register_subdomain<TestApp>(
        &TestApp {},
        &suins_manager,
        &mut suins,
        &clock,
        subdomain_name,
        TEST_ADDRESS,
        ctx(&mut scenario),
    );

    let mut record = suins.registry<Registry>().lookup(domain::new(subdomain_name));
    assert!(record.is_some());
    let name_record = record.extract();
    assert_eq(name_record.target_address(), option::some(TEST_ADDRESS));

    // clean up
    ts::return_shared(suins);
    ts::return_shared(clock);
    ts::return_shared(suins_manager);
    scenario.end();
}

fun test_init(scenario: &mut ts::Scenario) {
    // Create suins manager
    let domain_name = utf8(b"test.sui");
    let suins_manager_id = suins_manager::create_and_share_suins_manager(ctx(scenario));
    let admin_cap_id = suins_manager::create_admin_cap_for_user(
        suins_manager_id,
        ADMIN,
        ctx(scenario),
    );
    {
        // Create main domain and set suins nft
        scenario.next_tx(ADMIN);
        let mut suins_manager = scenario.take_shared_by_id<SuiNSManager>(suins_manager_id);
        let admin_cap = scenario.take_from_sender_by_id<suins_manager::AdminCap>(admin_cap_id);
        let parent = subdomain_tests::create_sld_name(domain_name, scenario);

        suins_manager::set_suins_nft(&admin_cap, &mut suins_manager, parent);
        ts::return_shared(suins_manager);
        ts::return_to_address(ADMIN, admin_cap);
    };
    {
        // Check if main domain is created
        scenario.next_tx(ADMIN);
        let suins = scenario.take_shared<SuiNS>();
        let optional = suins.registry<Registry>().lookup(domain::new(domain_name));
        assert!(optional.is_some());
        ts::return_shared(suins);
    };
    {
        // Authorize test app
        scenario.next_tx(ADMIN);
        let mut suins_manager = scenario.take_shared_by_id<SuiNSManager>(suins_manager_id);
        let admin_cap = scenario.take_from_sender_by_id<suins_manager::AdminCap>(admin_cap_id);
        suins_manager::authorize_app<TestApp>(&mut suins_manager, &admin_cap);
        ts::return_shared(suins_manager);
        ts::return_to_address(ADMIN, admin_cap);
    };
}
