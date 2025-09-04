module crowd_walrus::admin {
    use crowd_walrus::project;
    use std::string::String;
    use sui::{dynamic_field as df, event, table};

    // === Errors ===

    const E_NOT_AUTHORIZED: u64 = 1;

    // === Structs ===

    /// The admin object
    public struct Admin has key, store {
        id: UID,
        created_at: u64,
        projects: table::Table<String, ID>, // Subdomain to project ID
    }

    /// Capability for admin operations
    public struct AdminCap has key, store {
        id: UID,
        admin_id: ID,
    }

    /// Capability for validating admin operations
    public struct ValidateCap has key, store {
        id: UID,
        admin_id: ID,
    }

    // === Events ===

    public struct AdminCreated has copy, drop {
        admin_id: ID,
        creator: address,
    }

    // === Init Function ===

    /// Initialize the admin
    fun init(ctx: &mut TxContext) {
        let admin = Admin {
            id: object::new(ctx),
            created_at: tx_context::epoch(ctx),
            projects: table::new(ctx),
        };

        let admin_id = object::id(&admin);

        // Create admin capability for the creator
        let admin_cap = AdminCap {
            id: object::new(ctx),
            admin_id,
        };

        // Emit creation event
        event::emit(AdminCreated {
            admin_id,
            creator: tx_context::sender(ctx),
        });

        // Transfer capability to creator
        transfer::transfer(admin_cap, tx_context::sender(ctx));

        // Share admin object with creator
        transfer::share_object(admin)
    }

    // === Public Functions ===

    /// Register a new project
    public(package) fun create_project(
        admin: &mut Admin,
        name: String,
        description: String,
        subdomain_name: String,
        ctx: &mut TxContext,
    ): project::ProjectOwnerCap {
        let (project_id, project_owner_cap) = project::new(
            object::id(admin),
            name,
            description,
            subdomain_name,
            ctx,
        );
        table::add(&mut admin.projects, subdomain_name, project_id);
        project_owner_cap
    }

    // === Admin Functions ===
    /// Add dynamic field for extensibility
    public fun add_field<K: copy + drop + store, V: store>(
        admin: &mut Admin,
        cap: &AdminCap,
        key: K,
        value: V,
    ) {
        assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);

        df::add(&mut admin.id, key, value);
    }

    /// Remove dynamic field
    public fun remove_field<K: copy + drop + store, V: store>(
        admin: &mut Admin,
        cap: &AdminCap,
        key: K,
    ): V {
        assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);

        df::remove(&mut admin.id, key)
    }

    /// Create a validation capability for a new validator
    public fun create_validate_cap(
        admin: &Admin,
        cap: &AdminCap,
        new_validator: address,
        ctx: &mut TxContext,
    ) {
        assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);

        transfer::transfer(
            ValidateCap {
                id: object::new(ctx),
                admin_id: object::id(admin),
            },
            new_validator,
        )
    }

    // === View Functions ===

    /// Check if dynamic field exists
    public fun has_field<K: copy + drop + store>(admin: &Admin, key: K): bool {
        df::exists_(&admin.id, key)
    }

    /// Borrow dynamic field
    public fun borrow_field<K: copy + drop + store, V: store>(admin: &Admin, key: K): &V {
        df::borrow(&admin.id, key)
    }

    /// Borrow mutable dynamic field (requires admin cap)
    public fun borrow_field_mut<K: copy + drop + store, V: store>(
        admin: &mut Admin,
        cap: &AdminCap,
        key: K,
    ): &mut V {
        assert!(object::id(admin) == cap.admin_id, E_NOT_AUTHORIZED);

        df::borrow_mut(&mut admin.id, key)
    }

    // === Test Functions ===

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
