module crowd_walrus::campaign;

use std::string::String;

public struct Campaign has key, store {
    id: UID,
    admin_id: ID,
    name: String,
    description: String,
    subdomain_name: String,
    created_at: u64,
}

public struct CampaignOwnerCap has key, store {
    id: UID,
    campaign_id: ID,
}

public(package) fun new(
    admin_id: ID,
    name: String,
    description: String,
    subdomain_name: String,
    ctx: &mut TxContext,
): (ID, CampaignOwnerCap) {
    let campaign = Campaign {
        id: object::new(ctx),
        admin_id,
        name,
        description,
        subdomain_name,
        created_at: tx_context::epoch(ctx),
    };

    let campaign_id = object::id(&campaign);
    let campaign_owner_cap = CampaignOwnerCap {
        id: object::new(ctx),
        campaign_id,
    };

    transfer::share_object(campaign);
    (campaign_id, campaign_owner_cap)
}

public fun subdomain_name(campaign: &Campaign): String {
    campaign.subdomain_name
}

public fun campaign_id(campaign_owner_cap: &CampaignOwnerCap): ID {
    campaign_owner_cap.campaign_id
}
