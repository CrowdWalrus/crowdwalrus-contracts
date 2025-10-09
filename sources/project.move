module crowd_walrus::project;

use std::string::String;
use sui::clock::Clock;

public struct Project has key, store {
    id: sui::object::UID,
    admin_id: sui::object::ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    created_at_ms: u64, // Unix timestamp in milliseconds (UTC) recorded at creation
}

public struct ProjectOwnerCap has key, store {
    id: sui::object::UID,
    project_id: sui::object::ID,
}

public(package) fun new(
    admin_id: sui::object::ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    clock: &Clock,
    ctx: &mut sui::tx_context::TxContext,
): (sui::object::ID, ProjectOwnerCap) {
    let project = Project {
        id: sui::object::new(ctx),
        admin_id,
        name,
        short_description,
        subdomain_name,
        created_at_ms: sui::clock::timestamp_ms(clock),
    };

    let project_id = sui::object::id(&project);
    let project_owner_cap = ProjectOwnerCap {
        id: sui::object::new(ctx),
        project_id,
    };

    sui::transfer::share_object(project);
    (project_id, project_owner_cap)
}

public fun subdomain_name(project: &Project): String {
    project.subdomain_name
}

public fun project_id(project_owner_cap: &ProjectOwnerCap): sui::object::ID {
    project_owner_cap.project_id
}
