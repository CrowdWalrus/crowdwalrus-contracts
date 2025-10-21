Phase 2 — Implementation Task List (Sui Move)
0) Global Conventions (read once, used by all tasks)

USD unit: all USD values use micro‑USD (u64), floor‑rounded.

Rounding policy: recipient gets the remainder when splitting basis points.

Locking: parameters_locked becomes true on first donation; after that, start/end/funding_goal/payout_policy cannot change.

Oracle freshness: effective_max_age_ms = min(registry.max_age_ms_for_T, donor_opt_max_age_ms if provided).

Events: include both canonical type (std::type_name::get_with_original_ids<T>()) and human symbol (from TokenRegistry).

Security: check overflow on all additions and multiplications (use u128 intermediates).

Ownership: Badges are owned and non‑transferable by design (no transfer APIs). Do not freeze badges.

A) Campaign Schema & Lifecycle
A1. Add typed funding goal to Campaign

File / Module: sources/campaign.move / crowd_walrus::campaign

Product intent: Show donors a trustworthy goal in USD; enable comparisons/UX without parsing metadata.

Add/Change:

Field: funding_goal_usd_micro: u64 to Campaign (stored at creation, never mutated).

Getter: funding_goal_usd_micro(&Campaign): u64.

Thread parameter through new<App>(...) and through crowd_walrus::create_campaign(...).

Inputs/Outputs: Input at creation; view returns u64.

Events/Errors: Reuse existing error style; no new event required.

Security/Invariants: Value can be 0; cannot be mutated post‑create; overflow not applicable.

Edge cases: Very large goals near u64::MAX—document but accept.

Tests: Create campaign with nonzero/zero goal; verify getter; ensure metadata updates cannot change it.

Acceptance: Field present, written only once, readable, covered by tests.

Checklist: add field → update constructor → update create path → add getter → tests.

A2. Introduce typed PayoutPolicy on Campaign

File / Module: sources/campaign.move / crowd_walrus::campaign

Product intent: Donors must see/receive predictable fee split enforced on‑chain.

Add/Change:

Struct: PayoutPolicy { platform_bps: u16, platform_sink: address, recipient_sink: address }.

Add field payout_policy: PayoutPolicy to Campaign.

Getters for all fields.

Inputs/Outputs: Accept PayoutPolicy at creation (or resolved preset—see G2).

Events/Errors: New error code for invalid bps (e.g., E_INVALID_BPS); invalid sinks (E_INVALID_SINK).

Security/Invariants: platform_bps ≤ 10_000; both sinks are nonzero.

Edge cases: platform_bps = 0 (valid); platform_bps = 10_000 (recipient gets 0, valid).

Tests: Create with 0% and 5%; getters match; invalid bps and zero sink abort.

Acceptance: Typed policy enforced; tests pass.

Checklist: define struct → add field → getters → validations at creation → tests.

A3. Link CampaignStats and add parameters_locked

File / Module: sources/campaign.move

Product intent: Fast discovery of stats; guard critical parameters after first donation.

Add/Change:

Field: stats_id: object::ID (write‑once).

Field: parameters_locked: bool (defaults false).

Getters for both fields.

Inputs/Outputs: stats_id set once by create flow; lock set by donations flow.

Events/Errors: New error E_STATS_ALREADY_SET if attempted overwrite.

Security/Invariants: stats_id can only be set once; parameters_locked only flips from false to true.

Edge cases: None beyond idempotency.

Tests: After create, stats_id set; parameters_locked == false.

Acceptance: Fields exist; invariants enforced; tests pass.

Checklist: add fields → getters → write‑once setter used by create flow → tests.

A4. Enforce locking on updates after first donation

File / Module: sources/campaign.move (applies inside existing update entry functions)

Product intent: Prevent fee/timeline rug‑pulls after donors start contributing.

Add/Change:

At top of setters that modify start_date, end_date, funding_goal_usd_micro, payout_policy: assert !parameters_locked; otherwise abort E_PARAMETERS_LOCKED.

Keep metadata edits (name/description) allowed; continue emitting CampaignBasicsUpdated.

Inputs/Outputs: No new inputs; updates remain as is with added guard.

Events/Errors: New E_PARAMETERS_LOCKED; donation flow will emit lock event (see G5).

Security/Invariants: Lock is one‑way; check must exist in all relevant update functions.

Edge cases: First donation concurrently with update—donation tx that sets lock should cause the update tx to fail if it runs after.

Tests: Before donation, updates succeed; after first donation, guarded updates abort.

Acceptance: All guarded setters block correctly post‑lock; tests pass.

Checklist: add assertions → ensure coverage across setters → tests.

A5. Update create_campaign to accept typed fields and create stats

File / Module: sources/crowd_walrus.move / crowd_walrus::crowd_walrus

Product intent: Campaigns are fully configured and stats‑linked at birth.

Add/Change:

Extend parameters to pass funding_goal_usd_micro and payout_policy.

Construct Campaign via campaign::new.

Call campaign_stats::create_for_campaign and store resulting stats_id via write‑once path.

Emit event CampaignStatsCreated (created in CampaignStats module) when stats created (module emits).

Inputs/Outputs: Inputs extended; same output campaign_id.

Events/Errors: Validation errors from policy or time bounds propagate.

Security/Invariants: Validate bps/sinks/time; stats_id set exactly once.

Edge cases: None beyond validations.

Tests: Creation happy path; invalid policy abort; stats_id present and nonzero.

Acceptance: All paths compile and tests pass.

Checklist: thread new params → create stats → set stats_id → tests.

B) Token & Oracle Infrastructure
B1. Implement TokenRegistry (per‑token metadata + staleness)

File / Module: sources/token_registry.move / crowd_walrus::token_registry

Product intent: Let platform onboard tokens and set valuation parameters without code changes.

Add/Change:

Shared object TokenRegistry.

Dynamic field map keyed by phantom CoinKey<T> storing: symbol: String, name: String, decimals: u8, pyth_feed_id: vector<u8> (length 32), enabled: bool, max_age_ms: u64.

Admin functions (cap‑gated): add/update token, enable/disable, set max_age_ms.

Read functions: get symbol/name/decimals/feed_id/enabled/max_age_ms for T, and existence checks.

Inputs/Outputs: Admin functions consume AdminCap from platform; read functions are public.

Events/Errors: TokenAdded, TokenUpdated, TokenEnabled, TokenDisabled; errors for duplicate add, missing token, bad feed length, invalid decimals.

Security/Invariants: Only AdminCap mutates; pyth_feed_id must be 32 bytes; decimals in [0, 38] (reasonable bound).

Edge cases: Re‑adding existing token should abort; disabling a token used by old donations remains allowed (only blocks future).

Tests: Add→read; update fields; enable/disable; duplicate add abort; bad feed length abort.

Acceptance: Registry behaves correctly; all tests pass.

Checklist: define shared object → DOF schema → admin/read APIs → events+errors → tests.

B2. Add PriceOracle module (stateless USD valuation helper)

File / Module: sources/price_oracle.move / crowd_walrus::price_oracle

Product intent: Convert any Coin<T> amount to micro‑USD using Pyth updates inside the same PTB.

Add/Change:

Public function that takes: amount_raw (u128), decimals (u8), feed_id (vector<u8>), clock (&Clock), pyth_update (vector<u8>), and max_age_ms (u64); returns u64 micro‑USD with floor rounding.

Use u128 intermediates; enforce staleness with Pyth price publish time; validate exponent bounds.

Inputs/Outputs: Inputs listed above; output u64.

Events/Errors: Errors for stale update, missing price, invalid exponent/scale, zero amount.

Security/Invariants: Must only succeed with a fresh update (same PTB); floor rounding.

Edge cases: Tiny amounts leading to 0 micro‑USD are acceptable; document.

Tests: Stale abort; scaling tests for 6/9/18 decimals; boundary exponents.

Acceptance: Deterministic results; tests pass.

Checklist: function design → staleness logic → scaling/round → tests.

C) Campaign Aggregates
C1. Create CampaignStats shared object + creation API

File / Module: sources/campaign_stats.move / crowd_walrus::campaign_stats

Product intent: Real‑time campaign totals without scanning history.

Add/Change:

Struct: CampaignStats { id: UID, parent_id: ID, total_usd_micro: u64 }.

create_for_campaign(&Campaign, &mut TxContext) -> CampaignStats (caller shares it; emits CampaignStatsCreated { campaign_id, stats_id }).

View getter: total_usd_micro(&CampaignStats) -> u64.

Inputs/Outputs: Input parent campaign (by ref), ctx; returns object to be shared.

Events/Errors: CampaignStatsCreated; error if mismatched parent or duplicate attempt (optional).

Security/Invariants: One stats object per campaign; parent_id must match.

Edge cases: Idempotent creation if called only once by create flow.

Tests: Create stats; event fields correct; parent ID matches.

Acceptance: Stats object created & shared; tests pass.

Checklist: define struct → create API → event → getter → tests.

C2. Add per‑coin stats as dynamic object fields

File / Module: sources/campaign_stats.move

Product intent: Show per‑asset totals/counts in campaign analytics.

Add/Change:

DOF struct PerCoinStats<T> { id: UID, total_raw: u128, donation_count: u64 }.

API to initialize if missing and increment on donation.

Inputs/Outputs: On donation: call “touch/init” then “increment” for the token type T.

Events/Errors: None beyond correctness.

Security/Invariants: Overflow checks on u128/u64; init only once per T.

Edge cases: Multiple donations of same T; different T independent.

Tests: Increment twice same T; second token unaffected.

Acceptance: Per‑coin accounting correct; tests pass.

Checklist: define DOF struct → init helper → increment helper → tests.

D) Profiles (Owned Identity)
D1. ProfilesRegistry shared map address → profile_id

File / Module: sources/profiles.move / crowd_walrus::profiles

Product intent: Ensure exactly one profile per address; discoverable by indexer/UI.

Add/Change:

Shared ProfilesRegistry with DOF owner: address -> profile_id: ID.

API: exists(owner), id_of(owner) -> Option<ID>, create_for(owner, &mut TxContext) -> ID.

Emit ProfileCreated { owner, profile_id }.

Inputs/Outputs: No admin cap; only owner creates self (or PTB uses sender).

Events/Errors: Abort duplicate creation (E_PROFILE_EXISTS).

Security/Invariants: One‑to‑one mapping; only owner can create their own profile.

Edge cases: Address re‑use is identity; ok.

Tests: create→event; duplicate abort; id_of returns same ID.

Acceptance: Registry behaves; tests pass.

Checklist: define shared + DOF → APIs → event → tests.

D2. Profile object with totals + badge bitset

File / Module: sources/profiles.move

Product intent: Power donor dashboards and badge logic.

Add/Change:

Owned object Profile { id: UID, owner: address, total_usd_micro: u64, badge_levels_earned: u16, metadata: VecMap<String, String> }.

API: add_usd(&mut Profile, delta: u64) (overflow check), update_metadata (owner‑only).

Getter for badge_levels_earned.

Inputs/Outputs: Mutators require &mut Profile (passed as PTB object ref).

Events/Errors: Abort non‑owner metadata edits; abort on overflow in add_usd.

Security/Invariants: owner immutable; add_usd monotonic.

Edge cases: Large totals near u64::MAX—abort on overflow.

Tests: Owner vs non‑owner metadata; add_usd monotonic; getter works.

Acceptance: Profile correct; tests pass.

Checklist: define object → APIs → owner checks → tests.

D3. create_or_get_profile_for_sender helper

File / Module: sources/profiles.move

Product intent: One‑click donation: no separate “create profile” step.

Add/Change:

Helper that checks registry; if absent, creates; returns profile_id.

Emits ProfileCreated only when created.

Inputs/Outputs: No inputs; returns ID for PTB.

Events/Errors: see above.

Security/Invariants: Idempotent by address.

Edge cases: None.

Tests: With/without existing profile; returns expected ID.

Acceptance: Helper works; tests pass.

Checklist: implement helper → tests.

E) Badge Rewards (Soulbound)
E1. BadgeConfig shared thresholds + image URIs

File / Module: sources/badge_rewards.move / crowd_walrus::badge_rewards

Product intent: Marketing can tune milestone levels and art without code deploys.

Add/Change:

Shared object BadgeConfig { thresholds_micro: vector<u64>, image_uris: vector<String> }.

Admin APIs to set/replace config; require length=5 and strictly ascending thresholds; lengths must match.

Emit BadgeConfigUpdated.

Inputs/Outputs: Admin in; read by award logic.

Events/Errors: Abort on invalid lengths/order (E_BADGE_CONFIG_INVALID).

Security/Invariants: Match lengths; ascending strictly; URIs non‑empty.

Edge cases: No overlap or duplicates in thresholds.

Tests: Valid update; invalid lengths/order abort; reads fine.

Acceptance: Config validated and stored; tests pass.

Checklist: shared object → admin APIs → validation → event → tests.

E2. DonorBadge soulbound + Display template setup

File / Module: sources/badge_rewards.move

Product intent: Visible collectibles in wallets; non‑transferable.

Add/Change:

Owned object DonorBadge { id, level: u8, owner: address, image_uri: String, issued_at_ms: u64 }.

No transfer APIs; badges remain owned by owner.

Admin entry setup_badge_display(pub: &Publisher, &mut TxContext) to register Display fields using object fields (name includes level; image uses image_uri; description text; optional link).

Inputs/Outputs: Mint to address; display configured once.

Events/Errors: None beyond successful mint.

Security/Invariants: level ∈ 1..=5; owner set correctly.

Edge cases: None.

Tests: Badge creation; assert no transfer path available; display fields exist (via display API call in tests).

Acceptance: Badges owned and visible; tests pass.

Checklist: define badge → mint function used by awards → display setup → tests.

E3. maybe_award_badges(profile, old_total, new_total, config)

File / Module: sources/badge_rewards.move

Product intent: Reward donors instantly when crossing milestones.

Add/Change:

For each threshold crossed where corresponding bit in badge_levels_earned is 0, set bit and mint DonorBadge at that level.

Emit BadgeMinted { owner, level, profile_id, timestamp_ms } per new level.

Return list (vector<u8>) of minted levels for UI.

Inputs/Outputs: Inputs &mut Profile, &BadgeConfig, old_total: u64, new_total: u64, clock.

Events/Errors: no double‑mint by bitset check.

Security/Invariants: Idempotent; supports multi‑level jumps.

Edge cases: Exact equality at threshold mints once; re‑donate without passing new threshold mints none.

Tests: 0→L1; L1→L3; re‑donate no duplicate; exact threshold.

Acceptance: Awards correct; tests pass.

Checklist: implement compare+bitset+mint → event → return levels → tests.

F) Donations (Non‑Custodial Flow)
F1. precheck (status/time/token gate)

File / Module: sources/donations.move / crowd_walrus::donations

Product intent: Fail fast with clear error if donation can’t proceed.

Add/Change:

Validate: campaign not deleted; is_active; start_date ≤ now ≤ end_date; token T is enabled in TokenRegistry.

Inputs/Outputs: Inputs &Campaign, &TokenRegistry, &Clock, token type T; output unit or abort.

Events/Errors: Specific error codes for each failure (e.g., E_CAMPAIGN_INACTIVE, E_OUTSIDE_WINDOW, E_TOKEN_DISABLED).

Security/Invariants: Time uses Clock ms; inclusive at boundaries.

Edge cases: Exactly at start/end timestamps.

Tests: Each branch aborts; happy path passes.

Acceptance: Precheck reusable and robust; tests pass.

Checklist: assert checks → error codes → tests.

F2. split_and_send<T> (bps split + transfers)

File / Module: sources/donations.move

Product intent: Route funds immediately to recipients; no custody risk.

Add/Change:

Input Coin<T> and &PayoutPolicy.

Compute platform = floor(amount * bps / 10_000), recipient = amount − platform; recipient gets remainder.

Transfer to platform_sink and recipient_sink.

Return tuple of sent raw amounts as u128 (for event use).

Inputs/Outputs: Inputs as above; outputs platform_sent, recipient_sent.

Events/Errors: Abort on zero total donation (E_ZERO_AMOUNT), invalid sinks (shouldn’t happen due to earlier validation).

Security/Invariants: Overflow‑safe multiplication using u128 intermediates; dust handling supports 0 platform split.

Edge cases: 1 unit donation with 5% bps results in platform 0, recipient 1 (allowed).

Tests: 0%, 5%, 10_000 bps; uneven remainder; tiny amounts.

Acceptance: Transfers correct; tests pass.

Checklist: compute+transfer → return values → tests.

F3. value_in_usd_micro<T> (registry + oracle)

File / Module: sources/donations.move

Product intent: Convert donation amount to micro‑USD with correct freshness.

Add/Change:

Look up decimals, feed_id, max_age_ms in TokenRegistry for T.

Compute effective_max_age_ms = min(registry.max_age_ms, opt_caller_max_age_ms if provided).

Call price_oracle::quote_usd<T>(...).

Inputs/Outputs: Inputs amount, registry, clock, pyth_update, optional donor max age; outputs u64.

Events/Errors: Propagate stale/disabled errors; abort if token disabled.

Security/Invariants: Use u128 math; floor rounding.

Edge cases: None beyond oracle rules.

Tests: Disabled token abort; stale abort; decimal correctness.

Acceptance: Returns deterministic usd_micro; tests pass.

Checklist: wire registry → compute min age → call price oracle → tests.

F4. Donation event with canonical type + symbol

File / Module: sources/donations.move

Product intent: Power indexer/analytics and human‑readable receipts.

Add/Change:

Event DonationReceived fields: campaign_id, donor, coin_type_canonical: String, coin_symbol: String, amount_raw: u128, amount_usd_micro: u64, platform_bps: u16, platform_sink: address, recipient_sink: address, timestamp_ms: u64.

Get canonical type from std::type_name::get_with_original_ids<T>() converted to String.

Get symbol from TokenRegistry.

Inputs/Outputs: Emitted on each donation.

Events/Errors: —

Security/Invariants: No PII beyond addresses.

Edge cases: None.

Tests: Verify all fields match expected values for a donation.

Acceptance: Event emitted once per donation with correct fields; tests pass.

Checklist: define event → populate fields → tests.

F5. donate<T> entry (core, with slippage + lock toggle)

File / Module: sources/donations.move

Product intent: Core low‑level donation; used by donate_and_award.

Add/Change:

Inputs: &mut Campaign, &mut CampaignStats, &TokenRegistry, &Clock, Coin<T>, pyth_update: vector<u8>, expected_min_usd_micro: u64, opt_max_age_ms: Option<u64>, &mut TxContext.

Steps: precheck → usd_micro via F3 → assert usd_micro ≥ expected_min_usd_micro → split_and_send → increment CampaignStats.total_usd_micro and per‑coin stats → if parameters_locked == false, set it true and emit CampaignParametersLocked → emit DonationReceived → return usd_micro.

Inputs/Outputs: Returns usd_micro (u64).

Events/Errors: CampaignParametersLocked (only once) + DonationReceived; forward aborts from checks and oracle.

Security/Invariants: Atomicity; overflow checks; idempotent lock.

Edge cases: First donation triggers lock; concurrent updates fail (by A4).

Tests: Happy path; slippage abort; lock event emitted once.

Acceptance: Works end‑to‑end; tests pass.

Checklist: implement flow order → lock toggle → events → tests.

F6. donate_and_award<T> entry (auto‑profile + badges)

File / Module: sources/donations.move

Product intent: One‑click donor UX: donation + profile + badges in one PTB.

Add/Change:

Inputs: &mut Campaign, &mut CampaignStats, &TokenRegistry, &badge_rewards::BadgeConfig, &profiles::ProfilesRegistry, &Clock, Coin<T>, pyth_update, expected_min_usd_micro, opt_max_age_ms, &mut TxContext.

Steps: ensure profile exists for sender (via registry helper) and load &mut Profile; call donate<T>; increment profile total via add_usd; call maybe_award_badges with (old_total, new_total); return { usd_micro, minted_levels }.

Inputs/Outputs: Returns a small struct or tuple { u64, vector<u8> } (usd, levels).

Events/Errors: Bubble up from donate and awards.

Security/Invariants: Only owner mutates profile; idempotent awards.

Edge cases: Cross multiple thresholds; exact threshold.

Tests: First donation creates profile + possibly mints badge; repeat donation crosses next threshold.

Acceptance: Orchestration correct; tests pass.

Checklist: compose profile helper → invoke donate → update profile/awards → tests.

G) Platform Split Templates (Admin‑managed presets)
G1. SplitPolicyRegistry (global named presets)

File / Module: sources/platform_policy.move / crowd_walrus::platform_policy

Product intent: Business can add/adjust split presets (e.g., “Commercial 10%”) for future campaigns.

Add/Change:

Shared object mapping policy_id: String -> { platform_bps: u16, platform_sink: address, enabled: bool }.

AdminCap‑gated add/update/enable/disable APIs; emit PolicyAdded, PolicyUpdated, PolicyDisabled.

Inputs/Outputs: Admin in; read by create flow.

Events/Errors: Validate bps bounds; zero sink abort; duplicate id abort.

Security/Invariants: Only AdminCap mutates; preset changes never touch existing campaigns (snapshot model).

Edge cases: Disabling a preset used by old campaigns is fine (snapshot is copied).

Tests: Add/update/disable; invalid bps or zero sink abort; reads correct.

Acceptance: Registry works; tests pass.

Checklist: shared + DOF or table → admin APIs → events → tests.

G2. create_campaign resolves preset or explicit policy

File / Module: sources/crowd_walrus.move

Product intent: Simple UI—choose preset or specify explicit split; existing campaigns remain stable.

Add/Change:

Overload or extend to accept either policy_id: Option<String> or an explicit PayoutPolicy.

If policy_id provided: resolve from SplitPolicyRegistry; snapshot values into the new Campaign.

If both provided, explicit wins (document).

Inputs/Outputs: Same outputs; stored policy is resolved/captured.

Events/Errors: Missing/disabled preset abort; invalid explicit policy abort.

Security/Invariants: Snapshot copied; changes to preset later do not affect campaign.

Edge cases: Ambiguous inputs—prefer explicit.

Tests: Create with preset; create with explicit; disabled preset aborts.

Acceptance: Works as specified; tests pass.

Checklist: read registry → branch logic → snapshot copy → tests.

H) Events & Documentation
H1. Finalize and document all new events

File / Module: in respective modules

Product intent: Make indexer integration deterministic from day one.

Add/Change:

Ensure final field sets and types match the PRD table (DonationReceived, ProfileCreated, BadgeMinted, CampaignParametersLocked, CampaignStatsCreated, Policy* events, Token* events).

Add a single source of truth list in Documentation/UPDATE_IMPLEMENTATION.md.

Inputs/Outputs: —

Events/Errors: —

Security/Invariants: No PII; include timestamps.

Edge cases: None.

Tests: Each event emitted where expected; assert field equality in test logs.

Acceptance: Events consistent and documented.

Checklist: audit all emits → update docs → tests.

I) Admin Surfaces
I1. TokenRegistry admin enforcement

File / Module: sources/token_registry.move

Product intent: Safe operations team interfaces.

Add/Change: Verify only AdminCap can mutate; emit events; comprehensive error coverage.

Inputs/Outputs: —

Events/Errors: Already defined in B1.

Security/Invariants: Confirm cap checks in every mutator.

Edge cases: None.

Tests: Unauthorized calls abort; authorized succeed; events emitted.

Acceptance: Passes tests.

Checklist: audit guards → add tests.

I2. BadgeConfig admin enforcement

File / Module: sources/badge_rewards.move

Product intent: Marketing control with guardrails.

Add/Change: Ensure capability requirement; validate data; emit update event.

Inputs/Outputs: —

Events/Errors: Already defined in E1.

Security/Invariants: Sorting, length check.

Edge cases: None.

Tests: Unauthorized abort; invalid config abort; success path emits event.

Acceptance: Passes tests.

Checklist: guards → validations → tests.

I3. SplitPolicyRegistry admin enforcement

File / Module: sources/platform_policy.move

Product intent: Business control of presets for future campaigns.

Add/Change: Cap‑gated; events on add/update/disable; validation.

Inputs/Outputs: —

Events/Errors: Already defined in G1.

Security/Invariants: bps bounds; sink valid; cannot delete a preset in use (not necessary, but can be allowed since campaigns snapshot).

Edge cases: None.

Tests: Unauthorized abort; events; reads.

Acceptance: Passes tests.

Checklist: guards → events → tests.

J) Tests & Integration
J1. Unit test suites (one per module)

Files:

tests/token_registry_tests.move

tests/price_oracle_tests.move

tests/campaign_stats_tests.move

tests/profiles_tests.move

tests/badge_rewards_tests.move

tests/donations_tests.move

Product intent: Guarantee each building block works before e2e.

Add/Change: Write focused tests per acceptance criteria above; assert events and aborts.

Inputs/Outputs: —

Events/Errors: Verify specific error codes and event fields.

Security/Invariants: Overflow/staleness/locking.

Edge cases: Boundary timestamps; tiny donations; 0% and 100% bps.

Acceptance: All unit tests pass.

Checklist: author tests → run → address failures.

J2. Integration scenarios (small, focused)

File: tests/integration_phase2_tests.move

Product intent: Demonstrate end‑to‑end UX for QA and stakeholders.

Scenarios (separate test functions):

Create campaign via preset; stats created; stats_id set.

First donation with fresh Pyth update: profile auto‑created; parameters locked; stats updated; badge L1 minted; DonationReceived emitted.

Repeat donation crosses next threshold: profile reused; L2 minted; aggregates updated.

Donation with different token: per‑coin stats independent.

Slippage floor lower than actual: success. Slippage floor higher than actual: abort.

Acceptance: All scenarios pass; event logs match.

Checklist: implement 5 tests → assert events & state.

K) Documentation & DevEx
K1. Update UPDATE_IMPLEMENTATION.md

File: Documentation/UPDATE_IMPLEMENTATION.md

Product intent: Make FE/back‑end integrations trivial for PTB construction and indexer mapping.

Add/Change:

Enumerate all entry points and required object references for PTB composition (describe steps, no code).

Document rounding, staleness, slippage, locking rules, and all event schemas.

Describe how to find stats_id from Campaign and profile_id from ProfilesRegistry or events.

Acceptance: Reviewable by FE and indexer engineers; no ambiguity.

Checklist: write → review → finalize.

K2. Update README.md (module map & flows)

File: Documentation/README.md

Product intent: Fast onboarding for new contributors.

Add/Change: Module overview, primary flows (create, donate, award), admin flows, error code glossary.

Acceptance: Clear, concise, current.

Checklist: update → link to deeper docs.

L) Optional Enhancements (each ~15 min)
L1. Per‑campaign token allowlist (opt‑in)

File / Module: sources/campaign.move or sources/campaign_stats.move

Product intent: Campaigns can restrict accepted tokens to a subset of registry.

Add/Change: DOF CoinKey<T> -> bool under campaign or stats; precheck consults allowlist if present; default allow all.

Acceptance: Donations for disallowed token abort; tests pass.

Checklist: DOF + check + tests.

L2. Minimum donation thresholds (global or per‑campaign)

File / Module: sources/donations.move (global) or sources/campaign.move (per‑campaign)

Product intent: Avoid spammy micro‑donations.

Add/Change: A global min in raw units or micro‑USD; or per‑campaign field; validate in precheck.

Acceptance: Donations below min abort; tests pass.

Checklist: add config → validate → tests.

L3. Public view helpers for analytics

File / Module: sources/campaign_stats.move, sources/profiles.move

Product intent: Lightweight UIs can query totals without indexer.

Add/Change: Views for per_coin_total<T>, donation_count<T>, badge_levels(&Profile) returning the bitset or decoded levels.

Acceptance: Views return correct values; tests pass.

Checklist: add views → tests.

Notes on Admin‑Changeable Percentages (future)

Solved via presets: Admin adds/updates presets in SplitPolicyRegistry. New campaigns choose a preset, snapshotting the bps/sink. Existing campaigns remain unaffected and then lock on first donation.

If you ever need to change splits post‑creation but pre‑first‑donation, add a dual‑approval (owner + admin) flow in a future task; out of scope for Phase 2 to preserve donor trust.

Final Definition of Done (Phase 2)

All tasks A–J completed and tested; K completed for docs; optional L as time allows.

Unit and integration tests green; events validated; docs updated.

Frontend can: create campaign via preset, donate with Pyth update and slippage floor, see badges in wallet, and show totals per campaign and per token.