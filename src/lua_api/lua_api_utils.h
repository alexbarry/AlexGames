#include<stdbool.h>

float lua_get_int_or_float_func(void *L, int stack_idx, const char *field_name, bool nil_ok, const char *func_name);

#define lua_get_int_or_float(L, stack_idx, field_name) \
	lua_get_int_or_float_func(L, stack_idx, field_name, false, __func__)

#define lua_get_int_or_float_or_nil(L, stack_idx, field_name) \
	lua_get_int_or_float_func(L, stack_idx, field_name, true, __func__)
