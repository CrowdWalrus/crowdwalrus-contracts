# Crowd Walrus — Upgrade Guide (Single-PTB Donations)

This guide upgrades the on-chain package so the donation flow can update Pyth and call the donation function in a single Programmable Transaction Block (PTB), without re-creating existing shared objects (TokenRegistry, BadgeConfig, ProfilesRegistry, Campaigns, CampaignStats).

Current production/testnet package: `0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10` (initial Phase 2 publish on 2025-11-07).

Important: you do not need `entry` to call a function from a PTB. PTBs can invoke either `entry` or `public` functions. Using `entry` on a `public` function adds restrictions (e.g., return types must have `drop`) and triggers the `lint(public_entry)` warning. Keep donation call sites as `public fun`. 
– Reference: “MoveCall invokes either an entry or a public Move function.” (Sui docs: Programmable Transaction Blocks)

What you will do here:
- Upgrade the package to a new version (new package ID)
- Update only the package ID in your addresses file and frontend config
- Keep all existing shared object IDs unchanged

## 0) Requirements

- Sui CLI authenticated for testnet and wallet unlocked
- jq installed (for JSON edits)
- Repo root at `crowd-walrus-contracts`

### 0.1) What actually blocks single‑PTB

- Pyth package alignment: the `PriceInfoObject` you pass must come from the same Pyth package address the donations module was compiled against. If not, Sui raises `TypeMismatch` at the oracle parameter.
- Freshness checks: the `price_oracle::enforce_freshness` guard uses `max_age_ms`; if the quote is older than allowed, the donation aborts.
- Gas/coin plumbing: ensure donation coins are not the gas coin when composing multiple calls, otherwise wallets can fail coin selection.

### 0.2) Why our first “upgrade” failed (objects didn’t migrate)

- We ran `sui client upgrade` and received a new package ID `0x9d6710f1…`. On Sui, user package upgrades always yield a new package object ID.
- All existing shared objects (Campaign, CampaignStats, TokenRegistry, ProfilesRegistry, …) remained typed under the original package address `0xc762…` (for example: `0xc762…::campaign::Campaign`).
- We pointed the frontend to the new package ID immediately. This broke type‑tag queries and owner/type checks in the UI (no campaigns found, spurious ownership errors), because the chain still stores our shared objects with the old type address.
- When we also mixed Pyth state/package addresses across PTBs, we saw `TypeMismatch` on `PriceInfoObject`.

Conclusion: we created a new package, but our data surface (shared objects the UI queries) did not “migrate” to that new package. That is expected on Sui. Don’t flip the frontend to the new package ID until you provide a migration or a dual‑query strategy.

Concrete proof (testnet, current state):

```
# Example campaign still typed under the old package (0xc762…)
sui client object 0x9e1a648ba30630aa85f3f38dc29c49a01621b0cd9c8d8b084068814e85669ebd --json \
  | jq -r '.type'

# → 0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10::campaign::Campaign
```

## 0.3) Pre‑upgrade Pyth package alignment (current deployment)

The current deployment (`0xc762a509…`) is linked against the Pyth “Beta” package on testnet:

- Pyth Package (Beta): `0xabf837e98c26087cba0883c0a7a28326b1fa3c5e1e2c5abdb486f9e8f594c837`
- Pyth State (Beta):   `0x243759059f4c3111179da5878c12f68d612c21a8d54d85edc86164bb18be1c7c`

Frontends must use the **same** Pyth package/state IDs as the package expects
(see the Pyth contract addresses page). Any mismatch will cause type errors.

If the frontend refreshes prices using the current state, the `PriceInfoObject` type will be from 0x431c1c…, but the donations entry expects 0xabf837…, resulting in:

`CommandArgumentError { arg_idx: 7, kind: TypeMismatch }`

Until you finish the upgrade, keep the frontend on the Beta state so the types match.

Frontend config (testnet, legacy package only):

```
pyth: {
  hermesUrl: "https://hermes-beta.pyth.network",
  pythStateId: "0x243759059f4c3111179da5878c12f68d612c21a8d54d85edc86164bb18be1c7c",
  wormholeStateId: "0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790",
}
```

Quick checks:

- Verify donations entry expects 0xabf837 types:

```
curl -s https://fullnode.testnet.sui.io:443 \
  -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"sui_getNormalizedMoveFunction","params":["'"$(jq -r '.packageId' deployment.addresses.testnet.json)'"","donations","donate_and_award_first_time"]}' \
| jq '.result.parameters[7]'
```

- Resolve the SUI PriceInfoObject under Beta:

```
node scripts/resolve-beta-priceinfo.js 0x50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266
```

After this change, the donation call will not fail at argument binding. It may still abort on business rules (e.g., campaign window) until you complete the upgrade below.

## 0.2) Move 2024 package manager note (no `[addresses]` edits)

With the Move 2024 package manager, **do not** edit `Move.toml` addresses. Address management is handled via `Published.toml` and the selected build environment.

- Use `--environment testnet` for upgrades (published package).
- Use `--environment testnet_unpublished` only for local unpublished builds/tests.

## 1) Build (sanity)

```bash
sui move build
```

## 2) Prepare variables

```bash
# Current package id as recorded in your deployment file
export PKG_OLD=$(jq -r '.packageId' deployment.addresses.testnet.json)

# Use the saved UpgradeCap from the last publish
export UPGRADE_CAP=$(jq -r '.ownedCaps.upgradeCap' deployment.addresses.testnet.json)

# Gas budget for the upgrade
export GAS_BUDGET=500000000
```

## 3) Run the upgrade

```bash
sui client upgrade \
  --upgrade-capability "$UPGRADE_CAP" \
  --verify-compatibility \
  --gas-budget "$GAS_BUDGET" \
  .
```

After execution, the CLI prints a new package object ID. Copy it and set:

```bash
export PKG_NEW=<paste-new-package-id-from-cli>
```

## 4) Update local addresses file

Only the packageId changes; all shared object IDs remain the same.

```bash
tmp=$(mktemp)
jq --arg pkg "$PKG_NEW" '.packageId=$pkg' \
  deployment.addresses.testnet.json > "$tmp" && \
mv "$tmp" deployment.addresses.testnet.json
```

## 5) Update docs that reference the package ID

- Edit `docs/phase2/FRONTEND_TESTNET_ADDRESSES.md` and replace the old package ID with `$PKG_NEW`.
- If you keep a “last deploy” note, append an entry to `deployments/` with the digest and the new package ID.

## 6) Frontend configuration change (don’t sever access to live objects)

- Do not flip `contracts.packageId` to `$PKG_NEW` until you can still see your existing shared objects in the UI. Options:
  - Keep `contracts.packageId = $PKG_OLD` and continue operating while you prepare migration/dual‑query.
  - Or, implement migration helpers (admin‑gated) in the new package to port shared objects to new types, or dual‑query both `0xOLD::module::Type` and `0xNEW::module::Type` in the UI during a transition.
- Do not touch these object IDs: `tokenRegistry`, `badgeConfig`, `profilesRegistry`, existing `campaign` and `campaignStats`.

## 7) Quick on-chain sanity checks (dev-inspect)

Verify the upgraded code can read your existing TokenRegistry:

```bash
# Example: check if SUI token is enabled in the existing registry
sui client call \
  --dev-inspect \
  --package "$PKG_NEW" \
  --module token_registry \
  --function is_enabled \
  --type-args 0x2::sui::SUI \
  --args $(jq -r '.sharedObjects.tokenRegistry' deployment.addresses.testnet.json) \
  --sender $(jq -r '.accounts.deployer' deployment.addresses.testnet.json) \
  --json | jq '.results.returnValues? // .results'
```

Expected: a boolean result. This proves upgraded functions accept the existing registry object (type identity is preserved across an upgrade).

## 8) Enable single‑PTB (what to change)

1) Keep donation entrypoints as `public fun` (no `entry` needed). If you previously added `entry` and received `lint(public_entry)` warnings, revert to `public fun` or add `#[allow(lint(public_entry))]` only if you explicitly want `entry` semantics.

2) Rebuild and upgrade. Do not flip the frontend `contracts.packageId` until either:
   - you provide admin‑gated migration functions that re‑create any user‑facing shared objects under the new package types, or
   - you implement a temporary dual‑query in the UI to read both old and new type‑tags during the transition window.

3) Keep Pyth package alignment consistent. Verify the normalized ABI expects the Pyth package address you intend to use from the client (Beta or current):

```
curl -s https://fullnode.testnet.sui.io:443 \
  -H 'Content-Type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"sui_getNormalizedMoveFunction","params":["'$PKG_NEW'","donations","donate_and_award_first_time"]}' \
| jq '.result.parameters[7]'
```

4) With those two in place, the single PTB is: Wormhole/Hermes → `pyth::update_single_price_feed` (returns/updates a `PriceInfoObject`) → `donations::donate_*` (both `public`).

Tip: keep `opt_max_age_ms` aligned with the registry’s `max_age_ms` so `price_oracle::enforce_freshness` does not abort with code `7` on stale feeds.

## 9) Rollback / repeatability

If something needs adjusting, you can temporarily point the dapp back to `$PKG_OLD` while you fix and upgrade again. Objects remain unchanged by an upgrade.

## Notes

- Do not re-create TokenRegistry, BadgeConfig, ProfilesRegistry, or existing Campaign/Stats objects for an upgrade. They continue to work after you switch your moveCall targets to `$PKG_NEW`.
- With Move 2024, do not edit `Move.toml` addresses; keep `Published.toml` updated for the active environment.

## 10) Post-upgrade Pyth switch (frontend)

Switch the frontend back to the “current” Pyth state so you use the latest package and keep following Pyth’s guidance:

```
pyth: {
  hermesUrl: "https://hermes.pyth.network",
  pythStateId: "0x1f9310238ee9298fb703c3419030b35b22bb1cc37113e3bb5007c99aec79e5b8",
  wormholeStateId: "0xaeab97f96cf9877fee2883315d459552b2b921edc16d7ceac6eab944dd88919c",
}
```

At this point, donations run as a single PTB (update then donate) without private-entry restrictions or type mismatches.
