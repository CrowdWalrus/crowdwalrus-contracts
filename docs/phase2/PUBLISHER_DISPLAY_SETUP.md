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

## Updating Display Metadata After Publish

We now support in-place edits to the existing `Display<DonorBadge>` so ops can refresh copy/artwork without republishing the package.

- **Testnet display object ID**: `0x3e040f2d1efe17209a8acbdca994a46765654df45b4d59fc52b2f415d6933160` (created in tx `CZWgWxEb318Z728Jt5CSPZSzXEBf9yeRkN6hWFXKeNub`).
- **Authority**: either the package `Publisher` **or** the Crowd Walrus `AdminCap` can call the update entry; both paths emit the same events.
- **Function**: `badge_rewards::update_badge_display` (publisher path) or `crowd_walrus::update_badge_display_with_admin` (admin path).
- **Args (both functions)**: `<display_id> <keys: vector<string>> <values: vector<string>> <deep_link_base: string> <Clock (0x6)>`. Keys/values must be same length; only the provided fields are edited.
- **Allowed keys**: `name`, `image_url`, `description`. The `link` field is regenerated automatically and should not be included in `keys`.
- **Deep link base**: pass the base domain once (no trailing slash); the contract appends `/profile/{owner}` automatically so wallets get the correct deep link. Default production base: `https://crowdwalrus.xyz`.
- **Emitted events**: `display::VersionUpdated<DonorBadge>` and custom `badge_rewards::BadgeDisplayUpdated` (includes changed keys and timestamp). Wallet/indexers should listen for these to refresh metadata.

### When to Call
- After changing badge art URLs or moving CDN buckets (update `image_url`).
- When copy needs an edit (e.g., `name` or `description`).
- When switching badge deep links between staging/production by passing a different `deep_link_base`.

### CLI Examples

Update via **Publisher** (still held by deployer):

```bash
sui client call \
  --package $PACKAGE_ID \
  --module badge_rewards \
  --function update_badge_display \
  --args $PUBLISHER_ID \
        0x3e040f2d1efe17209a8acbdca994a46765654df45b4d59fc52b2f415d6933160 \
        '["name","image_url","description"]' \
        '["Crowd Walrus Donor Badge LVL {level}","{image_uri}","Updated description {owner}"]' \
        "https://crowdwalrus.xyz" \
        0x6 \
  --gas-budget 30000000
```

Update via **AdminCap** (no Publisher required):

```bash
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function update_badge_display_with_admin \
  --args 0x3e040f2d1efe17209a8acbdca994a46765654df45b4d59fc52b2f415d6933160 \
        $ADMIN_CAP_ID \
        $CROWD_WALRUS_ID \
        '["name","description"]' \
        '["Crowd Walrus Donor Badge LVL {level}","Updated description {owner}"]' \  
        "https://crowdwalrus.xyz" \
        0x6 \
  --gas-budget 30000000
```

Notes:
- Keep the `keys`/`values` vectors aligned; only the specified fields are edited before bumping the display version.
- The `link` field is always regenerated from `deep_link_base` plus `/profile/{owner}`; do not include `link` in `keys`.
- Every update call bumps the display version so wallets refresh automatically.

Finding the Display object ID after a new deploy:
- After running `setup_badge_display`, capture the created Display ID from the transaction effects, or query: `sui client objects --owner <your-address> | grep Display<badge_rewards::DonorBadge>`.

Remove fields via **Publisher**:

```bash
sui client call \
  --package $PACKAGE_ID \
  --module badge_rewards \
  --function remove_badge_display_keys \
  --args $PUBLISHER_ID \
        0x3e040f2d1efe17209a8acbdca994a46765654df45b4d59fc52b2f415d6933160 \
        '["description"]' \
        "https://crowdwalrus.xyz" \
        0x6 \
  --gas-budget 30000000
```

Remove fields via **AdminCap**:

```bash
sui client call \
  --package $PACKAGE_ID \
  --module crowd_walrus \
  --function remove_badge_display_keys_with_admin \
  --args 0x3e040f2d1efe17209a8acbdca994a46765654df45b4d59fc52b2f415d6933160 \
        $ADMIN_CAP_ID \
        $CROWD_WALRUS_ID \
        '["description"]' \
        "https://crowdwalrus.xyz" \
        0x6 \
  --gas-budget 30000000
```
