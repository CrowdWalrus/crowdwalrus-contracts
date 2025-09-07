#[test_only]
module crowd_walrus::admin_test;

use crowd_walrus::manager::{Self, CrowdWalrus, AdminCap, ValidateCap};
use crowd_walrus::project::{Project, ProjectOwnerCap};
use std::string::{Self, String};
use sui::test_scenario as ts;
use sui::test_utils::{Self as tu, assert_eq};

const ADMIN: address = @0xA;
const USER1: address = @0xB;
const USER2: address = @0xC;

#[test]
public fun test_create_project() {
    let mut sc = ts::begin(ADMIN);
    let ctx = &mut tx_context::dummy();
    let crowd_walrus_id = manager::create_and_share_crowd_walrus(ctx);
    let subdomain_name: String = string::utf8(b"test-subdomain");

    {
        sc.next_tx(USER1);
        let mut crowd_walrus = sc.take_shared_by_id<CrowdWalrus>(crowd_walrus_id);

        // Test admin id equals admin_id
        assert_eq(object::id(&crowd_walrus), crowd_walrus_id);

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

    {
        sc.next_tx(USER1);
        let project_owner_cap = sc.take_from_sender<ProjectOwnerCap>();
        let project = sc.take_shared_by_id<Project>(project_owner_cap.project_id());

        assert_eq(project.subdomain_name(), subdomain_name);

        // Clean up
        tu::destroy(project_owner_cap);
        ts::return_shared(project);
    };

    sc.end();
}

#[test, expected_failure(abort_code = manager::E_PROJECT_ALREADY_EXISTS)]
public fun test_create_project_with_duplicate_subdomain_name() {
    let mut sc = ts::begin(ADMIN);
    let ctx = &mut tx_context::dummy();
    let crowd_walrus_id = manager::create_and_share_crowd_walrus(ctx);
    let subdomain_name: String = string::utf8(b"test-subdomain");

    // First creation
    {
        sc.next_tx(USER1);
        let mut crowd_walrus = sc.take_shared_by_id<CrowdWalrus>(crowd_walrus_id);

        manager::create_project(
            &mut crowd_walrus,
            string::utf8(b"Test Project 1"),
            string::utf8(b"A test project description 1"),
            subdomain_name,
            ctx,
        );

        // Clean up
        ts::return_shared(crowd_walrus);
    };

    // Second creation
    {
        sc.next_tx(USER2);
        let mut crowd_walrus = sc.take_shared_by_id<CrowdWalrus>(crowd_walrus_id);
        manager::create_project(
            &mut crowd_walrus,
            string::utf8(b"Test Project 2"),
            string::utf8(b"A test project description 2"),
            subdomain_name,
            ctx,
        );
        ts::return_shared(crowd_walrus);
    };

    sc.end();
}

#[test]
public fun test_validate_project() {
    let validator = USER1;
    let project_owner = USER2;

    let ctx = &mut tx_context::dummy();
    let mut sc = ts::begin(ADMIN);

    // Create crowd walrus
    { manager::test_init(ctx); sc.next_tx(ADMIN); };

    let mut crowd_walrus = sc.take_shared<CrowdWalrus>();

    // Test create validate cap
    {
        let admin_cap = sc.take_from_sender<AdminCap>();

        crowd_walrus.create_validate_cap(&admin_cap, validator, ctx);

        sc.return_to_sender(admin_cap);
    };

    // Test create project
    {
        sc.next_tx(project_owner);
        crowd_walrus.create_project(
            string::utf8(b"Test Project"),
            string::utf8(b"A test project description"),
            string::utf8(b"test-subdomain"),
            ctx,
        );
    };

    // Test validate project
    {
        sc.next_tx(validator);
        let project = sc.take_shared<Project>();
        let validate_cap = sc.take_from_sender<ValidateCap>();

        // Before validate
        assert!(!crowd_walrus.is_project_validated(object::id(&project)));
        assert_eq(crowd_walrus.get_validated_projects_list().length(), 0);

        // Validate
        crowd_walrus.validate_project(&validate_cap, &project, ctx);

        // After validate
        assert!(crowd_walrus.is_project_validated(object::id(&project)));
        assert_eq(crowd_walrus.get_validated_projects_list().length(), 1);
        assert!(
            vector::contains<ID>(
                &crowd_walrus.get_validated_projects_list(),
                &object::id(&project),
            ),
        );

        // Clean up
        ts::return_shared(project);
        sc.return_to_sender(validate_cap);
    };

    // Test unvalidate project
    {
        sc.next_tx(validator);
        let project = sc.take_shared<Project>();
        let validate_cap = sc.take_from_sender<ValidateCap>();
        crowd_walrus.unvalidate_project(&validate_cap, &project, ctx);

        assert!(!crowd_walrus.is_project_validated(object::id(&project)));
        assert_eq(crowd_walrus.get_validated_projects_list().length(), 0);

        // Clean up
        ts::return_shared(project);
        sc.return_to_sender(validate_cap);
    };

    // Clean up
    ts::return_shared(crowd_walrus);
    sc.end();
}

#[test, expected_failure(abort_code = manager::E_ALREADY_VALIDATED)]
public fun test_validate_project_twice() {
    let validator = USER1;
    let project_owner = USER2;
    let ctx = &mut tx_context::dummy();
    let mut sc = ts::begin(ADMIN);
    // Create crowd walrus
    { manager::test_init(ctx); sc.next_tx(ADMIN); };
    let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
    manager::create_validate_cap_for_user(
        object::id(&crowd_walrus),
        validator,
        ctx,
    );
    // Create project
    {
        sc.next_tx(project_owner);
        crowd_walrus.create_project(
            string::utf8(b"Test Project"),
            string::utf8(b"A test project description"),
            string::utf8(b"test-subdomain"),
            ctx,
        );
    };
    // Validate project
    {
        sc.next_tx(validator);
        let validate_cap = sc.take_from_sender<ValidateCap>();
        let project = sc.take_shared<Project>();
        crowd_walrus.validate_project(&validate_cap, &project, ctx);
        sc.return_to_sender(validate_cap);
        ts::return_shared(project);
    };
    // Validate project again
    {
        sc.next_tx(validator);
        let validate_cap = sc.take_from_sender<ValidateCap>();
        let project = sc.take_shared<Project>();
        crowd_walrus.validate_project(&validate_cap, &project, ctx);
        sc.return_to_sender(validate_cap);
        ts::return_shared(project);
    };

    ts::return_shared(crowd_walrus);
    sc.end();
}

#[test, expected_failure(abort_code = manager::E_NOT_VALIDATED)]
public fun test_unvalidate_project_twice() {
    let validator = USER1;
    let project_owner = USER2;
    let ctx = &mut tx_context::dummy();
    let mut sc = ts::begin(ADMIN);
    // Create crowd walrus
    { manager::test_init(ctx); sc.next_tx(ADMIN); };
    let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
    manager::create_validate_cap_for_user(object::id(&crowd_walrus), validator, ctx);
    // Test create project
    {
        sc.next_tx(project_owner);
        crowd_walrus.create_project(
            string::utf8(b"Test Project"),
            string::utf8(b"A test project description"),
            string::utf8(b"test-subdomain"),
            ctx,
        );
    };
    // Test unvalidate project
    {
        sc.next_tx(validator);
        let validate_cap = sc.take_from_sender<ValidateCap>();
        let project = sc.take_shared<Project>();
        crowd_walrus.unvalidate_project(&validate_cap, &project, ctx);
        sc.return_to_sender(validate_cap);
        ts::return_shared(project);
    };

    ts::return_shared(crowd_walrus);
    sc.end();
}
