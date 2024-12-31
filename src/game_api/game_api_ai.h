
#if 0

// TODO do I really need to bother with a C layer? Why not go directly from Lua to Rust?
// I don't plan on implementing others with the same interface right now

// Called by the game
struct game_api_ai_callbacks {
	void (*init)(const uint8_t* game_state, size_t game_state_len);
	void (*expand_tree)(int count);
	size_t (*get_move)(const uint8_t *game_state, game_state_len, uint8_t *move_out, size_t max_move_out_len);
	double (*get_move_score)(const uint8_t *move, size_t move_out_len);
	size_t (*move_node)(const uint8_t *game_state, game_state_len, const uint8_t *move, size_t move_out_len);
};

struct rust_ai_init_params {
    struct game_api_callbacks *callbacks;
	void *ai_handle;
	size_t (*get_possible_moves)(void *handle, uint8_t *state, size_t state_len,
	                             uint8_t *game_moves_out, size_t max_game_moves_out_len,
	                             size_t *game_moves_out_len);
	int32_t (*get_player_turn)(void *handle, uint8_t *game_state, size_t game_state_len),
	apply_move: Option<unsafe extern "C" fn(*mut c_void, *const u8, usize, *const u8, usize)>,
	get_score: Option<unsafe extern "C" fn(*mut c_void, *const u8, usize) -> i32>,
}

#endif
