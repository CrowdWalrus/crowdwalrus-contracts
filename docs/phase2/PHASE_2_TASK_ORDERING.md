Crowd Walrus — Phase 2

Optimal, Non‑Blocking Task Ordering (Updated)

What changed vs. previous plan

Fix: Swap E2 → E1 → E5 (Profile before ProfilesRegistry before helper).

Tidy: Fold A4 locking into G5 (donate core) instead of a separate step.

Tracks: Split Profiles and Badges into Track 2A and Track 2B.

Slight move: B2 (staleness helper) moved earlier (after C1).

Bootstrap timing: Keep B0a late (publish‑time init) so earlier PRs stay simple.

Serial Critical Path (with checkpoints)

B0 — Add Pyth dependency in Move.toml (pin commit; lockfile)

A1 — Campaign: funding_goal_usd_micro (typed, immutable)

A2 — Campaign: PayoutPolicy type + validation

A3 — Campaign: stats_id (write‑once) + parameters_locked flag

D1 — CampaignStats (shared) + CampaignStatsCreated event

E2 — Profile object (owned: totals, bitset, metadata) ← SWAPPED UP

E1 — ProfilesRegistry (address → profile_id; emits ProfileCreated) ← SWAPPED DOWN

E5 — Helper: create_or_get_profile_for_sender (uses E2/E1)

H1 — Platform split presets registry (cap‑gated; events)

A5 + H2 — create_campaign wiring (preset selection + seeded default preset), link stats_id, auto‑create Profile via E5, emit events

★ Checkpoint α — Campaign creation works end‑to‑end (with presets and auto‑profiles).

B1 — TokenRegistry (cap‑gated; DOF; events)

C1 — PriceOracle quote_usd<T> (Pyth, floor to micro‑USD)

B2 — Effective staleness helper (min of registry vs. donor override) ← MOVED UP

D2 — Per‑coin stats DOF on CampaignStats (+ increments)

D3 — Stats views (total + per‑coin getters)

F1 — BadgeConfig (cap‑gated thresholds & URIs; event)

F2 + E2b — DonorBadge (soulbound) + Display setup entry (Publisher)

G1–G4 — Donations building blocks

G1 precheck (campaign active; token enabled)

G2 split & send (recipient gets remainder)

G3 valuation helper (registry + oracle + override)

G4 DonationReceived event shape

★ Checkpoint β — Stats & badges ready; donation building blocks in place.

G5 — donate<T> core helper (internal; includes A4 locking logic here)

slippage guard, split, stats update, toggle parameters_locked on first donation, emit event, return USD

★ Checkpoint γ — Core donations work (non‑custodial, USD valuation, stats, lock).

F3 — maybe_award_badges (bitset, mint, BadgeMinted)

G6a — donate_and_award_first_time<T> (create & transfer Profile internally; awards)

G6b — donate_and_award<T> (repeat donors with &mut Profile)

★ Checkpoint δ — Full donor UX (first‑time + repeat with badges).

E3–E4 — Standalone create_profile and update_profile_metadata (+ event)

B0a — Publish‑time bootstrap init: create/share TokenRegistry, ProfilesRegistry, PlatformPolicy, BadgeConfig; mint/transfer AdminCap

★ Checkpoint ε — Publish‑ready (shared objects exist at deploy).

J1 — Finalize event schemas & docs (names, fields, types, when emitted)

K1 — Unit tests per module (assert events, aborts, boundaries)

K2 — Integration scenarios (end‑to‑end PTBs, concurrency, slippage)

L1–L2 — Developer docs & README refresh (PTB recipes, Publisher/Display, oracle update bundling, auto‑creation rules)

★ Checkpoint ζ — Ship‑ready (green tests + docs).

Parallelization Plan (tracks)

Run these in parallel; merge at the numbered checkpoints.

Track 1 — Campaign & Stats

A1 → A2 → A3 → D1 → A5+H2 → D2 → D3

Merge at #5, #10, #15.

Track 2A — Profiles

E2 → E1 → E5 → E3 → E4

Needed by #10 (create_campaign auto‑profile) and #21 (G6a).

Merge at #8, #23.

Track 2B — Badges

F1 → F2(+E2b) → F3

Needed by #21–#22 (award flows).

Merge at #17, #20.

Track 3 — Tokens & Oracle

B0 → B1 → C1 → B2

Unblocks G3 and G5.

Merge at #13.

Track 4 — Donations

G1–G4 → G5 (with locking) → G6a → G6b

Depends on #10, #13–#15, #17–#20 as noted.

Merge at #18, #19, #21–#22.

Track 5 — Admin/Bootstrap/Tests/Docs

H1 early for presets (used by #10).

B0a at #24 (after registries/configs exist).

J1 after all event emitters (#25).

K1/K2 then L1–L2 (#26–#28).

Dependency Map (updated)

B0 → C1

A1–A3 → D1 → A5

E2 → E1 → E5 → A5 & G6a ← fixed

H1 → A5 (preset path)

B1 → G1 / G3 / C1 / B2 / G5

C1 + B2 → G3 → G5

D2 → G5

F1 + F2 → F3 → G6a/G6b

G1–G4 → G5 → G6a/G6b

B1 + E1 + H1 + F1 → B0a

All event producers → J1

Everything → K2 → L1/L2

Practical notes

Cap‑gating (I1/I2): Implement inside B1/H1/F1 as you write them; don’t defer.

Error codes: Lock early in each module to stabilize tests.

Locking (A4): Implement solely inside G5 (toggle + mutator guards) to avoid duplication.

Option<u64> override: Plumb opt_max_age_ms across B2 → G3 → G5 once.

Display: After setup_badge_display(pub, ctx), call display::update_version; document Publisher flow in L1.

Checkpoint discipline

At each checkpoint (α…ζ) run sui move test and deploy to localnet to catch cross‑module breaks early.
