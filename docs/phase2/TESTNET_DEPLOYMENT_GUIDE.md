# Phase 2 Testnet Deployment Guide

## Overview

This guide covers deploying Phase 2 of Crowd Walrus to Sui Testnet. Phase 2 adds multi-token donations, USD pricing via Pyth, profiles, badges, and platform policies to the existing campaign system.

**Deployment Options:**
1. **Fresh Publish**: Creates all new shared objects with new IDs
2. **Upgrade**: Preserves existing shared object IDs using your `UpgradeCap`

This guide covers **fresh publish**. For upgrades, see the [Upgrade Path](#upgrade-path-alternative) section.

---

## Prerequisites: Sui & Tooling

As of November 7, 2025, the latest Sui Testnet release is `testnet-v1.60.0`. Update your CLI to the exact Testnet release before deploying to avoid protocol/version mismatches.

### A. Install or Update `suiup`

```bash
# Install suiup (if not already installed)
curl -sSfL https://raw.githubusercontent.com/MystenLabs/suiup/main/install.sh | sh

# Ensure ~/.local/bin is on PATH (macOS zsh example)
# Run these if `command -v suiup` returns nothing
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Sanity check
command -v suiup && suiup list
```

### B. Pin Sui CLI to Testnet `1.60.0`

```bash
# Install the exact Testnet build and set it default
suiup install sui@testnet-1.60.0 -y
suiup default set sui@testnet-1.60.0

# Verify version and path
sui --version
suiup which sui
which -a sui   # Ensure the suiup path is first
```

Tip: To always get the newest Testnet build when this guide becomes stale, you can run:

```bash
suiup install sui@testnet -y
```

### C. Optional: Install/Update Walrus CLI

```bash
# Installs the latest Testnet-compatible Walrus CLI
suiup install walrus -y
walrus --version
```

Why update before deploy?
- Each Sui network (testnet/mainnet) runs a specific protocol/release. Using an older CLI can fail on publish/upgrade or encode calls incorrectly.
- `suiup` makes it easy to pin and switch versions, so rollbacks are instant if needed (`suiup show` then `suiup default set <version>`).

---

## Pre-Deployment Checklist

### 1. Verify Your Environment

```bash
# Confirm you're on testnet
sui client active-env
# Should output: testnet

# If not on testnet, switch now (safe to run even if already on testnet)
sui client switch --env testnet

# Check your active address (this will be the deployer/admin)
sui client active-address

# Check gas balance (need ~0.2-0.5 SUI for deployment)
sui client gas
```

**Required Gas:**
- **Package Publish**: 200,000,000 - 500,000,000 MIST (0.2 - 0.5 SUI)
- **Admin Calls**: 10,000,000 - 30,000,000 MIST each (0.01 - 0.03 SUI)

### 2. Verify Build

```bash
cd /Users/alireza/Codes/crowd-walrus-contracts

# Clean build
sui move build

# Run all tests to ensure everything passes
sui move test
```

### 3. Review Dependencies

Confirm these are in your `Move.toml`:
- ✅ Sui Framework: implicit (no explicit Sui dependency; CLI resolves the correct framework for Testnet)
- ✅ Pyth: `sui-contract-testnet`
- ✅ SuiNS: `crowdwalrus-testnet-core-v2`
- ✅ Subdomains: `crowdwalrus-testnet-core-v2`
- ✅ Denylist: `crowdwalrus-testnet-core-v2`

---

## Deployment Steps

### Step 1: Deploy the Package

```bash
# Deploy to testnet with adequate gas
sui client publish --gas-budget 500000000
```

**Expected outputs:**
- Transaction Digest
- **Package ID** (most important - save this!)
- Publisher object ID (needed for badge display setup)
- UpgradeCap object ID (save for future upgrades)

> The package initializer now claims the Publisher automatically via `package::claim_and_keep`, so capture the Publisher from the **Created Objects** section right after `sui client publish` completes.

**Owned objects created (transferred to deployer):**
1. `crowd_walrus::AdminCap` - Main admin capability
2. `suins_manager::AdminCap` - SuiNS admin capability
3. `0x2::package::Publisher` - For badge display setup
4. `0x2::package::UpgradeCap` - For future upgrades

**Shared objects created:**
1. `CrowdWalrus` - Main platform object
2. `SuiNSManager` - SuiNS subdomain manager
3. `TokenRegistry` - Token metadata registry (stored as dynamic field)
4. `ProfilesRegistry` - User profile registry
5. `PolicyRegistry` - Platform fee preset registry
6. `BadgeConfig` - Badge threshold configuration

**Events emitted:**
- `AdminCreated` (CrowdWalrus)
- `AdminCreated` (SuiNS Manager)
- `SuiNSManagerCreated`
- `PolicyRegistryCreated`
- `ProfilesRegistryCreated`
- `TokenRegistryCreated`
- `BadgeConfigCreated`

### Step 2: Record All Object IDs

Create a deployment record file. Extract these IDs from the transaction output:

```bash
# Save these environment variables for subsequent steps:

export PACKAGE_ID="<from transaction output>"
export CROWD_WALRUS_ID="<shared object from transaction>"
export SUINS_MANAGER_ID="<shared object from transaction>"
export POLICY_REGISTRY_ID="<from PolicyRegistryCreated event>"
export PROFILES_REGISTRY_ID="<from ProfilesRegistryCreated event>"
export BADGE_CONFIG_ID="<from BadgeConfigCreated event>"

export ADMIN_CAP_ID="<owned by deployer>"
export SUINS_ADMIN_CAP_ID="<owned by deployer>"
export PUBLISHER_ID="<owned by deployer>"
export UPGRADE_CAP_ID="<owned by deployer>"

# Clock is a standard Sui shared object
export CLOCK="0x6"

# Pyth State Objects (Testnet – verify current IDs at deployment time)
export PYTH_STATE="0xd3e79c2c083b934e78b3bd58a490ec6b092561954da6e7322e1e2b3c8abfddc0"
export WORMHOLE_STATE="0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790"
```

Persist the captured values in two places so tooling can consume them:

- `deployments/deploy-<date>-phase2.env` — environment exports loaded by manual scripts.
- `deployment.addresses.testnet.json` — structured map for front-end/indexer integrations.

**To get TOKEN_REGISTRY_ID:**

The TokenRegistry is stored as a dynamic field under CrowdWalrus. Use this two-step process:

```bash
# Step 1: Query dynamic fields on CrowdWalrus
sui client dynamic-fields --object-id $CROWD_WALRUS_ID

# Step 2: Extract TokenRegistry ID from the dynamic field (requires jq)
FIELD=$(sui client dynamic-fields --object-id $CROWD_WALRUS_ID --json | jq -r '.data[] | select(.name.type | endswith("crowd_walrus::TokenRegistryKey")) | .objectId')
export TOKEN_REGISTRY_ID=$(sui client object $FIELD --json | jq -r '.content.fields.value.fields.id')
```

**Alternative:** Extract from `TokenRegistryCreated` event in the publish transaction:

```bash
# First, save the transaction digest from the publish command
export TX_DIGEST="<transaction_digest_from_publish>"

# Then extract TokenRegistry ID from events
export TOKEN_REGISTRY_ID=$(sui client transaction --digest $TX_DIGEST --json | jq -r '.events[]? | select(.type | endswith("crowd_walrus::TokenRegistryCreated")) | .parsedJson.token_registry_id')
```

### Optional: Verify Package Modules

Quick sanity check to confirm all modules were published:

```bash
# List all modules in the published package
sui client object $PACKAGE_ID --json | jq -r '.content.disassembled | keys[]' | sort

# Expected output (10 modules):
# badge_rewards
# campaign
# campaign_stats
# crowd_walrus
# donations
# platform_policy
# price_oracle
# profiles
# suins_manager
# token_registry
```

### Optional: Persist IDs to JSON File

For easier frontend/indexer integration, save all deployment addresses to a JSON file:

```bash
# Create deployment addresses file for testnet
jq -n \
  --arg pkg "$PACKAGE_ID" \
  --arg cw "$CROWD_WALRUS_ID" \
  --arg pol "$POLICY_REGISTRY_ID" \
  --arg prof "$PROFILES_REGISTRY_ID" \
  --arg tok "$TOKEN_REGISTRY_ID" \
  --arg badge "$BADGE_CONFIG_ID" \
  --arg sm "$SUINS_MANAGER_ID" \
  --arg admin "$ADMIN_CAP_ID" \
  --arg upgrade "$UPGRADE_CAP_ID" \
  '{
    network: "testnet",
    package: $pkg,
    crowdWalrus: $cw,
    policyRegistry: $pol,
    profilesRegistry: $prof,
    tokenRegistry: $tok,
    badgeConfig: $badge,
    suinsManager: $sm,
    adminCap: $admin,
    upgradeCap: $upgrade
  }' > deployment.addresses.testnet.json

cat deployment.addresses.testnet.json
```

### Optional: Update Move.toml for Local Builds

After deployment, update your `Move.toml` to reference the published package for future local builds:

```bash
# Update the crowd_walrus address in Move.toml
sed -i.bak "s/crowd_walrus = \"0x0\"/crowd_walrus = \"$PACKAGE_ID\"/" Move.toml

# Verify the change
grep "crowd_walrus =" Move.toml
```

---

## Post-Deployment Configuration

### Step 3: Secure Admin Capabilities (CRITICAL)

```bash
# If using a different operations wallet, transfer AdminCap
# Otherwise, skip this step and keep it on deployer address

# Transfer main AdminCap
sui client transfer \
  --to <OPS_WALLET_ADDRESS> \
  --object-id $ADMIN_CAP_ID \
  --gas-budget 10000000

# Transfer SuiNS AdminCap
sui client transfer \
  --to <OPS_WALLET_ADDRESS> \
  --object-id $SUINS_ADMIN_CAP_ID \
  --gas-budget 10000000
```

⚠️ **IMPORTANT**: Store backup recovery procedures for these caps (multisig or hardware wallet recommended)

---

### Step 4: Wire SuiNS Subdomain Support (CRITICAL)

⚠️ **This step is MANDATORY** - without it, all campaign creations will abort!

**Prerequisites:**
- You need a `SuinsRegistration` NFT that controls your production namespace (e.g., `*.crowdwalrus.sui`)
- This NFT must be owned by the address calling `set_suins_nft`
- The NFT will be transferred into the SuiNSManager (consumed by value)

```bash
# Get your SuiNS registration NFT ID
# (This is the NFT you own for your domain)
export SUINS_NFT_ID="<your_suins_registration_nft>"

# Call set_suins_nft to register your SuiNS NFT
sui client call \
  --package $PACKAGE_ID \
  --module suins_manager \
  --function set_suins_nft \
  --args $SUINS_MANAGER_ID $SUINS_ADMIN_CAP_ID $SUINS_NFT_ID \
  --gas-budget 15000000
```

**What this does:**
- Transfers your SuinsRegistration NFT into the SuiNSManager
- Enables `create_campaign` to register subdomains like `mycampaign.crowdwalrus.sui`
- Without this, all campaign creation calls will abort with an error

---

### Step 5: Configure Badge Display (RECOMMENDED)

This registers wallet display metadata for donor badges. While badges will mint without this, they won't render properly in wallets.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module badge_rewards \
  --function setup_badge_display \
  --args $PUBLISHER_ID \
  --gas-budget 15000000
```

**What this does:**
- Creates a shared `Display<DonorBadge>` object
- Wallets can now render badge name, image, description, and links
- Only needs to be done once per package version
- Re-run after upgrades with the new Publisher

---

### Step 6: Update Platform Policy Presets

A default `"standard"` preset is seeded at deployment with:
- Platform fee: **0 bps** (0%)
- Platform address: **deployer address**

#### 6.1 Update the Standard Preset

```bash
# Example: Update to 5% platform fee with production address
export PLATFORM_ADDRESS="<your_production_platform_address>"

sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function update_platform_policy \
  --args \
    $POLICY_REGISTRY_ID \
    $ADMIN_CAP_ID \
    '"standard"' \
    500 \
    $PLATFORM_ADDRESS \
    $CLOCK \
  --gas-budget 15000000
```

**Parameters:**
- `registry`: PolicyRegistry shared object
- `admin_cap`: AdminCap for authorization
- `name`: `"standard"` (the default preset name)
- `platform_bps`: Basis points (0-10,000), e.g., 500 = 5%, 1000 = 10%
- `platform_address`: Where platform fees are sent
- `clock`: Standard Sui Clock object at `0x6`

#### 6.2 Add Additional Presets (Optional)

```bash
# Example: Create a "commercial" preset with 10% fee
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function add_platform_policy \
  --args \
    $POLICY_REGISTRY_ID \
    $ADMIN_CAP_ID \
    '"commercial"' \
    1000 \
    $PLATFORM_ADDRESS \
    $CLOCK \
  --gas-budget 15000000
```

#### 6.3 Disable a Preset (Optional)

```bash
# Prevent new campaigns from using this preset (existing campaigns unaffected)
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function disable_platform_policy \
  --args \
    $POLICY_REGISTRY_ID \
    $ADMIN_CAP_ID \
    '"preset_name"' \
    $CLOCK \
  --gas-budget 10000000
```

#### 6.4 Enable a Preset (Optional)

```bash
# Re-enable a preset for future campaigns (existing campaigns unaffected)
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function enable_platform_policy \
  --args \
    $POLICY_REGISTRY_ID \
    $ADMIN_CAP_ID \
    '"commercial"' \
    $CLOCK \
  --gas-budget 10000000
```

---

### Step 7: Populate Token Registry

For **each** supported token type, you must:
1. Add token metadata with Pyth feed ID
2. Enable the token
3. (Optional) Set custom max age for staleness

#### 7.1 Get Pyth Feed IDs

⚠️ **CRITICAL**: Always verify current feed IDs from Pyth before deployment. Feed IDs can change!

Get current Pyth price feed IDs from: https://www.pyth.network/developers/price-feed-ids#sui-testnet

**Example Feed IDs (verify these at deployment time):**
- **SUI/USD**: `0x23d7315d5865acaa1550110f319ce1a79e25f526d5ec7f0e5ef4798da6cfd43b`
- **USDC/USD**: `0x41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722`
- **USDT/USD**: `0x1fc18861232290221461220bd4e2acd1dcdfbc89c84092c93c18bdc7756c1588`

#### 7.2 Add SUI Token

```bash
# Verify this feed ID from Pyth documentation before using!
export  ="0x23d7315d5865acaa1550110f319ce1a79e25f526d5ec7f0e5ef4798da6cfd43b"

# Add SUI token
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function add_token \
  --type-args 0x2::sui::SUI \
  --args \
    $TOKEN_REGISTRY_ID \
    $ADMIN_CAP_ID \
    '"SUI"' \
    '"Sui"' \
    9 \
    $SUI_FEED_ID \
    60000 \
    $CLOCK \
  --gas-budget 20000000
```

**Parameters explained:**
- `--type-args`: The coin type (e.g., `0x2::sui::SUI`)
- `registry`: TokenRegistry shared object
- `admin_cap`: AdminCap for authorization
- `symbol`: Human-readable symbol (e.g., `"SUI"`)
- `name`: Full token name (e.g., `"Sui"`)
- `decimals`: Token decimals (SUI = 9, USDC = 6, etc.) - **must be ≤ 38** (enforced)
- `pyth_feed_id`: 32-byte Pyth feed ID as `0x...` hex string - **must be exactly 32 bytes** (enforced)
- `max_age_ms`: Default staleness limit in milliseconds (60000 = 60 seconds)
- `clock`: Standard Sui Clock object

#### 7.3 Enable the Token

```bash
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function set_token_enabled \
  --type-args 0x2::sui::SUI \
  --args \
    $TOKEN_REGISTRY_ID \
    $ADMIN_CAP_ID \
    true \
    $CLOCK \
  --gas-budget 10000000
```

#### 7.4 Add USDC (Example)

```bash
# Get the actual USDC package ID on testnet
# NOTE: USDC module/type name varies by issuer - verify the exact type on testnet before use
# This is an example - replace with actual testnet USDC type
export USDC_TYPE="0x<testnet_usdc_package>::usdc::USDC"
export USDC_FEED_ID="0x41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722"

# Add USDC token
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function add_token \
  --type-args $USDC_TYPE \
  --args \
    $TOKEN_REGISTRY_ID \
    $ADMIN_CAP_ID \
    '"USDC"' \
    '"USD Coin"' \
    6 \
    $USDC_FEED_ID \
    60000 \
    $CLOCK \
  --gas-budget 20000000

# Enable USDC
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function set_token_enabled \
  --type-args $USDC_TYPE \
  --args \
    $TOKEN_REGISTRY_ID \
    $ADMIN_CAP_ID \
    true \
    $CLOCK \
  --gas-budget 10000000
```

#### 7.5 Update Token Max Age (Optional)

```bash
# Set tighter staleness requirement for a specific token
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function set_token_max_age \
  --type-args 0x2::sui::SUI \
  --args \
    $TOKEN_REGISTRY_ID \
    $ADMIN_CAP_ID \
    30000 \
    $CLOCK \
  --gas-budget 10000000
```

---

### Step 8: Configure Badge Thresholds and Images

⚠️ **REQUIRED**: Badges won't mint until this is configured!

Set the 5 badge levels with:
- USD thresholds (micro-USD amounts)
- Donation count thresholds (number of separate donations)
- Walrus image URIs (hosted artwork)

```bash
# Example badge configuration
# Both thresholds must be met to unlock each level

sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function update_badge_config \
  --args \
    $BADGE_CONFIG_ID \
    $ADMIN_CAP_ID \
    '[1000000,5000000,10000000,50000000,100000000]' \
    '[1,5,10,25,50]' \
    '["https://aggregator.walrus-testnet.walrus.space/v1/<blob-id-1>","https://aggregator.walrus-testnet.walrus.space/v1/<blob-id-2>","https://aggregator.walrus-testnet.walrus.space/v1/<blob-id-3>","https://aggregator.walrus-testnet.walrus.space/v1/<blob-id-4>","https://aggregator.walrus-testnet.walrus.space/v1/<blob-id-5>"]' \
    $CLOCK \
  --gas-budget 25000000
```

**Parameters explained:**
- `amount_thresholds_micro`: USD amounts in micro-USD (1,000,000 = $1)
  - Level 1: $1
  - Level 2: $5
  - Level 3: $10
  - Level 4: $50
  - Level 5: $100
- `payment_thresholds`: Number of distinct donations required
  - Level 1: 1 donation
  - Level 2: 5 donations
  - Level 3: 10 donations
  - Level 4: 25 donations
  - Level 5: 50 donations
- `image_uris`: Walrus blob URIs for each level's artwork

⚠️ **REQUIREMENTS**:
- **Exactly 5 levels** (no more, no less)
- **Strictly ascending** thresholds (each level must be higher than the previous)
- **Non-empty URIs** for all 5 levels
- **Both thresholds** (amount AND count) must be satisfied to mint a badge

**Badge Minting Logic:**
A donor earns Level N badge when:
- Their total USD donations ≥ `amount_thresholds_micro[N-1]` **AND**
- Their donation count ≥ `payment_thresholds[N-1]`

---

### Step 9: Validate Configuration

Before going live, verify all configuration is correct:

```bash
# Query TokenRegistry to verify tokens
sui client object $TOKEN_REGISTRY_ID

# Query BadgeConfig to verify thresholds
sui client object $BADGE_CONFIG_ID

# Query PolicyRegistry to verify presets
sui client object $POLICY_REGISTRY_ID
```

---

## Post-Deployment Testing

### Step 10: Smoke Test Campaign Creation

Create a test campaign to verify everything works:

```bash
# Get the SuiNS shared object ID
# NOTE: This is the SHARED OBJECT of type suins::suins::SuiNS, NOT the package ID
# You must obtain this from SuiNS documentation or your deployment records
export SUINS="<suins_shared_object_id>"  # Get from SuiNS testnet deployment

# Calculate timestamps (in milliseconds)
export START_TIME=$(($(date +%s) * 1000 + 60000))  # Start in 1 minute
export END_TIME=$((START_TIME + 2592000000))       # End in 30 days

export TEST_RECIPIENT="<test_wallet_address>"

# Optional: sanity check the SUINS object type before creating a campaign
# Expected to end with: ::suins::suins::SuiNS
sui client object $SUINS --json | jq -r '.content.type'

# Create a test campaign using default "standard" policy
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function create_campaign \
  --args \
    $CROWD_WALRUS_ID \
    $POLICY_REGISTRY_ID \
    $PROFILES_REGISTRY_ID \
    $SUINS_MANAGER_ID \
    $SUINS \
    $CLOCK \
    '"Test Campaign"' \
    '"Testing phase 2 deployment"' \
    '"test-deploy-001"' \
    '[]' \
    '[]' \
    10000000000 \
    $TEST_RECIPIENT \
    none \
    $START_TIME \
    $END_TIME \
  --gas-budget 30000000
```

**Expected outcomes:**
- ✅ Transaction succeeds
- ✅ Campaign object created and shared
- ✅ CampaignStats object created and shared
- ✅ Profile auto-created if creator doesn't have one
- ✅ SuiNS subdomain registers: `test-deploy-001.crowdwalrus.sui`
- ✅ Events emitted: `CampaignCreated`, `CampaignStatsCreated`, possibly `ProfileCreated`

**To use a specific policy preset:**
Replace `none` with `some("commercial")` or `0x1::option::some("commercial")` (depending on your CLI version).

### Step 11: Test Donation Flow (Advanced)

Making a test donation requires a Programmable Transaction Block (PTB) that:
1. Fetches and updates Pyth price feed
2. Calls the donation function

This is complex and best handled by frontend integration. For manual testing, you'll need to construct a PTB with multiple commands.

**Key validation points:**
- ✅ `DonationReceived` event emits with correct USD values
- ✅ `CampaignParametersLocked` event on first donation
- ✅ Badge mints if thresholds crossed (`BadgeMinted` event)
- ✅ Split amounts match platform policy (check event fields)

---

## Configuration Checklist

| Component | Action | Required | Status |
|-----------|--------|----------|--------|
| Package | Published to testnet | ✅ CRITICAL | ✅ Completed – Nov 7 2025 |
| Object IDs | All IDs recorded | ✅ CRITICAL | ✅ Logged in `deployments/deploy-2025-11-07-phase2.md` |
| AdminCap | Secured to ops wallet | ⚠️ Recommended | ⬜ |
| SuiNS NFT | Registered via `set_suins_nft` | ✅ CRITICAL | ✅ Completed – Nov 8 2025 (tx `H24Z9rPKeGJfMaBQAsUQnnmiSQKoTMWKmKEZAZRahSL4`) |
| Badge Display | Registered via `setup_badge_display` | ⚠️ Recommended | ⬜ |
| Platform Policies | Updated "standard", added presets | ✅ CRITICAL | ⬜ |
| Token Registry | Added & enabled tokens (min 1) | ✅ CRITICAL | ⬜ |
| Badge Config | Set thresholds & image URIs | ✅ CRITICAL | ⬜ |
| Smoke Tests | Created test campaign | ⚠️ Recommended | ⬜ |

---

## Upgrade Path (Alternative)

If you're **upgrading** an existing deployment instead of fresh publishing:

### 1. Perform Upgrade

```bash
# Use your existing UpgradeCap (run from project root)
sui client upgrade \
  --package . \
  --upgrade-capability $EXISTING_UPGRADE_CAP_ID \
  --gas-budget 500000000

# If you have unpublished dependencies, add:
# --with-unpublished-dependencies

# Note: After a successful upgrade, the CLI prints a new package ID.
# Set it for subsequent admin calls (e.g., migrations):
# export NEW_PACKAGE_ID="<printed_by_upgrade_command>"
```

This preserves existing shared object IDs (CrowdWalrus, SuiNSManager, etc.).

### 2. Run Migration

Phase 2 added TokenRegistry as a new shared object. Run the migration to create it:

```bash
# This creates and wires TokenRegistry if it doesn't exist
sui client call \
  --package $NEW_PACKAGE_ID \
  --module crowd_walrus \
  --function migrate_token_registry \
  --args $CROWD_WALRUS_ID $ADMIN_CAP_ID \
  --gas-budget 15000000
```

### 3. Continue with Configuration

After migration, proceed with Steps 5-11 (badge display, policies, tokens, etc.) exactly as in the fresh publish path.

---

## Important Notes

### Critical Requirements
1. **SuiNS NFT** must be set via `set_suins_nft` before ANY campaign can be created (will abort otherwise)
2. **Badge Config** must be populated before badges can mint (will no-op otherwise)
3. **At least one token** must be added and enabled for donations to work
4. **Most admin functions** require the Clock object (`0x6`) as an argument (exceptions: `set_suins_nft`, `migrate_token_registry`)
5. **Recipient address** in campaign creation must be non-zero (enforced by contract)

### Pyth Oracle Integration
- Price updates must happen **in the same PTB** as donations
- Staleness is enforced per token (default 60s, configurable via `set_token_max_age`)
- Feed IDs must **exactly match** what's in TokenRegistry (checked on-chain)
- Always verify feed IDs from Pyth docs at deployment time (they can change)

### Platform Policies
- `"standard"` preset is seeded at deploy with 0% fee and deployer address
- Campaign creators can only choose from **enabled** presets (disabled ones abort)
- Policies are **snapshotted** at campaign creation - updating a preset doesn't affect existing campaigns

### Clock Object
- All functions that emit events require `&Clock`
- Clock is a Sui system object at address `0x6`
- Always pass `0x6` as the clock argument

### Gas Estimates
Based on actual testnet transactions:
- Package publish: ~93M MIST (0.093 SUI), recommend 200-500M budget
- Admin calls: 10-30M MIST per call
- Campaign creation: ~20-30M MIST
- Token operations: ~10-20M MIST

---

## Troubleshooting

### Campaign creation fails
- ✅ Check SuiNS NFT is registered (`set_suins_nft` called)
- ✅ Verify `start_date` is not in the past (must be ≥ current timestamp)
- ✅ Confirm policy name exists and is enabled (or use `none` for default)
- ✅ Verify all required arguments including Clock (`0x6`)
- ✅ Ensure recipient address is non-zero (contract enforced)
- ✅ Confirm you're using the correct SuiNS shared object (not package ID)

### Donations fail
- ✅ Verify token is enabled in TokenRegistry
- ✅ Check Pyth price update is in same PTB before donation call
- ✅ Confirm campaign is active (within start/end time window)
- ✅ Check `expected_min_usd_micro` slippage isn't too strict
- ✅ Verify Pyth feed ID matches TokenRegistry exactly

### Badges don't mint
- ✅ Verify BadgeConfig is populated (call `update_badge_config`)
- ✅ Check **BOTH** thresholds are met (amount AND count)
- ✅ Confirm Display was set up (optional, but needed for wallet rendering)

### CLI errors
- ✅ Use `none` not `'[]'` for Option<String> arguments
- ✅ Don't add `--type-args` to non-generic functions
- ✅ Always include Clock (`0x6`) argument where required
- ✅ Verify gas budget is sufficient (10-30M MIST for admin calls)

---

## Reference Documentation

- **Post-deployment config**: `docs/phase2/POST_DEPLOYMENT_CONFIG.md`
- **Developer guide**: `docs/phase2/PHASE_2_DEV_DOCUMENT.md`
- **Event schemas**: `docs/phase2/EVENT_SCHEMAS.md`
- **Badge display setup**: `docs/phase2/PUBLISHER_DISPLAY_SETUP.md`
- **Dependencies**: `docs/phase2/DEPENDENCIES.md`
- **Task list**: `docs/phase2/PHASE_2_TASKS.md`

## External Resources

- **Pyth Price Feed IDs**: https://www.pyth.network/developers/price-feed-ids#sui-testnet
- **Pyth Sui Documentation**: https://docs.pyth.network/price-feeds/use-real-time-data/sui
- **Sui CLI Documentation**: https://docs.sui.io/references/cli

---

## Quick Reference

### Standard Object IDs (Testnet Constants)

```bash
# These are standard Sui objects (never change)
CLOCK="0x6"

# These are Pyth deployment objects (check Pyth docs for updates)
PYTH_STATE="0xd3e79c2c083b934e78b3bd58a490ec6b092561954da6e7322e1e2b3c8abfddc0"
WORMHOLE_STATE="0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790"

# SuiNS shared object (NOT the package address)
# Get this from SuiNS testnet deployment documentation
SUINS="<suins_shared_object_id>"  # Type: suins::suins::SuiNS
```

### Command Template

```bash
# Generic admin call template
sui client call \
  --package $PACKAGE_ID \
  --module <module_name> \
  --function <function_name> \
  --type-args <CoinType> \     # Only for generic functions like add_token<T>
  --args <arg1> <arg2> ... \   # Append $CLOCK only when required by function signature
  --gas-budget <10000000-30000000>

# Note: Most admin functions require &Clock as the last argument (exceptions: set_suins_nft, migrate_token_registry)
```

---

**Last Updated**: Based on codebase state as of Phase 2 completion (November 2025)

**Maintainer**: Update this guide if function signatures change or new configuration steps are added.
