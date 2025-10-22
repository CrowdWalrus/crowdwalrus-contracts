TL;DR — Critical‑path order (serial checkpoints)

B0 — Pyth dependency in Move.toml
Unblocks C1 and any code that imports the oracle modules.

A1 → A2 → A3 — Core Campaign schema (goal, payout policy type/validation, stats_id + parameters_locked)
Gives a stable Campaign type for everything else to plug into.

D1 — CampaignStats (shared) + event
So campaigns can link stats_id immediately.

E1 → E2 → E5 — ProfilesRegistry, Profile object, helper
Needed for profile auto‑creation in campaign creation and first‑time donations.

H1 — Platform policy presets registry (cap‑gated)
So campaigns can choose a preset; required for preset path of campaign creation.

A5 + H2 — create_campaign wiring (accept preset or explicit policy, link stats, auto‑create profile, emit events)
At this point, campaigns can be created end‑to‑end (minus donations).

B1 — TokenRegistry (cap‑gated) (+ events)
Required before valuation and donation prechecks.

C1 — PriceOracle quote_usd<T> (with Pyth)
Enables USD valuation.

D2 → D3 — Per‑coin stats DOF + views
So donations can update totals and per‑coin counts.

F1 — BadgeConfig (cap‑gated)
Foundation for awards; needed before minting.

F2 (+E2b) — DonorBadge (soulbound) + Display setup entry
Prepares the collectible; awards depend on this type existing.

B2 — Effective staleness helper
Small, but it finalizes the donation valuation inputs.

G1 → G2 → G3 → G4 — Donation building blocks

Precheck (campaign status + token enabled)

Split & send (floor; recipient remainder)

Valuation helper (registry + oracle + override)

DonationReceived event

A4 — Locking enforcement (toggle on first donation; updaters require unlocked)
Hook the lock flip into the donation path, and guard mutators.

G5 — donate<T> core (slippage guard, split, stats update, lock, event, return USD)
Now core donations work, minus badges and first‑time profile flow.

F3 — maybe_award_badges
Enables awards for donation flows.

G6a — donate_and_award_first_time<T> (creates + transfers Profile internally; awards)
One‑tap first‑donation path complete.

G6b — donate_and_award<T> (requires &mut Profile)
Repeat‑donor path complete.

E3 → E4 — Standalone create_profile & update_profile_metadata (+ event)
These are independent APIs; shipping them here avoids blocking donation work but still hits Phase‑2 acceptance.

B0a — Publish‑time bootstrap init (create/share TokenRegistry, ProfilesRegistry, PlatformPolicy, BadgeConfig; mint AdminCap)
Run after those modules exist so init can actually construct them; required for realistic integration and admin flows.

J1 — Event schema pass + doc sync
Verify all fields and names match PRD; update the reference doc.

K1 — Unit tests per module (run continuously but ensure completion now)

K2 — Integration scenarios (end‑to‑end: campaign creation, first‑time donation, repeat donor, multi‑token, slippage/lock, concurrency)

L1 → L2 — Developer docs + README refresh
Lock in PTB recipes (oracle updates in PTB, Display registration, auto‑creation rules).

Why this order works

Shortest critical path to “usable campaigns + donations”:
Campaign type → CampaignStats → Profiles helper → Presets → create_campaign → TokenRegistry → Oracle → Stats DOF → Donation blocks → donate<T> → award helpers → first‑time + repeat entries.

No circular waits:
create_campaign needs Profiles helper (E5) and presets (H1), so both precede A5. Donation core (G5) requires TokenRegistry (B1), Oracle (C1), Stats (D2), and lock logic (A4), so those precede G5.

Bootstrap init (B0a) is deliberately late:
It depends on all registries/config types existing (B1, E1, H1, F1) and cap‑gating (I1/I2). Putting it right before integration keeps earlier PRs smaller and avoids re‑writing init as types evolve.

Badges after donation core scaffolding, before donation “award” entries:
You can test donate<T> without badges; then layer F3 + G6a/G6b to complete the UX.

Parallelization plan (no blocking)

Assign 3–4 engineers across tracks; merge at the numbered checkpoints.

Track 1 — Campaign & Stats

A1–A3 → D1 → A5 (+H2) → D2–D3 → A4
Merge points: #3, #6, #9, #14

Track 2 — Profiles & Badges

E1–E2–E5 → (later) E3–E4

F1 → F2(+E2b) → F3
Merge points: #4, #10–#11, #16, #19

Track 3 — Tokens & Oracle

B0 → B1(+I1) → C1 → B2
Merge points: #1, #7, #8, #12

Track 4 — Donations Orchestration

G1–G4 → G5 → G6a → G6b
Waits for #7–#9 (registry/oracle/stats) and #14 (lock enforcement) and #10–#11–#16 (badges) as noted.
Merge points: #13, #15, #17, #18

Track 5 — Admin & Bootstrap, Tests & Docs

H1(+I1) done early (Track 1 dependency)

B0a after #7, #4, #10, #5 (all registries/config present) → #20

J1 after all event producers done → #21

K1 incrementally per module; K2 after #20 → #23

L1–L2 last → #24

“What unlocks what” (quick dependency map)

B0 → C1

A1–A3 → D1 → A5

E1–E2 → E5 → A5 & G6a

H1 → A5 (preset path)

B1 → G1/G3/C1/B2/G5

C1 + B2 → G3 → G5

D2 → G5 (per‑coin stats)

F1 + F2 → F3 → G6a/G6b

G1–G4 + A4 → G5 → G6a/G6b

B1 + E1 + H1 + F1 (+ I1/I2) → B0a

All event emitters → J1

Everything → K2 → L1/L2

Practical checkpoints (ship small, test as you go)

Checkpoint α (after #6): Campaign creation works with presets & auto‑profiles; CampaignStatsCreated emitted.

Checkpoint β (after #9): Per‑coin stats in place; read‑only views OK.

Checkpoint γ (after #15): Core donate<T> works end‑to‑end with USD valuation, slippage guard, splits, aggregates, lock toggle, event.

Checkpoint δ (after #18): Full donor UX: first‑time + repeat with badges.

Checkpoint ε (after #20): Realistic environment: shared registries/configs auto‑created at publish; AdminCap minted.

Checkpoint ζ (after #23): All unit + integration tests green; docs can be finalized.

Notes & tiny optimizations

Implement cap‑gating (I1/I2) inside B1, H1, F1 when you write them (don’t wait for a separate step).

Define shared error codes early in each module to avoid churn when tests start asserting on them.

For A4 locking, wire the toggling into G5 once, then block the campaign updaters with a simple assert_unlocked helper—keeps the surface clean.

Add the opt_max_age_ms: Option<u64> plumbing when you build B2/G3/G5 (avoid a second pass).

For Display, remember display::update_version in the admin path after setup_badge_display; document the Publisher flow in L1 (as your E2b note specifies).