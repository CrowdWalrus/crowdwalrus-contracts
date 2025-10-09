module crowd_walrus::project;

use std::string::String;
use sui::clock::{Self as clock, Clock};

public struct Project has key, store {
    id: object::UID,
    admin_id: object::ID,
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
    admin_id: ID,
    name: String,
    short_description: String,
    subdomain_name: String,
    clock: &Clock,
    ctx: &mut tx_context::TxContext,
): (object::ID, ProjectOwnerCap) {
    let project = Project {
        id: object::new(ctx),
        admin_id,
        name,
        short_description,
        subdomain_name,
        created_at_ms: clock::timestamp_ms(clock),
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

public fun project_id(project_owner_cap: &ProjectOwnerCap): object::ID {
    project_owner_cap.project_id
}
