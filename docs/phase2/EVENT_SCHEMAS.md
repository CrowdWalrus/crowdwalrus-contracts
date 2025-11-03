# Phase 2 Developer Reference — Event Schemas

This document captures the canonical schema for every Phase 2 event that downstream
indexers must handle. All events are emitted via `sui::event::emit` and share the
following conventions:

- `timestamp_ms` values come from `clock::timestamp_ms` and represent Unix time in
  milliseconds (UTC).
- String fields are `std::string::String` unless otherwise noted.
- Canonical coin type strings are produced with
  `std::type_name::with_original_ids<T>()` and converted to ASCII.
- Vectors use Sui Move `vector<T>` and preserve the order provided by the emitting
  module (for example, badge thresholds remain level-aligned).

## Donation Flows

### crowd_walrus::donations::DonationReceived

Emitted exactly once per successful donation (from `donate<T>`,
`donate_and_award_first_time<T>`, and `donate_and_award<T>`) after funds have been
split, stats updated, and slippage checks satisfied.

| Field | Type | Description |
| --- | --- | --- |
| `campaign_id` | `sui::object::ID` | Campaign receiving the contribution. |
| `donor` | `address` | Address that executed the donation transaction. |
| `coin_type_canonical` | `String` | Canonical Move type name for the donated coin. |
| `coin_symbol` | `String` | Human-readable symbol resolved from `TokenRegistry`. |
| `amount_raw` | `u64` | Total token amount contributed (raw coin units). |
| `amount_usd_micro` | `u64` | Floor-rounded micro-USD valuation produced by `price_oracle::quote_usd`. |
| `platform_amount_raw` | `u64` | Raw token amount sent to the platform address. |
| `recipient_amount_raw` | `u64` | Raw token amount sent to the campaign recipient. |
| `platform_amount_usd_micro` | `u64` | Micro-USD valuation of the platform split. |
| `recipient_amount_usd_micro` | `u64` | Micro-USD valuation of the recipient split. |
| `platform_bps` | `u16` | Basis points applied to the donation for platform fees. |
| `platform_address` | `address` | Destination for the platform split. |
| `recipient_address` | `address` | Destination for the recipient split. |
| `timestamp_ms` | `u64` | Block timestamp when the donation executed. |

## Campaign Lifecycle

### crowd_walrus::campaign_stats::CampaignStatsCreated

Emitted when `campaign_stats::create_for_campaign` provisions the shared
`CampaignStats` object during campaign creation. Exactly one instance exists per
campaign.

| Field | Type | Description |
| --- | --- | --- |
| `campaign_id` | `sui::object::ID` | Parent campaign object ID. |
| `stats_id` | `sui::object::ID` | Newly created `CampaignStats` shared object ID. |
| `timestamp_ms` | `u64` | Timestamp of stats provisioning. |

### crowd_walrus::campaign::CampaignParametersLocked

Emitted the first time `campaign::lock_parameters_if_unlocked` succeeds (invoked
from the donation pipeline) to signal that immutable campaign economics are now
frozen.

| Field | Type | Description |
| --- | --- | --- |
| `campaign_id` | `sui::object::ID` | Campaign whose parameters are now locked. |
| `timestamp_ms` | `u64` | Timestamp of the locking donation. |

## Profiles

### crowd_walrus::profiles::ProfileCreated

Emitted when a profile is minted through `create_profile` or auto-created inside
`create_campaign`/`donate_and_award_first_time<T>`. Each wallet receives at most
one profile.

| Field | Type | Description |
| --- | --- | --- |
| `owner` | `address` | Wallet that now owns the profile object. |
| `profile_id` | `sui::object::ID` | Newly created `Profile` object ID. |
| `timestamp_ms` | `u64` | Timestamp of profile creation. |

### crowd_walrus::profiles::ProfileMetadataUpdated

Emitted whenever `profiles::update_profile_metadata` mutates a metadata key that
passes owner and length validation.

| Field | Type | Description |
| --- | --- | --- |
| `profile_id` | `sui::object::ID` | Profile whose metadata changed. |
| `owner` | `address` | Profile owner that authorized the update. |
| `key` | `String` | Metadata key (1–64 bytes). |
| `value` | `String` | Metadata value (1–2048 bytes). |
| `timestamp_ms` | `u64` | Timestamp of the successful update. |

## Badge Rewards

### crowd_walrus::badge_rewards::BadgeConfigUpdated

Emitted by admin-only configuration setters after validation succeeds.

| Field | Type | Description |
| --- | --- | --- |
| `amount_thresholds_micro` | `vector<u64>` | Donation total thresholds (micro-USD) per badge level. |
| `payment_thresholds` | `vector<u64>` | Distinct payment count thresholds per badge level. |
| `image_uris` | `vector<String>` | Image URIs aligned with each badge level. |
| `timestamp_ms` | `u64` | Timestamp of the configuration change. |

### crowd_walrus::badge_rewards::BadgeMinted

Emitted from `badge_rewards::maybe_award_badges` when a donor newly satisfies both
amount and payment thresholds for a badge level.

| Field | Type | Description |
| --- | --- | --- |
| `owner` | `address` | Wallet receiving the non-transferable badge. |
| `level` | `u8` | Badge level awarded (1–5). |
| `profile_id` | `sui::object::ID` | Profile that crossed the thresholds. |
| `timestamp_ms` | `u64` | Timestamp of badge issuance. |

## Platform Policy Presets

### crowd_walrus::platform_policy::PolicyAdded

Emitted when a new preset is inserted (either during bootstrap or via admin entry).

| Field | Type | Description |
| --- | --- | --- |
| `policy_name` | `String` | Unique preset name. |
| `platform_bps` | `u16` | Fee basis points stored in the preset. |
| `platform_address` | `address` | Fee recipient recorded in the preset. |
| `enabled` | `bool` | Always `true` for newly added presets. |
| `timestamp_ms` | `u64` | Timestamp of creation (0 for init bootstraps). |

### crowd_walrus::platform_policy::PolicyUpdated

Emitted when admins change bps, address, or re-enable a preset.

| Field | Type | Description |
| --- | --- | --- |
| `policy_name` | `String` | Preset identifier. |
| `platform_bps` | `u16` | Updated fee basis points. |
| `platform_address` | `address` | Updated fee recipient. |
| `enabled` | `bool` | Current enabled flag after the update. |
| `timestamp_ms` | `u64` | Timestamp of the update. |

### crowd_walrus::platform_policy::PolicyDisabled

Emitted after admins disable a preset.

| Field | Type | Description |
| --- | --- | --- |
| `policy_name` | `String` | Preset identifier. |
| `platform_bps` | `u16` | Fee basis points stored on disable. |
| `platform_address` | `address` | Fee recipient stored on disable. |
| `enabled` | `bool` | Always `false` when the event is emitted. |
| `timestamp_ms` | `u64` | Timestamp of the disable action. |

## Token Registry

### crowd_walrus::token_registry::TokenAdded

Emitted when a new coin type is registered. Tokens start disabled until explicitly
enabled.

| Field | Type | Description |
| --- | --- | --- |
| `coin_type` | `String` | Canonical Move type name for the coin. |
| `symbol` | `String` | Symbol stored for display purposes. |
| `name` | `String` | Full name stored for display purposes. |
| `decimals` | `u8` | Number of fractional decimals expected for the coin. |
| `pyth_feed_id` | `vector<u8>` | 32-byte Pyth price feed identifier. |
| `max_age_ms` | `u64` | Default staleness budget for price updates. |
| `enabled` | `bool` | Initial enabled flag (defaults to `false`). |
| `timestamp_ms` | `u64` | Timestamp of the add operation (0 if seeded at init). |

### crowd_walrus::token_registry::TokenUpdated

Emitted for metadata edits (`update_metadata<T>`) and max-age updates
(`set_max_age_ms<T>`).

| Field | Type | Description |
| --- | --- | --- |
| `coin_type` | `String` | Canonical Move type name for the coin. |
| `symbol` | `String` | Updated symbol. |
| `name` | `String` | Updated name. |
| `decimals` | `u8` | Updated decimals. |
| `pyth_feed_id` | `vector<u8>` | Updated 32-byte feed identifier. |
| `max_age_ms` | `u64` | Updated staleness budget. |
| `timestamp_ms` | `u64` | Timestamp of the update. |

### crowd_walrus::token_registry::TokenEnabled

Emitted when a token is enabled for donations.

| Field | Type | Description |
| --- | --- | --- |
| `coin_type` | `String` | Canonical Move type name for the coin. |
| `symbol` | `String` | Symbol at the moment of enablement. |
| `timestamp_ms` | `u64` | Timestamp of enablement. |

### crowd_walrus::token_registry::TokenDisabled

Emitted when a token is disabled for donations.

| Field | Type | Description |
| --- | --- | --- |
| `coin_type` | `String` | Canonical Move type name for the coin. |
| `symbol` | `String` | Symbol at the moment of disablement. |
| `timestamp_ms` | `u64` | Timestamp of disablement. |

---

**Indexer Guidance**

- Treat `DonationReceived` as the single source of truth for donation amounts and
  splits. Raw and USD values include both platform and recipient breakdowns.
- `CampaignParametersLocked` is emitted at most once per campaign and signals that
  start/end dates, funding goal, and payout policy are immutable for indexers.
- Badge-related events rely on `BadgeConfigUpdated` for level metadata and
  `BadgeMinted` for donor progress; store both to render badges accurately.
- Policy and token registry events provide an auditable trail; the latest state can
  always be derived by replaying events in timestamp order.
