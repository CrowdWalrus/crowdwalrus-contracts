module crowd_walrus::manager;

use crowd_walrus::project;
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

/// The admin object
public struct CrowdWalrus has key, store {
    id: UID,
    created_at: u64,
    projects: table::Table<String, ID>, // Subdomain to project ID
    validated_projects: table::Table<ID, bool>,
}

/// Capability for admin operations
public struct AdminCap has key, store {
    id: UID,
    admin_id: ID,
}

/// Capability for validating admin operations
public struct ValidateCap has key, store {
    id: UID,
    admin_id: ID,
}

// === Events ===

public struct AdminCreated has copy, drop {
    admin_id: ID,
    creator: address,
}

public struct ProjectValidated has copy, drop {
    project_id: ID,
    validator: address,
}

public struct ProjectValidationRevoked has copy, drop {
    project_id: ID,
    unvalidator: address,
}

// === Init Function ===

/// Initialize the admin
fun init(_otw: MANAGER, ctx: &mut TxContext) {
    let crowd_walrus = CrowdWalrus {
        id: object::new(ctx),
        created_at: tx_context::epoch(ctx),
        projects: table::new(ctx),
        validated_projects: table::new(ctx),
    };

    let admin_id = object::id(&crowd_walrus);

    // Create admin capability for the creator
    let admin_cap = AdminCap {
        id: object::new(ctx),
        admin_id,
    };

    // Emit creation event
    event::emit(AdminCreated {
        admin_id,
        creator: tx_context::sender(ctx),
    });

    // Transfer capability to creator
    transfer::transfer(admin_cap, tx_context::sender(ctx));

    // Share admin object with creator
    transfer::share_object(crowd_walrus)
}

// === Public Functions ===

/// Register a new project
entry fun create_project(
    crowd_walrus: &mut CrowdWalrus,
    name: String,
    description: String,
    subdomain_name: String,
    ctx: &mut TxContext,
) {
    let (project_id, project_owner_cap) = project::new(
        object::id(crowd_walrus),
        name,
        description,
        subdomain_name,
        ctx,
    );
    table::add(&mut crowd_walrus.projects, subdomain_name, project_id);
    transfer::public_transfer(project_owner_cap, tx_context::sender(ctx));
}

/// Validate a project
entry fun validate_project(
    crowd_walrus: &mut CrowdWalrus,
    cap: &ValidateCap,
    project: &project::Project,
    ctx: &TxContext,
) {
    let project_id = object::id(project);

    assert!(object::id(crowd_walrus) == cap.admin_id, E_NOT_AUTHORIZED);
    assert!(!table::contains(&crowd_walrus.validated_projects, project_id), E_ALREADY_VALIDATED);

    table::add(&mut crowd_walrus.validated_projects, project_id, true);

    // event
    event::emit(ProjectValidated {
        project_id,
        validator: tx_context::sender(ctx),
    });
}

entry fun unvalidate_project(
    crowd_walrus: &mut CrowdWalrus,
    cap: &ValidateCap,
    project: &project::Project,
    ctx: &TxContext,
) {
    let project_id = object::id(project);

    assert!(object::id(crowd_walrus) == cap.admin_id, E_NOT_AUTHORIZED);
    assert!(table::contains(&crowd_walrus.validated_projects, project_id), E_NOT_VALIDATED);

    table::remove(&mut crowd_walrus.validated_projects, project_id);

    // event
    event::emit(ProjectValidationRevoked {
        project_id,
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
    assert!(object::id(crowd_walrus) == cap.admin_id, E_NOT_AUTHORIZED);

    df::add(&mut crowd_walrus.id, key, value);
}

/// Remove dynamic field
public fun remove_field<K: copy + drop + store, V: store>(
    crowd_walrus: &mut CrowdWalrus,
    cap: &AdminCap,
    key: K,
): V {
    assert!(object::id(crowd_walrus) == cap.admin_id, E_NOT_AUTHORIZED);

    df::remove(&mut crowd_walrus.id, key)
}

/// Create a validation capability for a new validator
public fun create_validate_cap(
    crowd_walrus: &CrowdWalrus,
    cap: &AdminCap,
    new_validator: address,
    ctx: &mut TxContext,
) {
    assert!(object::id(crowd_walrus) == cap.admin_id, E_NOT_AUTHORIZED);

    transfer::transfer(
        ValidateCap {
            id: object::new(ctx),
            admin_id: object::id(crowd_walrus),
        },
        new_validator,
    )
}

// === View Functions ===
// Get Subdomain Name
public fun get_project(crowd_walrus: &CrowdWalrus, subdomain_name: String): Option<ID> {
    if (table::contains(&crowd_walrus.projects, subdomain_name)) {
        option::some(*table::borrow(&crowd_walrus.projects, subdomain_name))
    } else {
        option::none()
    }
}

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
    assert!(object::id(crowd_walrus) == cap.admin_id, E_NOT_AUTHORIZED);

    df::borrow_mut(&mut crowd_walrus.id, key)
}

#[test]
public fun test_init() {
    let mut ctx = tx_context::dummy();
    init(MANAGER {}, &mut ctx);
}

#[test_only]
public fun create_crowd_walrus(ctx: &mut TxContext): CrowdWalrus {
    CrowdWalrus {
        id: object::new(ctx),
        created_at: tx_context::epoch(ctx),
        projects: table::new(ctx),
        validated_projects: table::new(ctx),
    }
}

#[test_only]
public fun create_and_share_crowd_walrus(ctx: &mut TxContext): ID {
    let crowd_walrus = create_crowd_walrus(ctx);
    let crowd_walrus_id = object::id(&crowd_walrus);
    transfer::share_object(crowd_walrus);
    crowd_walrus_id
}
