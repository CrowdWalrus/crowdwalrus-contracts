module crowd_walrus::token_registry;

use std::string::{Self as string, String};
use std::type_name::{Self as type_name};
use sui::clock::{Self as clock, Clock};
use sui::dynamic_field::{Self as df};
use sui::event;
use sui::object::{Self as sui_object};
use sui::tx_context::{Self as tx_ctx};

const FEED_ID_LENGTH: u64 = 32;
const MAX_DECIMALS: u8 = 38;

const E_COIN_EXISTS: u64 = 1;
const E_COIN_NOT_FOUND: u64 = 2;
const E_BAD_FEED_ID: u64 = 3;
const E_BAD_DECIMALS: u64 = 4;

public struct TokenRegistry has key {
    id: sui_object::UID,
    crowd_walrus_id: sui_object::ID,
}

public struct CoinKey<phantom T> has copy, drop, store {}

public struct TokenMetadata has store {
    symbol: String,
    name: String,
    decimals: u8,
    pyth_feed_id: vector<u8>,
    enabled: bool,
    max_age_ms: u64,
}

public struct TokenAdded has copy, drop {
    coin_type: String,
    symbol: String,
    name: String,
    decimals: u8,
    pyth_feed_id: vector<u8>,
    max_age_ms: u64,
    enabled: bool,
    timestamp_ms: u64,
}

public struct TokenUpdated has copy, drop {
    coin_type: String,
    symbol: String,
    name: String,
    decimals: u8,
    pyth_feed_id: vector<u8>,
    max_age_ms: u64,
    timestamp_ms: u64,
}

public struct TokenEnabled has copy, drop {
    coin_type: String,
    symbol: String,
    timestamp_ms: u64,
}

public struct TokenDisabled has copy, drop {
    coin_type: String,
    symbol: String,
    timestamp_ms: u64,
}

public fun token_added_coin_type(event: &TokenAdded): String {
    copy event.coin_type
}

public fun token_added_symbol(event: &TokenAdded): String {
    copy event.symbol
}

public fun token_added_name(event: &TokenAdded): String {
    copy event.name
}

public fun token_added_decimals(event: &TokenAdded): u8 {
    event.decimals
}

public fun token_added_pyth_feed_id(event: &TokenAdded): vector<u8> {
    clone_bytes(&event.pyth_feed_id)
}

public fun token_added_max_age_ms(event: &TokenAdded): u64 {
    event.max_age_ms
}

public fun token_added_enabled(event: &TokenAdded): bool {
    event.enabled
}

public fun token_added_timestamp_ms(event: &TokenAdded): u64 {
    event.timestamp_ms
}

public fun token_updated_coin_type(event: &TokenUpdated): String {
    copy event.coin_type
}

public fun token_updated_symbol(event: &TokenUpdated): String {
    copy event.symbol
}

public fun token_updated_name(event: &TokenUpdated): String {
    copy event.name
}

public fun token_updated_decimals(event: &TokenUpdated): u8 {
    event.decimals
}

public fun token_updated_pyth_feed_id(event: &TokenUpdated): vector<u8> {
    clone_bytes(&event.pyth_feed_id)
}

public fun token_updated_max_age_ms(event: &TokenUpdated): u64 {
    event.max_age_ms
}

public fun token_updated_timestamp_ms(event: &TokenUpdated): u64 {
    event.timestamp_ms
}

public fun token_enabled_coin_type(event: &TokenEnabled): String {
    copy event.coin_type
}

public fun token_enabled_symbol(event: &TokenEnabled): String {
    copy event.symbol
}

public fun token_enabled_timestamp_ms(event: &TokenEnabled): u64 {
    event.timestamp_ms
}

public fun token_disabled_coin_type(event: &TokenDisabled): String {
    copy event.coin_type
}

public fun token_disabled_symbol(event: &TokenDisabled): String {
    copy event.symbol
}

public fun token_disabled_timestamp_ms(event: &TokenDisabled): u64 {
    event.timestamp_ms
}

public(package) fun create_registry(
    crowd_walrus_id: sui_object::ID,
    ctx: &mut tx_ctx::TxContext,
): TokenRegistry {
    TokenRegistry {
        id: sui_object::new(ctx),
        crowd_walrus_id,
    }
}

public(package) fun share_registry(registry: TokenRegistry) {
    sui::transfer::share_object(registry);
}

public fun registry_owner_id(registry: &TokenRegistry): sui_object::ID {
    registry.crowd_walrus_id
}

public fun contains<T>(registry: &TokenRegistry): bool {
    df::exists_(&registry.id, coin_key<T>())
}

public fun coin_type_canonical<T>(): String {
    string::from_ascii(type_name::with_original_ids<T>().into_string())
}

public fun symbol<T>(registry: &TokenRegistry): String {
    let metadata = borrow_metadata<T>(registry);
    copy metadata.symbol
}

public fun name<T>(registry: &TokenRegistry): String {
    let metadata = borrow_metadata<T>(registry);
    copy metadata.name
}

public fun decimals<T>(registry: &TokenRegistry): u8 {
    let metadata = borrow_metadata<T>(registry);
    metadata.decimals
}

public fun pyth_feed_id<T>(registry: &TokenRegistry): vector<u8> {
    let metadata = borrow_metadata<T>(registry);
    clone_bytes(&metadata.pyth_feed_id)
}

public fun is_enabled<T>(registry: &TokenRegistry): bool {
    let metadata = borrow_metadata<T>(registry);
    metadata.enabled
}

public fun max_age_ms<T>(registry: &TokenRegistry): u64 {
    let metadata = borrow_metadata<T>(registry);
    metadata.max_age_ms
}

public(package) fun require_enabled<T>(registry: &TokenRegistry) {
    ensure_exists<T>(registry);
    assert!(is_enabled<T>(registry), E_COIN_NOT_FOUND);
}

fun borrow_metadata_mut<T>(registry: &mut TokenRegistry): &mut TokenMetadata {
    ensure_exists<T>(registry);
    df::borrow_mut(&mut registry.id, coin_key<T>())
}

public(package) fun add_coin<T>(
    registry: &mut TokenRegistry,
    symbol: String,
    name: String,
    decimals: u8,
    pyth_feed_id: vector<u8>,
    max_age_ms: u64,
    clock: &Clock,
) {
    assert!(!contains<T>(registry), E_COIN_EXISTS);
    assert_feed_id(&pyth_feed_id);
    assert_decimals(decimals);

    let metadata = TokenMetadata {
        symbol,
        name,
        decimals,
        pyth_feed_id,
        enabled: false,
        max_age_ms,
    };
    df::add(&mut registry.id, coin_key<T>(), metadata);
    emit_added_event<T>(registry, clock);
}

public(package) fun update_metadata<T>(
    registry: &mut TokenRegistry,
    symbol: String,
    name: String,
    decimals: u8,
    pyth_feed_id: vector<u8>,
    clock: &Clock,
) {
    assert_feed_id(&pyth_feed_id);
    assert_decimals(decimals);
    ensure_exists<T>(registry);
    let metadata = borrow_metadata_mut<T>(registry);
    metadata.symbol = symbol;
    metadata.name = name;
    metadata.decimals = decimals;
    metadata.pyth_feed_id = pyth_feed_id;
    emit_updated_event<T>(metadata, clock);
}

public(package) fun set_enabled<T>(
    registry: &mut TokenRegistry,
    enabled: bool,
    clock: &Clock,
) {
    ensure_exists<T>(registry);
    let metadata = borrow_metadata_mut<T>(registry);
    metadata.enabled = enabled;
    if (enabled) {
        emit_enabled_event<T>(metadata, clock);
    } else {
        emit_disabled_event<T>(metadata, clock);
    };
}

public(package) fun set_max_age_ms<T>(
    registry: &mut TokenRegistry,
    max_age_ms: u64,
    clock: &Clock,
) {
    ensure_exists<T>(registry);
    let metadata = borrow_metadata_mut<T>(registry);
    metadata.max_age_ms = max_age_ms;
    emit_updated_event<T>(metadata, clock);
}

fun emit_added_event<T>(registry: &TokenRegistry, clock: &Clock) {
    let metadata = borrow_metadata<T>(registry);
    event::emit(TokenAdded {
        coin_type: coin_type_canonical<T>(),
        symbol: copy metadata.symbol,
        name: copy metadata.name,
        decimals: metadata.decimals,
        pyth_feed_id: clone_bytes(&metadata.pyth_feed_id),
        max_age_ms: metadata.max_age_ms,
        enabled: metadata.enabled,
        timestamp_ms: clock::timestamp_ms(clock),
    });
}

fun emit_updated_event<T>(metadata: &TokenMetadata, clock: &Clock) {
    event::emit(TokenUpdated {
        coin_type: coin_type_canonical<T>(),
        symbol: copy metadata.symbol,
        name: copy metadata.name,
        decimals: metadata.decimals,
        pyth_feed_id: clone_bytes(&metadata.pyth_feed_id),
        max_age_ms: metadata.max_age_ms,
        timestamp_ms: clock::timestamp_ms(clock),
    });
}

fun emit_enabled_event<T>(metadata: &TokenMetadata, clock: &Clock) {
    event::emit(TokenEnabled {
        coin_type: coin_type_canonical<T>(),
        symbol: copy metadata.symbol,
        timestamp_ms: clock::timestamp_ms(clock),
    });
}

fun emit_disabled_event<T>(metadata: &TokenMetadata, clock: &Clock) {
    event::emit(TokenDisabled {
        coin_type: coin_type_canonical<T>(),
        symbol: copy metadata.symbol,
        timestamp_ms: clock::timestamp_ms(clock),
    });
}

fun coin_key<T>(): CoinKey<T> {
    CoinKey {}
}

fun borrow_metadata<T>(registry: &TokenRegistry): &TokenMetadata {
    ensure_exists<T>(registry);
    df::borrow(&registry.id, coin_key<T>())
}

fun assert_feed_id(pyth_feed_id: &vector<u8>) {
    let len = vector::length(pyth_feed_id);
    assert!(len == FEED_ID_LENGTH, E_BAD_FEED_ID);
}

fun assert_decimals(decimals: u8) {
    assert!(decimals <= MAX_DECIMALS, E_BAD_DECIMALS);
}

fun ensure_exists<T>(registry: &TokenRegistry) {
    assert!(contains<T>(registry), E_COIN_NOT_FOUND);
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
