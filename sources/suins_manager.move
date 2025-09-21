module crowd_walrus::suins_manager;

use std::string::String;
use subdomains::subdomains::{new_leaf, remove_leaf};
use sui::clock::Clock;
use sui::dynamic_field as df;
use sui::dynamic_object_field as dof;
use suins::suins::SuiNS;
use suins::suins_registration::SuinsRegistration;

const E_SUINS_NFT_ALREADY_REGISTERED: u64 = 1;
const E_SUINS_NFT_NOT_FOUND: u64 = 2;
const E_APP_NOT_AUTHORIZED: u64 = 3;

// === Structs ===
public struct RegKey has copy, drop, store {}

public struct SuiNSManager has key {
    id: UID,
    suins_id: ID,
    crowd_walrus_id: ID,
    domain_name: vector<u8>,
}

/// Capability for the admin of the SuiNSManager
public struct AdminCap has key, store {
    id: UID,
    suins_manager_id: ID,
}

// === App Auth ===

/// An authorization Key kept in the SuiNSManager - allows applications access
/// protected features of the SuiNSManager (such as app_add_balance, etc.)
/// The `App` type parameter is a witness which should be defined in the
/// original module (Controller, Registry, Registrar - whatever).
public struct AppKey<phantom App: drop> has copy, drop, store {}

/// Authorize an application to access protected features of the SuiNS.
public fun authorize_app<App: drop>(_: &AdminCap, self: &mut SuiNSManager) {
    df::add(&mut self.id, AppKey<App> {}, true);
}

/// Deauthorize an application by removing its authorization key.
public fun deauthorize_app<App: drop>(_: &AdminCap, self: &mut SuiNSManager): bool {
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

public fun add_suins_nft(_: &AdminCap, self: &mut SuiNSManager, suins_nft: SuinsRegistration) {
    assert!(!dof::exists_(&self.id, RegKey {}), E_SUINS_NFT_ALREADY_REGISTERED);
    dof::add(&mut self.id, RegKey {}, suins_nft);
}

public fun get_back_suins_nft(_: &AdminCap, self: &mut SuiNSManager): SuinsRegistration {
    assert!(dof::exists_(&self.id, RegKey {}), E_SUINS_NFT_NOT_FOUND);
    dof::remove(&mut self.id, RegKey {})
}

fun get_suins_nft(self: &SuiNSManager): &SuinsRegistration {
    assert!(dof::exists_(&self.id, RegKey {}), E_SUINS_NFT_NOT_FOUND);
    dof::borrow(&self.id, RegKey {})
}

// === Protected Functions ===
public(package) fun new(
    suins_id: ID,
    crowd_walrus_id: ID,
    domain_name: vector<u8>,
    ctx: &mut TxContext,
): (ID, AdminCap) {
    let suins_manager = SuiNSManager {
        id: object::new(ctx),
        suins_id: suins_id,
        crowd_walrus_id: crowd_walrus_id,
        domain_name: domain_name,
    };

    let suins_manager_id = object::id(&suins_manager);
    let suins_manager_cap = AdminCap {
        id: object::new(ctx),
        suins_manager_id: suins_manager_id,
    };

    transfer::share_object(suins_manager);
    (suins_manager_id, suins_manager_cap)
}

// === Public Functions ===

/// Register a subdomain for the SuiNS.
/// Aborts with `ERecordExists` if the subdomain already exists.
public fun register_subdomain<App: drop>(
    _: &App,
    self: &SuiNSManager,
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
