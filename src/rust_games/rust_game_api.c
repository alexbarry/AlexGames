#include "rust_game_api.h"


// This one is defined in rust
extern void *start_rust_game_rust(const char *game_str, size_t game_str_len, const struct game_api_callbacks *callbacks);

// TODO return a C structure that points to C wrapper functions that
// call all the Rust bindings
void *start_rust_game(const char *game_str, size_t game_str_len, const struct game_api_callbacks *callbacks) {
	return start_rust_game_rust(game_str, game_str_len, callbacks);
}

