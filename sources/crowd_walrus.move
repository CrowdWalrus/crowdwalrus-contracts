module crowd_walrus::manager;

use crowd_walrus::campaign;
use std::string::String;
use sui::dynamic_field as df;
use sui::event;
use sui::table;

public struct MANAGER has drop {}

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
fun init(_otw: MANAGER, ctx: &mut TxContext) {
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
        creator: tx_context::sender(ctx),
    });

    // Transfer capability to creator
    transfer::transfer(admin_cap, tx_context::sender(ctx));

    // Share crowd walrus object with creator
    transfer::share_object(crowd_walrus)
}

// === Public Functions ===

/// Register a new campaign
entry fun create_campaign(
    crowd_walrus: &CrowdWalrus,
    name: String,
    description: String,
    subdomain_name: String,
    ctx: &mut TxContext,
): ID {
    // register subname
    // TODO: register on suins manager

    let (campaign_id, campaign_owner_cap) = campaign::new(
        object::id(crowd_walrus),
        name,
        description,
        subdomain_name,
        ctx,
    );

    transfer::public_transfer(campaign_owner_cap, tx_context::sender(ctx));
    campaign_id
}

/// Validate a campaign
entry fun validate_campaign(
    crowd_walrus: &mut CrowdWalrus,
    cap: &ValidateCap,
    campaign: &campaign::Campaign,
    ctx: &TxContext,
) {
    let campaign_id = object::id(campaign);

    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);
    assert!(!table::contains(&crowd_walrus.validated_maps, campaign_id), E_ALREADY_VALIDATED);

    table::add(&mut crowd_walrus.validated_maps, campaign_id, true);
    vector::push_back(&mut crowd_walrus.validated_campaigns_list, campaign_id);

    // event
    event::emit(CampaignValidated {
        campaign_id,
        validator: tx_context::sender(ctx),
    });
}

entry fun unvalidate_campaign(
    crowd_walrus: &mut CrowdWalrus,
    cap: &ValidateCap,
    campaign: &campaign::Campaign,
    ctx: &TxContext,
) {
    let campaign_id = object::id(campaign);

    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);
    assert!(table::contains(&crowd_walrus.validated_maps, campaign_id), E_NOT_VALIDATED);

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

/// ==== Dynamic Field Functions ====

/// Check if dynamic field exists
public fun has_field<K: copy + drop + store>(crowd_walrus: &CrowdWalrus, key: K): bool {
    df::exists_(&crowd_walrus.id, key)
}

/// Borrow dynamic field
public fun borrow_field<K: copy + drop + store, V: store>(crowd_walrus: &CrowdWalrus, key: K): &V {
    df::borrow(&crowd_walrus.id, key)
}

/// Borrow mutable dynamic field (requires admin cap)
public fun borrow_field_mut<K: copy + drop + store, V: store>(
    crowd_walrus: &mut CrowdWalrus,
    cap: &AdminCap,
    key: K,
): &mut V {
    assert!(object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);

    df::borrow_mut(&mut crowd_walrus.id, key)
}

#[test_only]
public fun test_init(ctx: &mut TxContext) {
    init(MANAGER {}, ctx);
}

#[test_only]
public fun create_crowd_walrus(ctx: &mut TxContext): CrowdWalrus {
    CrowdWalrus {
        id: object::new(ctx),
        created_at: tx_context::epoch(ctx),
        validated_maps: table::new(ctx),
        validated_campaigns_list: vector::empty(),
    }
}

#[test_only]
public fun create_and_share_crowd_walrus(ctx: &mut TxContext): ID {
    let crowd_walrus = create_crowd_walrus(ctx);
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
