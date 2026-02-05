# Fix Deployment Issues (Dry-Run Publish)

Date/time recorded: 2026-01-31 18:14:34 +04 (+0400)

## Scope
This document records the problems and fixes we applied while troubleshooting
`sui client publish --dry-run` for mainnet/testnet. The focus was to make dry-run
work without `--with-unpublished-dependencies` and without using the deprecated
`--environment`/`--json` flags on publish.

## Problems Encountered

1) **Dry-run failed with** `Failed to fetch package Pyth` and
   `Object 0x04e20dd... does not exist`.
   - This happened when running:
     `sui client publish --dry-run --environment mainnet --json`
   - Pyth mainnet package IDs do not exist on testnet RPC endpoints.

2) **Using `--environment`/`--json` on publish.**
   - We explicitly decided to avoid `--environment` and `--json` for publish/dry-run
     to keep behavior consistent and reduce confusion.

3) **Testnet dry-run failed in `testnet` env** due to `Published.toml` already
   pinning a published package. Tests also failed with `0x0::` unbound modules.

4) **SuiNS testnet dependency addresses were `0x0` upstream**, causing address
   conflicts without `--with-unpublished-dependencies`.

5) **Out-of-date SuiNS published-at IDs** (mainnet and testnet) caused mismatches
   between declared dependency IDs and the IDs used by the chain during dry-run.

6) **Warnings unrelated to failure** were shown:
   - `lint(share_owned)` unknown warning filter.
   - Invalid doc comments in dependency sources (Pyth/SuiNS).

## Root Causes

- `--environment mainnet` only affects Move build environment; it does **not**
  switch the RPC. If `sui client` is still pointed at testnet, fetching mainnet
  package IDs fails.
- `Published.toml` binds `testnet` to an already published package; dry-run
  behaves as if upgrading, not as a fresh publish.
- Upstream SuiNS testnet branch has `denylist` address set to `0x0`.
- SuiNS latest published package IDs changed (mainnet latest is not the earlier
  `0x00c2...` anymore; testnet latest is not `0x6707...`).

## Fixes Applied

1) **Always switch the client RPC environment explicitly** before dry-run:
   - Mainnet:
     ```bash
     sui client switch --env mainnet
     sui client publish --dry-run --gas-budget 500000000
     ```
   - Testnet dry-run (unpublished env):
     ```bash
     sui client switch --env testnet_unpublished
     sui client publish --dry-run --gas-budget 500000000
     ```

2) **Stop using `--environment`/`--json` on publish/dry-run.**
   - We kept environment control strictly in `sui client switch --env ...`.

3) **Use `testnet_unpublished` for dry-run and tests** so that
   `Published.toml` does not force a published package ID.

4) **Use forked SuiNS testnet packages** with corrected addresses and
   `rename-from` mapping to keep `suins_*` names in our code.

5) **Update SuiNS published-at IDs** to latest on-chain packages:
   - Mainnet SuiNS published-at: `0x71af035413ed499710980ed8adb010bbf2cc5cacf4ab37c7710a4bb87eb58ba5`
   - Testnet SuiNS published-at (core v2): `0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1`
   - Note: deployment JSON `globals.suinsPackage` should still use the **original**
     SuiNS package ID that matches your SuinsRegistration NFT type (e.g., mainnet
     `0xd22b...`, testnet `0x22fa...`).

6) **Document expected warnings** so they are not mistaken for failures.

## Verified Results

- Mainnet dry-run succeeded:
  - Dependencies list includes Pyth/Wormhole mainnet packages and SuiNS `0x71af...`.
  - Estimated gas: `346,677,700 MIST`.

- Testnet dry-run succeeded in `testnet_unpublished`:
  - Dependencies list includes Pyth/Wormhole testnet packages and SuiNS `0x670...`.
  - Estimated gas: `349,230,800 MIST`.

## Update (2026-01-31 18:59:16 +0400)

- Switched testnet SuiNS from a vendored copy to the forked `crowdwalrus-testnet-core-v2`
  branch using `rename-from` for `subdomains`/`denylist`.
- Aligned testnet SuiNS `published-at` to the fork’s value (`0x670...`) and confirmed
  the dry‑run dependency list uses it.
- Verified dry-run still succeeds on mainnet and `testnet_unpublished` without
  `--with-unpublished-dependencies`.

## Reference Checks

- Confirm the client is on the intended RPC:
  ```bash
  sui client active-env
  sui client envs
  ```

- If a dependency fetch fails, verify it exists on the current network:
  ```bash
  sui client object --json <PACKAGE_ID> | jq -r '.type'
  ```

## Notes

- The `lint(share_owned)` warnings do not stop the dry-run.
- Invalid doc comment warnings in dependencies do not stop builds.
- Testnet tests fail in `testnet` env due to `0x0::` locations in `expected_failure`.
  Use `testnet_unpublished` for tests.
