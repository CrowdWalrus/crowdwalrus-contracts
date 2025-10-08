# Contract Update Requirements for Campaign Editing

## Background
We are introducing an on-chain edit flow so campaign owners can adjust certain fields after creation while keeping immutable data (e.g., subdomain, creation timestamp) intact. The current `crowd_walrus` Move package only exposes `create_campaign` and auxiliary functions for updates history, which means any edit attempt must be encoded as a brand-new campaign. The new front-end will depend on contract support for partial edits that:

- Separate inexpensive Sui-only updates (title, short description, status) from storage-heavy Walrus metadata.
- Enforce the same or stricter validation rules as creation at the time of edit.
- Emit structured events so downstream indexers can reconcile diffs.
- Preserve capability-based ownership checks via `CampaignOwnerCap`.

The changes below describe what must be added or adjusted in the Move codebase **without supplying the final implementation**; each item explains _what_ to build and _why_ it matters for the product.

### Walrus Metadata Snapshot
When a campaign is created or edited, the front-end serializes the Lexical rich-text editor state (JSON string) and packages that JSON plus the cover image into a Walrus quilt upload. The contract does not store the blob itself; it only keeps references inside `campaign.metadata` so off-chain clients can fetch the quilt, download `description.json` (serialized Lexical editor state), and rebuild the editor state.

- `walrus_quilt_id`: String-encoded u256 returned by Walrus that points to the quilt bundle containing the serialized description JSON and embedded assets.
- `walrus_storage_epochs`: String representing the number of epochs we prepay Walrus to retain the quilt.
- `cover_image_id`: String handle for the primary image inside the quilt bundle (defaults to `cover.jpg` unless the UI names it differently).
- Additional keys like `category`, `social_twitter`, and `social_discord` stay alongside the Walrus entries so the contract keeps one metadata map for both storage pointers and ancillary campaign details.

## Required Changes

### 1. Add Entry Function for Editing Core Fields (`update_campaign_basics`)
- **What:** Introduce a new `entry fun update_campaign_basics` that accepts mutable `Campaign`, the caller’s `CampaignOwnerCap`, optional new name and optional new short description, plus `Clock`/`TxContext` for validation and event emission. Optionality should be expressed as `option::Option<String>` parameters (`None` = do not change, `Some(value)` = update). The `Campaign` struct now stores the donation destination as a dedicated `recipient_address: address` field (moved out of metadata).
- **Why:** The UI needs a lightweight transaction when owners only tweak Sui-stored strings. Bundling both fields in one function reduces round trips, keeps edits atomic, and avoids forcing a Walrus upload when the user changes text copy only.
- **Business Rules to Enforce:** Emit a `CampaignBasicsUpdated` event containing campaign ID, editor address, timestamp, and flags for the fields that changed. No string length validation at contract level - frontend handles this.

### 2. Add Entry Function for Editing Metadata (`update_campaign_metadata`)
- **What:** Expose `entry fun update_campaign_metadata` that updates or inserts key/value pairs in `campaign.metadata`. It must accept parallel vectors of keys and values, guard that their lengths match, and loop through to mutate existing entries or append new ones.
- **Why:** Metadata holds Walrus blob identifiers, category, and social links. The edit page will call this function after finishing a Walrus upload or changing any metadata-backed field, so the contract must allow targeted updates without recreating the whole object.
- **Additional Requirements:**
  - Reject attempts to mutate `funding_goal`; that key is immutable after creation to block bait-and-switch behaviour.
  - Metadata deletions are **out of scope** for MVP. Empty strings (`""`) are the intended mechanism for blanking metadata values. Frontend should only send empty strings when users explicitly clear fields. Contract treats `""` as a valid value and stores it normally in the `VecMap`.
  - Preserve existing insertion order (`VecMap` maintains first-write order). New keys append to the end; overwrites leave the original position unchanged.
  - Emit a `CampaignMetadataUpdated` event listing changed keys, timestamp, and editor address.

### 3. Promote Status Update to an Entry Function
- **What:** Convert the existing `set_is_active` helper into an `entry fun update_active_status` that accepts explicit `new_status: bool` parameter while checking the owner capability. The function only updates state and emits event if the status actually changes (no-op if status is already the target value).
- **Why:** The UI needs explicit on/off control rather than a toggle. The implementation checks if status is changing before emitting events, preventing misleading "changed" events when the value is already correct. This gives frontend full control while avoiding spurious events for indexers.

### 4. Strengthen Validation in `create_campaign`
- **What:** Update `create_campaign` to enforce basic date validation: `start_date < end_date` and `start_date` not in the past. The entry function accepts `recipient_address: address` explicitly instead of relying on metadata. No string length or recipient address validation is enforced - frontend is responsible for these checks.
- **Why:** Date validation prevents obviously broken campaigns. Other validations (name/description length, recipient address validation) are intentionally omitted to allow maximum flexibility - frontend handles these checks.

### 5. Enforce Immutability Constraints
- **What:** Add inline documentation and asserts clarifying which fields cannot change (subdomain, start date, creation timestamp, validation status, admin ID, funding goal, and recipient address). Guard `update_campaign_metadata` with a runtime abort (`E_FUNDING_GOAL_IMMUTABLE`) if the request includes the `funding_goal` key, and ensure the new struct field has no mutator.
- **Why:** Future contributors need guidance when modifying the module. Explicit checks prevent accidental relaxations that would break front-end assumptions or governance rules.

### 6. Emit New Events for Every Edit Path
- **What:** Define new structs and emit them from the corresponding entry functions:
  - `struct CampaignBasicsUpdated has copy, drop { campaign_id: ID, editor: address, timestamp_ms: u64, name_updated: bool, description_updated: bool }`
  - `struct CampaignMetadataUpdated has copy, drop { campaign_id: ID, editor: address, timestamp_ms: u64, keys_updated: vector<String> }`
  - `struct CampaignStatusChanged has copy, drop { campaign_id: ID, editor: address, timestamp_ms: u64, new_status: bool }`
- **Timestamp semantics:** The `timestamp_ms: u64` field stores Unix epoch milliseconds obtained from `Clock::timestamp_ms(&clock)`, NOT the Sui epoch number. This value updates once per checkpoint and remains identical for all calls within the same transaction.
- **Implementation note:** Move events must own their payloads. When emitting vectors you still read afterwards, copy them first, for example:
  ```
  let mut keys_for_event = vector::empty<String>();
  vector::extend(&mut keys_for_event, &keys);
  event::emit(CampaignMetadataUpdated { keys_updated: keys_for_event, ... });
  ```
  This avoids borrow-checker issues and makes ownership explicit.
- **Why:** Indexers and analytics need to track history with minimal replay work while keeping gas costs predictable.

### 7. Guard Against Oversized Metadata Updates
- **What:** No hard limits enforced at contract level. Frontend is responsible for reasonable metadata sizes. VecMap updates use `get_mut()` to preserve insertion order for existing keys, avoiding the issue where remove+insert moves keys to the end.
- **Why:** Flexibility prioritized over strict validation. Risk accepted that unbounded growth could cause gas issues. Order preservation ensures consistent iteration behavior for frontend and indexers.

### 8. Add Unit/Integration Tests Covering New Paths
- **What:** Extend Move test suite to cover happy and failure cases for each new entry function, ensuring capability checks, validation, and event emission behave as expected.
- **Why:** Contract changes are security-sensitive. Automated tests will prevent regressions while we iterate on front-end features tied to these functions.

## Error Codes
Reserve the following abort codes for the edit feature (existing codes 0–3 remain unchanged, future work can use higher numbers):

```
const E_KEY_VALUE_MISMATCH: u64 = 4;                    // Used: metadata keys/values length mismatch
const E_INVALID_DATE_RANGE: u64 = 5;                    // Used: start_date >= end_date
const E_START_DATE_IN_PAST: u64 = 6;                    // Used: start_date < current time
const E_CANNOT_CHANGE_GOAL_WITH_DONATIONS: u64 = 7;     // Reserved for future
const E_FUNDING_GOAL_IMMUTABLE: u64 = 8;                // Used: attempt to change funding_goal
const E_RECIPIENT_ADDRESS_INVALID: u64 = 9;             // Reserved for future
const E_RECIPIENT_ADDRESS_IMMUTABLE: u64 = 10;          // Reserved for future
```

### Constants

**No validation constants are defined** for string lengths (`name`, `short_description`) or metadata size limits (`MAX_METADATA_KEYS`).

**Rationale:** This is an intentional design decision to maximize flexibility. Frontend is responsible for input validation. The contract accepts any string length and unlimited metadata entries, accepting the risk of potential gas issues in exchange for developer freedom.

## Testing Expectations
Add Move tests that:

- Succeed and emit events for happy-path basics and metadata edits.
- Abort with the appropriate error codes for each guard (inactive campaign, missing Walrus fields, metadata overflow, funding goal immutability, recipient address validation, etc.).
- Exercise the new `create_campaign` validations to ensure new campaigns still pass creation after the stricter checks.
- Verify event field values match expected behavior:
  - `CampaignBasicsUpdated`: `name_updated` and `description_updated` flags correctly reflect which fields changed (true when `Some(value)` provided, false when `None`)
  - `CampaignMetadataUpdated`: `keys_updated` vector correctly lists all modified keys and preserves ordering
  - All events: `timestamp_ms` values are non-zero and identical within same transaction
  - All events: `editor` address matches transaction sender from `TxContext`

## Deferred Features
The following features were discussed during planning but are **out of scope for MVP** and may be implemented in future phases:

- **Funding Goal Edits:** Initially considered with locking mechanism after first donation, but ultimately decided to make `funding_goal` completely immutable to eliminate bait-and-switch attacks.
- **Grace Period for Deadline Reductions:** Considered implementing a 7-day notice period before `end_date` reductions take effect, but deferred due to MVP timeline constraints.
- **Walrus Storage Extension:** Extending blob storage epochs without re-uploading content is not supported in MVP. All Walrus content edits require new blob uploads with updated `walrus_quilt_id` and `walrus_storage_epochs`.

## Summary
The contract must grow a dedicated edit surface that respects capability-based ownership, maintains immutable invariants, and cleanly separates Sui-only edits from Walrus-dependent metadata changes. Implementing the entry functions, validations, and events above enables the front-end edit page, keeps storage costs predictable, and provides auditable history for every change.
