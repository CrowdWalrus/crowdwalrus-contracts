module crowd_walrus::profiles;

use std::string::{Self as string, String};

use sui::clock::{Self as clock, Clock};
use sui::dynamic_field as df;
use sui::event;
use sui::object::{Self as sui_object};
use sui::tx_context::{Self as tx_ctx};
use sui::vec_map::{Self as vec_map, VecMap};

const E_NOT_PROFILE_OWNER: u64 = 1;
const E_KEY_VALUE_MISMATCH: u64 = 2;
const E_OVERFLOW: u64 = 3;
const E_INVALID_BADGE_LEVEL: u64 = 4;
const E_INVALID_BADGE_MASK: u64 = 5;
const E_PROFILE_EXISTS: u64 = 6;
const E_EMPTY_KEY: u64 = 7;
const E_EMPTY_VALUE: u64 = 8;
const E_KEY_TOO_LONG: u64 = 9;
const E_VALUE_TOO_LONG: u64 = 10;
const E_TOO_MANY_METADATA_ENTRIES: u64 = 11;
const E_SUBDOMAIN_ALREADY_SET: u64 = 12;
const E_SUBDOMAIN_NOT_SET: u64 = 13;

public(package) fun profile_exists_error_code(): u64 {
    E_PROFILE_EXISTS
}

public(package) fun not_profile_owner_error_code(): u64 {
    E_NOT_PROFILE_OWNER
}

public(package) fun subdomain_already_set_error_code(): u64 {
    E_SUBDOMAIN_ALREADY_SET
}

public(package) fun subdomain_not_set_error_code(): u64 {
    E_SUBDOMAIN_NOT_SET
}

public struct ProfilesRegistry has key {
    id: sui_object::UID,
}

public struct ProfileCreated has copy, drop {
    owner: address,
    profile_id: sui_object::ID,
    timestamp_ms: u64,
}

public struct ProfileMetadataUpdated has copy, drop {
    profile_id: sui_object::ID,
    owner: address,
    key: String,
    value: String,
    timestamp_ms: u64,
}

public struct ProfileSubdomainSet has copy, drop {
    profile_id: sui_object::ID,
    owner: address,
    subdomain_name: String,
    timestamp_ms: u64,
}

public struct ProfileSubdomainRemoved has copy, drop {
    profile_id: sui_object::ID,
    owner: address,
    subdomain_name: String,
    timestamp_ms: u64,
    removed_by: address,
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

/// PTB-friendly helper that creates and registers a profile for the sender
/// and returns the owned Profile object so callers can compose additional
/// operations (metadata updates, subdomain registration, etc.) within the
/// same transaction before transferring it out.
public fun create_profile_for_sender(
    registry: &mut ProfilesRegistry,
    clock: &Clock,
    ctx: &mut tx_ctx::TxContext,
): Profile {
    create_for(registry, tx_ctx::sender(ctx), clock, ctx)
}

entry fun create_profile(
    registry: &mut ProfilesRegistry,
    clock: &Clock,
    ctx: &mut tx_ctx::TxContext,
) {
    let sender = tx_ctx::sender(ctx);
    let profile = create_profile_for_sender(registry, clock, ctx);
    transfer_to(profile, sender);
}

// Clock parameter ensures ProfileMetadataUpdated timestamps remain canonical for indexers.
entry fun update_profile_metadata(
    profile: &mut Profile,
    key: String,
    value: String,
    clock: &Clock,
    ctx: &tx_ctx::TxContext,
) {
    upsert_profile_metadata(
        profile,
        vector[key],
        vector[value],
        clock,
        ctx,
    );
}

/// Batch-capable metadata updater that emits one `ProfileMetadataUpdated` event
/// per key/value pair. Accepts empty vectors (no-op) so callers can keep a
/// single PTB structure regardless of whether metadata is provided.
public fun upsert_profile_metadata(
    profile: &mut Profile,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    clock: &Clock,
    ctx: &tx_ctx::TxContext,
) {
    let sender = tx_ctx::sender(ctx);
    assert!(profile.owner == sender, E_NOT_PROFILE_OWNER);
    assert!(
        std::vector::length(&metadata_keys) == std::vector::length(&metadata_values),
        E_KEY_VALUE_MISMATCH,
    );

    let len = std::vector::length(&metadata_keys);
    let mut i = 0;
    while (i < len) {
        let key_ref = std::vector::borrow(&metadata_keys, i);
        let value_ref = std::vector::borrow(&metadata_values, i);

        assert_valid_metadata_entry(&profile.metadata, key_ref, value_ref);

        let key_for_store = *key_ref;
        let value_for_store = *value_ref;
        let key_for_event = *key_ref;
        let value_for_event = *value_ref;

        insert_or_update_metadata(&mut profile.metadata, key_for_store, value_for_store);

        event::emit(ProfileMetadataUpdated {
            profile_id: sui_object::id(profile),
            owner: sender,
            key: key_for_event,
            value: value_for_event,
            timestamp_ms: clock::timestamp_ms(clock),
        });

        i = i + 1;
    };
}

#[test_only]
public fun create_registry_for_tests(ctx: &mut tx_ctx::TxContext): ProfilesRegistry {
    create_registry(ctx)
}

const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;
const BADGE_LEVEL_MAX: u8 = 5;
const BADGE_LEVEL_MASK: u16 = 0x001F;
const MAX_METADATA_KEY_LENGTH: u64 = 64;
const MAX_METADATA_VALUE_LENGTH: u64 = 2048;
const MAX_METADATA_ENTRIES: u64 = 100;

public struct Profile has key {
    id: sui_object::UID,
    owner: address,
    total_usd_micro: u64,
    total_donations_count: u64,
    badge_levels_earned: u16,
    subdomain_name: std::option::Option<String>,
    metadata: VecMap<String, String>,
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

public fun metadata(profile: &Profile): &VecMap<String, String> {
    &profile.metadata
}

public fun subdomain_name(profile: &Profile): std::option::Option<String> {
    profile.subdomain_name
}

public(package) fun emit_profile_subdomain_set(
    profile_id: sui_object::ID,
    owner: address,
    subdomain_name: String,
    timestamp_ms: u64,
) {
    event::emit(ProfileSubdomainSet {
        profile_id,
        owner,
        subdomain_name,
        timestamp_ms,
    });
}

public(package) fun emit_profile_subdomain_removed(
    profile_id: sui_object::ID,
    owner: address,
    subdomain_name: String,
    timestamp_ms: u64,
    removed_by: address,
) {
    event::emit(ProfileSubdomainRemoved {
        profile_id,
        owner,
        subdomain_name,
        timestamp_ms,
        removed_by,
    });
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

    let metadata = vec_map::from_keys_values(metadata_keys, metadata_values);
    assert_valid_metadata(&metadata);

    Profile {
        id: sui_object::new(ctx),
        owner,
        total_usd_micro: 0,
        total_donations_count: 0,
        badge_levels_earned: 0,
        subdomain_name: std::option::none(),
        metadata,
    }
}

public(package) fun assert_subdomain_not_set(profile: &Profile) {
    assert!(std::option::is_none(&profile.subdomain_name), E_SUBDOMAIN_ALREADY_SET);
}

public(package) fun set_subdomain(profile: &mut Profile, subdomain_name: String) {
    assert_subdomain_not_set(profile);
    profile.subdomain_name = std::option::some(subdomain_name);
}

public(package) fun clear_subdomain(profile: &mut Profile) {
    assert!(std::option::is_some(&profile.subdomain_name), E_SUBDOMAIN_NOT_SET);
    profile.subdomain_name = std::option::none();
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
        assert_valid_metadata_entry(&profile.metadata, &key, &value);
        insert_or_update_metadata(&mut profile.metadata, key, value);
        i = i + 1;
    };
}

fun assert_valid_metadata_entry(
    metadata: &VecMap<String, String>,
    key: &String,
    value: &String,
) {
    let key_len = string::length(key);
    let value_len = string::length(value);
    assert!(key_len > 0, E_EMPTY_KEY);
    assert!(value_len > 0, E_EMPTY_VALUE);
    assert!(key_len <= MAX_METADATA_KEY_LENGTH, E_KEY_TOO_LONG);
    assert!(value_len <= MAX_METADATA_VALUE_LENGTH, E_VALUE_TOO_LONG);
    if (!vec_map::contains(metadata, key)) {
        assert!(vec_map::length(metadata) < MAX_METADATA_ENTRIES, E_TOO_MANY_METADATA_ENTRIES);
    };
}

fun assert_valid_metadata(metadata: &VecMap<String, String>) {
    let mut i = 0;
    let len = vec_map::length(metadata);
    assert!(len <= MAX_METADATA_ENTRIES, E_TOO_MANY_METADATA_ENTRIES);
    while (i < len) {
        let (key_ref, value_ref) = vec_map::get_entry_by_idx(metadata, i);
        let key_len = string::length(key_ref);
        let value_len = string::length(value_ref);
        assert!(key_len > 0, E_EMPTY_KEY);
        assert!(value_len > 0, E_EMPTY_VALUE);
        assert!(key_len <= MAX_METADATA_KEY_LENGTH, E_KEY_TOO_LONG);
        assert!(value_len <= MAX_METADATA_VALUE_LENGTH, E_VALUE_TOO_LONG);
        i = i + 1;
    };
}

fun insert_or_update_metadata(
    metadata: &mut VecMap<String, String>,
    key: String,
    value: String,
) {
    if (vec_map::contains(metadata, &key)) {
        let existing = vec_map::get_mut(metadata, &key);
        *existing = value;
    } else {
        vec_map::insert(metadata, key, value);
    };
}

public fun profile_metadata_updated_owner(event: &ProfileMetadataUpdated): address {
    event.owner
}

public fun profile_metadata_updated_profile_id(
    event: &ProfileMetadataUpdated,
): sui_object::ID {
    event.profile_id
}

public fun profile_metadata_updated_key(event: &ProfileMetadataUpdated): String {
    copy event.key
}

public fun profile_metadata_updated_value(event: &ProfileMetadataUpdated): String {
    copy event.value
}

public fun profile_metadata_updated_timestamp_ms(event: &ProfileMetadataUpdated): u64 {
    event.timestamp_ms
}
