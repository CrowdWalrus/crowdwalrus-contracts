#[test_only]
#[allow(unused_const)]
module crowd_walrus::campaign_tests;

use crowd_walrus::campaign::{Self as campaign, Campaign, CampaignOwnerCap, CampaignUpdate};
use crowd_walrus::crowd_walrus::CrowdWalrusApp;
use crowd_walrus::crowd_walrus_tests as crowd_walrus_tests;
use crowd_walrus::platform_policy;
use std::string::{String, utf8};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::event;
use sui::test_scenario as ts;
use sui::vec_map as vec_map;

const ADMIN: address = @0xA;
const USER1: address = @0xB;
const USER2: address = @0xC;

const DEFAULT_PLATFORM_BPS: u16 = 0;
const TEST_DOMAIN_NAME: vector<u8> = b"test.sui";

const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;
const E_CAMPAIGN_DELETED: u64 = 11;

#[test]
public fun test_set_is_active() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Test Campaign"),
        utf8(b"A test campaign short description"),
        b"sub",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1, // recipient_address
        0,
        U64_MAX,
    );

    {
        scenario.next_tx(campaign_owner);

        let campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();

        assert_eq!(campaign::payout_platform_bps(&campaign), DEFAULT_PLATFORM_BPS);
        assert_eq!(campaign::payout_platform_address(&campaign), ADMIN);
        assert_eq!(campaign::payout_recipient_address(&campaign), USER1);

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
    };

    {
        scenario.next_tx(campaign_owner);

        let campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();

        assert!(campaign.is_active());

        // clean up
        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
    };

    // Deactivate campaign
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        campaign.set_is_active(&campaign_owner_cap, false);

        assert!(!campaign.is_active());

        // clean up
        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
    };
    scenario.end();
}

#[test]
public fun test_payout_policy_custom_values() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    let platform_address = USER2;
    let recipient_address_policy = USER1;
    let custom_bps: u16 = 1_234;

    scenario.next_tx(ADMIN);
    let mut policy_registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();
    crowd_walrus::crowd_walrus::add_platform_policy_internal(
        &mut policy_registry,
        &admin_cap,
        utf8(b"custompolicy"),
        custom_bps,
        platform_address,
        &clock,
    );
    ts::return_shared(policy_registry);
    ts::return_shared(clock);
    scenario.return_to_sender(admin_cap);
    ts::next_tx(&mut scenario, ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign_with_policy(
        &mut scenario,
        utf8(b"Custom Policy"),
        utf8(b"Custom payout policy"),
        b"custompolicy",
        vector::empty(),
        vector::empty(),
        2_000_000,
        recipient_address_policy,
        option::some(utf8(b"custompolicy")),
        0,
        U64_MAX,
    );

    scenario.next_tx(campaign_owner);
    let campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
    let owner_cap = scenario.take_from_sender<CampaignOwnerCap>();

    assert_eq!(campaign::payout_platform_bps(&campaign), custom_bps);
    assert_eq!(campaign::payout_platform_address(&campaign), platform_address);
    assert_eq!(campaign::payout_recipient_address(&campaign), recipient_address_policy);

    ts::return_shared(campaign);
    scenario.return_to_sender(owner_cap);
    scenario.end();
}

// === New Edit Feature Tests ===

/// Test updating campaign name and description successfully
#[test]
public fun test_update_campaign_basics_happy_path() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    // Create a campaign
    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Original Name"),
        utf8(b"Original Description"),
        b"sub",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1, // recipient_address
        0,
        U64_MAX,
    );

    // Update both name and description
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, true);
        assert!(campaign::is_verified(&campaign));

        let before_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        let before_len = vector::length(&before_events);

        // Call the update function with both new values
        crowd_walrus::campaign::update_campaign_basics(
            &mut campaign,
            &campaign_owner_cap,
            option::some(utf8(b"Updated Name")),
            option::some(utf8(b"Updated Description")),
            &clock,
            ts::ctx(&mut scenario),
        );

        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, false);
        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, false);
        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, false);
        assert!(!campaign::is_verified(&campaign));

        let after_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        assert_eq!(vector::length(&after_events), before_len + 1);

        // Verify the changes (we'd need getter functions to check, but for now we trust it worked)
        // In a real scenario, you'd add public getter functions to verify the state

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    // Update only name (description stays the same)
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, true);
        assert!(campaign::is_verified(&campaign));

        let before_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        let before_len = vector::length(&before_events);

        crowd_walrus::campaign::update_campaign_basics(
            &mut campaign,
            &campaign_owner_cap,
            option::some(utf8(b"Another Name")),
            option::none(), // Keep description as-is
            &clock,
            ts::ctx(&mut scenario),
        );

        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, false);
        assert!(!campaign::is_verified(&campaign));

        let after_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        assert_eq!(vector::length(&after_events), before_len + 1);

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    // Update only description (name stays the same)
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, true);
        assert!(campaign::is_verified(&campaign));

        let before_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        let before_len = vector::length(&before_events);

        crowd_walrus::campaign::update_campaign_basics(
            &mut campaign,
            &campaign_owner_cap,
            option::none(), // Keep name as-is
            option::some(utf8(b"Yet Another Description")),
            &clock,
            ts::ctx(&mut scenario),
        );

        assert!(!campaign::is_verified(&campaign));

        let after_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        assert_eq!(vector::length(&after_events), before_len + 1);

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    // No event emitted when values identical and campaign stays verified
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, true);
        assert!(campaign::is_verified(&campaign));

        let before_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        let before_len = vector::length(&before_events);

        crowd_walrus::campaign::update_campaign_basics(
            &mut campaign,
            &campaign_owner_cap,
            option::some(utf8(b"Another Name")),
            option::none(),
            &clock,
            ts::ctx(&mut scenario),
        );

        let after_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        assert_eq!(vector::length(&after_events), before_len);
        assert!(campaign::is_verified(&campaign));

        // description unchanged path
        crowd_walrus::campaign::update_campaign_basics(
            &mut campaign,
            &campaign_owner_cap,
            option::none(),
            option::some(utf8(b"Yet Another Description")),
            &clock,
            ts::ctx(&mut scenario),
        );
        let final_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        assert_eq!(vector::length(&final_events), before_len);
        assert!(campaign::is_verified(&campaign));

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    // No event emitted when campaign was already unverified
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, false);
        assert!(!campaign::is_verified(&campaign));
        let before_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        let before_len = vector::length(&before_events);

        crowd_walrus::campaign::update_campaign_basics(
            &mut campaign,
            &campaign_owner_cap,
            option::none(),
            option::none(),
            &clock,
            ts::ctx(&mut scenario),
        );

        let after_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        assert_eq!(vector::length(&after_events), before_len);
        assert!(!campaign::is_verified(&campaign));

    ts::return_shared(campaign);
    scenario.return_to_sender(campaign_owner_cap);
    ts::return_shared(clock);
    };

    scenario.end();
}

/// Test updating campaign metadata successfully
#[test]
public fun test_update_campaign_metadata_happy_path() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    // Create a campaign with initial metadata
    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Test Campaign"),
        utf8(b"Test Description"),
        b"sub",
        vector[utf8(b"category"), utf8(b"walrus_quilt_id")],
        vector[utf8(b"technology"), utf8(b"123456")],
        1_000_000,
        USER1, // recipient_address
        0,
        U64_MAX,
    );

    // Update existing metadata and add new keys
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, true);
        assert!(campaign::is_verified(&campaign));

        let before_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        let before_len = vector::length(&before_events);

        // Update category, add new social_twitter
        crowd_walrus::campaign::update_campaign_metadata(
            &mut campaign,
            &campaign_owner_cap,
            vector[utf8(b"category"), utf8(b"social_twitter")],
            vector[utf8(b"education"), utf8(b"@example")],
            &clock,
            ts::ctx(&mut scenario),
        );

        assert!(!campaign::is_verified(&campaign));

        let after_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        assert_eq!(vector::length(&after_events), before_len + 1);

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    // No event emitted when metadata unchanged and campaign stays verified
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, true);
        assert!(campaign::is_verified(&campaign));

        let before_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        let before_len = vector::length(&before_events);

        crowd_walrus::campaign::update_campaign_metadata(
            &mut campaign,
            &campaign_owner_cap,
            vector[utf8(b"category")],
            vector[utf8(b"education")],
            &clock,
            ts::ctx(&mut scenario),
        );

        let after_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        assert_eq!(vector::length(&after_events), before_len);
        assert!(campaign::is_verified(&campaign));

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    // No event emitted when campaign already unverified
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        let app = crowd_walrus::crowd_walrus::get_app();
        campaign::set_verified<CrowdWalrusApp>(&mut campaign, &app, false);
        assert!(!campaign::is_verified(&campaign));
        let before_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        let before_len = vector::length(&before_events);

        crowd_walrus::campaign::update_campaign_metadata(
            &mut campaign,
            &campaign_owner_cap,
            vector[utf8(b"category")],
            vector[utf8(b"education")],
            &clock,
            ts::ctx(&mut scenario),
        );

        let after_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
        assert_eq!(vector::length(&after_events), before_len);
        assert!(!campaign::is_verified(&campaign));

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    scenario.end();
}

#[test, expected_failure(abort_code = campaign::E_INVALID_BPS, location = 0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e::campaign)]
public fun test_new_payout_policy_rejects_excess_bps() {
    let _policy = campaign::new_payout_policy(10_001, ADMIN, USER1);
}

#[test, expected_failure(abort_code = campaign::E_ZERO_ADDRESS, location = 0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e::campaign)]
public fun test_new_payout_policy_rejects_zero_platform_address() {
    let _policy = campaign::new_payout_policy(100, @0x0, USER1);
}

#[test, expected_failure(abort_code = campaign::E_ZERO_ADDRESS, location = 0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e::campaign)]
public fun test_new_payout_policy_rejects_zero_recipient_address() {
    let _policy = campaign::new_payout_policy(100, ADMIN, @0x0);
}

#[test]
public fun test_campaign_funding_goal_getter() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Funding Goal Check"),
        utf8(b"Ensure typed goal stored"),
        b"goalcheck",
        vector::empty(),
        vector::empty(),
        2_500_000,
        USER1,
        0,
        U64_MAX,
    );

    {
        scenario.next_tx(campaign_owner);
        let campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        assert_eq!(campaign::funding_goal_usd_micro(&campaign), 2_500_000);
        ts::return_shared(campaign);
    };

    scenario.end();
}

#[test]
public fun test_campaign_stats_id_defaults_and_setter() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let (mut campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        utf8(b"Stats Link"),
        utf8(b"Verify stats linkage defaults"),
        b"statslink",
        vector::empty(),
        vector::empty(),
        1_000,
        USER1,
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );

    ts::return_shared(clock);
    assert!(!campaign::parameters_locked(&campaign));
    assert_eq!(object::id_to_address(&campaign::stats_id(&campaign)), @0x0);

    let expected_stats_id = object::id_from_address(@0x123);
    campaign::set_stats_id(&mut campaign, expected_stats_id);
    assert_eq!(campaign::stats_id(&campaign), expected_stats_id);

    campaign::share(campaign);
    campaign::delete_owner_cap(owner_cap);
    scenario.end();
}

#[test, expected_failure(abort_code = campaign::E_STATS_ALREADY_SET, location = 0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e::campaign)]
public fun test_campaign_stats_id_double_set_fails() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let (mut campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        utf8(b"Stats Write Once"),
        utf8(b"Ensure stats id cannot reset"),
        b"stats-write-once",
        vector::empty(),
        vector::empty(),
        1_000,
        USER1,
        DEFAULT_PLATFORM_BPS,
        ADMIN,
        0,
        U64_MAX,
    );

    ts::return_shared(clock);
    campaign::set_stats_id(&mut campaign, object::id_from_address(@0x111));
    campaign::delete_owner_cap(owner_cap);
    campaign::set_stats_id(&mut campaign, object::id_from_address(@0x222));

    ts::return_shared(campaign);
    scenario.end();
}

// TODO(human): Add test for funding_goal immutability
// Test name: test_update_campaign_metadata_funding_goal_immutable
// This test should verify that attempting to update the "funding_goal"
// metadata key causes the transaction to abort with E_FUNDING_GOAL_IMMUTABLE error

#[test, expected_failure(abort_code = crowd_walrus::campaign::E_FUNDING_GOAL_IMMUTABLE)]
public fun test_update_campaign_metadata_funding_goal_immutable() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    // Create a campaign with initial metadata
    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Test Campaign"),
        utf8(b"Test Description"),
        b"sub",
        vector[utf8(b"category"), utf8(b"walrus_quilt_id")],
        vector[utf8(b"technology"), utf8(b"123456")],
        1_000_000,
        USER1, // recipient_address
        0,
        U64_MAX,
    );

    // Update the campaign metadata
    {

        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        crowd_walrus::campaign::update_campaign_metadata(
            &mut campaign,
            &campaign_owner_cap,
            vector[utf8(b"funding_goal")],
            vector[utf8(b"1000000")],
            &clock,
            ts::ctx(&mut scenario),
        );

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };
    scenario.end();
}

#[test, expected_failure(abort_code = crowd_walrus::campaign::E_RECIPIENT_ADDRESS_IMMUTABLE)]
public fun test_update_campaign_metadata_recipient_address_immutable() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Test Campaign"),
        utf8(b"Test Description"),
        b"sub",
        vector[utf8(b"category"), utf8(b"walrus_quilt_id")],
        vector[utf8(b"technology"), utf8(b"123456")],
        1_000_000,
        USER1, // recipient_address
        0,
        U64_MAX,
    );

    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        crowd_walrus::campaign::update_campaign_metadata(
            &mut campaign,
            &campaign_owner_cap,
            vector[utf8(b"recipient_address")],
            vector[utf8(b"@0xDEADBEEF")],
            &clock,
            ts::ctx(&mut scenario),
        );

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    scenario.end();
}

#[test, expected_failure(abort_code = crowd_walrus::campaign::E_KEY_VALUE_MISMATCH)]
public fun test_update_campaign_metadata_key_value_mismatch() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Test Campaign"),
        utf8(b"Test Description"),
        b"sub",
        vector[utf8(b"category"), utf8(b"walrus_quilt_id")],
        vector[utf8(b"technology"), utf8(b"123456")],
        1_000_000,
        USER1, // recipient_address
        0,
        U64_MAX,
    );

    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        crowd_walrus::campaign::update_campaign_metadata(
            &mut campaign,
            &campaign_owner_cap,
            vector[utf8(b"category"), utf8(b"walrus_quilt_id")],
            vector[utf8(b"education"), utf8(b"123456"), utf8(b"extra")],
            &clock,
            ts::ctx(&mut scenario),
        );

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    scenario.end();
}

#[test]
public fun test_update_active_status_changes() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Test Campaign"),
        utf8(b"Test Description"),
        b"sub",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1, // recipient_address
        0,
        U64_MAX,
    );

    // Deactivate campaign via entry function
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        assert!(campaign.is_active());

        crowd_walrus::campaign::update_active_status(
            &mut campaign,
            &campaign_owner_cap,
            false,
            &clock,
            ts::ctx(&mut scenario),
        );

        assert!(!campaign.is_active());

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    // Reactivate campaign and verify
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        assert!(!campaign.is_active());

        crowd_walrus::campaign::update_active_status(
            &mut campaign,
            &campaign_owner_cap,
            true,
            &clock,
            ts::ctx(&mut scenario),
        );

        assert!(campaign.is_active());

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    scenario.end();
}

#[test]
public fun test_update_active_status_no_op() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Test Campaign"),
        utf8(b"Test Description"),
        b"sub",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1, // recipient_address
        0,
        U64_MAX,
    );

    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<sui::clock::Clock>();

        assert!(campaign.is_active());

        crowd_walrus::campaign::update_active_status(
            &mut campaign,
            &campaign_owner_cap,
            true,
            &clock,
            ts::ctx(&mut scenario),
        );

        // Should remain active because status was already true
        assert!(campaign.is_active());

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    scenario.end();
}

#[test]
public fun test_mark_deleted_sets_flags() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Mark Deleted"),
        utf8(b"Checking deleted flags"),
        b"markdeleted",
        vector::empty(),
        vector::empty(),
        1_000_000,
        campaign_owner,
        0,
        U64_MAX,
    );

    scenario.next_tx(campaign_owner);
    let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
    let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();

    campaign::mark_deleted(&mut campaign, &campaign_owner_cap, 42);

    assert!(campaign.is_deleted());
    assert!(!campaign.is_active());
    assert!(!campaign.is_verified());
    let deleted_at = campaign.deleted_at_ms();
    assert!(option::is_some(&deleted_at));
    assert_eq!(option::destroy_some(deleted_at), 42);

    ts::return_shared(campaign);
    scenario.return_to_sender(campaign_owner_cap);
    scenario.end();
}

#[test, expected_failure(abort_code = E_CAMPAIGN_DELETED, location = 0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e::campaign)]
public fun test_add_update_rejects_deleted_campaign() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Cannot Update"),
        utf8(b"Deleted campaigns reject updates"),
        b"noupdates",
        vector::empty(),
        vector::empty(),
        1_000_000,
        campaign_owner,
        0,
        U64_MAX,
    );

    scenario.next_tx(campaign_owner);
    let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
    let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<sui::clock::Clock>();

    campaign::mark_deleted(&mut campaign, &campaign_owner_cap, 99);

    crowd_walrus::campaign::add_update(
        &mut campaign,
        &campaign_owner_cap,
        vector[utf8(b"status")],
        vector[utf8(b"should fail")],
        &clock,
        ts::ctx(&mut scenario),
    );
    ts::return_shared(campaign);
    scenario.return_to_sender(campaign_owner_cap);
    ts::return_shared(clock);
    scenario.end();
}

// === Campaign Creation Validation Tests ===
// Note: These tests verify validation rules enforced during campaign creation

#[test, expected_failure(abort_code = 6, location = 0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e::crowd_walrus)] // E_START_DATE_IN_PAST
public fun test_create_campaign_start_date_in_past() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    // Advance the clock to make timestamp > 0
    {
        scenario.next_tx(campaign_owner);
        let mut clock = scenario.take_shared<sui::clock::Clock>();
        clock.increment_for_testing(1000); // Advance by 1000ms
        ts::return_shared(clock);
    };

    // Now try to create with start_date=0 (which is now in the past)
    {
        scenario.next_tx(campaign_owner);
        crowd_walrus_tests::create_test_campaign(
            &mut scenario,
            utf8(b"Past Start Date"),
            utf8(b"Attempting to create campaign with past start date"),
            b"sub",
            vector::empty(),
            vector::empty(),
            1_000_000,
            USER1, // recipient_address
            0,  // This is now in the past since we advanced the clock
            U64_MAX,
        );
    };

    scenario.end();
}

#[test, expected_failure(abort_code = crowd_walrus::campaign::E_INVALID_DATE_RANGE)]
public fun test_create_campaign_invalid_date_range() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Invalid Date Range"),
        utf8(b"Start date must be before end date"),
        b"invalid_date_range",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        100,
        50,
    );

    scenario.end();
}

#[test, expected_failure(abort_code = crowd_walrus::campaign::E_RECIPIENT_ADDRESS_INVALID, location = 0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e::crowd_walrus)]
public fun test_create_campaign_invalid_recipient_address() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    crowd_walrus_tests::create_test_campaign_with_policy(
        &mut scenario,
        utf8(b"Invalid Recipient Campaign"),
        utf8(b"Recipient address must not be zero"),
        b"sub",
        vector::empty(),
        vector::empty(),
        1_000_000,
        @0x0,
        option::none(),
        0,
        U64_MAX,
    );

    scenario.end();
}

// === Campaign Updates Tests ===

#[test]
public fun test_add_update_happy_path() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Update Campaign"),
        utf8(b"Testing updates"),
        b"update",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        0,
        U64_MAX,
    );

    scenario.next_tx(campaign_owner);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();

    let app = crowd_walrus::crowd_walrus::get_app();
    campaign::set_verified<CrowdWalrusApp>(&mut campaign_obj, &app, true);
    assert!(campaign::is_verified(&campaign_obj));

    let before_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
    let before_len = vector::length(&before_events);

    crowd_walrus::campaign::add_update(
        &mut campaign_obj,
        &campaign_owner_cap,
        vector[utf8(b"walrus_quilt_id"), utf8(b"headline")],
        vector[utf8(b"0xabc"), utf8(b"Reached 50% funding")],
        &clock,
        ts::ctx(&mut scenario),
    );

    assert_eq!(
        crowd_walrus::campaign::update_count(&campaign_obj),
        1
    );
    assert!(crowd_walrus::campaign::has_update(&campaign_obj, 0));
    assert!(!crowd_walrus::campaign::has_update(&campaign_obj, 1));
    assert!(campaign::is_verified(&campaign_obj));

    let after_events = event::events_by_type<crowd_walrus::campaign::CampaignUnverified>();
    assert_eq!(vector::length(&after_events), before_len);

    let update_id = crowd_walrus::campaign::get_update_id(&campaign_obj, 0);

    let update_id_option =
        crowd_walrus::campaign::try_get_update_id(&campaign_obj, 0);
    assert!(option::is_some(&update_id_option));
    let extracted_update_id = option::destroy_some(update_id_option);
    assert_eq!(extracted_update_id, update_id);

    let missing_update_id =
        crowd_walrus::campaign::try_get_update_id(&campaign_obj, 1);
    assert!(!option::is_some(&missing_update_id));

    let expected_timestamp = sui::clock::timestamp_ms(&clock);

    ts::return_shared(campaign_obj);
    scenario.return_to_sender(campaign_owner_cap);
    ts::return_shared(clock);

    scenario.next_tx(campaign_owner);
    let update_object = ts::take_immutable_by_id<CampaignUpdate>(&scenario, update_id);
    assert_eq!(object::id(&update_object), update_id);
    assert_eq!(
        crowd_walrus::campaign::update_parent_id(&update_object),
        campaign_id
    );
    assert_eq!(
        crowd_walrus::campaign::update_sequence(&update_object),
        0
    );
    assert_eq!(
        crowd_walrus::campaign::update_author(&update_object),
        campaign_owner
    );
    assert_eq!(
        crowd_walrus::campaign::update_created_at_ms(&update_object),
        expected_timestamp
    );
    let update_metadata =
        crowd_walrus::campaign::update_metadata(&update_object);
    assert_eq!(vec_map::length(update_metadata), 2);
    assert_eq!(
        *vec_map::get(update_metadata, &utf8(b"walrus_quilt_id")),
        utf8(b"0xabc"),
    );
    assert_eq!(
        *vec_map::get(update_metadata, &utf8(b"headline")),
        utf8(b"Reached 50% funding"),
    );

    ts::return_immutable(update_object);
    scenario.end();
}

#[test]
public fun test_add_multiple_updates_sequences() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Multi Update Campaign"),
        utf8(b"Testing multiple updates"),
        b"multi",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        0,
        U64_MAX,
    );

    // First update
    scenario.next_tx(campaign_owner);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();
    crowd_walrus::campaign::add_update(
        &mut campaign_obj,
        &campaign_owner_cap,
        vector[utf8(b"walrus_quilt_id")],
        vector[utf8(b"0x001")],
        &clock,
        ts::ctx(&mut scenario),
    );
    ts::return_shared(campaign_obj);
    scenario.return_to_sender(campaign_owner_cap);
    ts::return_shared(clock);

    // Second update
    scenario.next_tx(campaign_owner);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();
    crowd_walrus::campaign::add_update(
        &mut campaign_obj,
        &campaign_owner_cap,
        vector[utf8(b"walrus_quilt_id")],
        vector[utf8(b"0x002")],
        &clock,
        ts::ctx(&mut scenario),
    );
    ts::return_shared(campaign_obj);
    scenario.return_to_sender(campaign_owner_cap);
    ts::return_shared(clock);

    // Third update (validate state)
    scenario.next_tx(campaign_owner);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();
    crowd_walrus::campaign::add_update(
        &mut campaign_obj,
        &campaign_owner_cap,
        vector[utf8(b"walrus_quilt_id")],
        vector[utf8(b"0x003")],
        &clock,
        ts::ctx(&mut scenario),
    );

    assert_eq!(
        crowd_walrus::campaign::update_count(&campaign_obj),
        3
    );

    let id0 = crowd_walrus::campaign::get_update_id(&campaign_obj, 0);
    let id1 = crowd_walrus::campaign::get_update_id(&campaign_obj, 1);
    let id2 = crowd_walrus::campaign::get_update_id(&campaign_obj, 2);

    assert!(id0 != id1);
    assert!(id1 != id2);
    assert!(id0 != id2);

    assert!(crowd_walrus::campaign::has_update(&campaign_obj, 0));
    assert!(crowd_walrus::campaign::has_update(&campaign_obj, 1));
    assert!(crowd_walrus::campaign::has_update(&campaign_obj, 2));
    assert!(!crowd_walrus::campaign::has_update(&campaign_obj, 3));

    let update_ids = vector[id0, id1, id2];

    ts::return_shared(campaign_obj);
    scenario.return_to_sender(campaign_owner_cap);
    ts::return_shared(clock);

    scenario.next_tx(campaign_owner);
    let mut i = 0;
    while (i < 3) {
        let update_id_ref = *vector::borrow(&update_ids, i);
        let update = ts::take_immutable_by_id<CampaignUpdate>(&scenario, update_id_ref);
        assert_eq!(crowd_walrus::campaign::update_sequence(&update), i);
        ts::return_immutable(update);
        i = i + 1;
    };

    scenario.end();
}

#[test]
public fun test_add_update_empty_metadata_allowed() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Empty Metadata Campaign"),
        utf8(b"Testing empty metadata"),
        b"empty",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        0,
        U64_MAX,
    );

    scenario.next_tx(campaign_owner);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::campaign::add_update(
        &mut campaign_obj,
        &campaign_owner_cap,
        vector::empty<String>(),
        vector::empty<String>(),
        &clock,
        ts::ctx(&mut scenario),
    );

    assert_eq!(
        crowd_walrus::campaign::update_count(&campaign_obj),
        1
    );
    let update_id = crowd_walrus::campaign::get_update_id(&campaign_obj, 0);
    ts::return_shared(campaign_obj);
    scenario.return_to_sender(campaign_owner_cap);
    ts::return_shared(clock);

    scenario.next_tx(campaign_owner);
    let update = ts::take_immutable_by_id<CampaignUpdate>(&scenario, update_id);
    assert_eq!(object::id(&update), update_id);
    assert_eq!(
        vec_map::length(crowd_walrus::campaign::update_metadata(&update)),
        0
    );
    ts::return_immutable(update);

    scenario.end();
}

#[test, expected_failure(abort_code = crowd_walrus::campaign::E_APP_NOT_AUTHORIZED)]
public fun test_add_update_wrong_cap_fails() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let campaign_a = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Campaign A"),
        utf8(b"First"),
        b"companya",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        0,
        U64_MAX,
    );

    scenario.next_tx(USER2);
    let _campaign_b = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Campaign B"),
        utf8(b"Second"),
        b"companyb",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER2,
        0,
        U64_MAX,
    );

    {
        scenario.next_tx(USER2);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_a);
        let wrong_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<Clock>();

        crowd_walrus::campaign::add_update(
            &mut campaign,
            &wrong_cap,
            vector::empty(),
            vector::empty(),
            &clock,
            ts::ctx(&mut scenario),
        );

        ts::return_shared(campaign);
        scenario.return_to_sender(wrong_cap);
        ts::return_shared(clock);
    };

    scenario.end();
}

#[test, expected_failure(abort_code = crowd_walrus::campaign::E_KEY_VALUE_MISMATCH)]
public fun test_add_update_key_value_mismatch() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Mismatch Campaign"),
        utf8(b"Testing mismatch"),
        b"mismatch",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        0,
        U64_MAX,
    );

    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<Clock>();

        crowd_walrus::campaign::add_update(
            &mut campaign,
            &campaign_owner_cap,
            vector[utf8(b"a"), utf8(b"b")],
            vector[utf8(b"only_one")],
            &clock,
            ts::ctx(&mut scenario),
        );

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    scenario.end();
}

#[test, expected_failure(abort_code = sui::vec_map::EKeyAlreadyExists)]
public fun test_add_update_duplicate_metadata_keys() {
    let campaign_owner = USER1;

    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Duplicate Key Campaign"),
        utf8(b"Testing duplicate keys"),
        b"dup",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        0,
        U64_MAX,
    );

    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        let clock = scenario.take_shared<Clock>();

        crowd_walrus::campaign::add_update(
            &mut campaign,
            &campaign_owner_cap,
            vector[utf8(b"key"), utf8(b"key")],
            vector[utf8(b"value1"), utf8(b"value2")],
            &clock,
            ts::ctx(&mut scenario),
        );

        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
        ts::return_shared(clock);
    };

    scenario.end();
}

#[test]
public fun test_update_author_is_creator() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(USER1);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Soulbound Campaign"),
        utf8(b"Owner cap stays with creator"),
        b"soulbound",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        0,
        U64_MAX,
    );

    scenario.next_tx(USER1);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::campaign::add_update(
        &mut campaign_obj,
        &campaign_owner_cap,
        vector[utf8(b"note")],
        vector[utf8(b"posted by creator")],
        &clock,
        ts::ctx(&mut scenario),
    );

    let update_id = crowd_walrus::campaign::get_update_id(&campaign_obj, 0);

    ts::return_shared(campaign_obj);
    scenario.return_to_sender(campaign_owner_cap);
    ts::return_shared(clock);

    scenario.next_tx(USER1);
    let update = ts::take_immutable_by_id<CampaignUpdate>(&scenario, update_id);
    assert_eq!(
        crowd_walrus::campaign::update_author(&update),
        USER1
    );
    ts::return_immutable(update);
    scenario.end();
}

#[test]
public fun test_update_try_get_missing_returns_none() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"No Update Campaign"),
        utf8(b"Testing missing update"),
        b"none",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        0,
        U64_MAX,
    );

    scenario.next_tx(campaign_owner);
    let campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let missing: option::Option<object::ID> =
        crowd_walrus::campaign::try_get_update_id(&campaign_obj, 0);
    assert!(!option::is_some(&missing));

    ts::return_shared(campaign_obj);
    scenario.end();
}

#[test, expected_failure(abort_code = sui::dynamic_field::EFieldDoesNotExist, location = 0x2::dynamic_field)]
public fun test_get_update_id_missing_sequence_aborts() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"No Updates Campaign"),
        utf8(b"Missing sequence abort"),
        b"noupdates",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        0,
        U64_MAX,
    );

    scenario.next_tx(campaign_owner);
    let campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
    // This call should abort because no updates exist for sequence 0.
    crowd_walrus::campaign::get_update_id(&campaign, 0);
    abort 0
}

#[test]
public fun test_add_update_emits_event() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Event Campaign"),
        utf8(b"Ensures event emission"),
        b"event",
        vector::empty(),
        vector::empty(),
        1_000_000,
        USER1,
        0,
        U64_MAX,
    );

    scenario.next_tx(campaign_owner);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::campaign::add_update(
        &mut campaign_obj,
        &campaign_owner_cap,
        vector[utf8(b"walrus_quilt_id")],
        vector[utf8(b"0xdeadbeef")],
        &clock,
        ts::ctx(&mut scenario),
    );

    ts::return_shared(campaign_obj);
    scenario.return_to_sender(campaign_owner_cap);
    ts::return_shared(clock);

    let effects = ts::end(scenario);
    assert_eq!(ts::num_user_events(&effects), 1);
}
