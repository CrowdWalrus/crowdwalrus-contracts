#[test_only]
module crowd_walrus::donations_tests;

use crowd_walrus::campaign::{Self as campaign};
use crowd_walrus::crowd_walrus::{Self as crowd_walrus};
use crowd_walrus::crowd_walrus_tests;
use crowd_walrus::donations;
use crowd_walrus::price_oracle;
use crowd_walrus::token_registry::{Self as token_registry};
use pyth::price::{Self as pyth_price};
use pyth::price_feed::{Self as price_feed};
use pyth::price_identifier::{Self as price_identifier};
use pyth::price_info::{Self as price_info, PriceInfoObject};
use pyth::pyth;
use pyth::pyth_tests::{Self as pyth_tests};
use std::string::{Self as string, String};
use std::unit_test::assert_eq;
use sui::coin::{Self as coin};
use sui::clock::{Self as clock, Clock};
use sui::test_scenario::{Self as ts};
use sui::test_utils::{Self as tu};
use wormhole::state::State as WormState;
use wormhole::vaa::{Self as vaa, VAA};

const ADMIN: address = @0xA;
const OWNER: address = @0xB;
const DONOR: address = @0xD;
const DEPLOYER: address = @0x1234;
const E_CAMPAIGN_DELETED: u64 = 11;
public struct TestCoin has drop, store {}
public struct DisabledCoin has drop, store {}
public struct UnlistedCoin has drop, store {}

#[test]
fun effective_max_age_without_override_uses_registry_value() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);

    let effective = donations::effective_max_age_ms<TestCoin>(&registry, std::option::none());
    assert_eq!(effective, 5_000);

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test]
fun effective_max_age_with_override_uses_minimum() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();
    let clock = scenario.take_shared<Clock>();

    add_enabled_token(&mut registry, &admin_cap, &clock, 8_000);

    let tighter = donations::effective_max_age_ms<TestCoin>(&registry, std::option::some(3_000));
    assert_eq!(tighter, 3_000);

    let looser = donations::effective_max_age_ms<TestCoin>(&registry, std::option::some(12_000));
    assert_eq!(looser, 8_000);

    let zero = donations::effective_max_age_ms<TestCoin>(&registry, std::option::some(0));
    assert_eq!(zero, 8_000);

    ts::return_shared(clock);
    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
    ts::end(scenario);
}

#[test]
fun precheck_allows_active_campaign() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, mut clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Donation Ready"),
        string::utf8(b"Active campaign"),
        b"precheck-ok",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        1_000,
        10_000,
    );
    clock.increment_for_testing(1_000);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
   let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
   add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
   donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test]
fun precheck_allows_at_exact_start_time() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, mut clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Start Boundary"),
        string::utf8(b""),
        b"start-boundary",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        5_000,
        15_000,
    );
    clock.increment_for_testing(5_000);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test]
fun precheck_allows_at_exact_end_time() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, mut clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"End Boundary"),
        string::utf8(b""),
        b"end-boundary",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        12_000,
    );
    clock.increment_for_testing(12_000);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = donations::E_CAMPAIGN_INACTIVE, location = 0x0::donations)]
fun precheck_fails_when_campaign_inactive() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (mut campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Inactive Campaign"),
        string::utf8(b"Inactive campaign"),
        b"inactive",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        10_000,
    );
    campaign::set_is_active(&mut campaign, &owner_cap, false);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = donations::E_CAMPAIGN_CLOSED, location = 0x0::donations)]
fun precheck_fails_when_before_start() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Future Campaign"),
        string::utf8(b"Future window"),
        b"future",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        10_000,
        20_000,
    );

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = E_CAMPAIGN_DELETED, location = 0x0::campaign)]
fun precheck_fails_when_campaign_deleted() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (mut campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Deleted Campaign"),
        string::utf8(b""),
        b"deleted",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        10_000,
    );
    campaign::mark_deleted(&mut campaign, &owner_cap, 1);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = donations::E_CAMPAIGN_CLOSED, location = 0x0::donations)]
fun precheck_fails_when_after_end() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, mut clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Expired Campaign"),
        string::utf8(b"Expired window"),
        b"expired",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        5_000,
    );

    clock.increment_for_testing(10_000);

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    add_enabled_token(&mut registry, &admin_cap, &clock, 5_000);
    donations::precheck<TestCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = donations::E_TOKEN_DISABLED, location = 0x0::donations)]
fun precheck_fails_when_token_disabled() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"No Token"),
        string::utf8(b"Token disabled"),
        b"disabled-token",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        10_000,
    );

    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_address<crowd_walrus::AdminCap>(ADMIN);
    crowd_walrus::add_token_internal<DisabledCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"DIS"),
        string::utf8(b"Disabled Coin"),
        9,
        feed_id(9),
        5_000,
        &clock,
    );
    donations::precheck<DisabledCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    ts::return_to_address(ADMIN, admin_cap);
    campaign::share(campaign);
    tu::destroy(owner_cap);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = donations::E_TOKEN_DISABLED, location = 0x0::donations)]
fun precheck_fails_when_token_unregistered() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(OWNER);
    let (campaign, _owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Unregistered Token"),
        string::utf8(b""),
        b"no-token",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        10_000,
    );

    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    donations::precheck<UnlistedCoin>(&campaign, &registry, &clock);
    ts::return_shared(clock);
    ts::return_shared(registry);
    campaign::share(campaign);
    tu::destroy(_owner_cap);
    ts::end(scenario);
}

#[test]
fun split_and_transfer_routes_all_to_recipient_when_platform_zero() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(DONOR);
    let (campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Zero Fee"),
        string::utf8(b"All to recipient"),
        b"split-zero",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        0,
        ADMIN,
        0,
        10_000,
    );

    let donation = coin::mint_for_testing<TestCoin>(1_000, ts::ctx(&mut scenario));
    let (platform_sent, recipient_sent) = donations::split_and_transfer<TestCoin>(
        &campaign,
        donation,
        ts::ctx(&mut scenario),
    );

    assert_eq!(platform_sent, 0);
    assert_eq!(recipient_sent, 1_000);

    ts::return_shared(clock);
    campaign::share(campaign);
    tu::destroy(owner_cap);

    let _ = ts::next_tx(&mut scenario, DONOR);

    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    assert_eq!(coin::value(&recipient_coin), recipient_sent);
    ts::return_to_address(OWNER, recipient_coin);

    ts::end(scenario);
}

#[test]
fun split_and_transfer_applies_platform_fee_with_floor_and_remainder() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(DONOR);
    let (campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"Five Percent"),
        string::utf8(b"Checks remainder"),
        b"split-five",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        500,
        ADMIN,
        0,
        10_000,
    );

    let donation = coin::mint_for_testing<TestCoin>(101, ts::ctx(&mut scenario));
    let (platform_sent, recipient_sent) = donations::split_and_transfer<TestCoin>(
        &campaign,
        donation,
        ts::ctx(&mut scenario),
    );

    assert_eq!(platform_sent, 5);
    assert_eq!(recipient_sent, 96);

    ts::return_shared(clock);
    campaign::share(campaign);
    tu::destroy(owner_cap);

    let _ = ts::next_tx(&mut scenario, DONOR);

    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    assert_eq!(coin::value(&platform_coin), platform_sent);
    ts::return_to_address(ADMIN, platform_coin);

    let recipient_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, OWNER);
    assert_eq!(coin::value(&recipient_coin), recipient_sent);
    ts::return_to_address(OWNER, recipient_coin);

    ts::end(scenario);
}

#[test]
fun split_and_transfer_routes_all_to_platform_when_fee_maximum() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);
    scenario.next_tx(DONOR);
    let (campaign, owner_cap, clock) = crowd_walrus_tests::create_unshared_campaign(
        &mut scenario,
        string::utf8(b"All Platform"),
        string::utf8(b"Full fee"),
        b"split-full",
        vector::empty<String>(),
        vector::empty<String>(),
        1,
        OWNER,
        10_000,
        ADMIN,
        0,
        10_000,
    );

    let donation = coin::mint_for_testing<TestCoin>(250, ts::ctx(&mut scenario));
    let (platform_sent, recipient_sent) = donations::split_and_transfer<TestCoin>(
        &campaign,
        donation,
        ts::ctx(&mut scenario),
    );

    assert_eq!(platform_sent, 250);
    assert_eq!(recipient_sent, 0);

    ts::return_shared(clock);
    campaign::share(campaign);
    tu::destroy(owner_cap);

    let _ = ts::next_tx(&mut scenario, DONOR);

    let platform_coin = ts::take_from_address<coin::Coin<TestCoin>>(&scenario, ADMIN);
    assert_eq!(coin::value(&platform_coin), platform_sent);
    ts::return_to_address(ADMIN, platform_coin);
    assert_eq!(
        ts::has_most_recent_for_address<coin::Coin<TestCoin>>(OWNER),
        false
    );

    ts::end(scenario);
}

#[test]
fun quote_usd_micro_uses_registry_metadata_and_override() {
    let max_age_ms = 4_000;
    let override_ms = 1_000;
    let (mut scenario, clock_obj, price_obj, fee_coins) =
        setup_quote_scenario(6, max_age_ms, true);

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();
    let amount = 1_234_567;
    let usd = donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        amount,
        &price_obj,
        std::option::some(override_ms),
    );
    let decimals = token_registry::decimals<TestCoin>(&registry);
    assert_eq!(decimals, 6);
    let feed_id = token_registry::pyth_feed_id<TestCoin>(&registry);
    let expected = price_oracle::quote_usd<TestCoin>(
        (amount as u128),
        decimals,
        feed_id,
        &price_obj,
        &clock_obj,
        override_ms,
    );
    assert_eq!(usd, expected);

    ts::return_shared(registry);

    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = price_oracle::E_PRICE_STALE, location = 0x0::price_oracle)]
fun quote_usd_micro_aborts_when_price_stale() {
    let max_age_ms = 1_000;
    let (mut scenario, mut clock_obj, price_obj, fee_coins) =
        setup_quote_scenario(9, max_age_ms, true);

    let publish_time = publish_time_ms(&price_obj);
    clock::set_for_testing(&mut clock_obj, publish_time + max_age_ms + 1);

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        1,
        &price_obj,
        std::option::none(),
    );

    ts::return_shared(registry);
    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = donations::E_TOKEN_DISABLED, location = 0x0::donations)]
fun quote_usd_micro_aborts_when_token_disabled() {
    let max_age_ms = 2_000;
    let (mut scenario, clock_obj, price_obj, fee_coins) =
        setup_quote_scenario(8, max_age_ms, false);

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        10,
        &price_obj,
        std::option::none(),
    );

    ts::return_shared(registry);
    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = price_oracle::E_FEED_ID_MISMATCH, location = 0x0::price_oracle)]
fun quote_usd_micro_aborts_when_feed_id_mismatched() {
    let (mut scenario, clock_obj, price_obj, feed_id, fee_coins) = setup_verified_price_info();
    let mut wrong_feed = clone_bytes(&feed_id);
    let first_byte = vector::borrow_mut(&mut wrong_feed, 0);
    *first_byte = *first_byte ^ 0x1;

    register_test_coin_with_feed(
        &mut scenario,
        &clock_obj,
        wrong_feed,
        6,
        2_000,
        true,
    );

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        100,
        &price_obj,
        std::option::none(),
    );

    ts::return_shared(registry);
    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = donations::E_COIN_NOT_FOUND, location = 0x0::donations)]
fun quote_usd_micro_aborts_when_token_not_in_registry() {
    let max_age_ms = 3_000;
    let (mut scenario, clock_obj, price_obj, fee_coins) =
        setup_quote_scenario(6, max_age_ms, true);

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    donations::quote_usd_micro<UnlistedCoin>(
        &registry,
        &clock_obj,
        5,
        &price_obj,
        std::option::none(),
    );

    ts::return_shared(registry);
    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

#[test, expected_failure(abort_code = price_oracle::E_ZERO_AMOUNT, location = 0x0::price_oracle)]
fun quote_usd_micro_aborts_on_zero_amount() {
    let max_age_ms = 4_000;
    let (mut scenario, clock_obj, price_obj, fee_coins) =
        setup_quote_scenario(6, max_age_ms, true);

    ts::next_tx(&mut scenario, ADMIN);
    let registry = scenario.take_shared<token_registry::TokenRegistry>();

    donations::quote_usd_micro<TestCoin>(
        &registry,
        &clock_obj,
        0,
        &price_obj,
        std::option::none(),
    );

    ts::return_shared(registry);
    cleanup_quote_scenario(scenario, clock_obj, price_obj, fee_coins);
}

fun add_enabled_token(
    registry: &mut token_registry::TokenRegistry,
    admin_cap: &crowd_walrus::AdminCap,
    clock: &Clock,
    max_age_ms: u64,
) {
    crowd_walrus::add_token_internal<TestCoin>(
        registry,
        admin_cap,
        string::utf8(b"TEST"),
        string::utf8(b"Test Coin"),
        9,
        feed_id(7),
        max_age_ms,
        clock,
    );
    crowd_walrus::set_token_enabled_internal<TestCoin>(
        registry,
        admin_cap,
        true,
        clock,
    );
}

fun feed_id(val: u8): vector<u8> {
    let mut bytes = vector::empty<u8>();
    let mut i = 0;
    while (i < 32) {
        vector::push_back(&mut bytes, val);
        i = i + 1;
    };
    bytes
}

fun setup_quote_scenario(
    decimals: u8,
    max_age_ms: u64,
    enable_token: bool,
): (ts::Scenario, Clock, PriceInfoObject, coin::Coin<sui::sui::SUI>) {
    let (mut scenario, clock_obj, price_obj, feed_id, fee_coins) = setup_verified_price_info();
    register_test_coin_with_feed(
        &mut scenario,
        &clock_obj,
        clone_bytes(&feed_id),
        decimals,
        max_age_ms,
        enable_token,
    );
    (scenario, clock_obj, price_obj, fee_coins)
}

fun register_test_coin_with_feed(
    scenario: &mut ts::Scenario,
    clock_obj: &Clock,
    feed_id: vector<u8>,
    decimals: u8,
    max_age_ms: u64,
    enable_token: bool,
) {
    ts::next_tx(scenario, ADMIN);
    let crowd_walrus_id = crowd_walrus::create_and_share_crowd_walrus(ts::ctx(scenario));
    crowd_walrus::create_admin_cap_for_user(crowd_walrus_id, ADMIN, ts::ctx(scenario));

    ts::next_tx(scenario, ADMIN);
    let mut registry = scenario.take_shared<token_registry::TokenRegistry>();
    let admin_cap = scenario.take_from_sender<crowd_walrus::AdminCap>();

    crowd_walrus::add_token_internal<TestCoin>(
        &mut registry,
        &admin_cap,
        string::utf8(b"TEST"),
        string::utf8(b"Test Coin"),
        decimals,
        feed_id,
        max_age_ms,
        clock_obj,
    );
    if (enable_token) {
        crowd_walrus::set_token_enabled_internal<TestCoin>(
            &mut registry,
            &admin_cap,
            true,
            clock_obj,
        );
    };

    ts::return_shared(registry);
    scenario.return_to_sender(admin_cap);
}

fun clone_bytes(bytes: &vector<u8>): vector<u8> {
    let mut out = vector::empty<u8>();
    let len = vector::length(bytes);
    let mut i = 0;
    while (i < len) {
        vector::push_back(&mut out, *vector::borrow(bytes, i));
        i = i + 1;
    };
    out
}

fun cleanup_quote_scenario(
    scenario: ts::Scenario,
    clock_obj: Clock,
    price_obj: PriceInfoObject,
    fee_coins: coin::Coin<sui::sui::SUI>,
) {
    price_info::destroy(price_obj);
    clock::destroy_for_testing(clock_obj);
    coin::burn_for_testing(fee_coins);
    ts::end(scenario);
}

fun setup_verified_price_info(): (
    ts::Scenario,
    Clock,
    PriceInfoObject,
    vector<u8>,
    coin::Coin<sui::sui::SUI>,
) {
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
        ts::ctx(&mut scenario),
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

fun publish_time_ms(price_obj: &PriceInfoObject): u64 {
    let price_info_data = price_info::get_price_info_from_price_info_object(price_obj);
    let price_feed_ref = price_info::get_price_feed(&price_info_data);
    let spot_price = price_feed::get_price(price_feed_ref);
    publish_time_ms_from_secs(pyth_price::get_timestamp(&spot_price))
}

fun publish_time_ms_from_secs(seconds: u64): u64 {
    seconds * 1_000
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
