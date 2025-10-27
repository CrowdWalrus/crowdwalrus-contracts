module crowd_walrus::price_oracle;

use pyth::i64::{Self as pyth_i64, I64};
use pyth::price::{Self as pyth_price, Price};
use pyth::price_feed::{Self as price_feed};
use pyth::price_identifier::{Self as price_identifier};
use pyth::price_info::{Self as price_info, PriceInfo, PriceInfoObject};
use std::u256;
use sui::clock::{Self as clock, Clock};

const FEED_ID_LENGTH: u64 = 32;
const MICROS_PER_UNIT: u64 = 1_000_000;
const MILLIS_PER_SECOND: u64 = 1_000;
const MAX_DECIMALS: u8 = 38;
const MAX_EXPONENT_ABS: u8 = 38;
const ONE_U256: u256 = 1;
const TEN_U256: u256 = 10;

const E_ZERO_AMOUNT: u64 = 1;
const E_INVALID_FEED_ID: u64 = 2;
const E_PRICE_NOT_FOUND: u64 = 3;
const E_NEGATIVE_PRICE: u64 = 5;
const E_EXPONENT_TOO_LARGE: u64 = 6;
const E_PRICE_STALE: u64 = 7;
const E_VALUE_OVERFLOW: u64 = 8;
const E_FEED_ID_MISMATCH: u64 = 9;

#[allow(unused_type_parameter)]
public fun quote_usd<T>(
    amount_raw: u128,
    decimals: u8,
    feed_id: vector<u8>,
    price_info_object: &PriceInfoObject,
    clock: &Clock,
    max_age_ms: u64,
): u64 {
    assert!(amount_raw > 0, E_ZERO_AMOUNT);
    assert!(vector::length(&feed_id) == FEED_ID_LENGTH, E_INVALID_FEED_ID);
    assert!(decimals <= MAX_DECIMALS, E_EXPONENT_TOO_LARGE);

    let price_info = price_info::get_price_info_from_price_info_object(price_info_object);
    ensure_feed_matches(&feed_id, &price_info);

    let price_feed = price_info::get_price_feed(&price_info);
    let spot_price = price_feed::get_price(price_feed);
    enforce_freshness(clock, max_age_ms, &spot_price);

    let signed_price = pyth_price::get_price(&spot_price);
    let expo = pyth_price::get_expo(&spot_price);
    compute_usd_micro(amount_raw, decimals, &signed_price, &expo)
}

public fun e_zero_amount(): u64 {
    E_ZERO_AMOUNT
}

public fun e_invalid_feed_id(): u64 {
    E_INVALID_FEED_ID
}

public fun e_price_not_found(): u64 {
    E_PRICE_NOT_FOUND
}

public fun e_negative_price(): u64 {
    E_NEGATIVE_PRICE
}

public fun e_exponent_too_large(): u64 {
    E_EXPONENT_TOO_LARGE
}

public fun e_price_stale(): u64 {
    E_PRICE_STALE
}

public fun e_value_overflow(): u64 {
    E_VALUE_OVERFLOW
}

public fun e_feed_id_mismatch(): u64 {
    E_FEED_ID_MISMATCH
}

fun ensure_feed_matches(feed_id: &vector<u8>, info: &PriceInfo) {
    let identifier = price_info::get_price_identifier(info);
    let identifier_bytes = price_identifier::get_bytes(&identifier);
    assert!(bytes_equal(feed_id, &identifier_bytes), E_FEED_ID_MISMATCH);
}

fun enforce_freshness(clock_ref: &Clock, max_age_ms: u64, price: &Price) {
    if (max_age_ms == 0) {
        return
    };

    let publish_time_ms = seconds_to_millis(pyth_price::get_timestamp(price));
    let now_ms = clock::timestamp_ms(clock_ref);
    assert!(now_ms >= publish_time_ms, E_PRICE_STALE);
    let age_ms = now_ms - publish_time_ms;
    assert!(age_ms <= max_age_ms, E_PRICE_STALE);
}

fun compute_usd_micro(
    amount_raw: u128,
    decimals: u8,
    price: &I64,
    expo: &I64,
): u64 {
    assert!(!pyth_i64::get_is_negative(price), E_NEGATIVE_PRICE);

    let price_mag = pyth_i64::get_magnitude_if_positive(price);
    let mut numerator: u256 = (amount_raw as u256);
    numerator = numerator * (price_mag as u256);
    numerator = numerator * (MICROS_PER_UNIT as u256);

    let expo_is_negative = pyth_i64::get_is_negative(expo);
    let expo_mag = if (expo_is_negative) {
        pyth_i64::get_magnitude_if_negative(expo)
    } else {
        pyth_i64::get_magnitude_if_positive(expo)
    };
    assert!(expo_mag <= (MAX_EXPONENT_ABS as u64), E_EXPONENT_TOO_LARGE);
    let expo_u8 = (expo_mag as u8);

    if (!expo_is_negative) {
        numerator = numerator * pow10_u256(expo_u8);
    };

    let mut denominator = pow10_u256(decimals);
    if (expo_is_negative) {
        denominator = denominator * pow10_u256(expo_u8);
    };

    let value_u256 = numerator / denominator;
    let maybe_u64 = u256::try_as_u64(value_u256);
    assert!(std::option::is_some(&maybe_u64), E_VALUE_OVERFLOW);
    std::option::destroy_some(maybe_u64)
}

fun pow10_u256(exp: u8): u256 {
    let mut result = ONE_U256;
    let mut i: u64 = 0;
    let target = (exp as u64);
    while (i < target) {
        result = result * TEN_U256;
        i = i + 1;
    };
    result
}

fun seconds_to_millis(seconds: u64): u64 {
    seconds * MILLIS_PER_SECOND
}

fun bytes_equal(left: &vector<u8>, right: &vector<u8>): bool {
    let len = vector::length(left);
    if (len != vector::length(right)) {
        return false
    };

    let mut i = 0;
    while (i < len) {
        if (*vector::borrow(left, i) != *vector::borrow(right, i)) {
            return false
        };
        i = i + 1;
    };
    true
}
