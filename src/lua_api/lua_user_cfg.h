int luaopen_alexlib(lua_State *L);

// If I understand correctly, this is needed to include
// the library in the command line lua interpreter.
// But calling luaL_requiref(L, "alex_c_api", luaopen_alexlib, 0) 
// is enough
//#define LUA_EXTRALIBS { "alex_c_api", luaopen_alexlib },
