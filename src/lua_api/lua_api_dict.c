#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "lua_api_utils.h"

#include "game_api.h"
#include "game_api_words.h"

static int lua_dict_ready(lua_State *L);
static int lua_dict_init(lua_State *L);
static int lua_dict_is_valid_word(lua_State *L);
static int lua_dict_get_word_freq(lua_State *L);
static int lua_dict_get_random_word(lua_State *L);
static int lua_dict_get_words_made_from_letters(lua_State *L);


static const struct game_dict_api *g_dict_api = NULL;
static void *g_dict_handle = NULL;

static const struct luaL_Reg lua_dict_c_api[] = {
	{"is_ready",                    lua_dict_ready},
	{"init",                        lua_dict_init},
	{"is_valid_word",               lua_dict_is_valid_word},
	{"get_word_freq",               lua_dict_get_word_freq},
	{"get_random_word",             lua_dict_get_random_word},
	{"get_words_made_from_letters", lua_dict_get_words_made_from_letters},

	{NULL, NULL},
};

static int luaopen_alexlib_dict(lua_State *L) {
	luaL_newlib(L, lua_dict_c_api);
	return 1;
}

void init_lua_alex_dict(void *L, const char *name, const struct game_dict_api *api) {
	alex_log("%s\n", __func__);
	g_dict_api = api;
	luaL_requiref(L, name, luaopen_alexlib_dict, 0);
}


static int lua_dict_ready(lua_State *L) {
	bool is_ready = g_dict_api->is_ready();
	lua_pushboolean(L, is_ready);
	return 1;
}

static int lua_dict_init(lua_State *L) {
	size_t language_str_len = 0;
	const char *language = lua_tolstring(L, 1, &language_str_len);

	g_dict_handle = g_dict_api->init(language);

	return 0;
}

static int lua_dict_is_valid_word(lua_State *L) {
	size_t word_str_len = 0;
	const char *word = lua_tolstring(L, 1, &word_str_len);

	bool is_valid_word = g_dict_api->is_valid_word(g_dict_handle, word);

	lua_pushboolean(L, is_valid_word);
	return 1;
}

static int lua_dict_get_word_freq(lua_State *L) {
	size_t word_str_len = 0;
	const char *word = lua_tolstring(L, 1, &word_str_len);

	word_freq_t word_freq = g_dict_api->get_word_freq(g_dict_handle, word);

	lua_pushnumber(L, word_freq);
	return 1;
}

//	int (*get_random_word)(void *dict_handle,
//	                       const struct word_query_params *params,
//	                       char *word_out, size_t max_word_out_len,
//	                       int *possib_word_count_out);

static int lua_dict_get_random_word(lua_State *L) {
	struct word_query_params params = get_default_params();

	//size_t letters_str_len = 0;
	//const char *letters = lua_tolstring(L, 1, &letters_str_len);

	// TODO move this into a helper function, need to reuse it for 
	// the other function

	int param_idx = 1;

	if (lua_isnone(L, param_idx) || lua_isnil(L, param_idx)) {
		// do nothing, use default params
	} else if (lua_istable(L, param_idx)) {
		{
			int field_type = lua_getfield(L, param_idx, "min_length");
			if (field_type != LUA_TNIL) {
				lua_Integer val = lua_get_int_or_float(L, -1, "min_length");
				params.min_length = val;
			}
			lua_pop(L, 1);
		}

		{
			int field_type = lua_getfield(L, param_idx, "max_length");
			if (field_type != LUA_TNIL) {
				lua_Integer val = lua_get_int_or_float(L, -1, "max_length");
				params.max_length = val;
			}
			lua_pop(L, 1);
		}

		{
			int field_type = lua_getfield(L, param_idx, "min_freq");
			if (field_type != LUA_TNIL) {
				float val = lua_get_int_or_float(L, -1, "min_freq");
				params.min_freq = val;
			}
			lua_pop(L, 1);
		}
	} else {
		lua_pushliteral(L, "lua_dict_get_random_word: params is not nil or a table");
		lua_error(L);
	}

	int possib_word_count = -1;
	char word[MAX_WORD_LEN];

	int word_len = g_dict_api->get_random_word(g_dict_handle, &params,
	                                           word, sizeof(word),
	                                           &possib_word_count);

	// TODO include possib_word_count in a table or something
	lua_pushlstring(L, word, word_len);
	return 1;
}

static int lua_dict_get_words_made_from_letters(lua_State *L) {
	// TODO
	(void)L;
	return 0;
}

