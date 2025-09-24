#[test_only]
#[allow(unused_const)]
module crowd_walrus::crowd_walrus_tests;

use crowd_walrus::campaign::{Campaign, CampaignOwnerCap};
use crowd_walrus::crowd_walrus::{Self as crowd_walrus, CrowdWalrus, AdminCap, ValidateCap};
use crowd_walrus::suins_manager::{
    AdminCap as SuiNSManagerAdminCap,
    SuiNSManager,
    authorize_app as suins_manager_authorize_app
};
use crowd_walrus::suins_manager_tests::{Self as suins_manager_tests, get_test_subdomain_name};
use std::string::{Self, String};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::test_scenario::{Self as ts, ctx, Scenario};
use sui::test_utils as tu;
use suins::domain;
use suins::registry::Registry;
use suins::suins::SuiNS;

const ADMIN: address = @0xA;
const USER1: address = @0xB;
const USER2: address = @0xC;

#[test]
public fun test_create_campaign() {
    let mut sc = test_init(ADMIN);
    let subdomain_name = get_test_subdomain_name(b"sub");
    {
        sc.next_tx(USER1);

        let campaign_id = create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign description"),
            b"sub",
        );

        sc.next_tx(USER1);
        let suins = sc.take_shared<SuiNS>();
        let mut subname_option = suins.registry<Registry>().lookup(domain::new(subdomain_name));
        assert!(subname_option.is_some());
        let subname_record = subname_option.extract();
        assert_eq!(subname_record.target_address(), option::some(campaign_id.to_address()));

        // Clean up
        ts::return_shared(suins);
    };

    {
        sc.next_tx(USER1);
        let campaign_owner_cap = sc.take_from_sender<CampaignOwnerCap>();
        let campaign = sc.take_shared_by_id<Campaign>(campaign_owner_cap.campaign_id());

        assert_eq!(campaign.subdomain_name(), subdomain_name);

        // Clean up
        tu::destroy(campaign_owner_cap);
        ts::return_shared(campaign);
    };

    sc.end();
}

#[test, expected_failure(abort_code = suins::registry::ERecordNotExpired)]
public fun test_create_campaign_with_duplicate_subdomain_name() {
    let mut sc = test_init(ADMIN);

    // First creation
    {
        sc.next_tx(USER1);

        create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign 1"),
            string::utf8(b"A test campaign description 1"),
            b"sub",
        );
    };

    // Second creation
    {
        sc.next_tx(USER2);

        create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign 2"),
            string::utf8(b"A test campaign description 2"),
            b"sub",
        );
    };

    sc.end();
}

#[test]
public fun test_validate_campaign() {
    let validator = USER1;
    let campaign_owner = USER2;

    let mut sc = test_init(ADMIN);

    // Test create validate cap
    {
        sc.next_tx(ADMIN);
        let admin_cap = sc.take_from_sender<AdminCap>();
        let crowd_walrus = sc.take_shared<CrowdWalrus>();

        crowd_walrus.create_validate_cap(&admin_cap, validator, ctx(&mut sc));

        sc.return_to_sender(admin_cap);
        ts::return_shared(crowd_walrus);
    };

    // Test create campaign
    {
        sc.next_tx(campaign_owner);
        create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign description"),
            b"sub",
        );
    };

    // Test validate campaign
    {
        sc.next_tx(validator);
        let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
        let mut campaign = sc.take_shared<Campaign>();
        let validate_cap = sc.take_from_sender<ValidateCap>();

        // Before validate
        assert!(!crowd_walrus.is_campaign_validated(object::id(&campaign)));
        assert_eq!(crowd_walrus.get_validated_campaigns_list().length(), 0);

        // Validate
        crowd_walrus.validate_campaign(&validate_cap, &mut campaign, ctx(&mut sc));

        // After validate
        assert!(crowd_walrus.is_campaign_validated(object::id(&campaign)));
        assert_eq!(crowd_walrus.get_validated_campaigns_list().length(), 1);
        assert!(
            vector::contains<ID>(
                &crowd_walrus.get_validated_campaigns_list(),
                &object::id(&campaign),
            ),
        );
        assert!(campaign.is_validated());

        // Clean up
        ts::return_shared(campaign);
        sc.return_to_sender(validate_cap);
        ts::return_shared(crowd_walrus);
    };

    // Test unvalidate campaign
    {
        sc.next_tx(validator);
        let mut campaign = sc.take_shared<Campaign>();
        let validate_cap = sc.take_from_sender<ValidateCap>();
        let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
        crowd_walrus.unvalidate_campaign(&validate_cap, &mut campaign, ctx(&mut sc));

        assert!(!crowd_walrus.is_campaign_validated(object::id(&campaign)));
        assert_eq!(crowd_walrus.get_validated_campaigns_list().length(), 0);

        assert!(!campaign.is_validated());

        // Clean up
        ts::return_shared(campaign);
        sc.return_to_sender(validate_cap);
        ts::return_shared(crowd_walrus);
    };

    sc.end();
}

#[test, expected_failure(abort_code = crowd_walrus::E_ALREADY_VALIDATED)]
public fun test_validate_campaign_twice() {
    let validator = USER1;
    let campaign_owner = USER2;

    let mut sc = test_init(ADMIN);

    // Test create validate cap
    {
        sc.next_tx(ADMIN);
        let admin_cap = sc.take_from_sender<AdminCap>();
        let crowd_walrus = sc.take_shared<CrowdWalrus>();

        crowd_walrus.create_validate_cap(&admin_cap, validator, ctx(&mut sc));

        sc.return_to_sender(admin_cap);
        ts::return_shared(crowd_walrus);
    };

    // Test create campaign
    {
        sc.next_tx(campaign_owner);
        create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign description"),
            b"sub",
        );
    };

    // Validate campaign
    {
        sc.next_tx(validator);
        let mut campaign = sc.take_shared<Campaign>();
        let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
        let validate_cap = sc.take_from_sender<ValidateCap>();
        crowd_walrus.validate_campaign(&validate_cap, &mut campaign, ctx(&mut sc));

        // Clean up
        ts::return_shared(campaign);
        sc.return_to_sender(validate_cap);
        ts::return_shared(crowd_walrus);
    };

    // Validate campaign again
    {
        sc.next_tx(validator);
        let mut campaign = sc.take_shared<Campaign>();
        let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
        let validate_cap = sc.take_from_sender<ValidateCap>();
        crowd_walrus.validate_campaign(&validate_cap, &mut campaign, ctx(&mut sc));

        // Clean up
        ts::return_shared(campaign);
        sc.return_to_sender(validate_cap);
        ts::return_shared(crowd_walrus);
    };

    sc.end();
}

#[test, expected_failure(abort_code = crowd_walrus::E_NOT_VALIDATED)]
public fun test_unvalidate_invalid_campaign() {
    let validator = USER1;
    let campaign_owner = USER2;

    let mut sc = test_init(ADMIN);

    // Test create validate cap
    {
        sc.next_tx(ADMIN);
        let admin_cap = sc.take_from_sender<AdminCap>();
        let crowd_walrus = sc.take_shared<CrowdWalrus>();

        crowd_walrus.create_validate_cap(&admin_cap, validator, ctx(&mut sc));

        sc.return_to_sender(admin_cap);
        ts::return_shared(crowd_walrus);
    };

    // Test create campaign
    {
        sc.next_tx(campaign_owner);
        create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign description"),
            b"sub",
        );
    };

    // Test unvalidate campaign
    {
        sc.next_tx(validator);
        let validate_cap = sc.take_from_sender<ValidateCap>();
        let mut campaign = sc.take_shared<Campaign>();
        let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
        crowd_walrus.unvalidate_campaign(&validate_cap, &mut campaign, ctx(&mut sc));
        sc.return_to_sender(validate_cap);
        ts::return_shared(campaign);
        ts::return_shared(crowd_walrus);
    };

    sc.end();
}

public fun test_init(admin_address: address): Scenario {
    let mut scenario = suins_manager_tests::test_init(admin_address);
    let crowd_walrus_id = crowd_walrus::create_and_share_crowd_walrus(ctx(&mut scenario));

    crowd_walrus::create_admin_cap_for_user(
        crowd_walrus_id,
        admin_address,
        ctx(&mut scenario),
    );
    {
        scenario.next_tx(admin_address);
        suins_manager_tests::authorize_app(&mut scenario, admin_address, crowd_walrus::get_app());
    };

    {
        scenario.next_tx(admin_address);
        let mut suins_manager = scenario.take_shared<SuiNSManager>();
        let suins_manager_cap = scenario.take_from_sender<SuiNSManagerAdminCap>();

        suins_manager_authorize_app<crowd_walrus::CrowdWalrusApp>(
            &mut suins_manager,
            &suins_manager_cap,
        );
        ts::return_shared(suins_manager);
        ts::return_to_address(admin_address, suins_manager_cap);
    };
    scenario
}

public fun create_test_campaign(
    sc: &mut Scenario,
    title: String,
    description: String,
    subname: vector<u8>,
): ID {
    let crowd_walrus = sc.take_shared<CrowdWalrus>();
    let suins_manager = sc.take_shared<SuiNSManager>();
    let mut suins = sc.take_shared<SuiNS>();
    let clock = sc.take_shared<Clock>();
    let subdomain_name = get_test_subdomain_name(subname);
    let campaign_id = crowd_walrus::create_campaign(
        &crowd_walrus,
        &suins_manager,
        &mut suins,
        &clock,
        title,
        description,
        subdomain_name,
        string::utf8(b"Test metadata"),
        ctx(sc),
    );
    ts::return_shared(crowd_walrus);
    ts::return_shared(suins);
    ts::return_shared(clock);
    ts::return_shared(suins_manager);
    campaign_id
}
