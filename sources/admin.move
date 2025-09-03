module crowd_walrus_move::admin {

    use std::string::String;
    use sui::object::ID;

    public struct Admin {
        id: ID,
        name: String,
    }
}
