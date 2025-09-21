#[test_only]
module crowd_walrus::crowd_walrus_tests;

use crowd_walrus::campaign::{Campaign, CampaignOwnerCap};
use crowd_walrus::manager::{Self, CrowdWalrus, AdminCap, ValidateCap};
use std::string::{Self, String};
use sui::test_scenario as ts;
use sui::test_utils::{Self as tu, assert_eq};

const ADMIN: address = @0xA;
const USER1: address = @0xB;
const USER2: address = @0xC;

#[test]
public fun test_create_campaign() {
    let mut sc = ts::begin(ADMIN);
    let ctx = &mut tx_context::dummy();
    let crowd_walrus_id = manager::create_and_share_crowd_walrus(ctx);
    let subdomain_name: String = string::utf8(b"test-subdomain");

    {
        sc.next_tx(USER1);
        let crowd_walrus = sc.take_shared_by_id<CrowdWalrus>(crowd_walrus_id);

        // Test admin id equals admin_id
        assert_eq(object::id(&crowd_walrus), crowd_walrus_id);

        manager::create_campaign(
            &crowd_walrus,
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign description"),
            subdomain_name,
            ctx,
        );

        // Clean up
        ts::return_shared(crowd_walrus);
    };

    {
        sc.next_tx(USER1);
        let campaign_owner_cap = sc.take_from_sender<CampaignOwnerCap>();
        let campaign = sc.take_shared_by_id<Campaign>(campaign_owner_cap.campaign_id());

        assert_eq(campaign.subdomain_name(), subdomain_name);

        // Clean up
        tu::destroy(campaign_owner_cap);
        ts::return_shared(campaign);
    };

    sc.end();
}

// #[test, expected_failure(abort_code = manager::E_CAMPAIGN_ALREADY_EXISTS)]
// public fun test_create_campaign_with_duplicate_subdomain_name() {
//     let mut sc = ts::begin(ADMIN);
//     let ctx = &mut tx_context::dummy();
//     let crowd_walrus_id = manager::create_and_share_crowd_walrus(ctx);
//     let subdomain_name: String = string::utf8(b"test-subdomain");

//     // First creation
//     {
//         sc.next_tx(USER1);
//         let mut crowd_walrus = sc.take_shared_by_id<CrowdWalrus>(crowd_walrus_id);

//         manager::create_campaign(
//             &mut crowd_walrus,
//             string::utf8(b"Test Campaign 1"),
//             string::utf8(b"A test campaign description 1"),
//             subdomain_name,
//             ctx,
//         );

//         // Clean up
//         ts::return_shared(crowd_walrus);
//     };

//     // Second creation
//     {
//         sc.next_tx(USER2);
//         let mut crowd_walrus = sc.take_shared_by_id<CrowdWalrus>(crowd_walrus_id);
//         manager::create_campaign(
//             &mut crowd_walrus,
//             string::utf8(b"Test Campaign 2"),
//             string::utf8(b"A test campaign description 2"),
//             subdomain_name,
//             ctx,
//         );
//         ts::return_shared(crowd_walrus);
//     };

//     sc.end();
// }

#[test]
public fun test_validate_campaign() {
    let validator = USER1;
    let campaign_owner = USER2;

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

    // Test create campaign
    {
        sc.next_tx(campaign_owner);
        crowd_walrus.create_campaign(
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign description"),
            string::utf8(b"test-subdomain"),
            ctx,
        );
    };

    // Test validate campaign
    {
        sc.next_tx(validator);
        let campaign = sc.take_shared<Campaign>();
        let validate_cap = sc.take_from_sender<ValidateCap>();

        // Before validate
        assert!(!crowd_walrus.is_campaign_validated(object::id(&campaign)));
        assert_eq(crowd_walrus.get_validated_campaigns_list().length(), 0);

        // Validate
        crowd_walrus.validate_campaign(&validate_cap, &campaign, ctx);

        // After validate
        assert!(crowd_walrus.is_campaign_validated(object::id(&campaign)));
        assert_eq(crowd_walrus.get_validated_campaigns_list().length(), 1);
        assert!(
            vector::contains<ID>(
                &crowd_walrus.get_validated_campaigns_list(),
                &object::id(&campaign),
            ),
        );

        // Clean up
        ts::return_shared(campaign);
        sc.return_to_sender(validate_cap);
    };

    // Test unvalidate campaign
    {
        sc.next_tx(validator);
        let campaign = sc.take_shared<Campaign>();
        let validate_cap = sc.take_from_sender<ValidateCap>();
        crowd_walrus.unvalidate_campaign(&validate_cap, &campaign, ctx);

        assert!(!crowd_walrus.is_campaign_validated(object::id(&campaign)));
        assert_eq(crowd_walrus.get_validated_campaigns_list().length(), 0);

        // Clean up
        ts::return_shared(campaign);
        sc.return_to_sender(validate_cap);
    };

    // Clean up
    ts::return_shared(crowd_walrus);
    sc.end();
}

#[test, expected_failure(abort_code = manager::E_ALREADY_VALIDATED)]
public fun test_validate_campaign_twice() {
    let validator = USER1;
    let campaign_owner = USER2;
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
    // Create campaign
    {
        sc.next_tx(campaign_owner);
        crowd_walrus.create_campaign(
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign description"),
            string::utf8(b"test-subdomain"),
            ctx,
        );
    };
    // Validate campaign
    {
        sc.next_tx(validator);
        let validate_cap = sc.take_from_sender<ValidateCap>();
        let campaign = sc.take_shared<Campaign>();
        crowd_walrus.validate_campaign(&validate_cap, &campaign, ctx);
        sc.return_to_sender(validate_cap);
        ts::return_shared(campaign);
    };
    // Validate campaign again
    {
        sc.next_tx(validator);
        let validate_cap = sc.take_from_sender<ValidateCap>();
        let campaign = sc.take_shared<Campaign>();
        crowd_walrus.validate_campaign(&validate_cap, &campaign, ctx);
        sc.return_to_sender(validate_cap);
        ts::return_shared(campaign);
    };

    ts::return_shared(crowd_walrus);
    sc.end();
}

#[test, expected_failure(abort_code = manager::E_NOT_VALIDATED)]
public fun test_unvalidate_campaign_twice() {
    let validator = USER1;
    let campaign_owner = USER2;
    let ctx = &mut tx_context::dummy();
    let mut sc = ts::begin(ADMIN);
    // Create crowd walrus
    { manager::test_init(ctx); sc.next_tx(ADMIN); };
    let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
    manager::create_validate_cap_for_user(object::id(&crowd_walrus), validator, ctx);
    // Test create campaign
    {
        sc.next_tx(campaign_owner);
        crowd_walrus.create_campaign(
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign description"),
            string::utf8(b"test-subdomain"),
            ctx,
        );
    };
    // Test unvalidate campaign
    {
        sc.next_tx(validator);
        let validate_cap = sc.take_from_sender<ValidateCap>();
        let campaign = sc.take_shared<Campaign>();
        crowd_walrus.unvalidate_campaign(&validate_cap, &campaign, ctx);
        sc.return_to_sender(validate_cap);
        ts::return_shared(campaign);
    };

    ts::return_shared(crowd_walrus);
    sc.end();
}
