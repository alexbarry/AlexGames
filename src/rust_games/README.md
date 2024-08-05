## AlexGames Rust games

See [gem match](gem_match) and [reversi](reversi) for an example of how to implement a game.

Your game should implement `AlexGamesApi` (defined in [`rust_game_api.rs`](rust_game_api.rs)), and it can call the `*const CCallbacksPtr` it is passed to draw on the game canvas, initialize UI elements, send multiplayer messages, etc.

When adding a new game, two changes need to be made to [`rust_game_handler.rs`](rust_game_handler.rs):
* `get_rust_game_init_func`: need to match the `game_id` (string, e.g. `"reversi"` or `"gem_match`) to your game's implementation of `pub fn init(callbacks: *const rust_game_api::CCallbacksPtr) -> Box<dyn AlexGamesApi>`.
* `handle_void_ptr_to_trait_ref`: need to match the `game_id` string to the right cast of the `*mut AlexGamesHandle` field `api` to your game struct, which should implement the `AlexGamesApi` trait.

The `handle_void_ptr_to_trait_ref` step for each game could maybe be removed in the future by passing a struct of function pointers to C instead, or something like that. I think in C++ each object's vtable is referenced in a generic place on the object, but in Rust it seems to work differently, and you need to cast to your struct first before you can call the struct functions, even if all the structs implement the `AlexGamesApi` trait.
