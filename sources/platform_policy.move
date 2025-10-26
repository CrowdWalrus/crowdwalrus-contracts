module crowd_walrus::platform_policy;

use crowd_walrus::campaign;
use std::string::String;
use sui::clock::{Self as clock, Clock};
use sui::event;
use sui::object::{Self as sui_object};
use sui::table;
use sui::tx_context::{Self as tx_ctx};

const E_POLICY_EXISTS: u64 = 1;
const E_POLICY_NOT_FOUND: u64 = 2;
const E_POLICY_DISABLED: u64 = 3;

public struct Policy has copy, drop, store {
    platform_bps: u16,
    platform_address: address,
    enabled: bool,
}

public struct PolicyRegistry has key {
    id: sui_object::UID,
    crowd_walrus_id: sui_object::ID,
    policies: table::Table<String, Policy>,
}

public struct PolicyAdded has copy, drop {
    policy_name: String,
    platform_bps: u16,
    platform_address: address,
    enabled: bool,
    timestamp_ms: u64,
}

public struct PolicyUpdated has copy, drop {
    policy_name: String,
    platform_bps: u16,
    platform_address: address,
    enabled: bool,
    timestamp_ms: u64,
}

public struct PolicyDisabled has copy, drop {
    policy_name: String,
    platform_bps: u16,
    platform_address: address,
    enabled: bool,
    timestamp_ms: u64,
}

public(package) fun create_registry(
    crowd_walrus_id: sui_object::ID,
    ctx: &mut tx_ctx::TxContext,
): PolicyRegistry {
    PolicyRegistry {
        id: sui_object::new(ctx),
        crowd_walrus_id,
        policies: table::new(ctx),
    }
}

public(package) fun share_registry(registry: PolicyRegistry) {
    sui::transfer::share_object(registry);
}

public fun contains(registry: &PolicyRegistry, name: &String): bool {
    table::contains(&registry.policies, *name)
}

public fun borrow_policy(registry: &PolicyRegistry, name: &String): &Policy {
    assert!(contains(registry, name), E_POLICY_NOT_FOUND);
    table::borrow(&registry.policies, *name)
}

public fun borrow_policy_mut(
    registry: &mut PolicyRegistry,
    name: &String,
): &mut Policy {
    assert!(contains(registry, name), E_POLICY_NOT_FOUND);
    table::borrow_mut(&mut registry.policies, *name)
}

public fun policy_copy(registry: &PolicyRegistry, name: &String): Policy {
    let policy_ref = borrow_policy(registry, name);
    *policy_ref
}

public fun registry_owner_id(registry: &PolicyRegistry): sui_object::ID {
    registry.crowd_walrus_id
}

public fun require_enabled_policy(
    registry: &PolicyRegistry,
    name: &String,
): &Policy {
    let policy = borrow_policy(registry, name);
    assert!(policy.enabled, E_POLICY_DISABLED);
    policy
}

fun add_policy_with_timestamp(
    registry: &mut PolicyRegistry,
    name: String,
    platform_bps: u16,
    platform_address: address,
    timestamp_ms: u64,
) {
    assert!(!contains(registry, &name), E_POLICY_EXISTS);
    assert!(platform_bps <= 10_000, campaign::e_invalid_bps());
    assert!(platform_address != @0x0, campaign::e_zero_address());

    let policy = Policy {
        platform_bps,
        platform_address: platform_address,
        enabled: true,
    };
    let event_name = copy name;
    table::add(&mut registry.policies, name, policy);
    emit_added_event_with_timestamp(event_name, platform_bps, platform_address, timestamp_ms);
}

public(package) fun add_policy(
    registry: &mut PolicyRegistry,
    name: String,
    platform_bps: u16,
    platform_address: address,
    clock: &Clock,
) {
    add_policy_with_timestamp(
        registry,
        name,
        platform_bps,
        platform_address,
        clock::timestamp_ms(clock),
    );
}

public(package) fun add_policy_bootstrap(
    registry: &mut PolicyRegistry,
    name: String,
    platform_bps: u16,
    platform_address: address,
) {
    add_policy_with_timestamp(
        registry,
        name,
        platform_bps,
        platform_address,
        0,
    );
}

public(package) fun update_policy(
    registry: &mut PolicyRegistry,
    name: String,
    platform_bps: u16,
    platform_address: address,
    clock: &Clock,
) {
    assert!(platform_bps <= 10_000, campaign::e_invalid_bps());
    assert!(platform_address != @0x0, campaign::e_zero_address());

    let event_name = copy name;
    let policy = borrow_policy_mut(registry, &name);
    policy.platform_bps = platform_bps;
    policy.platform_address = platform_address;
    emit_updated_event(event_name, policy, clock);
}

public(package) fun disable_policy(
    registry: &mut PolicyRegistry,
    name: String,
    clock: &Clock,
) {
    let event_name = copy name;
    let policy = borrow_policy_mut(registry, &name);
    if (!policy.enabled) {
        abort E_POLICY_DISABLED
    };
    policy.enabled = false;
    emit_disabled_event(event_name, policy, clock);
}

/// Re-enable a policy; even if it is already active we emit `PolicyUpdated`
/// so indexers receive a fresh timestamp.
public(package) fun enable_policy(
    registry: &mut PolicyRegistry,
    name: String,
    clock: &Clock,
) {
    let event_name = copy name;
    let policy = borrow_policy_mut(registry, &name);
    if (!policy.enabled) {
        policy.enabled = true;
        emit_updated_event(event_name, policy, clock);
        return
    };
    // No-op if already enabled; still emit update to record timestamp
    emit_updated_event(event_name, policy, clock);
}

public fun policy_platform_bps(policy: &Policy): u16 {
    policy.platform_bps
}

public fun policy_platform_address(policy: &Policy): address {
    policy.platform_address
}

public fun policy_enabled(policy: &Policy): bool {
    policy.enabled
}

fun emit_added_event_with_timestamp(
    policy_name: String,
    platform_bps: u16,
    platform_address: address,
    timestamp_ms: u64,
) {
    event::emit(PolicyAdded {
        policy_name,
        platform_bps,
        platform_address,
        enabled: true,
        timestamp_ms,
    });
}

fun emit_updated_event(policy_name: String, policy: &Policy, clock: &Clock) {
    event::emit(PolicyUpdated {
        policy_name,
        platform_bps: policy.platform_bps,
        platform_address: policy.platform_address,
        enabled: policy.enabled,
        timestamp_ms: clock::timestamp_ms(clock),
    });
}

fun emit_disabled_event(policy_name: String, policy: &Policy, clock: &Clock) {
    event::emit(PolicyDisabled {
        policy_name,
        platform_bps: policy.platform_bps,
        platform_address: policy.platform_address,
        enabled: policy.enabled,
        timestamp_ms: clock::timestamp_ms(clock),
    });
}

#[test_only]
public fun create_registry_for_tests(
    crowd_walrus_id: sui_object::ID,
    ctx: &mut tx_ctx::TxContext,
): PolicyRegistry {
    create_registry(crowd_walrus_id, ctx)
}

#[test_only]
public fun destroy_registry(registry: PolicyRegistry) {
    let PolicyRegistry { id, policies, crowd_walrus_id: _ } = registry;
    table::drop(policies);
    sui_object::delete(id);
}
