# Phase 2 Dependencies

This document tracks external dependency revisions for reproducible builds as required by Phase 2 implementation.

---

## Pyth Network Oracle Dependency

**Added:** October 23, 2025 (Task B0)

**Purpose:** On-chain USD price valuation for donations, badges, and campaign statistics.

### Dependency Configuration

```toml
[dependencies.Pyth]
git = "https://github.com/pyth-network/pyth-crosschain.git"
subdir = "target_chains/sui/contracts"
rev = "sui-contract-testnet"
```

### Details

- **Repository:** https://github.com/pyth-network/pyth-crosschain
- **Subdirectory:** `target_chains/sui/contracts`
- **Revision:** `sui-contract-testnet` (git tag)
- **Network:** Sui Testnet
- **Date Pinned:** October 23, 2025

### Testnet Runtime Addresses

These state IDs are used at runtime in PTBs (Programmable Transaction Blocks), not in Move.toml:

- **Pyth State ID (Beta):** `0x243759059f4c3111179da5878c12f68d612c21a8d54d85edc86164bb18be1c7c`
- **Wormhole State ID:** `0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790`

### Architecture Notes

- **Pyth** provides the oracle contract for price feeds
- **Wormhole** is an internal dependency of Pyth (transitive dependency - not declared in our Move.toml)
- **Hermes** is the off-chain service for fetching price updates (frontend integration)

### Integration Pattern

1. Frontend fetches price updates from Hermes API
2. Frontend builds PTB with `pyth::update_single_price_feed` call using pythStateId and wormholeStateId
3. Smart contract calls `pyth::get_price()` to read validated prices

---

## Verification

This revision was verified to build successfully with:
- Sui Framework: `framework/mainnet`
- Edition: `2024.beta`
- Other dependencies: SuiNS testnet packages (crowdwalrus-testnet-core-v2)

**Build Status:** ✅ Confirmed - `sui move build` succeeded (Oct 23, 2025)

---

## References

- Pyth Sui Documentation: https://docs.pyth.network/price-feeds/use-real-time-data/sui
- Pyth Contract Addresses: https://docs.pyth.network/price-feeds/contract-addresses/sui
- Phase 2 Task List: `PHASE_2_TASKS.md` (Task B0)
