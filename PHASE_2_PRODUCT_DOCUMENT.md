Crowd Walrus — Phase 2 Product Requirements Document (PRD)

Version: 1.1 (Updated)
Date: October 21, 2025 (Updated)
Owner: Crowd Walrus (Contracts & Platform)
Scope: Donations, Token Support, USD Valuation (PriceOracle), User Profiles, Badge Rewards, Campaign Aggregates, Split Policy Templates, Events & Indexing.

**Changelog v1.1:**
- Updated Section 4 (UX Scenarios): Clarified first-time vs repeat donor PTB flows; added profile auto-creation in campaign creation flow
- Updated Section 5.1 (Campaign Enhancements): Added auto-profile creation for campaign owners
- Updated Section 5.4 (Donations): Split into donate_and_award_first_time vs donate_and_award entry points
- Updated Section 5.5 (Profiles): Clarified profile creation patterns (dual-entry approach)
- Updated Section 13 (Acceptance Criteria): Emphasized profile auto-creation in both flows
- Updated Section 14 (Open Questions): Marked minimums as resolved (no enforcement in Phase 2)
- Updated Section 17 (Mapping): Added key implementation notes on dual entries and ownership model

1) Executive Summary

Phase 2 introduces donations with on‑chain USD valuation, non‑custodial fee splits, user profiles, and gamified badge rewards. We add typed campaign goals and a separate CampaignStats object for scalable, real‑time totals. Admins can define global split policy presets for future campaigns. The system is designed for trust, simplicity, and indexer‑friendly analytics.

2) Goals & Non‑Goals
2.1 Goals

Accept donations in multiple Sui tokens (SUI, WAL, USDC, USD‑stable on Sui; extensible).

Compute USD (micro‑USD) value per donation using PriceOracle (Pyth), with staleness and slippage guards.

Enforce non‑custodial fee splitting (recipient + platform) via typed PayoutPolicy.

Maintain on‑chain aggregates for campaigns and users; emit rich events for per‑donation rows (indexer).

Offer user profiles (optional, auto‑created on first donation/campaign) with cumulative USD and badge bitset.

Provide badge rewards (5 levels) as soulbound collectibles, wallet‑rendered via Display metadata.

Allow AdminCap to manage global split policy presets for new campaigns without affecting existing ones.

Lock critical campaign parameters after first donation.

2.2 Non‑Goals

Holding/withdrawing funds (we route direct to sinks).

Off‑chain storage design (beyond Walrus image URIs and indexer guidance).

Cross‑chain assets or non‑Sui oracles.

Complex per‑donation on‑chain records (we use events, not objects).

3) Users & Personas

Donor: Wants fast, safe donations, visible badges, clear USD values.

Campaign Owner: Wants predictable goals and fee splits; real‑time totals; easy creation UX.

Admin (Platform): Configures accepted tokens, price feeds, freshness; manages fee presets and badge config.

Indexer / Analytics: Needs canonical, stable event data to power feeds and leaderboards.

4) UX Scenarios (Happy Path)

Create Campaign (Owner)

Owner calls create_campaign with:

Split preset (e.g., Non‑profit 0% platform, Commercial 5% platform) or explicit PayoutPolicy.

funding_goal_usd_micro, start/end dates, recipient address.

System automatically:

Checks ProfilesRegistry; if owner has no profile, creates Profile internally and transfers to owner.

Creates CampaignStats and links its stats_id.

Emits ProfileCreated (if new), CampaignStatsCreated events.

First‑Time Donor

Donor signs a PTB that:

Includes a fresh Pyth update.

Calls donate_and_award_first_time<T>: creates Profile internally, registers in ProfilesRegistry, performs donation (prechecks, USD valuation, split & send, stats update, lock campaign params if first donation to campaign), awards badges, transfers Profile to donor.

Emits ProfileCreated, DonationReceived, and BadgeMinted (if threshold crossed) events.

Repeat Donor

Frontend queries existing profile_id from indexer/registry.

Donor signs a PTB that:

Includes owned Profile object reference and fresh Pyth update.

Calls donate_and_award<T> with &mut Profile: performs donation, updates profile totals, awards additional badges if thresholds crossed.

Emits DonationReceived and BadgeMinted (if new level) events.

Admin

Adds/updates tokens in TokenRegistry (symbol, decimals, feed id, max_age_ms).

Updates split policy presets for future campaigns (e.g., add “Commercial 10%”).

Updates BadgeConfig (thresholds + image URIs).

5) Functional Requirements
5.1 Campaign Enhancements

Typed Funding Goal: funding_goal_usd_micro: u64 stored in Campaign; immutable after creation.

PayoutPolicy (per campaign): {platform_bps, platform_sink, recipient_sink}; validated at creation; locks on first donation.

Parameter Locking: On first donation, set parameters_locked = true. After this, cannot change: start/end times, funding goal, payout policy; can change: name/description (emit events). Recipient address stays immutable.

Auto-Profile Creation: If campaign owner has no profile in ProfilesRegistry, create_campaign creates one internally and transfers to owner.

Acceptance Criteria

Creating a campaign with invalid bps (>10_000) or zero sinks fails.

After first donation, attempts to change locked fields abort with explicit error.

stats_id is stored in campaign at creation; CampaignStatsCreated emitted.

Profile is auto-created for campaign owner if they don't have one; ProfileCreated event emitted.

5.2 Token Support & Oracle Valuation

TokenRegistry (shared): For each Coin<T>, store {symbol, name, decimals, pyth_feed_id (32 bytes), enabled, max_age_ms}.

PriceOracle: quote_usd<T>(amount_raw, decimals, feed_id, clock, pyth_update, max_age_ms) → u64 (micro‑USD). Uses u128 intermediates, floor rounding, staleness check.

Per‑Token Staleness: Use min(registry.max_age_ms, donor.max_age_ms?).

Slippage Floor: expected_min_usd_micro param in donation entry. Abort if actual USD < expected.

Zero Amount & Minimums: Abort on zero donation; optional minimum thresholds (raw or micro‑USD).

Acceptance Criteria

Disabled token or stale update aborts.

Correct decimal scaling verified by tests.

Donation aborts if usd < expected_min_usd_micro.

5.3 Campaign Aggregates (Hot Path)

CampaignStats (shared, one per campaign) stores total_usd_micro and parent link.

Per‑coin stats via dynamic object fields under CampaignStats:

PerCoinStats<T> { total_raw: u128, donation_count: u64 }.

Acceptance Criteria

On donation, both totals increment correctly.

Aggregates readable without scanning events.

CampaignStatsCreated includes campaign_id and stats_id.

5.4 Donations (Non‑Custodial)

precheck: campaign active, not deleted, within dates; token enabled.

split_and_send: basis‑points split; recipient gets remainder; immediate transfers to sinks.

donate<T>: precheck → USD valuation → split & send → stats → DonationReceived event. Accepts expected_min_usd_micro, optional donor_max_age_ms.

**Two donation + award entry points:**

donate_and_award_first_time<T>: For first-time donors. Creates Profile internally and transfers it to sender. Does NOT take profile parameter. Aborts with E_USE_REGULAR_DONATE if profile already exists (user should call donate_and_award instead). Flow: check registry → create profile → donate → update profile totals → award badges → transfer profile to sender → return {usd_micro, minted_levels}.

donate_and_award<T>: For repeat donors. Requires &mut Profile parameter (user's owned Profile object). Verifies sender owns the profile. Flow: verify ownership → store old_total → donate → update profile totals → award badges → return {usd_micro, minted_levels}. Profile persists automatically (passed by reference).

**Frontend logic:** Check ProfilesRegistry (via indexer or on-chain query) for existing profile_id. If none exists, call donate_and_award_first_time. If profile_id exists, call donate_and_award with profile object reference.

Event Requirements

DonationReceived includes: campaign_id, donor, coin_type_canonical (from std::type_name::get_with_original_ids<T>()), coin_symbol (from registry), amount_raw, amount_usd_micro, platform_bps, platform_sink, recipient_sink, timestamp_ms.

Acceptance Criteria

All steps are atomic; any failure aborts entire tx.

Events emit exactly once per donation and contain all fields.

First-time donation creates and transfers profile; repeat donation uses existing profile by reference.

5.5 Profiles (Owned Objects)

ProfilesRegistry (shared): address → profile_id mapping; enforces 1:1 uniqueness; emits ProfileCreated.

Profile (owned): owner, total_usd_micro, badge_levels_earned (bitset, u16), metadata (VecMap).

**Profile Creation Patterns:**

- First-time donation: donate_and_award_first_time<T> creates profile internally, registers in ProfilesRegistry, and transfers to sender
- Direct creation: Optional create_profile() entry function for users who want a profile before donating
- Internal helper: create_or_get_profile_for_sender used by first_time entry to enforce uniqueness via registry check

Acceptance Criteria

Profile is auto‑created on first donation via donate_and_award_first_time entry.

Only owner can update profile metadata (enforced via ownership checks).

Totals increment and persist across donations.

ProfilesRegistry prevents duplicate profiles per address.

5.6 Badge Rewards (Soulbound)

BadgeConfig (shared, admin‑managed): 5 ascending thresholds_micro with image_uris (Walrus).

DonorBadge (owned, no transfer functions): level, owner, image_uri, issued_at_ms. Display template registered via admin entry; must render in wallets.

maybe_award_badges: compares old_total → new_total, sets bitset, mints any newly crossed levels; emits BadgeMinted.

Acceptance Criteria

No duplicate badge mints per level (bitset enforces).

Wallets display badges using configured Display fields.

BadgeConfig validation (lengths equal, ascending).

5.7 Split Policy Presets (Admin, Future Campaigns)

SplitPolicyRegistry (shared): Named presets (id → {platform_bps, platform_sink}) managed by AdminCap.

Create Campaign: Accept either policy_id to snapshot a preset OR explicit PayoutPolicy.

Snapshots are copied into campaign and locked on first donation; later changes in presets affect only future campaigns.

Acceptance Criteria

Admin can add/update/disable presets.

Creating with preset resolves to stored values; existing campaigns remain unaffected by later changes.

6) Events (for Indexer)
Event	When	Fields (required)
CampaignStatsCreated	On stats creation	campaign_id, stats_id, timestamp_ms
CampaignParametersLocked	First donation	campaign_id, timestamp_ms
DonationReceived	Each donation	campaign_id, donor, coin_type_canonical, coin_symbol, amount_raw, amount_usd_micro, platform_bps, platform_sink, recipient_sink, timestamp_ms
ProfileCreated	Profile first creation	owner, profile_id, timestamp_ms
BadgeConfigUpdated	Admin change	thresholds_micro, image_uris, timestamp_ms
BadgeMinted	On award	owner, level, profile_id, timestamp_ms
PolicyAdded/PolicyUpdated/PolicyDisabled	Preset changes	policy_id, bps, sink, timestamp_ms
TokenAdded/TokenUpdated/TokenEnabled/TokenDisabled	Registry changes	symbol, decimals, feed_id, max_age_ms, enabled, timestamp_ms

Indexer Guidance

Join on coin_type_canonical for canonical token identity; prefer coin_symbol for UI labels.

Treat DonationReceived as the single source of truth for per‑donation rows.

7) Non‑Functional Requirements

Atomicity: Donation cmds are all‑or‑nothing.

Performance: Acceptable contention on per‑campaign stats; not a DeFi HFT use case.

Gas: No per‑donation objects, only events + aggregate increments.

Scalability: DOFs for per‑coin stats; registry‑based token onboarding.

Security: Parameter locking; explicit bps bounds; staleness & slippage checks; overflow‑safe math (u128 intermediates).

Observability: Events contain all needed fields; no PII beyond addresses.

8) Constraints & Rules (Canonical)

Rounding: Recipient gets remainder (floor platform fee).

USD Valuation: Use floor to micro‑USD (never over‑credit).

Zero & Minimums: Abort on zero donation; optional min thresholds (global or per‑token).

Staleness: Enforce effective_max_age = min(registry.max_age_ms, donor.max_age_ms?).

Policy Changes: Locked on first donation. Preset updates affect future campaigns only.

Badges: Soulbound via no transfer functions + Sui Display; do not freeze badges.

9) Dependencies & Assumptions

Sui Framework compatible with our repo; pinned to testnet channel.

Pyth Crosschain Contracts for Sui; Pyth price update must be included in the same PTB as donate*.

Walrus Storage used for badge images (URIs stored in BadgeConfig).

Indexer available to consume events and provide feeds/search/leaderboards.

10) Risks & Mitigations
Risk	Mitigation
Oracle staleness or missing update	Enforce staleness; require expected_min_usd_micro; abort if invalid.
Admin misconfiguration (bad bps/sinks)	Strict validation; capability‑gated; event logs; presets only affect new campaigns.
Rounding disputes	Document rule (“recipient gets remainder”) and include bps + amounts in events.
Shared object contention on popular campaigns	Separate CampaignStats object; admin edits don’t lock donation path.
Spam micro‑donations	Zero abort + optional minimum thresholds.
Symbol drift vs canonical type	Emit both canonical and human symbol in events.
11) KPIs / Success Metrics

Donations: # donations, total micro‑USD donated, avg donation size.

Conversion: % first‑time donors who auto‑create profiles.

Engagement: # badges minted per level; repeat donation rate.

Campaigns: # campaigns created; % with at least one donation.

Reliability: % donations that succeed without staleness/slippage aborts.

12) Rollout Plan

Milestone A: Campaign fields + SplitPolicyRegistry + TokenRegistry.

Milestone B: PriceOracle + staleness/slippage; CampaignStats.

Milestone C: Profiles + Registry; BadgeConfig + DonorBadge + Display.

Milestone D: Donations (donate, donate_and_award_first_time, donate_and_award) + Events.

Milestone E: Integration tests; Docs refresh; QA sign‑off.

13) Acceptance Criteria (Release‑Blocking)

Campaign creation with typed goal & policy works; stats_id linked; profile auto-created for owner if missing; parameters lock on first donation.

Donations succeed for enabled tokens with fresh oracle updates; slippage guard respected; correct fee split and rounding.

Aggregates update accurately; per‑coin stats correct.

Profile auto‑creation functions in both campaign creation and first donation flows; badges mint exactly once per level; badges render in a wallet using Display.

All required events emitted with canonical type and symbol.

All unit & integration tests pass; documentation updated.

14) Open Questions & Decisions Made

✅ **Minimums (Resolved - Phase 2)**: No minimum donation enforcement in Phase 2. Accept all non-zero donations. May add optional minimums (global or per-campaign, in raw units or micro-USD) in future phase if spam becomes an issue. See optional task L2 in implementation backlog.

❓ **Additional Badge Levels**: If marketing expands beyond 5 levels, switch bitset width from u16 to u64 (supports up to 64 levels with same pattern) or handle via new module versioning? Current implementation uses u16 (16 levels max).

❓ **Per‑campaign token allowlist**: Default allow all TokenRegistry-enabled tokens. Add opt-in allowlist at campaign level for stricter curation (e.g., stablecoin-only campaigns)? See optional task L1 in implementation backlog.

15) Object Model (Summary)

Campaign: core metadata; funding_goal_usd_micro, payout_policy, stats_id, parameters_locked.

CampaignStats (shared): parent_id, total_usd_micro; DOFs: PerCoinStats<T>.

TokenRegistry (shared): Coin<T> → {symbol, name, decimals, feed_id, enabled, max_age_ms}.

PriceOracle: valuation helper (stateless).

ProfilesRegistry (shared): address → profile_id.

Profile (owned): owner, total_usd_micro, badge_levels_earned, metadata.

BadgeRewards (shared BadgeConfig + DonorBadge).

SplitPolicyRegistry (shared): presets for future campaigns.

16) Event Schemas (Reference)

DonationReceived
campaign_id, donor, coin_type_canonical, coin_symbol, amount_raw, amount_usd_micro, platform_bps, platform_sink, recipient_sink, timestamp_ms

BadgeMinted
owner, level, profile_id, timestamp_ms

CampaignParametersLocked
campaign_id, timestamp_ms

CampaignStatsCreated
campaign_id, stats_id, timestamp_ms

ProfileCreated
owner, profile_id, timestamp_ms

BadgeConfigUpdated
thresholds_micro, image_uris, timestamp_ms

PolicyAdded / PolicyUpdated / PolicyDisabled
policy_id, platform_bps, platform_sink, timestamp_ms

TokenAdded / TokenUpdated / TokenEnabled / TokenDisabled
symbol, name, decimals, feed_id, max_age_ms, enabled, timestamp_ms

17) Mapping to Engineering Tasks (Phase‑2 Backlog)

This PRD aligns with the final task list: B0 (dependencies), A1-A5 (campaign schema), B1-B2 (token registry), C1 (price oracle), D1-D3 (campaign stats), E1-E3 (profiles), F1-F3 (badge rewards), G1-G6b (donations), H1-H2 (platform policy), I1-I2 (admin surfaces), J1 (events), K1-K2 (tests), L1-L2 (docs).

**Key implementation notes:**
- G6a (donate_and_award_first_time) and G6b (donate_and_award) are separate entry points for clarity and simplicity
- Profile ownership model: owned objects passed by &mut reference for repeat donors; created and transferred for first-timers
- CampaignStats is a separate shared object (not DOF) to reduce contention between donations and admin operations

Each task is small (15–30 min), testable, and follows Sui Move best practices.

Appendix A — Design Tenets

Trust by default: lock value‑impacting parameters after first donation; snapshot presets at creation.

Simplicity on-chain: aggregates + events; no per‑donation objects.

Determinism: floor rounding; canonical type names; explicit error codes.

Scalability: separate hot‑path CampaignStats; DOFs for per‑type growth.