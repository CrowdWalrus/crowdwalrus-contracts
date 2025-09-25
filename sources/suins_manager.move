module crowd_walrus::suins_manager;

use std::string::String;
use subdomains::subdomains::{new_leaf, remove_leaf};
use sui::clock::Clock;
use sui::dynamic_field as df;
use sui::dynamic_object_field as dof;
use sui::event;
use suins::suins::SuiNS;
use suins::suins_registration::SuinsRegistration;

const E_SUINS_NFT_ALREADY_REGISTERED: u64 = 1;
const E_SUINS_NFT_NOT_FOUND: u64 = 2;
const E_APP_NOT_AUTHORIZED: u64 = 3;

// === Structs ===
public struct RegKey has copy, drop, store {}

public struct SuiNSManager has key {
    id: UID,
}

/// Capability for the admin of the SuiNSManager
public struct AdminCap has key, store {
    id: UID,
    suins_manager_id: ID,
}

/// === Events ===
public struct SuiNSManagerCreated has copy, drop {
    suins_manager_id: ID,
    creator: address,
}

public struct AdminCreated has copy, drop {
    suins_manager_id: ID,
    admin_id: ID,
    creator: address,
}

// === App Auth ===

/// An authorization Key kept in the SuiNSManager - allows applications access
/// protected features of the SuiNSManager (such as app_add_balance, etc.)
/// The `App` type parameter is a witness which should be defined in the
/// original module (Controller, Registry, Registrar - whatever).
public struct AppKey<phantom App: drop> has copy, drop, store {}

/// Authorize an application to access protected features of the SuiNS.
public fun authorize_app<App: drop>(self: &mut SuiNSManager, _: &AdminCap) {
    df::add(&mut self.id, AppKey<App> {}, true);
}

/// Deauthorize an application by removing its authorization key.
public fun deauthorize_app<App: drop>(self: &mut SuiNSManager, _: &AdminCap): bool {
    df::remove(&mut self.id, AppKey<App> {})
}

/// Check if an application is authorized to access protected features of
/// the SuiNS.
public fun is_app_authorized<App: drop>(self: &SuiNSManager): bool {
    df::exists_(&self.id, AppKey<App> {})
}

/// Assert that an application is authorized to access protected features of
/// the SuiNS. Aborts with `EAppNotAuthorized` if not.
public fun assert_app_is_authorized<App: drop>(self: &SuiNSManager) {
    assert!(self.is_app_authorized<App>(), E_APP_NOT_AUTHORIZED);
}

// === SuiNS Registry ===

entry fun set_suins_nft(self: &mut SuiNSManager, _: &AdminCap, suins_nft: SuinsRegistration) {
    assert!(!dof::exists_(&self.id, RegKey {}), E_SUINS_NFT_ALREADY_REGISTERED);
    dof::add(&mut self.id, RegKey {}, suins_nft);
}

entry fun remove_suins_nft(self: &mut SuiNSManager, _: &AdminCap, recipient: address) {
    assert!(dof::exists_(&self.id, RegKey {}), E_SUINS_NFT_NOT_FOUND);
    let suins_nft: SuinsRegistration = dof::remove(&mut self.id, RegKey {});
    transfer::public_transfer(suins_nft, recipient);
}

fun get_suins_nft(self: &SuiNSManager): &SuinsRegistration {
    assert!(dof::exists_(&self.id, RegKey {}), E_SUINS_NFT_NOT_FOUND);
    dof::borrow(&self.id, RegKey {})
}

// === Protected Functions ===
public(package) fun new<App: drop>(_: &App, ctx: &mut TxContext): (ID, AdminCap) {
    let mut suins_manager = SuiNSManager {
        id: object::new(ctx),
    };
    df::add(&mut suins_manager.id, AppKey<App> {}, true);

    event::emit(SuiNSManagerCreated {
        suins_manager_id: object::id(&suins_manager),
        creator: tx_context::sender(ctx),
    });

    let suins_manager_id = object::id(&suins_manager);
    let suins_manager_cap = AdminCap {
        id: object::new(ctx),
        suins_manager_id: suins_manager_id,
    };
    event::emit(AdminCreated {
        suins_manager_id: suins_manager_id,
        admin_id: object::id(&suins_manager_cap),
        creator: tx_context::sender(ctx),
    });

    transfer::share_object(suins_manager);
    (suins_manager_id, suins_manager_cap)
}

// === Public Functions ===

/// Register a subdomain for the SuiNS.
/// Aborts with `ERecordExists` if the subdomain already exists.
public fun register_subdomain<App: drop>(
    self: &SuiNSManager,
    _: &App,
    suins: &mut SuiNS,
    clock: &Clock,
    subdomain_name: String,
    target: address,
    ctx: &mut TxContext,
) {
    self.assert_app_is_authorized<App>();

    new_leaf(
        suins,
        get_suins_nft(self),
        clock,
        subdomain_name,
        target,
        ctx,
    );
}

/// Remove a subdomain from the SuiNS.
/// Aborts with `ERecordNotFound` if the subdomain does not exist.
public fun remove_subdomain(
    self: &SuiNSManager,
    _: &AdminCap,
    suins: &mut SuiNS,
    subdomain_name: String,
    clock: &Clock,
) {
    remove_leaf(suins, get_suins_nft(self), clock, subdomain_name);
}

#[test_only]
public fun create_suins_manager(ctx: &mut TxContext): SuiNSManager {
    SuiNSManager {
        id: object::new(ctx),
    }
}

#[test_only]
public fun create_and_share_suins_manager(ctx: &mut TxContext): ID {
    let suins_manager = create_suins_manager(ctx);
    let suins_manager_id = object::id(&suins_manager);
    transfer::share_object(suins_manager);
    suins_manager_id
}

#[test_only]
public fun create_admin_cap_for_user(suins_manager_id: ID, user: address, ctx: &mut TxContext): ID {
    let admin_cap = AdminCap {
        id: object::new(ctx),
        suins_manager_id: suins_manager_id,
    };
    let admin_cap_id = object::id(&admin_cap);
    transfer::transfer(admin_cap, user);
    admin_cap_id
}
