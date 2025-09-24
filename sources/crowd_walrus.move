module crowd_walrus::crowd_walrus;

use crowd_walrus::campaign;
use crowd_walrus::suins_manager::{Self as suins_manager, SuiNSManager, register_subdomain};
use std::string::String;
use sui::clock::Clock;
use sui::dynamic_field as df;
use sui::event;
use sui::table;
use suins::suins::SuiNS;

public struct CROWD_WALRUS has drop {}
/// Authorization token for the app.
public struct CrowdWalrusApp has drop {}

// === Errors ===

const E_NOT_AUTHORIZED: u64 = 1;
const E_ALREADY_VALIDATED: u64 = 2;
const E_NOT_VALIDATED: u64 = 3;

// === Structs ===

/// The crowd walrus object
public struct CrowdWalrus has key, store {
    id: UID,
    created_at: u64,
    validated_maps: table::Table<ID, bool>,
    validated_campaigns_list: vector<ID>,
}

/// Capability for admin operations
public struct AdminCap has key, store {
    id: UID,
    crowd_walrus_id: ID,
}

/// Capability for validating admin operations
public struct ValidateCap has key, store {
    id: UID,
    crowd_walrus_id: ID,
}

// === Events ====

public struct AdminCreated has copy, drop {
    crowd_walrus_id: ID,
    admin_id: ID,
    creator: address,
}

public struct CampaignValidated has copy, drop {
    campaign_id: ID,
    validator: address,
}

// public struct ProjectValidated has copy, drop {
//     campaign_id: ID,
//     validator: address,
// }

public struct CampaignUnvalidated has copy, drop {
    campaign_id: ID,
    unvalidator: address,
}

// public struct ProjectUnvalidated has copy, drop {
//     campaign_id: ID,
//     unvalidator: address,
// }

// === Init Function ===

/// Initialize the crowd walrus
fun init(_otw: CROWD_WALRUS, ctx: &mut TxContext) {
    let crowd_walrus = CrowdWalrus {
        id: object::new(ctx),
        created_at: tx_context::epoch(ctx),
        validated_maps: table::new(ctx),
        validated_campaigns_list: vector::empty(),
    };

    let crowd_walrus_id = object::id(&crowd_walrus);

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
    description: String,
    subdomain_name: String,
    metadata: String,
    ctx: &mut TxContext,
): ID {
    // register subname
    // TODO: register on suins manager

    let app = CrowdWalrusApp {};

    let (campaign_id, campaign_owner_cap) = campaign::new(
        &app,
        object::id(crowd_walrus),
        name,
        description,
        subdomain_name,
        metadata,
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
    campaign_id
}

/// Validate a campaign
entry fun validate_campaign(
    crowd_walrus: &mut CrowdWalrus,
    cap: &ValidateCap,
    campaign: &mut campaign::Campaign,
    ctx: &TxContext,
) {
    let campaign_id = object::id(campaign);

    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);
    assert!(!table::contains(&crowd_walrus.validated_maps, campaign_id), E_ALREADY_VALIDATED);

    table::add(&mut crowd_walrus.validated_maps, campaign_id, true);
    vector::push_back(&mut crowd_walrus.validated_campaigns_list, campaign_id);

    campaign::set_validated(campaign, &CrowdWalrusApp {}, true);

    // event
    event::emit(CampaignValidated {
        campaign_id,
        validator: tx_context::sender(ctx),
    });
}

entry fun unvalidate_campaign(
    crowd_walrus: &mut CrowdWalrus,
    cap: &ValidateCap,
    campaign: &mut campaign::Campaign,
    ctx: &TxContext,
) {
    let campaign_id = object::id(campaign);

    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);
    assert!(table::contains(&crowd_walrus.validated_maps, campaign_id), E_NOT_VALIDATED);

    campaign::set_validated(campaign, &CrowdWalrusApp {}, false);

    table::remove(&mut crowd_walrus.validated_maps, campaign_id);

    let mut i: u64 = 0;
    let length = crowd_walrus.validated_campaigns_list.length();

    while (i < length) {
        if (crowd_walrus.validated_campaigns_list[i] == campaign_id) {
            vector::remove(&mut crowd_walrus.validated_campaigns_list, i);
            break
        } else {
            i = i + 1;
        }
    };
    event::emit(CampaignUnvalidated {
        campaign_id,
        unvalidator: tx_context::sender(ctx),
    });
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

/// Create a validation capability for a new validator
entry fun create_validate_cap(
    crowd_walrus: &CrowdWalrus,
    cap: &AdminCap,
    new_validator: address,
    ctx: &mut TxContext,
) {
    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);

    transfer::transfer(
        ValidateCap {
            id: object::new(ctx),
            crowd_walrus_id: object::id(crowd_walrus),
        },
        new_validator,
    )
}

// === View Functions ===
/// Get Admin Cap crowd_walrus_id
public fun crowd_walrus_id(cap: &AdminCap): ID {
    cap.crowd_walrus_id
}

/// Check if a campaign is validated
public fun is_campaign_validated(crowd_walrus: &CrowdWalrus, campaign_id: ID): bool {
    table::contains(&crowd_walrus.validated_maps, campaign_id)
}

/// Get the validated campaigns list
public fun get_validated_campaigns_list(crowd_walrus: &CrowdWalrus): vector<ID> {
    crowd_walrus.validated_campaigns_list
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

    let suins_manager_cap = scenario.take_from_sender<suins_manager::AdminCap>();
    let suins_manager = scenario.take_shared<suins_manager::SuiNSManager>();

    assert!(suins_manager.is_app_authorized<CrowdWalrusApp>());

    // clean up
    scenario.return_to_sender(crowd_walrus_cap);
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
    let crowd_walrus = CrowdWalrus {
        id: object::new(ctx),
        created_at: tx_context::epoch(ctx),
        validated_maps: table::new(ctx),
        validated_campaigns_list: vector::empty(),
    };
    let crowd_walrus_id = object::id(&crowd_walrus);
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

#[test_only]
public fun create_validate_cap_for_user(
    crowd_walrus_id: ID,
    user: address,
    ctx: &mut TxContext,
): ID {
    let validate_cap = ValidateCap {
        id: object::new(ctx),
        crowd_walrus_id: crowd_walrus_id,
    };
    let validate_cap_id = object::id(&validate_cap);
    transfer::transfer(validate_cap, user);
    validate_cap_id
}
