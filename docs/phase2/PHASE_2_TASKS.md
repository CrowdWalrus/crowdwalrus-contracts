Phase 2 — Updated Implementation Task List (Sui Move)

Global conventions (apply to all tasks)
• USD unit: micro‑USD (u64), floor rounding.
• Split rule: recipient gets remainder.
• Locking: parameters_locked = true on first donation. Core parameters (start/end/funding_goal/payout_policy) are immutable from creation; metadata can still change.
• Metadata: Profile and Campaign metadata use VecMap with 100-entry caps; keys must be 1–64 bytes, values 1–2048 bytes, updates to existing keys bypass the cap.
• Oracle freshness: effective_max_age_ms = min(registry.max_age_ms_for_T, donor_override if provided).
• Events: include canonical type (std::type_name::get_with_original_ids<T>()) and human symbol (from TokenRegistry).
• Safety: checked arithmetic; abort on overflow; clear error codes.
• Badges: owned & non‑transferable (no transfer API); do not freeze.
• DOF for per‑coin stats and registry mappings.
• Profile auto‑creation: Both create_campaign (A5) and donate_and_award_first_time (G6a) check ProfilesRegistry and create Profile internally if sender has none; transfer to sender; emit ProfileCreated.

B0) Build & Dependencies (new upfront)
B0. Add Pyth dependency in Move.toml

✅ COMPLETED (Oct 23, 2025) — Wormhole auto-resolved as transitive dependency. See docs/phase2/DEPENDENCIES.md.

File/Module: Move.toml (package manifest)

Product intent: Enable on‑chain price reads from Pyth for USD valuation.

Implement:

Add a dependency for Pyth’s Sui contracts (git + subdir = target_chains/sui/contracts).

Pin to a specific commit hash (preferred) or a tag compatible with the Sui testnet toolchain; avoid floating "main".

Move.lock must resolve successfully.

Preconditions: Sui framework dependency already present.

Postconditions: Project builds with Pyth imported.

Move patterns: External package pinning; reproducible builds.

Security/Edges: Pin to a stable commit; record the exact revision in docs/phase2/DEPENDENCIES.md.

Tests: sui move build succeeds; Pyth modules resolvable by other tasks.

Acceptance: Build green; Move.lock updated; docs/phase2/DEPENDENCIES.md lists the pinned revision.

Deps: None.

Err codes: N/A.

B0a. Publish-time shared object bootstrap

✅ COMPLETED (Nov 3, 2025) — `init` now provisions TokenRegistry, ProfilesRegistry, PlatformPolicy, and BadgeConfig with events + stored IDs; tests cover bootstrap wiring.

File/Module: sources/crowd_walrus.move (init) + respective module inits

Product intent: Ensure TokenRegistry, ProfilesRegistry, PlatformPolicy registry, and BadgeConfig exist immediately after publish with the correct AdminCap wiring.

Implement:

Extend crowd_walrus::init to create and share each shared object (TokenRegistry, ProfilesRegistry, PlatformPolicy, BadgeConfig) and mint/transfer the AdminCap so subsequent admin-gated entries function.

If a module needs its own init helper (e.g., token_registry::init), add it and invoke from crowd_walrus::init.

Record object IDs inside CrowdWalrus or emit events so clients can discover them.

Preconditions: Dependent modules compiled.

Postconditions: All shared state deployed once; AdminCap holder has access.

Patterns: Package init wiring; single-source-of-truth objects.

Security/Edges: Prevent duplicate creation on re-publish; assert objects absent before instantiating.

Tests: sui move test covering init scenario; ensure objects exist and AdminCap transferred.

Acceptance: After package publish, all registries/configs available; init tests pass.

Deps: B0, E1, F1, H1, I1, I2.

Err codes: Reuse module-specific duplicate errors if init rerun.

A) Campaign schema & lifecycle (existing files)
A1. Typed funding goal on Campaign
✅ COMPLETED (Oct 23, 2025) — Field + getter wired; tests updated; Sui dependency pinned to mainnet-v1.57.3 for toolchain parity.

File/Module: sources/campaign.move / crowd_walrus::campaign

Product intent: Reliable progress bars & communications (not metadata‑based).

Implement:

Add funding_goal_usd_micro: u64 to Campaign.

Add getter funding_goal_usd_micro(&Campaign): u64.

Thread into new<App>() and crowd_walrus::create_campaign.

Preconditions: Value may be zero.

Postconditions: Immutable after creation.

Patterns: Typed core state; no mutator.

Security/Edges: None.

Tests: Create + get; ensure metadata cannot alter it.

Acceptance: Field set/read; no mutation path.

Deps: A5.

✅ COMPLETED (Oct 23, 2025)
A2. Typed PayoutPolicy on Campaign

File/Module: sources/campaign.move / crowd_walrus::campaign

Product intent: Trustworthy on‑chain split commitment.

Implement:

PayoutPolicy { platform_bps: u16, platform_address: address, recipient_address: address }.

Field payout_policy + getters; creation validation (bps ≤ 10_000, addresses ≠ zero).

Preconditions: Valid bps/addresses.

Postconditions: Policy stored; later locked (A4).

Notes: Recipient payout address now lives only inside PayoutPolicy for canonical storage.

Patterns: Basis‑points; strong typing.

Security/Edges: 0% and 100% valid.

Tests: Valid and invalid cases.

Acceptance: Validated; getters return expected.

Deps: A5, G2.

Err codes: E_INVALID_BPS, E_ZERO_ADDRESS.

A3. stats_id + parameters_locked

✅ COMPLETED (Oct 23, 2025) — Added write-once stats link + lock flag with unit tests.

File/Module: sources/campaign.move

Product intent: Fast aggregate lookups; protect donors post‑first donation.

Implement:

Add stats_id: object::ID (write‑once) and parameters_locked: bool (default false).

Getters for both; internal write‑once setter for stats_id.

Preconditions: Set only at creation.

Postconditions: Flag toggled by donations flow.

Patterns: Write‑once ID; lock bit.

Security/Edges: Prevent multiple stats_id sets.

Tests: Correct initial values; setter used once.

Acceptance: Behaves as specified.

Deps: A5.

Err codes: E_STATS_ALREADY_SET.

A4. Parameter lock milestone after first donation
✅ COMPLETED (Oct 30, 2025) — parameters_locked milestone emits event on first donation and donate<T> now asserts stats ownership.

File/Module: sources/campaign.move + toggle in donations (G5/G6a/G6b)

Product intent: Prevent fee/date rug-pulls.

Implement:

In donations, if not locked, set locked and emit CampaignParametersLocked { campaign_id, timestamp_ms }.

start_date, end_date, funding_goal_usd_micro, and payout_policy are immutable from creation in the current product scope. The parameters_locked flag and event provide an indexer-friendly signal that donations have begun; metadata remains editable.

Preconditions: First donation detection.

Postconditions: Protected updates abort thereafter.

Patterns: One‑way toggle; idempotent.

Security/Edges: Concurrent updates fail correctly; donors cannot attach mismatched CampaignStats (E_STATS_MISMATCH).

Tests: Single lock event emitted on first donation; parameters_locked flag set; metadata edits continue to function.

Acceptance: Enforced & event present.

Deps: G5/G6a/G6b.

Err codes: E_PARAMETERS_LOCKED.

A5. create_campaign wiring (fields + stats + profile)
✅ COMPLETED (Oct 26, 2025) — create_campaign now wires stats + auto-profiles with integration tests for both fresh and existing owners.

File/Module: sources/crowd_walrus.move / crowd_walrus::crowd_walrus

Product intent: Campaigns start fully configured with aggregates linked; campaign owners get profiles automatically.

Implement:

Extend to accept funding_goal_usd_micro and PayoutPolicy or preset (H2).

Call profiles::create_or_get_profile_for_sender (E5) to handle registry lookup and conditional creation; this avoids duplicating logic.

After campaign::new, call campaign_stats::create_for_campaign (returns shared stats_id and sets it internally). Emit CampaignStatsCreated.

Preconditions: Valid time & policy; ProfilesRegistry available.

Postconditions: stats_id stored; profile created if missing; both events emitted conditionally.

Patterns: Constructor composition; conditional profile creation (same pattern as G6a).

Security/Edges: Profile uniqueness enforced by registry; validation aborts propagate.

Tests: Verified via create_campaign integration tests covering new and existing profile owners; invalid policy/time aborts.

Acceptance: Correct linking; profile auto-creation works; events present.

Deps: C1 (CampaignStats), E1-E2 and E5 (ProfilesRegistry + Profile + helper), H1 (platform_policy for preset resolution - see H2 for implementation details).

Err codes: E_INVALID_BPS, E_ZERO_ADDRESS, time validation errors.

B) Token & oracle infrastructure
B1. TokenRegistry (per-token metadata & staleness)

✅ COMPLETED (Oct 26, 2025) — Shared registry + admin flows merged; migration entry guards legacy deployments.

File/Module: sources/token_registry.move / crowd_walrus::token_registry

Product intent: Onboard tokens with symbols and freshness policy; drive UI labels & oracle.

Implement:

Shared TokenRegistry with DOF keyed by CoinKey<T> storing: symbol, name, decimals, pyth_feed_id (32 bytes), enabled, max_age_ms.

AdminCap-gated: add_coin<T>, update_metadata<T>, set_enabled<T>, set_max_age_ms<T>.

Views for all fields.

Events: TokenAdded, TokenUpdated, TokenEnabled, TokenDisabled.

Coordinate with B0a so crowd_walrus::init (or a module init helper) instantiates and shares the registry once at publish.

Preconditions: Unique per T; feed id len 32.

Postconditions: Readable by donations/oracle.

Patterns: Shared + DOF; cap‑gated.

Security/Edges: Duplicate add abort; decimals must be 0..=38.

Tests: Add/enable/disable/update; views; errors.

Acceptance: Registry complete; tests pass.

Deps: B0 (Pyth added).

Err codes: E_COIN_EXISTS, E_COIN_NOT_FOUND, E_BAD_FEED_ID.

B2. Effective staleness helper
✅ COMPLETED (Oct 27, 2025) — Helper computes min(registry max-age, donor override) with zero treated as no override; covered by unit tests.

File/Module: sources/donations.move / crowd_walrus::donations

Product intent: Donors can demand fresher prices than defaults.

Implement:

Compute effective_max_age_ms = min(registry.max_age_ms<T>, caller_override if provided). Treat zero/None as “no override”.

Preconditions: Token exists & enabled.

Postconditions: Used in PriceOracle call.

Patterns: Pure helper.

Security/Edges: None beyond min logic.

Tests: No override vs. tighter override.

Acceptance: Correct min used; tests pass.

Deps: B1.

C) PriceOracle
C1. quote_usd<T> valuation (staleness + floor)
✅ COMPLETED (Oct 27, 2025) — quote_usd now reads verified PriceInfoObjects with feed-ID validation and staleness enforcement.

File/Module: sources/price_oracle.move / crowd_walrus::price_oracle

Product intent: Deterministic USD valuation for receipts, badges, stats.

Implement:

Inputs: amount_raw (u128), decimals (u8), feed_id (vector<u8>), price_info_object (&PriceInfoObject), clock, max_age_ms (u64).

Use u128 math; apply exponent; floor to micro‑USD; checked downcast to u64.

Reject zero amounts; stale price info; mismatched feed IDs.

Preconditions: Caller must have updated the referenced PriceInfoObject via a verified Pyth update (same PTB).

Postconditions: Returns micro‑USD or abort.

Patterns: Stateless reader; update‑then‑consume.

Security/Edges: Exponent sanity; staleness; enforce PriceInfoObject feed matches registry metadata; no raw byte parsing.

Tests: Decimals (6/9/18); stale abort; zero abort.

Acceptance: Correct outputs; tests pass.

Deps: B0, B1.

D) Campaign aggregates

D1. CampaignStats creation + event

✅ COMPLETED (Oct 25, 2025) — CampaignStats now stores total USD and donation counts with creation event.


File/Module: sources/campaign_stats.move / crowd_walrus::campaign_stats

Product intent: Live totals without scanning events.

Implement:

Shared CampaignStats { parent_id, total_usd_micro, total_donations_count } (has key only).

create_for_campaign(&mut Campaign, &Clock, &mut TxContext) -> object::ID; share internally and emit CampaignStatsCreated { campaign_id, stats_id, timestamp_ms }.

Preconditions: Not previously created.

Postconditions: Shared stats exists & is linked in A5 with zeroed totals/counts.

Patterns: Separate shared object.

Security/Edges: Enforce one‑per‑campaign via A3 setter.

Tests: Created; event correct; initial totals/counts zero.

Acceptance: Pass.

Deps: A5.

Err codes: Optional E_STATS_ALREADY_EXISTS.

D2. Per-coin stats via DOF

✅ COMPLETED (Oct 27, 2025) — Per-coin totals tracked with overflow-safe helpers and tests.

File/Module: sources/campaign_stats.move

Product intent: Token‑level analytics for campaigns.

Implement:

DOF PerCoinStats<T> { total_raw: u128, donation_count: u64 }.

Helpers ensure_per_coin<T>(...) and add_donation<T>(raw, usd_micro); increment total_usd_micro, total_donations_count, and per‑coin stats with overflow checks.

Preconditions: Stats exist.

Postconditions: Totals/counts updated.

Patterns: DOF per token.

Security/Edges: Overflow checks.

Tests: Multi‑token increments; counts accurate.

Acceptance: Pass.

Deps: G5/G6a/G6b.

Err codes: E_OVERFLOW.

D3. Views for stats
✅ COMPLETED (Oct 27, 2025) — Added O(1) view helpers exposing total and per-coin aggregates.

File/Module: sources/campaign_stats.move

Product intent: Lightweight UIs without indexer.

Implement:

Views: total_usd_micro, total_donations_count, per_coin_total_raw<T>, per_coin_donation_count<T>.

Preconditions: —

Postconditions: Read‑only.

Patterns: Pure views.

Security/Edges: None.

Tests: Values reflect prior increments.

Acceptance: Pass.

Deps: D2.

E) Profiles (owned)
E1. ProfilesRegistry (address → profile_id)
✅ COMPLETED (Oct 25, 2025) — Shared registry + ProfileCreated event landed; publish-time init hook remains tracked under B0a.

File/Module: sources/profiles.move / crowd_walrus::profiles

Product intent: One profile per wallet; discoverable by indexer.

Implement:

Shared map (DOF) address -> profile_id.

exists, id_of, create_for(owner, ctx); emit ProfileCreated { owner, profile_id, timestamp_ms }.

Align with B0a so publish-time init creates and shares the registry alongside the AdminCap.

Preconditions: Not already mapped.

Postconditions: Mapping persisted.

Patterns: Shared + DOF.

Security/Edges: Only create for sender; duplicate abort.

Tests: Create; duplicate abort; lookup returns same id.

Acceptance: Pass.

Deps: E2.

Err codes: E_PROFILE_EXISTS, E_NOT_PROFILE_OWNER.

E2. Profile object + bitset + metadata
✅ COMPLETED (Oct 25, 2025) — Profiles track USD totals and donation counts with soulbound enforcement.

File/Module: sources/profiles.move

Product intent: Lifetime giving + badges per user.

Implement:

Owned Profile { owner, total_usd_micro: u64, total_donations_count: u64, badge_levels_earned: u16, metadata: VecMap<String,String> }.

add_contribution(amount_micro: u64) with overflow checks; increments both total_usd_micro and total_donations_count; set_metadata (owner‑only); getters exposed for both totals.

Preconditions: Owned by signer for mutators.

Postconditions: Totals, donation count, and bitset persist; donation count reflects number of distinct payments contributing to totals.

Patterns: Owned object with strict owner checks; true soulbound (Profile omits `store`, no transfer after creation).

Security/Edges: Overflow; KV length mismatch; ensure donation count increments exactly once per contribution.

Tests: Owner vs non‑owner; totals add; donation count increments; metadata changes.

Acceptance: Pass.

Deps: E1.

Err codes: E_NOT_PROFILE_OWNER, E_KEY_VALUE_MISMATCH, E_OVERFLOW.

E2b. Publisher handling for Display setup (clarification)
✅ COMPLETED (Oct 28, 2025) — Publisher & Display deployer runbook captured in docs/phase2/PUBLISHER_DISPLAY_SETUP.md; matches badge_rewards::setup_badge_display implementation.

File/Module: docs/phase2/PUBLISHER_DISPLAY_SETUP.md + sources/badge_rewards.move

Product intent: Ensure we can call Display registration with the correct Publisher.

Implement:

Document how deployer obtains the sui::package::Publisher at publish time and passes &Publisher to the admin entry (setup_badge_display) and call display::update_version after registering templates (required for wallets to pick up changes).

Add an admin entry in badge_rewards that accepts &Publisher and registers templates.

No object “claiming” is required in init; the deployer simply supplies the Publisher to the entry when configuring display.

Preconditions: Package published; Publisher available to deployer.

Postconditions: Display registered once per package version.

Patterns: Publisher‑gated configuration entry.

Security/Edges: Only callable by whoever controls the Publisher (implicitly the deployer).

Tests: Display entry callable in tests using a test Publisher handle.

Acceptance: Docs + callable entry present.

Deps: F2.

E3. Standalone create_profile entry function
✅ COMPLETED (Nov 2, 2025) — Entry now accepts Clock for timestamped events; tests cover happy path and duplicate abort.

File/Module: sources/profiles.move

Product intent: Users can create profiles before any other action (optional, improves UX).

Implement:

entry fun create_profile(registry: &mut ProfilesRegistry, clock: &Clock, ctx: &mut TxContext).

Check ProfilesRegistry; if sender already has profile, abort with E_PROFILE_EXISTS.

Create Profile via profiles::create_for, register in ProfilesRegistry, transfer to sender, emit ProfileCreated.

Preconditions: Sender has no existing profile.

Postconditions: Profile created and transferred to sender; registered in ProfilesRegistry.

Patterns: Simple entry point; can be called standalone or skipped (auto-created in A5/G6a).

Security/Edges: Duplicate creation aborts; only sender can create their own profile.

Tests: Happy path creates profile; duplicate call aborts; ProfileCreated event emitted.

Acceptance: Standalone profile creation works; tests pass.

Deps: E1, E2.

Err codes: E_PROFILE_EXISTS.

E4. update_profile_metadata entry function
✅ COMPLETED (Nov 2, 2025) — Entry enforces owner-only updates, 64/2048 length bounds, and emits ProfileMetadataUpdated.

File/Module: sources/profiles.move

Product intent: Users can update their profile information (name, bio, avatar URI, etc).

Implement:

Public entry fun update_profile_metadata(profile: &mut Profile, key: String, value: String, clock: &Clock, ctx: &mut TxContext).

Verify tx_context::sender(ctx) == profile.owner (E_NOT_PROFILE_OWNER).

Update metadata VecMap with new key-value pair (insert_or_update).

Guard against empty strings and overlong keys/values (1–64 byte keys, 1–2048 byte values) and enforce a 100-entry cap when inserting new keys (E_TOO_MANY_METADATA_ENTRIES).

Emit ProfileMetadataUpdated { profile_id, owner, key, value, timestamp_ms }.

Preconditions: Caller owns the profile.

Postconditions: Metadata updated; event emitted.

Patterns: Owned object by &mut reference; owner-only mutation.

Security/Edges: Only owner can update; key/value validation (non-empty, max length enforced).

Tests: Owner updates successfully; non-owner aborts; empty or oversized key/value abort with expected errors; event emitted.

Acceptance: Metadata updates work; tests pass.

Deps: E2.

Err codes: E_NOT_PROFILE_OWNER, E_EMPTY_KEY.

E5. Helper: create_or_get_profile_for_sender (internal helper)
✅ COMPLETED (Oct 25, 2025) — Helper now auto-mints or reuses profiles with test coverage for both paths.

File/Module: sources/profiles.move

Product intent: Reusable internal helper for profile auto-creation in both create_campaign (A5) and donate_and_award_first_time (G6a).

Implement:

Check ProfilesRegistry; if exists, return existing id; else create Profile via create_for, register in ProfilesRegistry, transfer to sender, emit ProfileCreated, return new id.

Preconditions: Valid sender address.

Postconditions: Profile exists for sender (either pre-existing or newly created); ID returned.

Patterns: Registry lookup + conditional create; used internally by A5 and G6a.

Security/Edges: Idempotent; no duplicate profiles.

Tests: Both branches (existing profile returns same id, new profile creates and returns new id).

Acceptance: Pass; works as helper for both flows.

Deps: E1/E2; Used by: A5, G6a.

F) Badge rewards (soulbound)
✅ COMPLETED (Oct 28, 2025) — Shared config object, admin setter validation, focused tests.
F1. BadgeConfig (thresholds + URIs)

File/Module: sources/badge_rewards.move

Product intent: Marketing controls milestones & art.

Implement:

Shared BadgeConfig { amount_thresholds_micro (len=5, ascending), payment_thresholds (len=5, ascending), image_uris (len=5) }.

Admin setters with validation; emit BadgeConfigUpdated.

Ensure B0a provisions and shares the BadgeConfig during init so badge award flows can borrow it immediately after publish.

Preconditions: AdminCap only.

Postconditions: Config stored.

Patterns: Cap‑gated; strict validation across both threshold vectors (length match, monotonic growth) + URIs.

Security/Edges: Length/order enforced; URIs non‑empty; supports future threshold tuning without code change.

Tests: Invalid shapes abort; valid emits event.

Acceptance: Pass.

Deps: I2.

F2. DonorBadge (soulbound) + Display setup entry
✅ COMPLETED (Oct 28, 2025) — DonorBadge minted via package-only helper and display registered with standard name/image_url/description/link templates.

File/Module: sources/badge_rewards.move

Product intent: Visible, non‑transferable achievement collectibles.

Implement:

Owned DonorBadge { level, owner, image_uri, issued_at_ms } with no transfer API.

Admin entry setup_badge_display(pub:&Publisher, ctx) to register Display templates (name, image_url, description, link) using badge fields.

Preconditions: Level within 1..5.

Postconditions: Badge mints; wallets can render display.

Patterns: Soulbound by omission; Publisher‑gated Display.

Security/Edges: Do not freeze; invalid level abort.

Tests: Badge exists and owned; Display configured.

Acceptance: Pass.

Deps: F1, E2b.

Err codes: E_BAD_BADGE_LEVEL.

F3. Award logic with bitset & events
✅ COMPLETED (Oct 31, 2025) — maybe_award_badges now emits BadgeMinted per level with exhaustive threshold tests.

File/Module: sources/badge_rewards.move

Product intent: Instant recognition when donors cross milestones.

Implement:

maybe_award_badges(profile:&mut Profile, config:&BadgeConfig, old_amount:u64, old_count:u64, new_amount:u64, new_count:u64, clock) sets bits for newly satisfied levels (both amount + payment thresholds), mints badges, emits BadgeMinted { owner, level, profile_id, timestamp_ms }. Returns minted levels (vector<u8>).

Preconditions: Config set; profile owned by signer; caller supplies pre/post totals and counts.

Postconditions: New badges minted exactly once per level; both thresholds satisfied before mint.

Patterns: Idempotent; multi‑level crossing; evaluates amount and payment thresholds together.

Security/Edges: Boundary equality (amount OR payments alone) does not mint; requires satisfying both; no duplicates.

Tests: Amount-only increase (no mint); payment-only increase (no mint); 0→L1 with both satisfied; L1→L3 jump meeting both; repeat call no duplicate; exact dual-boundary.

Acceptance: Pass.

Deps: E2, F1, F2.

G) Donations (non‑custodial orchestration)
G1. Precheck (time/status/token)

✅ COMPLETED (Oct 29, 2025) — Added donation precheck validations and boundary/negative path tests.

File/Module: sources/donations.move / crowd_walrus::donations

Product intent: Early, clear failures.

Implement:

Validate: is_active, not deleted, within window (inclusive), generic type parameter T is enabled in TokenRegistry (no coin value argument is passed).

Preconditions: Inputs available.

Postconditions: Unit or abort with error.

Patterns: Pure check.

Security/Edges: Start/end boundaries; disabled token.

Tests: Each path.

Acceptance: Pass.

Deps: B1, A1–A4.

Err codes: E_CAMPAIGN_INACTIVE, E_CAMPAIGN_CLOSED, E_TOKEN_DISABLED.

G2. Split & direct transfer
✅ COMPLETED (Oct 29, 2025) — Added split_and_transfer helper with fee rounding tests.

File/Module: sources/donations.move

Product intent: Immediate routing; predictable rounding.

Implement:

Compute platform and recipient per basis points; transfer; return sent amounts.

Preconditions: Nonzero amount; addresses valid.

Postconditions: Funds routed; no custody.

Patterns: Floor; recipient remainder; u128 intermediates.

Security/Edges: Tiny amounts may yield 0 platform.

Tests: 0%, 5%, 100%; remainder cases.

Acceptance: Pass.

Deps: A2.

Err codes: E_ZERO_DONATION.

G3. USD valuation helper (registry + oracle + override)
✅ COMPLETED (Oct 29, 2025) — Added quote_usd_micro helper with feed/staleness/zero guard tests.


File/Module: sources/donations.move

Product intent: Accurate receipt value & badge basis.

Implement:

Lookup token metadata; compute effective max age (B2); validate that the supplied PriceInfoObject matches the feed; call PriceOracle to get micro‑USD.

Preconditions: Token exists and enabled; caller has updated the PriceInfoObject earlier in the PTB.

Postconditions: Returns micro‑USD or abort.

Patterns: Stateless call; floor rounding.

Security/Edges: Stale abort; exponent sanity.

Tests: Decimal scaling; stale path; disabled token.

Acceptance: Pass.

Deps: B1, B2, C1.

Err codes: E_COIN_NOT_FOUND (if missing), E_TOKEN_DISABLED.

G4. DonationReceived event (canonical + symbol)
✅ COMPLETED (Oct 30, 2025) — Event now includes split amounts with invariants + tests.

File/Module: sources/donations.move

Product intent: Indexer uses a single event to power donation feeds.

Implement:

Emit event with fields: campaign_id, donor, coin_type_canonical, coin_symbol, amount_raw, amount_usd_micro, platform_amount_raw, recipient_amount_raw, platform_amount_usd_micro, recipient_amount_usd_micro, platform_bps, platform_address, recipient_address, timestamp_ms.

Preconditions: Values computed.

Postconditions: One event per donation.

Patterns: Canonical + human labels; event records actual split results so indexer does not recompute.

Security/Edges: No PII beyond addresses.

Tests: Fields exact; split amounts sum back to totals.

Acceptance: Pass.

Deps: B1, A2.

G5. donate<T> entry (core; slippage + locking)
✅ COMPLETED (Oct 30, 2025) — donate<T> now enforces stats ownership (E_STATS_MISMATCH), emits DonationReceived, locks params, and boundary/slippage tests cover all edges.

File/Module: sources/donations.move

Product intent: Core donation API for integrators.

Implement:

Inputs: &mut Campaign, &mut CampaignStats, &TokenRegistry, &Clock, Coin<T>, &PriceInfoObject, expected_min_usd_micro: u64, opt_max_age_ms: Option<u64>, &mut TxContext.

Flow: G1 → G3 → assert slippage floor → G2 → D2 add_donation → if first donation then A4 lock → G4 event → return micro‑USD.

Preconditions: Valid inputs; PriceInfoObject already refreshed this PTB via Pyth update.

Postconditions: Funds routed; stats updated; event emitted; maybe locked.

Patterns: Atomic orchestration.

Security/Edges: Overflow checks; idempotent lock.

Related invariants: Owner-driven campaign edit entry functions (e.g., `campaign::update_campaign_basics`, `campaign::update_campaign_metadata`) must clear `is_verified` and emit `CampaignUnverified`; campaign update postings (add_update) never do. Indexers should rely on the event + `Campaign` flag (the legacy CrowdWalrus registry cache is deprecated). Metadata guardrails: `campaign::update_campaign_metadata` enforces non-empty keys/values, 1–64 byte keys, 1–2048 byte values, and a 100-entry cap for new keys (errors E_EMPTY_KEY, E_EMPTY_VALUE, E_KEY_TOO_LONG, E_VALUE_TOO_LONG, E_TOO_MANY_METADATA_ENTRIES).

Tests: Happy/slippage/boundary times/remainder.

Acceptance: Pass.

Deps: A2–A4, B1–B2, C1, D1–D2, G1–G4.

Err codes: E_SLIPPAGE_EXCEEDED.

G6a. donate_and_award_first_time<T> entry (creates Profile internally)
✅ COMPLETED (Nov 1, 2025) — Entry auto-mints profile, updates stats, mints badges, and returns outcome struct with tests for edge cases.


File/Module: sources/donations.move

Product intent: Truly one‑tap first donation—no separate profile step.

Implement:

Inputs: &mut Campaign, &mut CampaignStats, &TokenRegistry, &BadgeConfig, &ProfilesRegistry, &Clock, Coin<T>, &PriceInfoObject, expected_min_usd_micro: u64, opt_max_age_ms: Option<u64>, &mut TxContext.

Flow: create Profile inside this entry (map in registry, create owned object, set owner); call G5 donate<T> with the verified PriceInfoObject; update profile total; call F3 maybe_award_badges; transfer the newly created Profile to the sender (ensure it ends owned by the donor); return { usd_micro, minted_levels }.

Preconditions: Sender has no existing profile (abort if exists to avoid duplicates); caller supplies a freshly updated PriceInfoObject.

Postconditions: Donation processed; profile minted to sender; badges minted if eligible.

Patterns: Owned object creation + transfer within same entry; atomic.

Security/Edges: Duplicate protection; owner set correctly.

Tests: First donation path mints profile + possibly badge; event checks.

Acceptance: Pass.

Deps: E1-E2 and E5 (ProfilesRegistry + Profile + helper for auto-creation), F1–F3 (badge rewards), G5 (core donate).

Err codes: Surface E_PROFILE_EXISTS if already mapped.

G6b. donate_and_award<T> entry (requires &mut Profile)

✅ COMPLETED (Nov 1, 2025) — Documented repeat donor entry; tests cover multi-level badge unlocks.

File/Module: sources/donations.move

Product intent: Efficient repeat donations with existing Profile.

Implement:

Inputs: &mut Campaign, &mut CampaignStats, &TokenRegistry, &BadgeConfig, &Clock, &mut Profile, Coin<T>, &PriceInfoObject, expected_min_usd_micro: u64, opt_max_age_ms: Option<u64>, &mut TxContext.

Flow: call G5 donate<T>; update profile totals; call F3 awards; return { usd_micro, minted_levels }.

Preconditions: Caller owns Profile (enforce owner) and provides a recently updated PriceInfoObject.

Postconditions: Donation processed; badges minted as needed.

Patterns: Owned object by &mut reference; atomic.

Security/Edges: Owner check; multi‑level crossing.

Tests: Repeat donor awards next badge level; totals increment.

Acceptance: Pass.

Deps: E2, F1–F3, G5.

Err codes: Propagate underlying + E_NOT_PROFILE_OWNER on misuse.

H) Platform split presets (admin; future campaigns)
H1. platform_policy presets registry
✅ COMPLETED (Oct 25, 2025)

File/Module: sources/platform_policy.move / crowd_walrus::platform_policy

Product intent: Business can add/adjust defaults (e.g., 5%→10%) for new campaigns.

Implement:

Shared registry name -> { platform_bps, platform_address, enabled } with AdminCap-gated add/update/enable/disable.

Events: PolicyAdded, PolicyUpdated, PolicyDisabled.

Hook into B0a bootstrap so the registry is created and shared exactly once during package init.

Preconditions: Valid bps & address; unique name.

Postconditions: Presets set for future campaigns; registry ID persisted on CrowdWalrus and emitted at init for discovery.

Patterns: Snapshot at creation (H2); existing campaigns unaffected.

Security/Edges: Duplicate names abort; bounds enforced.

Tests: Admin ops; errors; events (incl. invalid bps/address, missing/disabled policy).

Acceptance: Pass — entry functions callable by PTBs, registry discoverable via stored field/event.

Deps: I1.

Err codes: E_POLICY_EXISTS, E_POLICY_NOT_FOUND, E_POLICY_DISABLED, reuse E_INVALID_BPS, E_ZERO_ADDRESS.

H2. create_campaign snapshots preset policies only
✅ COMPLETED (Oct 26, 2025) — seeded `"standard"` fallback preset and removed explicit policy inputs.

File/Module: sources/crowd_walrus.move

Product intent: Campaign creators must pick an admin-owned preset; omitting a name auto-selects the seeded `"standard"` preset so they cannot inject custom splits.

Implement:

Bootstrap the `"standard"` preset during `crowd_walrus::init` (0 bps to start, platform address = publisher) so fallback is always present. Branch: if policy_name provided, resolve from platform_policy and copy into PayoutPolicy; else resolve the default preset and copy its values. No direct parameters for custom bps/address.

This extends A5's create_campaign implementation (resolved policy is passed to campaign::new along with stats creation and profile creation).

Preconditions: Enabled preset exists if referenced; default preset is bootstrapped on init but must remain enabled (abort otherwise).

Postconditions: Campaign stores snapshot; later preset changes don't affect it.

Patterns: Resolve‑and‑copy; default resolver fetches `"standard"` preset seeded with 0 bps and the publisher's address.

Security/Edges: Missing/disabled preset abort; default preset missing/disabled aborts and blocks creation (ops must restore preset).

Tests: Preset path; default preset path (no policy name); missing/disabled presets abort.

Acceptance: Pass.

Deps: H1 (platform_policy registry); Extends: A5 (this is part of A5 implementation).

I) Admin surfaces
I1. Cap‑gate TokenRegistry & PlatformPolicy

File/Module: sources/token_registry.move, sources/platform_policy.move

Product intent: Ops controls tokens & presets; prevents unauthorized changes.

Implement:

All mutators require crowd_walrus::AdminCap; emit events.

Preconditions: AdminCap holder only.

Postconditions: Controlled changes.

Patterns: Capability pattern (matches your codebase).

Security/Edges: Unauthorized aborts.

Tests: Unauthorized/authorized paths + events.

Acceptance: Pass.

Deps: Existing AdminCap.

Err codes: Reuse E_NOT_AUTHORIZED.

I2. Cap‑gate BadgeConfig updates

File/Module: sources/badge_rewards.move

Product intent: Marketing updates go through admin channel.

Implement:

Enforce AdminCap on config setters; emit BadgeConfigUpdated.

Preconditions: Admin only.

Postconditions: Config changed.

Patterns: Capability gating.

Security/Edges: Unauthorized abort.

Tests: As above.

Acceptance: Pass.

Deps: AdminCap.

J) Events & Docs
J1. Finalize & document event schemas

File/Module: All relevant modules; Documentation/UPDATE_IMPLEMENTATION.md

Product intent: Indexer has a single, authoritative reference.

Implement:

Verify all event field sets match: DonationReceived, CampaignStatsCreated, CampaignParametersLocked, ProfileCreated, ProfileMetadataUpdated, BadgeConfigUpdated, BadgeMinted, PolicyAdded/Updated/Disabled, Token*.

Document names, fields, types, and when emitted.

Preconditions: Events implemented.

Postconditions: Doc synced.

Patterns: Consistent timestamps; canonical type strings.

Security/Edges: No PII beyond addresses.

Tests: Assert event fields in unit tests.

Acceptance: Docs reflect code; tests pass.

Deps: All event producers.

K) Tests
K1. Unit tests per module

Files:

tests/token_registry_tests.move

tests/price_oracle_tests.move

tests/campaign_stats_tests.move

tests/profiles_tests.move

tests/badge_rewards_tests.move

tests/donations_tests.move

Product intent: Every building block verified.

Implement:

Cover happy paths and aborts per task; assert events; overflow/staleness/locking cases.

Preconditions: Modules in place.

Postconditions: Green tests.

Patterns: sui::test_scenario.

Security/Edges: Boundary timestamps; dust; double‑mint; double profile; disabled tokens; slippage.

Acceptance: All pass.

K2. Integration scenarios (targeted)

File: tests/integration_phase2_tests.move

Product intent: Demonstrate end‑to‑end UX paths.

Implement scenarios:

Standalone profile creation (E3): user creates profile explicitly; ProfileCreated event emitted; duplicate creation aborts.

Profile metadata update (E4): owner updates metadata successfully; non-owner aborts; ProfileMetadataUpdated event emitted.

Create campaign via preset without existing profile: profile auto-created and transferred to owner; stats created; stats_id linked; ProfileCreated and CampaignStatsCreated events emitted.

Create campaign with existing profile: no ProfileCreated event; only CampaignStatsCreated emitted; stats linked correctly.

First donation (G6a): profile created internally; lock toggled; stats updated; badge L1 minted; ProfileCreated, DonationReceived, CampaignParametersLocked events emitted.

Repeat donation (G6b): profile passed by &mut; cumulative totals; next badge; events emitted.

DonationReceived assertions: verify coin_type_canonical and coin_symbol fields are present and match the expected registry metadata for each donation.

Different token: per-coin stats independent.

Concurrent donations: simulate two donors contributing in the same test_scenario to confirm no contention or double-lock issues on CampaignStats.

Slippage floor: success when met; abort when not.

Acceptance: All scenarios pass with correct events and state.

L) Documentation & DevEx
L1. Update UPDATE_IMPLEMENTATION.md (developer‑facing)

File: Documentation/UPDATE_IMPLEMENTATION.md

Product intent: Engineers can assemble PTBs and admin workflows without reading code.

Implement:

PTB patterns for: campaign creation (auto-creates profile if missing), first-time donor (call G6a only), repeat donor (call G6b with &mut Profile), preset selection or default seeded campaign creation (initially 0 bps), Display registration using Publisher; include the Display template keys (name, image_url, description, link) and remind readers to call display::update_version after setup_badge_display(pub, ctx).

Explain how integrators fetch Pyth price updates off-chain (e.g., via Pyth SDK) and attach them to the same PTB, clarifying staleness semantics and donor overrides.

Document profile auto-creation in both create_campaign (A5) and donate_and_award_first_time (G6a): check ProfilesRegistry → create if missing → transfer to sender → emit ProfileCreated.

List entry function inputs (object refs required), rounding, slippage, staleness, locking, event schemas.

Acceptance: Clear, stepwise, unambiguous; profile auto-creation documented for both flows.

L2. Update README.md (product overview)

File: Documentation/README.md

Product intent: Stakeholder‑friendly summary.

Implement:

Features (donations, tokens, USD valuation, profiles, badges, stats, presets), key flows, and admin knobs.

Acceptance: Up‑to‑date & concise.

Notes on the three external feedback points

F6 ambiguity → Resolved by splitting into G6a (creates Profile internally) and G6b (requires &mut Profile). Frontend chooses based on existence. This removes ambiguity and keeps PTBs clean.

Pyth dependency → Added B0 with best practice: pin to a specific commit hash (preferred) or compatible tag, avoid floating main, and capture the revision in Documentation/last_deploy.md. Acceptance requires build success and lockfile update.

Publisher setup → Clarified in E2b docs (docs/phase2/PUBLISHER_DISPLAY_SETUP.md) and L1 docs: use the Publisher object obtained at publish time by the deployer to call the setup_badge_display entry. No special “claiming” via OTW is required; just pass &Publisher to the admin entry that registers Display.
