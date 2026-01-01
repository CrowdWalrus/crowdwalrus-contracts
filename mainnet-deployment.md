# CrowdWalrus Mainnet Deployment — Ordered Task List

> Scope: **contracts (crowd-walrus-contracts)**, **indexer (crowdwalrus-indexer)**, **dapp (crowdwalrus-dapp)**.  
> Goal: move from **testnet** to **mainnet** with a fresh publish, full post‑deploy config, indexer + dapp aligned.  
> Branches (current): **contracts = `phase2`**, **dapp = `staging`**, **indexer = `main`**.  
> Do **not** deploy while preparing; only run publish/config steps when you reach them.

---

## 1) Freeze and align branches (all repos)
1. **Contracts (`crowd-walrus-contracts`, branch `phase2`)**
   - Pull latest and ensure working tree is clean.
   - Confirm Phase 2 code is the exact release candidate.
2. **Dapp (`crowdwalrus-dapp`, branch `staging`)**
   - Pull latest and ensure working tree is clean.
   - Confirm staging contains the Phase 2 integration updates.
3. **Indexer (`crowdwalrus-indexer`, branch `main`)**
   - Pull latest and ensure working tree is clean.
   - Confirm `config/indexer.example.toml` and ops docs are current.
4. Decide whether you will **deploy directly from these branches** or create a dedicated **`mainnet-release`** branch per repo. If creating a release branch, do it now and use it consistently for all steps below.

---

## 2) Collect mainnet inputs (before any edits)
Gather/confirm these values **from official sources** (Pyth, SuiNS, Walrus) and internal product decisions:
1. **Sui CLI mainnet release** to pin with `suiup`.
2. **Pyth mainnet dependency revision** (for `Move.toml`).
3. **SuiNS mainnet package revisions** for `suins`, `subdomains`, `denylist` (and their **mainnet published addresses**).
4. **SuiNS shared object ID** (`suins::suins::SuiNS`) for **mainnet** (not the package ID).
5. **SuiNS Registration NFT ID** for the production domain (`crowdwalrus.sui`).
6. **Pyth mainnet state IDs**:
   - `pythStateId` (mainnet)
   - `wormholeStateId` (mainnet)
7. **Token list + Pyth feed IDs** for mainnet (e.g., SUI, USDC, WAL, others you will support at launch).
8. **Platform fee policy values**:
   - `platform_bps`
   - `platform_address`
9. **Badge thresholds + mainnet Walrus image URIs** (5 levels each).
10. **Ops wallet address** that will hold the AdminCaps on mainnet.
11. **Indexer base URL** for production (confirm where `https://indexer.crowdwalrus.xyz` should point).
12. **Walrus mainnet settings** (system + subsidy object IDs in dapp config).

---

## 3) Contracts: update dependencies for mainnet (branch `phase2`)
**Files:** `Move.toml`, `Move.lock`
1. Update **Pyth** dependency to a **mainnet** revision (currently `sui-contract-testnet`).
2. Update **SuiNS** dependencies to a **mainnet** release (not the testnet fork).
3. Update `[addresses]` in `Move.toml`:
   - `suins`
   - `subdomains`
   - `denylist`
4. If the official SuiNS mainnet release has **address conflicts**, apply the workaround from `docs/SUINS_DEPENDENCY_ISSUE.md` (fork or `--with-unpublished-dependencies`).
5. Keep `crowd_walrus = "0x0"` until after publish (fresh mainnet publish).
6. Run `sui move build` to regenerate `Move.lock` with mainnet dependencies.

---

## 4) Contracts: build & test on mainnet toolchain (branch `phase2`)
1. Pin Sui CLI to the **current mainnet release** (`suiup install sui@mainnet …`).
2. Confirm CLI version and that `suiup` path is used first.
3. Switch to mainnet:
   - `sui client switch --env mainnet`
   - `sui client active-env` → should be `mainnet`
4. Confirm deployer address and gas balance:
   - `sui client active-address`
   - `sui client gas` (ensure enough SUI for publish + admin calls)
5. Build & test:
   - `sui move build`
   - `sui move test`

---

## 5) Contracts: publish package to mainnet (branch `phase2`)
1. Publish (fresh):
   - `sui client publish --gas-budget 500000000`  
   - If SuiNS dep conflict exists, add `--with-unpublished-dependencies`.
2. Capture **all created IDs** from the publish output:
   - **Package ID**
   - **Shared objects**: CrowdWalrus, PolicyRegistry, ProfilesRegistry, TokenRegistry, BadgeConfig, SuiNSManager
   - **Owned caps**: AdminCap, SuiNS AdminCap, Publisher, UpgradeCap
3. Resolve **TokenRegistry** ID if needed (dynamic field under `CrowdWalrus`).
4. Record the **publish transaction digest**.

---

## 6) Contracts: record deployment artifacts (branch `phase2`)
1. Save publish output files:
   - `deployments/publish-YYYY-MM-DD-mainnet-phase2.json`
   - `deployments/publish-YYYY-MM-DD-mainnet-phase2.raw.txt`
2. Create deployment record:
   - `deployment.addresses.mainnet.YYYY-MM-DD.json`
   - `deployment.addresses.mainnet.json` (latest, canonical)
3. Include in the JSON (mirror `deployment.addresses.testnet.json` schema):
   - `network`, `label`, `deployedAt`, `txDigest`, `packageId`, `accounts.deployer`
   - `sharedObjects.*`, `ownedCaps.*`
   - `globals.clock = 0x6`
   - `globals.pythState` (mainnet)
   - `globals.wormholeState` (mainnet)
   - `globals.suinsPackage` (mainnet)
4. Update `Move.toml` **after publish**:
   - set `crowd_walrus = "<NEW_PACKAGE_ID>"`
5. Commit deployment records + `Move.toml` changes.

---

## 7) Contracts: post‑deploy configuration (branch `phase2`)
Follow `docs/phase2/POST_DEPLOYMENT_CONFIG.md` + `docs/phase2/PUBLISHER_DISPLAY_SETUP.md`.
1. **Secure AdminCaps**
   - Transfer `AdminCap` and `SuiNS AdminCap` to the ops wallet (if different from deployer).
2. **SuiNS registration (CRITICAL)**
   - Use mainnet `SuinsRegistration` NFT for `crowdwalrus.sui`.
   - Call `set_suins_nft` on the **new** `SuiNSManager`.
3. **Badge display (RECOMMENDED)**
   - Call `badge_rewards::setup_badge_display` with the **Publisher** from publish output.
   - Record the Display object ID and tx digest in `deployment.addresses.mainnet.json`.
4. **Platform policy presets**
   - Update seeded `"standard"` preset to production platform address + bps.
   - Add any additional presets (e.g., `"commercial"`) and enable as needed.
   - Record tx digests and values in `deployment.addresses.mainnet.json`.
5. **Token registry (CRITICAL)**
   - For each supported coin type `T`:
     - `add_token<T>` with symbol/name/decimals + **mainnet Pyth feed ID**
     - `set_token_enabled<T>(true)`
     - Optional: `set_token_max_age<T>` for stricter freshness
   - Include **WAL** if donors will use Walrus token on mainnet.
   - Record feed IDs + tx digests in `deployment.addresses.mainnet.json`.
6. **Badge configuration (CRITICAL)**
   - Call `update_badge_config` with 5 ascending thresholds and **mainnet** Walrus image URIs.
   - Record thresholds + tx digest in `deployment.addresses.mainnet.json`.
7. **Validation checks**
   - Read `TokenRegistry`, `BadgeConfig`, `PolicyRegistry` to confirm values.
8. **Smoke tests (mainnet)**
   - Create a private campaign (verify SuiNS domain registration works).
   - Perform a minimal donation (validate events, splits, badge mint if thresholds crossed).

---

## 8) Dapp: update mainnet config (branch `staging`)
**Files:** `src/shared/config/contracts.ts`, `src/shared/config/networkConfig.ts`
1. Fill **mainnet** placeholders in `contracts.ts`:
   - `packageId`, `crowdWalrusObjectId`, `suinsManagerObjectId`, `suinsObjectId`
   - `policyRegistryObjectId`, `profilesRegistryObjectId`, `tokenRegistryObjectId`, `badgeConfigObjectId`
2. Update **mainnet Pyth config** in `contracts.ts`:
   - `pythStateId`, `wormholeStateId` (mainnet)
   - ensure `hermesUrl` stays `https://hermes.pyth.network`
3. Verify **Walrus mainnet config** in `contracts.ts`:
   - `systemObjectId`, `subsidyObjectId`, `aggregatorUrl`
4. Ensure `campaignDomain` = `crowdwalrus.sui` matches your mainnet SuiNS registration.
5. Switch default network for production build:
   - `DEFAULT_NETWORK = "mainnet"` in `src/shared/config/networkConfig.ts`.
6. Confirm indexer base URL in `src/shared/config/indexer.ts` points to the **mainnet** indexer domain.
7. Build:
   - `pnpm build`

---

## 9) Dapp: deploy to Walrus Sites mainnet (branch `staging`)
Follow `crowdwalrus-dapp/deployment.md` **mainnet section**.
1. Switch wallet to mainnet:
   - `sui client switch --env mainnet`
2. Install **mainnet** `site-builder` binary.
3. Ensure WAL tokens exist:
   - `walrus get-wal` (mainnet)
4. Deploy:
   - `pnpm build`
   - `./site-builder-mainnet deploy --epochs <N> dist/` (choose a mainnet retention period)
5. Record:
   - Site object ID
   - Base36 subdomain
   - `dist/ws-resources.json`
6. Publish the mainnet URL (`https://<subdomain>.wal.app`) for internal QA.

---

## 10) Indexer: configure mainnet and deploy (branch `main`)
Follow `docs/operational_runbook.md` + `docs/aws_deployment.md`.
1. Update mainnet config:
   - `config/indexer.toml` → `mainnet.package_id = <NEW_MAINNET_PACKAGE_ID>`
   - Ensure `checkpoint_store_url = https://checkpoints.mainnet.sui.io`
2. Update production env (`/etc/crowdwalrus/indexer-mainnet.env`):
   - `DATABASE_URL` (mainnet DB)
   - `PACKAGE_ID_MAINNET` (new package)
   - `CHECKPOINT_STORE_MAINNET`
   - `SUI_NETWORK=mainnet`
3. Ensure **mainnet database exists** and migrations run (deploy.sh handles this if diesel is available).
4. Deploy mainnet service:
   - `scripts/deploy.sh --network mainnet`
5. If using automation (`docs/deployment_automation.md`):
   - Set `DEPLOY_MAINNET=true`
   - Ensure runner + sudoers are in place
6. Monitor initial sync:
   - `/health` will be **degraded** until lag converges (expected).

---

## 11) End‑to‑end validation (after all three are updated)
1. **Indexer**
   - `/health` returns network `mainnet` and tracks checkpoints.
   - `/v1/stats`, `/v1/campaigns` return data.
2. **Dapp**
   - Loads mainnet config, contracts, and indexer endpoints.
   - Campaign creation works (SuiNS subdomain registered).
   - Donations work (token enabled, Pyth update in PTB, slippage checks).
3. **Contracts**
   - `DonationReceived`, `CampaignParametersLocked`, `BadgeMinted` events emitted as expected.

---

## 12) Post‑release housekeeping
1. Update `deployment.addresses.mainnet.json` with **postConfig** results:
   - policy presets, token registry entries, badge config, display setup txs.
2. Tag releases (optional):
   - `contracts`: tag with package ID or date
   - `dapp`: tag with Walrus site deployment date
   - `indexer`: tag with deployed commit
3. Share final IDs + config with all teams (dapp, indexer, ops).
4. Archive artifacts in `deployments/` and keep a dated `deployment.addresses.mainnet.YYYY-MM-DD.json`.

---

## Quick reference: files to change
- Contracts:
  - `Move.toml`
  - `Move.lock`
  - `deployment.addresses.mainnet.json` (new)
  - `deployments/publish-YYYY-MM-DD-mainnet-phase2.*` (new)
- Dapp:
  - `src/shared/config/contracts.ts`
  - `src/shared/config/networkConfig.ts`
  - `src/shared/config/indexer.ts` (only if indexer domain changes)
- Indexer:
  - `config/indexer.toml`
  - `/etc/crowdwalrus/indexer-mainnet.env` (production host)

