# Campaign Updates Implementation Guide

## Overview

This document outlines the complete implementation plan for the Campaign Updates feature, incorporating architectural discussions and best practices for Sui Move development.

## Background

Campaign updates allow campaign owners to post progress updates to their backers. Updates are separate from campaign edits - they represent a timeline of announcements, milestones, and communications rather than modifications to the campaign itself.

All update content (rich text descriptions, images) is stored in Walrus storage and referenced via metadata. The contract only stores references and metadata, not the content itself.

## Architecture Decision

### Storage Pattern: Immutable Update Objects Referenced via Dynamic Fields

**Decision:** Store each update as a separate frozen (immutable) object, with its ID referenced from the parent Campaign via dynamic fields.

**Important:** Frozen objects have no owner and are globally accessible. They are not "child objects" in the technical sense—the dynamic field (containing the ID reference) is owned by the campaign, but the update object itself is immutable and owner-less.

**Rationale:**
- **Gas Efficiency:** Campaign mutations (verification, status changes) don't load all updates
- **Scalability:** Unbounded growth doesn't inflate parent object size
- **Lazy Loading:** Frontends fetch updates on-demand
- **Immutability:** Frozen objects are cheapest to read and enforce append-only semantics
- **Storage Cost Locality:** Each update pays its own storage costs

**Alternatives Rejected:**
- ❌ Embedded `vector<CampaignUpdate>`: Poor scalability, expensive campaign mutations
- ❌ Shared objects: Unnecessary consensus overhead for immutable data
- ❌ Owned objects: Need public read access for indexers and frontends

## Schema Design

### New Structs

```move
// Separate frozen object for each update
public struct CampaignUpdate has key, store {
    id: UID,
    parent_id: ID,                    // Future-proof: will support Projects too
    sequence: u64,                    // Sequential ID for ordering
    author: address,                  // Who posted this update
    metadata: VecMap<String, String>, // All content references (all keys optional)
    created_at_ms: u64,              // Network timestamp in milliseconds (Unix-like, from sui::clock)
}

// Dynamic field key for storing update references
public struct UpdateKey has copy, drop, store {
    sequence: u64,
}

// Event emitted when update is added
public struct CampaignUpdateAdded has copy, drop {
    campaign_id: ID,
    update_id: ID,                    // ID of the new frozen update object
    sequence: u64,
    author: address,
    metadata: VecMap<String, String>, // Full metadata for indexer efficiency
    created_at_ms: u64,               // Network timestamp in milliseconds (Unix-like)
}
```

### Campaign Struct Changes

```move
public struct Campaign has key, store {
    // ... existing fields ...

    // REMOVE THIS FIELD (breaking change for testnet):
    // updates: vector<CampaignUpdate>,  ❌ DELETE

    // ADD THIS FIELD:
    next_update_seq: u64,  // Counter for sequential update IDs
}
```

## Design Decisions

### 1. Parent ID Abstraction

**Field Name:** `parent_id: ID` (not `campaign_id`)

**Rationale:**
- Future feature: "Projects" will also have updates with identical pattern
- Authorization flows through parent module (campaign.move), so type safety preserved
- Event names provide type context (`CampaignUpdateAdded` vs future `ProjectUpdateAdded`)
- Can add `parent_type: u8` later if needed (non-breaking change)

**Type Safety:** Each parent type maintains its own entry function and event type, providing clear boundaries.

### 2. Metadata-Only Updates

**No Title/Description Fields:** Unlike the current implementation, updates contain ONLY metadata.

**Rationale:**
- All rich content lives in Walrus storage
- Metadata contains `walrus_quilt_id` pointing to content bundle
- Maximum flexibility: different update types can use different metadata schemas
- Simpler contract logic: one generic data field vs. multiple specific fields

**Canonical Metadata Keys:**
- `walrus_quilt_id`: String-encoded u256 pointing to Walrus quilt bundle
- Other keys are application-defined and optional

### 3. Optional Metadata

**Allow Empty Metadata:** `VecMap::empty()` is a valid update

**Use Cases for Empty Updates:**
- Simple status signals: "Milestone reached"
- Temporal markers: "AMA happening now"
- Placeholder updates with metadata added off-chain

**Validation:** No minimum key requirements enforced by contract

### 4. Event Payload Richness

**Decision:** Include full `VecMap<String, String>` in event

**Rationale:**
- Indexers can cache Walrus references without fetching update objects
- Metadata is small (typically 2-5 keys, 100-500 bytes total)
- Events don't count toward object storage costs
- Events contribute to transaction size limits (~128 KB total per transaction), but our metadata is tiny
- Reduces round-trips for common queries

**Implementation Note:** Must clone metadata for event before moving it into update object (see implementation section).

### 5. Author Tracking

**Field:** `author: address` on every update

**Rationale:**
- Ownership may transfer (CampaignOwnerCap moved to new address)
- Historical attribution matters for accountability
- Future: multi-sig or delegated posting scenarios
- Audit trail for backers

**Value:** Track who posted what, not just who owns the campaign now

### 6. Timestamp Precision

**Use:** `clock::timestamp_ms(&clock)` (not `tx_context::epoch`)

**Rationale:**
- Consistency with existing edit functions (`campaign::update_campaign_basics`, etc.)
- Network timestamp in milliseconds (Unix-like in practice) for cross-platform compatibility
- Easier frontend date handling
- Better precision for sorting and filtering
- Note: `sui::clock` provides network time, not strictly guaranteed to be Unix epoch but treated as such in practice

### 7. Naming Convention

**Keep Campaign-Specific Names:** `CampaignUpdate`, `CampaignUpdateAdded`, etc.

**Rationale:**
- Different parent types may evolve different policies
- Clear module boundaries (campaign.move owns campaign updates)
- When Projects launch, copy pattern with adjustments
- Can refactor to shared module later if patterns converge
- Don't abstract until you have 2-3 concrete examples

### 8. Migration Strategy

**No Migration Code:** Clean removal of legacy `vector<CampaignUpdate>` field

**Rationale:**
- Testnet deployment - data doesn't matter
- Migration code would be dead weight in production
- Document breaking change with comment

**Documentation:**
```move
// BREAKING CHANGE (2025-01): Removed updates: vector<CampaignUpdate>
// Updates are now stored as separate frozen child objects via dynamic fields.
// See add_update() and get_update_id() for new access pattern.
```

## Implementation Details

### Verification Reset on Owner Edits

- `campaign::update_campaign_basics` and `campaign::update_campaign_metadata` emit `CampaignUnverified` when they mutate data while the campaign is verified. The `unverifier` address is the editing owner, and downstream indexers should treat the event plus `Campaign.is_verified` flag as canonical (the CrowdWalrus registry cache is only updated on explicit verify/unverify calls).
- `add_update` remains metadata-only and does **not** change verification; indexers can rely on the absence of `CampaignUnverified` during timeline updates.

### Parameter Lock Milestone

- `parameters_locked` flips to true on the first successful donation and emits `CampaignParametersLocked` once. Campaign economic parameters (start/end dates, funding goal, payout policy) stay immutable from creation; the flag exists as an indexer/UI signal rather than an enforcement gate today.

### Entry Function: `add_update`

```move
entry fun add_update(
    campaign: &mut Campaign,
    cap: &CampaignOwnerCap,
    metadata_keys: vector<String>,
    metadata_values: vector<String>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // 1. Authorization check
    assert!(cap.campaign_id == object::id(campaign), E_APP_NOT_AUTHORIZED);

    // 2. Validate key-value pairing
    assert!(
        vector::length(&metadata_keys) == vector::length(&metadata_values),
        E_KEY_VALUE_MISMATCH
    );

    // 3. Get sequential ID and compute timestamp once
    let sequence = campaign.next_update_seq;
    let now = clock::timestamp_ms(clock);  // Compute once, use everywhere

    // 4. Optional: Guard against overflow (unlikely but professional)
    // assert!(sequence < 18446744073709551615, E_MAX_UPDATES_REACHED);

    // 5. Build metadata for update object
    // Note: from_keys_values will ABORT if duplicate keys exist (EKeyAlreadyExists)
    let metadata = vec_map::from_keys_values(metadata_keys, metadata_values);

    // 6. Build metadata for event by extracting from the VecMap
    // VecMap doesn't have 'copy', so we extract keys/values and rebuild
    // String has 'copy' ability, so dereferencing (*key, *value) creates copies
    let mut event_keys = vector::empty<String>();
    let mut event_values = vector::empty<String>();
    let mut i = 0;
    let len = vec_map::size(&metadata);  // Use VecMap's size for consistency
    while (i < len) {
        let (key, value) = vec_map::get_entry_by_idx(&metadata, i);
        vector::push_back(&mut event_keys, *key);      // String is copied
        vector::push_back(&mut event_values, *value);  // String is copied
        i = i + 1;
    };
    let metadata_for_event = vec_map::from_keys_values(event_keys, event_values);

    // 7. Create update object with consistent timestamp
    let update = CampaignUpdate {
        id: object::new(ctx),
        parent_id: object::id(campaign),
        sequence,
        author: tx_context::sender(ctx),
        metadata,  // Original metadata moves here
        created_at_ms: now,  // Use precomputed timestamp
    };

    let update_id = object::id(&update);

    // 8. Store reference in dynamic field
    df::add(&mut campaign.id, UpdateKey { sequence }, update_id);

    // 9. Increment counter
    campaign.next_update_seq = sequence + 1;

    // 10. Emit event with cloned metadata and consistent timestamp
    event::emit(CampaignUpdateAdded {
        campaign_id: object::id(campaign),
        update_id,
        sequence,
        author: tx_context::sender(ctx),
        metadata: metadata_for_event,  // Use cloned version
        created_at_ms: now,  // Same timestamp as object
    });

    // 10. Freeze the update (immutable, public read access)
    transfer::freeze_object(update);
}
```

**Critical Implementation Note - Metadata Cloning:**

Move's ownership system prevents using a value after it's moved. Since `VecMap` does not have `copy` ability, we cannot simply use the same metadata in both the update object and the event.

❌ **Wrong approach:**
```move
let metadata = vec_map::from_keys_values(keys, values);
let update = CampaignUpdate { metadata, ... };  // metadata moved here
event::emit(CampaignUpdateAdded { metadata, ... });  // ❌ Error: use after move
```

❌ **Also wrong (vectors are consumed):**
```move
let metadata = vec_map::from_keys_values(keys, values);
let metadata_for_event = vec_map::from_keys_values(keys, values);  // ❌ keys/values already moved
```

✅ **Correct approach - Extract and rebuild:**
```move
// Build metadata once from input vectors
let metadata = vec_map::from_keys_values(metadata_keys, metadata_values);

// Extract keys/values by iterating through VecMap
// String has 'copy' ability, so dereferencing creates copies
let mut event_keys = vector::empty<String>();
let mut event_values = vector::empty<String>();
let mut i = 0;
let len = vec_map::size(&metadata);
while (i < len) {
    let (key, value) = vec_map::get_entry_by_idx(&metadata, i);
    vector::push_back(&mut event_keys, *key);      // String is copied
    vector::push_back(&mut event_values, *value);  // String is copied
    i = i + 1;
};

// Build second VecMap for event
let metadata_for_event = vec_map::from_keys_values(event_keys, event_values);

// Now we can use both
let update = CampaignUpdate { metadata, ... };
event::emit(CampaignUpdateAdded { metadata: metadata_for_event, ... });
```

**Cost:** One additional loop through metadata entries (typically 2-5 items), which is negligible compared to object creation and storage costs.

**Note on String copying:** The `String` type in Sui's stdlib has `copy, drop, store` abilities. When you dereference a borrowed String (`*key`), Move's compiler automatically creates a copy. This is why the pattern above works - no explicit `clone()` method is needed.

**Alternative simpler approach (if supported by your Sui version):**

Some Sui framework versions may not have `get_entry_by_idx()`. In that case, you can keep references to the original input vectors before they're consumed, or use the keys/values extraction pattern. The approach shown above using `get_entry_by_idx()` is confirmed to work with current Sui framework versions and matches the pattern used elsewhere in your codebase (see `update_campaign_metadata` in campaign.move).

### View Helper Functions

```move
/// Get total number of updates posted to this campaign
public fun update_count(campaign: &Campaign): u64 {
    campaign.next_update_seq
}

/// Get the object ID of an update by its sequence number
/// Aborts if update doesn't exist
public fun get_update_id(campaign: &Campaign, sequence: u64): ID {
    *df::borrow(&campaign.id, UpdateKey { sequence })
}

/// Check if an update exists at the given sequence number
public fun has_update(campaign: &Campaign, sequence: u64): bool {
    df::exists_(&campaign.id, UpdateKey { sequence })
}

/// Safe version that returns Option instead of aborting
public fun try_get_update_id(campaign: &Campaign, sequence: u64): Option<ID> {
    if (has_update(campaign, sequence)) {
        option::some(*df::borrow(&campaign.id, UpdateKey { sequence }))
    } else {
        option::none()
    }
}
```

### Initialization

When creating a new Campaign in `campaign::new()`:

```move
let campaign = Campaign {
    // ... existing fields ...
    next_update_seq: 0,  // Initialize counter
};
```

### Remove Legacy Code

**Delete these:**
```move
// From Campaign struct:
updates: vector<CampaignUpdate>,  // ❌ DELETE

// From view functions:
public fun updates(campaign: &Campaign): vector<CampaignUpdate> {
    campaign.updates
}  // ❌ DELETE ENTIRE FUNCTION
```

**Update this:**
```move
// In campaign::new()
updates: vector::empty(),  // ❌ DELETE THIS LINE
next_update_seq: 0,        // ✅ ADD THIS LINE
```

## Error Codes

Reuse existing error codes from campaign.move:
```move
const E_APP_NOT_AUTHORIZED: u64 = 1;    // Used for cap validation
const E_KEY_VALUE_MISMATCH: u64 = 4;    // Used for metadata validation
```

No new error codes required.

## Testing Requirements

### Unit Tests to Add

1. **Happy Path - Add Update with Metadata**
   - Create campaign
   - Add update with walrus_quilt_id
   - Verify sequence = 0
   - Verify update_count = 1
   - Verify event emitted with correct fields
   - Verify frozen object created

2. **Happy Path - Multiple Updates**
   - Add 3 updates sequentially
   - Verify sequences 0, 1, 2
   - Verify update_count = 3
   - Verify get_update_id works for all sequences

3. **Empty Metadata**
   - Add update with empty vectors
   - Verify it succeeds
   - Verify metadata is empty VecMap

4. **Authorization - Wrong Cap**
   - Try to add update with another campaign's cap
   - Verify aborts with E_APP_NOT_AUTHORIZED

5. **Key-Value Mismatch**
   - Try to add update with mismatched key/value lengths
   - Verify aborts with E_KEY_VALUE_MISMATCH

6. **Duplicate Keys**
   - Try to add update with duplicate keys: `["key1", "key1"]` / `["val1", "val2"]`
   - Verify aborts with `EKeyAlreadyExists` error from vec_map
   - Document this behavior for frontend developers

7. **Timestamp Consistency**
   - Add update and capture event
   - Verify update.created_at_ms == event.created_at_ms
   - Ensures single timestamp computation is working

8. **View Functions**
   - Test has_update for existing and non-existing sequences
   - Test try_get_update_id returns Some/None correctly
   - Test get_update_id aborts for non-existing sequence

9. **Event Validation**
   - Verify CampaignUpdateAdded contains:
     - Correct campaign_id
     - Correct update_id (matches frozen object)
     - Correct sequence
     - Correct author (matches tx sender)
     - Correct metadata (matches input)
     - timestamp_ms matches update object's timestamp

10. **Frozen Object Verification**
    - Verify update object is frozen (not shared, not owned)
    - Verify frozen object can be read
    - Verify frozen object cannot be mutated

11. **Author Tracking**
    - Create campaign as USER1
    - Transfer CampaignOwnerCap to USER2
    - Add update as USER2
    - Verify update.author = USER2 (not USER1)

### Integration Tests

1. **Full Campaign Lifecycle**
   - Create campaign
   - Add updates over time
   - Verify campaign updates, status changes
   - Query updates via dynamic fields

2. **Indexer Simulation**
   - Listen for CampaignUpdateAdded events
   - Build cache from event metadata only
   - Verify no object fetches needed for basic display

## Frontend Integration Notes

### Creating an Update

1. **Upload content to Walrus:**
   ```typescript
   const quiltId = await walrus.uploadQuilt({
     richTextContent: editorState,
     images: uploadedImages,
   });
   ```

2. **Submit transaction:**
   ```typescript
   await campaign.addUpdate({
     metadataKeys: ['walrus_quilt_id', 'update_type'],
     metadataValues: [quiltId, 'milestone'],
   });
   ```

### Querying Updates

1. **Get update count:**
   ```typescript
   const count = await campaign.updateCount();
   ```

2. **Get latest updates (from events):**
   ```typescript
   // Note: Sui RPC can only filter by MoveEventType, Sender, Package, Module, or TimeRange
   // You CANNOT filter by custom event fields like campaign_id directly
   const allEvents = await sui.queryEvents({
     query: { MoveEventType: `${PACKAGE_ID}::campaign::CampaignUpdateAdded` },
   });

   // Filter client-side for specific campaign
   const campaignEvents = allEvents.data.filter(
     e => e.parsedJson.campaign_id === campaignId
   );

   // Events contain full metadata - no object fetch needed!
   const updates = campaignEvents.map(e => ({
     updateId: e.parsedJson.update_id,
     sequence: e.parsedJson.sequence,
     author: e.parsedJson.author,
     walrusQuiltId: e.parsedJson.metadata.walrus_quilt_id,
     timestamp: e.parsedJson.created_at_ms,
   }));

   // For production: Use an indexer service for efficient campaign-specific queries
   // Indexers can filter by campaign_id without fetching all events
   ```

3. **Fetch update by sequence (using dynamic fields):**
   ```typescript
   // Recommended: Use RPC's native dynamic field support
   const updateField = await sui.getDynamicFieldObject({
     parentId: campaignId,
     name: {
       type: `${PACKAGE_ID}::campaign::UpdateKey`,
       value: { sequence: 0 }
     }
   });

   // The field's value is the update ID
   const updateId = updateField.data.content.fields.value;
   const update = await sui.getObject({ id: updateId });

   // Alternative: Call view function (less efficient)
   // const updateId = await campaign.getUpdateId(sequence);
   // const update = await sui.getObject({ id: updateId });
   ```

### Displaying Updates

```typescript
// From event cache:
const walrusContent = await walrus.fetchQuilt(
  update.metadata.walrus_quilt_id
);

// Render rich text editor with fetched content
renderEditor(walrusContent.richTextJson);
```

## Future Extensions

### Phase 2: Moderation (Redaction Registry)

If update moderation becomes necessary, implement without touching frozen updates:

```move
// Add to campaign module:
public struct RedactionNote has store, copy, drop {
    reason: String,
    redacted_at_ms: u64,
    redacted_by: address,
}

public struct RedactionKey has copy, drop, store {
    update_id: ID,
}

entry fun redact_update(
    campaign: &mut Campaign,
    cap: &CampaignOwnerCap,
    sequence: u64,
    reason: String,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let update_id = *df::borrow(&campaign.id, UpdateKey { sequence });

    df::add(
        &mut campaign.id,
        RedactionKey { update_id },
        RedactionNote {
            reason,
            redacted_at_ms: clock::timestamp_ms(clock),
            redacted_by: tx_context::sender(ctx),
        }
    );

    event::emit(CampaignUpdateRedacted {
        campaign_id: object::id(campaign),
        update_id,
        sequence,
        reason,
    });
}

// View function:
public fun is_redacted(campaign: &Campaign, update_id: ID): bool {
    df::exists_(&campaign.id, RedactionKey { update_id })
}
```

**Benefits:**
- Original frozen updates remain unchanged
- Full transparency: "this was redacted because..."
- Audit trail preserved
- Can be added later without migration

### Hard Deletion (Last Resort)

**Important Limitation:** Move contracts **cannot fetch objects by ID** from within contract code. There is no global `get_object_by_id()` function available on-chain.

If legal compliance requires deletion, it must be a **client-side operation**:

```typescript
// CLIENT-SIDE deletion workflow
async function deleteUpdate(campaignId, sequence, reason) {
  // 1. Fetch the update object first (client-side)
  const updateId = await getUpdateId(campaignId, sequence);
  const update = await sui.getObject({ id: updateId });
  const metadata = update.data.content.fields.metadata;

  // 2. Call delete function with metadata as input
  await campaign.deleteUpdate({
    sequence,
    reason,
    metadata,  // Pass metadata from client
  });
}
```

```move
// ON-CHAIN delete function (simplified - metadata passed in)
entry fun delete_update(
    campaign: &mut Campaign,
    cap: &AdminCap,
    sequence: u64,
    reason: String,
    original_metadata: VecMap<String, String>,  // Passed from client
    ctx: &TxContext,
) {
    let update_id = df::remove(&mut campaign.id, UpdateKey { sequence });

    // Emit tombstone event for off-chain preservation
    event::emit(CampaignUpdateDeleted {
        campaign_id: object::id(campaign),
        update_id,
        sequence,
        reason,
        deleted_by: tx_context::sender(ctx),
        metadata: original_metadata,  // From client, not fetched on-chain
    });

    // Note: Cannot delete frozen object - it remains on-chain but unlinkable
}
```

**Alternative:** Rely on indexers to preserve metadata from the original `CampaignUpdateAdded` event, and don't include it in the deletion event.

### Project Updates

When Projects feature launches:

1. Copy the update pattern to `project.move`
2. Create `ProjectUpdate` struct (same fields as CampaignUpdate)
3. Implement `project::add_update` with same logic
4. Emit `ProjectUpdateAdded` events
5. If patterns are identical after 6+ months, refactor to shared `updates.move` module

## References

### Related Files
- `sources/campaign.move` - Main implementation file
- `tests/campaign_tests.move` - Test suite
- `CONTRACT_EDIT_REQUIREMENTS.md` - Campaign editing specification
- `CLAUDE.md` - Project overview and architecture

### Sui Documentation
- [Dynamic Fields](https://docs.sui.io/concepts/dynamic-fields)
- [Object Ownership](https://docs.sui.io/concepts/object-ownership)
- [Events](https://docs.sui.io/concepts/events)

### Walrus Documentation
- [Walrus Quilt](https://docs.walrus.site) - Content bundling
- [Blob Storage](https://docs.walrus.site) - Storage epochs and pricing

## Implementation Checklist

- [ ] Update Campaign struct (remove updates vector, add next_update_seq)
- [ ] Define CampaignUpdate struct with key, store
- [ ] Define UpdateKey struct
- [ ] Define CampaignUpdateAdded event
- [ ] Implement add_update entry function
- [ ] Implement view helpers (update_count, get_update_id, has_update, try_get_update_id)
- [ ] Update campaign::new() to initialize next_update_seq
- [ ] Remove legacy updates vector getter function
- [ ] Add breaking change comment
- [ ] Write unit tests (11 test cases listed above)
- [ ] Write integration tests
- [ ] Run `sui move build` and fix any errors
- [ ] Run `sui move test` and verify all tests pass
- [ ] Update frontend documentation with new update flow
- [ ] Deploy to testnet and verify frozen objects work as expected

## Design Principles Applied

1. **Composition over Mutation** - Redaction registry overlays frozen data
2. **Pay for What You Use** - Each update pays its own storage costs
3. **Lazy Loading** - Frontends fetch updates on demand
4. **Event-Driven Architecture** - Rich events reduce RPC calls
5. **Fail Fast** - Authorization and validation happen upfront
6. **YAGNI** - Don't build moderation until needed
7. **Future-Proof** - parent_id and extensible metadata support evolution
8. **Transparency First** - Immutable updates build trust with backers

---

## Implementation Notes from Review

This document incorporates feedback from multiple technical reviews. Key corrections made:

### Critical Fixes Applied:

1. **Single Timestamp Computation** - Compute `clock::timestamp_ms(&clock)` once and reuse for both object and event to guarantee consistency

2. **Consistent Length Usage** - Use `vec_map::size(&metadata)` instead of mixing input vector length with VecMap size after potential deduplication

3. **RPC Event Filtering Reality** - Documented that Sui RPC cannot filter by custom event fields like `campaign_id`. Must filter by `MoveEventType` then filter client-side or use indexer.

4. **Move On-Chain Object Fetching Limitation** - Clarified that Move contracts cannot fetch objects by ID. Hard deletion must be client-side operation passing metadata as input.

5. **Dynamic Field RPC Access** - Added `getDynamicFieldObject` pattern as recommended approach over view functions

6. **Duplicate Keys Behavior** - Documented that `vec_map::from_keys_values` aborts with `EKeyAlreadyExists` if duplicate keys provided. Added test case.

7. **Overflow Guard** - Added commented overflow check for sequence (optional but professional)

### Verified Assumptions:

- ✅ `String` has `copy, drop, store` abilities - dereferencing creates copy
- ✅ `sui::object::ID` has `copy, drop, store` abilities - can be returned by value from view functions
- ✅ `vec_map::get_entry_by_idx()` exists in current Sui framework
- ✅ `vec_map::size()` is alias for `length()`
- ✅ Pattern matches existing usage in `update_campaign_metadata()`
- ✅ Returning `ID` by value from `df::borrow` is valid (used 30+ times in existing codebase)

### Terminology Clarifications:

- **Frozen/Immutable Objects:** Have no owner, globally accessible, cannot be mutated or transferred
- **Child Objects:** Objects stored via `dynamic_object_field::add` that are owned by the parent
- **Our Pattern:** We use frozen objects (no owner) + dynamic fields (storing ID references), not true child objects
- **Why This Matters:** The dynamic field is owned by the campaign, but the frozen update object itself is owner-less and globally readable

---

**Document Version:** 1.2
**Last Updated:** 2025-01-10
**Status:** Ready for Implementation (Post-Review, Terminology Corrected)
