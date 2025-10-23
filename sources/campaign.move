module crowd_walrus::campaign;

use std::string::String;

use sui::clock::{Self as clock, Clock};
use sui::dynamic_field as df;
use sui::event;
use sui::vec_map::{Self, VecMap};
// === Error Codes ===
const E_APP_NOT_AUTHORIZED: u64 = 1;
// Error codes 2-3 reserved for future use
const E_KEY_VALUE_MISMATCH: u64 = 4;
const E_INVALID_DATE_RANGE: u64 = 5;
const E_START_DATE_IN_PAST: u64 = 6;
const E_FUNDING_GOAL_IMMUTABLE: u64 = 8;
const E_RECIPIENT_ADDRESS_INVALID: u64 = 9;
const E_RECIPIENT_ADDRESS_IMMUTABLE: u64 = 10;
const E_CAMPAIGN_DELETED: u64 = 11;
const E_INVALID_BPS: u64 = 12;
const E_ZERO_ADDRESS: u64 = 13;
const E_STATS_ALREADY_SET: u64 = 14;

// === Error Code Accessors ===
public fun e_start_date_in_past(): u64 { E_START_DATE_IN_PAST }
public fun e_invalid_bps(): u64 { E_INVALID_BPS }
public fun e_zero_address(): u64 { E_ZERO_ADDRESS }
public fun e_campaign_deleted(): u64 { E_CAMPAIGN_DELETED }
public fun e_recipient_address_invalid(): u64 { E_RECIPIENT_ADDRESS_INVALID }

public struct PayoutPolicy has copy, drop, store {
    platform_bps: u16,
    platform_address: address,
    recipient_address: address,
}

public fun new_payout_policy(
    platform_bps: u16,
    platform_address: address,
    recipient_address: address,
): PayoutPolicy {
    assert_valid_payout_policy_fields(platform_bps, platform_address, recipient_address);
    PayoutPolicy { platform_bps, platform_address, recipient_address }
}

fun assert_valid_payout_policy(policy: &PayoutPolicy) {
    assert_valid_payout_policy_fields(
        policy.platform_bps,
        policy.platform_address,
        policy.recipient_address,
    );
}

fun assert_valid_payout_policy_fields(
    platform_bps: u16,
    platform_address: address,
    recipient_address: address,
) {
    assert!(platform_bps <= 10_000, E_INVALID_BPS);
    assert!(platform_address != @0x0, E_ZERO_ADDRESS);
    assert!(recipient_address != @0x0, E_ZERO_ADDRESS);
}

public struct Campaign has key, store {
    id: object::UID,
    admin_id: object::ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    metadata: VecMap<String, String>,
    funding_goal_usd_micro: u64,
    payout_policy: PayoutPolicy,
    stats_id: object::ID,
    start_date: u64,        // Unix timestamp in milliseconds (UTC) when donations open
    end_date: u64,          // Unix timestamp in milliseconds (UTC) when donations close
    created_at_ms: u64,     // Unix timestamp in milliseconds (UTC) recorded at creation
    is_verified: bool,
    is_active: bool,
    is_deleted: bool,
    parameters_locked: bool,
    deleted_at_ms: std::option::Option<u64>,
    // BREAKING CHANGE (2025-01): Removed updates: vector<CampaignUpdate>
    // Updates now stored as frozen objects referenced via dynamic fields.
    next_update_seq: u64,
}

public struct CampaignUpdate has key, store {
    id: object::UID,
    parent_id: object::ID,
    sequence: u64,
    author: address,
    metadata: VecMap<String, String>,
    created_at_ms: u64,  // Unix timestamp in milliseconds (UTC) when the update was created
}

public struct UpdateKey has copy, drop, store {
    sequence: u64,
}

public struct CampaignOwnerCap has key, store {
    id: object::UID,
    campaign_id: object::ID,
}

// === Events ===
public struct CampaignUpdateAdded has copy, drop {
    campaign_id: object::ID,
    update_id: object::ID,
    sequence: u64,
    author: address,
    metadata: VecMap<String, String>,
    created_at_ms: u64,
}

public struct CampaignBasicsUpdated has copy, drop {
    campaign_id: object::ID,
    editor: address,
    timestamp_ms: u64,
    name_updated: bool,
    description_updated: bool,
}

public struct CampaignMetadataUpdated has copy, drop {
    campaign_id: object::ID,
    editor: address,
    timestamp_ms: u64,
    keys_updated: vector<String>,
}

public struct CampaignStatusChanged has copy, drop {
    campaign_id: object::ID,
    editor: address,
    timestamp_ms: u64,
    new_status: bool,
}

// === App Auth ===

/// An authorization Key kept in the Campaign - allows applications access
/// protected features of the Campaign.
/// The `App` type parameter is a witness which should be defined in the
/// original module (CrowdWalrusApp in this case).
public struct AppKey<phantom App: drop> has copy, drop, store {}

// === Authorization Functions ===

/// Authorize an application to access protected features of the Campaign.
public fun authorize_app<App: drop>(self: &mut Campaign, cap: &CampaignOwnerCap) {
    assert_owner(self, cap);
    assert_not_deleted(self);
    df::add(&mut self.id, AppKey<App> {}, true);
}

/// Deauthorize an application by removing its authorization key.
public fun deauthorize_app<App: drop>(self: &mut Campaign, cap: &CampaignOwnerCap): bool {
    assert_owner(self, cap);
    assert_not_deleted(self);
    df::remove(&mut self.id, AppKey<App> {})
}

/// Check if an application is authorized to access protected features of
/// the Campaign.
public fun is_app_authorized<App: drop>(self: &Campaign): bool {
    df::exists_(&self.id, AppKey<App> {})
}

/// Assert that an application is authorized to access protected features of
/// the Campaign. Aborts with `E_APP_NOT_AUTHORIZED` if not.
public fun assert_app_is_authorized<App: drop>(self: &Campaign) {
    assert!(self.is_app_authorized<App>(), E_APP_NOT_AUTHORIZED);
}

/// Create a new campaign
///
/// Validation: Only enforces date range (start < end). No validation for:
/// - String lengths (name, short_description) - frontend handles
/// - Metadata size limits - frontend handles
///
/// This is intentional to maximize flexibility.
public(package) fun new<App: drop>(
    _: &App,
    admin_id: object::ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    metadata: VecMap<String, String>,
    funding_goal_usd_micro: u64,
    payout_policy: PayoutPolicy,
    start_date: u64,
    end_date: u64,
    clock: &Clock,
    ctx: &mut tx_context::TxContext,
): (object::ID, CampaignOwnerCap) {
    let creation_time_ms = clock::timestamp_ms(clock);
    // Check date range
    assert!(start_date < end_date, E_INVALID_DATE_RANGE);
    assert!(start_date >= creation_time_ms, E_START_DATE_IN_PAST);
    assert_valid_payout_policy(&payout_policy);

    let mut campaign = Campaign {
        id: object::new(ctx),
        admin_id,
        name,
        short_description,
        subdomain_name,
        metadata,
        funding_goal_usd_micro,
        payout_policy,
        stats_id: object::id_from_address(@0x0),
        start_date,
        end_date,
        created_at_ms: creation_time_ms,
        is_verified: false,
        is_active: true,
        is_deleted: false,
        parameters_locked: false,
        deleted_at_ms: std::option::none(),
        next_update_seq: 0,
    };

    let campaign_id = object::id(&campaign);
    let campaign_owner_cap = CampaignOwnerCap {
        id: object::new(ctx),
        campaign_id,
    };

    // Authorize the passed app
    df::add(&mut campaign.id, AppKey<App> {}, true);

    transfer::share_object(campaign);
    (campaign_id, campaign_owner_cap)
}

public(package) fun set_stats_id(campaign: &mut Campaign, stats_id: object::ID) {
    assert!(object::id_to_address(&campaign.stats_id) == @0x0, E_STATS_ALREADY_SET);
    campaign.stats_id = stats_id;
}

public fun subdomain_name(campaign: &Campaign): String {
    campaign.subdomain_name
}

public fun funding_goal_usd_micro(campaign: &Campaign): u64 {
    campaign.funding_goal_usd_micro
}

public fun metadata(campaign: &Campaign): VecMap<String, String> {
    campaign.metadata
}

public fun payout_policy(campaign: &Campaign): &PayoutPolicy {
    &campaign.payout_policy
}

public fun payout_platform_bps(campaign: &Campaign): u16 {
    campaign.payout_policy.platform_bps
}

public fun payout_platform_address(campaign: &Campaign): address {
    campaign.payout_policy.platform_address
}

public fun payout_recipient_address(campaign: &Campaign): address {
    campaign.payout_policy.recipient_address
}

public fun payout_policy_platform_bps(policy: &PayoutPolicy): u16 {
    policy.platform_bps
}

public fun payout_policy_platform_address(policy: &PayoutPolicy): address {
    policy.platform_address
}

public fun payout_policy_recipient_address(policy: &PayoutPolicy): address {
    policy.recipient_address
}

public fun stats_id(campaign: &Campaign): object::ID {
    campaign.stats_id
}

public fun parameters_locked(campaign: &Campaign): bool {
    campaign.parameters_locked
}

public fun campaign_id(campaign_owner_cap: &CampaignOwnerCap): object::ID {
    campaign_owner_cap.campaign_id
}

public fun delete_owner_cap(cap: CampaignOwnerCap) {
    let CampaignOwnerCap { id, campaign_id: _ } = cap;
    object::delete(id);
}

public fun set_verified<App: drop>(campaign: &mut Campaign, _: &App, verified: bool) {
    campaign.assert_app_is_authorized<App>();
    assert_not_deleted(campaign);
    campaign.is_verified = verified
}

public fun set_is_active(campaign: &mut Campaign, cap: &CampaignOwnerCap, is_active: bool) {
    assert_owner(campaign, cap);
    assert_not_deleted(campaign);
    campaign.is_active = is_active
}

public fun assert_not_deleted(campaign: &Campaign) {
    assert!(!campaign.is_deleted, E_CAMPAIGN_DELETED);
}

public fun assert_owner(campaign: &Campaign, cap: &CampaignOwnerCap) {
    assert!(cap.campaign_id == object::id(campaign), E_APP_NOT_AUTHORIZED);
}

public(package) fun mark_deleted(
    campaign: &mut Campaign,
    cap: &CampaignOwnerCap,
    timestamp_ms: u64,
) {
    assert_owner(campaign, cap);
    assert_not_deleted(campaign);
    campaign.is_active = false;
    campaign.is_verified = false;
    campaign.is_deleted = true;
    campaign.deleted_at_ms = std::option::some(timestamp_ms);
}

/// Update campaign active status (activate or deactivate)
/// Only emits event if status actually changes
entry fun update_active_status(
    campaign: &mut Campaign,
    cap: &CampaignOwnerCap,
    new_status: bool,
    clock: &Clock,
    ctx: &tx_context::TxContext,
) {
    // Verify ownership
    assert_owner(campaign, cap);
    assert_not_deleted(campaign);

    // Only update and emit event if status is actually changing
    if (campaign.is_active != new_status) {
        campaign.is_active = new_status;
        let timestamp_ms = clock::timestamp_ms(clock);

        event::emit(CampaignStatusChanged {
            campaign_id: object::id(campaign),
            editor: tx_context::sender(ctx),
            timestamp_ms,
            new_status,
        });
    };
}

entry fun add_update(
    campaign: &mut Campaign,
    cap: &CampaignOwnerCap,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    clock: &Clock,
    ctx: &mut tx_context::TxContext,
) {
    // Verify ownership
    assert_owner(campaign, cap);
    assert_not_deleted(campaign);

    // Ensure key/value vectors align
    assert!(vector::length(&metadata_keys) == vector::length(&metadata_values), E_KEY_VALUE_MISMATCH);

    let sequence = campaign.next_update_seq;
    let timestamp_ms = clock::timestamp_ms(clock);
    let sender = tx_context::sender(ctx);

    // Build metadata once from provided vectors
    let metadata = vec_map::from_keys_values(metadata_keys, metadata_values);

    // Clone metadata for event emission
    let mut event_keys = vector::empty<String>();
    let mut event_values = vector::empty<String>();
    let mut i = 0;
    let len = vec_map::length(&metadata);
    while (i < len) {
        let (key, value) = vec_map::get_entry_by_idx(&metadata, i);
        vector::push_back(&mut event_keys, *key);
        vector::push_back(&mut event_values, *value);
        i = i + 1;
    };
    let metadata_for_event = vec_map::from_keys_values(event_keys, event_values);

    let update = CampaignUpdate {
        id: object::new(ctx),
        parent_id: object::id(campaign),
        sequence,
        author: sender,
        metadata,
        created_at_ms: timestamp_ms,
    };

    let update_id = object::id(&update);

    df::add(&mut campaign.id, UpdateKey { sequence }, update_id);

    campaign.next_update_seq = sequence + 1;

    event::emit(CampaignUpdateAdded {
        campaign_id: object::id(campaign),
        update_id,
        sequence,
        author: sender,
        metadata: metadata_for_event,
        created_at_ms: timestamp_ms,
    });

    transfer::freeze_object(update);
}

/// Update campaign name and/or short description
/// Pass None to keep existing value, Some(new_value) to update
///
/// No string length validation - frontend handles input validation.
/// This is intentional to maximize flexibility at the cost of potential
/// storage overhead.
entry fun update_campaign_basics(
    campaign: &mut Campaign,
    cap: &CampaignOwnerCap,
    new_name: Option<String>,
    new_description: Option<String>,
    clock: &Clock,
    ctx: &tx_context::TxContext,
) {
    assert_owner(campaign, cap);
    assert_not_deleted(campaign);
    let mut name_updated = false;
    let mut description_updated = false;
    if(std::option::is_some(&new_name)) {
        let new_name = std::option::destroy_some(new_name);
        campaign.name = new_name;
        name_updated = true;
    };
    if(std::option::is_some(&new_description)) {
        let new_description = std::option::destroy_some(new_description);
        campaign.short_description = new_description;
        description_updated = true;
    };
    let timestamp_ms = clock::timestamp_ms(clock);
    event::emit(CampaignBasicsUpdated {
        campaign_id: object::id(campaign),
        editor: tx_context::sender(ctx),
        timestamp_ms,
        name_updated,
        description_updated,
    });
}

/// Update campaign metadata (key-value pairs)
/// Funding goal is immutable and cannot be changed
///
/// No limits on metadata size or number of keys - frontend handles validation.
/// This is intentional to maximize flexibility. VecMap updates use get_mut()
/// to preserve insertion order for existing keys.
entry fun update_campaign_metadata(
    campaign: &mut Campaign,
    cap: &CampaignOwnerCap,
    keys: vector<String>,
    values: vector<String>,
    clock: &Clock,
    ctx: &tx_context::TxContext,
) {
    // Verify ownership
    assert_owner(campaign, cap);
    assert_not_deleted(campaign);

    // Verify keys and values have same length
    assert!(vector::length(&keys) == vector::length(&values), E_KEY_VALUE_MISMATCH);

    let mut i = 0;
    while(i < vector::length(&keys)) {
        let key = *vector::borrow(&keys, i);

        // Prevent funding_goal modification
        assert!(key != std::string::utf8(b"funding_goal"), E_FUNDING_GOAL_IMMUTABLE);
        assert!(key != std::string::utf8(b"recipient_address"), E_RECIPIENT_ADDRESS_IMMUTABLE);

        let value = *vector::borrow(&values, i);

        // Update existing key or insert new key
        // Use get_mut to preserve insertion order for existing keys
        if (vec_map::contains(&campaign.metadata, &key)) {
            let value_ref = vec_map::get_mut(&mut campaign.metadata, &key);
            *value_ref = value;
        } else {
            // New key - insert at end
            vec_map::insert(&mut campaign.metadata, key, value);
        };

        i = i + 1;
    };

    let timestamp_ms = clock::timestamp_ms(clock);
    event::emit(CampaignMetadataUpdated {
        campaign_id: object::id(campaign),
        editor: tx_context::sender(ctx),
        timestamp_ms,
        keys_updated: keys,
    });
}

// === View Functions ===

public fun is_verified(campaign: &Campaign): bool {
    campaign.is_verified
}

public fun is_active(campaign: &Campaign): bool {
    campaign.is_active
}

public fun is_deleted(campaign: &Campaign): bool {
    campaign.is_deleted
}

public fun deleted_at_ms(campaign: &Campaign): std::option::Option<u64> {
    campaign.deleted_at_ms
}

public fun admin_id(campaign: &Campaign): object::ID {
    campaign.admin_id
}

public fun update_count(campaign: &Campaign): u64 {
    campaign.next_update_seq
}

public fun created_at_ms(campaign: &Campaign): u64 {
    campaign.created_at_ms
}

public fun get_update_id(campaign: &Campaign, sequence: u64): object::ID {
    *df::borrow(&campaign.id, UpdateKey { sequence })
}

public fun has_update(campaign: &Campaign, sequence: u64): bool {
    df::exists_(&campaign.id, UpdateKey { sequence })
}

public fun try_get_update_id(
    campaign: &Campaign,
    sequence: u64,
): Option<object::ID> {
    if (has_update(campaign, sequence)) {
        std::option::some(*df::borrow(&campaign.id, UpdateKey { sequence }))
    } else {
        std::option::none()
    }
}

public fun update_parent_id(update: &CampaignUpdate): object::ID {
    update.parent_id
}

public fun update_sequence(update: &CampaignUpdate): u64 {
    update.sequence
}

public fun update_author(update: &CampaignUpdate): address {
    update.author
}

public fun update_created_at_ms(update: &CampaignUpdate): u64 {
    update.created_at_ms
}

public fun update_metadata(update: &CampaignUpdate): &VecMap<String, String> {
    &update.metadata
}
