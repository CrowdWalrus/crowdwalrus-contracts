#[test_only]
module crowd_walrus::profiles_tests;

use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::profiles::{Self as profiles};
use std::string::{Self as string};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::event;
use sui::object::{Self as sui_object};
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
fun test_profiles_registry_create_for_and_lookup() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);
    scenario.next_tx(OWNER);
    let clock = scenario.take_shared<Clock>();
    let mut registry = profiles::create_registry_for_tests(ts::ctx(&mut scenario));

    let profile = profiles::create_for(
        &mut registry,
        OWNER,
        &clock,
        ts::ctx(&mut scenario),
    );

    assert!(profiles::exists(&registry, OWNER));
    let profile_id = sui_object::id(&profile);
    assert_eq!(profiles::id_of(&registry, OWNER), profile_id);
    assert_eq!(profiles::owner(&profile), OWNER);

    test_utils::destroy(profile);
    profiles::share_registry(registry);
    ts::return_shared(clock);

    let effects = ts::next_tx(&mut scenario, OWNER);
    assert_eq!(ts::num_user_events(&effects), 1);

    ts::end(scenario);
}

#[test]
fun test_create_profile_entry_creates_profile() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);

    scenario.next_tx(OWNER);
    let events_before =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());
    let clock = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    assert!(!profiles::exists(&registry, OWNER));

    profiles::create_profile(&mut registry, &clock, ts::ctx(&mut scenario));

    let events_after =
        vector::length(&event::events_by_type<profiles::ProfileCreated>());
    assert_eq!(events_after, events_before + 1);

    ts::return_shared(registry);
    ts::return_shared(clock);

    let effects = ts::next_tx(&mut scenario, OWNER);
    assert_eq!(ts::num_user_events(&effects), 1);

    scenario.next_tx(OWNER);
    let registry_after = scenario.take_shared<profiles::ProfilesRegistry>();
    assert!(profiles::exists(&registry_after, OWNER));
    let profile_id = profiles::id_of(&registry_after, OWNER);
    ts::return_shared(registry_after);
    let _ = ts::next_tx(&mut scenario, OWNER);

    let profile = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    assert_eq!(profiles::owner(&profile), OWNER);
    assert_eq!(profiles::total_usd_micro(&profile), 0);
    assert_eq!(profiles::total_donations_count(&profile), 0);
    assert_eq!(sui_object::id(&profile), profile_id);
    ts::return_to_address(OWNER, profile);

    ts::end(scenario);
}

#[test, expected_failure(
    abort_code = profiles::E_PROFILE_EXISTS,
    location = 0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e::profiles
)]
fun test_create_profile_entry_duplicate_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);

    scenario.next_tx(OWNER);
    let clock = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock);
    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let clock_again = scenario.take_shared<Clock>();
    let mut registry_again = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry_again, &clock_again, ts::ctx(&mut scenario));
    ts::return_shared(registry_again);
    ts::return_shared(clock_again);
    let _ = ts::next_tx(&mut scenario, OWNER);
    ts::end(scenario);
}

#[test, expected_failure(
    abort_code = profiles::E_PROFILE_EXISTS,
    location = 0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e::profiles
)]
fun test_profiles_registry_duplicate_creation_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);
    scenario.next_tx(OWNER);
    let clock = scenario.take_shared<Clock>();
    let mut registry = profiles::create_registry_for_tests(ts::ctx(&mut scenario));

    let profile = profiles::create_for(
        &mut registry,
        OWNER,
        &clock,
        ts::ctx(&mut scenario),
    );

    test_utils::destroy(profile);
    let profile_again = profiles::create_for(
        &mut registry,
        OWNER,
        &clock,
        ts::ctx(&mut scenario),
    );

    test_utils::destroy(profile_again);
    profiles::share_registry(registry);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test]
fun test_create_or_get_profile_creates_when_missing() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);
    scenario.next_tx(OWNER);
    let clock = scenario.take_shared<Clock>();
    let mut registry = profiles::create_registry_for_tests(ts::ctx(&mut scenario));

    let profile_id = profiles::create_or_get_profile_for_sender(
        &mut registry,
        &clock,
        ts::ctx(&mut scenario),
    );

    assert!(profiles::exists(&registry, OWNER));
    assert_eq!(profiles::id_of(&registry, OWNER), profile_id);

    profiles::share_registry(registry);
    ts::return_shared(clock);

    let effects = ts::next_tx(&mut scenario, OWNER);
    assert_eq!(ts::num_user_events(&effects), 1);

    ts::end(scenario);
}

#[test]
fun test_create_or_get_profile_returns_existing_id() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);
    scenario.next_tx(OWNER);
    let clock = scenario.take_shared<Clock>();
    let mut registry = profiles::create_registry_for_tests(ts::ctx(&mut scenario));

    let first_id = profiles::create_or_get_profile_for_sender(
        &mut registry,
        &clock,
        ts::ctx(&mut scenario),
    );
    let second_id = profiles::create_or_get_profile_for_sender(
        &mut registry,
        &clock,
        ts::ctx(&mut scenario),
    );

    assert_eq!(first_id, second_id);
    assert!(profiles::exists(&registry, OWNER));

    profiles::share_registry(registry);
    ts::return_shared(clock);

    let effects = ts::next_tx(&mut scenario, OWNER);
    assert_eq!(ts::num_user_events(&effects), 1);

    ts::end(scenario);
}

#[test]
fun test_update_profile_metadata_updates_value_and_emits_event() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);

    scenario.next_tx(OWNER);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let clock = scenario.take_shared<Clock>();
    let metadata_events_before =
        vector::length(&event::events_by_type<profiles::ProfileMetadataUpdated>());

    profiles::update_profile_metadata(
        &mut profile,
        string::utf8(b"name"),
        string::utf8(b"Walrus"),
        &clock,
        ts::ctx(&mut scenario),
    );

    let metadata_view = profiles::metadata(&profile);
    let key_lookup = string::utf8(b"name");
    assert_eq!(metadata_view.length(), 1);
    assert_eq!(
        *metadata_view.get(&key_lookup),
        string::utf8(b"Walrus"),
    );

    let metadata_events_after =
        event::events_by_type<profiles::ProfileMetadataUpdated>();
    assert_eq!(
        vector::length(&metadata_events_after),
        metadata_events_before + 1,
    );
    let last_event = *vector::borrow(&metadata_events_after, metadata_events_before);
    assert_eq!(profiles::profile_metadata_updated_owner(&last_event), OWNER);
    assert_eq!(
        profiles::profile_metadata_updated_profile_id(&last_event),
        sui_object::id(&profile),
    );
    assert_eq!(profiles::profile_metadata_updated_key(&last_event), key_lookup);
    assert_eq!(
        profiles::profile_metadata_updated_value(&last_event),
        string::utf8(b"Walrus"),
    );

    ts::return_to_address(OWNER, profile);
    ts::return_shared(clock);

    let effects = ts::next_tx(&mut scenario, OWNER);
    assert_eq!(ts::num_user_events(&effects), 1);

    ts::end(scenario);
}

#[test]
fun test_update_profile_metadata_max_length_succeeds() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);

    scenario.next_tx(OWNER);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let clock = scenario.take_shared<Clock>();
    let metadata_events_before =
        vector::length(&event::events_by_type<profiles::ProfileMetadataUpdated>());

    profiles::update_profile_metadata(
        &mut profile,
        make_ascii_string(64),
        make_ascii_string(2048),
        &clock,
        ts::ctx(&mut scenario),
    );

    let metadata_view = profiles::metadata(&profile);
    let key_lookup = make_ascii_string(64);
    assert_eq!(metadata_view.length(), 1);
    assert_eq!(
        *metadata_view.get(&key_lookup),
        make_ascii_string(2048),
    );

    let metadata_events_after =
        event::events_by_type<profiles::ProfileMetadataUpdated>();
    assert_eq!(
        vector::length(&metadata_events_after),
        metadata_events_before + 1,
    );
    let last_event = *vector::borrow(&metadata_events_after, metadata_events_before);
    assert_eq!(profiles::profile_metadata_updated_owner(&last_event), OWNER);
    assert_eq!(
        profiles::profile_metadata_updated_profile_id(&last_event),
        sui_object::id(&profile),
    );
    assert_eq!(
        profiles::profile_metadata_updated_key(&last_event),
        key_lookup,
    );
    assert_eq!(
        profiles::profile_metadata_updated_value(&last_event),
        make_ascii_string(2048),
    );

    ts::return_to_address(OWNER, profile);
    ts::return_shared(clock);

    let effects = ts::next_tx(&mut scenario, OWNER);
    assert_eq!(ts::num_user_events(&effects), 1);

    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_NOT_PROFILE_OWNER)]
fun test_update_profile_metadata_non_owner_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);

    scenario.next_tx(OWNER);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OTHER);
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let clock = scenario.take_shared<Clock>();

    profiles::update_profile_metadata(
        &mut profile,
        string::utf8(b"name"),
        string::utf8(b"Attacker"),
        &clock,
        ts::ctx(&mut scenario),
    );

    ts::return_to_address(OWNER, profile);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_EMPTY_KEY)]
fun test_update_profile_metadata_empty_key_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);

    scenario.next_tx(OWNER);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let clock = scenario.take_shared<Clock>();

    profiles::update_profile_metadata(
        &mut profile,
        string::utf8(b""),
        string::utf8(b"value"),
        &clock,
        ts::ctx(&mut scenario),
    );

    ts::return_to_address(OWNER, profile);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_EMPTY_VALUE)]
fun test_update_profile_metadata_empty_value_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);

    scenario.next_tx(OWNER);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let clock = scenario.take_shared<Clock>();

    profiles::update_profile_metadata(
        &mut profile,
        string::utf8(b"name"),
        string::utf8(b""),
        &clock,
        ts::ctx(&mut scenario),
    );

    ts::return_to_address(OWNER, profile);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_KEY_TOO_LONG)]
fun test_update_profile_metadata_key_too_long_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);

    scenario.next_tx(OWNER);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let clock = scenario.take_shared<Clock>();

    profiles::update_profile_metadata(
        &mut profile,
        make_ascii_string(65),
        string::utf8(b"value"),
        &clock,
        ts::ctx(&mut scenario),
    );

    ts::return_to_address(OWNER, profile);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_VALUE_TOO_LONG)]
fun test_update_profile_metadata_value_too_long_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);

    scenario.next_tx(OWNER);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let clock = scenario.take_shared<Clock>();

    profiles::update_profile_metadata(
        &mut profile,
        string::utf8(b"name"),
        make_ascii_string(2049),
        &clock,
        ts::ctx(&mut scenario),
    );

    ts::return_to_address(OWNER, profile);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = profiles::E_TOO_MANY_METADATA_ENTRIES)]
fun test_update_profile_metadata_too_many_entries_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(OWNER);

    scenario.next_tx(OWNER);
    let clock_init = scenario.take_shared<Clock>();
    let mut registry = scenario.take_shared<profiles::ProfilesRegistry>();
    profiles::create_profile(&mut registry, &clock_init, ts::ctx(&mut scenario));
    ts::return_shared(registry);
    ts::return_shared(clock_init);
    let _ = ts::next_tx(&mut scenario, OWNER);

    scenario.next_tx(OWNER);
    let mut profile = ts::take_from_address<profiles::Profile>(&scenario, OWNER);
    let clock = scenario.take_shared<Clock>();

    let mut idx = 0;
    while (idx < 100) {
        profiles::update_profile_metadata(
            &mut profile,
            unique_metadata_key(idx),
            string::utf8(b"value"),
            &clock,
            ts::ctx(&mut scenario),
        );
        idx = idx + 1;
    };

    profiles::update_profile_metadata(
        &mut profile,
        unique_metadata_key(100),
        string::utf8(b"value"),
        &clock,
        ts::ctx(&mut scenario),
    );

    ts::return_to_address(OWNER, profile);
    ts::return_shared(clock);
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

fun unique_metadata_key(index: u64): string::String {
    if (index < 64) {
        make_ascii_string(index + 1)
    } else {
        let mut bytes = vector::empty<u8>();
        vector::push_back(&mut bytes, 0x62);
        let mut remaining = index - 64 + 1;
        while (remaining > 0) {
            vector::push_back(&mut bytes, 0x61);
            remaining = remaining - 1;
        };
        string::utf8(bytes)
    }
}

fun make_ascii_string(length: u64): string::String {
    let mut bytes = vector::empty<u8>();
    let mut idx = 0;
    while (idx < length) {
        vector::push_back(&mut bytes, 0x61);
        idx = idx + 1;
    };
    string::utf8(bytes)
}
