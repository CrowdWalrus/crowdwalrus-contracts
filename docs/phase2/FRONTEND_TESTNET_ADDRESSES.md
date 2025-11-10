# Crowd Walrus — Frontend Addresses (Sui Testnet)

This file centralizes all on‑chain IDs and constants the frontend needs on Sui testnet for Phase 2.

## Overview
- Network: testnet
- Package ID: `0xc762a509c02849b7ca0b63eb4226c1fb87aed519af51258424a3591faaacac10`
- Deployer: `0x4fcb599f85adb345fd608c69040615caa7af84ec8bbf181569a4dbe7368acfbb`

## Core Shared Objects
- CrowdWalrus (platform): `0x10e5b1e7f63c33d8e49eeac79168badfb9b271209bd12a59bbcde1ecd0187596`
  - Root platform object used by admin entries and campaign creation.
- PolicyRegistry: `0xaf5058f1ff30262fdeeeaa325b4b1ce12a73015abbf22867f63e9f449bb9e8c3`
  - Stores platform policy presets (e.g., "standard", "commercial").
- ProfilesRegistry: `0xd72f3907908b0575afea266c457c0109690ab11e8568106364c76e2444c2aeac`
  - Auto‑creates/looks up donor profiles.
- BadgeConfig: `0x71c1e75eb42a29a81680f9f1e454e87468561a5cd28e2217e841c6693d00ea23`
  - Holds badge thresholds (USD + donation count) and level image URIs.
- TokenRegistry: `0xee1330d94cd954ae58fd18a8336738562f05487fae56dda9c655f461eac52b6f`
  - Stores token metadata (symbol, name, decimals, Pyth feed, enabled, max_age_ms).
- SuiNSManager: `0x48ceb4364109da3b9cd889d29dc9e14bafa5983777ccaa3f5d6385958b8190cf`
  - Used by campaign creation to register subdomains.

## Global Objects
- Clock: `0x6`
- Pyth State (testnet): `0xd3e79c2c083b934e78b3bd58a490ec6b092561954da6e7322e1e2b3c8abfddc0`
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
- Frontend should include a fresh Pyth price update for the selected token in the same PTB as the donation.
- Donor may optionally pass a stricter per‑tx max_age_ms; effective limit is min(registry, donor override).

## Policies (for campaign creation)
- "standard" — 0 bps, platform address = deployer (enabled).
- "commercial" — 500 bps (5%), platform address `0x4aa24001f656ee00a56c1d7a16c65973fa65b4b94c0b79adead1cc3b70261f45` (enabled).

Pass `none` to use the default preset (standard) or `some("commercial")` to use the 5% preset when creating a campaign.

## Badges
- Display<DonorBadge> object: `0x3e040f2d1efe17209a8acbdca994a46765654df45b4d59fc52b2f415d6933160`
  - Wallet metadata template registered; required for rendering badge name/image/description/link.
- Badge thresholds (USD micro): [5_000_000, 10_000_000, 15_000_000, 20_000_000, 25_000_000]
- Donation counts: [2, 4, 6, 8, 10]
- Image URIs (Walrus aggregator): level‑ordered list as configured on Nov 8, 2025.

## SuiNS
- SuiNSManager is wired with the production registration NFT.
- Frontend must supply the SuiNS shared object of type `suins::suins::SuiNS` when creating campaigns (not tracked here).

## Walrus (UI convenience)
- Aggregator (testnet): `https://aggregator.walrus-testnet.walrus.space/v1`
- Relay: `https://relay.walrus.site`

## Admin (testnet note)
- Admin caps are intentionally kept on the deployer for testnet:
  - AdminCap: `0x3d220d55745a74563ea5b0af717c2957bd17954be6403e738b8994875766afa3`
  - SuiNS AdminCap: `0xafd251e536c837dc64ef58881965f2222b9e0f9966f9296f1f967367cb5da78b`

---
If any of these change (new publish/upgrade), update this file and the frontend .env accordingly.
