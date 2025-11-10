# Crowd Walrus — Upgrade Guide (Single-PTB Donations)

This guide upgrades the on-chain package so the donation flow can update Pyth and call the donation function in a single Programmable Transaction Block (PTB), without re-creating existing shared objects (TokenRegistry, BadgeConfig, ProfilesRegistry, Campaigns, CampaignStats).

Key change already in the source tree: donation entrypoints were changed from `entry fun` to `public fun`, which removes private-entry composition restrictions and lets a PTB call them after the client updates the Pyth `PriceInfoObject`.

What you will do here:
- Upgrade the package to a new version (new package ID)
- Update only the package ID in your addresses file and frontend config
- Keep all existing shared object IDs unchanged

## 0) Requirements

- Sui CLI authenticated for testnet and wallet unlocked
- jq installed (for JSON edits)
- Repo root at `crowd-walrus-contracts`

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

## 6) Frontend configuration change

- In your dapp config, set `contracts.packageId = $PKG_NEW`.
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

## 8) Single-PTB donation dry run

No code changes needed besides `packageId`:
- Build the PTB client-side: Wormhole parse/verify → Pyth `create_authenticated_price_infos_using_accumulator` → `pyth::update_single_price_feed` → call `donations::donate_and_award_first_time` or `donations::donate_and_award` (now `public fun`).
- Ensure moveCall targets use `$PKG_NEW` for `crowd_walrus::donations`.

## 9) Rollback / repeatability

If something needs adjusting, you can temporarily point the dapp back to `$PKG_OLD` while you fix and upgrade again. Objects remain unchanged by an upgrade.

## Notes

- Do not re-create TokenRegistry, BadgeConfig, ProfilesRegistry, or existing Campaign/Stats objects for an upgrade. They continue to work after you switch your moveCall targets to `$PKG_NEW`.
- Keep the `addresses.crowd_walrus` named address in `Move.toml` as-is; the toolchain manages upgrade metadata in `Move.lock`.

