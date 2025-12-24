# Phase 2 Developer Guide

This guide aggregates the developer-facing workflows for the Crowd Walrus Phase 2 release. Detailed
event schemas live in `docs/phase2/EVENT_SCHEMAS.md` and remain the canonical reference for indexers.

## Transaction Recipes

### Campaign creation (`crowd_walrus::create_campaign`)
- Inputs: `&CrowdWalrus`, `&platform_policy::PolicyRegistry`, `&mut profiles::ProfilesRegistry`,
  `&suins_manager::SuiNSManager`, `&mut suins::SuiNS`, `&Clock`, `&mut TxContext`, campaign metadata,
  `funding_goal_usd_micro`, recipient address, optional preset name, and window timestamps.
- Flow: validates the policy registry binding, resolves a preset (`Some(name)` or the seeded
  `None -> "standard"` preset that currently carries a 0 bps platform fee), constructs the campaign,
  keyless stats object, and SUINS subdomain, and calls
  `profiles::create_or_get_profile_for_sender` so campaign owners leave the PTB with an owned profile.
- Events: always emits `CampaignCreated` and `campaign_stats::CampaignStatsCreated`. A new
  `profiles::ProfileCreated` event only fires if the creator had no profile. Expect the SUINS call to
  bind the campaign address to the requested subdomain.
- Returns the campaign object ID for downstream wiring.

### First-time donor (`donations::donate_and_award_first_time<T>`)
- Inputs: `&mut campaign::Campaign`, `&mut campaign_stats::CampaignStats`,
  `&token_registry::TokenRegistry`, `&badge_rewards::BadgeConfig`,
  `&mut profiles::ProfilesRegistry`, `&Clock`, the donor’s `Coin<T>`,
  a freshly updated `pyth::price_info::PriceInfoObject`, `expected_min_usd_micro`, optional
  max-age override, and `&mut TxContext`.
- Flow: asserts the sender lacks a profile, mints one via `profiles::create_for`, runs the full
  `donations::donate` pipeline (precheck, USD quote, split, stats), updates profile totals, evaluates
  badge thresholds, and transfers the profile back to the donor so it leaves owned.
- Events: emits `ProfileCreated`, `DonationReceived`, and any `badge_rewards::BadgeMinted`
  levels. The first donation to a campaign also emits `campaign::CampaignParametersLocked`.
- Returns `DonationAwardOutcome { usd_micro, minted_levels }`.

### Repeat donor (`donations::donate_and_award<T>`)
- Inputs: `&mut campaign::Campaign`, `&mut campaign_stats::CampaignStats`,
  `&token_registry::TokenRegistry`, `&badge_rewards::BadgeConfig`, `&Clock`,
  `&mut profiles::Profile`, the donor’s `Coin<T>`, `&PriceInfoObject`,
  `expected_min_usd_micro`, optional max-age override, and `&mut TxContext`.
- Flow: verifies the signer owns the supplied profile, runs `donations::donate`, increments totals,
  and evaluates badge rewards. Profile registry access is unnecessary—the caller must bring their
  owned profile into the PTB.
- Events & return shape match the first-time donor flow (minus the initial `ProfileCreated`).

### Badge display registration (`badge_rewards::setup_badge_display`)
- Inputs: `&Publisher` obtained at publish time and `&mut TxContext`.
- Source: `crowd_walrus::crowd_walrus::init` now calls `sui::package::claim_and_keep`, so every publish hands the deployer an owned `Publisher` visible in the transaction effects.
- Flow: registers the donor badge `Display` template with the keys `name`, `image_url`,
  `description`, and `link`—respectively rendering the badge label, image URI from `BadgeConfig`,
  textual description with `{level}`/`{owner}` placeholders, and a deep link to the badge detail
  page. The entry already calls `display::update_version`, but if you layer any follow-up mutations
  on the returned `Display` you must invoke `display::update_version` again before finishing the PTB
  to ensure wallets pick up template changes.
- Result: the `DonorBadge` display object is shared so threshold updates and badge mints render
  consistently across wallets.

## Admin Operations

### Token onboarding (`crowd_walrus::add_token<T>`, `set_token_enabled<T>`, `set_token_max_age<T>`)
- Inputs: `&mut token_registry::TokenRegistry`, `&crowd_walrus::AdminCap`, `&Clock`, plus token
  metadata (symbol, name, decimals, 32-byte Pyth feed ID) and desired max staleness.
- Flow: call `add_token<T>` to register metadata, optionally `update_token_metadata<T>` later to
  amend symbol/name/decimals/feed, `set_token_enabled<T>` to toggle donation eligibility, and
  `set_token_max_age<T>` to tighten or loosen the freshness budget. All entries assert that the cap
  matches the registry’s owner ID.
- Events: `token_registry::TokenAdded`, `TokenUpdated`, `TokenEnabled`, and `TokenDisabled` (see
  event schemas for payloads). Both metadata edits and max-age updates surface via `TokenUpdated`.

### Badge configuration (`crowd_walrus::update_badge_config`)
- Inputs: `&mut badge_rewards::BadgeConfig`, `&AdminCap`, `&Clock`, and three vectors (USD thresholds,
  payment thresholds, image URIs) of length five.
- Flow: provide strictly increasing thresholds; the entry validates lengths and ordering, writes the
  new configuration, and emits `badge_rewards::BadgeConfigUpdated`.
- Use case: adjust badge progression or artwork without redeploying the package.

### Platform policy presets
- Inputs: `&mut platform_policy::PolicyRegistry`, `&AdminCap`, `&Clock`, policy name, basis points,
  and platform payout address.
- Flow: `crowd_walrus::add_platform_policy` seeds new presets, `update_platform_policy` modifies existing ones,
  `enable_platform_policy`/`disable_platform_policy` toggle availability. Campaign creation resolves
  presets by name (defaulting to the init-seeded `"standard"` policy), so disabling a preset prevents
  future campaigns from selecting it while leaving existing campaigns untouched.
- Events: `platform_policy::PolicyAdded`, `PolicyUpdated`, and `PolicyDisabled`. Enabling or updating
  a policy reuses `PolicyUpdated` for indexer-friendly timestamps.

## Pyth price feed integration

1. Off-chain, use the Pyth SDK (REST, Hermes, or Wormhole guardian RPC) to request a signed price
   update for the feed registered in `token_registry::pyth_feed_id<T>`. Capture both the VAA bytes
   and the expected publish timestamp.
2. Inside the PTB, call the Pyth on-chain entry (e.g., `pyth::create_price_feeds` or the production
   `update_price_feeds`) supplying the verified VAAs so Sui materializes/refreshes the
   `PriceInfoObject`.
3. Pass the refreshed `PriceInfoObject` handle directly into `donate_and_award_first_time<T>` or
   `donate_and_award<T>` in the same PTB. The oracle enforces that the object’s feed ID matches the
   registry metadata and that the publish time is within the effective staleness window.
4. Staleness: the token registry advertises a max age per coin. Donors can optionally pass
   `opt_max_age_ms = Some(value)` to demand fresher data—`0` or `None` simply defers to the registry.
   The helper `effective_max_age_ms` feeds the tighter of the two values into the oracle.

## Profile auto-creation touchpoints

- `crowd_walrus::create_campaign` calls `profiles::create_or_get_profile_for_sender` after the
  campaign object is constructed, guaranteeing owners always exit with a profile. Existing entries
  are reused; new profiles emit `ProfileCreated` and are transferred to the sender.
- `donations::donate_and_award_first_time<T>` creates a profile up front via
  `profiles::create_for`, writes it into the registry map, performs the donation, then transfers the
  owned profile to the donor. A duplicate profile triggers `profiles::profile_exists_error_code()`,
  prompting integrators to switch to the repeat-donor path.

## Entry reference

| Entry | Shared/owned references to load | Returns | Primary events |
| --- | --- | --- | --- |
| `crowd_walrus::create_campaign` | `&CrowdWalrus`, `&PolicyRegistry`, `&mut ProfilesRegistry`, `&SuiNSManager`, `&mut SuiNS`, `&Clock`, `&mut TxContext` | `campaign_id: ID` | `CampaignCreated`, `CampaignStatsCreated`, conditional `ProfileCreated` |
| `donations::donate_and_award_first_time<T>` | `&mut Campaign`, `&mut CampaignStats`, `&TokenRegistry`, `&BadgeConfig`, `&mut ProfilesRegistry`, `&Clock`, `Coin<T>`, `&PriceInfoObject`, `&mut TxContext` | `DonationAwardOutcome` | `ProfileCreated`, `DonationReceived`, `CampaignParametersLocked*`, `BadgeMinted*` |
| `donations::donate_and_award<T>` | `&mut Campaign`, `&mut CampaignStats`, `&TokenRegistry`, `&BadgeConfig`, `&Clock`, `&mut Profile`, `Coin<T>`, `&PriceInfoObject`, `&mut TxContext` | `DonationAwardOutcome` | `DonationReceived`, `CampaignParametersLocked*`, `BadgeMinted*` |
| `badge_rewards::setup_badge_display` | `&Publisher`, `&mut TxContext` | `()` | the display share itself (no bespoke event) |

`*` denotes events emitted only when the donation is the first for a campaign or when badge thresholds
are crossed. See `docs/phase2/EVENT_SCHEMAS.md` for field-level payloads.

## Rounding, slippage, locking, and events

- USD valuation: `price_oracle::quote_usd` floors to micro-USD after applying price exponent math and
  checked conversions. Zero amounts or stale prices abort.
- Split accounting: `donations::split_and_transfer` uses u128 math with floor division on the
  platform share; any remainder stays with the recipient. Raw coin transfers route directly to the
  platform and recipient addresses—no custody is taken.
- Slippage: callers set `expected_min_usd_micro`. The donation aborts if the quoted USD value drops
  below this floor between constructing and executing the PTB.
- Staleness controls: registry defaults enforce maximum age per token; donor overrides can only
  tighten that window. `opt_max_age_ms = Some(0)` is equivalent to no override.
- Locking: the first successful donation toggles `Campaign.parameters_locked = true` and emits
  `CampaignParametersLocked`. Core parameters (start, end, funding goal, payout policy) are immutable
  afterward, while metadata updates remain allowed.
- Event catalog: `CampaignCreated`, `CampaignStatsCreated`, `ProfileCreated`,
  `DonationReceived`, `CampaignParametersLocked`, and `BadgeMinted` are the critical signals for
  wallet/indexer integrations. Reference their full schemas in `docs/phase2/EVENT_SCHEMAS.md`.
