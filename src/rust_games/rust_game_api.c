#include<string.h>
#include<stdint.h>

#include "rust_game_api.h"

extern void rust_game_api_handle_user_clicked(void *L, int pos_y, int pos_x);
extern void rust_game_api_start_game(void *L, int session_id, const uint8_t *state, size_t state_len);
extern void rust_game_api_update(void *L, int dt_ms);
extern size_t rust_game_api_get_state(void *L, uint8_t *state_out, size_t state_out_max_len);
extern void rust_game_api_handle_btn_clicked(void *L, const char *btn_id);
extern void rust_game_api_destroy_game(void *L);
extern void rust_game_api_handle_mousemove(void *L, int pos_y, int pos_x, int buttons);
extern void rust_game_api_handle_mouse_evt(void *L, int evt_id, int pos_y, int pos_x, int buttons);
extern void rust_game_api_handle_touch_evt(void *L, 
                                           const char *evt_id_str, int evt_id_str_len, 
                                           void *changed_touches, int changed_touches_len);
extern void rust_game_api_handle_popup_btn_clicked(void *L,
                                                   const char *popup_id, int btn_idx,
                                                   const struct popup_state *popup_state);


// This one is defined in rust
extern void *start_rust_game_rust(const char *game_str, size_t game_str_len, const struct game_api_callbacks *callbacks);

// TODO return a C structure that points to C wrapper functions that
// call all the Rust bindings
void *start_rust_game(const char *game_str, size_t game_str_len, const struct game_api_callbacks *callbacks) {
	void *handle = start_rust_game_rust(game_str, game_str_len, callbacks);
	printf("%s returned %p\n", __func__, handle);
	return handle;
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
	rust_api.handle_btn_clicked  = rust_game_api_handle_btn_clicked;
	rust_api.get_state           = rust_game_api_get_state;
	rust_api.destroy_game        = rust_game_api_destroy_game;
	rust_api.handle_mousemove    = rust_game_api_handle_mousemove;
	rust_api.handle_mouse_evt    = rust_game_api_handle_mouse_evt;
	rust_api.handle_touch_evt    = rust_game_api_handle_touch_evt;
	rust_api.handle_popup_btn_clicked = rust_game_api_handle_popup_btn_clicked;
	return &rust_api;
}
