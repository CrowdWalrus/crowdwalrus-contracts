#[test_only]
module crowd_walrus::price_oracle_tests;

use crowd_walrus::price_oracle::{Self as price_oracle};
use pyth::i64;
use pyth::price::{Self as pyth_price};
use pyth::price_feed::{Self as price_feed};
use pyth::price_identifier::{Self as price_identifier};
use pyth::price_info::{Self as price_info, PriceInfoObject};
use pyth::pyth;
use pyth::pyth_tests::{Self as pyth_tests};
use wormhole::state::State as WormState;
use wormhole::vaa::{Self as vaa, VAA};
use std::u256;
use std::unit_test::assert_eq;
use sui::clock::{Self as clock, Clock};
use sui::coin::{Self as coin, Coin};
use sui::test_scenario::{Self as ts, Scenario, ctx};

const DEPLOYER: address = @0x1234;
const MICROS_PER_UNIT: u64 = 1_000_000;

public struct TestCoin has drop, store {}

#[test]
fun test_quote_usd_with_verified_feed() {
    let amount_raw = 1_000_000;
    let decimals = 6;

    let (scenario, clock_obj, price_obj, feed_id, fee_coins) = setup_verified_price_info();
    let result = price_oracle::quote_usd<TestCoin>(
        amount_raw,
        decimals,
        copy feed_id,
        &price_obj,
        &clock_obj,
        1_000,
    );

    let expected = compute_expected_usd(amount_raw, decimals, &price_obj);
    assert_eq!(result, expected);

    cleanup(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
#[expected_failure(abort_code = price_oracle::E_FEED_ID_MISMATCH, location = 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::price_oracle)]
fun test_quote_usd_feed_mismatch_aborts() {
    let (scenario, clock_obj, price_obj, feed_id, fee_coins) = setup_verified_price_info();
    let mut wrong_feed = feed_id;
    let byte_ref = vector::borrow_mut(&mut wrong_feed, 0);
    *byte_ref = *byte_ref + 1;

    price_oracle::quote_usd<TestCoin>(
        1_000_000,
        6,
        wrong_feed,
        &price_obj,
        &clock_obj,
        1_000,
    );

    cleanup(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
#[expected_failure(abort_code = price_oracle::E_ZERO_AMOUNT, location = 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::price_oracle)]
fun test_quote_usd_zero_amount_aborts() {
    let (scenario, clock_obj, price_obj, feed_id, fee_coins) = setup_verified_price_info();
    price_oracle::quote_usd<TestCoin>(
        0,
        6,
        feed_id,
        &price_obj,
        &clock_obj,
        1_000,
    );

    cleanup(scenario, clock_obj, price_obj, fee_coins);
}

#[test]
#[expected_failure(abort_code = price_oracle::E_PRICE_STALE, location = 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::price_oracle)]
fun test_quote_usd_stale_price_aborts() {
    let (scenario, mut clock_obj, price_obj, feed_id, fee_coins) = setup_verified_price_info();

    // Force staleness by jumping clock beyond tolerance.
    let publish_time = publish_time_ms(&price_obj);
    clock::set_for_testing(&mut clock_obj, publish_time + 5_000);

    price_oracle::quote_usd<TestCoin>(
        1_000_000,
        6,
        feed_id,
        &price_obj,
        &clock_obj,
        1_000,
    );

    cleanup(scenario, clock_obj, price_obj, fee_coins);
}

fun setup_verified_price_info(): (Scenario, Clock, PriceInfoObject, vector<u8>, Coin<sui::sui::SUI>) {
    let governance_emitter =
        x"5d1f252d5de865279b00c84bce362774c2804294ed53299bc4a0389a5defef92";
    let data_sources = pyth_tests::data_sources_for_test_vaa();
    let guardians = vector[x"beFA429d57cD18b7F8A4d91A2da9AB4AF05d0FBe"];

    let (mut scenario, fee_coins, mut clock_obj) =
        pyth_tests::setup_test(500, 23, governance_emitter, data_sources, guardians, 50, 0);

    ts::next_tx(&mut scenario, DEPLOYER);
    let (mut pyth_state, worm_state) = pyth_tests::take_wormhole_and_pyth_states(&scenario);
    let verified_vaas = verified_test_vaas(&worm_state, &clock_obj);

    pyth::create_price_feeds(
        &mut pyth_state,
        verified_vaas,
        &clock_obj,
        ctx(&mut scenario),
    );

    ts::return_shared(pyth_state);
    ts::return_shared(worm_state);

    ts::next_tx(&mut scenario, DEPLOYER);
    let price_obj = ts::take_shared<PriceInfoObject>(&scenario);

    let price_info_data = price_info::get_price_info_from_price_info_object(&price_obj);
    let price_feed_ref = price_info::get_price_feed(&price_info_data);
    let spot_price = price_feed::get_price(price_feed_ref);
    let publish_time = pyth_price::get_timestamp(&spot_price);
    clock::set_for_testing(&mut clock_obj, publish_time_ms_from_secs(publish_time) + 500);

    let feed_id = price_identifier::get_bytes(&price_info::get_price_identifier(&price_info_data));

    (scenario, clock_obj, price_obj, feed_id, fee_coins)
}

fun compute_expected_usd(
    amount_raw: u128,
    decimals: u8,
    price_obj: &PriceInfoObject,
): u64 {
    let price_info_data = price_info::get_price_info_from_price_info_object(price_obj);
    let price_feed_ref = price_info::get_price_feed(&price_info_data);
    let spot_price = price_feed::get_price(price_feed_ref);
    let price_i64 = pyth_price::get_price(&spot_price);
    let expo_i64 = pyth_price::get_expo(&spot_price);

    assert!(!i64::get_is_negative(&price_i64), price_oracle::e_negative_price());

    let price_mag = i64::get_magnitude_if_positive(&price_i64);
    let mut numerator: u256 = (amount_raw as u256);
    numerator = numerator * (price_mag as u256);
    numerator = numerator * (MICROS_PER_UNIT as u256);

    let expo_is_negative = i64::get_is_negative(&expo_i64);
    let expo_mag = if (expo_is_negative) {
        i64::get_magnitude_if_negative(&expo_i64)
    } else {
        i64::get_magnitude_if_positive(&expo_i64)
    };
    assert!(expo_mag <= 38, price_oracle::e_exponent_too_large());
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
    assert!(std::option::is_some(&maybe_u64), price_oracle::e_value_overflow());
    std::option::destroy_some(maybe_u64)
}

fun publish_time_ms(price_obj: &PriceInfoObject): u64 {
    let price_info_data = price_info::get_price_info_from_price_info_object(price_obj);
    let price_feed_ref = price_info::get_price_feed(&price_info_data);
    let spot_price = price_feed::get_price(price_feed_ref);
    publish_time_ms_from_secs(pyth_price::get_timestamp(&spot_price))
}

fun publish_time_ms_from_secs(seconds: u64): u64 {
    seconds * 1_000
}

fun pow10_u256(exp: u8): u256 {
    let mut result = 1 as u256;
    let mut i: u64 = 0;
    let target = (exp as u64);
    while (i < target) {
        result = result * (10 as u256);
        i = i + 1;
    };
    result
}

fun verified_test_vaas(worm_state: &WormState, clock_obj: &Clock): vector<VAA> {
    let mut vaa_bytes = test_vaa_bytes();
    let mut reversed = vector::empty<VAA>();
    while (!vector::is_empty(&vaa_bytes)) {
        let bytes = vector::pop_back(&mut vaa_bytes);
        let verified = vaa::parse_and_verify(worm_state, bytes, clock_obj);
        vector::push_back(&mut reversed, verified);
    };
    vector::destroy_empty(vaa_bytes);

    let mut verified = vector::empty<VAA>();
    while (!vector::is_empty(&reversed)) {
        let item = vector::pop_back(&mut reversed);
        vector::push_back(&mut verified, item);
    };
    vector::destroy_empty(reversed);
    verified
}

fun test_vaa_bytes(): vector<vector<u8>> {
    vector[
        x"0100000000010036eb563b80a24f4253bee6150eb8924e4bdf6e4fa1dfc759a6664d2e865b4b134651a7b021b7f1ce3bd078070b688b6f2e37ce2de0d9b48e6a78684561e49d5201527e4f9b00000001001171f8dcb863d176e2c420ad6610cf687359612b6fb392e0642b0ca6b1f186aa3b0000000000000001005032574800030000000102000400951436e0be37536be96f0896366089506a59763d036728332d3e3038047851aea7c6c75c89f14810ec1c54c03ab8f1864a4c4032791f05747f560faec380a695d1000000000000049a0000000000000008fffffffb00000000000005dc0000000000000003000000000100000001000000006329c0eb000000006329c0e9000000006329c0e400000000000006150000000000000007215258d81468614f6b7e194c5d145609394f67b041e93e6695dcc616faadd0603b9551a68d01d954d6387aff4df1529027ffb2fee413082e509feb29cc4904fe000000000000041a0000000000000003fffffffb00000000000005cb0000000000000003010000000100000001000000006329c0eb000000006329c0e9000000006329c0e4000000000000048600000000000000078ac9cf3ab299af710d735163726fdae0db8465280502eb9f801f74b3c1bd190333832fad6e36eb05a8972fe5f219b27b5b2bb2230a79ce79beb4c5c5e7ecc76d00000000000003f20000000000000002fffffffb00000000000005e70000000000000003010000000100000001000000006329c0eb000000006329c0e9000000006329c0e40000000000000685000000000000000861db714e9ff987b6fedf00d01f9fea6db7c30632d6fc83b7bc9459d7192bc44a21a28b4c6619968bd8c20e95b0aaed7df2187fd310275347e0376a2cd7427db800000000000006cb0000000000000001fffffffb00000000000005e40000000000000003010000000100000001000000006329c0eb000000006329c0e9000000006329c0e400000000000007970000000000000001"
    ]
}

fun cleanup(
    scenario: Scenario,
    clock_obj: Clock,
    price_obj: PriceInfoObject,
    fee_coins: Coin<sui::sui::SUI>,
) {
    price_info::destroy(price_obj);
    clock::destroy_for_testing(clock_obj);
    coin::burn_for_testing(fee_coins);
    ts::end(scenario);
}
