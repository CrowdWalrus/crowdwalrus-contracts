# CrowdWalrus Smart Contracts – Security Audit

## Overview
- **Scope**: Move modules under `sources/` (`crowd_walrus`, `campaign`, `suins_manager`).
- **Tech Stack**: Sui Move 2024.beta with dependencies on Sui framework and SuiNS packages.
- **Methodology**: Manual source review focusing on authentication/authorization flows, state transition safety, data validation, and integration with external SuiNS components.

## Summary of Findings
| ID | Title | Severity | Status |
| --- | --- | --- | --- |
| F-01 | Unbounded campaign metadata can exhaust storage/gas | Medium | Open |
| F-02 | Verification capability cannot be revoked | Medium | Open |
| F-03 | Missing length check before building VecMap in `create_campaign` | Low | Open |

## Detailed Findings

### F-01 Unbounded campaign metadata can exhaust storage/gas (Medium)
**Location**: `sources/campaign.move` lines 130-186; `sources/crowd_walrus.move` lines 114-165.

**Description**: The `campaign::new` documentation explicitly states that string lengths and metadata size limits are intentionally left to the frontend (`crowd_walrus::create_campaign` forwards user-provided metadata directly into `vec_map::from_keys_values`).【F:sources/campaign.move†L130-L186】【F:sources/crowd_walrus.move†L114-L165】 Attackers can craft transactions that submit extremely large vectors or long strings, forcing the Move VM to allocate and store oversized data. Because these values are written to shared objects, the excessive data persists on-chain and incurs high storage costs for the project, while each failed attempt only costs gas to the attacker.

**Impact**: High storage or execution cost, potential denial of service for honest users if gas limits are hit.

**Recommendation**: Enforce reasonable upper bounds on metadata vector length and string size within the Move code. Reject requests exceeding project-defined limits before attempting to materialize the `VecMap`.

### F-02 Verification capability cannot be revoked (Medium)
**Location**: `sources/crowd_walrus.move` lines 302-318.

**Description**: `create_verify_cap` mints a `VerifyCap` object and sends it to an address but the module exposes no function for the admin to claw back or invalidate a compromised capability.【F:sources/crowd_walrus.move†L302-L318】 If a verifier’s key is lost or stolen, the attacker can continue to mark arbitrary campaigns as verified/unverified indefinitely.

**Impact**: Compromise of a verifier permanently undermines campaign vetting, damaging trust in the platform.

**Recommendation**: Provide an admin-only revoke path (e.g., forcing a transfer to admin followed by `object::delete`) or gate verification on an allow-list stored on-chain so the admin can disable a verifier without their cooperation.

### F-03 Missing length check before building VecMap in `create_campaign` (Low)
**Location**: `sources/crowd_walrus.move` lines 134-158.

**Description**: `create_campaign` calls `vec_map::from_keys_values(metadata_keys, metadata_values)` without first validating that both vectors have the same length.【F:sources/crowd_walrus.move†L134-L158】 If the vectors mismatch, `from_keys_values` aborts with a generic VecMap error, bubbling up as a transaction failure without a descriptive platform-specific error code.

**Impact**: Low. Users receive unclear feedback on malformed metadata submissions, and repeated failing transactions waste gas.

**Recommendation**: Add an explicit `assert!(vector::length(&metadata_keys) == vector::length(&metadata_values), /* custom error */)` before building the map to provide deterministic, user-friendly failures.

## Additional Observations
- The access-control checks around campaign deletion correctly ensure that only campaigns owned by the platform’s admin can be torn down and that SuiNS entries are removed beforehand.【F:sources/crowd_walrus.move†L236-L276】
- Campaign updates and metadata edits already validate key/value lengths and prevent modification of immutable semantic keys such as `funding_goal` and `recipient_address`, which is a good practice.【F:sources/campaign.move†L236-L336】

## Recommended Next Steps
1. Prioritize remediation of the two medium-severity findings.
2. Add regression tests covering the new guardrails once implemented.
3. Consider performing a follow-up review after fixes to confirm that mitigations do not introduce regressions.
