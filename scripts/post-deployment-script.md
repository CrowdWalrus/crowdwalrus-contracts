# Phase 2 Post-Deployment Script Guide

This document explains how the Phase 2 post-deployment automation works, what configuration it uses, and how to run it safely for the current and future deployments.

It covers:
- `scripts/post_deploy_phase2.sh`
- `deployment.addresses.testnet.2025-11-11.json`

---

## 1. High-Level Purpose

The goal of the script is to turn your existing manual, error‑prone post‑deploy steps into a **config‑driven, idempotent** flow:

- Verify that all recorded IDs in the deployment JSON actually exist on chain and have the expected types.
- Wire **SuiNS**, **token registry**, **badge config**, and **platform policies** using a single, repeatable script.
- Make updating things like Pyth feed IDs, token decimals, badge thresholds, and policy bps as simple as editing JSON and re‑running the script.

The script never hard‑codes addresses; everything comes from the deployment JSON.

---

## 2. Files and Responsibilities

### 2.1 `deployment.addresses.testnet.2025-11-11.json`

This file is the **single source of truth** for your November 11, 2025 Phase 2 testnet deployment.

Key sections:

- `network`: `"testnet"`  
  Used to assert that `sui client active-env` is also `testnet` before doing anything.

- `label`: `"phase2"`  
  Just a human label/name for this deployment.

- `deployedAt`: `"2025-11-11"`  
  Deployment date (metadata only).

- `txDigest`: publish transaction digest  
  Useful for exploring the initial publish in the Sui explorer, but not used by the script.

- `packageId`:  
  The published package ID for Phase 2, e.g.:  
  `0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e`

- `accounts.deployer`:  
  The address that published the package and owns the admin caps:  
  `0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb`

- `sharedObjects`: core shared state created at publish:
  - `crowdWalrus` → `CrowdWalrus` platform object.
  - `suinsManager` → `SuiNSManager`.
  - `policyRegistry` → `PolicyRegistry`.
  - `profilesRegistry` → `ProfilesRegistry`.
  - `badgeConfig` → `BadgeConfig`.
  - `tokenRegistry` → `TokenRegistry`.

- `ownedCaps`: critical capabilities owned by the deployer:
  - `adminCap` → `crowd_walrus::AdminCap`.
  - `suinsAdminCap` → `suins_manager::AdminCap`.
  - `publisher` → `0x2::package::Publisher` used for badge display.
  - `upgradeCap` → `0x2::package::UpgradeCap` for future upgrades.

- `globals`:
  - `clock` → always `0x6` (Sui system Clock object).
  - `pythState`, `wormholeState` → Pyth/Wormhole state object IDs.

- `migration.suinsRegistration`:
  - `nftId` → `SuinsRegistration` NFT that was registered for your namespace.
  - `registeredWithTx`, `newManager`, `newAdminCap` → historical metadata.
  - The script uses `nftId` to verify SuiNS configuration.

- `postConfig.display`:
  - `donorBadgeDisplay` → `Display<DonorBadge>` object ID.
  - `setupTx` → tx digest that created the display (for audit only).

- `postConfig.policies`:
  - A map of platform policy presets by name.
  - Example: `"commercial"` with:
    - `bps`: `500` (5% fee).
    - `platformAddress`: final fee recipient.
    - `enabled`: whether new campaigns can use this preset.
    - `txDigest`: tx that originally created/updated it (metadata only).

- `postConfig.tokens`:
  - Per‑token configuration keyed by coin type.
  - For each token:
    - `symbol`: human symbol (e.g. `"SUI"`, `"USDC"`, `"WAL"`).
    - `name`: human name (e.g. `"Sui"`, `"USD Coin"`, `"WAL Token"`).
    - `decimals`: token decimals (9 for SUI/WAL, 6 for USDC).
    - `feedId`: 32‑byte Pyth feed ID in hex string form.
    - `maxAgeMs`: default price staleness limit in milliseconds.
    - `enabled`: whether this token should be usable for donations.
    - Optional historical fields like `addTx`, `enableTx` are kept as metadata.

  Currently you have:
  - `0x2::sui::SUI`
  - `0xa1ec7f...::usdc::USDC`
  - `0x8270fe...::wal::WAL` (WAL Token)

- `postConfig.badges`:
  - `amountThresholdsMicro`: 5 strictly ascending USD thresholds (micro‑USD).
  - `paymentThresholds`: 5 strictly ascending donation count thresholds.
  - `imageUris`: 5 Walrus blob URIs for badge images.
  - `updateTx`: tx digest of the last manual update (metadata only).

These `postConfig` sections are what the script uses to push configuration into the chain.

---

### 2.2 `scripts/post_deploy_phase2.sh`

This is a Bash script that drives the Sui CLI using the JSON above. It supports:

- `dry-run` mode: print all `sui client` calls that would be executed, **without** modifying the chain.
- `apply` mode: actually run the Sui transactions.

Usage:

```bash
./scripts/post_deploy_phase2.sh [deployment_json] [mode]
```

- `deployment_json` (optional): path to the deployment config file.  
  Default: `deployment.addresses.testnet.2025-11-11.json`
- `mode` (optional): `"dry-run"` (default) or `"apply"`.

---

## 3. Script Behavior in Detail

### 3.1 Sanity checks and environment verification

1. **Prerequisites**
   - Requires `jq` and `sui` to be installed and on `PATH`.
   - Exits with an error if either is missing.

2. **Config and mode**
   - Reads:
     - `CONFIG_FILE` = first argument or default JSON path.
     - `MODE` = second argument or `"dry-run"`.
   - Validates that `MODE` is either `"dry-run"` or `"apply"`.

3. **Network safety**
   - Reads `.network` from the JSON (`"testnet"`).
   - Calls `sui client active-env`.
   - If the active environment does not match the config network, it **exits with an error** and tells you to run:
     - `sui client switch --env testnet`

This prevents accidentally applying testnet config against the wrong environment.

---

### 3.2 Object type verification (critical)

The script loads IDs from the JSON:

- `packageId`
- All entries under `sharedObjects` and `ownedCaps`
- `postConfig.display.donorBadgeDisplay`
- `migration.suinsRegistration.nftId`

It then calls `sui client object <id> --json` and checks `.type` against the expected type:

- `CrowdWalrus`:
  - Expected: `<packageId>::crowd_walrus::CrowdWalrus`
- `SuiNSManager`:
  - Expected: `<packageId>::suins_manager::SuiNSManager`
- `PolicyRegistry`:
  - Expected: `<packageId>::platform_policy::PolicyRegistry`
- `ProfilesRegistry`:
  - Expected: `<packageId>::profiles::ProfilesRegistry`
- `BadgeConfig`:
  - Expected: `<packageId>::badge_rewards::BadgeConfig`
- `TokenRegistry`:
  - Expected: `<packageId>::token_registry::TokenRegistry`
- `AdminCap`:
  - Expected: `<packageId>::crowd_walrus::AdminCap`
- `SuiNS AdminCap`:
  - Expected: `<packageId>::suins_manager::AdminCap`
- `Publisher`:
  - Expected: `0x2::package::Publisher`
- `UpgradeCap`:
  - Expected: `0x2::package::UpgradeCap`
- Donor badge Display:
  - Expected: `0x2::display::Display<<packageId>::badge_rewards::DonorBadge>`
- SuiNS registration NFT:
  - Expected: `<suinsPackage>::suins_registration::SuinsRegistration` where `suinsPackage` comes from `globals.suinsPackage`.
  - Note: `globals.suinsPackage` should match the **original** SuiNS package ID
    used by your NFT type (e.g., mainnet `0xd22b...`, testnet `0x22fa...`), not
    necessarily the `published-at` dependency ID.

If any type does not match, the script exits immediately with an error. This strongly guards against using an outdated or wrong JSON file.

---

### 3.3 SuiNS registration

Function: `ensure_suins_registration`

- Calls `sui client dynamic-field <suinsManagerId> --json` and looks for a dynamic field whose `name.type` ends with `::suins_manager::RegKey`.
  - If present:
    - Confirms the stored SuinsRegistration object ID matches `migration.suinsRegistration.nftId`.
    - Logs that SuiNS is already configured and does nothing else.
  - If absent:
    - Logs that SuiNS registration is missing.
    - Prints/runs:
      ```bash
      sui client call \
        --package <packageId> \
        --module suins_manager \
        --function set_suins_nft \
        --args <suinsManagerId> <suinsAdminCapId> <suinsNftId> \
        --gas-budget 15000000
      ```

This makes SuiNS configuration **idempotent** and safe to re-run.

**Important for migrations between contracts**:

- The script only handles the **second half** of the migration (`set_suins_nft` on the new manager), assuming you already control the `SuinsRegistration` NFT in your wallet.
- When moving from an OLD package/manager to a NEW one, the full migration flow is:
  1. **Return the NFT from the OLD manager to your wallet** (manual step, using the OLD package):
     ```bash
     sui client call \
       --package $OLD_PACKAGE_ID \
       --module suins_manager \
       --function remove_suins_nft \
       --args $OLD_SUINS_MANAGER_ID $OLD_SUINS_ADMIN_CAP_ID $DEPLOYER_ADDRESS \
       --gas-budget 15000000

     # Optional: verify the NFT is owned by your deployer address again
     sui client object $SUINS_NFT_ID --json | jq -r '.owner'
     ```
     If this aborts with `E_SUINS_NFT_NOT_FOUND`, the OLD manager did not hold the NFT; you can skip this step if you already control a valid registration NFT.
  2. **Run the post-deploy script for the NEW package/manager** (with the new JSON).  
     If the new manager does not yet hold the NFT, `ensure_suins_registration` will call:
     ```bash
     sui client call \
       --package $PACKAGE_ID \
       --module suins_manager \
       --function set_suins_nft \
       --args $SUINS_MANAGER_ID $SUINS_ADMIN_CAP_ID $SUINS_NFT_ID \
       --gas-budget 15000000
     ```
     This moves the `SuinsRegistration` NFT into the NEW manager so campaign creation can register subdomains.

---

### 3.4 Token registry configuration (SUI, USDC, WAL)

Function: `ensure_token_config`

For each token type key in `postConfig.tokens`:

1. Reads from JSON:
   - `symbol`
   - `name`
   - `decimals`
   - `feedId` (Pyth feed hex)
   - `maxAgeMs`
   - `enabled`

2. Checks if token metadata already exists:
   - `sui client dynamic-field <tokenRegistryId> --json`
   - Looks for `name.type` containing the given coin type (e.g. `0x2::sui::SUI`).
   - If no dynamic field is found (new environment):
     - Calls `crowd_walrus::add_token<T>`:
       ```bash
       sui client call \
         --package <packageId> \
         --module crowd_walrus \
         --function add_token \
         --type-args <CoinType> \
         --args \
           <tokenRegistryId> \
           <adminCapId> \
           "<SYMBOL>" \
           "<NAME>" \
           <decimals> \
           <feedId> \
           <maxAgeMs> \
           <clockId> \
         --gas-budget 20000000
       ```
     - If `enabled` is `true`, also calls `set_token_enabled<T>(..., true, clock)`.

   - If metadata already exists (your current testnet):
     - Always calls:
       - `update_token_metadata<T>` to sync symbol/name/decimals/pyth_feed_id.
       - `set_token_max_age<T>` to set `maxAgeMs`.
       - `set_token_enabled<T>` to reflect the `enabled` flag.

This ensures SUI, USDC, WAL (and any future tokens you add) are fully configured exactly as described in your JSON.

---

### 3.5 Badge configuration

Function: `ensure_badge_config`

Reads:

- `postConfig.badges.amountThresholdsMicro`
- `postConfig.badges.paymentThresholds`
- `postConfig.badges.imageUris`

Then prints/runs:

```bash
sui client call \
  --package <packageId> \
  --module crowd_walrus \
  --function update_badge_config \
  --args \
    <badgeConfigId> \
    <adminCapId> \
    [amounts...] \
    [payments...] \
    [imageUris...] \
    <clockId> \
  --gas-budget 25000000
```

This directly drives `update_badge_config` and allows you to tune badge thresholds and artwork by editing JSON only.

---

### 3.6 Platform policy presets

Function: `ensure_policies`

1. Reads `postConfig.policies` (map of policy names to config).
2. Fetches the internal table ID from `PolicyRegistry.policies`.
3. For each policy (e.g. `"standard"`, `"commercial"`):
   - Reads:
     - `bps` → platform fee in basis points.
     - `platformAddress` → fee recipient.
     - `enabled` → boolean.
   - Checks via `sui client dynamic-field <policyTableId> --json` whether an entry exists whose `name.value` equals the policy name.
   - If the policy **does not exist yet** (fresh publish):
     - Calls:
       ```bash
       sui client call \
         --package <packageId> \
         --module crowd_walrus \
         --function add_platform_policy \
         --args \
           <policyRegistryId> \
           <adminCapId> \
           "policyName" \
           <bps> \
           <platformAddress> \
           <clockId> \
         --gas-budget 15000000
       ```
   - If the policy **already exists**:
     - Calls:
     ```bash
     sui client call \
       --package <packageId> \
       --module crowd_walrus \
       --function update_platform_policy \
       --args \
         <policyRegistryId> \
         <adminCapId> \
         "policyName" \
         <bps> \
         <platformAddress> \
         <clockId> \
       --gas-budget 15000000
     ```
   - Then calls either:
     - `enable_platform_policy` or
     - `disable_platform_policy`  
     depending on `enabled`.

This works both for a fresh publish (where `"commercial"` does not exist yet) and for later re-runs where policies already exist.

---

### 3.7 Badge display verification

Function: `ensure_badge_display`

- If `postConfig.display.donorBadgeDisplay` is **present and non-empty**:
  - Reuses `check_object_type` to assert that it is a `Display<DonorBadge>` for the current `packageId`.
  - This is the normal path for deployments where the Display has already been created and recorded.
- If no Display ID is present in the JSON (typical for a brand-new publish):
  - In `apply` mode:
    - Calls `badge_rewards::setup_badge_display(Publisher)` via:
      ```bash
      sui client call \
        --package <packageId> \
        --module badge_rewards \
        --function setup_badge_display \
        --args <publisherId> \
        --gas-budget 15000000 \
        --json
      ```
    - Parses the transaction JSON to find the new `Display<DonorBadge>` object ID and logs it so you can paste it into `postConfig.display.donorBadgeDisplay`.
  - In `dry-run` mode:
    - Prints the `setup_badge_display` command that would be run and reminds you to capture the new Display ID after applying.

This makes badge display setup safe for both fresh publishes and subsequent runs.

---

## 4. Running the Script (Current Deployment)

From the repo root (`crowd-walrus-contracts`):

### 4.1 Dry run (recommended first)

```bash
./scripts/post_deploy_phase2.sh deployment.addresses.testnet.2025-11-11.json dry-run
```

This will:

- Check that you’re on `testnet`.
- Verify every object ID and type in the JSON.
- Print all `sui client call` commands that would be executed to:
  - Re‑assert SuiNS registration (if needed).
  - Configure SUI, USDC, WAL in the token registry.
  - Configure badge thresholds and image URIs.
  - Configure platform policy presets (e.g. `commercial`).

No on-chain state is changed in `dry-run` mode.

### 4.2 Apply changes

Once the dry run output looks correct:

```bash
./scripts/post_deploy_phase2.sh deployment.addresses.testnet.2025-11-11.json apply
```

This will:

- Use the same logic as the dry run.
- Actually send the Sui transactions to testnet using your active wallet (which must hold `AdminCap` and related caps).

You can safely re-run `apply` multiple times; the script is designed to be idempotent:

- It will not try to re‑register SuiNS if already registered.
- It will keep tokens/policies/badge config in sync with whatever is in the JSON.

---

## 5. Using This for Future Deployments

For a new Phase 2 deployment (fresh publish or upgrade with the same deployer):

1. **Start from the template JSON**

   You can either copy the template:

   ```bash
   cp deployment.addresses.testnet.template.json deployment.addresses.testnet.YYYY-MM-DD.json
   ```

   or, if you prefer, copy an existing dated file:

   ```bash
   cp deployment.addresses.testnet.2025-11-11.json deployment.addresses.testnet.YYYY-MM-DD.json
   ```

2. **Update core IDs**

   - `txDigest`: new publish/upgrade digest.
   - `packageId`: new package ID if you did a fresh publish (for an upgrade it may stay the same).
   - `sharedObjects.*`: new shared object IDs from the new publish.
   - `ownedCaps.*`: new cap IDs if they changed.
   - `globals.pythState` / `globals.wormholeState` if Pyth/Wormhole deployments are updated.
   - `globals.suinsPackage`: SuiNS package ID for the target network.

3. **Update post-config to match your desired state**

   - `postConfig.tokens`:
     - Add/remove tokens.
     - Tweak `feedId`, `maxAgeMs`, `enabled`.
   - `postConfig.policies`:
     - Add/update entries such as `"standard"` and `"commercial"` with desired `bps`, `platformAddress`, `enabled`.
   - `postConfig.badges`:
     - Adjust thresholds and Walrus image URIs.

4. **Run the script against the new JSON**

   - Dry run:

     ```bash
     ./scripts/post_deploy_phase2.sh deployment.addresses.testnet.YYYY-MM-DD.json dry-run
     ```

   - Apply:

     ```bash
     ./scripts/post_deploy_phase2.sh deployment.addresses.testnet.YYYY-MM-DD.json apply
     ```

This pattern lets you keep each deployment’s configuration under version control and re‑apply or tweak post‑deployment state with confidence and repeatability.

---

## 6. Summary

- `deployment.addresses.testnet.2025-11-11.json` is your canonical snapshot of the Phase 2 testnet deployment plus all desired post‑deploy settings.
- `scripts/post_deploy_phase2.sh` reads that JSON, verifies everything on-chain, and applies SuiNS, tokens (SUI/USDC/WAL), badge config, and policy presets via `sui client`.
- Everything is configurable by editing JSON; the script is idempotent and safe to re-run after upgrades or config changes.  

Use `dry-run` to audit, then `apply` to commit the changes on-chain.
