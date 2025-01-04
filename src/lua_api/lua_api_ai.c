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

// TODO remove all this, we are inside a Lua game when any of this is called,
// so there is already an error handler pushed, assuming lua_api.c did its job.
// So don't push another one... I think?
const bool push_err_handler = true;

static const struct luaL_Reg lua_alexgames_ai_api[] = {
	{"init",           lua_ai_init },
	{"destroy",        lua_ai_destroy },
	{"expand_tree",    lua_expand_tree },
	{"get_move",       lua_get_move },
	{"get_move_score", lua_get_move_score },
	{"move_node",      lua_move_node },
	{NULL, NULL},
};

static uint8_t move_out_buff[256];

static int luaopen_alexlib_ai(lua_State *L) {
	luaL_newlib(L, lua_alexgames_ai_api);
	return 1;
}

void init_alexgames_ai(lua_State *L, const char *name) {
	printf("Adding lua lib \"%s\"...\n", name);
	luaL_requiref(L, name, luaopen_alexlib_ai, 0);
}

static bool read_bytearray(lua_State *L, int idx, const uint8_t **ary_out, size_t *ary_out_len, const char *caller_func_name) {
	printf("%s: entering from %s\n", __func__, caller_func_name);
	if (!lua_isstring(L, idx)) {
		printf("%s: param is not string, is %d\n", caller_func_name, lua_type(L, idx));
		alex_log_err_user_visible(api, "%s: read_bytearray param idx %d is not a string", caller_func_name, idx);
		return false;
	}

	*ary_out = (const uint8_t *)lua_tolstring(L, idx, ary_out_len);
	return true;
}




// TODO maybe add a second mutex here? Or at least a log...
#define LUA_API_ENTER() \
	if (lua_gettop(L) != 0) { \
		alex_log("%s: %d items on stack before starting!\n", __func__, lua_gettop(L)); \
	} \


#define LUA_API_EXIT() \
	if (lua_gettop(L) > 0) {                                                               \
		alex_log("%s: %d items left on stack after completion!\n", __func__, lua_gettop(L)); \
	}                                                                                      \


static size_t lua_get_possible_moves(void *L, uint8_t *state, size_t state_len,
	                              uint8_t *game_moves_out, size_t max_game_moves_out_len,
	                              size_t *game_moves_out_len) {
	size_t val_to_return = 0;
	size_t num_moves = 0;
#if 0
	//return 0; // TODO REMOVE
	static bool returned_fake_data = false;

	if (!returned_fake_data) {
	game_moves_out[0] = 10;
	game_moves_out[1] = 20;
	game_moves_out[2] = 30;
	game_moves_out[3] = 40;
	*game_moves_out_len = 1;
	returned_fake_data = true;
	return 4;
	} else {
		return 0;
	}
#endif
	printf("%s: %s\n", __FILE__, __func__);
	LUA_API_ENTER();
	// TODO call Lua global for now, maybe register a function from lua_ai_init in the future

	//lua_checkstack_or_return_val(L, 2, 0);
	lua_checkstack_or_return_val(L, 2, 0);
	int lua_err_handler_index = 0;
	if (push_err_handler) {
		lua_push_error_handler(L);
		lua_err_handler_index = lua_gettop(L);
	}
	lua_getglobal_checktype_or_return_val(L, "get_possible_moves", LUA_TFUNCTION, 0);
	lua_pushlstring(L, (char *)state, state_len);

	// Should be returning a list of strings
	//int rc = pcall_handle_error(L, 1, 1);
	// TODO TODO all I need to do to fix the confusing errors is to
	// add a parameter to point to the lua error handler index. In my previous Lua APIs, it was
	// always at the beginning, but now it isn't because of the ai init state param
	int rc = lua_pcall(L, 1, 1, lua_err_handler_index);
	printf("%s: pcall returned %d\n", __func__, rc);
	if (rc) {
		handle_lua_err(L);
		val_to_return = -1;
		goto err;
	}

	if (lua_type(L, -1) != LUA_TTABLE) {
		alex_log_err_user_visible(api, "%s: expected get_possible_moves to return a table, instead got type %d\n", __func__, lua_type(L, -1));
		return -1;
	}

	num_moves = lua_rawlen(L, -1);
	//printf("Read length %d\n", num_moves);
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
				alex_log_err_user_visible(api, "%s: first elem len is %d, %d elems, caller's game_moves_out buffer is only %d bytes long",
				                          __func__, data_len, num_moves, max_game_moves_out_len);
				break;
			}
		} else if (data_len != len) {
			alex_log_err_user_visible(api, "%s: move index %d from Lua game is length %d, but first element "
			              "is len %d. Must all be the same length for now.",
			              __func__, i, len, data_len);
			break;
		}

		memcpy(game_moves_out, data, len);
		game_moves_out += len;

		// pop the move
		lua_pop(L, 1);
	}
	val_to_return = data_len * num_moves;

	// pop the list of moves
	lua_pop(L, 1);

	// pop the state string/bytearray that was passed as a parameter
	//lua_pop(L, 1);

	err:
	printf("%s:%d\n", __FILE__, __LINE__);
	dump_lua_stack(L);
	if (push_err_handler) lua_pop_error_handler(L);

	if (lua_gettop(L) != 0) {
		alex_log_err_user_visible(api, "Expected top to be 0, was %d\n", lua_gettop(L));
	}

	//printf("%s: done, returning %zu, top=%d\n", __func__, data_len * num_moves, lua_gettop(L));
	LUA_API_EXIT();
	return val_to_return;
}

int32_t lua_get_player_turn(void *L, uint8_t *game_state, size_t game_state_len) {
	//return 0; // TODO REMOVE
	printf("%s: %s\n", __FILE__, __func__);
	LUA_API_ENTER();
	int player_turn = -1;

	int lua_err_handler_index = 0;
	if (push_err_handler) {
		lua_push_error_handler(L);
		lua_err_handler_index = lua_gettop(L);
	}
	lua_getglobal_checktype_or_return_val(L, "get_player_turn", LUA_TFUNCTION, 0);
	lua_pushlstring(L, (char *)game_state, game_state_len);

	//pcall_handle_error(L, 1, 1);
	int rc = lua_pcall(L, 1, 1, lua_err_handler_index);
	if (rc) {
		handle_lua_err(L);
		goto err;
	}

	int is_int = 0;
	player_turn = lua_tointegerx(L, -1, &is_int);
	lua_pop(L, 1);

	if (!is_int) {
		alex_log_err_user_visible(api, "%s: expected get_player_turn to return an integer, did not");
		goto err;
	}

	err:
	if (push_err_handler) lua_pop_error_handler(L);
	LUA_API_EXIT();
	printf("%s: returning player turn %d to Rust, top=%d\n", __func__, player_turn, lua_gettop(L));
	return player_turn;
}

size_t lua_apply_move(void *L, const uint8_t *state, size_t state_len, const uint8_t *move, size_t move_len, uint8_t *state_out, size_t max_state_out_len) {
	printf("[ai] C API apply_move called\n");
	printf("%s: %s\n", __FILE__, __func__);
	size_t state_out_len = 0;
	LUA_API_ENTER();

	lua_checkstack_or_return_val(L, 3, 0);

	int lua_err_handler_index = 0;
	if (push_err_handler) {
		lua_push_error_handler(L);
		lua_err_handler_index = lua_gettop(L);
	}
	lua_getglobal_checktype_or_return_val(L, "apply_move", LUA_TFUNCTION, 0);
	lua_pushlstring(L, (char *)state, state_len);
	lua_pushlstring(L, (char *)move, move_len);

	printf("%s: calling pcall...\n", __func__);
	//pcall_handle_error(L, 2, 1);
	int rc = lua_pcall(L, 2, 1, lua_err_handler_index);
	if (rc) {
		handle_lua_err(L);
		state_out_len = -1;
		goto err;
	}
	printf("%s: finished calling pcall\n", __func__);
	const uint8_t *state_out_lua;
	if (!read_bytearray(L, -1, &state_out_lua, &state_out_len, __func__)) {
		printf("%s: failed to read bytearray\n", __func__);
		return 0;
	}
	printf("%s: successfully read bytearray\n", __func__);

	if (state_out_len >= max_state_out_len) {
		alex_log_err_user_visible(api, "%s: received state len %d from Lua, buff size is only %d\n", __func__, state_out_len, max_state_out_len);
		state_out_len = -1;
		return 0;
	}


	printf("[ai verbose] C lua_apply_move read state (%d bytes) %.*s\n", state_out_len, state_out_len, state_out_lua);
	memcpy(state_out, state_out_lua, state_out_len);
	lua_pop(L, 1);
	printf("[ai verbose] %s:%d\n", __FILE__, __LINE__);
	err:
	printf("[ai verbose] %s:%d\n", __FILE__, __LINE__);
	if (push_err_handler) lua_pop_error_handler(L);
	printf("[ai verbose] %s:%d\n", __FILE__, __LINE__);
	printf("%s: done %s\n", __FILE__, __func__);
	LUA_API_EXIT();
	printf("%s: finished\n", __func__);
	printf("[ai verbose] %s:%d\n", __FILE__, __LINE__);
	printf("[ai verbose] C lua_apply_move returning %d\n", state_out_len);
	return state_out_len;
}

int32_t lua_get_score(void *L, const uint8_t *state, size_t state_len, int32_t player) {
	printf("[ai] C API get_score called\n");
	printf("%s: %s\n", __FILE__, __func__);
	LUA_API_ENTER();
	int lua_err_handler_index = 0;
	if (push_err_handler) {
		lua_push_error_handler(L);
		lua_err_handler_index = lua_gettop(L);
	}
	lua_getglobal_checktype_or_return_val(L, "get_score", LUA_TFUNCTION, 0);
	lua_pushlstring(L, (char *)state, state_len);
	lua_pushinteger(L, player);

	//pcall_handle_error(L, 2, 1);
	int rc = lua_pcall(L, 2, 1, lua_err_handler_index);
	if (rc) {
		handle_lua_err(L);
		goto err;
	}


	int score = lua_tointeger(L, -1);
	lua_pop(L, 1);
	err:
	if (push_err_handler) lua_pop_error_handler(L);

	
	LUA_API_EXIT();
	return 0;
}


static int lua_ai_init(lua_State *L) {
	printf("%s: lua_ai_init called\n", __FILE__);
	LUA_API_ENTER();

	if (lua_gettop(L) != 1) {
		alex_log_err_user_visible(api, "%s start: Expected top to be 1, was %d\n", __func__, lua_gettop(L));
	}


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
	lua_pop(L, 1); // pop bytearray (string)

	//lua_settop(L, 0);
	lua_pushlightuserdata(L, handle);

	if (lua_gettop(L) != 0) {
		alex_log_err_user_visible(api, "%s end Expected top to be 0, was %d\n", __func__, lua_gettop(L));
	}
	LUA_API_EXIT();
	printf("[ai] lua_ai_init finished\n");
	return 1;
}
static int lua_ai_destroy(lua_State *L) {
	// TODO
	return 0;
}
static int lua_expand_tree(lua_State *L) {
	//printf("%s: %s\n", __FILE__, __func__);

	void *ai_handle = lua_touserdata(L, 1);
	int count = lua_tonumber(L, 2);

	//printf("Expanding tree %d times\n", count);

	rust_game_api_ai_expand_tree(ai_handle, count);

	return 0;
}
static int lua_get_move(lua_State *L) {
	printf("%s: %s\n", __FILE__, __func__);

	void *ai_handle = lua_touserdata(L, 1);
	size_t state_len = 0;
	const uint8_t *state = (const uint8_t *)lua_tolstring(L, 2, &state_len);

	size_t move_out_len = rust_game_api_ai_get_move(ai_handle,
	                                                state, state_len,
	                                                move_out_buff, sizeof(move_out_buff));

	if (move_out_len <= 0) {
		return 0;
	}

	lua_pushlstring(L, (char*)move_out_buff, (int)move_out_len);
	return 1;
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
