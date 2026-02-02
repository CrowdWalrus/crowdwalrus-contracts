# SuiNS Dependency Address Management Issue

## Problem Summary

When integrating SuiNS contracts as dependencies in a Sui Move package, you may encounter the error:

```
Conflicting assignments for address 'suins': '0x...' and '0x0'
```

This occurs because Sui Move's dependency system cannot override addresses from git dependencies when those dependencies specify their own addresses in their `Move.toml` files.

> **Move 2024 note:** With the new package manager, you should **not** set `[addresses]` in your consuming package. Address resolution now uses dependency metadata (including `published-at`) plus `Published.toml`. The examples below referencing `[addresses]` are kept for historical context.

## Current Fix (Jan 2026)

We no longer use the `releases/*` branches for SuiNS. The `main` branch includes
the renamed packages (`suins_subdomains`, `suins_denylist`) and the `published-at`
metadata needed for `sui client publish --dry-run` without
`--with-unpublished-dependencies`. The upstream `testnet` branch still leaves
`denylist` at `0x0`, so we use a fork with corrected addresses for testnet and
map package names with `rename-from`.

**Move.toml (summary):**

```toml
[dependencies]
suins = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/suins", rev = "main", published-at = "0x71af035413ed499710980ed8adb010bbf2cc5cacf4ab37c7710a4bb87eb58ba5" }
suins_subdomains = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/subdomains", rev = "main", published-at = "0xe0108df96c8dfac6d285e5b8afbeafc9a205002a3ec7807329929c8b4d53a8a0" }
suins_denylist = { git = "https://github.com/MystenLabs/suins-contracts.git", subdir = "packages/denylist", rev = "main", published-at = "0xc967b7862d926720761ee15fbd0254a975afa928712abcaa4f7c17bb2b38d38b" }

[dep-replacements.testnet]
suins = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/suins", rev = "crowdwalrus-testnet-core-v2", published-at = "0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1" }
suins_subdomains = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/subdomains", rev = "crowdwalrus-testnet-core-v2", rename-from = "subdomains", published-at = "0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636" }
suins_denylist = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/denylist", rev = "crowdwalrus-testnet-core-v2", rename-from = "denylist", published-at = "0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49" }
```

This is the approach used in this repo today (see `Move.toml`).

## Root Cause

### Incomplete Testnet Release Configuration

The official [MystenLabs/suins-contracts](https://github.com/MystenLabs/suins-contracts) `releases/testnet/core/v2` branch has **inconsistent address configuration**:

**✅ `suins` package** - Testnet address IS uncommented:
```toml
[addresses]
# mainnet
#suins = "0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0"
# testnet
suins = "0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93"
```

**❌ `subdomains` package** - Testnet address is STILL commented out:
```toml
[addresses]
#mainnet
subdomains="0x0"

#testnet
#subdomains = "0xb0c14a9891efc8080e976db617a2d830183aa9034cbdf575dbb9e5856e38c283"
```

**❌ `denylist` package** - Set to 0x0 instead of testnet address:
```toml
[addresses]
denylist = "0x0"
```

This appears to be an **oversight** in the official release branch rather than an intentional design.

### Sui Move Limitation (still relevant)

Sui Move's build system does not allow you to override a dependency's address assignment from your consuming package unless:
- The dependency sets its address to `"_"` (unassigned)
- The dependency uses automated address management properly
- You use `addr_subst` (which also fails in this case due to timing of conflict detection)

Since the official branch has `subdomains="0x0"` and `denylist="0x0"`, and there's no way to override these from the consuming package, the build fails with address conflicts.

## Failed Solutions

### ❌ Using `addr_subst`
```toml
[dependencies]
suins = { git = "...", addr_subst = { "suins" = "0x..." } }
```
**Result**: Still throws "Conflicting assignments" error because conflict is detected before substitution occurs.

### ❌ Overriding in `[addresses]` section (legacy pre‑Move‑2024)
```toml
[addresses]
suins = "0x..."
```
**Result**: Creates conflict with the dependency's own `Move.toml` address setting (and is no longer supported in the Move 2024 flow).

### ❌ Using `override = true`
```toml
[dependencies]
suins = { git = "...", override = true }
```
**Result**: Only resolves version conflicts, not address conflicts.

### ❌ Using Move Registry (MVR)
```toml
[dependencies]
suins = { r.mvr = "@suins/core", override = true }
suins_subdomains = { r.mvr = "@suins/subnames", override = true }
```
**Result**: Version conflicts between core (v5) and subdomains (requires v2 core).

## Solutions

### ✅ Solution 1: Use a Fork with Fixed Addresses (Current)

Use a fork of the official repository that has properly uncommented the testnet addresses for ALL packages (not just `suins`).

**Example fork**: [aminlatifi/suins-contracts](https://github.com/aminlatifi/suins-contracts)

This fork fixes the official release by:
1. Uncommenting the testnet address in `subdomains/Move.toml`
2. Uncommenting the testnet address in `denylist/Move.toml`
3. Adding correct `published-at` metadata

```toml
[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/mainnet", override = true }
suins = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/suins", rev = "crowdwalrus-testnet-core-v2" }
subdomains = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/subdomains", rev = "crowdwalrus-testnet-core-v2" }
denylist = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/denylist", rev = "crowdwalrus-testnet-core-v2" }
```

**Note**: The fork uses package names `subdomains` and `denylist` (not `suins_subdomains` and `suins_denylist`).
We keep `suins_*` names in our code and map them with `rename-from`:

```toml
suins_subdomains = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/subdomains", rev = "crowdwalrus-testnet-core-v2", rename-from = "subdomains" }
suins_denylist = { git = "https://github.com/aminlatifi/suins-contracts.git", subdir = "packages/denylist", rev = "crowdwalrus-testnet-core-v2", rename-from = "denylist" }
```

### ✅ Solution 1b: Use official releases with `published-at`

If the official release tags include correct `published-at` metadata, prefer those tags directly in your `Move.toml`. This aligns with the Move 2024 package manager and avoids local address overrides.

### 🚫 Disallowed: `--with-unpublished-dependencies`

We **do not** use `--with-unpublished-dependencies`. All dependencies must be
published on-chain and referenced with correct `published-at` metadata.

### ✅ Solution 3: Create Your Own Fork

1. Fork [MystenLabs/suins-contracts](https://github.com/MystenLabs/suins-contracts)
2. Checkout the appropriate release branch (e.g., `releases/testnet/core/v2`)
3. Fix the testnet addresses in:
   - `packages/suins/Move.toml` ✅ (already uncommented)
   - `packages/subdomains/Move.toml` ❌ (needs uncommenting)
   - `packages/denylist/Move.toml` ❌ (needs changing from `0x0` to actual testnet address)
4. Optionally add `published-at` metadata for better package tracking
5. Create a new branch (e.g., `testnet-core-v2-configured`)
6. Use your fork in `Move.toml`

**Specific changes needed:**

`packages/subdomains/Move.toml`:
```toml
# Change from:
#testnet
#subdomains = "0xb0c14a9891efc8080e976db617a2d830183aa9034cbdf575dbb9e5856e38c283"

# To:
#testnet
subdomains = "0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636"
```

`packages/denylist/Move.toml`:
```toml
# Change from:
denylist = "0x0"

# To:
#testnet
denylist = "0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49"
```

## Package Name Differences (still relevant)

**Official MystenLabs packages** (mainnet releases):
- `suins` → package name: `suins`
- `suins_subdomains` → package name: `suins_subdomains`
- `suins_denylist` → package name: `suins_denylist`

**Fork with uncommented addresses**:
- `suins` → package name: `suins`
- `subdomains` → package name: `subdomains`
- `denylist` → package name: `denylist`

Make sure your `use` statements match the package names:

```move
// For fork (aminlatifi)
use suins::suins::SuiNS;
use subdomains::subdomains::{new_leaf, remove_leaf};
use subdomains::subdomain_tests as subdomain_tests;

// For official MystenLabs (if they had addresses uncommented)
use suins::suins::SuiNS;
use suins_subdomains::subdomains::{new_leaf, remove_leaf};
use suins_subdomains::subdomain_tests as subdomain_tests;
```

## Network-Specific Addresses (Testnet)

For reference, these are the testnet addresses as of core v2:

```toml
suins = "0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93" # original-id
suins_published = "0x67072134f0867b886c9541873d1cb327feb7e161cd56dd76cb6aa9e464410db1" # published-at used by core v2 branch
suins_subdomains = "0x3c272bc45f9157b7818ece4f7411bdfa8af46303b071aca4e18c03119c9ff636"
suins_denylist = "0xa86c05fbc6371788eb31260dc5085f4bfeab8b95c95d9092c9eb86e63fae3d49"
```

Note: A newer SuiNS package exists on testnet, but the core v2 fork pins the
`published-at` shown above, so we keep it aligned with that branch.

## Should This Be Reported to MystenLabs?

**Yes, potentially.** The inconsistent address configuration in `releases/testnet/core/v2` could be:
- An oversight that should be fixed
- Or an intentional state if they expect users to use unpublished deps (not allowed for us)

You could open an issue on [MystenLabs/suins-contracts](https://github.com/MystenLabs/suins-contracts/issues) asking:
1. Is the testnet release branch intended to be usable directly as a git dependency?
2. If yes, should `subdomains` and `denylist` have their testnet addresses uncommented like `suins` does?
3. If no, should the documentation clarify the intended usage pattern?

## Future Improvements

The Sui ecosystem is actively working on better solutions:

1. **Move Registry (MVR)**: Intended to resolve dependencies from on-chain published packages automatically
2. **Improved Address Management**: Better override mechanisms for git dependencies
3. **Package Maintainer Best Practices**: Encouraging published packages to use automated address management
4. **Consistent Release Branches**: Ensuring all packages in a release have compatible address configurations

## Related Resources

- [SuiNS Integration Docs](https://docs.suins.io/developer/integration)
- [Sui Automated Address Management](https://docs.sui.io/concepts/sui-move-concepts/packages/automated-address-management)
- [Forum: Choosing on-chain location of external dependency](https://forums.sui.io/t/choosing-the-on-chain-location-of-an-external-dependency/2310)
- [Package Maintainer Best Practices](https://docs.suins.io/move-registry/maintainer-practices)

## Troubleshooting

### Error: "Conflicting assignments for address"
- **Solution**: Use `main`/`testnet` branches with `suins_*` packages + `published-at` in Move.toml

### Error: "Name of dependency 'X' does not match dependency's package name 'Y'"
- **Solution**: Check the actual package name in the dependency's `Move.toml` and match it exactly,
  or use `rename-from` to map the original package name to your preferred dependency name.

### Error: MVR version conflicts
- **Solution**: Stick with git dependencies until MVR matures, or ensure all MVR packages use compatible versions

### Build succeeds but imports fail
- **Solution**: Verify your `use` statements match the actual package names (check for `suins_subdomains` vs `subdomains`)

## Last Updated

January 2026 (SuiNS main branch + forked testnet core v2 packages with `rename-from`)
