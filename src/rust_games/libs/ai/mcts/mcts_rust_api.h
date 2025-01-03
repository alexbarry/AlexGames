#include <stdint.h>

#include "game_api_ai.h"

// These functions are defined in mcts_rust_api.rs

void* rust_game_api_ai_init(const struct ai_init_params *params,
                            const uint8_t *state,
                            size_t state_len);
void rust_game_api_ai_destroy(void *handle);


void rust_game_api_ai_expand_tree(void *handle, int32_t count);
size_t rust_game_api_ai_get_move(void *handle,
                                 const uint8_t *state, size_t state_len,
                                 uint8_t *move_out, size_t max_move_out_len);
double rust_game_api_ai_get_move_score(void *handle,
                                       const uint8_t *game_move, size_t game_move_len);
void rust_game_api_ai_move_node(void *handle,
                                const uint8_t *state, size_t state_len,
                                const uint8_t *move, size_t move_len);
