module crowd_walrus::campaign_stats;

use crowd_walrus::campaign::{Self as campaign, Campaign};
use sui::clock::{Self as clock, Clock};
use sui::event;
use sui::object::{Self as sui_object};

const E_STATS_ALREADY_EXISTS: u64 = 1;

public fun e_stats_already_exists(): u64 {
    E_STATS_ALREADY_EXISTS
}

public struct CampaignStats has key {
    id: sui_object::UID,
    parent_id: sui_object::ID,
    total_usd_micro: u64,
    total_donations_count: u64,
}

public struct CampaignStatsCreated has copy, drop {
    campaign_id: sui_object::ID,
    stats_id: sui_object::ID,
    timestamp_ms: u64,
}

public fun total_usd_micro(stats: &CampaignStats): u64 {
    stats.total_usd_micro
}

public fun total_donations_count(stats: &CampaignStats): u64 {
    stats.total_donations_count
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
