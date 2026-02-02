# Mainnet Dry-Run & Dependency Lessons (Sui Move)

This document captures the key lessons, decisions, and configuration changes from our mainnet dry‑run work. It’s intended for future devs and AI agents so we don’t repeat the same dependency pitfalls.

## What we learned

### 1) `--verify-deps` is stricter than “official docs”
- **Problem:** `sui client publish --dry-run --verify-deps` failed even when using *officially recommended* dependency revisions for Pyth/Wormhole.
- **Reason:** `--verify-deps` compares **local source bytecode** to the **on‑chain bytecode**. If they’re not byte‑for‑byte identical, verification fails.
- **Impact:** Pyth, Wormhole, and SuiNS on-chain packages currently **do not match** the git sources we can pull (even from official docs).
- **Outcome:** For now, we accept **non‑verified publishes** (no forks), and document the risk.

### 2) Address conflicts are caused by mixed address sources
- **Problem:** Build failures like:
  `Conflicting assignments for address 'suins' ...` or `suins_denylist ...`
- **Reason:** The consuming package set addresses in `[addresses]` that **conflicted** with addresses declared inside dependencies.
- **Fix:** **Remove `[addresses]` entirely** under the new package manager. Let the package system and dependencies define addresses.

### 3) Framework version conflicts require a single toolchain
- **Problem:** MoveStdlib conflicts between Pyth (pinned to a specific framework rev) and SuiNS.
- **Fix:** Use a single Sui CLI/toolchain per environment (mainnet or testnet). The framework is a **system dependency** now, so avoid explicit overrides.

### 4) Use SuiNS `main` branch + forked testnet packages
- The `main` branch includes the renamed packages (`suins_subdomains`, `suins_denylist`)
  and `published-at` metadata needed for dry‑run publish without `--with-unpublished-dependencies`.
- The upstream testnet branch still leaves `denylist` at `0x0`, so we use a fork with
  corrected addresses and map package names via `rename-from`.
- SuiNS addresses are managed by the dependency + `published-at`, not by `[addresses]`.

### 5) Dry-run publish gas (mainnet)
- **Publish dry‑run gas:** `0.3466777 SUI`
  - computationCost: `2,211,900 MIST`
  - storageCost: `343,960,800 MIST`
  - rebate: `0`

### 6) Dry-run publish gas (testnet_unpublished)
- **Publish dry‑run gas:** `0.3492308 SUI`
  - computationCost: `4,270,000 MIST`
  - storageCost: `343,960,800 MIST`
  - rebate: `0`

## Current configuration (single Move.toml + dep-replacements)

### Dependencies (mainnet base + testnet overrides)
Note: the Sui framework is now a system dependency, so it is not listed explicitly.
```toml
[dependencies]
pyth = { git = "https://github.com/pyth-network/pyth-crosschain.git", subdir = "target_chains/sui/contracts", rev = "sui-contract-mainnet" }
wormhole = { git = "https://github.com/wormhole-foundation/wormhole.git", subdir = "sui/wormhole", rev = "sui/mainnet" }

suins = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/suins", rev = "main", original-id = "0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0", published-at = "0x71af035413ed499710980ed8adb010bbf2cc5cacf4ab37c7710a4bb87eb58ba5" }
suins_subdomains = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/subdomains", rev = "main", original-id = "0xe177697e191327901637f8d2c5ffbbde8b1aaac27ec1024c4b62d1ebd1cd7430", published-at = "0xe0108df96c8dfac6d285e5b8afbeafc9a205002a3ec7807329929c8b4d53a8a0" }
suins_denylist = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/denylist", rev = "main", original-id = "0xc967b7862d926720761ee15fbd0254a975afa928712abcaa4f7c17bb2b38d38b", published-at = "0xc967b7862d926720761ee15fbd0254a975afa928712abcaa4f7c17bb2b38d38b" }

[dep-replacements.testnet]
pyth = { git = "https://github.com/pyth-network/pyth-crosschain.git", subdir = "target_chains/sui/contracts", rev = "sui-contract-testnet" }
wormhole = { git = "https://github.com/wormhole-foundation/wormhole.git", subdir = "sui/wormhole", rev = "sui/testnet" }

suins = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/suins", rev = "crowdwalrus-testnet-core-v2", original-id = "0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93", published-at = "0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1" }
suins_subdomains = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/subdomains", rev = "crowdwalrus-testnet-core-v2", rename-from = "subdomains", original-id = "0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636", published-at = "0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636" }
suins_denylist = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/denylist", rev = "crowdwalrus-testnet-core-v2", rename-from = "denylist", original-id = "0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49", published-at = "0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49" }

[dep-replacements.testnet_unpublished]
pyth = { git = "https://github.com/pyth-network/pyth-crosschain.git", subdir = "target_chains/sui/contracts", rev = "sui-contract-testnet" }
wormhole = { git = "https://github.com/wormhole-foundation/wormhole.git", subdir = "sui/wormhole", rev = "sui/testnet" }

suins = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/suins", rev = "crowdwalrus-testnet-core-v2", original-id = "0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93", published-at = "0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1" }
suins_subdomains = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/subdomains", rev = "crowdwalrus-testnet-core-v2", rename-from = "subdomains", original-id = "0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636", published-at = "0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636" }
suins_denylist = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/denylist", rev = "crowdwalrus-testnet-core-v2", rename-from = "denylist", original-id = "0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49", published-at = "0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49" }

[environments]
testnet_unpublished = "4c78adac"
```

## Commands used (reference)

### Build & test
```bash
sui move build --environment mainnet
sui move test  --environment mainnet
```

### Dry-run publish (works)
```bash
sui client publish --dry-run --gas-budget 500000000
```

### Dry-run publish with verification (fails today)
```bash
sui client publish --dry-run --verify-deps --gas-budget 500000000
```

## Why `--verify-deps` fails (summary)
- On‑chain bytecode for **Pyth**, **Wormhole**, and **SuiNS** doesn’t match the git sources.
- Official docs provide **recommended integration revisions**, but not necessarily the exact commit hashes used for the on‑chain publish.
- Without forks or exact upstream commit hashes, `--verify-deps` remains blocked.

## Net outcome
- We can **build + test successfully** on mainnet deps.
- We can **publish dry‑run** and estimate gas.
- We currently **cannot** pass `--verify-deps` without forking or upstream‑provided exact source hashes.

---

If you want `--verify-deps` to pass in the future, you’ll need the **exact git commit hashes** used to publish the on‑chain packages, or a maintained upstream mirror that matches them.
