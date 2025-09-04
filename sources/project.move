module crowd_walrus::project {
    use std::string::String;

    public struct Project has key, store {
        id: UID,
        admin_id: ID,
        listed: bool,
        name: String,
        description: String,
        subdomain_name: String,
    }

    public struct ProjectOwnerCap has key, store {
        id: UID,
        project_id: ID,
    }

    public(package) fun new(
        admin_id: ID,
        name: String,
        description: String,
        subdomain_name: String,
        ctx: &mut TxContext,
    ): (ID, ProjectOwnerCap) {
        let project = Project {
            id: object::new(ctx),
            admin_id,
            listed: false,
            name,
            description,
            subdomain_name,
        };

        let project_id = object::id(&project);
        let project_owner_cap = ProjectOwnerCap {
            id: object::new(ctx),
            project_id,
        };

        transfer::share_object(project);
        (project_id, project_owner_cap)
    }

    public fun subdomain_name(project: &Project): String {
        project.subdomain_name
    }
}
