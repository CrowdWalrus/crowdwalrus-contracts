#[test_only]
module crowd_walrus::admin_test;

use crowd_walrus::manager::{Self, CrowdWalrus};
use std::string::{Self, String};
use sui::test_scenario as ts;
use sui::test_utils::assert_eq;

const ADMIN: address = @0xA;
const USER1: address = @0xB;

#[test]
public fun test_create_project() {
    let mut scenario = ts::begin(ADMIN);
    let ctx = &mut tx_context::dummy();
    let admin_id = manager::create_and_share_crowd_walrus(ctx);

    ts::next_tx(&mut scenario, USER1);

    let mut crowd_walrus = ts::take_shared_by_id<CrowdWalrus>(&scenario, admin_id);

    ts::end(scenario);

    // Test admin id equals admin_id
    assert_eq(object::id(&crowd_walrus), admin_id);

    let subdomain_name: String = string::utf8(b"test-subdomain");
    manager::create_project(
        &mut crowd_walrus,
        string::utf8(b"Test Project"),
        string::utf8(b"A test project description"),
        subdomain_name,
        ctx,
    );

    // assert_eq(
    //     *factory::get_project(&admin, subdomain_name).borrow(),
    //     project_owner_cap.project_id(),
    // );

    // // Create project

    // // Verify project was added to admin's projects table

    // // Clean up
    // transfer::public_transfer(project_owner_cap, tx_context::sender(ctx));
    ts::return_shared(crowd_walrus);
    // tu::destroy(project_owner_cap);
}
