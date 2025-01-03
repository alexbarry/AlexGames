#include<stdbool.h>

float lua_get_int_or_float_func(void *L, int stack_idx, const char *field_name, bool nil_ok, const char *func_name);

#define lua_get_int_or_float(L, stack_idx, field_name) \
	lua_get_int_or_float_func(L, stack_idx, field_name, false, __func__)

#define lua_get_int_or_float_or_nil(L, stack_idx, field_name) \
	lua_get_int_or_float_func(L, stack_idx, field_name, true, __func__)

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

void lua_push_error_handler(void *L);
int pcall_handle_error(void *L, int nargs, int nresults);
void lua_pop_error_handler(void *L);
void dump_lua_stack(struct lua_State *L);
void handle_lua_err(void *L);



extern const struct game_api_callbacks *api;
