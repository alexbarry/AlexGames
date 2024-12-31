#include "lua.h"

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

static const struct luaL_Reg lua_c_api[] = {
	{"ai_init",        lua_ai_init },
	{"ai_destroy",     lua_ai_destroy },
	{"expand_tree",    lua_expand_tree },
	{"get_move",       lua_get_move },
	{"get_move_score", lua_get_move_score },
	{"move_node",      lua_move_node },
};

static int lua_ai_init(lua_State *L) {
}
static int lua_ai_destroy(lua_State *L) {
}
static int lua_expand_tree(lua_State *L) {
}
static int lua_get_move(lua_State *L) {
}
static int lua_get_move_score(lua_State *L) {
}
static int lua_move_node(lua_State *L) {
}
