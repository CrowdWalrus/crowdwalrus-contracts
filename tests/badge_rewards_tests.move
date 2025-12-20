#[test_only]
module crowd_walrus::badge_rewards_tests;

use crowd_walrus::badge_rewards::{Self as badge_rewards};
use crowd_walrus::crowd_walrus;
use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::profiles::{Self as profiles};
use std::string::{Self as string, String};
use std::unit_test::assert_eq;
use sui::clock::{Self as clock, Clock};
use sui::display;
use sui::event;
use sui::object as sui_object;
use sui::test_scenario::{Self as ts, Scenario, ctx};
use sui::test_utils as tu;
use sui::vec_map::{Self as vec_map};

const ADMIN: address = @0xA;
const OTHER: address = @0xB;

#[test]
fun test_update_badge_config_sets_fields_and_emits_event() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let mut clock = scenario.take_shared<Clock>();
    clock::set_for_testing(&mut clock, 10_000);
    let events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeConfigUpdated>());
    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        vector[
            100_000,
            250_000,
            500_000,
            1_000_000,
            2_000_000,
        ],
        vector[1, 5, 10, 20, 40],
        vector[
            string::utf8(b"walrus://badge1"),
            string::utf8(b"walrus://badge2"),
            string::utf8(b"walrus://badge3"),
            string::utf8(b"walrus://badge4"),
            string::utf8(b"walrus://badge5"),
        ],
        &clock,
    );

    let amounts = badge_rewards::amount_thresholds_micro(&config);
    assert_eq!(vector::length(amounts), badge_rewards::level_count());
    assert_eq!(*vector::borrow(amounts, 0), 100_000);
    assert_eq!(*vector::borrow(amounts, 4), 2_000_000);

    let payments = badge_rewards::payment_thresholds(&config);
    assert_eq!(*vector::borrow(payments, 0), 1);
    assert_eq!(*vector::borrow(payments, 2), 10);
    assert_eq!(*vector::borrow(payments, 4), 40);

    let uris = badge_rewards::image_uris(&config);
    assert_eq!(vector::length(uris), badge_rewards::level_count());
    assert_eq!(*vector::borrow(uris, 2), string::utf8(b"walrus://badge3"));

    let events_after = event::events_by_type<badge_rewards::BadgeConfigUpdated>();
    assert_eq!(vector::length(&events_after), events_before + 1);
    let recorded = vector::borrow(&events_after, events_before);
    assert_eq!(
        badge_rewards::badge_config_updated_amount_thresholds(recorded),
        vector[
            100_000,
            250_000,
            500_000,
            1_000_000,
            2_000_000,
        ],
    );
    assert_eq!(
        badge_rewards::badge_config_updated_payment_thresholds(recorded),
        vector[1, 5, 10, 20, 40],
    );
    assert_eq!(
        badge_rewards::badge_config_updated_image_uris(recorded),
        vector[
            string::utf8(b"walrus://badge1"),
            string::utf8(b"walrus://badge2"),
            string::utf8(b"walrus://badge3"),
            string::utf8(b"walrus://badge4"),
            string::utf8(b"walrus://badge5"),
        ],
    );
    assert_eq!(badge_rewards::badge_config_updated_timestamp_ms(recorded), 10_000);

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);

    let effects = ts::end(scenario);
    assert_eq!(ts::num_user_events(&effects), 1);
}

#[test, expected_failure(
    abort_code = badge_rewards::E_BAD_LENGTH,
    location = 0x0::badge_rewards
)]
fun test_update_badge_config_requires_five_entries() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        vector[100, 200, 300],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"a"),
            string::utf8(b"b"),
            string::utf8(b"c"),
            string::utf8(b"d"),
            string::utf8(b"e"),
        ],
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
    abort 0
}

#[test, expected_failure(
    abort_code = badge_rewards::E_NOT_ASCENDING,
    location = 0x0::badge_rewards
)]
fun test_update_badge_config_amounts_must_increase() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        vector[100, 100, 200, 300, 400],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"a"),
            string::utf8(b"b"),
            string::utf8(b"c"),
            string::utf8(b"d"),
            string::utf8(b"e"),
        ],
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
    abort 0
}

#[test, expected_failure(
    abort_code = badge_rewards::E_NOT_ASCENDING,
    location = 0x0::badge_rewards
)]
fun test_update_badge_config_payments_must_increase() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        vector[100, 200, 300, 400, 500],
        vector[1, 1, 2, 3, 4],
        vector[
            string::utf8(b"a"),
            string::utf8(b"b"),
            string::utf8(b"c"),
            string::utf8(b"d"),
            string::utf8(b"e"),
        ],
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
    abort 0
}

#[test, expected_failure(
    abort_code = badge_rewards::E_EMPTY_URI,
    location = 0x0::badge_rewards
)]
fun test_update_badge_config_requires_non_empty_uris() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        vector[100, 200, 300, 400, 500],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"a"),
            string::utf8(b""),
            string::utf8(b"c"),
            string::utf8(b"d"),
            string::utf8(b"e"),
        ],
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
    abort 0
}

#[test, expected_failure(
    abort_code = crowd_walrus::E_NOT_AUTHORIZED,
    location = 0x0::crowd_walrus
)]
fun test_update_badge_config_requires_matching_admin_cap() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);
    let config_id_opt = ts::most_recent_id_shared<badge_rewards::BadgeConfig>();
    assert!(option::is_some(&config_id_opt));
    let config_id = option::destroy_some(config_id_opt);

    // Create a separate CrowdWalrus deployment and admin cap for OTHER.
    scenario.next_tx(OTHER);
    let other_crowd_id = crowd_walrus::create_and_share_crowd_walrus(ctx(&mut scenario));
    crowd_walrus::create_admin_cap_for_user(other_crowd_id, OTHER, ctx(&mut scenario));

    scenario.next_tx(OTHER);
    let mut config =
        scenario.take_shared_by_id<badge_rewards::BadgeConfig>(config_id);
    let wrong_admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    crowd_walrus::update_badge_config_internal(
        &mut config,
        &wrong_admin_cap,
        vector[100, 200, 300, 400, 500],
        vector[1, 2, 3, 4, 5],
        vector[
            string::utf8(b"a"),
            string::utf8(b"b"),
            string::utf8(b"c"),
            string::utf8(b"d"),
            string::utf8(b"e"),
        ],
        &clock,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(wrong_admin_cap);
    ts::end(scenario);
    abort 0
}

#[test]
fun test_mint_badge_transfers_to_owner_with_fields() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(ADMIN);
    let image_uri = string::utf8(b"walrus://badge1");
    badge_rewards::mint_badge(
        OTHER,
        1,
        &image_uri,
        555,
        ctx(&mut scenario),
    );
    let effects = ts::next_tx(&mut scenario, OTHER);
    assert_eq!(ts::num_user_events(&effects), 0);

    let badge = scenario.take_from_sender<badge_rewards::DonorBadge>();
    assert_eq!(badge_rewards::level(&badge), 1);
    assert_eq!(badge_rewards::owner(&badge), OTHER);
    assert_eq!(*badge_rewards::image_uri(&badge), image_uri);
    assert_eq!(badge_rewards::issued_at_ms(&badge), 555);
    ts::return_to_sender(&scenario, badge);

    ts::end(scenario);
}

#[test, expected_failure(
    abort_code = badge_rewards::E_BAD_BADGE_LEVEL,
    location = 0x0::badge_rewards
)]
fun test_mint_badge_requires_valid_level() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(ADMIN);
    let image_uri = string::utf8(b"walrus://badge1");
    badge_rewards::mint_badge(
        OTHER,
        0,
        &image_uri,
        123,
        ctx(&mut scenario),
    );
    ts::end(scenario);
}

#[test]
fun test_setup_badge_display_registers_templates() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(ADMIN);
    let tx = ctx(&mut scenario);
    let publisher = badge_rewards::test_claim_publisher(tx);
    badge_rewards::setup_badge_display(&publisher, tx);
    publisher.burn();

    let effects = ts::next_tx(&mut scenario, ADMIN);
    assert_eq!(ts::num_user_events(&effects), 2);

    let display_obj = scenario.take_shared<display::Display<badge_rewards::DonorBadge>>();
    let fields = display::fields(&display_obj);
    assert_eq!(vec_map::length(fields), 4);
    let name_key = string::utf8(b"name");
    let image_key = string::utf8(b"image_url");
    let description_key = string::utf8(b"description");
    let link_key = string::utf8(b"link");
    let expected_name = string::utf8(b"Crowd Walrus Donor Badge Level {level}");
    let expected_image = string::utf8(b"{image_uri}");
    let expected_description = string::utf8(
        b"Rewarded to {owner} for reaching badge level {level}. Issued at {issued_at_ms} ms.",
    );
    let expected_link =
        string::utf8(b"https://crowdwalrus.xyz/profile/{owner}");
    assert_eq!(*vec_map::get(fields, &name_key), expected_name);
    assert_eq!(*vec_map::get(fields, &image_key), expected_image);
    assert_eq!(*vec_map::get(fields, &description_key), expected_description);
    assert_eq!(*vec_map::get(fields, &link_key), expected_link);
    ts::return_shared(display_obj);

    ts::end(scenario);
}

#[test]
fun test_update_badge_display_bumps_version_and_updates_templates() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(ADMIN);
    let tx = ctx(&mut scenario);
    let publisher = badge_rewards::test_claim_publisher(tx);
    badge_rewards::setup_badge_display(&publisher, tx);
    publisher.burn();
    let _ = ts::next_tx(&mut scenario, ADMIN);

    scenario.next_tx(ADMIN);
    let mut display_obj =
        scenario.take_shared<display::Display<badge_rewards::DonorBadge>>();
    let mut clock_obj = scenario.take_shared<Clock>();
    clock::set_for_testing(&mut clock_obj, 25_000);
    let tx_update = ctx(&mut scenario);
    let publisher = badge_rewards::test_claim_publisher(tx_update);

    let version_events_before = vector::length(
        &event::events_by_type<display::VersionUpdated<badge_rewards::DonorBadge>>(),
    );

    badge_rewards::update_badge_display(
        &publisher,
        &mut display_obj,
        vector[
            string::utf8(b"name"),
            string::utf8(b"description"),
            string::utf8(b"image_url"),
        ],
        vector[
            string::utf8(b"Crowd Walrus Badge LVL {level}"),
            string::utf8(b"Updated for {owner}"),
            string::utf8(b"https://cdn.crowdwalrus.app/badges/{level}.png"),
        ],
        string::utf8(b"https://staging.crowdwalrus.app"),
        &clock_obj,
        tx_update,
    );

    let version_events_after =
        event::events_by_type<display::VersionUpdated<badge_rewards::DonorBadge>>();
    assert_eq!(
        vector::length(&version_events_after),
        version_events_before + 1,
    );

    let display_events = event::events_by_type<badge_rewards::BadgeDisplayUpdated>();
    let last_display_event =
        vector::borrow(&display_events, vector::length(&display_events) - 1);
    let expected_link =
        string::utf8(b"https://staging.crowdwalrus.app/profile/{owner}");
    assert_eq!(
        badge_rewards::badge_display_updated_deep_link_template(last_display_event),
        expected_link,
    );

    let fields = display::fields(&display_obj);
    let name_key = string::utf8(b"name");
    let image_key = string::utf8(b"image_url");
    let description_key = string::utf8(b"description");
    let link_key = string::utf8(b"link");
    assert_eq!(
        *vec_map::get(fields, &name_key),
        string::utf8(b"Crowd Walrus Badge LVL {level}"),
    );
    assert_eq!(
        *vec_map::get(fields, &image_key),
        string::utf8(b"https://cdn.crowdwalrus.app/badges/{level}.png"),
    );
    assert_eq!(
        *vec_map::get(fields, &description_key),
        string::utf8(b"Updated for {owner}"),
    );
    assert_eq!(*vec_map::get(fields, &link_key), expected_link);

    ts::return_shared(clock_obj);
    ts::return_shared(display_obj);
    publisher.burn();

    let effects = ts::next_tx(&mut scenario, ADMIN);
    assert_eq!(ts::num_user_events(&effects), 2);

    ts::end(scenario);
}

#[test]
fun test_update_badge_display_with_admin_cap() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(ADMIN);
    let tx = ctx(&mut scenario);
    let publisher = badge_rewards::test_claim_publisher(tx);
    badge_rewards::setup_badge_display(&publisher, tx);
    publisher.burn();
    let _ = ts::next_tx(&mut scenario, ADMIN);

    scenario.next_tx(ADMIN);
    let mut display_obj =
        scenario.take_shared<display::Display<badge_rewards::DonorBadge>>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let crowd_walrus_id = crowd_walrus::admin_cap_crowd_walrus_id(&admin_cap);
    let mut clock_obj = scenario.take_shared<Clock>();
    clock::set_for_testing(&mut clock_obj, 33_333);

    let version_events_before = vector::length(
        &event::events_by_type<display::VersionUpdated<badge_rewards::DonorBadge>>(),
    );

    crowd_walrus::update_badge_display_with_admin(
        &mut display_obj,
        &admin_cap,
        crowd_walrus_id,
        vector[
            string::utf8(b"name"),
        ],
        vector[
            string::utf8(b"Reissued {level}"),
        ],
        string::utf8(b"https://app.crowdwalrus.com"),
        &clock_obj,
        ctx(&mut scenario),
    );

    let version_events_after =
        event::events_by_type<display::VersionUpdated<badge_rewards::DonorBadge>>();
    assert_eq!(
        vector::length(&version_events_after),
        version_events_before + 1,
    );

    let link_key = string::utf8(b"link");
    let name_key = string::utf8(b"name");
    let fields = display::fields(&display_obj);
    assert_eq!(
        *vec_map::get(fields, &link_key),
        string::utf8(b"https://app.crowdwalrus.com/profile/{owner}"),
    );
    assert_eq!(
        *vec_map::get(fields, &name_key),
        string::utf8(b"Reissued {level}"),
    );

    let display_events = event::events_by_type<badge_rewards::BadgeDisplayUpdated>();
    let last_display_event =
        vector::borrow(&display_events, vector::length(&display_events) - 1);
    assert_eq!(
        badge_rewards::badge_display_updated_timestamp_ms(last_display_event),
        33_333,
    );

    ts::return_shared(clock_obj);
    ts::return_shared(display_obj);
    scenario.return_to_sender(admin_cap);

    let effects = ts::next_tx(&mut scenario, ADMIN);
    assert_eq!(ts::num_user_events(&effects), 2);

    ts::end(scenario);
}

#[test]
fun test_remove_badge_display_keys() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(ADMIN);
    let tx = ctx(&mut scenario);
    let publisher = badge_rewards::test_claim_publisher(tx);
    badge_rewards::setup_badge_display(&publisher, tx);
    publisher.burn();
    let _ = ts::next_tx(&mut scenario, ADMIN);

    scenario.next_tx(ADMIN);
    let mut display_obj =
        scenario.take_shared<display::Display<badge_rewards::DonorBadge>>();
    let mut clock_obj = scenario.take_shared<Clock>();
    clock::set_for_testing(&mut clock_obj, 44_444);
    let tx_update = ctx(&mut scenario);
    let publisher = badge_rewards::test_claim_publisher(tx_update);

    let version_before =
        vector::length(&event::events_by_type<display::VersionUpdated<badge_rewards::DonorBadge>>());

    badge_rewards::remove_badge_display_keys(
        &publisher,
        &mut display_obj,
        vector[string::utf8(b"description")],
        string::utf8(b"https://crowdwalrus.xyz"),
        &clock_obj,
        tx_update,
    );

    let fields = display::fields(&display_obj);
    let description_key = string::utf8(b"description");
    assert!(!vec_map::contains(fields, &description_key));
    let link_key = string::utf8(b"link");
    assert_eq!(
        *vec_map::get(fields, &link_key),
        string::utf8(b"https://crowdwalrus.xyz/profile/{owner}"),
    );

    let version_events_after =
        event::events_by_type<display::VersionUpdated<badge_rewards::DonorBadge>>();
    assert_eq!(
        vector::length(&version_events_after),
        version_before + 1,
    );

    let display_events = event::events_by_type<badge_rewards::BadgeDisplayUpdated>();
    let last_display_event =
        vector::borrow(&display_events, vector::length(&display_events) - 1);
    assert_eq!(
        badge_rewards::badge_display_updated_deep_link_template(last_display_event),
        string::utf8(b"https://crowdwalrus.xyz/profile/{owner}"),
    );

    ts::return_shared(clock_obj);
    ts::return_shared(display_obj);
    publisher.burn();

    let effects = ts::next_tx(&mut scenario, ADMIN);
    assert_eq!(ts::num_user_events(&effects), 2);

    ts::end(scenario);
}

#[test]
fun test_remove_then_restore_badge_display_field_with_publisher() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    // Set up initial display
    scenario.next_tx(ADMIN);
    let tx_setup = ctx(&mut scenario);
    let publisher_setup = badge_rewards::test_claim_publisher(tx_setup);
    badge_rewards::setup_badge_display(&publisher_setup, tx_setup);
    publisher_setup.burn();
    let _ = ts::next_tx(&mut scenario, ADMIN);

    // Remove description
    scenario.next_tx(ADMIN);
    let mut display_obj =
        scenario.take_shared<display::Display<badge_rewards::DonorBadge>>();
    let mut clock_obj = scenario.take_shared<Clock>();
    clock::set_for_testing(&mut clock_obj, 50_000);
    let tx_remove = ctx(&mut scenario);
    let publisher_remove = badge_rewards::test_claim_publisher(tx_remove);

    badge_rewards::remove_badge_display_keys(
        &publisher_remove,
        &mut display_obj,
        vector[string::utf8(b"description")],
        string::utf8(b"https://crowdwalrus.xyz"),
        &clock_obj,
        tx_remove,
    );

    let fields_after_remove = display::fields(&display_obj);
    let description_key = string::utf8(b"description");
    assert!(!vec_map::contains(fields_after_remove, &description_key));
    publisher_remove.burn();

    let version_events_remove =
        event::events_by_type<display::VersionUpdated<badge_rewards::DonorBadge>>();
    assert_eq!(vector::length(&version_events_remove), 1);

    ts::return_shared(clock_obj);
    ts::return_shared(display_obj);
    let _ = ts::next_tx(&mut scenario, ADMIN);

    // Restore description via update
    scenario.next_tx(ADMIN);
    let mut display_obj_restore =
        scenario.take_shared<display::Display<badge_rewards::DonorBadge>>();
    let mut clock_restore = scenario.take_shared<Clock>();
    clock::set_for_testing(&mut clock_restore, 55_000);
    let tx_update = ctx(&mut scenario);
    let publisher_update = badge_rewards::test_claim_publisher(tx_update);

    badge_rewards::update_badge_display(
        &publisher_update,
        &mut display_obj_restore,
        vector[string::utf8(b"description")],
        vector[string::utf8(b"Restored description {owner}")],
        string::utf8(b"https://crowdwalrus.xyz"),
        &clock_restore,
        tx_update,
    );

    let fields_after_update = display::fields(&display_obj_restore);
    assert_eq!(
        *vec_map::get(fields_after_update, &description_key),
        string::utf8(b"Restored description {owner}"),
    );

    let version_events_final =
        event::events_by_type<display::VersionUpdated<badge_rewards::DonorBadge>>();
    assert_eq!(vector::length(&version_events_final), 1);

    ts::return_shared(clock_restore);
    ts::return_shared(display_obj_restore);
    publisher_update.burn();

    let effects = ts::next_tx(&mut scenario, ADMIN);
    assert_eq!(ts::num_user_events(&effects), 2);

    ts::end(scenario);
}

#[test]
fun test_maybe_award_badges_require_both_thresholds() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);
    update_badge_config_for_tests(&mut scenario);

    scenario.next_tx(OTHER);
    let mut profile_amount_only = profiles::create(
        OTHER,
        vector::empty(),
        vector::empty(),
        ctx(&mut scenario),
    );
    profiles::grant_badge_level(&mut profile_amount_only, 1);
    profiles::grant_badge_level(&mut profile_amount_only, 2);
    let clock_amount = scenario.take_shared<Clock>();
    let config_amount = scenario.take_shared<badge_rewards::BadgeConfig>();
    let minted_amount = badge_rewards::maybe_award_badges(
        &mut profile_amount_only,
        &config_amount,
        550_000,
        3,
        650_000,
        4,
        &clock_amount,
        ctx(&mut scenario),
    );
    assert_eq!(vector::length(&minted_amount), 0);
    assert!(!profiles::has_badge_level(&profile_amount_only, 3));
    ts::return_shared(clock_amount);
    ts::return_shared(config_amount);
    tu::destroy(profile_amount_only);
    let _ = ts::next_tx(&mut scenario, OTHER);

    scenario.next_tx(OTHER);
    let mut profile_payment_only = profiles::create(
        OTHER,
        vector::empty(),
        vector::empty(),
        ctx(&mut scenario),
    );
    profiles::grant_badge_level(&mut profile_payment_only, 1);
    profiles::grant_badge_level(&mut profile_payment_only, 2);
    let clock_payment = scenario.take_shared<Clock>();
    let config_payment = scenario.take_shared<badge_rewards::BadgeConfig>();
    let minted_payment = badge_rewards::maybe_award_badges(
        &mut profile_payment_only,
        &config_payment,
        550_000,
        4,
        590_000,
        5,
        &clock_payment,
        ctx(&mut scenario),
    );
    assert_eq!(vector::length(&minted_payment), 0);
    assert!(!profiles::has_badge_level(&profile_payment_only, 3));
    ts::return_shared(clock_payment);
    ts::return_shared(config_payment);
    tu::destroy(profile_payment_only);
    let _ = ts::next_tx(&mut scenario, OTHER);

    ts::end(scenario);
}

#[test]
fun test_maybe_award_badges_awards_levels_and_is_idempotent() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);
    update_badge_config_for_tests(&mut scenario);

    scenario.next_tx(OTHER);
    let mut profile = profiles::create(
        OTHER,
        vector::empty(),
        vector::empty(),
        ctx(&mut scenario),
    );
    let mut clock = scenario.take_shared<Clock>();
    let config = scenario.take_shared<badge_rewards::BadgeConfig>();
    clock::set_for_testing(&mut clock, 12_000);
    let minted_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());

    let minted = badge_rewards::maybe_award_badges(
        &mut profile,
        &config,
        0,
        0,
        600_000,
        5,
        &clock,
        ctx(&mut scenario),
    );
    assert_eq!(vector::length(&minted), 3);
    assert_eq!(*vector::borrow(&minted, 0), 1);
    assert_eq!(*vector::borrow(&minted, 1), 2);
    assert_eq!(*vector::borrow(&minted, 2), 3);
    assert!(profiles::has_badge_level(&profile, 1));
    assert!(profiles::has_badge_level(&profile, 2));
    assert!(profiles::has_badge_level(&profile, 3));
    assert!(!profiles::has_badge_level(&profile, 4));

    let profile_id = sui_object::id(&profile);
    let minted_events = event::events_by_type<badge_rewards::BadgeMinted>();
    assert_eq!(vector::length(&minted_events), minted_events_before + 3);
    let event_first = vector::borrow(&minted_events, minted_events_before);
    assert_eq!(badge_rewards::badge_minted_owner(event_first), OTHER);
    assert_eq!(badge_rewards::badge_minted_level(event_first), 1);
    assert_eq!(badge_rewards::badge_minted_profile_id(event_first), profile_id);
    assert_eq!(badge_rewards::badge_minted_timestamp_ms(event_first), 12_000);

    let event_second = vector::borrow(&minted_events, minted_events_before + 1);
    assert_eq!(badge_rewards::badge_minted_owner(event_second), OTHER);
    assert_eq!(badge_rewards::badge_minted_level(event_second), 2);
    assert_eq!(badge_rewards::badge_minted_profile_id(event_second), profile_id);
    assert_eq!(badge_rewards::badge_minted_timestamp_ms(event_second), 12_000);

    let event_third = vector::borrow(&minted_events, minted_events_before + 2);
    assert_eq!(badge_rewards::badge_minted_owner(event_third), OTHER);
    assert_eq!(badge_rewards::badge_minted_level(event_third), 3);
    assert_eq!(badge_rewards::badge_minted_profile_id(event_third), profile_id);
    assert_eq!(badge_rewards::badge_minted_timestamp_ms(event_third), 12_000);

    let minted_again = badge_rewards::maybe_award_badges(
        &mut profile,
        &config,
        600_000,
        5,
        600_000,
        5,
        &clock,
        ctx(&mut scenario),
    );
    assert_eq!(vector::length(&minted_again), 0);

    let minted_events_after_second =
        event::events_by_type<badge_rewards::BadgeMinted>();
    assert_eq!(
        vector::length(&minted_events_after_second),
        minted_events_before + 3,
    );

    ts::return_shared(clock);
    ts::return_shared(config);
    tu::destroy(profile);

    let effects = ts::next_tx(&mut scenario, OTHER);
    assert_eq!(ts::num_user_events(&effects), 3);

    ts::end(scenario);
}

#[test]
fun test_maybe_award_badges_awards_first_level() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);
    update_badge_config_for_tests(&mut scenario);

    scenario.next_tx(OTHER);
    let mut profile = profiles::create(
        OTHER,
        vector::empty(),
        vector::empty(),
        ctx(&mut scenario),
    );
    let mut clock = scenario.take_shared<Clock>();
    let config = scenario.take_shared<badge_rewards::BadgeConfig>();
    clock::set_for_testing(&mut clock, 13_000);
    let minted_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());

    let minted = badge_rewards::maybe_award_badges(
        &mut profile,
        &config,
        0,
        0,
        100_000,
        1,
        &clock,
        ctx(&mut scenario),
    );
    assert_eq!(vector::length(&minted), 1);
    assert_eq!(*vector::borrow(&minted, 0), 1);
    assert!(profiles::has_badge_level(&profile, 1));

    let profile_id = sui_object::id(&profile);
    let minted_events = event::events_by_type<badge_rewards::BadgeMinted>();
    assert_eq!(vector::length(&minted_events), minted_events_before + 1);
    let recorded = vector::borrow(&minted_events, minted_events_before);
    assert_eq!(badge_rewards::badge_minted_owner(recorded), OTHER);
    assert_eq!(badge_rewards::badge_minted_level(recorded), 1);
    assert_eq!(badge_rewards::badge_minted_profile_id(recorded), profile_id);
    assert_eq!(badge_rewards::badge_minted_timestamp_ms(recorded), 13_000);

    ts::return_shared(clock);
    ts::return_shared(config);
    tu::destroy(profile);

    let effects = ts::next_tx(&mut scenario, OTHER);
    assert_eq!(ts::num_user_events(&effects), 1);

    ts::end(scenario);
}

#[test]
fun test_maybe_award_badges_large_amount_single_payment_only_level_one() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);
    update_badge_config_for_tests(&mut scenario);

    scenario.next_tx(OTHER);
    let mut profile = profiles::create(
        OTHER,
        vector::empty(),
        vector::empty(),
        ctx(&mut scenario),
    );
    let mut clock = scenario.take_shared<Clock>();
    let config = scenario.take_shared<badge_rewards::BadgeConfig>();
    clock::set_for_testing(&mut clock, 14_000);
    let minted_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());

    let minted = badge_rewards::maybe_award_badges(
        &mut profile,
        &config,
        0,
        0,
        600_000,
        1,
        &clock,
        ctx(&mut scenario),
    );
    assert_eq!(vector::length(&minted), 1);
    assert_eq!(*vector::borrow(&minted, 0), 1);
    assert!(profiles::has_badge_level(&profile, 1));
    assert!(!profiles::has_badge_level(&profile, 2));
    assert!(!profiles::has_badge_level(&profile, 3));

    let profile_id = sui_object::id(&profile);
    let minted_events = event::events_by_type<badge_rewards::BadgeMinted>();
    assert_eq!(vector::length(&minted_events), minted_events_before + 1);
    let recorded = vector::borrow(&minted_events, minted_events_before);
    assert_eq!(badge_rewards::badge_minted_owner(recorded), OTHER);
    assert_eq!(badge_rewards::badge_minted_level(recorded), 1);
    assert_eq!(badge_rewards::badge_minted_profile_id(recorded), profile_id);
    assert_eq!(badge_rewards::badge_minted_timestamp_ms(recorded), 14_000);

    ts::return_shared(clock);
    ts::return_shared(config);
    tu::destroy(profile);

    let effects = ts::next_tx(&mut scenario, OTHER);
    assert_eq!(ts::num_user_events(&effects), 1);

    ts::end(scenario);
}

#[test]
fun test_maybe_award_badges_payment_only_no_award() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);
    update_badge_config_for_tests(&mut scenario);

    scenario.next_tx(OTHER);
    let mut profile = profiles::create(
        OTHER,
        vector::empty(),
        vector::empty(),
        ctx(&mut scenario),
    );
    let mut clock = scenario.take_shared<Clock>();
    let config = scenario.take_shared<badge_rewards::BadgeConfig>();
    clock::set_for_testing(&mut clock, 14_500);
    let minted_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());

    let minted = badge_rewards::maybe_award_badges(
        &mut profile,
        &config,
        0,
        0,
        90_000,
        5,
        &clock,
        ctx(&mut scenario),
    );
    assert_eq!(vector::length(&minted), 0);
    assert!(!profiles::has_badge_level(&profile, 1));

    let minted_events = event::events_by_type<badge_rewards::BadgeMinted>();
    assert_eq!(vector::length(&minted_events), minted_events_before);

    ts::return_shared(clock);
    ts::return_shared(config);
    tu::destroy(profile);

    let effects = ts::next_tx(&mut scenario, OTHER);
    assert_eq!(ts::num_user_events(&effects), 0);

    ts::end(scenario);
}

#[test]
fun test_maybe_award_badges_unconfigured_returns_empty() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);

    scenario.next_tx(OTHER);
    let mut profile = profiles::create(
        OTHER,
        vector::empty(),
        vector::empty(),
        ctx(&mut scenario),
    );
    let clock = scenario.take_shared<Clock>();
    let config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let minted_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());

    let minted = badge_rewards::maybe_award_badges(
        &mut profile,
        &config,
        0,
        0,
        500_000,
        5,
        &clock,
        ctx(&mut scenario),
    );
    assert_eq!(vector::length(&minted), 0);
    assert!(!profiles::has_badge_level(&profile, 1));

    let minted_events_after =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());
    assert_eq!(minted_events_after, minted_events_before);

    ts::return_shared(clock);
    ts::return_shared(config);
    tu::destroy(profile);

    let effects = ts::next_tx(&mut scenario, OTHER);
    assert_eq!(ts::num_user_events(&effects), 0);

    ts::end(scenario);
}

#[test]
fun test_maybe_award_badges_boundary_equality_awards() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);
    update_badge_config_for_tests(&mut scenario);

    scenario.next_tx(OTHER);
    let mut profile = profiles::create(
        OTHER,
        vector::empty(),
        vector::empty(),
        ctx(&mut scenario),
    );
    let mut clock = scenario.take_shared<Clock>();
    let config = scenario.take_shared<badge_rewards::BadgeConfig>();
    clock::set_for_testing(&mut clock, 14_500);
    let minted_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());

    let minted = badge_rewards::maybe_award_badges(
        &mut profile,
        &config,
        90_000,
        2,
        100_000,
        3,
        &clock,
        ctx(&mut scenario),
    );
    assert_eq!(vector::length(&minted), 1);
    assert_eq!(*vector::borrow(&minted, 0), 1);
    assert!(profiles::has_badge_level(&profile, 1));

    let profile_id = sui_object::id(&profile);
    let minted_events = event::events_by_type<badge_rewards::BadgeMinted>();
    assert_eq!(vector::length(&minted_events), minted_events_before + 1);
    let recorded = vector::borrow(&minted_events, minted_events_before);
    assert_eq!(badge_rewards::badge_minted_owner(recorded), OTHER);
    assert_eq!(badge_rewards::badge_minted_level(recorded), 1);
    assert_eq!(badge_rewards::badge_minted_profile_id(recorded), profile_id);
    assert_eq!(badge_rewards::badge_minted_timestamp_ms(recorded), 14_500);

    ts::return_shared(clock);
    ts::return_shared(config);
    tu::destroy(profile);

    let effects = ts::next_tx(&mut scenario, OTHER);
    assert_eq!(ts::num_user_events(&effects), 1);

    ts::end(scenario);
}

#[test]
fun test_maybe_award_badges_progression_from_level_one_to_three() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    bootstrap_badge_config(&mut scenario);
    update_badge_config_for_tests(&mut scenario);

    scenario.next_tx(OTHER);
    let mut profile = profiles::create(
        OTHER,
        vector::empty(),
        vector::empty(),
        ctx(&mut scenario),
    );
    profiles::grant_badge_level(&mut profile, 1);
    let mut clock = scenario.take_shared<Clock>();
    let config = scenario.take_shared<badge_rewards::BadgeConfig>();
    clock::set_for_testing(&mut clock, 15_000);
    let minted_events_before =
        vector::length(&event::events_by_type<badge_rewards::BadgeMinted>());

    let minted = badge_rewards::maybe_award_badges(
        &mut profile,
        &config,
        150_000,
        3,
        650_000,
        5,
        &clock,
        ctx(&mut scenario),
    );
    assert_eq!(vector::length(&minted), 2);
    assert_eq!(*vector::borrow(&minted, 0), 2);
    assert_eq!(*vector::borrow(&minted, 1), 3);
    assert!(profiles::has_badge_level(&profile, 2));
    assert!(profiles::has_badge_level(&profile, 3));

    let profile_id = sui_object::id(&profile);
    let minted_events = event::events_by_type<badge_rewards::BadgeMinted>();
    assert_eq!(vector::length(&minted_events), minted_events_before + 2);
    let level_two_event = vector::borrow(&minted_events, minted_events_before);
    assert_eq!(badge_rewards::badge_minted_owner(level_two_event), OTHER);
    assert_eq!(badge_rewards::badge_minted_level(level_two_event), 2);
    assert_eq!(badge_rewards::badge_minted_profile_id(level_two_event), profile_id);
    assert_eq!(badge_rewards::badge_minted_timestamp_ms(level_two_event), 15_000);

    let level_three_event = vector::borrow(&minted_events, minted_events_before + 1);
    assert_eq!(badge_rewards::badge_minted_owner(level_three_event), OTHER);
    assert_eq!(badge_rewards::badge_minted_level(level_three_event), 3);
    assert_eq!(
        badge_rewards::badge_minted_profile_id(level_three_event),
        profile_id,
    );
    assert_eq!(badge_rewards::badge_minted_timestamp_ms(level_three_event), 15_000);

    ts::return_shared(clock);
    ts::return_shared(config);
    tu::destroy(profile);

    let effects = ts::next_tx(&mut scenario, OTHER);
    assert_eq!(ts::num_user_events(&effects), 2);

    ts::end(scenario);
}

fun bootstrap_badge_config(scenario: &mut Scenario) {
    scenario.next_tx(ADMIN);
    let crowd = scenario.take_shared<crowd_walrus::CrowdWalrus>();
    let config = badge_rewards::create_config_for_tests(
        sui_object::id(&crowd),
        ctx(scenario),
    );
    badge_rewards::share_config(config);
    ts::return_shared(crowd);
}

fun update_badge_config_for_tests(scenario: &mut Scenario) {
    scenario.next_tx(ADMIN);
    let mut config = scenario.take_shared<badge_rewards::BadgeConfig>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();
    let (amounts, payments, uris) = default_badge_thresholds();
    crowd_walrus::update_badge_config_internal(
        &mut config,
        &admin_cap,
        amounts,
        payments,
        uris,
        &clock,
    );
    ts::return_shared(clock);
    ts::return_shared(config);
    scenario.return_to_sender(admin_cap);
}

fun default_badge_thresholds(): (
    vector<u64>,
    vector<u64>,
    vector<String>,
) {
    (
        vector[
            100_000,
            300_000,
            600_000,
            1_200_000,
            2_400_000,
        ],
        vector[1, 3, 5, 7, 9],
        vector[
            string::utf8(b"walrus://badge1"),
            string::utf8(b"walrus://badge2"),
            string::utf8(b"walrus://badge3"),
            string::utf8(b"walrus://badge4"),
            string::utf8(b"walrus://badge5"),
        ],
    )
}
