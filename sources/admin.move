// Singleton Admin
module crowd_walrus_move::admin;


use std::string::{Self, String};
use sui::object::{Self, ID, UID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};
use sui::dynamic_field as df;
use sui::event;

// Error codes
const E_NOT_AUTHORIZED: u64 = 1;
const E_ALREADY_INITIALIZED: u64 = 2;
const E_NOT_OWNER: u64 = 3;

// Events
public struct AdminCreated has copy, drop {
    admin_id: ID,
    creator: address,
}

public struct AdminUpgraded has copy, drop {
    admin_id: ID,
    version: u64,
    upgraded_by: address,
}

public struct OwnerAdded has copy, drop {
    admin_id: ID,
    new_owner: address,
    added_by: address,
}

public struct OwnerRemoved has copy, drop {
    admin_id: ID,
    removed_owner: address,
    removed_by: address,
}

// Capability for admin operations
public struct AdminCap has key, store {
    id: UID,
    admin_id: ID,
}

// The singleton admin object
public struct Admin has key, store {
    id: UID,
    version: u64,
    owners: vector<address>,
    created_at: u64,
    // Dynamic fields can be added for extensibility
}

// Initialize the admin singleton - can only be called once
fun init(ctx: &mut TxContext) {
    let admin = Admin {
        id: object::new(ctx),
        version: 1,
        owners: vector[tx_context::sender(ctx)],
        created_at: tx_context::epoch(ctx),
    };

    let admin_id = object::id(&admin);

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

    // Transfer admin object to creator
    transfer::transfer(admin, tx_context::sender(ctx));
    // Transfer capability to creator
    transfer::transfer(admin_cap, tx_context::sender(ctx));
}

// Create additional admin capabilities for new owners
public fun create_admin_cap(
    admin: &Admin,
    cap: &AdminCap,
    new_owner: address,
    ctx: &mut TxContext
): AdminCap {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);
    assert!(is_owner(admin, tx_context::sender(ctx)), E_NOT_OWNER);

    AdminCap {
        id: object::new(ctx),
        admin_id: object::id(admin),
    }
}

// Add a new owner
public fun add_owner(
    admin: &mut Admin,
    cap: &AdminCap,
    new_owner: address,
    ctx: &mut TxContext
) {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);
    assert!(is_owner(admin, tx_context::sender(ctx)), E_NOT_OWNER);

    if (!vector::contains(&admin.owners, &new_owner)) {
        vector::push_back(&mut admin.owners, new_owner);

        event::emit(OwnerAdded {
            admin_id: object::id(admin),
            new_owner,
            added_by: tx_context::sender(ctx),
        });
    }
}

// Remove an owner (must have at least one owner remaining)
public fun remove_owner(
    admin: &mut Admin,
    cap: &AdminCap,
    owner_to_remove: address,
    ctx: &mut TxContext
) {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);
    assert!(is_owner(admin, tx_context::sender(ctx)), E_NOT_OWNER);
    assert!(vector::length(&admin.owners) > 1, E_NOT_AUTHORIZED); // Must keep at least one owner

    let (found, index) = vector::index_of(&admin.owners, &owner_to_remove);
    if (found) {
        vector::remove(&mut admin.owners, index);

        event::emit(OwnerRemoved {
            admin_id: object::id(admin),
            removed_owner: owner_to_remove,
            removed_by: tx_context::sender(ctx),
        });
    }
}

// Upgrade the admin version
public fun upgrade_version(
    admin: &mut Admin,
    cap: &AdminCap,
    ctx: &mut TxContext
) {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);
    assert!(is_owner(admin, tx_context::sender(ctx)), E_NOT_OWNER);

    admin.version = admin.version + 1;

    event::emit(AdminUpgraded {
        admin_id: object::id(admin),
        version: admin.version,
        upgraded_by: tx_context::sender(ctx),
    });
}

// Add dynamic field for extensibility
public fun add_field<K: copy + drop + store, V: store>(
    admin: &mut Admin,
    cap: &AdminCap,
    key: K,
    value: V,
    ctx: &mut TxContext
) {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);
    assert!(is_owner(admin, tx_context::sender(ctx)), E_NOT_OWNER);

    df::add(&mut admin.id, key, value);
}

// Remove dynamic field
public fun remove_field<K: copy + drop + store, V: store>(
    admin: &mut Admin,
    cap: &AdminCap,
    key: K,
    ctx: &mut TxContext
): V {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);
    assert!(is_owner(admin, tx_context::sender(ctx)), E_NOT_OWNER);

    df::remove(&mut admin.id, key)
}

// === View Functions ===

public fun is_owner(admin: &Admin, addr: address): bool {
    vector::contains(&admin.owners, &addr)
}

public fun get_version(admin: &Admin): u64 {
    admin.version
}

public fun get_owners(admin: &Admin): vector<address> {
    admin.owners
}

public fun get_created_at(admin: &Admin): u64 {
    admin.created_at
}

public fun get_admin_id(cap: &AdminCap): ID {
    cap.admin_id
}

// Check if dynamic field exists
public fun has_field<K: copy + drop + store>(admin: &Admin, key: K): bool {
    df::exists_(&admin.id, key)
}

// Borrow dynamic field
public fun borrow_field<K: copy + drop + store, V: store>(admin: &Admin, key: K): &V {
    df::borrow(&admin.id, key)
}


// Borrow mutable dynamic field (requires admin cap)
public fun borrow_field_mut<K: copy + drop + store, V: store>(
    admin: &mut Admin,
    cap: &AdminCap,
    key: K,
    ctx: &mut TxContext
): &mut V {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);
    assert!(is_owner(admin, tx_context::sender(ctx)), E_NOT_OWNER);

    df::borrow_mut(&mut admin.id, key)
}

// === Test Functions ===
#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}
