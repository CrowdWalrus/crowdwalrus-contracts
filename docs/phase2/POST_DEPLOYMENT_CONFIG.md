# Phase 2 Post-Deployment Configuration

This checklist covers every contract-level action the platform team must run immediately after a new Crowd Walrus publish. All steps require the freshly minted `crowd_walrus::AdminCap` unless stated otherwise.

---

## 1. Capture Shared Object IDs
- Record the object IDs from the publish transaction effects or emitted events:
  - Shared `CrowdWalrus` object ID (present in the publish summary alongside `AdminCreated`)
  - `PolicyRegistryCreated`
  - `ProfilesRegistryCreated`
  - `TokenRegistryCreated`
  - `BadgeConfigCreated`
  - `SuiNSManagerCreated`
- Persist the IDs in deployment tooling or environment configuration so frontends/indexers can reference them without replaying history.

## 2. Secure the Admin Cap
- Transfer the `crowd_walrus::AdminCap` to the operations wallet that will manage post-deployment tasks.
- Store a backup procedure (multisig or hardware wallet) before running further configuration.

## 3. Wire SuiNS Subdomain Support
- Obtain the `suins::suins_registration::SuinsRegistration` NFT that controls the production namespace.
- Call `crowd_walrus::set_suins_nft` with:
  - `&mut SuiNSManager` (shared object from publish)
  - `&crowd_walrus::AdminCap`
  - The SuinsRegistration NFT
- This step enables `create_campaign` to register subdomains. Skipping it will abort all campaign creations.

## 4. Configure Platform Policy Presets
- Review the bootstrap `"standard"` preset (seeded with the deployer’s address at publish time).
- If the production platform address differs, call `crowd_walrus::update_platform_policy` to set:
  - `platform_bps` (0–10_000)
  - `platform_address`
- Use `crowd_walrus::add_platform_policy` to register any additional named presets (e.g., `"commercial"`).
- Optionally call `crowd_walrus::enable_platform_policy` / `disable_platform_policy` to control availability for UIs.

## 5. Populate the Token Registry
- For each supported coin type `T`:
  1. Call `crowd_walrus::add_token<T>` with symbol, name, decimals, `pyth_feed_id` (32 bytes), and default `max_age_ms`.
  2. Call `crowd_walrus::set_token_enabled<T>(…, true, …)` once metadata is verified.
  3. Call `crowd_walrus::set_token_max_age<T>` if you need token-specific freshness stricter than the default.
- Re-run `crowd_walrus::update_token_metadata<T>` if any feed IDs or symbols change later.
- Document the final symbol/feed mapping so the frontend knows which Pyth price IDs to request.

## 6. Seed Badge Configuration
- Prepare production badge thresholds (exactly five ascending values for both USD totals and donation counts) and Walrus image URIs.
- Call `crowd_walrus::update_badge_config` with:
  - `amount_thresholds_micro: vector<u64>` length 5, strictly ascending
  - `payment_thresholds: vector<u64>` length 5, strictly ascending
  - `image_uris: vector<String>` length 5, non-empty URIs
- Without this call, `badge_rewards::maybe_award_badges` will no-op and no badges will mint.

## 7. Validate Oracle Integration
- Ensure deployment playbooks include fetching a fresh Pyth update inside every donation PTB:
  - Call `pyth::update_single_price_feed` with the pinned `pythStateId` and `wormholeStateId`.
  - Use the same coin symbols configured in the token registry.
- Monitor for `DonationReceived` events to confirm USD valuations are landing as expected.

## 8. Post-Deployment Smoke Tests
- Create a private campaign using `create_campaign` to verify:
  - Auto-profile creation succeeds
  - SuiNS subdomain registers to the expected address
  - Campaign shares its stats object
- Run a test donation (on test wallet) ensuring:
  - Locked parameters event emits
  - Badge awarding emits `BadgeMinted` once thresholds are crossed
  - Split amounts mirror the configured platform policy

---

Keep this document in sync with future admin entry additions. If a Phase 2 task introduces new shared state or configuration knobs, append the corresponding post-deployment actions here.
