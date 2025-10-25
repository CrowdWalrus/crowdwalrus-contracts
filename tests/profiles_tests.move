#[test_only]
module crowd_walrus::profiles_tests;

use crowd_walrus::profiles::{Self as profiles};
use std::string::{Self as string};
use std::unit_test::assert_eq;
use sui::test_scenario::{Self as ts};
use sui::test_utils;

const OWNER: address = @0x1;
const OTHER: address = @0x2;
const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;

#[test]
fun test_create_profile_initial_state() {
    let mut scenario = ts::begin(OWNER);
    let profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );

    assert_eq!(profiles::owner(&profile), OWNER);
    assert_eq!(profiles::total_usd_micro(&profile), 0);
    assert_eq!(profiles::total_donations_count(&profile), 0);
    assert_eq!(profiles::badge_levels_earned(&profile), 0);
    assert_eq!(profiles::metadata(&profile).length(), 0);

    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test]
fun test_add_contribution_updates_totals_and_count() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );

    profiles::add_contribution(&mut profile, 500);
    profiles::add_contribution(&mut profile, 250);
    assert_eq!(profiles::total_usd_micro(&profile), 750);
    assert_eq!(profiles::total_donations_count(&profile), 2);

    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test]
fun test_add_contribution_zero_amount_noop() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );

    profiles::add_contribution(&mut profile, 0);
    profiles::add_contribution(&mut profile, 0);

    assert_eq!(profiles::total_usd_micro(&profile), 0);
    assert_eq!(profiles::total_donations_count(&profile), 0);

    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_OVERFLOW)]
fun test_add_contribution_overflow_aborts() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );

    profiles::add_contribution(&mut profile, U64_MAX);
    profiles::add_contribution(&mut profile, 1);

    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_OVERFLOW)]
fun test_add_contribution_donation_count_overflow_aborts() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );

    profiles::set_totals_for_test(&mut profile, 10, U64_MAX);
    profiles::add_contribution(&mut profile, 1);

    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test]
fun test_set_metadata_owner_updates() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );

    profiles::set_metadata(
        &mut profile,
        vector[string::utf8(b"name")],
        vector[string::utf8(b"Walrus")],
        ts::ctx(&mut scenario),
    );
    let metadata = profiles::metadata(&profile);
    assert_eq!(metadata.length(), 1);
    assert_eq!(*metadata.get(&string::utf8(b"name")), string::utf8(b"Walrus"));

    profiles::set_metadata(
        &mut profile,
        vector[string::utf8(b"bio")],
        vector[string::utf8(b"Sea mammal")],
        ts::ctx(&mut scenario),
    );
    let metadata_after = profiles::metadata(&profile);
    assert_eq!(metadata_after.length(), 2);
    assert_eq!(
        *metadata_after.get(&string::utf8(b"name")),
        string::utf8(b"Walrus"),
    );
    assert_eq!(
        *metadata_after.get(&string::utf8(b"bio")),
        string::utf8(b"Sea mammal"),
    );

    profiles::set_metadata(
        &mut profile,
        vector[string::utf8(b"name")],
        vector[string::utf8(b"Sir Walrus")],
        ts::ctx(&mut scenario),
    );
    let metadata_replace = profiles::metadata(&profile);
    assert_eq!(metadata_replace.length(), 2);
    assert_eq!(
        *metadata_replace.get(&string::utf8(b"name")),
        string::utf8(b"Sir Walrus"),
    );

    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_KEY_VALUE_MISMATCH)]
fun test_set_metadata_key_value_mismatch_aborts() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );

    profiles::set_metadata(
        &mut profile,
        vector[string::utf8(b"name")],
        vector::empty(),
        ts::ctx(&mut scenario),
    );

    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_NOT_PROFILE_OWNER)]
fun test_set_metadata_non_owner_aborts() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );

    ts::next_tx(&mut scenario, OTHER);
    profiles::set_metadata(
        &mut profile,
        vector[string::utf8(b"name")],
        vector[string::utf8(b"Attacker")],
        ts::ctx(&mut scenario),
    );
    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test]
fun test_grant_badge_level_monotonic() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );
    profiles::grant_badge_level(&mut profile, 1);
    profiles::grant_badge_level(&mut profile, 3);
    assert!(profiles::has_badge_level(&profile, 1));
    assert!(profiles::has_badge_level(&profile, 3));
    assert!(!profiles::has_badge_level(&profile, 2));
    let before_mask = profiles::badge_levels_earned(&profile);
    profiles::grant_badge_level(&mut profile, 1);
    assert_eq!(profiles::badge_levels_earned(&profile), before_mask);
    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test]
fun test_grant_badge_levels_mask() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );
    profiles::grant_badge_levels(&mut profile, 0x0003);
    assert!(profiles::has_badge_level(&profile, 1));
    assert!(profiles::has_badge_level(&profile, 2));
    assert!(!profiles::has_badge_level(&profile, 4));
    profiles::grant_badge_levels(&mut profile, 0x0018);
    assert!(profiles::has_badge_level(&profile, 4));
    assert!(profiles::has_badge_level(&profile, 5));
    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_INVALID_BADGE_LEVEL)]
fun test_grant_badge_level_out_of_range_aborts() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );
    profiles::grant_badge_level(&mut profile, 0);
    test_utils::destroy(profile);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_INVALID_BADGE_MASK)]
fun test_grant_badge_levels_invalid_mask_aborts() {
    let mut scenario = ts::begin(OWNER);
    let mut profile = profiles::create(
        OWNER,
        vector::empty(),
        vector::empty(),
        ts::ctx(&mut scenario),
    );
    profiles::grant_badge_levels(&mut profile, 0x0020);
    test_utils::destroy(profile);
    ts::end(scenario);
}
