#include <stdint.h>

#include "game_api.h"

#ifndef GAME_API_AI_H
#define GAME_API_AI_H

// Called by the game to query the Rust MCTS library
struct game_api_ai_callbacks {
	void (*init)(const uint8_t* game_state, size_t game_state_len);
	void (*expand_tree)(int count);
	size_t (*get_move)(const uint8_t *game_state, size_t game_state_len, uint8_t *move_out, size_t max_move_out_len);
	double (*get_move_score)(const uint8_t *move, size_t move_out_len);
	size_t (*move_node)(const uint8_t *game_state, size_t game_state_len, const uint8_t *move, size_t move_out_len);
};

// Passed as AiInitParamsCStruct to Rust.
struct ai_init_params {
    struct game_api_callbacks *callbacks;

	// Pointer to the MCTS Rust struct
	// TODO actually is this the Lua handle, which gets passed back to the callbacks to call the game functions like "get_possible_moves(state)"?
	void *ai_handle;

	// These functions are called by the Rust MCTS Library and are implemented by
	// the game.
	size_t (*get_possible_moves)(void *handle, uint8_t *state, size_t state_len,
	                             uint8_t *game_moves_out, size_t max_game_moves_out_len,
	                             size_t *game_moves_out_len);
	int32_t (*get_player_turn)(void *handle, uint8_t *game_state, size_t game_state_len);
	size_t (*apply_move)(void *handle, const uint8_t *state, size_t state_len, const uint8_t *move, size_t move_len);
	int32_t (*get_score)(void *handle, const uint8_t *state, size_t state_len, int32_t player);
};

#endif
