#include<stdbool.h>
#include<stdint.h>
#include<stddef.h>
#include<stdarg.h>

#ifndef LUA_API_H_
#define LUA_API_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "game_api.h"

#define UPLOADED_GAME_MAIN_FILE "game.lua"

extern const struct game_api lua_game_api;
void *start_lua_game(const struct game_api_callbacks *api_callbacks, const char *game_path);

// TODO maybe remove this one?
void *init_lua_game(const struct game_api_callbacks *api_callbacks_arg,
                    const char *lua_fpath);
void destroy_lua_game(void *L);

const char *get_lua_game_path(const char *game_id, size_t game_id_len);


#ifdef __cplusplus
}
#endif


#endif /* LUA_API_H_ */
