# Build/Test/Deploy Reference (Move 2024, Mainnet + Testnet)

This is the canonical reference for building, testing, and deploying this package after the Move 2024 package manager changes (single `Move.toml`, `Published.toml`, and environment-based builds).

---

## Key Concepts (Read Once)

- **Move edition `2024`** is an edition name, not the calendar year. It enables the modern package manager used by current Sui CLI releases.
- **No `[addresses]` in `Move.toml`.** Address management is handled by `Published.toml` + the selected build environment.
- **`Published.toml` should be committed.** It tracks published package IDs per environment.
- **Use `--environment` for clarity.** It ensures you build/test/publish against the intended network or unpublished flow.

---

## Environments

These are the environments used by this repo:

- **`mainnet`**: standard Sui CLI mainnet environment.
- **`testnet`**: standard Sui CLI testnet environment.
- **`testnet_unpublished`**: custom env defined in `Move.toml` with the testnet chain-id.  
  Use this to build/test/publish without binding to an already published testnet package in `Published.toml`.

> If you ever need a **fresh mainnet publish** while a `published.mainnet` entry already exists, add a similar `mainnet_unpublished` environment (using the mainnet chain-id) and publish with that, then copy the entry into `[published.mainnet]`.

---

## Tooling Setup

Use `suiup` to pin the Sui CLI version per network:

```bash
# Show installed binaries
suiup show

# Switch default CLI
suiup switch sui@mainnet-<version>
suiup switch sui@testnet-<version>

# Confirm version
sui --version
```

---

## Build and Test (Reference)

Always use explicit environments:

```bash
# Mainnet
sui move build --environment mainnet
sui move test  --environment mainnet

# Testnet (published package)
sui move build --environment testnet
sui move test  --environment testnet

# Testnet (unpublished / local)
sui move build --environment testnet_unpublished
sui move test  --environment testnet_unpublished
```

Notes:
- `Move.lock` updates per environment; keep it committed.
- Warnings from dependencies (e.g., Pyth) are expected; tests still pass.

---

## Deploy (Fresh Publish)

### Testnet (Fresh Publish)

Use the unpublished environment so you do not bind to an existing `published.testnet` entry:

```bash
sui client publish --environment testnet_unpublished --gas-budget 500000000
```

After publish:
1. Capture the new package ID and all shared/owned object IDs.
2. Update `Published.toml` by copying the `testnet_unpublished` entry to `[published.testnet]`.
3. Update `deployment.addresses.testnet.json` (and create a dated copy).

### Mainnet (Fresh Publish)

```bash
sui client publish --environment mainnet --gas-budget 500000000
```

After publish:
1. Capture the new package ID and all shared/owned object IDs.
2. If `Published.toml` has no `mainnet` entry yet, add it.
3. Update `deployment.addresses.mainnet.json` (and create a dated copy).

---

## Deploy (Upgrade)

Upgrades require the package to be recognized as already published in the target environment.

### Testnet Upgrade

```bash
sui client upgrade --environment testnet \
  --upgrade-capability "$UPGRADE_CAP" \
  --verify-compatibility \
  --gas-budget 500000000 \
  .
```

### Mainnet Upgrade

```bash
sui client upgrade --environment mainnet \
  --upgrade-capability "$UPGRADE_CAP" \
  --verify-compatibility \
  --gas-budget 500000000 \
  .
```

After upgrades:
- `Published.toml` should reflect the new version for that environment.
- Update deployment records with the new package ID and upgrade tx digest.

---

## Published.toml Checklist

This file is the source of truth for published package IDs:

```bash
cat Published.toml
```

Expected pattern:

```
[published.testnet]
chain-id = "4c78adac"
published-at = "<PACKAGE_ID>"
original-id = "<PACKAGE_ID>"
version = <VERSION>
```

Copy the same structure for `published.mainnet` once mainnet is published.

---

## Quick sanity checks

```bash
sui client active-env
sui client active-address
sui client gas
```

For object sanity (replace IDs):

```bash
sui client object <PACKAGE_ID>
sui client object <CROWD_WALRUS_ID>
sui client object <TOKEN_REGISTRY_ID>
```

---

## Related docs

- `docs/phase2/NEW_TESTNET_DEPLOYMENT_GUIDE.md`
- `docs/phase2/TESTNET_DEPLOYMENT_GUIDE.md`
- `docs/phase2/UPGRADE_TO_SINGLE_PTB.md`
- `docs/phase2/mainnet-dry-run-lessons.md`
