#[test_only]
module crowd_walrus::admin_test {
    use crowd_walrus::admin::{Self, Admin};
    use std::string::{Self, String};
    use sui::{test_scenario as ts, test_utils::{Self as tu, assert_eq}};

    const ADMIN: address = @0xA;
    const USER1: address = @0xB;

    #[test]
    public fun test_create_project() {
        let mut scenario = ts::begin(ADMIN);
        let ctx = &mut tx_context::dummy();
        let admin_id = admin::create_and_share_admin(ctx);

        ts::next_tx(&mut scenario, USER1);

        let mut admin = ts::take_shared_by_id<Admin>(&scenario, admin_id);

        ts::end(scenario);

        // Test admin id equals admin_id
        assert_eq(object::id(&admin), admin_id);

        let subdomain_name: String = string::utf8(b"test-subdomain");
        let project_owner_cap = admin::create_project(
            &mut admin,
            string::utf8(b"Test Project"),
            string::utf8(b"A test project description"),
            subdomain_name,
            ctx,
        );
        assert_eq(
            *admin::get_project(&admin, subdomain_name).borrow(),
            project_owner_cap.project_id(),
        );

        // // Create project

        // // Verify project was added to admin's projects table

        // // Clean up
        // transfer::public_transfer(project_owner_cap, tx_context::sender(ctx));
        ts::return_shared(admin);
        tu::destroy(project_owner_cap);
    }
}
