# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Platform Overview

CrowdWalrus is a decentralized crowdfunding platform on Sui blockchain with SuiNS subdomain integration. The system consists of three core modules:

- **crowd_walrus**: Main platform module managing verification system and authorization
- **campaign**: Crowdfunding campaign lifecycle and updates management
- **suins_manager**: SuiNS integration for subdomain registration per campaign

## Key Commands

### Build
```bash
sui move build
```

### Test
```bash
sui move test
```

### Deploy
```bash
sui client publish --gas-budget 100000000
```

After deployment, update `Move.toml` with the deployed package ID in the `[addresses]` section.

## Architecture

### Authorization Pattern

The codebase uses a witness-based authorization pattern throughout:

1. **CrowdWalrusApp**: Witness type defined in `crowd_walrus.move` that authorizes operations across modules
2. **AppKey<App>**: Generic authorization key stored as dynamic fields to grant apps access to protected features
3. Capabilities (`AdminCap`, `VerifyCap`, `CampaignOwnerCap`): Token-based permissions system

When calling protected functions, modules check authorization via `assert_app_is_authorized<App>()`.

### Campaign Creation Flow

1. User calls `create_campaign()` in `crowd_walrus.move` with campaign details
2. New `Campaign` object is created via `campaign::new()` with `CrowdWalrusApp` authorization
3. SuiNS subdomain is registered via `suins_manager.register_subdomain()` pointing to campaign's address
4. `CampaignOwnerCap` is transferred to creator for future operations

### Verification System

- `CrowdWalrus` emits verification events; campaigns keep their own `is_verified` flag
- Only holders of `VerifyCap` can verify/unverify campaigns
- Admin can create new `VerifyCap` tokens via `create_verify_cap()`
- Verification status is stored both in the central registry and on the campaign object itself

### SuiNS Integration

- `SuiNSManager` holds a `SuinsRegistration` NFT as a dynamic object field
- The NFT grants permission to create subdomains under the parent domain
- Admin must call `set_suins_nft()` with the registration NFT before subdomain operations work
- Each campaign gets its own subdomain pointing to the campaign's address

## Dependencies

- **Sui Framework**: Mainnet version from MystenLabs
- **SuiNS Core**: Testnet v2 (from `releases/testnet/core/v2`)
- **Subdomains**: Testnet v2 (from `releases/testnet/core/v2`)

For mainnet deployment, update SuiNS dependencies to mainnet versions.

## Code Conventions

- Use `entry fun` for public transaction entry points
- Use `public(package)` for module-internal cross-module calls
- Use `#[test_only]` for test helper functions
- Events are emitted for major state changes (verification, updates, etc.)
- Dynamic fields (`df`) for flexible key-value data, dynamic object fields (`dof`) for storing objects
- VecMap for campaign metadata to support arbitrary key-value pairs
