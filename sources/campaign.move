module crowd_walrus::campaign;

use std::string::String;
use sui::dynamic_field as df;
use sui::vec_map::{Self, VecMap};

const E_APP_NOT_AUTHORIZED: u64 = 1;

public struct Campaign has key, store {
    id: UID,
    admin_id: ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    metadata: VecMap<String, String>,
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

public(package) fun new<App: drop>(
    _: &App,
    admin_id: ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    metadata: VecMap<String, String>,
    start_date: u64,
    end_date: u64,
    ctx: &mut TxContext,
): (ID, CampaignOwnerCap) {
    let mut campaign = Campaign {
        id: object::new(ctx),
        admin_id,
        name,
        short_description,
        subdomain_name,
        metadata,
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
