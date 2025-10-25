module crowd_walrus::profiles;

use std::string::String;
use sui::object::{Self as sui_object};
use sui::tx_context::{Self as tx_ctx};
use sui::vec_map::{Self as vec_map};

const E_NOT_PROFILE_OWNER: u64 = 1;
const E_KEY_VALUE_MISMATCH: u64 = 2;
const E_OVERFLOW: u64 = 3;
const E_INVALID_BADGE_LEVEL: u64 = 4;
const E_INVALID_BADGE_MASK: u64 = 5;

const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;
const BADGE_LEVEL_MAX: u8 = 5;
const BADGE_LEVEL_MASK: u16 = 0x001F;

public struct Profile has key {
    id: sui_object::UID,
    owner: address,
    total_usd_micro: u64,
    badge_levels_earned: u16,
    metadata: vec_map::VecMap<String, String>,
}

public fun owner(profile: &Profile): address {
    profile.owner
}

public fun total_usd_micro(profile: &Profile): u64 {
    profile.total_usd_micro
}

public fun badge_levels_earned(profile: &Profile): u16 {
    profile.badge_levels_earned
}

public fun metadata(profile: &Profile): &vec_map::VecMap<String, String> {
    &profile.metadata
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
        badge_levels_earned: 0,
        metadata: vec_map::from_keys_values(metadata_keys, metadata_values),
    }
}

public(package) fun add_usd(profile: &mut Profile, amount_micro: u64) {
    if (amount_micro == 0) {
        return
    };

    let remaining = U64_MAX - profile.total_usd_micro;
    assert!(amount_micro <= remaining, E_OVERFLOW);
    profile.total_usd_micro = profile.total_usd_micro + amount_micro;
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
    profile.owner = sender;
}
