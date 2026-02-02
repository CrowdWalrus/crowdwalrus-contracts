# Build/Test/Deploy Reference (Move 2024, Mainnet + Testnet)

This is the canonical reference for building, testing, and deploying this package after the Move 2024 package manager changes (single `Move.toml`, `Published.toml`, and environment-based builds).

---

## Key Concepts (Read Once)

- **Move edition `2024`** is an edition name, not the calendar year. It enables the modern package manager used by current Sui CLI releases.
- **No `[addresses]` in `Move.toml`.** Address management is handled by `Published.toml` + the selected build environment.
- **`Published.toml` should be committed.** It tracks published package IDs per environment.
- **Do not use `--with-unpublished-dependencies`.** Fix `Move.toml` + `published-at` instead.
- **Branch revs are OK.** `Move.lock` pins the exact commit for reproducible builds.
- **Use `sui client switch --env …` for publish/dry‑run.** It avoids mixing flags and keeps the active network obvious.
- **SuiNS deps are now `suins_*`.** The upstream `main` branch renamed `subdomains`/`denylist` → `suins_subdomains`/`suins_denylist`.
- **Testnet SuiNS uses a fork.** Upstream testnet leaves `denylist` at `0x0`, so we use a fork and map package names via `rename-from`.
- **Build output note:** Testnet builds still print `subdomains`/`denylist` because those are the fork’s package names; `rename-from` keeps our in-code names consistent.

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
# Note: tests will fail in this env because Published.toml pins a real package ID.

# Testnet (unpublished / local)
sui move build --environment testnet_unpublished
sui move test  --environment testnet_unpublished
```

Notes:
- `Move.lock` updates per environment; keep it committed.
- `sui move test --environment testnet` fails with `0x0::` unbound module errors because tests use `expected_failure` locations.
- Warnings from dependencies (e.g., Pyth) are expected; tests still pass in `mainnet` and `testnet_unpublished`.

---

## Dry-run Publish (No Unpublished Deps)

```bash
# Mainnet dry-run
sui client switch --env mainnet
sui client publish --dry-run --gas-budget 500000000

# Testnet dry-run (use unpublished env to avoid Published.toml lock-in)
sui client switch --env testnet_unpublished
sui client publish --dry-run --gas-budget 500000000
```

Last observed gas estimates (Jan 2026):
- mainnet: `346,677,700 MIST`
- testnet_unpublished: `349,230,800 MIST`

---

## Deploy (Fresh Publish)

### Testnet (Fresh Publish)

Use the unpublished environment so you do not bind to an existing `published.testnet` entry:

```bash
sui client switch --env testnet_unpublished
sui client publish --gas-budget 500000000
```

After publish:
1. Capture the new package ID and all shared/owned object IDs.
2. Update `Published.toml` by copying the `testnet_unpublished` entry to `[published.testnet]`.
3. Update `deployment.addresses.testnet.json` (and create a dated copy).

### Mainnet (Fresh Publish)

```bash
sui client switch --env mainnet
sui client publish --gas-budget 500000000
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
sui client switch --env testnet
sui client upgrade \
  --upgrade-capability "$UPGRADE_CAP" \
  --verify-compatibility \
  --gas-budget 500000000 \
  .
```

### Mainnet Upgrade

```bash
sui client switch --env mainnet
sui client upgrade \
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

---

## Dependency Package IDs (Reference)

These are useful for sanity checks and PTB config:

**Pyth + Wormhole**
- Mainnet Pyth package: `0x04e20ddf36af412a4096f9014f4a565af9e812db9a05cc40254846cf6ed0ad91`
- Mainnet Wormhole package: `0x5306f64e312b581766351c07af79c72fcb1cd25147157fdc2f8ad76de9a3fb6a`
- Testnet Pyth package: `0xabf837e98c26087cba0883c0a7a28326b1fa3c5e1e2c5abdb486f9e8f594c837`
- Testnet Wormhole package: `0xf47329f4344f3bf0f8e436e2f7b485466cff300f12a166563995d3888c296a94`

**Pyth PTB State IDs**
- Mainnet Pyth State: `0x1f9310238ee9298fb703c3419030b35b22bb1cc37113e3bb5007c99aec79e5b8`
- Mainnet Wormhole State: `0xaeab97f96cf9877fee2883315d459552b2b921edc16d7ceac6eab944dd88919c`
- Testnet Pyth State: `0x243759059f4c3111179da5878c12f68d612c21a8d54d85edc86164bb18be1c7c`
- Testnet Wormhole State: `0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790`

**SuiNS (`suins_*`)**
- Mainnet SuiNS (current): `0x71af035413ed499710980ed8adb010bbf2cc5cacf4ab37c7710a4bb87eb58ba5`
- Mainnet SuiNS (original): `0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0`
- Mainnet Subnames (current): `0xe0108df96c8dfac6d285e5b8afbeafc9a205002a3ec7807329929c8b4d53a8a0`
- Mainnet Subnames (original): `0xe177697e191327901637f8d2c5ffbbde8b1aaac27ec1024c4b62d1ebd1cd7430`
- Mainnet Denylist: `0xc967b7862d926720761ee15fbd0254a975afa928712abcaa4f7c17bb2b38d38b`
- Testnet SuiNS (core v2 published-at): `0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1`
- Testnet SuiNS (original): `0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93`
- Testnet Subnames: `0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636`
- Testnet Denylist: `0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49`

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
