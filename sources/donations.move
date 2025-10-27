module crowd_walrus::donations;

use crowd_walrus::token_registry::{Self as token_registry};

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
        if (override_value == 0 || override_value >= registry_max) {
            registry_max
        } else {
            override_value
        }
    }
}
