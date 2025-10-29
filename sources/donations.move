module crowd_walrus::donations;

use crowd_walrus::campaign::{Self as campaign};
use crowd_walrus::token_registry::{Self as token_registry};
use std::u64;
use sui::clock::{Self as clock, Clock};

const E_CAMPAIGN_INACTIVE: u64 = 1;
const E_CAMPAIGN_CLOSED: u64 = 2;
const E_TOKEN_DISABLED: u64 = 3;

/// Early validation ensuring campaign status, timing, and token availability before processing a donation.
public fun precheck<T>(
    campaign: &campaign::Campaign,
    registry: &token_registry::TokenRegistry,
    clock: &Clock,
) {
    campaign::assert_not_deleted(campaign);
    assert!(campaign::is_active(campaign), E_CAMPAIGN_INACTIVE);

    let now = clock::timestamp_ms(clock);
    let start = campaign::start_date(campaign);
    let end = campaign::end_date(campaign);
    assert!(now >= start, E_CAMPAIGN_CLOSED);
    assert!(now <= end, E_CAMPAIGN_CLOSED);

    assert!(token_registry::contains<T>(registry), E_TOKEN_DISABLED);
    assert!(token_registry::is_enabled<T>(registry), E_TOKEN_DISABLED);
}

/// Returns the effective staleness budget for a donation, honoring donor overrides when tighter than
/// the registry default. Tokens must exist and be enabled before we quote prices.
public fun effective_max_age_ms<T>(
    registry: &token_registry::TokenRegistry,
    override_ms: std::option::Option<u64>,
): u64 {
    token_registry::require_enabled<T>(registry);
    let registry_max = token_registry::max_age_ms<T>(registry);

    if (!std::option::is_some(&override_ms)) {
        registry_max
    } else {
        let override_value = std::option::destroy_some(override_ms);
        if (override_value == 0) {
            registry_max
        } else {
            u64::min(registry_max, override_value)
        }
    }
}
