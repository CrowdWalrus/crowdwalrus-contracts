module crowd_walrus::crowd_walrus;

use crowd_walrus::campaign;
use crowd_walrus::platform_policy;
use crowd_walrus::suins_manager::{Self as suins_manager, SuiNSManager, register_subdomain};
use std::string::String;
use sui::clock::Clock;
use sui::dynamic_field as df;
use sui::event;
use sui::table;
use sui::vec_map;
use suins::suins::SuiNS;

public struct CROWD_WALRUS has drop {}
/// Authorization token for the app.
public struct CrowdWalrusApp has drop {}

// === Errors ===

const E_NOT_AUTHORIZED: u64 = 1;
const E_ALREADY_VERIFIED: u64 = 2;
const E_NOT_VERIFIED: u64 = 3;

// === Events ===
public struct CampaignCreated has copy, drop {
    campaign_id: ID,
    creator: address,
}

// === Structs ===

/// The crowd walrus object
public struct CrowdWalrus has key, store {
    id: UID,
    verified_maps: table::Table<ID, bool>,
    verified_campaigns_list: vector<ID>,
    /// Shared policy presets registry ObjectID created at publish time.
    policy_registry_id: ID,
}

/// Capability for admin operations
public struct AdminCap has key, store {
    id: UID,
    crowd_walrus_id: ID,
}

/// Capability for verifying admin operations
public struct VerifyCap has key, store {
    id: UID,
    crowd_walrus_id: ID,
}

// === Events ====

public struct AdminCreated has copy, drop {
    crowd_walrus_id: ID,
    admin_id: ID,
    creator: address,
}

public struct CampaignVerified has copy, drop {
    campaign_id: ID,
    verifier: address,
}

public struct CampaignUnverified has copy, drop {
    campaign_id: ID,
    unverifier: address,
}

public struct CampaignDeleted has copy, drop {
    campaign_id: ID,
    editor: address,
    timestamp_ms: u64,
}

public struct PolicyRegistryCreated has copy, drop {
    crowd_walrus_id: ID,
    policy_registry_id: ID,
}

// === Init Function ===

/// Initialize the crowd walrus
fun init(_otw: CROWD_WALRUS, ctx: &mut TxContext) {
    let crowd_walrus_uid = object::new(ctx);
    let crowd_walrus_id = object::uid_to_inner(&crowd_walrus_uid);

    let policy_registry = platform_policy::create_registry(crowd_walrus_id, ctx);
    // Persist the registry ID so admins can resolve it without replaying events.
    let policy_registry_id = object::id(&policy_registry);
    platform_policy::share_registry(policy_registry);

    let crowd_walrus = CrowdWalrus {
        id: crowd_walrus_uid,
        verified_maps: table::new(ctx),
        verified_campaigns_list: vector::empty(),
        policy_registry_id,
    };

    // Create admin capability for the creator
    let admin_cap = AdminCap {
        id: object::new(ctx),
        crowd_walrus_id,
    };

    // Emit creation event
    event::emit(AdminCreated {
        crowd_walrus_id,
        admin_id: object::id(&admin_cap),
        creator: tx_context::sender(ctx),
    });
    // Announce the shared registry to indexers and deployment tooling.
    event::emit(PolicyRegistryCreated {
        crowd_walrus_id,
        policy_registry_id,
    });

    // Transfer capability to creator
    transfer::transfer(admin_cap, tx_context::sender(ctx));

    // Share crowd walrus object with creator
    transfer::share_object(crowd_walrus);
    let (_, suins_manager_cap) = suins_manager::new(
        &CrowdWalrusApp {},
        ctx,
    );

    transfer::public_transfer(suins_manager_cap, tx_context::sender(ctx));
}

// === Public Functions ===

/// Register a new campaign
entry fun create_campaign(
    crowd_walrus: &CrowdWalrus,
    suins_manager: &SuiNSManager,
    suins: &mut SuiNS,
    clock: &Clock,
    name: String,
    short_description: String,
    subdomain_name: String,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    funding_goal_usd_micro: u64,
    recipient_address: address,
    platform_bps: u16,
    platform_address: address,
    start_date: u64,
    end_date: u64,
    ctx: &mut TxContext,
): ID {
    // Ensure start_date is not in the past
    let current_time_ms = sui::clock::timestamp_ms(clock);
    assert!(start_date >= current_time_ms, campaign::e_start_date_in_past());

    // register subname
    let app = CrowdWalrusApp {};
    let metadata = vec_map::from_keys_values(metadata_keys, metadata_values);
    assert!(recipient_address != @0x0, campaign::e_recipient_address_invalid());
    let payout_policy = campaign::new_payout_policy(platform_bps, platform_address, recipient_address);

    let (campaign_id, campaign_owner_cap) = campaign::new(
        &app,
        object::id(crowd_walrus),
        name,
        short_description,
        subdomain_name,
        metadata,
        funding_goal_usd_micro,
        payout_policy,
        start_date,
        end_date,
        clock,
        ctx,
    );
    suins_manager.register_subdomain(
        &app,
        suins,
        clock,
        subdomain_name,
        campaign_id.to_address(),
        ctx,
    );

    transfer::public_transfer(campaign_owner_cap, tx_context::sender(ctx));
    event::emit(CampaignCreated {
        campaign_id,
        creator: tx_context::sender(ctx),
    });
    campaign_id
}

/// Verify a campaign
entry fun verify_campaign(
    crowd_walrus: &mut CrowdWalrus,
    cap: &VerifyCap,
    campaign: &mut campaign::Campaign,
    ctx: &TxContext,
) {
    let campaign_id = object::id(campaign);

    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);
    assert!(!table::contains(&crowd_walrus.verified_maps, campaign_id), E_ALREADY_VERIFIED);
    campaign::assert_not_deleted(campaign);

    table::add(&mut crowd_walrus.verified_maps, campaign_id, true);
    vector::push_back(&mut crowd_walrus.verified_campaigns_list, campaign_id);

    campaign::set_verified(campaign, &CrowdWalrusApp {}, true);

    // event
    event::emit(CampaignVerified {
        campaign_id,
        verifier: tx_context::sender(ctx),
    });
}

entry fun unverify_campaign(
    crowd_walrus: &mut CrowdWalrus,
    cap: &VerifyCap,
    campaign: &mut campaign::Campaign,
    ctx: &TxContext,
) {
    let campaign_id = object::id(campaign);

    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);
    assert!(table::contains(&crowd_walrus.verified_maps, campaign_id), E_NOT_VERIFIED);

    campaign::set_verified(campaign, &CrowdWalrusApp {}, false);

    remove_verified_campaign(crowd_walrus, campaign_id);
    event::emit(CampaignUnverified {
        campaign_id,
        unverifier: tx_context::sender(ctx),
    });
}

fun remove_verified_campaign(
    crowd_walrus: &mut CrowdWalrus,
    campaign_id: ID,
) {
    if (!table::contains(&crowd_walrus.verified_maps, campaign_id)) {
        return
    };

    table::remove(&mut crowd_walrus.verified_maps, campaign_id);

    let mut i: u64 = 0;
    let length = crowd_walrus.verified_campaigns_list.length();

    while (i < length) {
        if (crowd_walrus.verified_campaigns_list[i] == campaign_id) {
            vector::remove(&mut crowd_walrus.verified_campaigns_list, i);
            break
        } else {
            i = i + 1;
        }
    };
}

entry fun delete_campaign(
    crowd_walrus: &mut CrowdWalrus,
    suins_manager: &SuiNSManager,
    suins: &mut SuiNS,
    campaign: &mut campaign::Campaign,
    cap: campaign::CampaignOwnerCap,
    clock: &Clock,
    ctx: &TxContext,
) {
    let campaign_id = object::id(campaign);

    assert!(campaign::admin_id(campaign) == object::id(crowd_walrus), E_NOT_AUTHORIZED);
    campaign::assert_owner(campaign, &cap);
    campaign::assert_not_deleted(campaign);

    let deleted_at_ms = sui::clock::timestamp_ms(clock);
    let subdomain_name = campaign::subdomain_name(campaign);

    if (table::contains(&crowd_walrus.verified_maps, campaign_id)) {
        campaign::set_verified(campaign, &CrowdWalrusApp {}, false);
        remove_verified_campaign(crowd_walrus, campaign_id);
    };

    suins_manager::remove_subdomain_for_app<CrowdWalrusApp>(
        suins_manager,
        &CrowdWalrusApp {},
        suins,
        clock,
        subdomain_name,
    );

    campaign::mark_deleted(campaign, &cap, deleted_at_ms);

    event::emit(CampaignDeleted {
        campaign_id,
        editor: tx_context::sender(ctx),
        timestamp_ms: deleted_at_ms,
    });

    campaign::delete_owner_cap(cap);
}

// === Admin Functions ===
/// Add dynamic field for extensibility
public fun add_field<K: copy + drop + store, V: store>(
    crowd_walrus: &mut CrowdWalrus,
    cap: &AdminCap,
    key: K,
    value: V,
) {
    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);

    df::add(&mut crowd_walrus.id, key, value);
}

/// Remove dynamic field
public fun remove_field<K: copy + drop + store, V: store>(
    crowd_walrus: &mut CrowdWalrus,
    cap: &AdminCap,
    key: K,
): V {
    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);

    df::remove(&mut crowd_walrus.id, key)
}

/// Create a verification capability for a new verifier
entry fun create_verify_cap(
    crowd_walrus: &CrowdWalrus,
    cap: &AdminCap,
    new_verifier: address,
    ctx: &mut TxContext,
) {
    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);

    transfer::transfer(
        VerifyCap {
            id: object::new(ctx),
            crowd_walrus_id: object::id(crowd_walrus),
        },
        new_verifier,
    )
}

// === View Functions ===
/// Get Admin Cap crowd_walrus_id
public fun crowd_walrus_id(cap: &AdminCap): ID {
    cap.crowd_walrus_id
}

/// Get the shared PolicyRegistry ID managed by this CrowdWalrus instance.
public fun policy_registry_id(crowd_walrus: &CrowdWalrus): ID {
    crowd_walrus.policy_registry_id
}

/// Check if a campaign is verified
public fun is_campaign_verified(crowd_walrus: &CrowdWalrus, campaign_id: ID): bool {
    table::contains(&crowd_walrus.verified_maps, campaign_id)
}

/// Get the verified campaigns list
public fun get_verified_campaigns_list(crowd_walrus: &CrowdWalrus): vector<ID> {
    crowd_walrus.verified_campaigns_list
}

#[test]
public fun test_init_function() {
    use sui::test_scenario::{Self as ts, ctx};
    let publisher_address: address = @0xA;
    let mut scenario = ts::begin(publisher_address);

    init(CROWD_WALRUS {}, ctx(&mut scenario));

    scenario.next_tx(publisher_address);

    let crowd_walrus = scenario.take_shared<CrowdWalrus>();
    let crowd_walrus_cap = scenario.take_from_sender<AdminCap>();
    assert!(object::id(&crowd_walrus) == crowd_walrus_cap.crowd_walrus_id);

    let policy_registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    // Ensure the stored registry ID matches the shared object we just fetched.
    assert!(object::id(&policy_registry) == policy_registry_id(&crowd_walrus));

    let suins_manager_cap = scenario.take_from_sender<suins_manager::AdminCap>();
    let suins_manager = scenario.take_shared<suins_manager::SuiNSManager>();

    assert!(suins_manager.is_app_authorized<CrowdWalrusApp>());

    // clean up
    scenario.return_to_sender(crowd_walrus_cap);
    ts::return_shared(policy_registry);
    scenario.return_to_sender(suins_manager_cap);
    ts::return_shared(crowd_walrus);
    ts::return_shared(suins_manager);

    scenario.end();
}

#[test_only]
public fun get_app(): CrowdWalrusApp {
    CrowdWalrusApp {}
}

#[test_only]
public fun create_and_share_crowd_walrus(ctx: &mut TxContext): ID {
    let crowd_walrus_uid = object::new(ctx);
    let crowd_walrus_id = object::uid_to_inner(&crowd_walrus_uid);
    let policy_registry = platform_policy::create_registry(crowd_walrus_id, ctx);
    let policy_registry_id = object::id(&policy_registry);
    platform_policy::share_registry(policy_registry);

    let crowd_walrus = CrowdWalrus {
        id: crowd_walrus_uid,
        verified_maps: table::new(ctx),
        verified_campaigns_list: vector::empty(),
        policy_registry_id,
    };
    transfer::share_object(crowd_walrus);
    crowd_walrus_id
}

#[test_only]
public fun create_admin_cap_for_user(crowd_walrus_id: ID, user: address, ctx: &mut TxContext): ID {
    let admin_cap = AdminCap {
        id: object::new(ctx),
        crowd_walrus_id: crowd_walrus_id,
    };
    let admin_cap_id = object::id(&admin_cap);
    transfer::transfer(admin_cap, user);
    admin_cap_id
}

public(package) fun add_platform_policy_internal(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    platform_bps: u16,
    platform_address: address,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, platform_policy::registry_owner_id(registry));
    platform_policy::add_policy(
        registry,
        name,
        platform_bps,
        platform_address,
        clock,
    );
}

entry fun add_platform_policy(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    platform_bps: u16,
    platform_address: address,
    clock: &Clock,
    _ctx: &mut TxContext,
) {
    // Entry wrapper allows direct PTB invocation; logic lives in the internal helper for reuse.
    add_platform_policy_internal(registry, admin_cap, name, platform_bps, platform_address, clock);
}

public(package) fun update_platform_policy_internal(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    platform_bps: u16,
    platform_address: address,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, platform_policy::registry_owner_id(registry));
    platform_policy::update_policy(
        registry,
        name,
        platform_bps,
        platform_address,
        clock,
    );
}

entry fun update_platform_policy(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    platform_bps: u16,
    platform_address: address,
    clock: &Clock,
    _ctx: &mut TxContext,
) {
    update_platform_policy_internal(registry, admin_cap, name, platform_bps, platform_address, clock);
}

public(package) fun disable_platform_policy_internal(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, platform_policy::registry_owner_id(registry));
    platform_policy::disable_policy(registry, name, clock);
}

entry fun disable_platform_policy(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    clock: &Clock,
    _ctx: &mut TxContext,
) {
    disable_platform_policy_internal(registry, admin_cap, name, clock);
}

public(package) fun enable_platform_policy_internal(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, platform_policy::registry_owner_id(registry));
    platform_policy::enable_policy(registry, name, clock);
}

entry fun enable_platform_policy(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    clock: &Clock,
    _ctx: &mut TxContext,
) {
    enable_platform_policy_internal(registry, admin_cap, name, clock);
}

public(package) fun assert_admin_cap_for(cap: &AdminCap, crowd_walrus_id: ID) {
    assert!(cap.crowd_walrus_id == crowd_walrus_id, E_NOT_AUTHORIZED);
}

public(package) fun admin_cap_crowd_walrus_id(cap: &AdminCap): ID {
    cap.crowd_walrus_id
}

#[test_only]
public fun create_verify_cap_for_user(
    crowd_walrus_id: ID,
    user: address,
    ctx: &mut TxContext,
): ID {
    let verify_cap = VerifyCap {
        id: object::new(ctx),
        crowd_walrus_id: crowd_walrus_id,
    };
    let verify_cap_id = object::id(&verify_cap);
    transfer::transfer(verify_cap, user);
    verify_cap_id
}
