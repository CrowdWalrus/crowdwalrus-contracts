# Crowd Walrus — Frontend Addresses (Sui Testnet)

Centralized on‑chain IDs and constants the frontend needs on Sui testnet (Phase 2, fresh publish on 2025‑11‑11).

## Overview
- Network: testnet
- Package ID: `0x5abd06b4c77fca5cdf684f77a2a06c1303218bf85ac27dde3cb07243655a3e9e`
- Deployer: `0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb`

## Core Shared Objects
- CrowdWalrus (platform): `0xc6632fb8fc6b2ceb5dee81292855a5def8a7c4289c8c7aa9908d0d5373e1376b`
  - Root platform object used by admin entries and campaign creation.
- PolicyRegistry: `0xd8f6ef8263676816f298c1f7f311829dd3ee67e26993832e842cb7660859f906`
  - Stores platform policy presets (e.g., "standard", "commercial").
- ProfilesRegistry: `0x2284d6443cbe5720da6b658237b66176a7c9746d2f8322c8a5cd0310357766b0`
  - Auto‑creates/looks up donor profiles.
- BadgeConfig: `0x6faec79a14bcd741a97d5a42722c49e6abed148955e87cdce0ad9e505b6c5412`
  - Holds badge thresholds (USD + donation count) and level image URIs.
- TokenRegistry: `0x92909eb4d9ff776ef04ff37fb5e100426dabc3e2a3bae2e549bde01ebd410ae4`
  - Stores token metadata (symbol, name, decimals, Pyth feed, enabled, max_age_ms).
- SuiNSManager: `0x73d8313a788722f5be2ea362cbb33ee9afac241d2bb88541aa6a93bf08e245ac`
  - Used by campaign creation to register subdomains.

## Global Objects
- Clock: `0x6`
- Pyth State (testnet - Beta channel): `0x243759059f4c3111179da5878c12f68d612c21a8d54d85edc86164bb18be1c7c`
- Wormhole State (testnet): `0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790`

## Token Configuration (supported by UI)
- SUI
  - Type: `0x2::sui::SUI`
  - Decimals: 9
  - Pyth feed ID (SUI/USD): `0x50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266`
  - Registry max_age_ms: 300000 (5 minutes)
- USDC (native Circle)
  - Type: `0xa1ec7fc00a6f40db9693ad1415d0c193ad3906494428cf252621037bd7117e29::usdc::USDC`
  - Decimals: 6
  - Pyth feed ID (USDC/USD): `0x41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722`
  - Registry max_age_ms: 300000 (5 minutes)

Notes:
- Frontend must include a fresh Pyth price update for the selected token in the same PTB as the donation.
- Donor may optionally pass a stricter per‑tx max_age_ms; effective limit is min(registry, donor override).

## Policies (for campaign creation)
- "standard" — 0 bps, platform address = deployer (enabled).
- "commercial" — 500 bps (5%), platform address `0x4aa24001f656ee00a56c1d7a16c65973fa65b4b94c0b79adead1cc3b70261f45` (enabled).

Pass `none` to use the default preset (standard) or `some("commercial")` to use the 5% preset when creating a campaign.

## Badges
- Display<DonorBadge> object: `0x7bcb7c36670767496e30c8ca8c51bdce92f1e34ebd4661d10e62660b6ef643a6`
  - Wallet metadata template registered; required for rendering badge name/image/description/link.
- Badge thresholds (USD micro): [5_000_000, 10_000_000, 15_000_000, 20_000_000, 25_000_000]
- Donation counts: [2, 4, 6, 8, 10]
- Image URIs: configured on 2025‑11‑11 (see on‑chain BadgeConfig).

## SuiNS
- SuiNSManager is wired with the production registration NFT.
- Frontend must supply the SuiNS shared object of type `suins::suins::SuiNS` when creating campaigns (not tracked here).

## Walrus (UI convenience)
- Aggregator (testnet): `https://aggregator.walrus-testnet.walrus.space/v1`
- Relay: `https://relay.walrus.site`

## Admin (testnet note)
- Admin caps are intentionally kept on the deployer for testnet:
  - AdminCap: `0x02596af627e9b4aa8aefbe4c83700934d51a44a559047c1e4f161e446a1f0775`
  - SuiNS AdminCap: `0x729906c42824a50870f07ad6f30cc4dffba6e085b10e57072551bddcc6303041`

---
If any of these change (new publish/upgrade), update this file and the frontend .env accordingly.
