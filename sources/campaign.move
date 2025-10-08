module crowd_walrus::campaign;

use std::string::String;
use sui::clock::{Self as clock, Clock};
use sui::dynamic_field as df;
use sui::vec_map::{Self, VecMap};
use sui::event;
// === Error Codes ===
const E_APP_NOT_AUTHORIZED: u64 = 1;
// Error codes 2-3 reserved for future use
const E_KEY_VALUE_MISMATCH: u64 = 4;
const E_INVALID_DATE_RANGE: u64 = 5;
const E_START_DATE_IN_PAST: u64 = 6;
const E_FUNDING_GOAL_IMMUTABLE: u64 = 8;
const E_RECIPIENT_ADDRESS_INVALID: u64 = 9;
const E_RECIPIENT_ADDRESS_IMMUTABLE: u64 = 10;

// === Error Code Accessors ===
public fun e_start_date_in_past(): u64 { E_START_DATE_IN_PAST }

public struct Campaign has key, store {
    id: UID,
    admin_id: ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    metadata: VecMap<String, String>,
    recipient_address: address, // Immutable - where donations are sent
    start_date: u64,
    end_date: u64,
    created_at: u64,
    validated: bool,
    isActive: bool,
    updates: vector<CampaignUpdate>,
}

public struct CampaignUpdate has copy, drop, store {
    title: String,
    short_description: String,
    metadata: VecMap<String, String>,
    created_at: u64,
}

public struct CampaignOwnerCap has key, store {
    id: UID,
    campaign_id: ID,
}

// === Events ===
public struct CampaignUpdateAdded has copy, drop {
    campaign_id: ID,
    update: CampaignUpdate,
}

public struct CampaignBasicsUpdated has copy, drop {
    campaign_id: ID,
    editor: address,
    timestamp_ms: u64,
    name_updated: bool,
    description_updated: bool,
}

public struct CampaignMetadataUpdated has copy, drop {
    campaign_id: ID,
    editor: address,
    timestamp_ms: u64,
    keys_updated: vector<String>,
}

public struct CampaignStatusChanged has copy, drop {
    campaign_id: ID,
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
public fun authorize_app<App: drop>(self: &mut Campaign, _: &CampaignOwnerCap) {
    df::add(&mut self.id, AppKey<App> {}, true);
}

/// Deauthorize an application by removing its authorization key.
public fun deauthorize_app<App: drop>(self: &mut Campaign, _: &CampaignOwnerCap): bool {
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
/// - Recipient address non-zero - frontend handles
///
/// This is intentional to maximize flexibility.
public(package) fun new<App: drop>(
    _: &App,
    admin_id: ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    metadata: VecMap<String, String>,
    recipient_address: address,
    start_date: u64,
    end_date: u64,
    ctx: &mut TxContext,
): (ID, CampaignOwnerCap) {
    // Validate date range
    assert!(start_date < end_date, E_INVALID_DATE_RANGE);
    assert!(recipient_address != @0x0, E_RECIPIENT_ADDRESS_INVALID);

    let mut campaign = Campaign {
        id: object::new(ctx),
        admin_id,
        name,
        short_description,
        subdomain_name,
        metadata,
        recipient_address,
        start_date,
        end_date,
        created_at: tx_context::epoch(ctx),
        validated: false,
        isActive: true,
        updates: vector::empty(),
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

public fun subdomain_name(campaign: &Campaign): String {
    campaign.subdomain_name
}

public fun metadata(campaign: &Campaign): VecMap<String, String> {
    campaign.metadata
}

public fun campaign_id(campaign_owner_cap: &CampaignOwnerCap): ID {
    campaign_owner_cap.campaign_id
}

public fun set_validated<App: drop>(campaign: &mut Campaign, _: &App, validated: bool) {
    campaign.assert_app_is_authorized<App>();
    campaign.validated = validated
}

public fun set_is_active(campaign: &mut Campaign, _: &CampaignOwnerCap, isActive: bool) {
    campaign.isActive = isActive
}

/// Update campaign active status (activate or deactivate)
/// Only emits event if status actually changes
entry fun update_active_status(
    campaign: &mut Campaign,
    cap: &CampaignOwnerCap,
    new_status: bool,
    clock: &Clock,
    ctx: &TxContext,
) {
    // Verify ownership
    assert!(cap.campaign_id == object::id(campaign), E_APP_NOT_AUTHORIZED);

    // Only update and emit event if status is actually changing
    if (campaign.isActive != new_status) {
        campaign.isActive = new_status;

        event::emit(CampaignStatusChanged {
            campaign_id: object::id(campaign),
            editor: tx_context::sender(ctx),
            timestamp_ms: clock::timestamp_ms(clock),
            new_status,
        });
    };
}

entry fun add_update(
    campaign: &mut Campaign,
    _: &CampaignOwnerCap,
    title: String,
    short_description: String,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    ctx: &TxContext,
) {
    let metadata = vec_map::from_keys_values(metadata_keys, metadata_values);
    let update = CampaignUpdate {
        title,
        short_description,
        metadata,
        created_at: tx_context::epoch(ctx),
    };
    vector::push_back(&mut campaign.updates, update);
    sui::event::emit(CampaignUpdateAdded {
        campaign_id: object::id(campaign),
        update,
    });
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
    ctx: &TxContext,
) {
    assert!(cap.campaign_id == object::id(campaign), E_APP_NOT_AUTHORIZED);
    let mut name_updated = false;
    let mut description_updated = false;
    if(option::is_some(&new_name)) {
        let new_name = option::destroy_some(new_name);
        campaign.name = new_name;
        name_updated = true;
    };
    if(option::is_some(&new_description)) {
        let new_description = option::destroy_some(new_description);
        campaign.short_description = new_description;
        description_updated = true;
    };
    event::emit(CampaignBasicsUpdated {
        campaign_id: object::id(campaign),
        editor: tx_context::sender(ctx),
        timestamp_ms: clock::timestamp_ms(clock),
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
    ctx: &TxContext,
) {
    // Verify ownership
    assert!(cap.campaign_id == object::id(campaign), E_APP_NOT_AUTHORIZED);

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

    event::emit(CampaignMetadataUpdated {
        campaign_id: object::id(campaign),
        editor: tx_context::sender(ctx),
        timestamp_ms: clock::timestamp_ms(clock),
        keys_updated: keys,
    });
}

// === View Functions ===

public fun is_validated(campaign: &Campaign): bool {
    campaign.validated
}

public fun is_active(campaign: &Campaign): bool {
    campaign.isActive
}

public fun updates(campaign: &Campaign): vector<CampaignUpdate> {
    campaign.updates
}
