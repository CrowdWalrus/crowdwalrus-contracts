# Crowd Walrus — New Testnet Deployment (Fresh Publish + Exact Post‑Config)

This guide fresh‑publishes a new Crowd Walrus package to Sui Testnet and then recreates the exact post‑deployment configuration you previously set up (policies, tokens, badge display, badge thresholds/URIs, SuiNS NFT). We intentionally do NOT migrate user data (old campaigns, user profiles) since this is a testnet reset.

Outcome: A brand‑new package with new shared objects, configured identically to your last deployment for platform‑level state (policies, tokens, badge config, display), ready for frontend use.

---

## 0) Prerequisites

- Sui CLI authenticated on `testnet` with enough gas (≥ 0.5 SUI recommended)
- `jq` installed for JSON parsing
- Repo root: this directory
- Previous deployment file present: `deployment.addresses.testnet.json`
- You still hold the SuiNS registration NFT used previously (we will move it from the OLD manager to the NEW manager)

Quick environment checks:

```bash
sui client active-env      # Should output: testnet
sui client gas             # Ensure ≥ 0.5 SUI
which jq                   # Path to jq
test -f deployment.addresses.testnet.json || echo "ERROR: previous deployment file missing"
export DEPLOYER_ADDRESS=$(sui client active-address)
echo "Deployer: $DEPLOYER_ADDRESS"
```

---

## 1) Prepare Build Addresses

Temporarily set the package address to `0x0` for a fresh publish.

```bash
# Set the package address to 0x0 for publish (portable)
sed -i.bak 's/^crowd_walrus = ".*"/crowd_walrus = "0x0"/' Move.toml

# Sanity check
grep -E '^crowd_walrus[[:space:]]*=[[:space:]]*"' Move.toml
```

Note: After successful publish, we will set this back to the new package ID.

---

## 2) Fresh Publish

```bash
# Make sure you’re on testnet and have gas
sui client active-env
sui client gas

# Publish the package
sui client publish --gas-budget 500000000
```

Copy the following from the publish output (Created Objects and Events):
- PACKAGE_ID (new)
- CROWD_WALRUS_ID (shared)
- POLICY_REGISTRY_ID (event PolicyRegistryCreated)
- PROFILES_REGISTRY_ID (event ProfilesRegistryCreated)
- BADGE_CONFIG_ID (event BadgeConfigCreated)
- SUINS_MANAGER_ID (shared; created by init)
- ADMIN_CAP_ID (owned by deployer)
- SUINS_ADMIN_CAP_ID (owned by deployer)
- PUBLISHER_ID (owned by deployer; from `0x2::package::Publisher`)
- UPGRADE_CAP_ID (owned by deployer; from `0x2::package::UpgradeCap`)

IMPORTANT: Manually copy these IDs now and export them. (Example values from the 2025‑11‑11 publish shown below.)

```bash
export TX_DIGEST="HcAuTtasTtjCJpCEhqfF3eJydnBFrA1hPZTypy1NMzvC"
export PACKAGE_ID="0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e"
export CROWD_WALRUS_ID="0xc6632fb8fc6b2ceb5dee81292855a5def8a7c4289c8c7aa9908d0d5373e1376b"
export POLICY_REGISTRY_ID="0xd8f6ef8263676816f298c1f7f311829dd3ee67e26993832e842cb7660859f906"
export PROFILES_REGISTRY_ID="0x2284d6443cbe5720da6b658237b66176a7c9746d2f8322c8a5cd0310357766b0"
export BADGE_CONFIG_ID="0x6faec79a14bcd741a97d5a42722c49e6abed148955e87cdce0ad9e505b6c5412"
export TOKEN_REGISTRY_ID="0x92909eb4d9ff776ef04ff37fb5e100426dabc3e2a3bae2e549bde01ebd410ae4"
export SUINS_MANAGER_ID="0x73d8313a788722f5be2ea362cbb33ee9afac241d2bb88541aa6a93bf08e245ac"
export ADMIN_CAP_ID="0x02596af627e9b4aa8aefbe4c83700934d51a44a559047c1e4f161e446a1f0775"
export SUINS_ADMIN_CAP_ID="0x729906c42824a50870f07ad6f30cc4dffba6e085b10e57072551bddcc6303041"
export PUBLISHER_ID="0xf12ab35c05b479b9be8224452c7ce051b520939f1045f2191d8ba0a72b22eb29"
export UPGRADE_CAP_ID="0x9ea6a8f8f76d78b28e891bdd85d119bbea8720419763a98cfb3bcc06e40f379e"
```

Resolve the TokenRegistry ID (stored as a dynamic field under `CrowdWalrus`):

```bash
# List dynamic fields on the new CrowdWalrus and grab the TokenRegistry slot
FIELD=$(sui client dynamic-field $CROWD_WALRUS_ID --json \
  | jq -r '.data[] | select(.name.type | endswith("crowd_walrus::TokenRegistryKey")) | .objectId')

# Read the field object to get the embedded value.id (the TokenRegistry object ID)
export TOKEN_REGISTRY_ID=$(sui client object $FIELD --json | jq -r '.content.fields.value.fields.id')
```

Finally, set well‑known constants:

```bash
# System Clock
export CLOCK=0x6

# Pyth testnet (Beta channel) — keep aligned with frontend until you change it
export PYTH_STATE=0x243759059f4c3111179da5878c12f68d612c21a8d54d85edc86164bb18be1c7c
export WORMHOLE_STATE=0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790
```

---

## 3) Load Previous Deployment (Source of Truth)

We will copy configuration from the previous deployment to the new one.

```bash
# Old deployment file (already in repo)
export OLD_FILE=deployment.addresses.testnet.json

# Old shared objects and caps
export OLD_POLICY_REGISTRY_ID=$(jq -r '.sharedObjects.policyRegistry' $OLD_FILE)
export OLD_PROFILES_REGISTRY_ID=$(jq -r '.sharedObjects.profilesRegistry' $OLD_FILE)
export OLD_BADGE_CONFIG_ID=$(jq -r '.sharedObjects.badgeConfig' $OLD_FILE)
export OLD_TOKEN_REGISTRY_ID=$(jq -r '.sharedObjects.tokenRegistry' $OLD_FILE)
export OLD_CROWD_WALRUS_ID=$(jq -r '.sharedObjects.crowdWalrus' $OLD_FILE)

export OLD_PACKAGE_ID=$(jq -r '.packageId' $OLD_FILE)

export OLD_ADMIN_CAP_ID=$(jq -r '.ownedCaps.adminCap' $OLD_FILE)
export OLD_SUINS_ADMIN_CAP_ID=$(jq -r '.ownedCaps.suinsAdminCap' $OLD_FILE)
export OLD_PUBLISHER_ID=$(jq -r '.ownedCaps.publisher' $OLD_FILE)

# Old SuiNS registration NFT (we will move it into the new SuiNSManager)
export SUINS_NFT_ID=$(jq -r '.migration.suinsRegistration.nftId' $OLD_FILE)
```

---

## 4) Move SuiNS Registration NFT (CRITICAL)

You previously transferred your `SuinsRegistration` NFT into the OLD SuiNSManager. We must:
1) Remove it from the OLD manager back to your wallet (deployer)
2) Set it into the NEW manager

4.1 Remove from OLD manager (type lives under the OLD package):

```bash
# Return the NFT to your wallet
sui client call \
  --package $OLD_PACKAGE_ID \
  --module suins_manager \
  --function remove_suins_nft \
  --args $OLD_SUINS_MANAGER_ID $OLD_SUINS_ADMIN_CAP_ID $DEPLOYER_ADDRESS \
  --gas-budget 15000000

# Verify you own the NFT again
sui client object $SUINS_NFT_ID --json | jq -r '.owner'
```

If this aborts with "E_SUINS_NFT_NOT_FOUND", your OLD manager did not hold the NFT; skip to the next step.

4.2 Set on NEW manager:

```bash
sui client call \
  --package $PACKAGE_ID \
  --module suins_manager \
  --function set_suins_nft \
  --args $SUINS_MANAGER_ID $SUINS_ADMIN_CAP_ID $SUINS_NFT_ID \
  --gas-budget 15000000
```

What this does: moves your `SuinsRegistration` NFT into the NEW manager; campaign creation will now be able to register subdomains.

---

## 5) Register DonorBadge Display (Recommended)

Sets wallet display metadata for the DonorBadge type using the fresh `Publisher`.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module badge_rewards \
  --function setup_badge_display \
  --args $PUBLISHER_ID \
  --gas-budget 15000000
```

---

## 6) Recreate Platform Policies (Exact Presets)

Your previous deployment exposed two presets to UIs:
- "standard" — 0 bps (platform address = deployer) [seeded automatically at publish]
- "commercial" — 500 bps, platform address = 0x4aa24001f656ee00a56c1d7a16c65973fa65b4b94c0b79adead1cc3b70261f45

6.1 Verify "standard" (no action needed unless you want a different platform address):
- It is created at publish with 0 bps and `platform_address = deployer` (the publish sender).

6.2 Add "commercial" (5%) with the same platform address as before:

```bash
export COMMERCIAL_NAME='"commercial"'
export COMMERCIAL_BPS=500
export COMMERCIAL_ADDR=0x4aa24001f656ee00a56c1d7a16c65973fa65b4b94c0b79adead1cc3b70261f45

sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function add_platform_policy \
  --args \
    $POLICY_REGISTRY_ID \
    $ADMIN_CAP_ID \
    $COMMERCIAL_NAME \
    $COMMERCIAL_BPS \
    $COMMERCIAL_ADDR \
    $CLOCK \
  --gas-budget 15000000
```

(Policies are enabled on add; you can force-enable if needed via `enable_platform_policy`.)

---

## 7) Recreate Token Registry (Exact Tokens)

We will add exactly the tokens you had before (SUI and USDC) with the same metadata and enable them.

SUI:
```bash
export SUI_TYPE=0x2::sui::SUI
export SUI_SYMBOL='"SUI"'
export SUI_NAME='"Sui"'
export SUI_DECIMALS=9
export SUI_FEED_ID=0x50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266
export SUI_MAX_AGE_MS=300000

# Add
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function add_token \
  --type-args $SUI_TYPE \
  --args \
    $TOKEN_REGISTRY_ID \
    $ADMIN_CAP_ID \
    $SUI_SYMBOL \
    $SUI_NAME \
    $SUI_DECIMALS \
    $SUI_FEED_ID \
    $SUI_MAX_AGE_MS \
    $CLOCK \
  --gas-budget 20000000

# Enable
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function set_token_enabled \
  --type-args $SUI_TYPE \
  --args $TOKEN_REGISTRY_ID $ADMIN_CAP_ID true $CLOCK \
  --gas-budget 10000000
```

USDC:
```bash
export USDC_TYPE=0xa1ec7fc00a6f40db9693ad1415d0c193ad3906494428cf252621037bd7117e29::usdc::USDC
export USDC_SYMBOL='"USDC"'
export USDC_NAME='"USD Coin"'
export USDC_DECIMALS=6
export USDC_FEED_ID=0x41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722
export USDC_MAX_AGE_MS=300000

# Add
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function add_token \
  --type-args $USDC_TYPE \
  --args \
    $TOKEN_REGISTRY_ID \
    $ADMIN_CAP_ID \
    $USDC_SYMBOL \
    $USDC_NAME \
    $USDC_DECIMALS \
    $USDC_FEED_ID \
    $USDC_MAX_AGE_MS \
    $CLOCK \
  --gas-budget 20000000

# Enable
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function set_token_enabled \
  --type-args $USDC_TYPE \
  --args $TOKEN_REGISTRY_ID $ADMIN_CAP_ID true $CLOCK \
  --gas-budget 10000000
```

(If you previously changed per‑token `max_age_ms`, repeat via `set_token_max_age<T>`.)

---

## 8) Reapply Badge Thresholds and Image URIs (Exact Copy)

Read the values from the old `BadgeConfig`, then set them on the new one verbatim.

```bash
# Read old values (compact JSON arrays)
export OLD_BADGE_AMOUNTS=$(sui client object $OLD_BADGE_CONFIG_ID --json | jq -c '.content.fields.amount_thresholds_micro')
export OLD_BADGE_COUNTS=$(sui client object $OLD_BADGE_CONFIG_ID --json | jq -c '.content.fields.payment_thresholds')
export OLD_BADGE_URIS=$(sui client object $OLD_BADGE_CONFIG_ID --json | jq -c '.content.fields.image_uris')

# Apply to new config
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function update_badge_config \
  --args \
    $BADGE_CONFIG_ID \
    $ADMIN_CAP_ID \
    "$OLD_BADGE_AMOUNTS" \
    "$OLD_BADGE_COUNTS" \
    "$OLD_BADGE_URIS" \
    $CLOCK \
  --gas-budget 25000000
```

Validation (optional):
```bash
sui client object $BADGE_CONFIG_ID --json | jq '.content.fields | {amount_thresholds_micro,payment_thresholds,image_uris}'
```

---

## 9) Persist New Deployment Addresses

Write a *new* JSON file stamped with today’s date (keep older files untouched). Example for 2025‑11‑11:

```bash
jq -n \
  --arg network "testnet" \
  --arg label "phase2" \
  --arg pkg  "$PACKAGE_ID" \
  --arg cw   "$CROWD_WALRUS_ID" \
  --arg pol  "$POLICY_REGISTRY_ID" \
  --arg prof "$PROFILES_REGISTRY_ID" \
  --arg tok  "$TOKEN_REGISTRY_ID" \
  --arg badge "$BADGE_CONFIG_ID" \
  --arg sm   "$SUINS_MANAGER_ID" \
  --arg admin "$ADMIN_CAP_ID" \
  --arg suinsAdmin "$SUINS_ADMIN_CAP_ID" \
  --arg publisher "$PUBLISHER_ID" \
  --arg upgrade "$UPGRADE_CAP_ID" \
  --arg clock "$CLOCK" \
  --arg pyth  "$PYTH_STATE" \
  --arg worm  "$WORMHOLE_STATE" \
  --arg deployer "$DEPLOYER_ADDRESS" \
  '{
    network: $network,
    label: $label,
    deployedAt: (now | strflocaltime("%Y-%m-%d")),
    packageId: $pkg,
    accounts: { deployer: $deployer },
    sharedObjects: {
      crowdWalrus: $cw,
      suinsManager: $sm,
      policyRegistry: $pol,
      profilesRegistry: $prof,
      badgeConfig: $badge,
      tokenRegistry: $tok
    },
    ownedCaps: {
      adminCap: $admin,
      suinsAdminCap: $suinsAdmin,
      publisher: $publisher,
      upgradeCap: $upgrade
    },
    globals: {
      clock: $clock,
      pythState: $pyth,
      wormholeState: $worm
    }
  }' > deployment.addresses.testnet.$(date +%Y-%m-%d).json

cat deployment.addresses.testnet.$(date +%Y-%m-%d).json
```

Archive naming pattern keeps a dated file for each deploy, and the canonical `deployment.addresses.testnet.json` points at the latest deployment for tooling. Keep both.

---

## 10) Update Move.toml Back to New Package

```bash
sed -i.bak "s/^crowd_walrus = \"0x0\"/crowd_walrus = \"$PACKAGE_ID\"/" Move.toml

# Verify
grep -E '^crowd_walrus[[:space:]]*=[[:space:]]*"' Move.toml
```

---

## 11) Quick Sanity Checks

```bash
# Modules exist
sui client object $PACKAGE_ID --json | jq -r '.content.disassembled | keys[]' | sort

# Policy presets (spot‑check by calling create_campaign with none/some("commercial"))
# Tokens present
sui client object $TOKEN_REGISTRY_ID

# Badge config populated
sui client object $BADGE_CONFIG_ID --json | jq '.content.fields | {amount_thresholds_micro,payment_thresholds,image_uris}'
```

---

## Notes

- We intentionally did not migrate user campaigns or user profiles in this guide.
- Keep the NEW AdminCap on the deployer; no transfer is required for this fresh testnet deploy.
- Pyth package/state alignment for donations remains unchanged; ensure the frontend requests a price from the same Pyth package/state expected by your compiled code before donation calls.
- If you add more tokens or presets later, repeat the same entry functions with the new values.

---

## Frontend Update

- Update frontend env/config with:
  - `contracts.packageId = $PACKAGE_ID`
  - Shared object IDs: `crowdWalrus`, `policyRegistry`, `profilesRegistry`, `badgeConfig`, `tokenRegistry`, `suinsManager`
- Old campaigns/profiles from the previous package will not appear (expected for fresh publish).

## Troubleshooting

- `remove_suins_nft` aborts E_SUINS_NFT_NOT_FOUND: the OLD manager did not hold the NFT; proceed to `set_suins_nft` on the NEW manager if you still have the NFT, otherwise obtain/issue a new registration NFT.
- `set_suins_nft` aborts E_SUINS_NFT_ALREADY_REGISTERED: you already set it on the NEW manager.
- Token add/enable errors: verify type, decimals, and Pyth feed IDs; ensure `--type-args` is present for generic token functions.

---

Last updated: 2025-11-11
