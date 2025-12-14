#[test_only]
module crowd_walrus::profile_subdomain_tests;

use crowd_walrus::crowd_walrus::{Self as cw, CrowdWalrusApp};
use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::profiles::{Self as profiles};
use crowd_walrus::suins_manager::{Self as suins_manager, SuiNSManager};
use crowd_walrus::suins_manager_tests as sm_tests;
use std::string::{Self as string};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::test_scenario::{Self as ts, ctx};
use suins::domain;
use suins::registry::Registry;
use suins::suins::SuiNS;

const ADMIN: address = @0xA;
const OWNER: address = @0x1;
const OTHER: address = @0x2;

// Create + subdomain in a single PTB via public helpers.
#[test]
fun test_create_profile_and_subdomain_single_ptb() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(OWNER);
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();

    let mut profile = profiles::create_profile_for_sender(
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    let subdomain_name = sm_tests::get_test_subdomain_name(b"ptb-sub");
    cw::set_profile_subdomain_public(
        &mut profile,
        &suins_manager,
        &mut suins,
        subdomain_name,
        &clock,
        ctx(&mut scenario),
    );

    let profile_id = sui::object::id(&profile);

    profiles::transfer_to(profile, OWNER);
    ts::return_shared(registry);
    ts::return_shared(suins_manager);
    ts::return_shared(suins);
    ts::return_shared(clock);

    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let profile_after = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let opt = profiles::subdomain_name(&profile_after);
    assert!(std::option::is_some(&opt));
    let value = std::option::destroy_some(opt);
    assert!(value == subdomain_name);
    ts::return_to_address(OWNER, profile_after);

    let suins_read = scenario.take_shared<SuiNS>();
    let mut record_opt = suins_read.registry<Registry>().lookup(domain::new(subdomain_name));
    assert!(record_opt.is_some());
    let record = record_opt.extract();
    assert!(record.target_address() == std::option::some(profile_id.to_address()));
    ts::return_shared(suins_read);

    scenario.end();
}

// Create + metadata + subdomain all in one PTB to mirror the full onboarding flow.
#[test]
fun test_create_profile_metadata_and_subdomain_single_ptb() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(OWNER);
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();

    let mut profile = profiles::create_profile_for_sender(
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );

    profiles::upsert_profile_metadata(
        &mut profile,
        vector[string::utf8(b"name")],
        vector[string::utf8(b"Full Setup")],
        &clock,
        ctx(&mut scenario),
    );

    let subdomain_name = sm_tests::get_test_subdomain_name(b"ptb-full");
    cw::set_profile_subdomain_public(
        &mut profile,
        &suins_manager,
        &mut suins,
        subdomain_name,
        &clock,
        ctx(&mut scenario),
    );

    profiles::transfer_to(profile, OWNER);
    ts::return_shared(registry);
    ts::return_shared(suins_manager);
    ts::return_shared(suins);
    ts::return_shared(clock);

    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let profile_after = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let metadata = profiles::metadata(&profile_after);
    assert_eq!(metadata.length(), 1);
    assert_eq!(
        *metadata.get(&string::utf8(b"name")),
        string::utf8(b"Full Setup"),
    );
    let opt = profiles::subdomain_name(&profile_after);
    assert!(std::option::is_some(&opt));
    let value = std::option::destroy_some(opt);
    assert!(value == subdomain_name);
    ts::return_to_address(OWNER, profile_after);

    scenario.end();
}

// Create without subdomain, then set it later with the public helper.
#[test]
fun test_create_profile_then_add_subdomain_later() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    // Tx1: create profile only.
    scenario.next_tx(OWNER);
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    let clock = scenario.take_shared<Clock>();
    let profile = profiles::create_profile_for_sender(
        &mut registry,
        &clock,
        ctx(&mut scenario),
    );
    profiles::transfer_to(profile, OWNER);
    ts::return_shared(registry);
    ts::return_shared(clock);
    let _ = ts::next_tx(&mut scenario, OWNER);

    // Tx2: set subdomain using the new helper.
    scenario.next_tx(OWNER);
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock_set = scenario.take_shared<Clock>();
    let mut profile_for_sub = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let subdomain_name = sm_tests::get_test_subdomain_name(b"later-sub");
    cw::set_profile_subdomain_public(
        &mut profile_for_sub,
        &suins_manager,
        &mut suins,
        subdomain_name,
        &clock_set,
        ctx(&mut scenario),
    );
    ts::return_to_address(OWNER, profile_for_sub);
    ts::return_shared(suins_manager);
    ts::return_shared(suins);
    ts::return_shared(clock_set);
    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let profile_after = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let opt = profiles::subdomain_name(&profile_after);
    assert!(std::option::is_some(&opt));
    let value = std::option::destroy_some(opt);
    assert!(value == subdomain_name);
    ts::return_to_address(OWNER, profile_after);

    scenario.end();
}

// Ensure the happy path registers the subdomain and stores it immutably on the profile.
#[test]
fun test_set_profile_subdomain_happy_path() {
    let mut scenario = sm_tests::test_init(ADMIN);
    authorize_crowd_walrus_app(&mut scenario, ADMIN);

    scenario.next_tx(OWNER);
    let mut profile = profiles::create(OWNER, vector::empty(), vector::empty(), ctx(&mut scenario));

    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();

    let subdomain_name = sm_tests::get_test_subdomain_name(b"profile");
    cw::set_profile_subdomain(
        &mut profile,
        &suins_manager,
        &mut suins,
        subdomain_name,
        &clock,
        ctx(&mut scenario),
    );

    // field set
    let opt = profiles::subdomain_name(&profile);
    assert!(std::option::is_some(&opt));
    let value = std::option::destroy_some(opt);
    assert!(value == subdomain_name);

    // registry points to profile
    let mut record_opt = suins.registry<Registry>().lookup(domain::new(copy value));
    assert!(record_opt.is_some());
    let record = record_opt.extract();
    let target = record.target_address();
    assert!(target == std::option::some(sui::object::id(&profile).to_address()));

    ts::return_shared(suins_manager);
    ts::return_shared(suins);
    ts::return_shared(clock);
    profiles::transfer_to(profile, OWNER);
    scenario.end();
}

// Owners only: different sender cannot set the subdomain.
#[test, expected_failure(abort_code = profiles::E_NOT_PROFILE_OWNER, location = 0x0::crowd_walrus)]
fun test_set_profile_subdomain_not_owner_aborts() {
    let mut scenario = sm_tests::test_init(ADMIN);
    authorize_crowd_walrus_app(&mut scenario, ADMIN);

    scenario.next_tx(OWNER);
    let mut profile = profiles::create(OWNER, vector::empty(), vector::empty(), ctx(&mut scenario));

    scenario.next_tx(OTHER);
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();

    let subdomain_name = sm_tests::get_test_subdomain_name(b"not-owner");
    cw::set_profile_subdomain(
        &mut profile,
        &suins_manager,
        &mut suins,
        subdomain_name,
        &clock,
        ctx(&mut scenario),
    );

    // unreachable
    ts::return_shared(suins_manager);
    ts::return_shared(suins);
    ts::return_shared(clock);
    profiles::transfer_to(profile, OWNER);
    scenario.end();
}

// Subdomain is immutable once set for the owner.
#[test, expected_failure(abort_code = profiles::E_SUBDOMAIN_ALREADY_SET, location = 0x0::profiles)]
fun test_set_profile_subdomain_twice_aborts() {
    let mut scenario = sm_tests::test_init(ADMIN);
    authorize_crowd_walrus_app(&mut scenario, ADMIN);

    scenario.next_tx(OWNER);
    let mut profile = profiles::create(OWNER, vector::empty(), vector::empty(), ctx(&mut scenario));

    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();

    let subdomain_name = sm_tests::get_test_subdomain_name(b"twice");
    cw::set_profile_subdomain(
        &mut profile,
        &suins_manager,
        &mut suins,
        subdomain_name,
        &clock,
        ctx(&mut scenario),
    );

    // second attempt should abort
    cw::set_profile_subdomain(
        &mut profile,
        &suins_manager,
        &mut suins,
        subdomain_name,
        &clock,
        ctx(&mut scenario),
    );

    ts::return_shared(suins_manager);
    ts::return_shared(suins);
    ts::return_shared(clock);
    profiles::transfer_to(profile, OWNER);
    scenario.end();
}

// Admin can remove a profile subdomain; registry entry removed and field cleared.
#[test]
fun test_remove_profile_subdomain_happy_path() {
    let mut scenario = sm_tests::test_init(ADMIN);
    authorize_crowd_walrus_app(&mut scenario, ADMIN);

    // set first
    scenario.next_tx(OWNER);
    let mut profile = profiles::create(OWNER, vector::empty(), vector::empty(), ctx(&mut scenario));
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();
    let subdomain_name = sm_tests::get_test_subdomain_name(b"remove");
    cw::set_profile_subdomain(
        &mut profile,
        &suins_manager,
        &mut suins,
        subdomain_name,
        &clock,
        ctx(&mut scenario),
    );

    ts::return_shared(suins_manager);
    ts::return_shared(suins);
    ts::return_shared(clock);

    // remove as admin
    scenario.next_tx(ADMIN);
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();
    let admin_cap = scenario.take_from_address<suins_manager::AdminCap>(ADMIN);

    cw::remove_profile_subdomain(
        &suins_manager,
        &admin_cap,
        &mut suins,
        &mut profile,
        &clock,
        ctx(&mut scenario),
    );

    let opt = profiles::subdomain_name(&profile);
    assert!(std::option::is_none(&opt));
    let record_opt = suins.registry<Registry>().lookup(domain::new(subdomain_name));
    assert!(record_opt.is_none());

    ts::return_to_address(ADMIN, admin_cap);
    ts::return_shared(suins_manager);
    ts::return_shared(suins);
    ts::return_shared(clock);
    profiles::transfer_to(profile, OWNER);
    scenario.end();
}

// Removing without a set subdomain aborts.
#[test, expected_failure(abort_code = profiles::E_SUBDOMAIN_NOT_SET, location = 0x0::crowd_walrus)]
fun test_remove_profile_subdomain_not_set_aborts() {
    let mut scenario = sm_tests::test_init(ADMIN);
    authorize_crowd_walrus_app(&mut scenario, ADMIN);

    scenario.next_tx(OWNER);
    let mut profile = profiles::create(OWNER, vector::empty(), vector::empty(), ctx(&mut scenario));

    scenario.next_tx(ADMIN);
    let suins_manager = scenario.take_shared<SuiNSManager>();
    let mut suins = scenario.take_shared<SuiNS>();
    let clock = scenario.take_shared<Clock>();
    let admin_cap = scenario.take_from_sender<suins_manager::AdminCap>();

    cw::remove_profile_subdomain(
        &suins_manager,
        &admin_cap,
        &mut suins,
        &mut profile,
        &clock,
        ctx(&mut scenario),
    );

    ts::return_to_address(ADMIN, admin_cap);
    ts::return_shared(suins_manager);
    ts::return_shared(suins);
    ts::return_shared(clock);
    profiles::transfer_to(profile, OWNER);
    scenario.end();
}

fun authorize_crowd_walrus_app(scenario: &mut ts::Scenario, admin_address: address) {
    scenario.next_tx(admin_address);
    let mut suins_manager = scenario.take_shared<SuiNSManager>();
    let admin_cap = scenario.take_from_sender<suins_manager::AdminCap>();
    suins_manager::authorize_app<CrowdWalrusApp>(&mut suins_manager, &admin_cap);
    ts::return_shared(suins_manager);
    ts::return_to_address(admin_address, admin_cap);
}
