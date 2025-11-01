module crowd_walrus::profiles;

use std::string::String;
use sui::clock::{Self as clock, Clock};
use sui::dynamic_field as df;
use sui::event;
use sui::object::{Self as sui_object};
use sui::tx_context::{Self as tx_ctx};
use sui::vec_map::{Self as vec_map};

const E_NOT_PROFILE_OWNER: u64 = 1;
const E_KEY_VALUE_MISMATCH: u64 = 2;
const E_OVERFLOW: u64 = 3;
const E_INVALID_BADGE_LEVEL: u64 = 4;
const E_INVALID_BADGE_MASK: u64 = 5;
const E_PROFILE_EXISTS: u64 = 6;

public(package) fun profile_exists_error_code(): u64 {
    E_PROFILE_EXISTS
}

public struct ProfilesRegistry has key {
    id: sui_object::UID,
}

public struct ProfileCreated has copy, drop {
    owner: address,
    profile_id: sui_object::ID,
    timestamp_ms: u64,
}

public struct RegistryKey has copy, drop, store {
    owner: address,
}

fun registry_key(owner: address): RegistryKey {
    RegistryKey { owner }
}

public fun exists(registry: &ProfilesRegistry, owner: address): bool {
    df::exists_(&registry.id, registry_key(owner))
}

public fun id_of(registry: &ProfilesRegistry, owner: address): sui_object::ID {
    *df::borrow(&registry.id, registry_key(owner))
}

public(package) fun create_registry(ctx: &mut tx_ctx::TxContext): ProfilesRegistry {
    ProfilesRegistry {
        id: sui_object::new(ctx),
    }
}

public(package) fun share_registry(registry: ProfilesRegistry) {
    sui::transfer::share_object(registry);
}

public(package) fun create_for(
    registry: &mut ProfilesRegistry,
    owner: address,
    clock: &Clock,
    ctx: &mut tx_ctx::TxContext,
): Profile {
    let sender = tx_ctx::sender(ctx);
    assert!(owner == sender, E_NOT_PROFILE_OWNER);
    assert!(!exists(registry, owner), E_PROFILE_EXISTS);

    let profile = create(owner, vector::empty(), vector::empty(), ctx);
    let profile_id = sui_object::id(&profile);

    df::add(&mut registry.id, registry_key(owner), profile_id);

    event::emit(ProfileCreated {
        owner,
        profile_id,
        timestamp_ms: clock::timestamp_ms(clock),
    });

    profile
}

public(package) fun create_or_get_profile_for_sender(
    registry: &mut ProfilesRegistry,
    clock: &Clock,
    ctx: &mut tx_ctx::TxContext,
): sui_object::ID {
    let sender = tx_ctx::sender(ctx);
    if (exists(registry, sender)) {
        id_of(registry, sender)
    } else {
        let profile = create_for(registry, sender, clock, ctx);
        let profile_id = sui_object::id(&profile);
        sui::transfer::transfer(profile, sender);
        profile_id
    }
}

#[test_only]
public fun create_registry_for_tests(ctx: &mut tx_ctx::TxContext): ProfilesRegistry {
    create_registry(ctx)
}

const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;
const BADGE_LEVEL_MAX: u8 = 5;
const BADGE_LEVEL_MASK: u16 = 0x001F;

public struct Profile has key {
    id: sui_object::UID,
    owner: address,
    total_usd_micro: u64,
    total_donations_count: u64,
    badge_levels_earned: u16,
    metadata: vec_map::VecMap<String, String>,
}

public fun owner(profile: &Profile): address {
    profile.owner
}

public fun total_usd_micro(profile: &Profile): u64 {
    profile.total_usd_micro
}

public fun total_donations_count(profile: &Profile): u64 {
    profile.total_donations_count
}

public fun badge_levels_earned(profile: &Profile): u16 {
    profile.badge_levels_earned
}

public fun metadata(profile: &Profile): &vec_map::VecMap<String, String> {
    &profile.metadata
}

#[test_only]
public(package) fun set_totals_for_test(
    profile: &mut Profile,
    usd_micro: u64,
    donations_count: u64,
) {
    profile.total_usd_micro = usd_micro;
    profile.total_donations_count = donations_count;
}

public fun has_badge_level(profile: &Profile, level: u8): bool {
    if (level == 0 || level > BADGE_LEVEL_MAX) {
        return false
    };
    let shift = level - 1;
    let mask = 1u16 << shift;
    (profile.badge_levels_earned & mask) != 0
}

public(package) fun create(
    owner: address,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    ctx: &mut tx_ctx::TxContext,
): Profile {
    assert!(
        std::vector::length(&metadata_keys) == std::vector::length(&metadata_values),
        E_KEY_VALUE_MISMATCH,
    );

    Profile {
        id: sui_object::new(ctx),
        owner,
        total_usd_micro: 0,
        total_donations_count: 0,
        badge_levels_earned: 0,
        metadata: vec_map::from_keys_values(metadata_keys, metadata_values),
    }
}

public(package) fun add_contribution(profile: &mut Profile, amount_micro: u64) {
    if (amount_micro == 0) {
        return
    };

    let remaining = U64_MAX - profile.total_usd_micro;
    assert!(amount_micro <= remaining, E_OVERFLOW);
    profile.total_usd_micro = profile.total_usd_micro + amount_micro;
    assert!(profile.total_donations_count < U64_MAX, E_OVERFLOW);
    profile.total_donations_count = profile.total_donations_count + 1;
}

public(package) fun grant_badge_level(profile: &mut Profile, level: u8) {
    assert!(level > 0 && level <= BADGE_LEVEL_MAX, E_INVALID_BADGE_LEVEL);
    let shift = level - 1;
    let mask = 1u16 << shift;
    profile.badge_levels_earned = profile.badge_levels_earned | mask;
}

public(package) fun grant_badge_levels(profile: &mut Profile, mask: u16) {
    assert!(mask <= BADGE_LEVEL_MASK, E_INVALID_BADGE_MASK);
    profile.badge_levels_earned = profile.badge_levels_earned | mask;
}

public(package) fun transfer_to(profile: Profile, recipient: address) {
    assert!(profile.owner == recipient, E_NOT_PROFILE_OWNER);
    sui::transfer::transfer(profile, recipient);
}

public(package) fun set_metadata(
    profile: &mut Profile,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    ctx: &tx_ctx::TxContext,
) {
    let sender = tx_ctx::sender(ctx);
    assert!(profile.owner == sender, E_NOT_PROFILE_OWNER);
    assert!(
        std::vector::length(&metadata_keys) == std::vector::length(&metadata_values),
        E_KEY_VALUE_MISMATCH,
    );
    let mut i = 0;
    let len = std::vector::length(&metadata_keys);
    while (i < len) {
        let key = *std::vector::borrow(&metadata_keys, i);
        let value = *std::vector::borrow(&metadata_values, i);
        if (vec_map::contains(&profile.metadata, &key)) {
            let existing = vec_map::get_mut(&mut profile.metadata, &key);
            *existing = value;
        } else {
            vec_map::insert(&mut profile.metadata, key, value);
        };
        i = i + 1;
    };
}
