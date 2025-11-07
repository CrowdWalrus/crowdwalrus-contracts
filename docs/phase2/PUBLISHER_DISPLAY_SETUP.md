# Phase 2 Publisher & Display Setup

This guide documents how the deployer configures Sui Display metadata for the non-transferable `DonorBadge` collectibles introduced in Phase 2.

## Workflow Overview

1. **Capture the Publisher at publish time.** The package initializer calls `sui::package::claim_and_keep`, so every publish emits a `Publisher` object under “Created Objects.” Record its ID; the object remains owned by the publishing address.
2. **Call the admin entry once per package version.** While you still hold the `Publisher`, submit a PTB that invokes `crowd_walrus::badge_rewards::setup_badge_display(&Publisher, &mut TxContext)`. Because the entry borrows the owned `Publisher`, only the deployer can execute it.
3. **No extra claiming or manual version bumps required.** The entry registers the four required Display fields (`name`, `image_url`, `description`, `link`), calls `display::update_version` internally, and shares the Display object so wallets pick up the metadata. Upgrades repeat the same flow using the new `Publisher` emitted by that publish transaction.

## Why the Publisher Matters

The `Publisher` object proves control over the `DonorBadge` type. Requiring `&Publisher` guarantees that only the official package deployer can register or refresh the Display template, preventing spoofed metadata.

## Wallet Impact

Once `setup_badge_display` runs, Sui wallets and marketplaces render donor badges with the configured fields, allowing supporters to see level, artwork, and descriptive copy instead of raw object data.
