# Phase 2 Dependencies

This document tracks external dependency revisions for reproducible builds as required by Phase 2 implementation.

---

## Pyth + Wormhole Oracle Dependencies

**Added:** October 23, 2025 (Task B0)

**Purpose:** On-chain USD price valuation for donations, badges, and campaign statistics.

### Dependency Configuration (current)

```toml
[dependencies]
pyth = { git = "https://github.com/pyth-network/pyth-crosschain.git", subdir = "target_chains/sui/contracts", rev = "sui-contract-mainnet" }
wormhole = { git = "https://github.com/wormhole-foundation/wormhole.git", subdir = "sui/wormhole", rev = "sui/mainnet" }

[dep-replacements.testnet]
pyth = { git = "https://github.com/pyth-network/pyth-crosschain.git", subdir = "target_chains/sui/contracts", rev = "sui-contract-testnet" }
wormhole = { git = "https://github.com/wormhole-foundation/wormhole.git", subdir = "sui/wormhole", rev = "sui/testnet" }
```

### Details

- **Repositories:** https://github.com/pyth-network/pyth-crosschain, https://github.com/wormhole-foundation/wormhole
- **Subdirectories:** `target_chains/sui/contracts`, `sui/wormhole`
- **Revisions:** upstream stable branches + `Move.lock` pinning
- **Date Pinned:** January 2026 (lockfile captures exact commits)

### Runtime Addresses (PTB)

These state IDs are used at runtime in PTBs (Programmable Transaction Blocks), not in Move.toml:

**Mainnet**
- **Pyth State ID:** `0x1f9310238ee9298fb703c3419030b35b22bb1cc37113e3bb5007c99aec79e5b8`
- **Wormhole State ID:** `0xaeab97f96cf9877fee2883315d459552b2b921edc16d7ceac6eab944dd88919c`

**Testnet**
- **Pyth State ID (Beta):** `0x243759059f4c3111179da5878c12f68d612c21a8d54d85edc86164bb18be1c7c`
- **Wormhole State ID:** `0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790`

### Architecture Notes

- **Pyth** provides the oracle contract for price feeds.
- **Wormhole** is an internal dependency of Pyth, but we pin it explicitly for deterministic builds.
- **Hermes** is the off-chain service for fetching price updates (frontend integration).

### Why stable branches (not hardcoded tags)

- **Upstream guidance:** Pyth documents `sui-contract-mainnet/testnet` as the supported branches.
- **Reproducibility:** `Move.lock` captures the exact commit we built against.

### Why testnet differs from mainnet

- **Networks upgrade on different schedules.** Testnet often runs ahead/behind mainnet, and published packages can lag different commits.
- **Match the chain, not the other network.** Use testnet branches/IDs even when mainnet is on a different release.

### Integration Pattern

1. Frontend fetches price updates from Hermes API
2. Frontend builds PTB with `pyth::update_single_price_feed` call using pythStateId and wormholeStateId
3. Smart contract calls `pyth::get_price()` to read validated prices

---

## SuiNS Dependencies

**Purpose:** Subdomain registration for campaign profiles and SuiNS integration.

### Dependency Configuration (current)

```toml
[dependencies]
suins = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/suins", rev = "main", original-id = "0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0", published-at = "0x71af035413ed499710980ed8adb010bbf2cc5cacf4ab37c7710a4bb87eb58ba5" }
suins_subdomains = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/subdomains", rev = "main", original-id = "0xe177697e191327901637f8d2c5ffbbde8b1aaac27ec1024c4b62d1ebd1cd7430", published-at = "0xe0108df96c8dfac6d285e5b8afbeafc9a205002a3ec7807329929c8b4d53a8a0" }
suins_denylist = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/denylist", rev = "main", original-id = "0xc967b7862d926720761ee15fbd0254a975afa928712abcaa4f7c17bb2b38d38b", published-at = "0xc967b7862d926720761ee15fbd0254a975afa928712abcaa4f7c17bb2b38d38b" }

[dep-replacements.testnet]
suins = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/suins", rev = "crowdwalrus-testnet-core-v2", original-id = "0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93", published-at = "0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1" }
suins_subdomains = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/subdomains", rev = "crowdwalrus-testnet-core-v2", rename-from = "subdomains", original-id = "0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636", published-at = "0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636" }
suins_denylist = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/denylist", rev = "crowdwalrus-testnet-core-v2", rename-from = "denylist", original-id = "0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49", published-at = "0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49" }
```

### Why these branches + names

- **Branch choice:** `main` includes the renamed `suins_*` packages and required `published-at` metadata.
- **Testnet fix:** Upstream testnet branch still leaves `denylist` at `0x0`, so we use a fork with corrected addresses and `rename-from` mapping.
- **`original-id` vs `published-at`:** `original-id` tracks the root package ID from SuiNS docs; `published-at` points to the on-chain package ID used by the dependency branch (not necessarily the newest on the network).
- **Testnet SuiNS published-at:** The fork’s `suins/Move.toml` uses `0x670...` (core v2), so we keep that to stay aligned with the branch sources.
- **No unpublished deps:** This avoids `--with-unpublished-dependencies` while keeping published package IDs explicit.
- **Upgrade safety:** We keep both `original-id` and `published-at` so upgrades stay compatible with on-chain types.

### Published IDs (on-chain)

**Mainnet**
- **SuiNS (current):** `0x71af035413ed499710980ed8adb010bbf2cc5cacf4ab37c7710a4bb87eb58ba5`
- **SuiNS (original):** `0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0`
- **Subnames (current):** `0xe0108df96c8dfac6d285e5b8afbeafc9a205002a3ec7807329929c8b4d53a8a0`
- **Subnames (original):** `0xe177697e191327901637f8d2c5ffbbde8b1aaac27ec1024c4b62d1ebd1cd7430`
- **Denylist:** `0xc967b7862d926720761ee15fbd0254a975afa928712abcaa4f7c17bb2b38d38b`

**Testnet**
- **SuiNS (core v2 published-at):** `0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1`
- **SuiNS (original):** `0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93`
- **Subnames:** `0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636`
- **Denylist:** `0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49`

---

## Verification

This config was verified to build and test with:
- Sui CLI: client 1.64.2 (server 1.64.1)
- Move edition: `2024`
- SuiNS dependencies: `main` branch + forked testnet core v2 packages (`rename-from`)

**Build Status (Jan 2026):**
- ✅ `sui move build --environment mainnet`
- ✅ `sui move test --environment mainnet`
- ✅ `sui move build --environment testnet`
- ❌ `sui move test --environment testnet` (expected failure: tests reference `0x0::` locations, but Published.toml pins testnet address)
- ✅ `sui move build --environment testnet_unpublished`
- ✅ `sui move test --environment testnet_unpublished`
- ✅ `sui client publish --dry-run --gas-budget 500000000` (mainnet)
- ✅ `sui client publish --dry-run --gas-budget 500000000` (testnet_unpublished)

---

## References

- Pyth Sui Documentation: https://docs.pyth.network/price-feeds/use-real-time-data/sui
- Pyth Contract Addresses: https://docs.pyth.network/price-feeds/contract-addresses/sui
- SuiNS Indexing Docs (active constants): https://docs.suins.io/developer/indexing
- Phase 2 Task List: `PHASE_2_TASKS.md` (Task B0)
