module crowd_walrus::project;

use std::string::String;

public struct Project has key, store {
    id: UID,
    admin_id: ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    created_at: u64,
}

public struct ProjectOwnerCap has key, store {
    id: UID,
    project_id: ID,
}

public(package) fun new(
    admin_id: ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    ctx: &mut TxContext,
): (ID, ProjectOwnerCap) {
    let project = Project {
        id: object::new(ctx),
        admin_id,
        name,
        short_description,
        subdomain_name,
        created_at: tx_context::epoch(ctx),
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

public fun project_id(project_owner_cap: &ProjectOwnerCap): ID {
    project_owner_cap.project_id
}
