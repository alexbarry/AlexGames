#include<string.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "lua_api_utils.h"

#include "game_api_ai.h"
#include "mcts_rust_api.h"

static int lua_ai_init(lua_State *L);
static int lua_ai_destroy(lua_State *L);
static int lua_expand_tree(lua_State *L);
static int lua_get_move(lua_State *L);
static int lua_get_move_score(lua_State *L);
static int lua_move_node(lua_State *L);

/*
	void (*init)(const uint8_t* game_state, size_t game_state_len);
	void (*expand_tree)(int count);
	size_t (*get_move)(const uint8_t *game_state, game_state_len, uint8_t *move_out, size_t max_move_out_len);
	double (*get_move_score)(const uint8_t *move, size_t move_out_len);
	size_t (*move_node)(const uint8_t *game_state, game_state_len, const uint8_t *move, size_t move_out_len);

*/

static const struct luaL_Reg lua_alexgames_ai_api[] = {
	{"init",           lua_ai_init },
	{"destroy",        lua_ai_destroy },
	{"expand_tree",    lua_expand_tree },
	{"get_move",       lua_get_move },
	{"get_move_score", lua_get_move_score },
	{"move_node",      lua_move_node },
	{NULL, NULL},
};

static int luaopen_alexlib_ai(lua_State *L) {
	luaL_newlib(L, lua_alexgames_ai_api);
	return 1;
}

void init_alexgames_ai(lua_State *L, const char *name) {
	printf("Adding lua lib \"%s\"...\n", name);
	luaL_requiref(L, name, luaopen_alexlib_ai, 0);
}


// TODO maybe add a second mutex here? Or at least a log...
#define LUA_API_ENTER() \
	do { } while (0)

#define LUA_API_EXIT() \
	do { } while (0)

static size_t lua_get_possible_moves(void *L, uint8_t *state, size_t state_len,
	                              uint8_t *game_moves_out, size_t max_game_moves_out_len,
	                              size_t *game_moves_out_len) {
	printf("%s: %s\n", __FILE__, __func__);
	// TODO call Lua global for now, maybe register a function from lua_ai_init in the future

	//lua_checkstack_or_return_val(L, 2, 0);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return_val(L, "get_possible_moves", LUA_TFUNCTION, 0);
	lua_pushlstring(L, (char *)state, state_len);

	// Should be returning a list of strings
	pcall_handle_error(L, 1, 1);

	size_t num_moves = lua_rawlen(L, -1);
	printf("Read length %d\n", num_moves);
	int i;
	int data_len = 0;
	*game_moves_out_len = 0;
	for (i=1; i<=num_moves; i++) {
		lua_rawgeti(L, -1, i);
		size_t len = 0;
		// TODO this data is getting copied a ton of times after this,
		// maybe change the Rust API to accept an array of pointers instead.
		const uint8_t *data = (const uint8_t *)lua_tolstring(L, -1, &len);
		if (i == 1) {
			data_len = len;
			*game_moves_out_len = len;
			if (data_len*num_moves > max_game_moves_out_len) {
				luaL_error(L, "%s: first elem len is %d, %d elems, caller's game_moves_out buffer is only %d bytes long",
				              __func__, data_len, num_moves, max_game_moves_out_len);
				break;
			}
		} else if (data_len != len) {
			luaL_error(L, "%s: move index %d from Lua game is length %d, but first element "
			              "is len %d. Must all be the same length for now.",
			              __func__, i, len, data_len);
			break;
		}

		memcpy(game_moves_out, data, len);
		game_moves_out += len;

		// pop the move
		lua_pop(L, 1);
	}
	// pop the list of moves
	lua_pop(L, 1);

	lua_pop_error_handler(L);

	printf("%s: done, returning %d\n", __func__, data_len * num_moves);
	return data_len * num_moves;
}

int32_t lua_get_player_turn(void *L, uint8_t *game_state, size_t game_state_len) {
	printf("%s: %s\n", __FILE__, __func__);
	return 1;
}

size_t lua_apply_move(void *L, const uint8_t *state, size_t state_len, const uint8_t *move, size_t move_len) {
	printf("%s: %s\n", __FILE__, __func__);
	return 0;
}

int32_t lua_get_score(void *L, const uint8_t *state, size_t state_len, int32_t player) {
	printf("%s: %s\n", __FILE__, __func__);
	return 0;
}


static bool read_bytearray(lua_State *L, int idx, const uint8_t **ary_out, size_t *ary_out_len, const char *caller_func_name) {
	if (!lua_isstring(L, idx)) {
		luaL_error(L, "%s: read_bytearray param idx %d is not a string", caller_func_name, idx);
		return false;
	}

	*ary_out = (const uint8_t *)lua_tolstring(L, idx, ary_out_len);
	return true;
}


static int lua_ai_init(lua_State *L) {
	printf("%s: lua_ai_init called\n", __FILE__);


	const uint8_t *state;
	size_t state_len = 0;
	if (!read_bytearray(L, 1, &state, &state_len, __func__)) {
		return 0;
	}

	//printf("lua_ai_init called with state=\"%.*s\" asdf\n", (int)state_len, state);
	const struct ai_init_params params = {
		// TODO
		.callbacks = NULL,

		// TODO rename
		.ai_handle = L,

		// TODO in the future, perhaps receive function references from Lua rather than
		// just getting global functions that have a hardcoded name.
		.get_possible_moves = lua_get_possible_moves,
		.get_player_turn = lua_get_player_turn,
		.apply_move = lua_apply_move,
		.get_score = lua_get_score,
	};

	void *handle = rust_game_api_ai_init(&params, state, state_len);

	lua_pushlightuserdata(L, handle);
	return 1;
}
static int lua_ai_destroy(lua_State *L) {
	// TODO
	return 0;
}
static int lua_expand_tree(lua_State *L) {
	printf("%s: %s\n", __FILE__, __func__);
	// TODO
	return 0;
}
static int lua_get_move(lua_State *L) {
	printf("%s: %s\n", __FILE__, __func__);
	// TODO
	return 0;
}
static int lua_get_move_score(lua_State *L) {
	printf("%s: %s\n", __FILE__, __func__);
	// TODO
	return 0;
}
static int lua_move_node(lua_State *L) {
	printf("%s: %s\n", __FILE__, __func__);
	// TODO
	return 0;
}
