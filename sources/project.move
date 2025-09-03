module crowd_walrus_move::project {

    use std::string::String;

    public struct Project {
        id: ID,
        name: String,
        description: String,
    }
}
