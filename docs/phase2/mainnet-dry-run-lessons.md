# Mainnet Dry-Run & Dependency Lessons (Sui Move)

This document captures the key lessons, decisions, and configuration changes from our mainnet dry‑run work. It’s intended for future devs and AI agents so we don’t repeat the same dependency pitfalls.

## What we learned

### 1) `--verify-deps` is stricter than “official docs”
- **Problem:** `sui client publish --dry-run --verify-deps` failed even when using *officially recommended* dependency revisions for Pyth/Wormhole.
- **Reason:** `--verify-deps` compares **local source bytecode** to the **on‑chain bytecode**. If they’re not byte‑for‑byte identical, verification fails.
- **Impact:** Pyth, Wormhole, and SuiNS on-chain packages currently **do not match** the git sources we can pull (even from official docs).
- **Outcome:** For now, we accept **non‑verified publishes** (no forks), and document the risk.

### 2) SuiNS address conflicts are caused by mixed address sources
- **Problem:** Build failures like:
  `Conflicting assignments for address 'suins' ...` or `suins_denylist ...`
- **Reason:** The consuming package set addresses in `[addresses]` that **conflicted** with addresses declared inside the SuiNS dependency itself.
- **Fix:** **Remove SuiNS address overrides** from `[addresses]`. Let the dependency define them.

### 3) Framework version conflicts require a global override
- **Problem:** MoveStdlib conflicts between Pyth (pinned to a specific framework rev) and SuiNS.
- **Fix:** Force a **single Sui framework** for all deps using `override = true`.
- **Why:** Our code + SuiNS depend on newer stdlib APIs (vector methods, vec_map helpers, etc.), so we aligned everything to `framework/mainnet`.

### 4) Use SuiNS `main` for newer source, avoid address overrides
- We switched SuiNS dependencies back to `main` (newer than `releases/main`).
- We **removed SuiNS addresses** in `[addresses]` so the dependency controls them.

### 5) Dry-run publish gas (mainnet)
- **Publish dry‑run gas:** `0.3464908 SUI`
  - computationCost: `2,530,000 MIST`
  - storageCost: `343,960,800 MIST`
  - rebate: `0`

## Current configuration (Move.toml / Move.mainnet.toml)

### Dependencies (mainnet)
```toml
[dependencies]
Pyth = { git = "https://github.com/pyth-network/pyth-crosschain.git", subdir = "target_chains/sui/contracts", rev = "sui-contract-mainnet" }
Wormhole = { git = "https://github.com/wormhole-foundation/wormhole.git", subdir = "sui/wormhole", rev = "sui/mainnet" }
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/mainnet", override = true }

suins = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/suins", rev = "main" }
suins_subdomains = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/subdomains", rev = "main" }
suins_denylist = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/denylist", rev = "main" }
```

### Addresses
We keep only the core addresses and **omit SuiNS overrides**:
```toml
[addresses]
crowd_walrus = "0x0"
sui = "0x2"
```

## Commands used (reference)

### Build & test
```bash
sui move build
sui move test
```

### Dry-run publish (works)
```bash
sui client publish --dry-run --json
```

### Dry-run publish with verification (fails today)
```bash
sui client publish --dry-run --verify-deps --json
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
