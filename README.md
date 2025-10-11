# CrowdWalrus Smart Contracts

A Sui Move smart contract system for managing crowdfunding campaigns with SuiNS subdomain integration.

## Overview

CrowdWalrus is a decentralized crowdfunding platform built on Sui blockchain that integrates with SuiNS (Sui Name Service) to provide subdomain management for campaigns. The system consists of three main modules:

- **crowd_walrus**: Main contract managing the platform and validation system
- **campaign**: Handles crowdfunding campaign logic and lifecycle
- **suins_manager**: Integrates with SuiNS for subdomain registration and management

## Prerequisites

Before deploying, ensure you have:

1. **Sui CLI**: Install the latest version from [Sui documentation](https://docs.sui.io/guides/developer/getting-started/sui-install)
2. **Active Sui Address**: Set up with sufficient SUI tokens for gas fees
3. **Network Access**: Configure for testnet, devnet, or mainnet deployment

## Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd crowdwalrus-contracts
```

2. Install dependencies (optional, for formatting):

```bash
npm install
# or
bun install
```

## Building the Contracts

Build the Move contracts before deployment:

```bash
sui move build
```

This will compile all modules and generate the build artifacts in the `build/` directory.

## Testing

Run the test suite to ensure everything works correctly:

```bash
sui move test
```

The test files are located in the `tests/` directory and include:

- `crowd_walrus_tests.move`
- `campaign_tests.move`
- `suins_manager_tests.move`

## Deployment

### 1. Configure Network

Set your Sui CLI to the desired network:

```bash
# For testnet
sui client switch --env testnet

# For devnet
sui client switch --env devnet

# For mainnet
sui client switch --env mainnet
```

### 2. Check Active Address

Verify your active address and balance:

```bash
sui client active-address
sui client gas
```

### 3. Deploy the Package

Deploy the smart contracts to the network:

```bash
sui client publish
```

**Important**: Save the output from this command as it contains:

- Package ID
- Object IDs for created objects
- Transaction digest

### 3.1. Set SuiNS NFT on SuiNSManager

In order to register subdomains when creating campaigns, you need to set the SuiNS NFT on SuiNSManager. To do that, you need to call the `set_suins_nft` function on SuiNSManager.
In test environment, we did create crowdwalrus-test.sui domain and set its NFT (`0x98dd15073e0b781ca524f7ef102edac6cd4393119a1f2f2b20f24f9056adb6d9`) object on SuiNSManager.

**NOTE**: The set SuiNS NFT will be used for all campaigns created in the future. It defines the base domain newly created campaigns will be registered on. For example, if you set the SuiNS NFT to `crowdwalrus-test.sui`, all campaigns will be registered on `crowdwalrus-test.sui` domain, e.g. campaign1.crowdwalrus-test.sui, campaign2.crowdwalrus-test.sui, etc.

**NOTE**: If you want to change the SuiNS NFT, you need to call the `remove_suins_nft` function on SuiNSManager to remove the old SuiNS NFT and then call the `set_suins_nft` function to set the new SuiNS NFT. The `remove_suins_nft` last parameter will define who will receive the old SuiNS NFT, which normally must be an account address.

**NOTE**: In case you want to deploy a new version of the SuiNSManager, you need to set the new SuiNS NFT on the new SuiNSManager. You need to do that manually in two steps:

1. Remove the old SuiNS NFT from the old SuiNSManager and send it to an account address which holds SuinsManager::AdminCap object.

2. Set the new SuiNS NFT on the new SuiNSManager using `set_suins_nft` function. That must be called by an account address which holds SuinsManager::AdminCap object on the new SuiNSManager.

Example:

```bash
sui client call --package PACKAGE_ID --module suins_manager --function set_suins_nft --args 0x98dd15073e0b781ca524f7ef102edac6cd4393119a1f2f2b20f24f9056adb6d9
```

### 4. Environment Setup

After successful deployment, update the package address in `Move.toml`:

```toml
[addresses]
crowd_walrus = "YOUR_DEPLOYED_PACKAGE_ID"
```

### 5. Initialize the System

After deployment, you'll need to initialize the CrowdWalrus system by calling the initialization functions with the appropriate parameters.

## Configuration

### Dependencies

The package uses the following dependencies:

- **Sui Framework**: Latest mainnet framework from MystenLabs
- **SuiNS Core**: Testnet core v2 for name service integration
- **SuiNS Subdomains**: Testnet subdomain management v2
- **SuiNS Denylist**: Testnet denylist management v2

All hosted on https://github.com/aminlatifi/suins-contracts/tree/crowdwalrus-testnet-core-v2 to work with suins version deployed on testnet.

### Network-Specific Notes

- **Testnet**: Uses SuiNS testnet contracts for subdomain functionality
- **Mainnet**: Requires updating SuiNS dependencies to mainnet versions
- **Devnet**: Suitable for development and testing

## Usage Examples

After deployment, you can interact with the contracts using:

```bash
# Call contract functions
sui client call --package PACKAGE_ID --module MODULE_NAME --function FUNCTION_NAME --args ARG1 ARG2

# Query objects
sui client object OBJECT_ID
```

## Repository Structure

```
crowdwalrus-contracts/
├── sources/           # Move source files
│   ├── crowd_walrus.move
│   ├── campaign.move
│   └── suins_manager.move
├── tests/            # Test files
├── build/            # Compiled artifacts
├── Move.toml         # Package configuration
└── README.md         # This file
```

### Getting Help

- Check CrowdWalrus documentation: https://github.com/CrowdWalrus/Docs
- Check Sui documentation: https://docs.sui.io
- Review Move language reference: https://move-language.github.io/move/
- SuiNS documentation: https://suins.io/docs
