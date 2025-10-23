# Crowd Walrus — Phase 2 Branching Plan

A practical, testable branching strategy that mirrors your Phase‑2 tasks and checkpoints, keeps PRs small, and minimizes merge conflicts across hot files like `crowd_walrus.move` and `donations.move`.

---

## Goals

- Each branch is **buildable + testable** in isolation.
- Branch names are **traceable to tasks** (A1…L2) and **sortable**.
- You can **merge each branch directly into `main`** when it’s green.
- Clear CI/PR gates so reviews stay fast.

---

## Naming Convention

```
p2-<NN>-<track>-<scope>
```

- `p2` — Phase 2
- `<NN>` — 2‑digit sequence for easy sorting
- `<track>` — `t1` (Campaign/Stats), `t2a` (Profiles), `t2b` (Badges), `t3` (Tokens/Oracle), `t4` (Donations), `t5` (Admin/Bootstrap/Docs)
- `<scope>` — short slug aligned to your task IDs

**Example:** `p2-03-t1-campaign-stats-d1`

---

## Recommended Branch Plan (merge each to `main` when green)

> Each row = one branch (one PR). “Includes” lists the exact tasks in scope.

| # | Branch name | Includes | Base | Why this slice is testable |
|---|---|---|---|---|
| 01 | **p2-01-t3-pyth-dep-b0** | **B0** | `main` | Adds & pins Pyth; build must be green; `Move.lock` updates; `Documentation/last_deploy.md` captures commit hash. |
| 02 | **p2-02-t1-campaign-core-a1-a3** | **A1, A2, A3** | `main` | Campaign fields & validation compile standalone; unit tests for getters, validation, write‑once `stats_id`, `parameters_locked=false`. |
| 03 | **p2-03-t1-campaign-stats-d1** | **D1** | `p2-02…` | Introduces `CampaignStats` and `CampaignStatsCreated` event; tests create + link semantics (no D2 math yet). |
| 04 | **p2-04-t2a-profiles-core-e2-e1** | **E2, E1** | `main` | Profiles object + registry compile independently; tests: create, duplicate abort, owner checks. |
| 05 | **p2-05-t2a-profiles-helper-e5** | **E5** | `p2-04…` | Adds `create_or_get_profile_for_sender` with tests for both branches (existing vs new). |
| 06 | **p2-06-t5-platform-policy-h1** | **H1** | `main` | Presets registry behind AdminCap with events; tests admin ops + disabled path. |
| 07 | **p2-07-t1-create-campaign-a5-h2** | **A5, H2** | `p2-02…`, `p2-03…`, `p2-04…`, `p2-05…`, `p2-06…` | Wires `create_campaign`: explicit or preset policy, links stats, auto‑creates profile via E5. **Checkpoint α** here. |
| 08 | **p2-08-t3-tokens-oracle-b1-c1-b2** | **B1, C1, B2** | `p2-01…` | TokenRegistry + Pyth quote_usd + staleness helper as one coherent unit; tests cover decimals, floor to micro‑USD, staleness min logic. |
| 09 | **p2-09-t1-per-coin-stats-d2-d3** | **D2, D3** | `p2-03…` | Adds per‑coin DOF math and views; unit tests for multi‑token increments + getters. |
| 10 | **p2-10-t2b-badges-config-display-f1-f2-e2b** | **F1, F2, E2b** | `main` | BadgeConfig, DonorBadge, and Display setup entry (Publisher). Tests validate config shape and soulbound invariant. |
| 11 | **p2-11-t4-donations-primitives-g1-g4** | **G1, G2, G3, G4** | `p2-06…`, `p2-08…` | Precheck, split, valuation wrapper, event shape; unit tests cover time windows, disabled tokens, split rounding (“recipient gets remainder”). |
| 12 | **p2-12-t4-donate-core-lock-g5** | **G5** | `p2-03…`, `p2-09…`, `p2-11…` | Core donation orchestration + **locking toggle** (A4 folded in). Tests: slippage floor, first‑donation lock, stats increment, event fields. **Checkpoint γ**. |
| 13 | **p2-13-t2b-badge-awards-f3** | **F3** | `p2-10…` | Award logic using profile bitset + BadgeMinted events; tests crossing boundaries, idempotency. |
| 14 | **p2-14-t4-first-time-donor-g6a** | **G6a** | `p2-04…`, `p2-05…`, `p2-10…`, `p2-12…`, `p2-13…` | One‑tap donation path creates Profile internally, routes funds, updates totals, awards badges. |
| 15 | **p2-15-t4-repeat-donor-g6b** | **G6b** | `p2-14…` | Repeat donor path with &mut Profile; tests next‑badge award + totals. **Checkpoint δ**. |
| 16 | **p2-16-t2a-profile-entries-e3-e4** | **E3, E4** | `p2-04…` | Standalone profile create + metadata update entries; tests owner enforcement and length guards. |
| 17 | **p2-17-t5-bootstrap-init-b0a** | **B0a** | `p2-06…`, `p2-04…`, `p2-08…`, `p2-10…` | Publish‑time init creates & shares TokenRegistry, ProfilesRegistry, PlatformPolicy, BadgeConfig; AdminCap wiring + duplicate‑guard tests. **Checkpoint ε**. |
| 18 | **p2-18-t5-events-docs-j1** | **J1** | `main` | Event schema doc sweep + unit tests asserting event shapes (no behavior change). |
| 19 | **p2-19-tests-all-k1-k2** | **K1, K2** | all prior | Full unit + integration scenarios exactly as listed; concurrency + slippage + multi‑token. |
| 20 | **p2-20-docs-l1-l2** | **L1, L2** | all prior | Dev recipes, Publisher/Display notes, oracle update bundling, README refresh. **Checkpoint ζ**. |

**Why 20?** Each PR is a coherent, testable increment while limiting “touch hot files” overlap. See the **Compact Variant** below if you prefer fewer PRs.

---

## Merge Order / Dependencies (at a glance)

```
01 → 08
02 → 03 → 07
04 → 05 → 07
06 → 07
07 = Checkpoint α

08 → 11 → 12
03 → 09 → 12
10 → 13 → 14 → 15
12 → 14 → 15
15 = Checkpoint δ

04 → 16 (independent)
06,04,08,10 → 17  (bootstrap)
18,19,20 can follow once behavior is complete
```

Tag milestones after merges to `main`:
- `p2-alpha` at PR #07
- `p2-gamma` at PR #12
- `p2-delta` at PR #15
- `p2-epsilon` at PR #17
- `p2-ship` at PR #20

---

## PR Checklist (copy into each PR)

**Build & Tests**
- [ ] `sui move build` passes
- [ ] `sui move test` passes
- [ ] New unit tests cover happy paths + aborts for tasks: ___
- [ ] Integration tests updated (if this PR completes a checkpoint)

**Contracts & Safety**
- [ ] All arithmetic is checked
- [ ] Error codes match spec (list)
- [ ] Events include canonical type + human symbol where required

**Docs & DevEx**
- [ ] UPDATE_IMPLEMENTATION.md updated (if entries or flows changed)
- [ ] README.md updated (if user‑visible capability changed)
- [ ] For **B0 only**: `Documentation/last_deploy.md` includes pinned Pyth revision
- [ ] For **B0a only**: init object IDs are recorded/emitted; duplicate creation is guarded

---

## CI Gates (fast + deterministic)

- **Always:** `sui move build`, `sui move test`, “no warnings” check.
- **Schema guard:** A small script that fails the PR if event structs’ field sets diverge from `Documentation/UPDATE_IMPLEMENTATION.md`.
- **Lockfile guard (B0):** If `Move.toml` changes, require `Move.lock` diff and docs update.
- **Lint (optional):** Move formatter + spellcheck for docs.

---

## How to Create and Stack the First Few Branches

```bash
# 01 — Pyth dep
git switch -c p2-01-t3-pyth-dep-b0
# … implement B0 …
git push -u origin p2-01-t3-pyth-dep-b0

# 02 — Campaign core
git switch main
git switch -c p2-02-t1-campaign-core-a1-a3
# … implement A1-A3 …
git push -u origin p2-02-t1-campaign-core-a1-a3

# 03 — CampaignStats from 02
git switch p2-02-t1-campaign-core-a1-a3
git switch -c p2-03-t1-campaign-stats-d1
# … implement D1 …
git push -u origin p2-03-t1-campaign-stats-d1
```

> Tip: Use **stacked PRs** only where a branch strictly builds on another (e.g., 03 on 02). For independent work (like 04 and 06), branch off `main` in parallel to reduce coupling.

---

## Compact Variant (≈10 PRs)

If you prefer fewer merges, combine closely related slices:

1. `p2-01-pyth-and-token-oracle` → **B0,B1,C1,B2**
2. `p2-02-campaign-core` → **A1–A3,D1**
3. `p2-03-profiles-core` → **E2,E1,E5**
4. `p2-04-platform-policy-and-create` → **H1,A5,H2** (→ **Checkpoint α**)
5. `p2-05-per-coin-stats` → **D2,D3**
6. `p2-06-badges-config-display` → **F1,F2,E2b**
7. `p2-07-donations-building-blocks` → **G1–G4**
8. `p2-08-donate-core-lock` → **G5** (→ **Checkpoint γ**)
9. `p2-09-awards-and-donor-flows` → **F3,G6a,G6b** (→ **Checkpoint δ**)
10. `p2-10-extras-bootstrap-tests-docs` → **E3,E4,B0a,J1,K1,K2,L1,L2** (→ **ε, ζ**)

---

## Tips to Keep Branches Conflict‑Free & Green

- **Stabilize shared signatures early.** In `p2-02…`, add non‑breaking getters/setters you know later PRs will need (even if not yet used).
- **Keep event names & field orders final** from their introducing PR to avoid downstream re-baselines.
- **Avoid “TODO: implement later” behavior changes** in hot modules (`crowd_walrus`, `donations`, `campaign_stats`). Prefer adding a new entry in a later PR rather than rewriting earlier ones.
- **Use `#[test_only]` utilities** for scaffolding price fixtures and time control in tests; never leak them into entry APIs.
- **Record IDs in events** where discoverability is needed (as planned for bootstrap), so later tests don’t rely on debug prints.

---

## Immediate Next Steps

1. Create **p2-01-t3-pyth-dep-b0**, pin Pyth, commit `Move.lock` and `Documentation/last_deploy.md`.
2. In parallel, start **p2-02-t1-campaign-core-a1-a3** and **p2-04-t2a-profiles-core-e2-e1**—they’re independent.
3. Branch **p2-03-t1-campaign-stats-d1** from the campaign branch, and **p2-05-t2a-profiles-helper-e5** from the profiles branch.
4. Land **p2-06-t5-platform-policy-h1**, then **p2-07-t1-create-campaign-a5-h2** to reach **Checkpoint α**.
