#include<stdio.h>
#include<stdlib.h>
#include<string.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "game_api.h"

#include "lua_api.h"
#include "lua_api_dict.h"
#ifdef ENABLE_WORD_DICT
#include "dictionary.h"
#endif

#include "utils/str_eq_literal.h"
#include "lua_api_utils.h"

static const bool include_file_line_before_lua_prints = false;

// TODO rearrange this
extern const struct game_api lua_game_api;

#define LOG_ALL_LUA_ENTRY_EXIT 0

// TODO put this in a header or remove entirely
// right now I'm just using them for debugging a non-WASM client.
// I don't think we necessarily want to rely on mutexes here, the APIs
// should be mostly asynchronous.
// But for debugging, taking mutexes can make it easier to catch threading issues
// (e.g. if the "mouse event" API would cause deadlock with the graphics APIs)
extern void alexgames_mutex_take();
extern void alexgames_mutex_release();

#define LUA_API_ENTER(return_val) { \
	if (LOG_ALL_LUA_ENTRY_EXIT) { \
		alex_log("LUA API %s: enter\n", __func__); \
	} \
	alexgames_mutex_take(); \
	if (lua_dead) { \
		alex_log_err("%s: returning because lua_dead\n", __func__); \
		return return_val; \
	} \
	if (lua_busy_protection_enabled && lua_api_busy) { \
		alex_log_err("%s: already busy processing lua API\n", __func__); \
		return return_val; \
	} \
	if (lua_gettop(L) != 0) { \
		alex_log("%s: %d items on stack before starting!\n", __func__, lua_gettop(L)); \
	} \
	lua_api_busy = true; \
}

#define LUA_API_EXIT() { \
	if (LOG_ALL_LUA_ENTRY_EXIT) {                                                          \
		alex_log("LUA API %s: exit\n", __func__);                                            \
	}                                                                                      \
	if (lua_gettop(L) > 0) {                                                               \
		alex_log("%s: %d items left on stack after completion!\n", __func__, lua_gettop(L)); \
	}                                                                                      \
	lua_api_busy = false;                                                                  \
	alexgames_mutex_release(); \
}


#ifdef ENABLE_GAME_LUA_TRACES
#define GAME_LUA_TRACE(...) \
	alex_log(__VA_ARGS__);
#else
#define GAME_LUA_TRACE(...)
#endif

static const char *lua_tolstring_notnil(lua_State* L, int idx, size_t *len);

static int lua_draw_graphic(lua_State *L);
static int lua_draw_line(lua_State *L);
static int lua_draw_text(lua_State *L);
static int lua_draw_rect(lua_State *L);
static int lua_draw_triangle(lua_State *L);
static int lua_draw_circle(lua_State *L);
static int lua_draw_clear(lua_State *L);
static int lua_draw_refresh(lua_State *L);
static int lua_send_message(lua_State *L);
static int lua_create_btn(lua_State *L);
static int lua_set_btn_enabled(lua_State *L);
static int lua_set_btn_visible(lua_State *L);
static int lua_show_popup(lua_State *L);
static int lua_add_game_option(lua_State *L);
static int lua_prompt_string(lua_State *L);
static int lua_hide_popup(lua_State *L);
static int lua_set_status_msg(lua_State *L);
static int lua_set_status_err(lua_State *L);
static int lua_set_timer_update_ms(lua_State *L);
static int lua_delete_timer(lua_State *L);
static int lua_enable_evt(lua_State *L);
static int lua_get_time_ms(lua_State *L);
static int lua_get_time_of_day(lua_State *L);
static int lua_store_data(lua_State *L);
static int lua_get_new_session_id(lua_State *L);
static int lua_get_last_session_id(lua_State *L);
static int lua_save_state(lua_State *L);
static int lua_has_saved_state_offset(lua_State *L);
static int lua_get_saved_state_offset(lua_State *L);
static int lua_read_stored_data(lua_State *L);

static int lua_draw_extra_canvas(lua_State *L);
static int lua_new_extra_canvas(lua_State *L);
static int lua_set_active_canvas(lua_State *L);
static int lua_delete_extra_canvases(lua_State *L);

static int lua_get_user_colour_pref(lua_State *L);
static int lua_is_feature_supported(lua_State *L);

#ifdef ENABLE_WORD_DICT
#if 0
static int lua_get_words(lua_State *L);
#endif
#endif

static int lua_my_print(lua_State* L);



int lua_err_handler(struct lua_State *L);
static void handle_lua_err(void *L);
static void lua_push_error_handler(void *L);
	

static bool lua_api_busy = false;
static bool lua_busy_protection_enabled = true;

static bool stop_lua_on_err = false;
static bool lua_dead = false;

#ifdef ENABLE_WORD_DICT
//static void *g_dict_handle = NULL;
#endif



// TODO rename to api_callbacks
// TODO remove global variable and move to a wrapper handle that points to this and
//      the lua state `L`
static const struct game_api_callbacks *api;

static const struct luaL_Reg lua_c_api[] = {
	{"draw_graphic",    lua_draw_graphic    },
	{"draw_line",       lua_draw_line       },
	{"draw_text",       lua_draw_text       },
	{"draw_rect",       lua_draw_rect       },
	{"draw_triangle",   lua_draw_triangle   },
	{"draw_circle",     lua_draw_circle     },
	{"draw_clear",      lua_draw_clear      },
	{"draw_refresh",    lua_draw_refresh    },
	{"send_message",    lua_send_message    },
	{"create_btn",      lua_create_btn      },
	{"set_btn_enabled", lua_set_btn_enabled },
	{"set_btn_visible", lua_set_btn_visible },
	{"show_popup",      lua_show_popup      },
	{"add_game_option", lua_add_game_option },
	{"prompt_string",   lua_prompt_string   },
	{"hide_popup",      lua_hide_popup      },
	{"set_status_msg",  lua_set_status_msg  },
	{"set_status_err",  lua_set_status_err  },
	{"set_timer_update_ms",  lua_set_timer_update_ms },
	{"delete_timer",    lua_delete_timer },
	{"enable_evt",      lua_enable_evt      },
	{"get_time_ms",     lua_get_time_ms     },
	{"get_time_of_day", lua_get_time_of_day },
	{"get_new_session_id", lua_get_new_session_id },
	{"get_last_session_id", lua_get_last_session_id },
	{"store_data",       lua_store_data       },
	{"read_stored_data", lua_read_stored_data },
	{"save_state",      lua_save_state      },
	{"has_saved_state_offset", lua_has_saved_state_offset },
	{"get_saved_state_offset", lua_get_saved_state_offset },
	{"draw_extra_canvas",     lua_draw_extra_canvas     },
	{"new_extra_canvas",      lua_new_extra_canvas      },
	{"set_active_canvas",     lua_set_active_canvas     },
	{"delete_extra_canvases", lua_delete_extra_canvases },
	{"get_user_colour_pref",  lua_get_user_colour_pref},
	{"is_feature_supported",  lua_is_feature_supported},

	{NULL, NULL}
};

static const struct luaL_Reg lua_printlib[] = {
        // Override print so that we can still see them even on platforms
        // where printf isn't visible (e.g. android)
        {"print", lua_my_print},
};



// note that using "do ... while (0)" is basically just a trick
// to require a semi-colon after the call to the macro,
// so that it behaves slightly more like a normal function.
//
// note that putting the number sign `#` before the macro parameter
// converts it to a string, so that if field is `MOUSE_EVT_DOWN`,
// `field` is equal to the value of `MOUSE_EVT_DOWN`, but `#field`
// is equal to a string: "MOUSE_EVT_DOWN"
#define LUA_SET_FIELD_INTEGER_DEFINE(L, field)  \
	do {                                        \
	    lua_pushinteger(L, field);              \
	    lua_setfield(L, -2, #field);            \
	} while (0)


static int luaopen_alexlib(lua_State *L) {
	luaL_newlib(L, lua_c_api);

	LUA_SET_FIELD_INTEGER_DEFINE(L, MOUSE_EVT_DOWN);
	LUA_SET_FIELD_INTEGER_DEFINE(L, MOUSE_EVT_UP);
	LUA_SET_FIELD_INTEGER_DEFINE(L, MOUSE_EVT_LEAVE);
	LUA_SET_FIELD_INTEGER_DEFINE(L, MOUSE_EVT_ALT_DOWN);
	LUA_SET_FIELD_INTEGER_DEFINE(L, MOUSE_EVT_ALT_UP);
	LUA_SET_FIELD_INTEGER_DEFINE(L, MOUSE_EVT_ALT2_DOWN);
	LUA_SET_FIELD_INTEGER_DEFINE(L, MOUSE_EVT_ALT2_UP);

	LUA_SET_FIELD_INTEGER_DEFINE(L, TEXT_ALIGN_LEFT);
	LUA_SET_FIELD_INTEGER_DEFINE(L, TEXT_ALIGN_CENTRE);
	LUA_SET_FIELD_INTEGER_DEFINE(L, TEXT_ALIGN_CENTER);
	LUA_SET_FIELD_INTEGER_DEFINE(L, TEXT_ALIGN_RIGHT);

	LUA_SET_FIELD_INTEGER_DEFINE(L, POPUP_ITEM_TYPE_MSG);
	LUA_SET_FIELD_INTEGER_DEFINE(L, POPUP_ITEM_TYPE_BTN);
	LUA_SET_FIELD_INTEGER_DEFINE(L, POPUP_ITEM_TYPE_DROPDOWN);

	LUA_SET_FIELD_INTEGER_DEFINE(L, OPTION_TYPE_BTN);
	LUA_SET_FIELD_INTEGER_DEFINE(L, OPTION_TYPE_TOGGLE);

	// TODO this causes a crash on windows wxWidgets, why?
#if 0
	lua_getglobal(L, "_G");
	luaL_setfuncs(L, lua_printlib, 0);
	lua_pop(L, 1);
#else
	(void)lua_printlib;
#endif

	return 1;
}

#ifdef ENABLE_WORD_DICT
#if 0
static int luaopen_alexdictlib(lua_State *L) {
	static const struct luaL_Reg dict_c_api[] = {
		{"get_words",    lua_get_words    },
	};

		// TODO put init in here
	luaL_newlib(L, dict_c_api);

	return 1;
}
#endif
#endif

//#define LUA_SCRIPT_DIR ROOT_DIR "src/lua_scripts"
//#define LUA_SCRIPT_DIR ROOT_DIR ""

#define LUA_PRELOAD_DIR "preload/"

#define LUA_UPLOAD_DIR "upload/"

#define lua_getglobal_checktype_or_return_statement(L, name, type, err, return_statement) \
	{                                                                    \
		int rc = lua_getglobal(L, (name));                               \
		if (rc != (type)) {                                              \
			/*lua_pop(L, 1);*/                                           \
			lua_settop(L, 0);                                            \
			LUA_API_EXIT();                                              \
			if (err) {                                                   \
				char msg[1024];                                          \
				int msg_len = snprintf(msg, sizeof(msg), "%s is type %s, expected %s", \
				   	     name,                                           \
				         lua_typename(L, rc),                            \
				         lua_typename(L, type));                         \
				alex_log_err(msg);                                       \
				api->set_status_err(msg, msg_len);                       \
			}                                                            \
			return_statement;                                            \
		}                                                                \
	}

#define lua_getglobal_checktype_or_return(L, name, type)     \
	lua_getglobal_checktype_or_return_statement(L, name, type, /*err=*/ true, return)

#define lua_getglobal_checktype_or_return_no_err(L, name, type) \
	lua_getglobal_checktype_or_return_statement(L, name, type, /*err=*/ false, return)

#define lua_getglobal_checktype_or_return_val(L, name, type, return_val)     \
	lua_getglobal_checktype_or_return_statement(L, name, type, /*err=*/ true, return return_val)

#define lua_getglobal_checktype_or_return_val_no_err(L, name, type, return_val)     \
	lua_getglobal_checktype_or_return_statement(L, name, type, /*err=*/ false, return return_val)


//			fprintf(stderr, "global \"%s\" not defined with type %d in " \
//			                "lua main, is type %d\n",                    \
//			                (name), (type), (rc));                       \
//

#define lua_checkstack_or_return_statement(L, stack_size, return_statement) \
	{                                                              \
		if (!lua_checkstack(L, stack_size)) {                      \
			alex_log_err("stack size can not fit %d more "         \
			             "elements\n", stack_size);                \
			LUA_API_EXIT()                                         \
			return_statement;                                      \
		}                                                          \
		int stack_depth = lua_gettop(L);                           \
		if (stack_depth >= 20) {                                   \
			alex_log_err("lua stack depth is %d\n", stack_depth);  \
			LUA_API_EXIT()                                         \
			return_statement;                                      \
		}                                                          \
	}

#define lua_checkstack_or_return(L, stack_size)                    \
	lua_checkstack_or_return_statement(L, stack_size, return)

#define lua_checkstack_or_return_val(L, stack_size, val)           \
	lua_checkstack_or_return_statement(L, stack_size, return val)
	


#if 0
static void handle_panic(void) {
	alex_log_err("lua panic, setting lua_dead");
	lua_dead = true;
}

static void handle_warning(void *ud, const char *msg, int tocount) {
	alex_log_err("lua warning: %s", msg);
}
#endif

const char *get_lua_game_path(const char *game_id, size_t game_id_len) {
	if (str_eq_literal(game_id, "go", game_id_len)) {
		return LUA_PRELOAD_DIR "games/go/go_main.lua";
	} else if (str_eq_literal(game_id, "wu", game_id_len)) {
		return LUA_PRELOAD_DIR "games/wu/wu_main.lua";
	} else if (str_eq_literal(game_id, "card_test", game_id_len)) {
		return LUA_PRELOAD_DIR "/libs/cards/card_test.lua";
	} else if (str_eq_literal(game_id, "31s", game_id_len)) {
		return LUA_PRELOAD_DIR "games/31s/31s_main.lua";
	} else if (str_eq_literal(game_id, "life", game_id_len)) {
		return LUA_PRELOAD_DIR "games/life/life_main.lua";
	} else if (str_eq_literal(game_id, "checkers", game_id_len)) {
		return LUA_PRELOAD_DIR "games/checkers/checkers_main.lua";
	} else if (str_eq_literal(game_id, "crib", game_id_len)) {
		return LUA_PRELOAD_DIR "games/crib/crib_main.lua";
	} else if (str_eq_literal(game_id, "card_sim", game_id_len)) {
		return LUA_PRELOAD_DIR "games/card_sim/card_generic_main.lua";
	} else if (str_eq_literal(game_id, "touch_test", game_id_len)) {
		return LUA_PRELOAD_DIR "games/touch_test/touch_test.lua";
	} else if (str_eq_literal(game_id, "draw_graphics_test", game_id_len)) {
		return LUA_PRELOAD_DIR "games/test/draw_graphics_test.lua";
	} else if (str_eq_literal(game_id, "snake", game_id_len)) {
		return LUA_PRELOAD_DIR "games/snake/snake_main.lua";
	} else if (str_eq_literal(game_id, "solitaire", game_id_len)) {
		return LUA_PRELOAD_DIR "games/solitaire/solitaire_main.lua";
	} else if (str_eq_literal(game_id, "card_angle_test", game_id_len)) {
		return LUA_PRELOAD_DIR "games/test/card_angle_test.lua";
	} else if (str_eq_literal(game_id, "minesweeper", game_id_len)) {
		return LUA_PRELOAD_DIR "games/minesweeper/minesweeper_main.lua";
	} else if (str_eq_literal(game_id, "hospital", game_id_len)) {
		return LUA_PRELOAD_DIR "games/hospital/hospital_main.lua";
	} else if (str_eq_literal(game_id, "bound", game_id_len)) {
		return LUA_PRELOAD_DIR "games/bound/bound_main.lua";
	} else if (str_eq_literal(game_id, "sudoku", game_id_len)) {
		return LUA_PRELOAD_DIR "games/sudoku/sudoku_main.lua";
	} else if (str_eq_literal(game_id, "backgammon", game_id_len)) {
		return LUA_PRELOAD_DIR "games/backgammon/backgammon_main.lua";
	} else if (str_eq_literal(game_id, "chess", game_id_len)) {
		return LUA_PRELOAD_DIR "games/chess/chess_main.lua";
	} else if (str_eq_literal(game_id, "blue", game_id_len)) {
		return LUA_PRELOAD_DIR "games/blue/blue_main.lua";
	} else if (str_eq_literal(game_id, "thrust", game_id_len)) {
		return LUA_PRELOAD_DIR "games/thrust/thrust_main.lua";
	} else if (str_eq_literal(game_id, "swarm", game_id_len)) {
		return LUA_PRELOAD_DIR "games/swarm/swarm_main.lua";
	} else if (str_eq_literal(game_id, "spider_swing", game_id_len)) {
		return LUA_PRELOAD_DIR "games/spider_swing/spider_swing_main.lua";
	} else if (str_eq_literal(game_id, "poker_chips", game_id_len)) {
		return LUA_PRELOAD_DIR "games/poker_chips/poker_chips_main.lua";
	} else if (str_eq_literal(game_id, "word_mastermind", game_id_len)) {
		return LUA_PRELOAD_DIR "games/word_mastermind/word_mastermind_main.lua";
	} else if (str_eq_literal(game_id, "crossword_letters", game_id_len)) {
		return LUA_PRELOAD_DIR "games/crossword_letters/crossword_letters_main.lua";
	} else if (str_eq_literal(game_id, "crossword_builder", game_id_len)) {
		return LUA_PRELOAD_DIR "games/crossword_builder/crossword_builder_main.lua";
	} else if (str_eq_literal(game_id, "fluid_mix", game_id_len)) {
		return LUA_PRELOAD_DIR "games/fluid_mix/fluid_mix_main.lua";
	} else if (str_eq_literal(game_id, "timer_test", game_id_len)) {
		return LUA_PRELOAD_DIR "games/test/timer_test.lua";
	} else if (str_eq_literal(game_id, "endless_runner", game_id_len)) {
		return LUA_PRELOAD_DIR "games/endless_runner/endless_runner_main.lua";
	} else if (str_eq_literal(game_id, "minesweeper_life", game_id_len)) {
		return LUA_PRELOAD_DIR "games/minesweeper_life/minesweeper_life_main.lua";
	} else {
		return NULL;
	}
}


void *start_lua_game(const struct game_api_callbacks *api_callbacks, const char *game_path) {

#if ENABLE_WORD_DICT
#if 0
	printf("Initializing dictionary...\n");
	g_dict_handle = init_dict();
	printf("done Initializing dictionary...?\n");
	if (g_dict_handle == NULL) {
		char msg[] = "Error initializing dictionary. Word games will not work.";
		fprintf(stderr, "%s:%d %s\n", __FILE__, __LINE__, msg);
		alex_log_err("%s", msg);
        api_callbacks->set_status_err(msg, sizeof(msg));
	}
	printf("it even returned %p!\n", g_dict_handle);
#endif
#endif

	set_game_api(&lua_game_api);
	void *L = init_lua_game(api_callbacks, game_path);
    if (L == NULL) {
        char err_msg[4096];
        snprintf(err_msg, sizeof(err_msg), "Failed to load game \"%s\"", game_path);
        alex_log_err("%.*s", (int)sizeof(err_msg), err_msg);
        api_callbacks->set_status_err(err_msg, sizeof(err_msg));
		return L;
    }
	//game_api->start_game(L);

	return L;
}


static void lua_push_error_handler(void *L) {
	lua_pushcfunction(L, lua_err_handler);
}

static void lua_pop_error_handler(void *L) {
	int type = lua_type(L, -1);
	if (type != LUA_TFUNCTION) {
		luaL_error(L, "%s: expected last stack value to be error handler func, was type %d (%s)", __func__, type, lua_typename(L, type)); 
	}
	lua_pop(L, -1);
}

// Must call `lua_pop_error_handler` after calling this (and removing
// the other stuff you need from the stack)
static int pcall_handle_error(void *L, int nargs, int nresults) {

	int rc = lua_pcall(L, nargs, nresults, 1);

	if (rc != LUA_OK) {
		alex_log_err("pcall_handler_err: lua_pcall returned %d\n", rc);
		handle_lua_err(L);
		// TODO should I clean up the stack or anything?
		//lua_settop(L, 0);
	}
	return rc;
}

// TODO should rename this file to lua_adapter or something
// void *init_lua_api(const struct game_api_callbacks *api_callbacks_arg, const char *game_str, int game_str_len) {
void *init_lua_game(const struct game_api_callbacks *api_callbacks_arg, const char *lua_fpath_arg) {
	GAME_LUA_TRACE("init_lua_game\n");
	//set_game_api(&lua_game_api);
	api = api_callbacks_arg;

	char lua_script_dir[4096];
	{
		int rc = alex_get_root_dir(lua_script_dir, sizeof(lua_script_dir));
		if (rc) {
			alex_log_err("Failed to get root dir");
			return NULL;
		}
	}

	char lua_fpath[1024];
	lua_fpath[0] = '\0';
	// TODO this doesn't actually protect against buffer overrun
	// strlcat is better, I think, but I get linker errors when trying to use that in windows
	strncat(lua_fpath, lua_script_dir, sizeof(lua_fpath)-1);
	strncat(lua_fpath, lua_fpath_arg, sizeof(lua_fpath)-1);

	alex_log("[lua_init] Trying to load lua script at \"%s\"...\n", lua_fpath);

	alex_log("[lua_init] init_lua called...\n");
	lua_State *L = luaL_newstate();
	alex_log("[lua_init] lua_State is %p\n", L);
	luaL_openlibs(L);

#ifdef ENABLE_WORD_DICT
	// TODO why does alex_c_api.dict have to be initialized before alex_c_api?
	// maybe I have a bug causing it to fail when they're reversed.

	// TODO remove this, this is the old dictionary API
	//luaL_requiref(L, "alex_c_api.dict",  luaopen_alexdictlib, 0);

	init_lua_alex_dict(L, "alex_c_api.dict", get_game_dict_api());
#endif
	luaL_requiref(L, "alex_c_api", luaopen_alexlib, 0);
	// luaL_requiref leaves a copy of the library on the stack, so we need to pop it
	lua_pop(L, -1);
	lua_pop(L, -1);

	alex_log("[lua_init] called luaL_openlibs\n");

	int rc;
	//rc = luaL_dofile(L, "lua_script/go.lua");
	//printf("rc = %d\n", rc);
	//rc = luaL_dofile(L, "src/lua_scripts/games/go/go_main.lua");
	//rc = luaL_dofile(L, "games/go/go_main.lua");

	#if 0
	alex_log("Setting package.path to %s\n", LUA_SCRIPT_DIR);
	lua_getglobal(L, "package");
	lua_pushlstring(L, LUA_SCRIPT_DIR, strlen(LUA_SCRIPT_DIR));
	lua_setfield(L, -2, "path");
	lua_pop(L, 1);
	#endif

	lua_getglobal(L, "package");
	lua_getfield(L, -1, "path");
	const char *current_path = lua_tostring(L, -1);
	char new_path[4096];
	//snprintf(new_path, sizeof(new_path), "%s;%s/?.lua", current_path, ROOT_DIR);
	//snprintf(new_path, sizeof(new_path), "%s;%s/?.lua;%s/?.lua;%s/?.lua", current_path, LUA_SCRIPT_DIR, LUA_PRELOAD_DIR, LUA_UPLOAD_DIR);

	char preload_path[4096];
	{
		char root_dir[4096];
		int rc = alex_get_root_dir(root_dir, sizeof(root_dir));
		if (rc) {
			alex_log_err("Error getting root_dir");
			return NULL;
		}
		snprintf(preload_path, sizeof(preload_path), "%s%s", root_dir, LUA_PRELOAD_DIR);
		alex_log("[init] preload_path = \"%s\"\n", preload_path);
	}
	// TODO include the game's dirname() directory here
	int new_path_len = snprintf(new_path, sizeof(new_path),
	                            "%s;%s/?.lua;%s/?.lua;%s/?.lua;%s/?.lua",
	                            current_path, lua_script_dir, preload_path,
	                            LUA_UPLOAD_DIR, GAME_UPLOAD_PATH);
	if (new_path_len >= sizeof(new_path)) {
		alex_log_err("Lua package.path too big, max size %d, actual %d\n", sizeof(new_path), new_path_len);
		const char path_too_big_err[] = "Lua package.path too big";
		api->set_status_err(path_too_big_err, sizeof(path_too_big_err));
		return NULL;
	}
	lua_pop(L, 1);
	alex_log("[lua_init] Including preload path: \"%s\"\n", preload_path);
	alex_log("[lua_init] Including upload  path: \"%s\"\n", GAME_UPLOAD_PATH);

	lua_pushstring(L, new_path);
	lua_setfield(L, -2, "path");
	lua_pop(L, 1);


	// TODO put this somewhere better
	// and don't call it for non lua games
	//set_game_api(&lua_game_api);

	lua_api_busy = false;
	alex_log("[lua_init] setting lua panic function\n");
	//lua_atpanic(L, handle_panic);
	//lua_setwarnf(L, handle_warning, NULL);

	//lua_setglobal(L, "package.path");

//#warning "TODO revert this: disabling garbage collection"
	//alex_log_err("TODO FIX THIS: disabling garbage collection to debug");
	//lua_gc(L, LUA_GCSTOP);
	
	alex_log("[lua_init] about to call luaL_dofile\n");
	//rc = luaL_dofile(L, lua_fpath);

	const bool enable_err_handler = true;
	if (enable_err_handler) {
		lua_pushcfunction(L, lua_err_handler);
	}
	rc = luaL_loadfile(L, lua_fpath);
	if (rc == LUA_OK) {
		if (enable_err_handler) {
			rc = lua_pcall(L, 0, 0, 1);
		} else {
			rc = lua_pcall(L, 0, 0, 0);
		}
	}
	alex_log("[lua_init] done calling luaL_dofile\n");

	if (rc != LUA_OK) {
		alex_log_err("line %d: rc = %d\n", __LINE__, rc);
		//lua_err_handler(L);
		//handle_lua_err(L);
		const char *err_msg = lua_tostring(L, -1);
		alex_log_err("[lua_init] err: %s\n", err_msg);
		api->set_status_err(err_msg, strlen(err_msg));
		return 0;
	} else {
		alex_log("[lua_init] luaL_dofile returned rc = %d (LUA_OK)\n", rc);
		if (enable_err_handler) {
			lua_pop(L, 1);
		}
	}

	// This is so that when switching games, if the new game doesn't
	// draw anything (e.g. while showing a popup like "waiting for players"),
	// the old game won't still be shown.
	// Can't clear game on old game teardown, because history_browse relies on
	// the game remaining drawn.
	GAME_LUA_TRACE("calling draw_clear and draw_refresh on init\n");
	api->draw_clear();
	api->draw_refresh();

	if (lua_gettop(L) != 0) {
		alex_log_err("[lua_init] %s: before finishing, lua_gettop(L) returned %d. Should be zero.\n", __func__, lua_gettop(L));
	}

	GAME_LUA_TRACE("init_lua_game completed\n");
	return L;
}

#define CHECK_NON_NULL_AND_CALL(ptr, func) \
	if (ptr == NULL) {                                                          \
		alex_log_err("lua_api.c:%d %s is null\n", __LINE__, #ptr);              \
	} else if (ptr->func == NULL) {                                             \
		alex_log_err("lua_api.c:%d %s->%s() is null\n", __LINE__, #ptr, #func); \
	} else {                                                                    \
		ptr->func();                                                            \
	}

void destroy_lua_game(void *L) {
	alex_log("destroy_lua_game\n");

	// Don't call "draw_clear" and "draw_refresh" here,
	// because history_browse relies on the graphics remaining drawn when it
	// runs through multiple games.
	// Instead, draw_clear and draw_refresh should be called when initializing a new game.

	CHECK_NON_NULL_AND_CALL(api, hide_popup);
	CHECK_NON_NULL_AND_CALL(api, destroy_all);
	lua_close(L);

#ifdef ENABLE_WORD_DICT
	// TODO remove this. The dictionary is now loaded by the game, not the game API itself.
	// This is so that games who don't use the dictionary don't need to waste memory loading it.
	//if (g_dict_handle != NULL) {
	//	teardown_dict(g_dict_handle);
	//	g_dict_handle = NULL;
	//}
#endif
}

// TODO better name for this.
// This is meant to be called by Lua when there is an error,
// and to do a stack trace.
//
// `handle_lua_err` is meant to be called from C when there is an error returned by lua.
// It should probably be removed and be replaced by this one, some day.
//
int lua_err_handler(struct lua_State *L) {

	//const char *err_msg = lua_tostring(L, -1);
	//alex_log_err("%s: %s\n", __func__, err_msg);
	//api->set_status_err(err_msg, strnlen(err_msg, strnlen(err_msg, 1000)));

	//lua_getfield(L, LUA_GLOBALSINDEX, "debug");

	if (!lua_isstring(L, 1)) {
		alex_log_err("%s: arg 1 is not a string?", __func__);
		return 1;
	}

	lua_getglobal(L, "debug");
	if (!lua_istable(L, -1)) {
		lua_pop(L, 1);
		alex_log_err("%s: debug is not a table?", __func__);
		return 1;
	}

	
	lua_getfield(L, -1, "traceback");
	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 2);
		alex_log_err("%s: debug.traceback is not a function?", __func__);
		return 1;
	}

	lua_pushvalue(L, 1);
	lua_pushinteger(L, 2);
	lua_call(L, 2, 1);

	return 1;
}

static void handle_lua_err(void *L) {
	if (L == NULL) {
		alex_log_err("%s: L == null\n", __func__);
		return;
	}


	const char *err_msg = lua_tostring(L, -1);
	if (err_msg == NULL) {
		alex_log_err("%s: err_msg == null\n", __func__);
		return;
	}

	alex_log_err("lua error: %s\n", err_msg);
	api->set_status_err(err_msg, strnlen(err_msg, 1000));
	lua_pop(L, 1);
	if (stop_lua_on_err) {
		lua_dead = true;
	}

	// handle_lua_err(L);
}

static int lua_my_print(lua_State* L) {
	if (include_file_line_before_lua_prints) {
	lua_Debug ar;
	lua_getstack(L, 1, &ar);
	lua_getinfo(L, "nSl", &ar);
	alex_log("[%s:%d]: ", ar.short_src, ar.currentline);
	}
    int nargs = lua_gettop(L);
	if (nargs == 1) {
		// It's ideal to just call alex_log a single time.
		// On android this corresponds to a single logcat log, which already includes a newline
		alex_log("%s\n", lua_tostring(L, 1));
	} else {
		for (int i = 1; i <= nargs; i++) {
			if (lua_isstring(L, i)) {
				alex_log("%s", lua_tostring(L, i));
			} else {
				alex_log("print arg %d type is %d, unhandled", i, lua_type(L, i));
			}
			if (i < nargs) {
				alex_log(" ");
			}
		}
		alex_log("\n");
	}
    return 0;
}

static void draw_board(void *L, int dt_ms) {
	GAME_LUA_TRACE("draw_board\n");
	if (L == NULL) {
		fprintf(stderr, "%s: L == NULL\n", __func__);
		return;
	}
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 1);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "draw_board", LUA_TFUNCTION);
	lua_pushnumber(L, dt_ms);
	pcall_handle_error(L, 1, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
	GAME_LUA_TRACE("draw_board completed\n");
}

static void handle_user_string_input(void *L, char *user_line, int str_len, bool is_cancelled) {
	LUA_API_ENTER();
	printf("%s: \"%.*s\", is_cancelled=%d\n", __func__, str_len, user_line, is_cancelled);
	lua_checkstack_or_return(L, 2);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "handle_user_string_input", LUA_TFUNCTION);
	lua_pushlstring(L, user_line, str_len);
	lua_pushboolean(L, is_cancelled);
	pcall_handle_error(L, 2, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}

static void handle_user_clicked(void *L, int pos_y, int pos_x) {
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 3);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return_no_err(L, "handle_user_clicked", LUA_TFUNCTION);
	lua_pushinteger(L, pos_y);
	lua_pushinteger(L, pos_x);
	pcall_handle_error(L, 2, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}

// TODO should probably only have this enabled if it's defined
static void handle_mousemove(void *L, int pos_y, int pos_x, int buttons) {
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 4);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "handle_mousemove", LUA_TFUNCTION);
	lua_pushinteger(L, pos_y);
	lua_pushinteger(L, pos_x);
	lua_pushinteger(L, buttons);
	pcall_handle_error(L, 3, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}

static void handle_mouse_evt(void *L, int mouse_evt_id, int pos_y, int pos_x, int buttons) {
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 5);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "handle_mouse_evt", LUA_TFUNCTION);
	lua_pushinteger(L, mouse_evt_id);
	lua_pushinteger(L, pos_y);
	lua_pushinteger(L, pos_x);
	lua_pushinteger(L, buttons);
	pcall_handle_error(L, 4, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}

static void handle_wheel_changed(void *L, int delta_y, int delta_x) {
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 3);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "handle_wheel_changed", LUA_TFUNCTION);
	lua_pushinteger(L, delta_y);
	lua_pushinteger(L, delta_x);
	pcall_handle_error(L, 2, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}


static bool handle_key_evt(void *L, const char *evt_id, const char *key_code) {
	LUA_API_ENTER(false);
	lua_checkstack_or_return_val(L, 3, false);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return_val(L, "handle_key_evt", LUA_TFUNCTION, false);
	lua_pushstring(L, evt_id);
	lua_pushstring(L, key_code);
	int rc = pcall_handle_error(L, 2, 1);
	if (rc == LUA_OK && lua_gettop(L) <= 0) {
		char msg[2048];
		snprintf(msg, sizeof(msg),
		         "handle_key_evt(evt_id=\"%s\", code=\"%s\") returned nil! "
		         "(top was %d) "
		         "Should return true or "
		         "false to indicate if key was handled or not",
		         evt_id, key_code, lua_gettop(L));
		alex_log_err(msg);
		// TODO may want to have the option to suppress this...
		// after some number of logs, should always suppress it
		api->set_status_err(msg, sizeof(msg));
	}
	bool return_value = lua_toboolean(L, -1);
	lua_pop(L, 1);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
	return return_value;
}

// TODO maybe change the void *changed_touches type to struct touch_info[]
static void handle_touch_evt(void *L,
                             const char *evt_id_str, int evt_id_str_len, 
                             void *changed_touches_ptr, int changed_touches_len) {
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 3);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "handle_touch_evt", LUA_TFUNCTION); // stack index 1

	lua_pushlstring(L, evt_id_str, evt_id_str_len); // stack idx 2
	lua_createtable(L, changed_touches_len, 0); // stack idx 3
	
	//printf("Recvd touch evt id \"%.*s\", changed_touches_len = %d\n",
	//	evt_id_str_len, evt_id_str, changed_touches_len);
	struct touch_info *changed_touches = (struct touch_info *)changed_touches_ptr;
	for (int i=0; i<changed_touches_len; i++) {
		struct touch_info *touch = changed_touches + i;
		lua_checkstack_or_return(L, 2);
		lua_createtable(L, 0, 3); // stack idx 4
		lua_pushnumber(L, touch->id); // stack idx 5
		lua_setfield(L, -2, "id");
		lua_pushnumber(L, touch->y); // stack idx 5
		lua_setfield(L, -2, "y");
		lua_pushnumber(L, touch->x); // stack idx 5
		lua_setfield(L, -2, "x");
		lua_seti(L, -2, i+1); // Lua arrays are 1 indexed
	}
	pcall_handle_error(L, 2, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}

static void handle_msg_received(void *L, const char *msg_src, int msg_src_len, const char *msg, int len) {
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 3);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "handle_msg_received", LUA_TFUNCTION);
	lua_pushlstring(L, msg_src, msg_src_len);
	lua_pushlstring(L, msg,     len);
	pcall_handle_error(L, 2, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}

static void handle_btn_clicked(void *L, const char *btn_id) {
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 2);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "handle_btn_clicked", LUA_TFUNCTION);
	lua_pushstring(L, btn_id);
	pcall_handle_error(L, 1, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}

static void handle_popup_btn_clicked(void *L, const char *popup_id, int btn_idx,
                                     const struct popup_state *popup_state) {
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 3);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "handle_popup_btn_clicked", LUA_TFUNCTION);
	lua_pushstring(L, popup_id);
	lua_pushinteger(L, btn_idx);
    if (popup_state == NULL) {
        // This is only possible if the platform implementation (e.g. html/wasm, android, wxWidgets)
        // didn't implement this functionality.
        alex_log_err("WARNING: popup_state is NULL");
        lua_pushnil(L);
    } else {
        lua_createtable(L, popup_state->items_count, 0);
        int i;
        for (i = 0; i < popup_state->items_count; i++) {
            const struct popup_state_item *item = &popup_state->items[i];
            lua_newtable(L);
            lua_pushinteger(L, item->id);
            lua_setfield(L, -2, "id");
            lua_pushinteger(L, item->selected);
            lua_setfield(L, -2, "selected");
            lua_seti(L, -2, i + 1); // Lua is 1 indexed
        }
    }
	pcall_handle_error(L, 3, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}

static void handle_game_option_evt(void *L, enum option_type option_type, const char *option_id, int value) {
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 2);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "handle_game_option_evt", LUA_TFUNCTION);
	lua_pushstring(L, option_id);
	if (option_type == OPTION_TYPE_TOGGLE) {
		lua_pushboolean(L, value);
	} else {
		lua_pushnil(L);
	}
	pcall_handle_error(L, 2, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}

static void start_game(void *L, int session_id, const uint8_t *state, size_t state_len) {
	LUA_API_ENTER();
	lua_checkstack_or_return(L, 4);
	lua_push_error_handler(L);
	lua_getglobal_checktype_or_return(L, "start_game", LUA_TFUNCTION);
	lua_pushinteger(L, session_id);
	if (state != NULL) {
		lua_pushlstring(L, (const char*)state, state_len);
	} else {
		lua_pushnil(L);
	}
	pcall_handle_error(L, 2, 0);
	lua_pop_error_handler(L);
	LUA_API_EXIT();
}

static lua_Integer read_bytearray(void *L, uint8_t *byteary_out, size_t byteary_out_len, const char *func_name) {
	lua_Integer byte_len;
	{
		lua_len(L, -1);
		// ensure that value isn't nil?
		{
			int is_int = 0;
			byte_len = lua_tointegerx(L, -1, &is_int);
			if (!is_int) {
				luaL_error(L, "why the hell is the length not an integer???");
			}
		}
		lua_pop(L, 1);
	}
	int i;
	for (i=1; i<=byte_len; i++) {
		if (i >= byteary_out_len) {
			luaL_error(L, "%s: game returned %b bytes of state, larger than buff %d", func_name, byte_len, byteary_out_len);
			break;
		}
		int type = lua_geti(L, -1, i);
		if (type != LUA_TNUMBER) {
			luaL_error(L, "%s: byte %d is type %s, expected number ", func_name, i, lua_typename(L, type));
		}
		int is_int = false;
		lua_Integer val_int = lua_tointegerx(L, -1, &is_int);
		if (!(0 <=val_int && val_int<= 0xff)) {
			luaL_error(L, "%s: byte %d is %d, expected uint8", func_name, i, val_int);
		}
		byteary_out[i-1] = val_int;
		lua_pop(L, 1); // pop byte read from lua_geti
	}

	return byte_len;
}

static size_t call_func_get_bytearray(void *L, const char *func_name,
                                      bool err_if_not_found,
                                      uint8_t *state_out, size_t state_out_len) {
	size_t err_return_val = 0;
	LUA_API_ENTER(err_return_val);
	lua_checkstack_or_return_val(L, 3, err_return_val);
	lua_push_error_handler(L);
	if (err_if_not_found) {
		lua_getglobal_checktype_or_return_val(L, func_name, LUA_TFUNCTION, err_return_val);
	} else {
		lua_getglobal_checktype_or_return_val_no_err(L, func_name, LUA_TFUNCTION, err_return_val);
	}
	pcall_handle_error(L, 0, 1);
	int return_type = lua_type(L, -1);
	int byte_len = 0;
	if (return_type == LUA_TTABLE) {
		byte_len = read_bytearray(L, state_out, state_out_len, func_name);
	} else if (return_type == LUA_TSTRING) {
		size_t return_str_len = 0;
		const char *return_str = lua_tolstring(L, -1, &return_str_len);
		if (return_str_len > state_out_len) {
			luaL_error(L, "%s: returned %d bytes of state, max buff is %d", func_name, return_str_len, state_out_len);
		}
		memcpy(state_out, return_str, return_str_len);
		byte_len = return_str_len;
		printf("Returning %d bytes of state\n", byte_len);
	} else if (return_type == LUA_TNIL) {
		lua_pop(L, 1); // pop table/string that was returned by func call
		goto err;
	} else {
		alex_log_err_user_visible(api, "%s: returned type %s, should be a table or string", func_name, lua_typename(L, return_type));
		byte_len = 0;
	}

	lua_pop(L, 1); // pop table/string that was returned by func call

	printf("%s: Returning %d bytes of state: ", func_name, byte_len);
	for (int i=0; i<byte_len; i++) {
		printf("%02x ", state_out[i]);
	}
	printf("\n");

	err:
	lua_pop_error_handler(L);
	LUA_API_EXIT();
	return byte_len;
}

static size_t get_state(void *L, uint8_t *state_out, size_t state_out_len) {
	printf("lua_api.c get_state called, L=%p, top=%d\n", L, lua_gettop(L));
	return call_func_get_bytearray(L, "get_state", /*err_if_not_found=*/ true, state_out, state_out_len);
}

static size_t get_init_state(void *L, uint8_t *state_out, size_t state_out_len) {
	return call_func_get_bytearray(L, "get_init_state", /*err_if_not_found=*/ false, state_out, state_out_len);
}

// Should only be used for debugging,
// so only print errors to console
static void lua_run_cmd(void *L, const char *str, int string_len) {
	int rc = luaL_dostring(L, str);
	if (rc == LUA_OK) {
		alex_log("Successfully ran command \"%s\"\n", str);
	} else {
		alex_log_err("lua_run_cmd returned error %d\n", rc);
		const char *err_msg = lua_tostring(L, -1);
		alex_log_err("lua_run_cmd stack top: %s\n", err_msg);
		lua_pop(L, -1);
	}
}

const struct game_api lua_game_api = {
	.init_lua_api = NULL, //init_lua_api, // TODO do I need this?
	.destroy_game = destroy_lua_game,
	.draw_board = draw_board,
	.handle_user_string_input = handle_user_string_input,
	.handle_user_clicked = handle_user_clicked,
	.handle_mousemove = handle_mousemove,
	.handle_wheel_changed = handle_wheel_changed,
	.handle_mouse_evt = handle_mouse_evt,
	.handle_key_evt = handle_key_evt,
	.handle_touch_evt = handle_touch_evt,
	.handle_msg_received = handle_msg_received,
	.handle_btn_clicked = handle_btn_clicked,
	.handle_popup_btn_clicked = handle_popup_btn_clicked,
	.handle_game_option_evt = handle_game_option_evt,
	.get_state      = get_state,
	.get_init_state = get_init_state,
	.start_game = start_game,
	.lua_run_cmd = lua_run_cmd,
};


// draw_graphic(string img_id, int y, int x, int width, int height
static int lua_draw_graphic(lua_State *L) {
	// TODO check if right number of arguments is present

	size_t img_id_len = 0;
	const char *img_id = lua_tolstring_notnil(L, 1, &img_id_len);

	GAME_LUA_TRACE("lua_draw_graphic id=%s\n", img_id);

	lua_Integer y            = lua_get_int_or_float(L, 2, "y");
	lua_Integer x            = lua_get_int_or_float(L, 3, "x");
	lua_Integer width        = lua_get_int_or_float(L, 4, "width");
	lua_Integer height       = lua_get_int_or_float(L, 5, "height");
	struct draw_graphic_params params = default_draw_graphic_params();
	int param_idx = 6;
	if (lua_isnone(L, param_idx) || lua_isnil(L, param_idx)) {
		// do nothing, use default params
	} else if (lua_istable(L, param_idx)) {
		{
			int field_type = lua_getfield(L, param_idx, "angle_degrees");
			if (field_type != LUA_TNIL) {
				lua_Integer val = lua_get_int_or_float(L, -1, "angle_degrees");
				params.angle_degrees = val;
			}
			lua_pop(L, 1);
			
		}
		{
			int field_type = lua_getfield(L, param_idx, "flip_y");
			if (field_type == LUA_TNIL) {
				// if not set, do nothing, keep default value
			} else if (field_type == LUA_TBOOLEAN) {
				params.flip_y = lua_toboolean(L, -1);
			} else {
				lua_pushliteral(L, "draw_graphic: params.flip_y is not a boolean (and not nil)");
				lua_error(L);
			}
			lua_pop(L, 1);
		}
		{
			int field_type = lua_getfield(L, param_idx, "flip_x");
			if (field_type == LUA_TNIL) {
				// if not set, do nothing, keep default value
			} else if (field_type == LUA_TBOOLEAN) {
				params.flip_x = lua_toboolean(L, -1);
			} else {
				lua_pushliteral(L, "draw_graphic: params.flip_x is not a boolean (and not nil)");
				lua_error(L);
			}
			lua_pop(L, 1);
		}
		{
			int field_type = lua_getfield(L, param_idx, "brightness_percent");
			if (field_type == LUA_TNIL) {
				// if not set, do nothing, keep default value
			} else {
				lua_Integer val = lua_get_int_or_float(L, -1, "angle_degrees");
				if (!(0 <= val && val <= 100)) {
					lua_pushliteral(L, "draw_graphic: params.brightness_percent should be an integer between 0 and 100");
				}
				params.brightness_percent = val;
			}
		}
		{
			int field_type = lua_getfield(L, param_idx, "invert");
			if (field_type == LUA_TNIL) {
				// if not set, do nothing, keep default value
			} else if (field_type == LUA_TBOOLEAN) {
				params.invert = lua_toboolean(L, -1);
			} else {
				lua_pushliteral(L, "draw_graphic: params.invert is not a boolean (and not nil)");
				lua_error(L);
			}
			lua_pop(L, 1);
		}
	} else {
		lua_pushliteral(L, "draw_graphic: params is not nil or a table");
		lua_error(L);
	}
	
	api->draw_graphic(img_id, y, x, width, height, &params);

	return 0;
}

static int lua_draw_line(lua_State *L) {
	size_t colour_str_len = 0;
	const char *colour_str = lua_tolstring_notnil(L, 1, &colour_str_len);

	lua_Integer line_size = lua_get_int_or_float(L, 2, "line_size"); // this probably should just be an int
	lua_Integer y1        = lua_get_int_or_float(L, 3, "y1");
	lua_Integer x1        = lua_get_int_or_float(L, 4, "x1");
	lua_Integer y2        = lua_get_int_or_float(L, 5, "y2");
	lua_Integer x2        = lua_get_int_or_float(L, 6, "x2");

	api->draw_line(colour_str, line_size, y1, x1, y2, x2);

	return 0;
}

static int lua_draw_text(lua_State *L) {
	size_t text_str_len = 0;
	const char *text_str = lua_tolstring_notnil(L, 1, &text_str_len);

	size_t colour_str_len = 0;
	const char *colour_str = lua_tolstring_notnil(L, 2, &colour_str_len);

	lua_Integer y     = lua_get_int_or_float(L, 3, "y");
	lua_Integer x     = lua_get_int_or_float(L, 4, "x");
	lua_Integer size  = lua_tointeger(L, 5);
	lua_Integer align = lua_tointeger(L, 6);

	api->draw_text(text_str, text_str_len,
	               colour_str, colour_str_len,
	               y, x, size, align);

	return 0;
}

static int lua_draw_rect(lua_State *L) {
	size_t fill_colour_len;
	const char *fill_colour_str = lua_tolstring_notnil(L, 1, &fill_colour_len);

	lua_Integer y_start = lua_get_int_or_float(L, 2, "y_start");
	lua_Integer x_start = lua_get_int_or_float(L, 3, "x_start");
	lua_Integer y_end   = lua_get_int_or_float(L, 4, "y_end");
	lua_Integer x_end   = lua_get_int_or_float(L, 5, "x_end");


	api->draw_rect(fill_colour_str, fill_colour_len,
	             y_start, x_start,
	             y_end  , x_end);
	return 0;
}

static int lua_draw_triangle(lua_State *L) {
	size_t fill_colour_len;
	const char *fill_colour_str = lua_tolstring_notnil(L, 1, &fill_colour_len);
	// TODO add errors for any colour strings that are nil

	lua_Integer y1 = lua_get_int_or_float(L, 2, "y1");
	lua_Integer x1 = lua_get_int_or_float(L, 3, "x1");
	lua_Integer y2 = lua_get_int_or_float(L, 4, "y2");
	lua_Integer x2 = lua_get_int_or_float(L, 5, "x2");
	lua_Integer y3 = lua_get_int_or_float(L, 6, "y3");
	lua_Integer x3 = lua_get_int_or_float(L, 7, "x3");

	api->draw_triangle(fill_colour_str, fill_colour_len,
	                   y1, x1,
	                   y2, x2,
	                   y3, x3);

	return 0;
}

static int lua_draw_circle(lua_State *L) {
	size_t fill_colour_len;
	const char *fill_colour_str = lua_tolstring_notnil(L, 1, &fill_colour_len);

	size_t outline_colour_len;
	const char *outline_colour_str = lua_tolstring_notnil(L, 2, &outline_colour_len);
	
	lua_Integer y      = lua_get_int_or_float(L, 3, "y");
	lua_Integer x      = lua_get_int_or_float(L, 4, "x");
	lua_Integer radius = lua_get_int_or_float(L, 5, "radius");
	lua_Integer outline_width = lua_get_int_or_float_or_nil(L, 6, "outline_width");

	api->draw_circle(fill_colour_str, fill_colour_len,
	               outline_colour_str, outline_colour_len,
	               y, x, radius, outline_width);
	return 0;
}


static int lua_draw_clear(lua_State *L) {
	api->draw_clear();
	return 0;
}

static int lua_draw_refresh(lua_State *L) {
	api->draw_refresh();
	return 0;
}

static int lua_send_message(lua_State *L) {
	size_t dst_len = 0;
	const char *dst = lua_tolstring_notnil(L, 1, &dst_len);

	size_t msg_len = 0;
	const char *msg = lua_tolstring_notnil(L, 2, &msg_len);


	api->send_message(dst, dst_len, msg, msg_len);

	return 0;
}


static int lua_create_btn(lua_State *L) {
	size_t btn_id_str_len = 0;
	const char *btn_id_str = lua_tolstring_notnil(L, 1, &btn_id_str_len);
	size_t btn_text_str_len = 0;
	const char *btn_text_str = lua_tolstring_notnil(L, 2, &btn_text_str_len);
	lua_Integer weight = lua_tointeger(L, 3);

	api->create_btn(btn_id_str, btn_text_str, weight);

	return 0;
}

static int lua_set_btn_enabled(lua_State *L) {
	size_t btn_id_str_len = 0;
	const char *btn_id_str = lua_tolstring_notnil(L, 1, &btn_id_str_len);
	int enabled = lua_toboolean(L, 2);

	api->set_btn_enabled(btn_id_str, enabled);

	return 0;
}

static int lua_set_btn_visible(lua_State *L) {
	size_t btn_id_str_len = 0;
	const char *btn_id_str = lua_tolstring_notnil(L, 1, &btn_id_str_len);
	int visible = lua_toboolean(L, 2);

	api->set_btn_visible(btn_id_str, visible);

	return 0;
}

static int lua_hide_popup(lua_State *L) {
	api->hide_popup();
	return 0;
}

static int lua_set_status_msg(lua_State *L) {

	size_t msg_len = 0;
	const char *msg = lua_tolstring_notnil(L, 1, &msg_len);

	api->set_status_msg(msg, msg_len);

	return 0;
}

static int lua_set_status_err(lua_State *L) {
	size_t msg_len = 0;
	const char *msg = lua_tolstring_notnil(L, 1, &msg_len);

	api->set_status_err(msg, msg_len);

	return 0;
}

#define MAX_BUTTONS (16)
#define MAX_BUTTON_STR_LEN (64)

static int lua_show_popup(lua_State *L) {
	size_t popup_id_str_len = 0;

	if (lua_type(L, 1) != LUA_TSTRING) {
		luaL_error(L, "%s: expected arg 1 to be popup id (string)", __func__);
		return 0;
	}
	const char *popup_id = lua_tolstring_notnil(L, 1, &popup_id_str_len);

	struct popup_info *popup_info = malloc(sizeof(struct popup_info));

	const int info_tbl_param_idx = 2;

	if (!lua_istable(L, info_tbl_param_idx)) {
		free(popup_info);
		luaL_error(L, "%s:%d: expected arg %d to be table", __func__, __LINE__, info_tbl_param_idx);
	}

	{
		int field_type = lua_getfield(L, info_tbl_param_idx, "title");
		if (field_type != LUA_TSTRING) {
			free(popup_info);
			luaL_error(L, "%s:%d: expected \"title\" field to be string, not %d", __func__, __LINE__, field_type);
		}
		const char *title = lua_tostring(L, -1);
		strncpy(popup_info->title, title, sizeof(popup_info->title));
		lua_pop(L, 1);
	}

	{
		int field_type = lua_getfield(L, info_tbl_param_idx, "items");
		if (field_type != LUA_TTABLE) {
			free(popup_info);
			luaL_error(L, "%s:%d: expected \"items\" field to be table, not %d", __func__, __LINE__, field_type);
		}

		lua_len(L, -1);
		lua_Integer items_len = lua_tointeger(L, -1);
		popup_info->item_count = items_len;
		lua_pop(L, 1);

		int i;
		for (i=0; i<items_len; i++) {
			lua_Integer lua_tbl_idx = i + 1; // Lua tables are 1 indexed

			lua_pushinteger(L, lua_tbl_idx);
			lua_gettable(L, -2); // push items[i]

			{
				int field_type2 = lua_getfield(L, -1, "item_type");
				if (field_type2 != LUA_TNUMBER) {
					free(popup_info);
					luaL_error(L, "%s:%d: expected \"item_type\" field to be number, not %d", __func__, __LINE__, field_type2);
				}
				popup_info->items[i].type = lua_tointeger(L, -1);
				lua_pop(L, 1);
			}

			union popup_item_info *info = &popup_info->items[i].info;
			switch(popup_info->items[i].type) {
				case POPUP_ITEM_TYPE_MSG:
				{
					int field_type2 = lua_getfield(L, -1, "msg");
					if (field_type2 != LUA_TSTRING) {
						free(popup_info);
						luaL_error(L, "%s:%d: expected \"msg\" field to be string, not %d", __func__, __LINE__, field_type2);
					}
					const char *msg = lua_tostring(L, -1);
					strncpy(info->msg.msg, msg, sizeof(info->msg.msg));
					lua_pop(L, 1);
				}
				break;

				case POPUP_ITEM_TYPE_DROPDOWN:
				{
					int field_type2 = lua_getfield(L, -1, "id");
					if (field_type2 == LUA_TNIL) {
						free(popup_info);
						luaL_error(L, "%s:%d: expected dropdown \"id\" field to be number, not nil", __func__, __LINE__, field_type2);
					} else if (field_type2 != LUA_TNUMBER) {
						free(popup_info);
						luaL_error(L, "%s:%d: expected dropdown \"id\" field to be number, not type %d", __func__, __LINE__, field_type2);
					}
					int is_num = 0;
					info->dropdown.id = lua_tointegerx(L, -1, &is_num);
					if (!is_num) {
						free(popup_info);
						luaL_error(L, "%s:%d: expected dropdown \"id\" field to be integer", __func__, __LINE__);
					}
					lua_pop(L, 1);

					field_type2 = lua_getfield(L, -1, "label");
					if (field_type2 != LUA_TSTRING) {
						free(popup_info);
						luaL_error(L, "%s:%d: expected \"label\" field to be string, not %d", __func__, __LINE__, field_type2);
					}
					const char *label = lua_tostring(L, -1);
					strncpy(info->dropdown.label, label, sizeof(info->dropdown.label));
					lua_pop(L, 1);

					field_type2 = lua_getfield(L, -1, "options");
					if (field_type2 != LUA_TTABLE) {
						free(popup_info);
						luaL_error(L, "%s:%d: expected \"options\" field to be table, not %d", __func__, __LINE__, field_type2);
					}
					lua_len(L, -1);
					lua_Integer options_len = lua_tointeger(L, -1);
					lua_pop(L, 1);

					info->dropdown.option_count = options_len;

					int option_idx;
					for (option_idx=0; option_idx<options_len; option_idx++) {
						lua_geti(L, -1, option_idx+1); // Lua tables are 1 indexed
						const char *option_txt = lua_tostring(L, -1);
						strncpy(info->dropdown.options[option_idx], option_txt, sizeof(info->dropdown.options[option_idx]));
						lua_pop(L, 1);
					}
					lua_pop(L, 1);
				}
				break;

				case POPUP_ITEM_TYPE_BTN:
				{
					int field_type2 = lua_getfield(L, -1, "text");
					if (field_type2 != LUA_TSTRING) {
						free(popup_info);
						luaL_error(L, "%s:%d: expected \"text\" field to be string, not %d", __func__, __LINE__, field_type2);
					}
					const char *btn_text = lua_tostring(L, -1);
					strncpy(info->btn.text, btn_text, sizeof(info->btn.text));
					lua_pop(L, 1);

					field_type2 = lua_getfield(L, -1, "id");
					if (field_type2 != LUA_TNUMBER) {
						free(popup_info);
						luaL_error(L, "%s:%d: expected \"id\" field to be number, not %d", __func__, __LINE__, field_type2);
					}
					info->btn.id = lua_tointeger(L, -1);
					lua_pop(L, 1);
				}
				break;
			}
			lua_pop(L, 1); // pop items[i]
		}
		lua_pop(L, 1); // pop items
	}

#if 0
	int i;
	for (i=0; i<popup_info->item_count; i++) {
		printf("i=%d, item_type: %d\n", i, popup_info->items[i].type);
		switch (popup_info->items[i].type) {
			case POPUP_ITEM_TYPE_MSG: printf("msg: %s\n", popup_info->items[i].info.msg.msg); break;
			case POPUP_ITEM_TYPE_BTN: printf("btn_id: %d, btn_text: %s\n", popup_info->items[i].info.btn.id, popup_info->items[i].info.btn.text); break;
			case POPUP_ITEM_TYPE_DROPDOWN: printf("not handled\n"); break;
		}
	}
#endif

	api->show_popup(L, popup_id, popup_id_str_len,
	                popup_info);
	printf("%s:%d\n", __FILE__, __LINE__);
	return 0;
}


static int lua_add_game_option(lua_State *L) {
	size_t option_id_str_len = 0;
	const char *option_id = lua_tolstring_notnil(L, 1, &option_id_str_len);

	const int info_param_idx = 2;
	if (!lua_istable(L, info_param_idx)) {
		luaL_error(L, "%s:%d: expected arg %d to be table", __func__, __LINE__, info_param_idx);
	}

	struct option_info *option_info = malloc(sizeof(struct option_info));
	memset(option_info, 0, sizeof(*option_info));


	{
		int field_type = lua_getfield(L, info_param_idx, "type");
		if (field_type != LUA_TNUMBER) {
			free(option_info);
			luaL_error(L, "%s:%d: expected \"type\" field to be string, not type %d", __func__, __LINE__, field_type);
		}
		option_info->option_type = lua_tonumber(L, -1);
	}

	if (option_info->option_type == OPTION_TYPE_BTN ||
	    option_info->option_type == OPTION_TYPE_TOGGLE) {
		int field_type = lua_getfield(L, info_param_idx, "label");
		if (field_type != LUA_TSTRING) {
			free(option_info);
			luaL_error(L, "%s:%d: expected \"label\" field to be string, not %d (%s)", __func__, __LINE__, field_type, lua_typename(L, field_type));
		}
		const char *label = lua_tostring(L, -1);
		strncpy(option_info->label, label, sizeof(option_info->label));
	}


	if (option_info->option_type == OPTION_TYPE_TOGGLE) {
		int field_type = lua_getfield(L, info_param_idx, "value");
		if (field_type != LUA_TBOOLEAN) {
			free(option_info);
			luaL_error(L, "%s:%d: expected \"value\" field to be bool, not %d (%s)", __func__, __LINE__, field_type, lua_typename(L, field_type));
		}
		option_info->value = lua_toboolean(L, -1);
	}
	

	lua_pop(L, -1);

	api->add_game_option(option_id, option_info);
	free(option_info);
	return 0;
}


static int lua_prompt_string(lua_State *L) {
	size_t title_len;
	const char *title = lua_tolstring_notnil(L, 1, &title_len);

	size_t msg_len;
	const char *msg = lua_tolstring_notnil(L, 2, &msg_len);

	api->prompt_string(title, title_len,
	                   msg,   msg_len);

	return 0;
}

static int lua_set_timer_update_ms(lua_State *L) {
	lua_Number update_period_ms = lua_get_int_or_float(L, 1, "update_period_ms");

	int timer_handle = api->update_timer_ms(update_period_ms);

	lua_pushnumber(L, timer_handle);
	return 1;
}


static int lua_delete_timer(lua_State *L) {
	int is_num = 0;
	lua_Number timer_handle = lua_tonumberx(L, 1, &is_num);

	if (!is_num) {
		luaL_error(L, "%s: expected param to be type number", __func__);
	}

	api->delete_timer(timer_handle);

	return 0;
}

static int lua_enable_evt(lua_State *L) {
	size_t evt_id_len = 0;
	const char *evt_id_str = lua_tolstring_notnil(L, 1, &evt_id_len);

	api->enable_evt(evt_id_str, evt_id_len);
	return 0;
}


static int lua_get_time_ms(lua_State *L) {
	long time_ms = api->get_time_ms();

	lua_pushnumber(L, time_ms);

	return 1;
}

static int lua_get_time_of_day(lua_State *L) {
	
	char time_of_day_str[128];
	size_t time_of_day_str_len = api->get_time_of_day(time_of_day_str, sizeof(time_of_day_str));

	lua_pushlstring(L, time_of_day_str, time_of_day_str_len);

	return 1;
}

static int lua_store_data(lua_State *L) {
	size_t key_len = 0;
	const char *key = lua_tolstring_notnil(L, 1, &key_len);

	size_t value_len = 0;
	uint8_t *value;
	bool is_malloced = false;
	if (lua_type(L, 2) == LUA_TSTRING) {
		value = (uint8_t*)lua_tolstring(L, 2, &value_len);
	} else if(lua_type(L, 2) == LUA_TTABLE) {
		lua_len(L, 2);
		value_len = lua_tonumber(L, -1);
		lua_pop(L, 1);

		value = malloc(value_len);
		is_malloced = true;

		for (int i=0; i<value_len; i++) {
			int lua_idx = i+1;
			int elem_type = lua_geti(L, 2, lua_idx);
			if (elem_type != LUA_TNUMBER) {
				free((void*)value);
				luaL_error(L, "%s:%d value arg elem %d is type %d (%s), expected number",
				           __func__, __LINE__, lua_idx, elem_type, lua_typename(L, elem_type));
				return 0;
			}
			int val = lua_tonumber(L, -1);
			if (val < 0 || val >= 256) {
				free((void*)value);
				luaL_error(L, "%s:%d value arg elem %d is %d, must be between 0 and 255",
				           __func__, __LINE__, lua_idx, val);
				return 0;

			}
			value[i] = (uint8_t)val;
			lua_pop(L, 1);
		}
	}

	api->store_data(NULL, key, value, value_len);

	if (is_malloced) {
		free(value);
	}

	return 0;
}

static int lua_read_stored_data(lua_State *L) {
	GAME_LUA_TRACE("read_stored_data\n");
	size_t key_len = 0;
	const char *key = lua_tolstring_notnil(L, 1, &key_len);

	//const uint8_t *state     = NULL;
	//size_t         state_len = 0;
	//api->read_state(key, &state, state_len);

	size_t val_buff_max = 1024*64;
	// TODO just make this static?
	uint8_t *val_buff = malloc(val_buff_max);
	size_t val_len = api->read_stored_data(NULL, key, val_buff, val_buff_max);
	
	int args_to_return;
	if (val_len == -1) {
		args_to_return = 0;
	} else {
		//printf("push string len %zu\n", val_len);
		lua_pushlstring(L, (const char *)val_buff, val_len);
		args_to_return = 1;
	}

	free((void*)val_buff);

	return args_to_return;
}


static int lua_get_new_session_id(lua_State *L) {

	int session_id = api->get_new_session_id();
	lua_pushnumber(L, session_id);

	return 1;
}


static int lua_get_last_session_id(lua_State *L) {
	GAME_LUA_TRACE("get_last_session_id\n");
	char game_id[128];
	game_id[0] = '\0';
	api->get_game_id(L, game_id, sizeof(game_id));

	if (game_id[0] == '\0') {
		alex_log_err_user_visible(api, "api->get_game_id() returned empty string");
		return 0;
	}

	int session_id = api->get_last_session_id(game_id);

	if (session_id == -1) {
		lua_pushnil(L);
	} else {
		lua_pushnumber(L, session_id);
	}
	return 1;
}

static int lua_save_state(lua_State *L) {
	lua_Integer session_id = lua_tointeger(L, 1);

	size_t value_len = 0;
	// TODO make this support lists of bytes too, like lua_store_data
	const uint8_t *value = (const uint8_t*)lua_tolstring_notnil(L, 2, &value_len);

	api->save_state(session_id, value, value_len);

	return 0;
}

static int lua_has_saved_state_offset(lua_State *L) {
	lua_Integer session_id     = lua_tointeger(L, 1);
	lua_Integer move_id_offset = lua_tointeger(L, 2);

	if (api->has_saved_state_offset == NULL) {
		luaL_error(L, "api->has_saved_state_offset is NULL");
		return 0;
	}

	bool has_value = api->has_saved_state_offset(session_id, move_id_offset);

	lua_pushboolean(L, has_value);
	return 1;
}

static int lua_get_saved_state_offset(lua_State *L) {
	lua_Integer session_id = -1;
	{
		int session_id_is_int = 0;
		session_id = lua_tointegerx(L, 1, &session_id_is_int);
		if (!session_id_is_int) {
			luaL_error(L, "get_saved_state_offset called with invalid session_id param, expected int");
			return 0;
		}
	}
	lua_Integer move_id_offset;
	{
		int move_id_offset_is_int = 0;
		move_id_offset = lua_tointegerx(L, 2, &move_id_offset_is_int);
		if (!move_id_offset_is_int) {
			luaL_error(L, "get_saved_state_offset called with invalid move_id_offset param, expected int");
			return 0;
		}
	}

	if (api->get_saved_state_offset == NULL) {
		luaL_error(L, "api->get_saved_state_offset is NULL");
		return 0;
	}

	const size_t max_saved_state_size = 64*1024;
	uint8_t *buff = malloc(max_saved_state_size);

	printf("Loading saved state session_id=%lld, move_id_offset=%lld\n", session_id, move_id_offset);
	int bytes_read = api->get_saved_state_offset(session_id, move_id_offset, buff, max_saved_state_size);

	int vals_to_return = 0;

	if (bytes_read == -1) {
		// do nothing?
		free(buff);
		return 0;
	} else if (bytes_read > max_saved_state_size) {
		free(buff);
		luaL_error(L, "api->get_saved_state_offset returned %d", bytes_read);
		return 0;
	} else if (bytes_read > 0) {
		lua_pushlstring(L, (const char *)buff, bytes_read);
		vals_to_return = 1;
	} else {
		free(buff);
		luaL_error(L, "api->get_saved_state_offset returned %d", bytes_read);
		return 0;
	}
	
	free(buff);
	return vals_to_return;
}

static int lua_draw_extra_canvas(lua_State *L) {
	size_t canvas_id_len = 0;
	const char *canvas_id = lua_tolstring_notnil(L, 1, &canvas_id_len);

	// TODO use lua_tointegerx and check if successfully converted arg to integer
	lua_Integer y            = lua_get_int_or_float(L, 2, "y");
	lua_Integer x            = lua_get_int_or_float(L, 3, "x");
	lua_Integer width        = lua_get_int_or_float(L, 4, "width");
	lua_Integer height       = lua_get_int_or_float(L, 5, "height");
	
	api->draw_extra_canvas(canvas_id, y, x, width, height);

	return 0;
}

static int lua_new_extra_canvas(lua_State *L) {
	size_t canvas_id_len = 0;
	const char *canvas_id = lua_tolstring_notnil(L, 1, &canvas_id_len);

	api->new_extra_canvas(canvas_id);
	return 0;
}

static int lua_set_active_canvas(lua_State *L) {
	size_t canvas_id_len = 0;
	const char *canvas_id = lua_tolstring_notnil(L, 1, &canvas_id_len);

	api->set_active_canvas(canvas_id);
	return 0;
}

static int lua_delete_extra_canvases(lua_State *L) {
	(void)L;

	api->delete_extra_canvases();
	return 0;
}


static int lua_get_user_colour_pref(lua_State *L) {
	char str_buff[128];
	size_t str_len = api->get_user_colour_pref(str_buff, sizeof(str_buff));
	//printf("User's colour preference is [%zu]: \"%.*s\"\n", str_len, (int)str_len, str_buff);

	lua_pushlstring(L, str_buff, str_len);
	return 1;
}

static int lua_is_feature_supported(lua_State *L) {
	size_t feature_id_len = 0;
	const char *feature_id = lua_tolstring_notnil(L, 1, &feature_id_len);
	
	bool is_supported = api->is_feature_supported(feature_id, feature_id_len);
	lua_pushboolean(L, is_supported);

	return 1;
}


static const char *lua_tolstring_notnil(lua_State* L, int idx, size_t *len) {
	int type = lua_type(L, idx);
	if (type != LUA_TSTRING) {
		luaL_error(L, "arg %d is type %s (%d), expected string", idx, lua_typename(L, type), type);
		return NULL;
	}

	return lua_tolstring(L, idx, len);
}

#ifdef ENABLE_WORD_DICT

struct word_table_handle {
	void *L;
	int lua_callback_func;
};

#if 0
static int lua_create_word_table(void *handle_arg) {
	printf("func %s starting\n", __func__);
	struct word_table_handle *handle = handle_arg;
	lua_newtable(handle->L);
	return 0;
}
#endif

#if 0
static int lua_add_word_to_table(void *handle_arg, int row_idx, int argc, const unsigned char **argv) {
	//printf("func %s starting\n", __func__);
	struct word_table_handle *handle = handle_arg;

	/*
	int i;
	for (i=0; i<argc; i++) {
		if (i != 0) { printf(", "); }
		printf("%s", argv[i]);
	}
	printf("\n");
	*/

	//printf("word = %10s, freq = %e\n", word, freq);

	lua_newtable(handle->L);

	int i;
	for (i=0; i<argc; i++) {
		//if (i != 0) { printf(", "); }
		//printf("%s", argv[i]);
		lua_pushstring(handle->L, (const char*)argv[i]);
		lua_seti(handle->L, -2, i+1);
	}
	//printf("\n");
	lua_seti(handle->L, -2, row_idx+1);
	//lua_insert(handle->L, -2);
	//lua_insert(handle->L, -2);

	return 0;
}

static int lua_word_table_done(void *handle_arg) {
	printf("func %s starting\n", __func__);
	struct word_table_handle *handle = handle_arg;

	int rc = lua_pcall(handle->L, 1, 0, 0);
	if (rc != LUA_OK) {
		handle_lua_err(handle->L);
	}

	free(handle_arg);
	return 0;
}
#endif

/**
 * Don't get too attached to this API, it is basically deprecated.
 * Supporting arbitrary SQL requires too much code (~2MB of WASM).
 */
#if 0
static int lua_get_words(lua_State *L) {
	//printf("lua_get_words\n");
	size_t query_len = 0;
	const char *query = lua_tolstring(L, 1, &query_len);
	//printf("lua_get_words(query=\"%s\")\n", query);

	if (g_dict_handle == NULL) {
		luaL_error(L, "%s: dict_handle is NULL", __func__);
		return 0;
	}

	if (!lua_isstring(L, 2) ||  strcmp(lua_tostring(L, 2), "en") != 0) {
		luaL_error(L, "%s: argument 2 must be \'en\', sorry only English support right now", __func__);
	}

	// TODO can put this on the stack now
	struct word_table_handle *handle = malloc(sizeof(struct word_table_handle));
	//printf("Created handle %p\n", handle);
	handle->L = L;
	//handle->lua_callback_func = luaL_ref(L, LUA_REGISTRYINDEX);

	struct word_callback_data data;
	data.handle = handle;
	//data.create_word_table     = lua_create_word_table;
	data.add_word_to_list_func = lua_add_word_to_table;
	//data.word_table_done       = lua_word_table_done;

	lua_newtable(handle->L);
	//printf("calling get_words with query \"%s\"\n", query);
	get_words(g_dict_handle, query, &data);
	free(handle);
	return 1;
}
#endif
#endif
