int luaopen_alexlib(lua_State *L);

// If I understand correctly, this is needed to include
// the library in the command line lua interpreter.
// But calling luaL_requiref(L, "alexgames", luaopen_alexlib, 0) 
// is enough
//#define LUA_EXTRALIBS { "alexgames", luaopen_alexlib },
