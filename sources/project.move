module crowd_walrus_move::project {
    use std::string::String;

    public struct Project has key, store {
        id: UID,
        name: String,
        description: String,
    }

    public struct ProjectOwnerCap has key, store {
        id: UID,
        project_id: ID,
    }

    public fun create_project(
        name: String,
        description: String,
        ctx: &mut TxContext,
    ): ProjectOwnerCap {
        let project = Project {
            id: object::new(ctx),
            name,
            description,
        };

        let project_owner_cap = ProjectOwnerCap {
            id: object::new(ctx),
            project_id: object::id(&project),
        };

        transfer::share_object(project);

        project_owner_cap
    }
}
