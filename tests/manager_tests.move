#[test_only]
module crowd_walrus::admin_test;

use crowd_walrus::manager::{Self, CrowdWalrus};
use crowd_walrus::project::{Project, ProjectOwnerCap};
use std::string::{Self, String};
use sui::test_scenario as ts;
use sui::test_utils::{Self as tu, assert_eq};

const ADMIN: address = @0xA;
const USER1: address = @0xB;

#[test]
public fun test_create_project() {
    let mut scenario = ts::begin(ADMIN);
    let ctx = &mut tx_context::dummy();
    let admin_id = manager::create_and_share_crowd_walrus(ctx);
    let subdomain_name: String = string::utf8(b"test-subdomain");

    scenario.next_tx(USER1);
    {
        let mut crowd_walrus = scenario.take_shared_by_id<CrowdWalrus>(admin_id);

        // Test admin id equals admin_id
        assert_eq(object::id(&crowd_walrus), admin_id);

        manager::create_project(
            &mut crowd_walrus,
            string::utf8(b"Test Project"),
            string::utf8(b"A test project description"),
            subdomain_name,
            ctx,
        );

        // Clean up
        ts::return_shared(crowd_walrus);
    };
    scenario.next_tx(USER1);
    {
        let project_owner_cap = scenario.take_from_sender<ProjectOwnerCap>();
        let project = scenario.take_shared_by_id<Project>(project_owner_cap.project_id());

        assert_eq(project.subdomain_name(), subdomain_name);

        // Clean up
        tu::destroy(project_owner_cap);
        ts::return_shared(project);
    };

    scenario.end();
}
