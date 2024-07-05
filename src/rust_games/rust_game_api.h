#ifndef RUST_GAME_API_H_
#define RUST_GAME_API_H_

#include "game_api.h"

#ifdef __cplusplus
extern "C" {
#endif

bool rust_game_supported(const char *game_str, size_t game_str_len);

void *start_rust_game(const char *game_str, size_t game_str_len, const struct game_api_callbacks *callbacks);

#ifdef __cplusplus
}
#endif


#endif /* ifndef GAME_API_H_ */
