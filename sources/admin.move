// Singleton Admin
module crowd_walrus_move::admin;


// use std::string::{Self, String};
// use sui::object::{Self, ID, UID};
// use sui::transfer;
// use sui::tx_context::{Self, TxContext};
use sui::dynamic_field as df;
use sui::event;

// Error codes
const E_NOT_AUTHORIZED: u64 = 1;

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


// Capability for admin operations
public struct AdminCap has key, store {
    id: UID,
    admin_id: ID,
}

public struct ValidateCap has key, store {
    id: UID,
    admin_id: ID,
}

// The singleton admin object
public struct Admin has key, store {
    id: UID,
    version: u64,
    created_at: u64,
    // Dynamic fields can be added for extensibility
}

// Initialize the admin singleton - can only be called once
fun init(ctx: &mut TxContext) {
    let admin = Admin {
        id: object::new(ctx),
        version: 1,
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

    // Transfer capability to creator
    transfer::transfer(admin_cap, tx_context::sender(ctx));

    // Share admin object with creator
    transfer::share_object(admin)
}

// Upgrade the admin version
public fun upgrade_version(
    admin: &mut Admin,
    cap: &AdminCap,
    ctx: &mut TxContext
) {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);

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
    value: V
) {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);

    df::add(&mut admin.id, key, value);
}

// Remove dynamic field
public fun remove_field<K: copy + drop + store, V: store>(
    admin: &mut Admin,
    cap: &AdminCap,
    key: K,
): V {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);

    df::remove(&mut admin.id, key)
}

public fun create_validate_cap(admin: &Admin, cap: &AdminCap, new_validator: address, ctx: &mut TxContext) {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);

    transfer::transfer(ValidateCap{
        id: object::new(ctx),
        admin_id: object::id(admin),
    }, new_validator)
}

// === View Functions ===

public fun get_version(admin: &Admin): u64 {
    admin.version
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
): &mut V {
    assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);

    df::borrow_mut(&mut admin.id, key)
}

// === Test Functions ===
#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}
