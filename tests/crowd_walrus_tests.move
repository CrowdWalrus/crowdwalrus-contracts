#[test_only]
#[allow(unused_const)]
module crowd_walrus::crowd_walrus_tests;

use crowd_walrus::campaign::{Self as campaign, Campaign, CampaignOwnerCap};
use crowd_walrus::campaign_stats::{Self as campaign_stats};
use crowd_walrus::crowd_walrus::{Self as crowd_walrus, CrowdWalrus, AdminCap, VerifyCap};
use crowd_walrus::platform_policy::{Self as platform_policy};
use crowd_walrus::profiles::{Self as profiles};
use crowd_walrus::suins_manager::{
    Self as suins_manager,
    AdminCap as SuiNSManagerAdminCap,
    SuiNSManager,
    authorize_app as suins_manager_authorize_app
};
use crowd_walrus::suins_manager_tests::{Self as suins_manager_tests, get_test_subdomain_name};
use std::string::{Self, String};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::object as sui_object;
use sui::test_scenario::{Self as ts, ctx, Scenario};
use sui::test_utils as tu;
use sui::vec_map::VecMap;
use suins::domain;
use suins::registry::Registry;
use suins::suins::SuiNS;

const ADMIN: address = @0xA;
const USER1: address = @0xB;
const USER2: address = @0xC;

const DEFAULT_PLATFORM_BPS: u16 = 500;

const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;
const E_CAMPAIGN_DELETED: u64 = 11;
const E_APP_NOT_AUTHORIZED: u64 = 1;

#[test]
public fun test_create_campaign() {
    let mut sc = test_init(ADMIN);
    let subdomain_name = get_test_subdomain_name(b"sub");
    {
        sc.next_tx(USER1);

        let campaign_id = create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign short description"),
            b"sub",
            vector[string::utf8(b"key1"), string::utf8(b"key2")],
            vector[string::utf8(b"value1"), string::utf8(b"value2")],
            1_000_000,
            USER1, // recipient_address
            0,
            U64_MAX,
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
        let profiles_registry = sc.take_shared<profiles::ProfilesRegistry>();
        let stats = sc.take_shared_by_id<campaign_stats::CampaignStats>(campaign::stats_id(&campaign));
        assert!(profiles::exists(&profiles_registry, USER1));
        let profile_id = profiles::id_of(&profiles_registry, USER1);
        assert!(sui_object::id_to_address(&profile_id) != @0x0);

        assert_eq!(campaign.subdomain_name(), subdomain_name);
        let metadata: VecMap<String, String> = campaign.metadata();
        assert_eq!(metadata.length(), 2);
        assert_eq!(*metadata.get(&string::utf8(b"key1")), string::utf8(b"value1"));
        assert_eq!(*metadata.get(&string::utf8(b"key2")), string::utf8(b"value2"));
        assert_eq!(campaign::funding_goal_usd_micro(&campaign), 1_000_000);
        assert_eq!(campaign::payout_platform_bps(&campaign), DEFAULT_PLATFORM_BPS);
        assert_eq!(campaign::payout_platform_address(&campaign), ADMIN);
        assert_eq!(campaign::payout_recipient_address(&campaign), USER1);
        assert_eq!(campaign::stats_id(&campaign), sui_object::id(&stats));
        assert_eq!(campaign_stats::total_usd_micro(&stats), 0);
        assert_eq!(campaign_stats::total_donations_count(&stats), 0);
        // Clean up
        tu::destroy(campaign_owner_cap);
        ts::return_shared(stats);
        ts::return_shared(profiles_registry);
        ts::return_shared(campaign);
    };

    sc.end();
}

#[test]
public fun test_create_campaign_reuses_existing_profile() {
    let mut sc = test_init(ADMIN);
    sc.next_tx(USER1);
    let mut registry = sc.take_shared<profiles::ProfilesRegistry>();
    let clock = sc.take_shared<Clock>();
    let initial_profile_id = profiles::create_or_get_profile_for_sender(
        &mut registry,
        &clock,
        ctx(&mut sc),
    );
    ts::return_shared(registry);
    ts::return_shared(clock);
    ts::next_tx(&mut sc, USER1);

    sc.next_tx(USER1);
    let campaign_id = create_test_campaign(
        &mut sc,
        string::utf8(b"Reuse Profile"),
        string::utf8(b"Existing profile should be reused"),
        b"reuse-profile",
        vector::empty(),
        vector::empty(),
        1_500_000,
        USER1,
        0,
        U64_MAX,
    );
    let effects = ts::next_tx(&mut sc, USER1);
    assert_eq!(ts::num_user_events(&effects), 2);

    sc.next_tx(USER1);
    let registry_after = sc.take_shared<profiles::ProfilesRegistry>();
    assert_eq!(profiles::id_of(&registry_after, USER1), initial_profile_id);
    ts::return_shared(registry_after);

    let campaign = sc.take_shared_by_id<Campaign>(campaign_id);
    let stats_id = campaign::stats_id(&campaign);
    assert!(sui_object::id_to_address(&stats_id) != @0x0);
    ts::return_shared(campaign);

    let stats = sc.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    assert_eq!(campaign_stats::total_usd_micro(&stats), 0);
    assert_eq!(campaign_stats::total_donations_count(&stats), 0);
    ts::return_shared(stats);

    ts::next_tx(&mut sc, USER1);

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
            string::utf8(b"A test campaign short description 1"),
            b"sub",
            vector::empty(),
            vector::empty(),
            500_000,
            USER1, // recipient_address
            0,
            U64_MAX,
        );
    };

    // Second creation
    {
        sc.next_tx(USER2);

        create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign 2"),
            string::utf8(b"A test campaign short description 2"),
            b"sub",
            vector::empty(),
            vector::empty(),
            500_000,
            USER2, // recipient_address
            0,
            U64_MAX,
        );
    };

    sc.end();
}

#[test]
public fun test_verify_campaign() {
    let verifier = USER1;
    let campaign_owner = USER2;

    let mut sc = test_init(ADMIN);

    // Test create verify cap
    {
        sc.next_tx(ADMIN);
        let admin_cap = sc.take_from_sender<AdminCap>();
        let crowd_walrus = sc.take_shared<CrowdWalrus>();

        crowd_walrus.create_verify_cap(&admin_cap, verifier, ctx(&mut sc));

        sc.return_to_sender(admin_cap);
        ts::return_shared(crowd_walrus);
    };

    // Test create campaign
    {
        sc.next_tx(campaign_owner);
        create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign short description"),
            b"sub",
            vector::empty(),
            vector::empty(),
            750_000,
            campaign_owner, // recipient_address
            0,
            U64_MAX,
        );
    };

    // Test verify campaign
    {
        sc.next_tx(verifier);
        let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
        let mut campaign = sc.take_shared<Campaign>();
        let verify_cap = sc.take_from_sender<VerifyCap>();

        // Before verify
        assert!(!crowd_walrus.is_campaign_verified(sui_object::id(&campaign)));
        assert_eq!(crowd_walrus.get_verified_campaigns_list().length(), 0);

        // Verify
        crowd_walrus.verify_campaign(&verify_cap, &mut campaign, ctx(&mut sc));

        // After verify
        assert!(crowd_walrus.is_campaign_verified(sui_object::id(&campaign)));
        assert_eq!(crowd_walrus.get_verified_campaigns_list().length(), 1);
        assert!(
            vector::contains<sui_object::ID>(
                &crowd_walrus.get_verified_campaigns_list(),
                &sui_object::id(&campaign),
            ),
        );
        assert!(campaign.is_verified());

        // Clean up
        ts::return_shared(campaign);
        sc.return_to_sender(verify_cap);
        ts::return_shared(crowd_walrus);
    };

    // Test unverify campaign
    {
        sc.next_tx(verifier);
        let mut campaign = sc.take_shared<Campaign>();
        let verify_cap = sc.take_from_sender<VerifyCap>();
        let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
        crowd_walrus.unverify_campaign(&verify_cap, &mut campaign, ctx(&mut sc));

        assert!(!crowd_walrus.is_campaign_verified(sui_object::id(&campaign)));
        assert_eq!(crowd_walrus.get_verified_campaigns_list().length(), 0);

        assert!(!campaign.is_verified());

        // Clean up
        ts::return_shared(campaign);
        sc.return_to_sender(verify_cap);
        ts::return_shared(crowd_walrus);
    };

    sc.end();
}

#[test]
public fun test_delete_campaign_happy_path() {
    let owner = USER1;
    let verifier = USER2;
    let mut sc = test_init(ADMIN);

    {
        sc.next_tx(ADMIN);
        let admin_cap = sc.take_from_sender<AdminCap>();
        let crowd = sc.take_shared<CrowdWalrus>();
        crowd_walrus::create_verify_cap(&crowd, &admin_cap, verifier, ctx(&mut sc));
        sc.return_to_sender(admin_cap);
        ts::return_shared(crowd);
    };

    sc.next_tx(owner);
    let campaign_id = create_test_campaign(
        &mut sc,
        string::utf8(b"Deletable Campaign"),
        string::utf8(b"This campaign will be deleted"),
        b"delete",
        vector::empty(),
        vector::empty(),
        900_000,
        owner,
        0,
        U64_MAX,
    );

    {
        sc.next_tx(verifier);
        let mut crowd = sc.take_shared<CrowdWalrus>();
        let mut campaign = sc.take_shared_by_id<Campaign>(campaign_id);
        let verify_cap = sc.take_from_sender<VerifyCap>();
        crowd_walrus::verify_campaign(&mut crowd, &verify_cap, &mut campaign, ctx(&mut sc));
        ts::return_shared(campaign);
        sc.return_to_sender(verify_cap);
        ts::return_shared(crowd);
    };

    {
        sc.next_tx(owner);
        let mut crowd = sc.take_shared<CrowdWalrus>();
        let suins_manager = sc.take_shared<SuiNSManager>();
        let mut suins = sc.take_shared<SuiNS>();
        let mut campaign = sc.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = sc.take_from_sender<CampaignOwnerCap>();
        let clock = sc.take_shared<Clock>();

        let delete_time = sui::clock::timestamp_ms(&clock);
        crowd_walrus::delete_campaign(
            &mut crowd,
            &suins_manager,
            &mut suins,
            &mut campaign,
            campaign_owner_cap,
            &clock,
            ctx(&mut sc),
        );

        assert!(campaign.is_deleted());
        assert!(!campaign.is_active());
        assert!(!campaign.is_verified());
        let deleted_at = campaign.deleted_at_ms();
        assert!(option::is_some(&deleted_at));
        let deleted_at_ms = option::destroy_some(deleted_at);
        assert_eq!(deleted_at_ms, delete_time);
        assert!(!crowd.is_campaign_verified(campaign_id));
        assert_eq!(crowd.get_verified_campaigns_list().length(), 0);

        let subdomain_option = suins
            .registry<Registry>()
            .lookup(domain::new(get_test_subdomain_name(b"delete")));
        assert!(!option::is_some(&subdomain_option));

        ts::return_shared(suins_manager);
        ts::return_shared(suins);
        ts::return_shared(campaign);
        ts::return_shared(clock);
        ts::return_shared(crowd);
    };

    sc.end();
}

#[test, expected_failure(abort_code = E_CAMPAIGN_DELETED, location = 0x0::campaign)]
public fun test_verify_campaign_rejects_deleted_campaign() {
    let owner = USER1;
    let verifier = USER2;
    let mut sc = test_init(ADMIN);

    {
        sc.next_tx(ADMIN);
        let admin_cap = sc.take_from_sender<AdminCap>();
        let crowd = sc.take_shared<CrowdWalrus>();
        crowd_walrus::create_verify_cap(&crowd, &admin_cap, verifier, ctx(&mut sc));
        sc.return_to_sender(admin_cap);
        ts::return_shared(crowd);
    };

    sc.next_tx(owner);
    let campaign_id = create_test_campaign(
        &mut sc,
        string::utf8(b"Deleted Campaign"),
        string::utf8(b"Should fail verification"),
        b"deletefail",
        vector::empty(),
        vector::empty(),
        700_000,
        owner,
        0,
        U64_MAX,
    );

    {
        sc.next_tx(owner);
        let mut crowd = sc.take_shared<CrowdWalrus>();
        let suins_manager = sc.take_shared<SuiNSManager>();
        let mut suins = sc.take_shared<SuiNS>();
        let mut campaign = sc.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = sc.take_from_sender<CampaignOwnerCap>();
        let clock = sc.take_shared<Clock>();

        crowd_walrus::delete_campaign(
            &mut crowd,
            &suins_manager,
            &mut suins,
            &mut campaign,
            campaign_owner_cap,
            &clock,
            ctx(&mut sc),
        );

        ts::return_shared(suins_manager);
        ts::return_shared(suins);
        ts::return_shared(campaign);
        ts::return_shared(clock);
        ts::return_shared(crowd);
    };

    {
        sc.next_tx(verifier);
        let mut crowd = sc.take_shared<CrowdWalrus>();
        let mut campaign = sc.take_shared_by_id<Campaign>(campaign_id);
        let verify_cap = sc.take_from_sender<VerifyCap>();
        crowd_walrus::verify_campaign(&mut crowd, &verify_cap, &mut campaign, ctx(&mut sc));
        ts::return_shared(campaign);
        sc.return_to_sender(verify_cap);
        ts::return_shared(crowd);
    };

    sc.end();
}

#[test, expected_failure(abort_code = E_APP_NOT_AUTHORIZED, location = 0x0::campaign)]
public fun test_delete_campaign_requires_matching_cap() {
    let owner = USER1;
    let mut sc = test_init(ADMIN);

    sc.next_tx(owner);
    let campaign_a_id = create_test_campaign(
        &mut sc,
        string::utf8(b"Campaign A"),
        string::utf8(b"First"),
        b"deletea",
        vector::empty(),
        vector::empty(),
        600_000,
        owner,
        0,
        U64_MAX,
    );

    sc.next_tx(owner);
    let cap_a = sc.take_from_sender<CampaignOwnerCap>();
    let campaign_a_cap_id = campaign::campaign_id(&cap_a);
    sc.return_to_sender(cap_a);

    sc.next_tx(owner);
    let _campaign_b_id = create_test_campaign(
        &mut sc,
        string::utf8(b"Campaign B"),
        string::utf8(b"Second"),
        b"deleteb",
        vector::empty(),
        vector::empty(),
        600_000,
        owner,
        0,
        U64_MAX,
    );

    sc.next_tx(owner);
    let mut crowd = sc.take_shared<CrowdWalrus>();
    let suins_manager = sc.take_shared<SuiNSManager>();
    let mut suins = sc.take_shared<SuiNS>();
    let mut campaign_a = sc.take_shared_by_id<Campaign>(campaign_a_id);
    let cap1 = sc.take_from_sender<CampaignOwnerCap>();
    let cap2 = sc.take_from_sender<CampaignOwnerCap>();
    let wrong_cap;
    if (campaign::campaign_id(&cap1) == campaign_a_cap_id) {
        sc.return_to_sender(cap1);
        wrong_cap = cap2;
    } else {
        sc.return_to_sender(cap2);
        wrong_cap = cap1;
    };
    let clock = sc.take_shared<Clock>();

    crowd_walrus::delete_campaign(
        &mut crowd,
        &suins_manager,
        &mut suins,
        &mut campaign_a,
        wrong_cap,
        &clock,
        ctx(&mut sc),
    );

    ts::return_shared(suins_manager);
    ts::return_shared(suins);
    ts::return_shared(crowd);
    ts::return_shared(campaign_a);
    ts::return_shared(clock);
    sc.end();
}

#[test, expected_failure(abort_code = crowd_walrus::E_ALREADY_VERIFIED)]
public fun test_verify_campaign_twice() {
    let verifier = USER1;
    let campaign_owner = USER2;

    let mut sc = test_init(ADMIN);

    // Test create verify cap
    {
        sc.next_tx(ADMIN);
        let admin_cap = sc.take_from_sender<AdminCap>();
        let crowd_walrus = sc.take_shared<CrowdWalrus>();

        crowd_walrus.create_verify_cap(&admin_cap, verifier, ctx(&mut sc));

        sc.return_to_sender(admin_cap);
        ts::return_shared(crowd_walrus);
    };

    // Test create campaign
    {
        sc.next_tx(campaign_owner);
        create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign short description"),
            b"sub",
            vector::empty(),
            vector::empty(),
            800_000,
            campaign_owner, // recipient_address
            0,
            U64_MAX,
        );
    };

    // Verify campaign
    {
        sc.next_tx(verifier);
        let mut campaign = sc.take_shared<Campaign>();
        let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
        let verify_cap = sc.take_from_sender<VerifyCap>();
        crowd_walrus.verify_campaign(&verify_cap, &mut campaign, ctx(&mut sc));

        // Clean up
        ts::return_shared(campaign);
        sc.return_to_sender(verify_cap);
        ts::return_shared(crowd_walrus);
    };

    // Verify campaign again
    {
        sc.next_tx(verifier);
        let mut campaign = sc.take_shared<Campaign>();
        let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
        let verify_cap = sc.take_from_sender<VerifyCap>();
        crowd_walrus.verify_campaign(&verify_cap, &mut campaign, ctx(&mut sc));

        // Clean up
        ts::return_shared(campaign);
        sc.return_to_sender(verify_cap);
        ts::return_shared(crowd_walrus);
    };

    sc.end();
}

#[test]
public fun test_delete_campaign_tolerates_missing_subdomain() {
    let owner = USER1;
    let mut sc = test_init(ADMIN);

    let subdomain = get_test_subdomain_name(b"deletemissing");

    sc.next_tx(owner);
    let campaign_id = create_test_campaign(
        &mut sc,
        string::utf8(b"Missing Subdomain Campaign"),
        string::utf8(b"Manual removal of subdomain"),
        b"deletemissing",
        vector::empty(),
        vector::empty(),
        650_000,
        owner,
        0,
        U64_MAX,
    );

    {
        sc.next_tx(ADMIN);
        let suins_manager = sc.take_shared<SuiNSManager>();
        let mut suins = sc.take_shared<SuiNS>();
        let clock = sc.take_shared<Clock>();
        let admin_cap = sc.take_from_address<SuiNSManagerAdminCap>(ADMIN);

        suins_manager::remove_subdomain(
            &suins_manager,
            &admin_cap,
            &mut suins,
            subdomain,
            &clock,
        );

        ts::return_to_address(ADMIN, admin_cap);
        ts::return_shared(suins_manager);
        ts::return_shared(suins);
        ts::return_shared(clock);
    };

    {
        sc.next_tx(owner);
        let mut crowd = sc.take_shared<CrowdWalrus>();
        let suins_manager = sc.take_shared<SuiNSManager>();
        let mut suins = sc.take_shared<SuiNS>();
        let mut campaign = sc.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = sc.take_from_sender<CampaignOwnerCap>();
        let clock = sc.take_shared<Clock>();

        crowd_walrus::delete_campaign(
            &mut crowd,
            &suins_manager,
            &mut suins,
            &mut campaign,
            campaign_owner_cap,
            &clock,
            ctx(&mut sc),
        );

        assert!(campaign.is_deleted());
        assert!(!crowd.is_campaign_verified(campaign_id));

        ts::return_shared(suins_manager);
        ts::return_shared(suins);
        ts::return_shared(campaign);
        ts::return_shared(clock);
        ts::return_shared(crowd);
    };

    sc.end();
}

#[test, expected_failure(abort_code = crowd_walrus::E_NOT_VERIFIED)]
public fun test_unverify_invalid_campaign() {
    let verifier = USER1;
    let campaign_owner = USER2;

    let mut sc = test_init(ADMIN);

    // Test create verify cap
    {
        sc.next_tx(ADMIN);
        let admin_cap = sc.take_from_sender<AdminCap>();
        let crowd_walrus = sc.take_shared<CrowdWalrus>();

        crowd_walrus.create_verify_cap(&admin_cap, verifier, ctx(&mut sc));

        sc.return_to_sender(admin_cap);
        ts::return_shared(crowd_walrus);
    };

    // Test create campaign
    {
        sc.next_tx(campaign_owner);
        create_test_campaign(
            &mut sc,
            string::utf8(b"Test Campaign"),
            string::utf8(b"A test campaign short description"),
            b"sub",
            vector::empty(),
            vector::empty(),
            800_000,
            campaign_owner, // recipient_address
            0,
            U64_MAX,
        );
    };

    // Test unverify campaign
    {
        sc.next_tx(verifier);
        let verify_cap = sc.take_from_sender<VerifyCap>();
        let mut campaign = sc.take_shared<Campaign>();
        let mut crowd_walrus = sc.take_shared<CrowdWalrus>();
        crowd_walrus.unverify_campaign(&verify_cap, &mut campaign, ctx(&mut sc));
        sc.return_to_sender(verify_cap);
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
    short_description: String,
    subname: vector<u8>,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    funding_goal_usd_micro: u64,
    recipient_address: address,
    start_date: u64,
    end_date: u64,
): sui_object::ID {
    create_test_campaign_with_policy(
        sc,
        title,
        short_description,
        subname,
        metadata_keys,
        metadata_values,
        funding_goal_usd_micro,
        recipient_address,
        option::none(),
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        start_date,
        end_date,
    )
}

public fun create_test_campaign_with_policy(
    sc: &mut Scenario,
    title: String,
    short_description: String,
    subname: vector<u8>,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    funding_goal_usd_micro: u64,
    recipient_address: address,
    policy_name: option::Option<String>,
    platform_bps: u16,
    platform_address: address,
    start_date: u64,
    end_date: u64,
): sui_object::ID {
    let crowd_walrus = sc.take_shared<CrowdWalrus>();
    let policy_registry = sc.take_shared<platform_policy::PolicyRegistry>();
    let mut profiles_registry = sc.take_shared<profiles::ProfilesRegistry>();
    let suins_manager = sc.take_shared<SuiNSManager>();
    let mut suins = sc.take_shared<SuiNS>();
    let clock = sc.take_shared<Clock>();
    let subdomain_name = get_test_subdomain_name(subname);
    let campaign_id = crowd_walrus::create_campaign(
        &crowd_walrus,
        &policy_registry,
        &mut profiles_registry,
        &suins_manager,
        &mut suins,
        &clock,
        title,
        short_description,
        subdomain_name,
        metadata_keys,
        metadata_values,
        funding_goal_usd_micro,
        recipient_address,
        policy_name,
        platform_bps,
        platform_address,
        start_date,
        end_date,
        ctx(sc),
    );
    ts::return_shared(crowd_walrus);
    ts::return_shared(policy_registry);
    ts::return_shared(profiles_registry);
    ts::return_shared(suins);
    ts::return_shared(clock);
    ts::return_shared(suins_manager);
    campaign_id
}

#[test_only]
public fun create_unshared_campaign(
    sc: &mut Scenario,
    title: String,
    short_description: String,
    subname: vector<u8>,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    funding_goal_usd_micro: u64,
    recipient_address: address,
    platform_bps: u16,
    platform_address: address,
    start_date: u64,
    end_date: u64,
): (Campaign, CampaignOwnerCap, Clock) {
    let crowd_walrus = sc.take_shared<CrowdWalrus>();
    let clock = sc.take_shared<Clock>();
    let app = crowd_walrus::get_app();
    let payout_policy = campaign::new_payout_policy(platform_bps, platform_address, recipient_address);
    let subdomain_name = get_test_subdomain_name(subname);
    let metadata = sui::vec_map::from_keys_values(metadata_keys, metadata_values);
    let (campaign, owner_cap) = campaign::new(
        &app,
        sui_object::id(&crowd_walrus),
        title,
        short_description,
        subdomain_name,
        metadata,
        funding_goal_usd_micro,
        payout_policy,
        start_date,
        end_date,
        &clock,
        ctx(sc),
    );
    ts::return_shared(crowd_walrus);
    (campaign, owner_cap, clock)
}

#[test]
public fun test_create_campaign_auto_creates_profile_and_stats() {
    let mut sc = test_init(ADMIN);

    sc.next_tx(USER1);
    let registry_check = sc.take_shared<profiles::ProfilesRegistry>();
    assert!(!profiles::exists(&registry_check, USER1));
    ts::return_shared(registry_check);
    ts::next_tx(&mut sc, USER1);

    sc.next_tx(USER1);
    let crowd_walrus = sc.take_shared<CrowdWalrus>();
    let policy_registry = sc.take_shared<platform_policy::PolicyRegistry>();
    let mut profiles_registry = sc.take_shared<profiles::ProfilesRegistry>();
    let suins_manager = sc.take_shared<SuiNSManager>();
    let mut suins = sc.take_shared<SuiNS>();
    let clock = sc.take_shared<Clock>();
    let subdomain_name = get_test_subdomain_name(b"profile-auto");
    let campaign_id = crowd_walrus::create_campaign(
        &crowd_walrus,
        &policy_registry,
        &mut profiles_registry,
        &suins_manager,
        &mut suins,
        &clock,
        string::utf8(b"Auto Profile"),
        string::utf8(b"Creates profile if missing"),
        subdomain_name,
        vector::empty(),
        vector::empty(),
        2_000_000,
        USER1,
        option::none(),
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
        ctx(&mut sc),
    );
    ts::return_shared(crowd_walrus);
    ts::return_shared(policy_registry);
    ts::return_shared(profiles_registry);
    ts::return_shared(suins);
    ts::return_shared(clock);
    ts::return_shared(suins_manager);
    let effects = ts::next_tx(&mut sc, USER1);
    assert_eq!(ts::num_user_events(&effects), 3);

    sc.next_tx(USER1);
    let registry_after = sc.take_shared<profiles::ProfilesRegistry>();
    assert!(profiles::exists(&registry_after, USER1));
    let profile_id = profiles::id_of(&registry_after, USER1);
    assert!(sui_object::id_to_address(&profile_id) != @0x0);
    ts::return_shared(registry_after);

    let campaign = sc.take_shared_by_id<Campaign>(campaign_id);
    let stats_id = campaign::stats_id(&campaign);
    assert!(sui_object::id_to_address(&stats_id) != @0x0);
    ts::return_shared(campaign);

    let stats = sc.take_shared_by_id<campaign_stats::CampaignStats>(stats_id);
    assert_eq!(campaign_stats::total_usd_micro(&stats), 0);
    assert_eq!(campaign_stats::total_donations_count(&stats), 0);
    ts::return_shared(stats);

    ts::next_tx(&mut sc, USER1);
    sc.end();
}

#[test]
public fun test_create_campaign_uses_policy_preset() {
    let mut sc = test_init(ADMIN);
    let preset_bps: u16 = 250;
    let preset_address: address = USER2;

    sc.next_tx(ADMIN);
    let mut policy_registry = sc.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = sc.take_from_sender<AdminCap>();
    let clock = sc.take_shared<Clock>();
    crowd_walrus::add_platform_policy_internal(
        &mut policy_registry,
        &admin_cap,
        string::utf8(b"nonprofit"),
        preset_bps,
        preset_address,
        &clock,
    );
    ts::return_shared(policy_registry);
    ts::return_shared(clock);
    sc.return_to_sender(admin_cap);
    ts::next_tx(&mut sc, ADMIN);

    sc.next_tx(USER1);
    let crowd_walrus = sc.take_shared<CrowdWalrus>();
    let policy_registry = sc.take_shared<platform_policy::PolicyRegistry>();
    let mut profiles_registry = sc.take_shared<profiles::ProfilesRegistry>();
    let suins_manager = sc.take_shared<SuiNSManager>();
    let mut suins = sc.take_shared<SuiNS>();
    let clock = sc.take_shared<Clock>();
    let subdomain_name = get_test_subdomain_name(b"preset-success");
    let fallback_bps: u16 = 900;
    let fallback_address: address = ADMIN;
    let campaign_id = crowd_walrus::create_campaign(
        &crowd_walrus,
        &policy_registry,
        &mut profiles_registry,
        &suins_manager,
        &mut suins,
        &clock,
        string::utf8(b"Preset Snapshot"),
        string::utf8(b"Uses preset values"),
        subdomain_name,
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        option::some(string::utf8(b"nonprofit")),
        fallback_bps,
        fallback_address,
        0,
        U64_MAX,
        ctx(&mut sc),
    );
    ts::return_shared(crowd_walrus);
    ts::return_shared(policy_registry);
    ts::return_shared(profiles_registry);
    ts::return_shared(suins);
    ts::return_shared(clock);
    ts::return_shared(suins_manager);
    ts::next_tx(&mut sc, USER1);

    sc.next_tx(USER1);
    let campaign = sc.take_shared_by_id<Campaign>(campaign_id);
    assert_eq!(campaign::payout_platform_bps(&campaign), preset_bps);
    assert_eq!(campaign::payout_platform_address(&campaign), preset_address);
    assert_eq!(campaign::payout_recipient_address(&campaign), USER1);
    ts::return_shared(campaign);
    sc.end();
}

#[test, expected_failure(abort_code = platform_policy::E_POLICY_NOT_FOUND, location = 0x0::platform_policy)]
public fun test_create_campaign_with_missing_preset_aborts() {
    let mut sc = test_init(ADMIN);

    sc.next_tx(USER1);
    create_test_campaign_with_policy(
        &mut sc,
        string::utf8(b"Missing Preset Fails"),
        string::utf8(b""),
        b"missing-preset",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        option::some(string::utf8(b"does-not-exist")),
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );
    sc.end();
}

#[test, expected_failure(abort_code = platform_policy::E_POLICY_DISABLED, location = 0x0::platform_policy)]
public fun test_create_campaign_with_disabled_preset_aborts() {
    let mut sc = test_init(ADMIN);

    sc.next_tx(ADMIN);
    let mut policy_registry = sc.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = sc.take_from_sender<AdminCap>();
    let clock = sc.take_shared<Clock>();
    crowd_walrus::add_platform_policy_internal(
        &mut policy_registry,
        &admin_cap,
        string::utf8(b"disabled"),
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        &clock,
    );
    ts::return_shared(policy_registry);
    ts::return_shared(clock);
    sc.return_to_sender(admin_cap);
    ts::next_tx(&mut sc, ADMIN);

    sc.next_tx(ADMIN);
    let mut policy_registry = sc.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = sc.take_from_sender<AdminCap>();
    let clock = sc.take_shared<Clock>();
    crowd_walrus::disable_platform_policy_internal(
        &mut policy_registry,
        &admin_cap,
        string::utf8(b"disabled"),
        &clock,
    );
    ts::return_shared(policy_registry);
    ts::return_shared(clock);
    sc.return_to_sender(admin_cap);
    ts::next_tx(&mut sc, ADMIN);

    sc.next_tx(USER1);
    create_test_campaign_with_policy(
        &mut sc,
        string::utf8(b"Disabled Preset Fails"),
        string::utf8(b""),
        b"disabled-preset",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        option::some(string::utf8(b"disabled")),
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );
    sc.end();
}
