
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include<stdbool.h>

float lua_get_int_or_float_func(void *L, int stack_idx, const char *field_name, bool nil_ok, const char *func_name) {
	// So at first I thought that Lua treated floats and integers separately.
	// Now I see that they don't, and really I should just call tonumberx instead of tointegerx.
	// I had originally just called tointegerx, then later added tonumberx.

	if (lua_gettop(L) < stack_idx) {
		if (nil_ok) {
			return 0;
		} else {
			luaL_error(L, "%s: expected stack idx %d to contain field %s, but top was %d", __func__, stack_idx, field_name, lua_gettop(L));
		}
	}

	if (lua_type(L, stack_idx) == LUA_TNIL) {
		if (nil_ok) {
			return 0;
		} else {
			luaL_error(L, "%s: param %s is nil", func_name, field_name);
		}
	}

	{
		int is_int = 0;
		lua_Integer val_int = lua_tointegerx(L, stack_idx, &is_int);
		if (is_int) {
			return val_int;
		}
	}

	{
		int is_float = 0;
		lua_Number val_float = lua_tonumberx(L, stack_idx, &is_float);
		if (is_float) {
			return val_float;
		}
	}

	luaL_error(L, "%s: could not convert %s to Lua number or int", func_name, field_name);
	return 0;
}
