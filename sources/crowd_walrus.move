module crowd_walrus::crowd_walrus;

use crowd_walrus::badge_rewards::{Self as badge_rewards};
use crowd_walrus::campaign::{Self as campaign};
use crowd_walrus::campaign_stats::{Self as campaign_stats};
use crowd_walrus::platform_policy::{Self as platform_policy};
use crowd_walrus::token_registry::{Self as token_registry};
use crowd_walrus::profiles::{Self as profiles};
use crowd_walrus::suins_manager::{Self as suins_manager, SuiNSManager, register_subdomain};
use std::string::{Self as string, String};
use sui::clock::{Self as clock, Clock};
use sui::dynamic_field::{Self as df};
use sui::event::{Self as event};
use sui::object::{Self as sui_object};
use sui::package;
use sui::tx_context::{Self as sui_tx_context};
use sui::vec_map::{Self as vec_map};
use suins::suins::SuiNS;

public struct CROWD_WALRUS has drop {}
/// Authorization token for the app.
public struct CrowdWalrusApp has drop {}

// === Errors ===

const E_NOT_AUTHORIZED: u64 = 1;
const E_ALREADY_VERIFIED: u64 = 2;
const E_NOT_VERIFIED: u64 = 3;
const E_TOKEN_REGISTRY_NOT_INITIALIZED: u64 = 4;

const DEFAULT_POLICY_NAME: vector<u8> = b"standard";

fun default_policy_name_internal(): String {
    string::utf8(DEFAULT_POLICY_NAME)
}

/// Returns the name of the preset used when campaign creators omit a policy.
public fun default_policy_name(): String {
    default_policy_name_internal()
}

// === Events ===
public struct CampaignCreated has copy, drop {
    campaign_id: sui_object::ID,
    creator: address,
}

// === Structs ===

/// The crowd walrus object
public struct CrowdWalrus has key, store {
    id: sui_object::UID,
    /// Shared policy presets registry ObjectID created at publish time.
    policy_registry_id: sui_object::ID,
    /// Shared profiles registry ObjectID created at publish time.
    profiles_registry_id: sui_object::ID,
    /// Shared badge configuration ObjectID created at publish time.
    /// Note: Created empty; platform admins must configure thresholds and URIs before badge minting.
    badge_config_id: sui_object::ID,
}

/// Capability for admin operations
public struct AdminCap has key, store {
    id: sui_object::UID,
    crowd_walrus_id: sui_object::ID,
}

/// Capability for verifying admin operations
public struct VerifyCap has key, store {
    id: sui_object::UID,
    crowd_walrus_id: sui_object::ID,
}

// === Events ====

public struct AdminCreated has copy, drop {
    crowd_walrus_id: sui_object::ID,
    admin_id: sui_object::ID,
    creator: address,
}

public struct CampaignVerified has copy, drop {
    campaign_id: sui_object::ID,
    verifier: address,
}

public struct CampaignDeleted has copy, drop {
    campaign_id: sui_object::ID,
    editor: address,
    timestamp_ms: u64,
}

public struct PolicyRegistryCreated has copy, drop {
    crowd_walrus_id: sui_object::ID,
    policy_registry_id: sui_object::ID,
}

public struct ProfilesRegistryCreated has copy, drop {
    crowd_walrus_id: sui_object::ID,
    profiles_registry_id: sui_object::ID,
}

public struct TokenRegistryCreated has copy, drop {
    crowd_walrus_id: sui_object::ID,
    token_registry_id: sui_object::ID,
}

public struct BadgeConfigCreated has copy, drop {
    crowd_walrus_id: sui_object::ID,
    badge_config_id: sui_object::ID,
}

public struct TokenRegistryKey has copy, drop, store {}

public struct TokenRegistrySlot has store {
    id: sui_object::ID,
}

// === Init Function ===

/// Initialize the crowd walrus
fun init(otw: CROWD_WALRUS, ctx: &mut sui_tx_context::TxContext) {
    package::claim_and_keep(otw, ctx);
    let crowd_walrus_uid = sui_object::new(ctx);
    let crowd_walrus_id = sui_object::uid_to_inner(&crowd_walrus_uid);

    let mut policy_registry = platform_policy::create_registry(crowd_walrus_id, ctx);
    platform_policy::add_policy_bootstrap(
        &mut policy_registry,
        default_policy_name_internal(),
        0,
        sui_tx_context::sender(ctx),
    );
    // Persist the registry sui_object::ID so admins can resolve it without replaying events.
    let policy_registry_id = sui_object::id(&policy_registry);
    platform_policy::share_registry(policy_registry);
    let token_registry = token_registry::create_registry(crowd_walrus_id, ctx);
    let token_registry_id = sui_object::id(&token_registry);
    token_registry::share_registry(token_registry);
    let profiles_registry = profiles::create_registry(ctx);
    let profiles_registry_id = sui_object::id(&profiles_registry);
    profiles::share_registry(profiles_registry);
    let badge_config = badge_rewards::create_config(crowd_walrus_id, ctx);
    let badge_config_id = sui_object::id(&badge_config);
    badge_rewards::share_config(badge_config);

    let mut crowd_walrus = CrowdWalrus {
        id: crowd_walrus_uid,
        policy_registry_id,
        profiles_registry_id,
        badge_config_id,
    };
    record_token_registry_id(&mut crowd_walrus, token_registry_id);

    // Create admin capability for the creator
    let admin_cap = AdminCap {
        id: sui_object::new(ctx),
        crowd_walrus_id,
    };

    // Emit creation event
    event::emit(AdminCreated {
        crowd_walrus_id,
        admin_id: sui_object::id(&admin_cap),
        creator: sui_tx_context::sender(ctx),
    });
    // Announce the shared registry to indexers and deployment tooling.
    event::emit(PolicyRegistryCreated {
        crowd_walrus_id,
        policy_registry_id,
    });
    event::emit(ProfilesRegistryCreated {
        crowd_walrus_id,
        profiles_registry_id,
    });
    event::emit(TokenRegistryCreated {
        crowd_walrus_id,
        token_registry_id,
    });
    event::emit(BadgeConfigCreated {
        crowd_walrus_id,
        badge_config_id,
    });

    // Transfer capability to creator
    transfer::transfer(admin_cap, sui_tx_context::sender(ctx));

    // Share crowd walrus object with creator
    transfer::share_object(crowd_walrus);
    let (_, suins_manager_cap) = suins_manager::new(
        &CrowdWalrusApp {},
        ctx,
    );

    transfer::public_transfer(suins_manager_cap, sui_tx_context::sender(ctx));
}

// === Public Functions ===

/// Register a new campaign using a preset payout policy.
///
/// Payout policy resolution rules:
/// - If `policy_name` is `std::option::Option::Some`, the preset is resolved from `policy_registry`
///   and its values are copied into the campaign.
/// - If `policy_name` is `std::option::Option::None`, the default preset (`"standard"`) seeded
///   during initialization is resolved from `policy_registry` and copied into the campaign instead.
///   This call aborts if that preset has been removed or disabled by admins.
entry fun create_campaign(
    crowd_walrus: &CrowdWalrus,
    policy_registry: &platform_policy::PolicyRegistry,
    profiles_registry: &mut profiles::ProfilesRegistry,
    suins_manager: &SuiNSManager,
    suins: &mut SuiNS,
    clock: &Clock,
    name: String,
    short_description: String,
    subdomain_name: String,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    funding_goal_usd_micro: u64,
    recipient_address: address,
    policy_name: std::option::Option<String>,
    start_date: u64,
    end_date: u64,
    ctx: &mut sui_tx_context::TxContext,
): sui_object::ID {
    // Ensure start_date is not in the past
    let current_time_ms = clock::timestamp_ms(clock);
    assert!(start_date >= current_time_ms, campaign::e_start_date_in_past());

    // register subname
    let app = CrowdWalrusApp {};
    let metadata = vec_map::from_keys_values(metadata_keys, metadata_values);
    assert!(
        sui_object::id(policy_registry) == policy_registry_id(crowd_walrus),
        E_NOT_AUTHORIZED,
    );
    assert!(recipient_address != @0x0, campaign::e_recipient_address_invalid());
    let payout_policy = resolve_payout_policy(
        policy_registry,
        policy_name,
        recipient_address,
    );

    let (mut campaign_obj, campaign_owner_cap) = campaign::new(
        &app,
        sui_object::id(crowd_walrus),
        name,
        short_description,
        subdomain_name,
        metadata,
        funding_goal_usd_micro,
        payout_policy,
        start_date,
        end_date,
        clock,
        ctx,
    );
    let campaign_id = sui_object::id(&campaign_obj);
    assert!(
        sui_object::id(profiles_registry) == profiles_registry_id(crowd_walrus),
        E_NOT_AUTHORIZED,
    );
    let _stats_id = campaign_stats::create_for_campaign(
        &mut campaign_obj,
        clock,
        ctx,
    );
    let _profile_id = profiles::create_or_get_profile_for_sender(
        profiles_registry,
        clock,
        ctx,
    );
    suins_manager.register_subdomain(
        &app,
        suins,
        clock,
        subdomain_name,
        campaign_id.to_address(),
        ctx,
    );
    campaign::share(campaign_obj);

    transfer::public_transfer(campaign_owner_cap, sui_tx_context::sender(ctx));
    event::emit(CampaignCreated {
        campaign_id,
        creator: sui_tx_context::sender(ctx),
    });
    campaign_id
}

fun set_profile_subdomain_internal(
    profile: &mut profiles::Profile,
    suins_manager: &SuiNSManager,
    suins: &mut SuiNS,
    subdomain_name: String,
    clock: &Clock,
    ctx: &mut sui_tx_context::TxContext,
) {
    let sender = sui_tx_context::sender(ctx);
    assert!(profiles::owner(profile) == sender, profiles::not_profile_owner_error_code());
    profiles::assert_subdomain_not_set(profile);

    let app = CrowdWalrusApp {};

    let profile_id = sui_object::id(profile);
    let subdomain_for_event = copy subdomain_name;

    register_subdomain(
        suins_manager,
        &app,
        suins,
        clock,
        copy subdomain_name,
        profile_id.to_address(),
        ctx,
    );

    profiles::set_subdomain(profile, subdomain_name);

    profiles::emit_profile_subdomain_set(
        profile_id,
        sender,
        subdomain_for_event,
        clock::timestamp_ms(clock),
    );
}

/// PTB-friendly helper so callers can compose profile creation,
/// metadata updates, and SuiNS subdomain registration within a single
/// transaction while holding the Profile by value.
public fun set_profile_subdomain_public(
    profile: &mut profiles::Profile,
    suins_manager: &SuiNSManager,
    suins: &mut SuiNS,
    subdomain_name: String,
    clock: &Clock,
    ctx: &mut sui_tx_context::TxContext,
) {
    set_profile_subdomain_internal(
        profile,
        suins_manager,
        suins,
        subdomain_name,
        clock,
        ctx,
    );
}

/// Set a SuiNS subdomain for a profile. Subdomains are immutable for the owner once set.
entry fun set_profile_subdomain(
    profile: &mut profiles::Profile,
    suins_manager: &SuiNSManager,
    suins: &mut SuiNS,
    subdomain_name: String,
    clock: &Clock,
    ctx: &mut sui_tx_context::TxContext,
) {
    set_profile_subdomain_internal(
        profile,
        suins_manager,
        suins,
        subdomain_name,
        clock,
        ctx,
    );
}

/// Admin-only removal of a profile's subdomain. Owners cannot clear or change their subdomain once set.
entry fun remove_profile_subdomain(
    suins_manager: &SuiNSManager,
    admin_cap: &suins_manager::AdminCap,
    suins: &mut SuiNS,
    profile: &mut profiles::Profile,
    clock: &Clock,
    ctx: &sui_tx_context::TxContext,
) {
    let sender = sui_tx_context::sender(ctx);
    let subdomain_opt = profiles::subdomain_name(profile);
    assert!(std::option::is_some(&subdomain_opt), profiles::subdomain_not_set_error_code());
    let subdomain_name = std::option::destroy_some(subdomain_opt);
    let subdomain_for_event = copy subdomain_name;

    suins_manager::remove_subdomain(
        suins_manager,
        admin_cap,
        suins,
        subdomain_name,
        clock,
    );

    profiles::clear_subdomain(profile);

    profiles::emit_profile_subdomain_removed(
        sui_object::id(profile),
        profiles::owner(profile),
        subdomain_for_event,
        clock::timestamp_ms(clock),
        sender,
    );
}

fun resolve_payout_policy(
    policy_registry: &platform_policy::PolicyRegistry,
    policy_name_opt: std::option::Option<String>,
    recipient_address: address,
): campaign::PayoutPolicy {
    if (std::option::is_some(&policy_name_opt)) {
        let policy_name = std::option::destroy_some(policy_name_opt);
        let preset = platform_policy::require_enabled_policy(policy_registry, &policy_name);
        return campaign::new_payout_policy(
            platform_policy::policy_platform_bps(preset),
            platform_policy::policy_platform_address(preset),
            recipient_address,
        )
    };
    let default_policy_name = default_policy_name_internal();
    let preset = platform_policy::require_enabled_policy(policy_registry, &default_policy_name);
    campaign::new_payout_policy(
        platform_policy::policy_platform_bps(preset),
        platform_policy::policy_platform_address(preset),
        recipient_address,
    )
}

/// Verify a campaign
entry fun verify_campaign(
    crowd_walrus: &CrowdWalrus,
    cap: &VerifyCap,
    campaign: &mut campaign::Campaign,
    ctx: &sui_tx_context::TxContext,
) {
    let campaign_id = sui_object::id(campaign);

    assert!(sui_object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);
    assert!(!campaign::is_verified(campaign), E_ALREADY_VERIFIED);
    campaign::assert_not_deleted(campaign);

    campaign::set_verified(campaign, &CrowdWalrusApp {}, true);

    // event
    event::emit(CampaignVerified {
        campaign_id,
        verifier: sui_tx_context::sender(ctx),
    });
}

entry fun unverify_campaign(
    crowd_walrus: &CrowdWalrus,
    cap: &VerifyCap,
    campaign: &mut campaign::Campaign,
    ctx: &sui_tx_context::TxContext,
) {

    assert!(sui_object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);
    assert!(campaign::is_verified(campaign), E_NOT_VERIFIED);

    campaign::set_verified(campaign, &CrowdWalrusApp {}, false);

    campaign::emit_campaign_unverified(campaign, sui_tx_context::sender(ctx));
}

entry fun delete_campaign(
    crowd_walrus: &CrowdWalrus,
    suins_manager: &SuiNSManager,
    suins: &mut SuiNS,
    campaign: &mut campaign::Campaign,
    cap: campaign::CampaignOwnerCap,
    clock: &Clock,
    ctx: &sui_tx_context::TxContext,
) {
    let campaign_id = sui_object::id(campaign);

    assert!(campaign::admin_id(campaign) == sui_object::id(crowd_walrus), E_NOT_AUTHORIZED);
    campaign::assert_owner(campaign, &cap);
    campaign::assert_not_deleted(campaign);

    let deleted_at_ms = clock::timestamp_ms(clock);
    let subdomain_name = campaign::subdomain_name(campaign);

    if (campaign::is_verified(campaign)) {
        campaign::set_verified(campaign, &CrowdWalrusApp {}, false);
        campaign::emit_campaign_unverified(campaign, sui_tx_context::sender(ctx));
    };

    suins_manager::remove_subdomain_for_app<CrowdWalrusApp>(
        suins_manager,
        &CrowdWalrusApp {},
        suins,
        clock,
        subdomain_name,
    );

    campaign::mark_deleted(campaign, &cap, deleted_at_ms);

    event::emit(CampaignDeleted {
        campaign_id,
        editor: sui_tx_context::sender(ctx),
        timestamp_ms: deleted_at_ms,
    });

    campaign::delete_owner_cap(cap);
}

// === Admin Functions ===
/// Add dynamic field for extensibility
public fun add_field<K: copy + drop + store, V: store>(
    crowd_walrus: &mut CrowdWalrus,
    cap: &AdminCap,
    key: K,
    value: V,
) {
    assert!(sui_object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);

    df::add(&mut crowd_walrus.id, key, value);
}

/// Remove dynamic field
public fun remove_field<K: copy + drop + store, V: store>(
    crowd_walrus: &mut CrowdWalrus,
    cap: &AdminCap,
    key: K,
): V {
    assert!(sui_object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);

    df::remove(&mut crowd_walrus.id, key)
}

/// Create a verification capability for a new verifier
entry fun create_verify_cap(
    crowd_walrus: &CrowdWalrus,
    cap: &AdminCap,
    new_verifier: address,
    ctx: &mut sui_tx_context::TxContext,
) {
    assert!(sui_object::id(crowd_walrus) == cap.crowd_walrus_id, E_NOT_AUTHORIZED);

    transfer::transfer(
        VerifyCap {
            id: sui_object::new(ctx),
            crowd_walrus_id: sui_object::id(crowd_walrus),
        },
        new_verifier,
    )
}

// === View Functions ===
/// Get Admin Cap crowd_walrus_id
public fun crowd_walrus_id(cap: &AdminCap): sui_object::ID {
    cap.crowd_walrus_id
}

fun token_registry_key(): TokenRegistryKey {
    TokenRegistryKey {}
}

fun record_token_registry_id(crowd_walrus: &mut CrowdWalrus, token_registry_id: sui_object::ID) {
    df::add(
        &mut crowd_walrus.id,
        token_registry_key(),
        TokenRegistrySlot { id: token_registry_id },
    );
}

fun borrow_token_registry_slot(crowd_walrus: &CrowdWalrus): &TokenRegistrySlot {
    df::borrow(&crowd_walrus.id, token_registry_key())
}

/// Get the shared PolicyRegistry sui_object::ID managed by this CrowdWalrus instance.
public fun policy_registry_id(crowd_walrus: &CrowdWalrus): sui_object::ID {
    crowd_walrus.policy_registry_id
}

/// Get the shared ProfilesRegistry sui_object::ID managed by this CrowdWalrus instance.
public fun profiles_registry_id(crowd_walrus: &CrowdWalrus): sui_object::ID {
    crowd_walrus.profiles_registry_id
}

/// Get the shared BadgeConfig sui_object::ID managed by this CrowdWalrus instance.
public fun badge_config_id(crowd_walrus: &CrowdWalrus): sui_object::ID {
    crowd_walrus.badge_config_id
}

/// Get the shared TokenRegistry sui_object::ID managed by this CrowdWalrus instance.
public fun token_registry_id(crowd_walrus: &CrowdWalrus): sui_object::ID {
    assert!(
        df::exists_(&crowd_walrus.id, token_registry_key()),
        E_TOKEN_REGISTRY_NOT_INITIALIZED,
    );
    borrow_token_registry_slot(crowd_walrus).id
}

/// Check if a campaign is verified
public fun is_campaign_verified(_crowd_walrus: &CrowdWalrus, campaign: &campaign::Campaign): bool {
    campaign::is_verified(campaign)
}

#[test]
public fun test_init_function() {
    use sui::test_scenario::{Self as ts, ctx};
    let publisher_address: address = @0xA;
    let mut scenario = ts::begin(publisher_address);

    init(CROWD_WALRUS {}, ctx(&mut scenario));

    scenario.next_tx(publisher_address);

    let crowd_walrus = scenario.take_shared<CrowdWalrus>();
    let crowd_walrus_cap = scenario.take_from_sender<AdminCap>();
    assert!(sui_object::id(&crowd_walrus) == crowd_walrus_cap.crowd_walrus_id);

    let policy_registry = scenario.take_shared<platform_policy::PolicyRegistry>();
    let profiles_registry = scenario.take_shared<profiles::ProfilesRegistry>();
    let token_registry = scenario.take_shared<token_registry::TokenRegistry>();
    let badge_config = scenario.take_shared<badge_rewards::BadgeConfig>();
    // Ensure the stored registry sui_object::ID matches the shared object we just fetched.
    assert!(sui_object::id(&policy_registry) == policy_registry_id(&crowd_walrus));
    assert!(sui_object::id(&profiles_registry) == profiles_registry_id(&crowd_walrus));
    assert!(sui_object::id(&token_registry) == token_registry_id(&crowd_walrus));
    assert!(sui_object::id(&badge_config) == badge_config_id(&crowd_walrus));

    let suins_manager_cap = scenario.take_from_sender<suins_manager::AdminCap>();
    let suins_manager = scenario.take_shared<suins_manager::SuiNSManager>();

    assert!(suins_manager.is_app_authorized<CrowdWalrusApp>());

    // clean up
    scenario.return_to_sender(crowd_walrus_cap);
    ts::return_shared(policy_registry);
    ts::return_shared(profiles_registry);
    ts::return_shared(token_registry);
    ts::return_shared(badge_config);
    scenario.return_to_sender(suins_manager_cap);
    ts::return_shared(crowd_walrus);
    ts::return_shared(suins_manager);

    scenario.end();
}

#[test]
public fun test_migrate_token_registry_creates_when_missing() {
    use sui::test_scenario::{Self as ts, ctx};
    let admin: address = @0xA;
    let mut scenario = ts::begin(admin);

    scenario.next_tx(admin);

    let crowd_walrus_uid = sui_object::new(ctx(&mut scenario));
    let crowd_walrus_id = sui_object::uid_to_inner(&crowd_walrus_uid);

    let mut policy_registry = platform_policy::create_registry(crowd_walrus_id, ctx(&mut scenario));
    platform_policy::add_policy_bootstrap(
        &mut policy_registry,
        default_policy_name_internal(),
        0,
        admin,
    );
    let policy_registry_id = sui_object::id(&policy_registry);
    platform_policy::share_registry(policy_registry);

    let profiles_registry = profiles::create_registry(ctx(&mut scenario));
    let profiles_registry_id = sui_object::id(&profiles_registry);
    profiles::share_registry(profiles_registry);
    let badge_config = badge_rewards::create_config(crowd_walrus_id, ctx(&mut scenario));
    let badge_config_id = sui_object::id(&badge_config);
    badge_rewards::share_config(badge_config);

    let crowd_walrus = CrowdWalrus {
        id: crowd_walrus_uid,
        policy_registry_id,
        profiles_registry_id,
        badge_config_id,
    };
    transfer::share_object(crowd_walrus);

    let admin_cap = AdminCap {
        id: sui_object::new(ctx(&mut scenario)),
        crowd_walrus_id,
    };
    transfer::transfer(admin_cap, admin);

    ts::next_tx(&mut scenario, admin);

    let mut crowd_walrus = scenario.take_shared<CrowdWalrus>();
    let admin_cap = scenario.take_from_sender<AdminCap>();

    migrate_token_registry(&mut crowd_walrus, &admin_cap, ctx(&mut scenario));

    assert!(df::exists_(&crowd_walrus.id, token_registry_key()));
    let slot = borrow_token_registry_slot(&crowd_walrus);
    let new_registry_id = slot.id;

    scenario.return_to_sender(admin_cap);
    ts::return_shared(crowd_walrus);

    ts::next_tx(&mut scenario, admin);

    let new_registry = scenario.take_shared_by_id<token_registry::TokenRegistry>(new_registry_id);
    ts::return_shared(new_registry);
    scenario.end();
}

#[test_only]
public fun get_app(): CrowdWalrusApp {
    CrowdWalrusApp {}
}

#[test_only]
public fun create_and_share_crowd_walrus(ctx: &mut sui_tx_context::TxContext): sui_object::ID {
    let crowd_walrus_uid = sui_object::new(ctx);
    let crowd_walrus_id = sui_object::uid_to_inner(&crowd_walrus_uid);
    let mut policy_registry = platform_policy::create_registry(crowd_walrus_id, ctx);
    platform_policy::add_policy_bootstrap(
        &mut policy_registry,
        default_policy_name_internal(),
        0,
        sui_tx_context::sender(ctx),
    );
    let policy_registry_id = sui_object::id(&policy_registry);
    platform_policy::share_registry(policy_registry);
    let token_registry = token_registry::create_registry(crowd_walrus_id, ctx);
    let token_registry_id = sui_object::id(&token_registry);
    token_registry::share_registry(token_registry);
    let profiles_registry = profiles::create_registry(ctx);
    let profiles_registry_id = sui_object::id(&profiles_registry);
    profiles::share_registry(profiles_registry);
    let badge_config = badge_rewards::create_config(crowd_walrus_id, ctx);
    let badge_config_id = sui_object::id(&badge_config);
    badge_rewards::share_config(badge_config);

    let mut crowd_walrus = CrowdWalrus {
        id: crowd_walrus_uid,
        policy_registry_id,
        profiles_registry_id,
        badge_config_id,
    };
    record_token_registry_id(&mut crowd_walrus, token_registry_id);
    transfer::share_object(crowd_walrus);
    crowd_walrus_id
}

#[test_only]
public fun create_admin_cap_for_user(crowd_walrus_id: sui_object::ID, user: address, ctx: &mut sui_tx_context::TxContext): sui_object::ID {
    let admin_cap = AdminCap {
        id: sui_object::new(ctx),
        crowd_walrus_id: crowd_walrus_id,
    };
    let admin_cap_id = sui_object::id(&admin_cap);
    transfer::transfer(admin_cap, user);
    admin_cap_id
}

public(package) fun add_platform_policy_internal(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    platform_bps: u16,
    platform_address: address,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, platform_policy::registry_owner_id(registry));
    platform_policy::add_policy(
        registry,
        name,
        platform_bps,
        platform_address,
        clock,
    );
}

entry fun add_platform_policy(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    platform_bps: u16,
    platform_address: address,
    clock: &Clock,
    _ctx: &mut sui_tx_context::TxContext,
) {
    // Entry wrapper allows direct PTB invocation; logic lives in the internal helper for reuse.
    add_platform_policy_internal(registry, admin_cap, name, platform_bps, platform_address, clock);
}

public(package) fun update_platform_policy_internal(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    platform_bps: u16,
    platform_address: address,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, platform_policy::registry_owner_id(registry));
    platform_policy::update_policy(
        registry,
        name,
        platform_bps,
        platform_address,
        clock,
    );
}

entry fun update_platform_policy(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    platform_bps: u16,
    platform_address: address,
    clock: &Clock,
    _ctx: &mut sui_tx_context::TxContext,
) {
    update_platform_policy_internal(registry, admin_cap, name, platform_bps, platform_address, clock);
}

public(package) fun disable_platform_policy_internal(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, platform_policy::registry_owner_id(registry));
    platform_policy::disable_policy(registry, name, clock);
}

entry fun disable_platform_policy(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    clock: &Clock,
    _ctx: &mut sui_tx_context::TxContext,
) {
    disable_platform_policy_internal(registry, admin_cap, name, clock);
}

public(package) fun enable_platform_policy_internal(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, platform_policy::registry_owner_id(registry));
    platform_policy::enable_policy(registry, name, clock);
}

entry fun enable_platform_policy(
    registry: &mut platform_policy::PolicyRegistry,
    admin_cap: &AdminCap,
    name: String,
    clock: &Clock,
    _ctx: &mut sui_tx_context::TxContext,
) {
    enable_platform_policy_internal(registry, admin_cap, name, clock);
}

public(package) fun add_token_internal<T>(
    registry: &mut token_registry::TokenRegistry,
    admin_cap: &AdminCap,
    symbol: String,
    name: String,
    decimals: u8,
    pyth_feed_id: vector<u8>,
    max_age_ms: u64,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, token_registry::registry_owner_id(registry));
    token_registry::add_coin<T>(
        registry,
        symbol,
        name,
        decimals,
        pyth_feed_id,
        max_age_ms,
        clock,
    );
}

entry fun add_token<T>(
    registry: &mut token_registry::TokenRegistry,
    admin_cap: &AdminCap,
    symbol: String,
    name: String,
    decimals: u8,
    pyth_feed_id: vector<u8>,
    max_age_ms: u64,
    clock: &Clock,
    _ctx: &mut sui_tx_context::TxContext,
) {
    add_token_internal<T>(
        registry,
        admin_cap,
        symbol,
        name,
        decimals,
        pyth_feed_id,
        max_age_ms,
        clock,
    );
}

public(package) fun update_token_metadata_internal<T>(
    registry: &mut token_registry::TokenRegistry,
    admin_cap: &AdminCap,
    symbol: String,
    name: String,
    decimals: u8,
    pyth_feed_id: vector<u8>,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, token_registry::registry_owner_id(registry));
    token_registry::update_metadata<T>(
        registry,
        symbol,
        name,
        decimals,
        pyth_feed_id,
        clock,
    );
}

entry fun update_token_metadata<T>(
    registry: &mut token_registry::TokenRegistry,
    admin_cap: &AdminCap,
    symbol: String,
    name: String,
    decimals: u8,
    pyth_feed_id: vector<u8>,
    clock: &Clock,
    _ctx: &mut sui_tx_context::TxContext,
) {
    update_token_metadata_internal<T>(
        registry,
        admin_cap,
        symbol,
        name,
        decimals,
        pyth_feed_id,
        clock,
    );
}

public(package) fun set_token_enabled_internal<T>(
    registry: &mut token_registry::TokenRegistry,
    admin_cap: &AdminCap,
    enabled: bool,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, token_registry::registry_owner_id(registry));
    token_registry::set_enabled<T>(registry, enabled, clock);
}

entry fun set_token_enabled<T>(
    registry: &mut token_registry::TokenRegistry,
    admin_cap: &AdminCap,
    enabled: bool,
    clock: &Clock,
    _ctx: &mut sui_tx_context::TxContext,
) {
    set_token_enabled_internal<T>(registry, admin_cap, enabled, clock);
}

public(package) fun set_token_max_age_internal<T>(
    registry: &mut token_registry::TokenRegistry,
    admin_cap: &AdminCap,
    max_age_ms: u64,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, token_registry::registry_owner_id(registry));
    token_registry::set_max_age_ms<T>(registry, max_age_ms, clock);
}

entry fun set_token_max_age<T>(
    registry: &mut token_registry::TokenRegistry,
    admin_cap: &AdminCap,
    max_age_ms: u64,
    clock: &Clock,
    _ctx: &mut sui_tx_context::TxContext,
) {
    set_token_max_age_internal<T>(registry, admin_cap, max_age_ms, clock);
}

public(package) fun update_badge_config_internal(
    config: &mut badge_rewards::BadgeConfig,
    admin_cap: &AdminCap,
    amount_thresholds_micro: vector<u64>,
    payment_thresholds: vector<u64>,
    image_uris: vector<String>,
    clock: &Clock,
) {
    assert_admin_cap_for(admin_cap, badge_rewards::crowd_walrus_id(config));
    badge_rewards::set_config(
        config,
        amount_thresholds_micro,
        payment_thresholds,
        image_uris,
        clock,
    );
}

entry fun update_badge_config(
    config: &mut badge_rewards::BadgeConfig,
    admin_cap: &AdminCap,
    amount_thresholds_micro: vector<u64>,
    payment_thresholds: vector<u64>,
    image_uris: vector<String>,
    clock: &Clock,
    _ctx: &mut sui_tx_context::TxContext,
) {
    update_badge_config_internal(
        config,
        admin_cap,
        amount_thresholds_micro,
        payment_thresholds,
        image_uris,
        clock,
    );
}

entry fun migrate_token_registry(
    crowd_walrus: &mut CrowdWalrus,
    admin_cap: &AdminCap,
    ctx: &mut sui_tx_context::TxContext,
) {
    let crowd_walrus_id = sui_object::id(crowd_walrus);
    assert_admin_cap_for(admin_cap, crowd_walrus_id);

    if (df::exists_(&crowd_walrus.id, token_registry_key())) {
        return
    };

    let token_registry = token_registry::create_registry(crowd_walrus_id, ctx);
    let token_registry_id = sui_object::id(&token_registry);
    token_registry::share_registry(token_registry);
    record_token_registry_id(crowd_walrus, token_registry_id);
    event::emit(TokenRegistryCreated {
        crowd_walrus_id,
        token_registry_id,
    });
}

public(package) fun assert_admin_cap_for(cap: &AdminCap, crowd_walrus_id: sui_object::ID) {
    assert!(cap.crowd_walrus_id == crowd_walrus_id, E_NOT_AUTHORIZED);
}

public(package) fun admin_cap_crowd_walrus_id(cap: &AdminCap): sui_object::ID {
    cap.crowd_walrus_id
}

#[test_only]
public fun create_verify_cap_for_user(
    crowd_walrus_id: sui_object::ID,
    user: address,
    ctx: &mut sui_tx_context::TxContext,
): sui_object::ID {
    let verify_cap = VerifyCap {
        id: sui_object::new(ctx),
        crowd_walrus_id: crowd_walrus_id,
    };
    let verify_cap_id = sui_object::id(&verify_cap);
    transfer::transfer(verify_cap, user);
    verify_cap_id
}
