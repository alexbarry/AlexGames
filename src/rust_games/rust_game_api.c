#include<string.h>
#include<stdint.h>

#include "rust_game_api.h"

extern void rust_game_api_handle_user_clicked(void *L, int pos_y, int pos_x);
extern void rust_game_api_start_game(void *L, int session_id, const uint8_t *state, size_t state_len);
extern void rust_game_api_update(void *L, int dt_ms);


// This one is defined in rust
extern void *start_rust_game_rust(const char *game_str, size_t game_str_len, const struct game_api_callbacks *callbacks);

// TODO return a C structure that points to C wrapper functions that
// call all the Rust bindings
void *start_rust_game(const char *game_str, size_t game_str_len, const struct game_api_callbacks *callbacks) {
	return start_rust_game_rust(game_str, game_str_len, callbacks);
}

#if 0
static void c_rust_handle_user_clicked(void *L, int pos_y, int pos_x) {
	
}
#endif

const struct game_api * get_rust_api(void) {
	static struct game_api rust_api;
	memset(&rust_api, 0, sizeof(rust_api));
	rust_api.handle_user_clicked = rust_game_api_handle_user_clicked;
	rust_api.start_game          = rust_game_api_start_game;
	rust_api.update              = rust_game_api_update;
	return &rust_api;
}
