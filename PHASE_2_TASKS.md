Phase 2 — Updated Implementation Task List (Sui Move)

Global conventions (apply to all tasks)
• USD unit: micro‑USD (u64), floor rounding.
• Split rule: recipient gets remainder.
• Locking: parameters_locked = true on first donation; after that, start/end/funding_goal/payout_policy cannot change; metadata can.
• Oracle freshness: effective_max_age_ms = min(registry.max_age_ms_for_T, donor_override if provided).
• Events: include canonical type (std::type_name::get_with_original_ids<T>()) and human symbol (from TokenRegistry).
• Safety: checked arithmetic; abort on overflow; clear error codes.
• Badges: owned & non‑transferable (no transfer API); do not freeze.
• DOF for per‑coin stats and registry mappings.

B) Build & Dependencies (new upfront)
B0. Add Pyth dependency in Move.toml

File/Module: Move.toml (package manifest)

Product intent: Enable on‑chain price reads from Pyth for USD valuation.

Implement:

Add a dependency for Pyth’s Sui contracts (git + subdir = target_chains/sui/contracts).

Pin to a specific commit or tag compatible with the Sui testnet toolchain (avoid floating "main").

Move.lock must resolve successfully.

Preconditions: Sui framework dependency already present.

Postconditions: Project builds with Pyth imported.

Move patterns: External package pinning; reproducible builds.

Security/Edges: Pin to a stable commit; document the exact rev in repo docs.

Tests: sui move build succeeds; Pyth modules resolvable by other tasks.

Acceptance: Build green; Move.lock updated; docs note the pinned rev.

Deps: None.

Err codes: N/A.

A) Campaign schema & lifecycle (existing files)
A1. Typed funding goal on Campaign

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

A2. Typed PayoutPolicy on Campaign

File/Module: sources/campaign.move / crowd_walrus::campaign

Product intent: Trustworthy on‑chain split commitment.

Implement:

PayoutPolicy { platform_bps: u16, platform_sink: address, recipient_sink: address }.

Field payout_policy + getters; creation validation (bps ≤ 10_000, sinks ≠ zero).

Preconditions: Valid bps/sinks.

Postconditions: Policy stored; later locked (A4).

Patterns: Basis‑points; strong typing.

Security/Edges: 0% and 100% valid.

Tests: Valid and invalid cases.

Acceptance: Validated; getters return expected.

Deps: A5, G2.

Err codes: E_INVALID_BPS, E_ZERO_SINK.

A3. stats_id + parameters_locked

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

A4. Lock critical params after first donation

File/Module: sources/campaign.move + toggle in donations (G5/G6a/G6b)

Product intent: Prevent fee/date rug‑pulls.

Implement:

In donations, if not locked, set locked and emit CampaignParametersLocked { campaign_id, timestamp_ms }.

In campaign updaters: assert unlocked when changing start_date, end_date, funding_goal_usd_micro, payout_policy; keep metadata editable.

Preconditions: First donation detection.

Postconditions: Protected updates abort thereafter.

Patterns: One‑way toggle; idempotent.

Security/Edges: Concurrent updates fail correctly.

Tests: Pre‑donation updates succeed; post‑donation abort; single lock event.

Acceptance: Enforced & event present.

Deps: G5/G6a/G6b.

Err codes: E_PARAMETERS_LOCKED.

A5. create_campaign wiring (fields + stats)

File/Module: sources/crowd_walrus.move / crowd_walrus::crowd_walrus

Product intent: Campaigns start fully configured with aggregates linked.

Implement:

Extend to accept funding_goal_usd_micro and PayoutPolicy or preset (H2).

After campaign::new, call campaign_stats::create_for_campaign and set stats_id.

Preconditions: Valid time & policy.

Postconditions: stats_id stored; CampaignStatsCreated emitted.

Patterns: Constructor composition.

Security/Edges: Validation aborts propagate.

Tests: Happy path; invalid policy/time aborts.

Acceptance: Correct linking; event present.

Deps: C1, H2.

B) Token & oracle infrastructure
B1. TokenRegistry (per‑token metadata & staleness)

File/Module: sources/token_registry.move / crowd_walrus::token_registry

Product intent: Onboard tokens with symbols and freshness policy; drive UI labels & oracle.

Implement:

Shared TokenRegistry with DOF keyed by CoinKey<T> storing: symbol, name, decimals, pyth_feed_id (32 bytes), enabled, max_age_ms.

AdminCap‑gated: add_coin<T>, update_metadata<T>, set_enabled<T>, set_max_age_ms<T>.

Views for all fields.

Events: TokenAdded, TokenUpdated, TokenEnabled, TokenDisabled.

Preconditions: Unique per T; feed id len 32.

Postconditions: Readable by donations/oracle.

Patterns: Shared + DOF; cap‑gated.

Security/Edges: Duplicate add abort; decimals bounds.

Tests: Add/enable/disable/update; views; errors.

Acceptance: Registry complete; tests pass.

Deps: B0 (Pyth added).

Err codes: E_COIN_EXISTS, E_COIN_NOT_FOUND, E_BAD_FEED_ID.

B2. Effective staleness helper

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

File/Module: sources/price_oracle.move / crowd_walrus::price_oracle

Product intent: Deterministic USD valuation for receipts, badges, stats.

Implement:

Inputs: amount_raw (u128), decimals (u8), feed_id (vector<u8>), clock, pyth_update (vector<u8>), max_age_ms (u64).

Use u128 math; apply exponent; floor to micro‑USD; checked downcast to u64.

Reject zero amounts; stale/invalid update.

Preconditions: Fresh Pyth update in the same PTB.

Postconditions: Returns micro‑USD or abort.

Patterns: Stateless; pull‑update.

Security/Edges: Exponent sanity; staleness.

Tests: Decimals (6/9/18); stale abort; zero abort.

Acceptance: Correct outputs; tests pass.

Deps: B0, B1.

D) Campaign aggregates
D1. CampaignStats creation + event

File/Module: sources/campaign_stats.move / crowd_walrus::campaign_stats

Product intent: Live totals without scanning events.

Implement:

Shared CampaignStats { parent_id, total_usd_micro }.

create_for_campaign(&Campaign, &mut TxContext) -> CampaignStats; emit CampaignStatsCreated { campaign_id, stats_id, timestamp_ms }.

Preconditions: Not previously created.

Postconditions: Shared stats exists & is linked in A5.

Patterns: Separate shared object.

Security/Edges: Enforce one‑per‑campaign via A3 setter.

Tests: Created; event correct.

Acceptance: Pass.

Deps: A5.

Err codes: Optional E_STATS_ALREADY_EXISTS.

D2. Per‑coin stats via DOF

File/Module: sources/campaign_stats.move

Product intent: Token‑level analytics for campaigns.

Implement:

DOF PerCoinStats<T> { total_raw: u128, donation_count: u64 }.

Helpers ensure_per_coin<T>(...) and add_donation<T>(raw, usd_micro); increment total_usd_micro and per‑coin stats with overflow checks.

Preconditions: Stats exist.

Postconditions: Totals/counts updated.

Patterns: DOF per token.

Security/Edges: Overflow checks.

Tests: Multi‑token increments; counts accurate.

Acceptance: Pass.

Deps: G5/G6a/G6b.

Err codes: E_OVERFLOW.

D3. Views for stats

File/Module: sources/campaign_stats.move

Product intent: Lightweight UIs without indexer.

Implement:

Views: total_usd_micro, per_coin_total_raw<T>, per_coin_donation_count<T>.

Preconditions: —

Postconditions: Read‑only.

Patterns: Pure views.

Security/Edges: None.

Tests: Values reflect prior increments.

Acceptance: Pass.

Deps: D2.

E) Profiles (owned)
E1. ProfilesRegistry (address → profile_id)

File/Module: sources/profiles.move / crowd_walrus::profiles

Product intent: One profile per wallet; discoverable by indexer.

Implement:

Shared map (DOF) address -> profile_id.

exists, id_of, create_for(owner, ctx); emit ProfileCreated { owner, profile_id, timestamp_ms }.

Preconditions: Not already mapped.

Postconditions: Mapping persisted.

Patterns: Shared + DOF.

Security/Edges: Only create for sender; duplicate abort.

Tests: Create; duplicate abort; lookup returns same id.

Acceptance: Pass.

Deps: E2.

Err codes: E_PROFILE_EXISTS, E_NOT_OWNER.

E2. Profile object + bitset + metadata

File/Module: sources/profiles.move

Product intent: Lifetime giving + badges per user.

Implement:

Owned Profile { owner, total_usd_micro: u64, badge_levels_earned: u16, metadata: VecMap<String,String> }.

add_usd(u64) with overflow check; set_metadata (owner‑only); getters.

Preconditions: Owned by signer for mutators.

Postconditions: Totals and bitset persist.

Patterns: Owned object with strict owner checks.

Security/Edges: Overflow; KV length mismatch.

Tests: Owner vs non‑owner; totals add; metadata changes.

Acceptance: Pass.

Deps: E1.

Err codes: E_NOT_PROFILE_OWNER, E_KEY_VALUE_MISMATCH, E_OVERFLOW.

E2b. Publisher handling for Display setup (clarification)

File/Module: Documentation/UPDATE_IMPLEMENTATION.md + sources/badge_rewards.move

Product intent: Ensure we can call Display registration with the correct Publisher.

Implement:

Document how deployer obtains the sui::package::Publisher at publish time and passes &Publisher to the admin entry (setup_badge_display).

Add an admin entry in badge_rewards that accepts &Publisher and registers templates.

No object “claiming” is required in init; the deployer simply supplies the Publisher to the entry when configuring display.

Preconditions: Package published; Publisher available to deployer.

Postconditions: Display registered once per package version.

Patterns: Publisher‑gated configuration entry.

Security/Edges: Only callable by whoever controls the Publisher (implicitly the deployer).

Tests: Display entry callable in tests using a test Publisher handle.

Acceptance: Docs + callable entry present.

Deps: F2.

E3. Helper: create_or_get_profile_for_sender (optional convenience)

File/Module: sources/profiles.move

Product intent: Simplify app logic outside donations (e.g., campaign creation UX).

Implement:

If exists, return id; else create and return new id.

Preconditions: —

Postconditions: ID available to PTB.

Patterns: Registry lookup + create.

Security/Edges: Idempotent.

Tests: Both branches.

Acceptance: Pass.

Deps: E1/E2.

F) Badge rewards (soulbound)
F1. BadgeConfig (thresholds + URIs)

File/Module: sources/badge_rewards.move

Product intent: Marketing controls milestones & art.

Implement:

Shared BadgeConfig { thresholds_micro (len=5, ascending), image_uris (len=5) }.

Admin setters with validation; emit BadgeConfigUpdated.

Preconditions: AdminCap only.

Postconditions: Config stored.

Patterns: Cap‑gated; strict validation.

Security/Edges: Length/order enforced; URIs non‑empty.

Tests: Invalid shapes abort; valid emits event.

Acceptance: Pass.

Deps: I2.

F2. DonorBadge (soulbound) + Display setup entry

File/Module: sources/badge_rewards.move

Product intent: Visible, non‑transferable achievement collectibles.

Implement:

Owned DonorBadge { level, owner, image_uri, issued_at_ms } with no transfer API.

Admin entry setup_badge_display(pub:&Publisher, ctx) to register Display templates (name, image, description, link) using badge fields.

Preconditions: Level within 1..5.

Postconditions: Badge mints; wallets can render display.

Patterns: Soulbound by omission; Publisher‑gated Display.

Security/Edges: Do not freeze; invalid level abort.

Tests: Badge exists and owned; Display configured.

Acceptance: Pass.

Deps: F1, E2b.

Err codes: E_BAD_BADGE_LEVEL.

F3. Award logic with bitset & events

File/Module: sources/badge_rewards.move

Product intent: Instant recognition when donors cross milestones.

Implement:

maybe_award_badges(profile:&mut Profile, config:&BadgeConfig, old_total:u64, new_total:u64, clock) sets bits for newly crossed levels, mints badges, emits BadgeMinted { owner, level, profile_id, timestamp_ms }. Returns minted levels (vector of u8).

Preconditions: Config set; profile owned by signer.

Postconditions: New badges minted exactly once per level.

Patterns: Idempotent; multi‑level crossing.

Security/Edges: Boundary equality mints once; no duplicates.

Tests: 0→L1; L1→L3; re‑donate no duplicate; exact boundary.

Acceptance: Pass.

Deps: E2, F1, F2.

G) Donations (non‑custodial orchestration)
G1. Precheck (time/status/token)

File/Module: sources/donations.move / crowd_walrus::donations

Product intent: Early, clear failures.

Implement:

Validate: is_active, not deleted, within window (inclusive), token T enabled.

Preconditions: Inputs available.

Postconditions: Unit or abort with error.

Patterns: Pure check.

Security/Edges: Start/end boundaries; disabled token.

Tests: Each path.

Acceptance: Pass.

Deps: B1, A‑state.

Err codes: E_CAMPAIGN_INACTIVE, E_CAMPAIGN_CLOSED, E_TOKEN_DISABLED.

G2. Split & direct transfer

File/Module: sources/donations.move

Product intent: Immediate routing; predictable rounding.

Implement:

Compute platform and recipient per basis points; transfer; return sent amounts.

Preconditions: Nonzero amount; sinks valid.

Postconditions: Funds routed; no custody.

Patterns: Floor; recipient remainder; u128 intermediates.

Security/Edges: Tiny amounts may yield 0 platform.

Tests: 0%, 5%, 100%; remainder cases.

Acceptance: Pass.

Deps: A2.

Err codes: E_ZERO_DONATION.

G3. USD valuation helper (registry + oracle + override)

File/Module: sources/donations.move

Product intent: Accurate receipt value & badge basis.

Implement:

Lookup token metadata; compute effective max age (B2); call PriceOracle to get micro‑USD.

Preconditions: Token exists and enabled; update present.

Postconditions: Returns micro‑USD or abort.

Patterns: Stateless call; floor rounding.

Security/Edges: Stale abort; exponent sanity.

Tests: Decimal scaling; stale path; disabled token.

Acceptance: Pass.

Deps: B1, B2, C1.

Err codes: E_TOKEN_NOT_REGISTERED (if missing).

G4. DonationReceived event (canonical + symbol)

File/Module: sources/donations.move

Product intent: Indexer uses a single event to power donation feeds.

Implement:

Emit event with fields: campaign_id, donor, coin_type_canonical, coin_symbol, amount_raw, amount_usd_micro, platform_bps, platform_sink, recipient_sink, timestamp_ms.

Preconditions: Values computed.

Postconditions: One event per donation.

Patterns: Canonical + human labels.

Security/Edges: No PII beyond addresses.

Tests: Fields exact.

Acceptance: Pass.

Deps: B1, A2.

G5. donate<T> entry (core; slippage + locking)

File/Module: sources/donations.move

Product intent: Core donation API for integrators.

Implement:

Inputs: &mut Campaign, &mut CampaignStats, &TokenRegistry, &Clock, Coin<T>, pyth_update, expected_min_usd_micro, opt_max_age_ms, &mut TxContext.

Flow: G1 → G3 → assert slippage floor → G2 → D2 add_donation → if first donation then A4 lock → G4 event → return micro‑USD.

Preconditions: Valid inputs.

Postconditions: Funds routed; stats updated; event emitted; maybe locked.

Patterns: Atomic orchestration.

Security/Edges: Overflow checks; idempotent lock.

Tests: Happy/slippage/boundary times/remainder.

Acceptance: Pass.

Deps: A2–A4, B1–B2, C1, D1–D2, G1–G4.

Err codes: E_SLIPPAGE_EXCEEDED.

G6a. donate_and_award_first_time<T> entry (creates Profile internally)

File/Module: sources/donations.move

Product intent: Truly one‑tap first donation—no separate profile step.

Implement:

Inputs: &mut Campaign, &mut CampaignStats, &TokenRegistry, &BadgeConfig, &ProfilesRegistry, &Clock, Coin<T>, pyth_update, expected_min_usd_micro, opt_max_age_ms, &mut TxContext.

Flow: create Profile inside this entry (map in registry, create owned object, set owner); call G5 donate<T>; update profile total; call F3 maybe_award_badges; transfer the newly created Profile to the sender (ensure it ends owned by the donor); return { usd_micro, minted_levels }.

Preconditions: Sender has no existing profile (abort if exists to avoid duplicates).

Postconditions: Donation processed; profile minted to sender; badges minted if eligible.

Patterns: Owned object creation + transfer within same entry; atomic.

Security/Edges: Duplicate protection; owner set correctly.

Tests: First donation path mints profile + possibly badge; event checks.

Acceptance: Pass.

Deps: E1–E2, F1–F3, G5.

Err codes: Surface E_PROFILE_EXISTS if already mapped.

G6b. donate_and_award<T> entry (requires &mut Profile)

File/Module: sources/donations.move

Product intent: Efficient repeat donations with existing Profile.

Implement:

Inputs: &mut Campaign, &mut CampaignStats, &TokenRegistry, &BadgeConfig, &Clock, &mut Profile, Coin<T>, pyth_update, expected_min_usd_micro, opt_max_age_ms, &mut TxContext.

Flow: call G5 donate<T>; update profile totals; call F3 awards; return { usd_micro, minted_levels }.

Preconditions: Caller owns Profile (enforce owner).

Postconditions: Donation processed; badges minted as needed.

Patterns: Owned object by &mut reference; atomic.

Security/Edges: Owner check; multi‑level crossing.

Tests: Repeat donor awards next badge level; totals increment.

Acceptance: Pass.

Deps: E2, F1–F3, G5.

Err codes: Propagate underlying + E_NOT_PROFILE_OWNER on misuse.

H) Platform split presets (admin; future campaigns)
H1. platform_policy presets registry

File/Module: sources/platform_policy.move / crowd_walrus::platform_policy

Product intent: Business can add/adjust defaults (e.g., 5%→10%) for new campaigns.

Implement:

Shared registry name -> { platform_bps, platform_sink, enabled } with AdminCap‑gated add/update/enable/disable.

Events: PolicyAdded, PolicyUpdated, PolicyDisabled.

Preconditions: Valid bps & sink; unique name.

Postconditions: Presets set for future campaigns.

Patterns: Snapshot at creation (H2); existing campaigns unaffected.

Security/Edges: Duplicate names abort; bounds enforced.

Tests: Admin ops; errors; events.

Acceptance: Pass.

Deps: I1.

Err codes: E_POLICY_EXISTS, E_POLICY_NOT_FOUND, E_POLICY_DISABLED, reuse E_INVALID_BPS, E_ZERO_SINK.

H2. create_campaign supports preset or explicit policy

File/Module: sources/crowd_walrus.move

Product intent: Simple creation (choose preset) with preserved immutability post‑first donation.

Implement:

Branch: if template_name provided, resolve from platform_policy and copy into PayoutPolicy; else accept explicit PayoutPolicy.

Continue with A5 (stats creation/link).

Preconditions: Enabled preset exists if referenced.

Postconditions: Campaign stores snapshot; later preset changes don’t affect it.

Patterns: Resolve‑and‑copy; not a pointer.

Security/Edges: Missing/disabled preset abort; still validate.

Tests: Preset and explicit paths; disabled preset abort.

Acceptance: Pass.

Deps: H1, A5.

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

Verify all event field sets match: DonationReceived, CampaignStatsCreated, CampaignParametersLocked, ProfileCreated, BadgeConfigUpdated, BadgeMinted, PolicyAdded/Updated/Disabled, Token*.

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

Create via preset: stats created; stats_id linked.

First donation (G6a): profile created internally; lock toggled; stats updated; badge L1 minted.

Repeat donation (G6b): profile passed by &mut; cumulative totals; next badge; events emitted.

Different token: per‑coin stats independent.

Slippage floor: success when met; abort when not.

Acceptance: All scenarios pass with correct events and state.

L) Documentation & DevEx
L1. Update UPDATE_IMPLEMENTATION.md (developer‑facing)

File: Documentation/UPDATE_IMPLEMENTATION.md

Product intent: Engineers can assemble PTBs and admin workflows without reading code.

Implement:

PTB patterns for: first‑time donor (call G6a only), repeat donor (call G6b with &mut Profile), preset vs explicit campaign creation, Display registration using Publisher.

List entry function inputs (object refs required), rounding, slippage, staleness, locking, event schemas.

Acceptance: Clear, stepwise, unambiguous.

L2. Update README.md (product overview)

File: Documentation/README.md

Product intent: Stakeholder‑friendly summary.

Implement:

Features (donations, tokens, USD valuation, profiles, badges, stats, presets), key flows, and admin knobs.

Acceptance: Up‑to‑date & concise.

Notes on the three external feedback points

F6 ambiguity → Resolved by splitting into G6a (creates Profile internally) and G6b (requires &mut Profile). Frontend chooses based on existence. This removes ambiguity and keeps PTBs clean.

Pyth dependency → Added B0 with best practice: pin to a known commit/tag (avoid floating main). Acceptance requires build success and lockfile update.

Publisher setup → Clarified in E2b and L1 docs: use the Publisher object obtained at publish time by the deployer to call the setup_badge_display entry. No special “claiming” via OTW is required; just pass &Publisher to the admin entry that registers Display.