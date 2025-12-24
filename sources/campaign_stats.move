module crowd_walrus::campaign_stats;

use crowd_walrus::campaign::{Self as campaign, Campaign};
use sui::clock::{Self as clock, Clock};
use sui::dynamic_field::{Self as df};
use sui::event;
use sui::object::{Self as sui_object};

const E_STATS_ALREADY_EXISTS: u64 = 1;
const E_OVERFLOW: u64 = 2;

const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;
const U128_MAX: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

public fun e_stats_already_exists(): u64 {
    E_STATS_ALREADY_EXISTS
}

public fun e_overflow(): u64 {
    E_OVERFLOW
}

public struct CampaignStats has key {
    id: sui_object::UID,
    parent_id: sui_object::ID,
    total_usd_micro: u64,
    total_donations_count: u64,
}

/// Key type for storing per-coin stats as dynamic fields keyed by coin type T.
public struct PerCoinKey<phantom T> has copy, drop, store {}

/// Per-coin aggregate totals tracked under CampaignStats.
public struct PerCoinStats<phantom T> has store {
    total_raw: u128,
    donation_count: u64,
}

public struct CampaignStatsCreated has copy, drop {
    campaign_id: sui_object::ID,
    stats_id: sui_object::ID,
    timestamp_ms: u64,
}

public fun campaign_stats_created_campaign_id(event: &CampaignStatsCreated): sui_object::ID {
    event.campaign_id
}

public fun campaign_stats_created_stats_id(event: &CampaignStatsCreated): sui_object::ID {
    event.stats_id
}

public fun campaign_stats_created_timestamp_ms(event: &CampaignStatsCreated): u64 {
    event.timestamp_ms
}

public fun total_usd_micro(stats: &CampaignStats): u64 {
    stats.total_usd_micro
}

public fun total_donations_count(stats: &CampaignStats): u64 {
    stats.total_donations_count
}

public fun per_coin_total_raw<T>(stats: &CampaignStats): u128 {
    let key = per_coin_key<T>();
    if (!df::exists_(&stats.id, copy key)) {
        0
    } else {
        let per_coin = df::borrow<PerCoinKey<T>, PerCoinStats<T>>(&stats.id, key);
        per_coin.total_raw
    }
}

public fun per_coin_donation_count<T>(stats: &CampaignStats): u64 {
    let key = per_coin_key<T>();
    if (!df::exists_(&stats.id, copy key)) {
        0
    } else {
        let per_coin = df::borrow<PerCoinKey<T>, PerCoinStats<T>>(&stats.id, key);
        per_coin.donation_count
    }
}

public fun id(stats: &CampaignStats): sui_object::ID {
    sui_object::id(stats)
}

fun per_coin_key<T>(): PerCoinKey<T> {
    PerCoinKey {}
}

public(package) fun ensure_per_coin<T>(stats: &mut CampaignStats): &mut PerCoinStats<T> {
    let key = per_coin_key<T>();
    if (!df::exists_(&stats.id, copy key)) {
        let entry = PerCoinStats<T> {
            total_raw: 0,
            donation_count: 0,
        };
        df::add(&mut stats.id, copy key, entry);
    };
    df::borrow_mut(&mut stats.id, key)
}

public(package) fun add_donation<T>(
    stats: &mut CampaignStats,
    raw_amount: u128,
    usd_micro: u64,
) {
    {
        let per_coin_stats = ensure_per_coin<T>(stats);
        let remaining_raw = U128_MAX - per_coin_stats.total_raw;
        assert!(raw_amount <= remaining_raw, E_OVERFLOW);
        per_coin_stats.total_raw = per_coin_stats.total_raw + raw_amount;

        assert!(per_coin_stats.donation_count < U64_MAX, E_OVERFLOW);
        per_coin_stats.donation_count = per_coin_stats.donation_count + 1;
    };

    let remaining_usd = U64_MAX - stats.total_usd_micro;
    assert!(usd_micro <= remaining_usd, E_OVERFLOW);
    stats.total_usd_micro = stats.total_usd_micro + usd_micro;

    assert!(stats.total_donations_count < U64_MAX, E_OVERFLOW);
    stats.total_donations_count = stats.total_donations_count + 1;
}

#[test_only]
public fun per_coin_totals_for_test<T>(stats: &CampaignStats): (u128, u64) {
    if (!df::exists_(&stats.id, per_coin_key<T>())) {
        (0, 0)
    } else {
        let per_coin = df::borrow<PerCoinKey<T>, PerCoinStats<T>>(&stats.id, per_coin_key<T>());
        (per_coin.total_raw, per_coin.donation_count)
    }
}

#[test_only]
public fun set_per_coin_totals_for_test<T>(stats: &mut CampaignStats, raw: u128, count: u64) {
    let per_coin = ensure_per_coin<T>(stats);
    per_coin.total_raw = raw;
    per_coin.donation_count = count;
}

public(package) fun create_for_campaign(
    campaign: &mut Campaign,
    clock: &Clock,
    ctx: &mut sui::tx_context::TxContext,
): sui_object::ID {
    assert!(
        sui_object::id_to_address(&campaign::stats_id(campaign)) == @0x0,
        E_STATS_ALREADY_EXISTS,
    );

    let campaign_id = sui_object::id(campaign);

    let stats = CampaignStats {
        id: sui_object::new(ctx),
        parent_id: campaign_id,
        total_usd_micro: 0,
        total_donations_count: 0,
    };

    let stats_id = sui_object::id(&stats);
    let timestamp_ms = clock::timestamp_ms(clock);

    campaign::set_stats_id(campaign, stats_id);

    sui::transfer::share_object(stats);

    event::emit(CampaignStatsCreated {
        campaign_id,
        stats_id,
        timestamp_ms,
    });

    stats_id
}
