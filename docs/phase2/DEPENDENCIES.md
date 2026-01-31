# Phase 2 Dependencies

This document tracks external dependency revisions for reproducible builds as required by Phase 2 implementation.

---

## Pyth + Wormhole Oracle Dependencies

**Added:** October 23, 2025 (Task B0)

**Purpose:** On-chain USD price valuation for donations, badges, and campaign statistics.

### Dependency Configuration (current)

```toml
[dependencies]
pyth = { git = "https://github.com/pyth-network/pyth-crosschain.git", subdir = "target_chains/sui/contracts", rev = "3bd1262dcba9518a6901aa6a15f04072799bfb37" }
wormhole = { git = "https://github.com/wormhole-foundation/wormhole.git", subdir = "sui/wormhole", rev = "b71be5cbb9537c4aac8e23e74371affa3825efcd" }

[dep-replacements.testnet]
pyth = { git = "https://github.com/pyth-network/pyth-crosschain.git", subdir = "target_chains/sui/contracts", rev = "62c7a5bc0fc857ba6417ad780190552d4919ceca" }
wormhole = { git = "https://github.com/wormhole-foundation/wormhole.git", subdir = "sui/wormhole", rev = "1b1cb69e809e0e7081cf1bf9b2779c41c14fc7f0" }
```

### Details

- **Repositories:** https://github.com/pyth-network/pyth-crosschain, https://github.com/wormhole-foundation/wormhole
- **Subdirectories:** `target_chains/sui/contracts`, `sui/wormhole`
- **Revisions:** pinned commit hashes (mainnet + testnet overrides)
- **Date Pinned:** January 2026

### Testnet Runtime Addresses

These state IDs are used at runtime in PTBs (Programmable Transaction Blocks), not in Move.toml:

- **Pyth State ID (Beta):** `0x243759059f4c3111179da5878c12f68d612c21a8d54d85edc86164bb18be1c7c`
- **Wormhole State ID:** `0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790`

### Architecture Notes

- **Pyth** provides the oracle contract for price feeds.
- **Wormhole** is an internal dependency of Pyth, but we pin it explicitly for deterministic builds.
- **Hermes** is the off-chain service for fetching price updates (frontend integration).

### Why commit hashes (not tags)

- **Reproducibility:** tags/branches can move; commit hashes are immutable.
- **Audits/debugging:** lockfiles and published bytecode can be traced back to an exact source tree.

### Why testnet commits differ from mainnet

- **Networks upgrade on different schedules.** Testnet often runs ahead/behind mainnet, and published packages can lag different commits.
- **Match the chain, not the other network.** We pin testnet commits that reflect testnet-published packages.

### Integration Pattern

1. Frontend fetches price updates from Hermes API
2. Frontend builds PTB with `pyth::update_single_price_feed` call using pythStateId and wormholeStateId
3. Smart contract calls `pyth::get_price()` to read validated prices

---

## Verification

This config was verified to build and test with:
- Sui CLI: mainnet 1.64.2 and testnet 1.64.1
- Move edition: `2024`
- SuiNS dependencies: mainnet v3 / testnet v2 via `dep-replacements`

**Build Status:** ✅ Confirmed - `sui move build` + `sui move test` (Jan 2026)

---

## References

- Pyth Sui Documentation: https://docs.pyth.network/price-feeds/use-real-time-data/sui
- Pyth Contract Addresses: https://docs.pyth.network/price-feeds/contract-addresses/sui
- Phase 2 Task List: `PHASE_2_TASKS.md` (Task B0)
