module crowd_walrus::badge_rewards;

use crowd_walrus::profiles::{Self as profiles};
use std::string::{Self as string, String};
use sui::vec_map;
use sui::clock::{Self as clock, Clock};
use sui::display;
use sui::event;
use sui::object::{Self as sui_object};
use sui::package::{Self as package, Publisher};
use sui::tx_context::{Self as tx_ctx};

const LEVEL_COUNT: u64 = 5;
const MAX_LEVEL: u8 = 5;

const E_BAD_LENGTH: u64 = 1;
const E_NOT_ASCENDING: u64 = 2;
const E_EMPTY_URI: u64 = 3;
const E_BAD_BADGE_LEVEL: u64 = 4;
const E_INVALID_TOTALS: u64 = 5;
const E_INVALID_PUBLISHER: u64 = 6;
const E_BAD_DISPLAY_LENGTH: u64 = 7;

const BADGE_DEEP_LINK_BASE_DEFAULT: vector<u8> = b"https://crowdwalrus.xyz";
const BADGE_DEEP_LINK_SUFFIX: vector<u8> = b"/profile/{owner}";

public struct BadgeConfig has key {
    id: sui_object::UID,
    crowd_walrus_id: sui_object::ID,
    amount_thresholds_micro: vector<u64>,
    payment_thresholds: vector<u64>,
    image_uris: vector<String>,
}

/// Owned badge object; no transfer API (non-transferable), so stored `owner`
/// stays aligned with the object's actual owner on-chain.
public struct DonorBadge has key {
    id: sui_object::UID,
    level: u8,
    owner: address,
    image_uri: String,
    issued_at_ms: u64,
}

#[test_only]
public struct TestPublisherOTW has drop {}

public struct BadgeConfigUpdated has copy, drop {
    amount_thresholds_micro: vector<u64>,
    payment_thresholds: vector<u64>,
    image_uris: vector<String>,
    timestamp_ms: u64,
}

public struct BadgeMinted has copy, drop {
    owner: address,
    level: u8,
    profile_id: sui_object::ID,
    timestamp_ms: u64,
}

public struct BadgeDisplayUpdated has copy, drop {
    keys: vector<String>,
    deep_link_template: String,
    timestamp_ms: u64,
}

public fun badge_config_updated_amount_thresholds(event: &BadgeConfigUpdated): vector<u64> {
    clone_u64_vector(&event.amount_thresholds_micro)
}

public fun badge_config_updated_payment_thresholds(event: &BadgeConfigUpdated): vector<u64> {
    clone_u64_vector(&event.payment_thresholds)
}

public fun badge_config_updated_image_uris(event: &BadgeConfigUpdated): vector<String> {
    clone_string_vector(&event.image_uris)
}

public fun badge_config_updated_timestamp_ms(event: &BadgeConfigUpdated): u64 {
    event.timestamp_ms
}

public fun badge_minted_owner(event: &BadgeMinted): address {
    event.owner
}

public fun badge_minted_level(event: &BadgeMinted): u8 {
    event.level
}

public fun badge_minted_profile_id(event: &BadgeMinted): sui_object::ID {
    event.profile_id
}

public fun badge_minted_timestamp_ms(event: &BadgeMinted): u64 {
    event.timestamp_ms
}

public fun badge_display_updated_keys(event: &BadgeDisplayUpdated): vector<String> {
    clone_string_vector(&event.keys)
}

public fun badge_display_updated_deep_link_template(event: &BadgeDisplayUpdated): String {
    clone_string(&event.deep_link_template)
}

public fun badge_display_updated_timestamp_ms(event: &BadgeDisplayUpdated): u64 {
    event.timestamp_ms
}

public(package) fun create_config(
    crowd_walrus_id: sui_object::ID,
    ctx: &mut tx_ctx::TxContext,
): BadgeConfig {
    BadgeConfig {
        id: sui_object::new(ctx),
        crowd_walrus_id,
        amount_thresholds_micro: vector::empty<u64>(),
        payment_thresholds: vector::empty<u64>(),
        image_uris: vector::empty<String>(),
    }
}

public(package) fun share_config(config: BadgeConfig) {
    sui::transfer::share_object(config);
}

public fun crowd_walrus_id(config: &BadgeConfig): sui_object::ID {
    config.crowd_walrus_id
}

public fun amount_thresholds_micro(config: &BadgeConfig): &vector<u64> {
    &config.amount_thresholds_micro
}

public fun payment_thresholds(config: &BadgeConfig): &vector<u64> {
    &config.payment_thresholds
}

public fun image_uris(config: &BadgeConfig): &vector<String> {
    &config.image_uris
}

public fun level(badge: &DonorBadge): u8 {
    badge.level
}

public fun owner(badge: &DonorBadge): address {
    badge.owner
}

public fun image_uri(badge: &DonorBadge): &String {
    &badge.image_uri
}

public fun issued_at_ms(badge: &DonorBadge): u64 {
    badge.issued_at_ms
}

public fun level_count(): u64 {
    LEVEL_COUNT
}

public fun is_configured(config: &BadgeConfig): bool {
    vector::length(amount_thresholds_micro(config)) == LEVEL_COUNT &&
        vector::length(payment_thresholds(config)) == LEVEL_COUNT &&
        vector::length(image_uris(config)) == LEVEL_COUNT
}

public(package) fun set_config(
    config: &mut BadgeConfig,
    amount_thresholds_micro: vector<u64>,
    payment_thresholds: vector<u64>,
    image_uris: vector<String>,
    clock: &Clock,
) {
    validate_inputs(&amount_thresholds_micro, &payment_thresholds, &image_uris);

    let event_amount_thresholds = clone_u64_vector(&amount_thresholds_micro);
    let event_payment_thresholds = clone_u64_vector(&payment_thresholds);
    let event_image_uris = clone_string_vector(&image_uris);

    config.amount_thresholds_micro = amount_thresholds_micro;
    config.payment_thresholds = payment_thresholds;
    config.image_uris = image_uris;

    event::emit(BadgeConfigUpdated {
        amount_thresholds_micro: event_amount_thresholds,
        payment_thresholds: event_payment_thresholds,
        image_uris: event_image_uris,
        timestamp_ms: clock::timestamp_ms(clock),
    });
}

#[test_only]
public fun create_config_for_tests(
    crowd_walrus_id: sui_object::ID,
    ctx: &mut tx_ctx::TxContext,
): BadgeConfig {
    create_config(crowd_walrus_id, ctx)
}

public(package) fun mint_badge(
    owner: address,
    level: u8,
    image_uri: &String,
    issued_at_ms: u64,
    ctx: &mut tx_ctx::TxContext,
) {
    assert_valid_level(level);
    let badge = DonorBadge {
        id: sui_object::new(ctx),
        level,
        owner,
        image_uri: clone_string(image_uri),
        issued_at_ms,
    };
    sui::transfer::transfer(badge, owner);
}

/// Evaluates badge thresholds against profile totals, awarding badges for levels that newly satisfy
/// both the amount and donation-count requirements. This guards against “whale” spikes or spammy
/// micro-donations earning badges on only one axis. Returns newly minted levels in ascending order
/// so UIs can render them deterministically.
public(package) fun maybe_award_badges(
    profile: &mut profiles::Profile,
    config: &BadgeConfig,
    old_amount: u64,
    old_count: u64,
    new_amount: u64,
    new_count: u64,
    clock: &Clock,
    ctx: &mut tx_ctx::TxContext,
): vector<u8> {
    assert!(new_amount >= old_amount, E_INVALID_TOTALS);
    assert!(new_count >= old_count, E_INVALID_TOTALS);

    if (!is_configured(config)) {
        return vector::empty<u8>()
    };

    let amount_thresholds = amount_thresholds_micro(config);
    let payment_thresholds = payment_thresholds(config);
    let image_uris = image_uris(config);
    let owner = profiles::owner(profile);
    let profile_id = sui_object::id(profile);
    let timestamp_ms = clock::timestamp_ms(clock);

    let mut minted_levels = vector::empty<u8>();

    let mut idx = 0;
    while (idx < LEVEL_COUNT) {
        let level = (idx as u8) + 1;

        if (!profiles::has_badge_level(profile, level)) {
            let amount_threshold = *vector::borrow(amount_thresholds, idx);
            let payment_threshold = *vector::borrow(payment_thresholds, idx);

            let is_eligible_now =
                new_amount >= amount_threshold && new_count >= payment_threshold;
            let was_eligible_before =
                old_amount >= amount_threshold && old_count >= payment_threshold;

            if (is_eligible_now && !was_eligible_before) {
                let image_uri = vector::borrow(image_uris, idx);
                mint_badge(owner, level, image_uri, timestamp_ms, ctx);
                event::emit(BadgeMinted {
                    owner,
                    level,
                    profile_id,
                    timestamp_ms,
                });
                profiles::grant_badge_level(profile, level);
                vector::push_back(&mut minted_levels, level);
            };
        };

        idx = idx + 1;
    };

    minted_levels
}

#[test_only]
public fun test_claim_publisher(ctx: &mut tx_ctx::TxContext): Publisher {
    sui::package::test_claim(TestPublisherOTW {}, ctx)
}

#[allow(lint(share_owned))]
entry fun setup_badge_display(pub: &Publisher, ctx: &mut tx_ctx::TxContext) {
    let mut display = display::new_with_fields<DonorBadge>(
        pub,
        vector[
            string::utf8(b"name"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"link"),
        ],
        vector[
            string::utf8(b"Crowd Walrus Donor Badge Level {level}"),
            string::utf8(b"{image_uri}"),
            string::utf8(b"Rewarded to {owner} for reaching badge level {level}. Issued at {issued_at_ms} ms."),
            default_badge_deep_link_template(),
        ],
        ctx,
    );
    display::update_version(&mut display);
    sui::transfer::public_share_object(display);
}

#[allow(lint(share_owned))]
entry fun update_badge_display(
    pub: &Publisher,
    display: &mut display::Display<DonorBadge>,
    keys: vector<String>,
    values: vector<String>,
    deep_link_base: String,
    clock: &Clock,
    _ctx: &mut tx_ctx::TxContext,
) {
    assert!(package::from_package<DonorBadge>(pub), E_INVALID_PUBLISHER);
    update_badge_display_internal(display, keys, values, deep_link_base, clock);
}

#[allow(lint(share_owned))]
entry fun remove_badge_display_keys(
    pub: &Publisher,
    display: &mut display::Display<DonorBadge>,
    keys: vector<String>,
    deep_link_base: String,
    clock: &Clock,
    _ctx: &mut tx_ctx::TxContext,
) {
    assert!(package::from_package<DonorBadge>(pub), E_INVALID_PUBLISHER);
    remove_badge_display_internal(display, keys, deep_link_base, clock);
}

public(package) fun update_badge_display_internal(
    display: &mut display::Display<DonorBadge>,
    keys: vector<String>,
    values: vector<String>,
    deep_link_base: String,
    clock: &Clock,
) {
    assert!(vector::length(&keys) == vector::length(&values), E_BAD_DISPLAY_LENGTH);

    apply_display_edits(display, &keys, &values);

    set_link_template(display, &deep_link_base);

    display::update_version(display);
    event::emit(BadgeDisplayUpdated {
        keys: clone_string_vector(&keys),
        deep_link_template: deep_link_template(&deep_link_base),
        timestamp_ms: clock::timestamp_ms(clock),
    });
}

public(package) fun remove_badge_display_internal(
    display: &mut display::Display<DonorBadge>,
    keys: vector<String>,
    deep_link_base: String,
    clock: &Clock,
) {
    remove_display_keys(display, &keys);
    set_link_template(display, &deep_link_base);
    display::update_version(display);
    event::emit(BadgeDisplayUpdated {
        keys: clone_string_vector(&keys),
        deep_link_template: deep_link_template(&deep_link_base),
        timestamp_ms: clock::timestamp_ms(clock),
    });
}

fun apply_display_edits(
    display: &mut display::Display<DonorBadge>,
    keys: &vector<String>,
    values: &vector<String>,
) {
    let mut idx = 0;
    let len = vector::length(keys);
    while (idx < len) {
        let key_ref = vector::borrow(keys, idx);
        let value_ref = vector::borrow(values, idx);
        let key = clone_string(key_ref);
        let value = clone_string(value_ref);
        let exists = {
            let snapshot = display::fields(display);
            vec_map::contains(snapshot, &key)
        };
        if (exists) {
            display::edit(display, key, value);
        } else {
            display::add(display, key, value);
        };
        idx = idx + 1;
    };
}

fun remove_display_keys(
    display: &mut display::Display<DonorBadge>,
    keys: &vector<String>,
) {
    let mut idx = 0;
    let len = vector::length(keys);
    while (idx < len) {
        let key_ref = vector::borrow(keys, idx);
        display::remove(display, clone_string(key_ref));
        idx = idx + 1;
    };
}

fun set_link_template(display: &mut display::Display<DonorBadge>, base: &String) {
    let link_key = string::utf8(b"link");
    let link_value = deep_link_template(base);
    let fields = display::fields(display);
    if (vec_map::contains(fields, &link_key)) {
        display::edit(display, link_key, link_value);
    } else {
        display::add(display, link_key, link_value);
    };
}

fun deep_link_template(base: &String): String {
    let mut template = clone_string(base);
    string::append_utf8(&mut template, BADGE_DEEP_LINK_SUFFIX);
    template
}

fun default_badge_deep_link_template(): String {
    let base = string::utf8(BADGE_DEEP_LINK_BASE_DEFAULT);
    deep_link_template(&base)
}

fun validate_inputs(
    amount_thresholds_micro: &vector<u64>,
    payment_thresholds: &vector<u64>,
    image_uris: &vector<String>,
) {
    assert!(
        vector::length(amount_thresholds_micro) == LEVEL_COUNT,
        E_BAD_LENGTH,
    );
    assert!(
        vector::length(payment_thresholds) == LEVEL_COUNT,
        E_BAD_LENGTH,
    );
    assert!(
        vector::length(image_uris) == LEVEL_COUNT,
        E_BAD_LENGTH,
    );

    assert_strictly_increasing(amount_thresholds_micro);
    assert_strictly_increasing(payment_thresholds);
    assert_non_empty_strings(image_uris);
}

fun assert_strictly_increasing(values: &vector<u64>) {
    let len = vector::length(values);
    let mut idx = 1;
    while (idx < len) {
        let prev = *vector::borrow(values, idx - 1);
        let current = *vector::borrow(values, idx);
        assert!(current > prev, E_NOT_ASCENDING);
        idx = idx + 1;
    };
}

fun assert_non_empty_strings(values: &vector<String>) {
    let len = vector::length(values);
    let mut idx = 0;
    while (idx < len) {
        let value_ref = vector::borrow(values, idx);
        assert!(string::length(value_ref) > 0, E_EMPTY_URI);
        idx = idx + 1;
    };
}

fun clone_u64_vector(values: &vector<u64>): vector<u64> {
    let mut result = vector::empty<u64>();
    let len = vector::length(values);
    let mut idx = 0;
    while (idx < len) {
        vector::push_back(&mut result, *vector::borrow(values, idx));
        idx = idx + 1;
    };
    result
}

fun clone_string_vector(values: &vector<String>): vector<String> {
    let mut clone = vector::empty<String>();
    let len = vector::length(values);
    let mut idx = 0;
    while (idx < len) {
        let value_ref = vector::borrow(values, idx);
        vector::push_back(&mut clone, clone_string(value_ref));
        idx = idx + 1;
    };
    clone
}

fun clone_string(value: &String): String {
    string::substring(value, 0, string::length(value))
}

fun assert_valid_level(level: u8) {
    assert!(
        level != 0 && level <= MAX_LEVEL,
        E_BAD_BADGE_LEVEL,
    );
}
