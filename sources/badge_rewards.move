module crowd_walrus::badge_rewards;

use std::string::{Self as string, String};
use sui::clock::{Self as clock, Clock};
use sui::event;
use sui::object::{Self as sui_object};
use sui::tx_context::{Self as tx_ctx};

const LEVEL_COUNT: u64 = 5;

const E_BAD_LENGTH: u64 = 1;
const E_NOT_ASCENDING: u64 = 2;
const E_EMPTY_URI: u64 = 3;

public struct BadgeConfig has key {
    id: sui_object::UID,
    crowd_walrus_id: sui_object::ID,
    amount_thresholds_micro: vector<u64>,
    payment_thresholds: vector<u64>,
    image_uris: vector<String>,
}

public struct BadgeConfigUpdated has copy, drop {
    amount_thresholds_micro: vector<u64>,
    payment_thresholds: vector<u64>,
    image_uris: vector<String>,
    timestamp_ms: u64,
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
        vector::push_back(
            &mut clone,
            string::substring(value_ref, 0, string::length(value_ref)),
        );
        idx = idx + 1;
    };
    clone
}
