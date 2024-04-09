#include <emscripten.h>
#include <stdio.h>
#include <stdlib.h>
#include<string.h>
#include <assert.h>

// for access() to check if file exists from uploaded game
#include<unistd.h>

#include "lua_api.h"
#include "game_api.h"
#include "game_api_utils.h"
#include "alexgames_config.h"

#include "saved_state_db_c_api.h"
#include "utils/str_eq_literal.h"
#include "history_browse_ui.h"
#include "emscripten_dict_api.h"

// TODO make a proper header for this
extern const struct game_api *get_stick_api();

static void *g_db_state_handler = NULL;
static char g_game_id[64];


extern const struct game_api_callbacks api_callbacks;

#if 0
void *init_lua_api(const struct game_api_callbacks *api_arg, const char *game_str, int game_str_len) {
	return game_api->init_lua_api(api_arg, game_str, game_str_len);
}
#endif

EMSCRIPTEN_KEEPALIVE
int get_game_count() {
	return alex_get_game_count();
}

EMSCRIPTEN_KEEPALIVE
const char *get_game_name(int idx) {
	return alex_get_game_name(idx);
}

EMSCRIPTEN_KEEPALIVE
void start_game(void *L, int session_id, const uint8_t *state, size_t state_len) {
	if (!game_api->start_game) {
		alex_log_err_user_visible(&api_callbacks, "start_game function not defined!");
		return;
	}
	game_api->start_game(L, session_id, state, state_len);
}

	
EMSCRIPTEN_KEEPALIVE
void update(void *L, int dt_ms) {
	game_api->update(L, dt_ms);
}

EMSCRIPTEN_KEEPALIVE
void handle_user_string_input(void *L, char *user_line, int str_len, bool is_cancelled) {
	game_api->handle_user_string_input(L, user_line, str_len, is_cancelled);
}

EMSCRIPTEN_KEEPALIVE
void handle_user_clicked(void *L, int pos_y, int pos_x) {
	game_api->handle_user_clicked(L, pos_y, pos_x);
}

EMSCRIPTEN_KEEPALIVE
void handle_mousemove(void *L, int pos_y, int pos_x, int buttons) {
	game_api->handle_mousemove(L, pos_y, pos_x, buttons);
}

EMSCRIPTEN_KEEPALIVE
void handle_mouse_evt(void *L, int mouse_evt_id, int pos_y, int pos_x, int buttons) {
	game_api->handle_mouse_evt(L, mouse_evt_id, pos_y, pos_x, buttons);
}

EMSCRIPTEN_KEEPALIVE
void handle_wheel_changed(void *L, int delta_y, int delta_x) {
	game_api->handle_wheel_changed(L, delta_y, delta_x);
}

EMSCRIPTEN_KEEPALIVE
bool handle_key_evt(void *L, const char *evt_id, const char *key_code) {
	return game_api->handle_key_evt(L, evt_id, key_code);
}

EMSCRIPTEN_KEEPALIVE
void handle_touch_evt(void *L,
                      const char *evt_id_str, int evt_id_str_len, 
                      void *changed_touches, int changed_touches_len) {
	game_api->handle_touch_evt(L,
	                           evt_id_str, evt_id_str_len,
	                           changed_touches, changed_touches_len);
}
	
EMSCRIPTEN_KEEPALIVE
void handle_msg_received(void *L, const char *msg_src, int msg_src_len, const char *msg, int len) {
	game_api->handle_msg_received(L, msg_src, msg_src_len, msg, len);
}

EMSCRIPTEN_KEEPALIVE
void handle_btn_clicked(void *L, const char *btn_id) {
	game_api->handle_btn_clicked(L, btn_id);
}

EMSCRIPTEN_KEEPALIVE
void handle_popup_btn_clicked(void *L, const char *popup_id, int btn_idx, const struct popup_state *popup_state) {
	game_api->handle_popup_btn_clicked(L, popup_id, btn_idx, popup_state);
}

EMSCRIPTEN_KEEPALIVE
void handle_game_option_evt(void *L, int option_type, const char *option_id, int value) {
	game_api->handle_game_option_evt(L, option_type, option_id, value);
}

size_t call_get_state_func_b64(size_t (*get_state_func)(void *, uint8_t *, size_t), void *L, uint8_t *state_out, size_t state_out_len) {

	if (get_state_func == NULL) {
		return 0;
	}

	const size_t tmp_buff_size = 64*1024;
	uint8_t *tmp_buff = malloc(tmp_buff_size);

	// TODO can this longjmp (on game error) and not call my `free` below? ...
	// I think I'm always calling the error handler one, so probably not.
	size_t tmp_buff_filled_len = get_state_func(L, tmp_buff, tmp_buff_size);
	
	size_t b64_data_len = write_b64((char *)state_out, state_out_len, tmp_buff, tmp_buff_filled_len);
	free(tmp_buff);

#if DEBUG
	// check that the base 64 decoded result is the same as the raw data that we base64 encoded
	printf("raw state     (%3zu bytes): ", tmp_buff_filled_len);
	for (int i=0; i<tmp_buff_filled_len; i++) { printf("%02x ", tmp_buff[i]); }
	printf("\n");

	printf("b64 enc state (%3zu bytes): ", b64_data_len);
	for (int i=0; i<b64_data_len; i++) { printf("%02x ", state_out[i]); }
	printf("\n");

	uint8_t *test_dec_buff = malloc(tmp_buff_size);
	size_t test_dec_b64_len = decode_b64(test_dec_buff, tmp_buff_size, (char*)state_out, b64_data_len);
	printf("%s: received raw state %zu bytes from game, enc to %zu b64 chars, test decoded to %zu bytes\n",
	       __func__, tmp_buff_filled_len, b64_data_len, test_dec_b64_len);

	printf("test dec raw state (%3zu bytes): ", test_dec_b64_len);
	for (int i=0; i<test_dec_b64_len; i++) { printf("%02x ", test_dec_buff[i]); }
	printf("\n");

	assert(test_dec_b64_len == tmp_buff_filled_len);
	assert(memcmp(tmp_buff, test_dec_buff, test_dec_b64_len) == 0);

	free(test_dec_buff);
#endif
	return b64_data_len;
}

EMSCRIPTEN_KEEPALIVE
void start_game_b64(void *L, int session_id, const char *state_b64, size_t state_b64_len) {
	alex_start_game_b64(game_api, &api_callbacks,
                        L,
                        session_id,
                        state_b64, state_b64_len);
}

EMSCRIPTEN_KEEPALIVE
size_t get_state(void *L, uint8_t *state_out, size_t state_out_len) {
	return call_get_state_func_b64(game_api->get_state, L, state_out, state_out_len);
}

EMSCRIPTEN_KEEPALIVE
size_t get_init_state(void *L, uint8_t *state_out, size_t state_out_len) {
	return call_get_state_func_b64(game_api->get_init_state, L, state_out, state_out_len);
}

EMSCRIPTEN_KEEPALIVE
void lua_run_cmd(void *L, const char *str, int string_len) {
	game_api->lua_run_cmd(L, str, string_len);
}

EMSCRIPTEN_KEEPALIVE
void destroy_game(void *L) {
	printf("destroy_game\n");
	game_api->destroy_game(L);
}


EMSCRIPTEN_KEEPALIVE
FILE *new_file(void *L, const char *fname) {
	return alex_new_file(L, fname);
}

EMSCRIPTEN_KEEPALIVE
void write_to_file(void *L, FILE *f, const uint8_t *data, size_t data_len) {
	return alex_write_to_file(L, f, data, data_len);
}

EMSCRIPTEN_KEEPALIVE
void close_file(void *L, FILE *f) {
	alex_close_file(L, f);
}

EMSCRIPTEN_KEEPALIVE
void dump_file(void *L, const char *fname) {
	alex_dump_file(L, fname);
}

#ifdef ENABLE_ZIP_UPLOAD
EMSCRIPTEN_KEEPALIVE
void unzip_file(void *L, const char *fname, const char *dst_name) {
	alex_unzip_file(L, fname, dst_name);
}
#endif

EM_JS(void, js_draw_graphic_raw, (const char *img_id_ptr, int y, int x, int width, int height, int angle_degrees, int flip_y, int flip_x, int brightness_percent, bool invert), {
	let img_id = UTF8ToString(img_id_ptr);
	let params = {
		"angle_degrees": angle_degrees,
		"flip_y":          !!flip_y,
		"flip_x":          !!flip_x,
		"brightness_percent": brightness_percent,
		"invert":          !!invert,
	};
	draw_graphic(gfx, img_id, y, x, width, height, params);
});

void js_draw_graphic(const char *img_id_ptr, int y, int x, int width, int height, const struct draw_graphic_params *params) {
	js_draw_graphic_raw(img_id_ptr, y, x, width, height, params->angle_degrees, params->flip_y, params->flip_x, params->brightness_percent,
	                    params->invert);
}


EM_JS(void, js_draw_text, (const char *text_ptr,   size_t text_len,
                           const char * colour_ptr, size_t colour_len,
                           int y, int x, int size, int align), {
	let text_str   = UTF8ToString(text_ptr,   text_len);
	let colour_str = UTF8ToString(colour_ptr, colour_len);
	draw_text(gfx, text_str, colour_str, y, x, size, align);
});

EM_JS(void, js_draw_line, (const char *colour_ptr, int line_size, int y1, int x1, int y2, int x2), {
	let colour = UTF8ToString(colour_ptr);
	draw_line(gfx, colour, line_size, y1, x1, y2, x2);
});


EM_JS(void, js_draw_rect, (const char *fill_colour_ptr, size_t fill_colour_len,
                           int y_start, int x_start,
                           int y_end, int x_end), {
	let fill_colour = UTF8ToString(fill_colour_ptr, fill_colour_len);
	draw_rect(gfx, fill_colour, y_start, x_start, y_end, x_end);
});

EM_JS(void, js_draw_triangle, (const char *fill_colour_ptr, size_t fill_colour_len,
                           int y1, int x1,
                           int y2, int x2,
                           int y3, int x3), {
	let fill_colour = UTF8ToString(fill_colour_ptr, fill_colour_len);
	draw_triangle(gfx, fill_colour, y1, x1, y2, x2, y3, x3);
});

EM_JS(void, js_draw_circle, (const char *fill_colour_ptr, size_t fill_colour_len,
                             const char *outline_colour_ptr, size_t outline_colour_len,
                            int y, int x, int radius, int outline_width), {
	let fill_colour    = UTF8ToString(fill_colour_ptr,    fill_colour_len);
	let outline_colour = UTF8ToString(outline_colour_ptr, outline_colour_len);
	
	draw_circle(gfx,
	            fill_colour, outline_colour,
	            y, x, radius, outline_width);
});



EM_JS(void, js_draw_clear, (), {
	draw_clear(gfx);
});

EM_JS(void, js_draw_refresh, (), {
	// Not needed on html version at the moment
});

EM_JS(void, js_send_message, (const char *dst_ptr, size_t dst_len, const char *msg_ptr, size_t msg_len), {
	let dst = UTF8ToString(dst_ptr, dst_len);

	// can't use the string API because msg_ptr may contain nulls
	//let msg = UTF8ToString(msg_ptr, len);
	let msg = new Array(msg_len);
	for (let i=0; i<msg_len; i++) {
		let signed_byte = getValue(msg_ptr + i, 'i8');
		if (signed_byte < 0) {
			unsigned_byte = 256 + signed_byte;
		} else {
			unsigned_byte = signed_byte;
		}
		msg[i] = unsigned_byte;
	}

	//console.log("sending message", msg);

	//console.log("sending message len ", msg.length, ", expected ", len, "message: ",  msg);
	send_message(dst, msg);
});

EM_JS(void, js_create_btn, (const char *btn_id_ptr, const char *btn_text_ptr, int weight), {
	let btn_id_str   = UTF8ToString(btn_id_ptr);
	let btn_text_str = UTF8ToString(btn_text_ptr);
	create_btn(gfx, btn_id_str, btn_text_str, weight);
});

EM_JS(void, js_set_btn_enabled, (const char *btn_id_ptr, bool enabled), {
	let btn_id_str   = UTF8ToString(btn_id_ptr);
	set_btn_enabled(gfx, btn_id_str, enabled);
});

EM_JS(void, js_set_btn_visible, (const char *btn_id_ptr, bool visible), {
	let btn_id_str   = UTF8ToString(btn_id_ptr);
	set_btn_visible(gfx, btn_id_str, visible);
});


EM_JS(void, js_show_popup_json, (const char *popup_id_ptr, size_t popup_id_str_len,
                            const char *info_json_ptr, size_t info_json_str_len), {
	let popup_id = UTF8ToString(popup_id_ptr, popup_id_str_len);
	let info_json_str = UTF8ToString(info_json_ptr, info_json_str_len);
	console.debug("popup info_json_str: ", info_json_str);
	let info = JSON.parse(info_json_str);
	console.log("Showping popup", info);
	show_popup(gfx, popup_id, info);
	
});


static void js_show_popup(void *L, const char *popup_id_ptr, size_t popup_id_str_len,
                          const struct popup_info *info) {
	char popup_info_json_str[10*1024];

	size_t json_str_len = popup_info_to_json_str(popup_info_json_str, sizeof(popup_info_json_str),
	                                             info);

	js_show_popup_json(popup_id_ptr, popup_id_str_len,
	                   popup_info_json_str, json_str_len);
}

EM_JS(void, js_add_game_option_json_str, (const char *option_id_ptr, const char *option_info, size_t option_info_len), {
	console.log("js_add_game_option_json_str");

	let option_id_str = UTF8ToString(option_id_ptr);

	let option_info_json_str = UTF8ToString(option_info, option_info_len);
	let option_info_json = JSON.parse(option_info_json_str);

	console.log("add_game_option", option_id_str, option_info_json);
	add_game_option(gfx, option_id_str, option_info_json);
});

void js_add_game_option(const char *option_id_ptr, const struct option_info *option_info) {
	char option_info_json_str[10*1024];
	size_t json_str_len = option_info_to_json_str(option_info_json_str,
	                                              sizeof(option_info_json_str),
	                                              option_info);

	js_add_game_option_json_str(option_id_ptr, option_info_json_str, json_str_len);
}

EM_JS(void, js_prompt_string, (const char *title, size_t title_len,
                               const char *msg,   size_t msg_len), {
	// TODO ... without wrapping this in a second set of braces, I was seeing
	// "duplicate title" errors, without even calling this method.
	// is all this code defined in some common place that shares scope? That seems wrong.
	{
		let title_str = UTF8ToString(title, title_len);
		let msg_str   = UTF8ToString(msg,   msg_len);

		prompt_string(gfx, title_str, msg_str);
	}
});

EM_JS(void, js_hide_popup, (), {
	hide_popup(gfx);
});

EM_JS(void, js_set_status_msg, (const char *msg_ptr, size_t msg_len), {
	let msg = UTF8ToString(msg_ptr, msg_len);
	set_status_msg(gfx, msg);
});

EM_JS(void, js_set_status_err, (const char *msg_ptr, size_t msg_len), {
	let msg = UTF8ToString(msg_ptr, msg_len);
	set_status_err(gfx, msg);
});

EM_JS(int, js_update_timer_ms, (int timer_period_ms), {
	return update_timer_period_ms(gfx, timer_period_ms);
});

EM_JS(void, js_delete_timer, (int handle), {
	delete_timer(gfx, handle);
});

// TODO should some day replace this with registering a callback for each event,
// rather than hardcoding the lua global function name
EM_JS(void, js_enable_evt, (const char *evt_id_ptr, size_t evt_id_len), {
	let evt_id = UTF8ToString(evt_id_ptr, evt_id_len);
	enable_event(evt_id);
});

EM_JS(void, js_disable_evt, (const char *evt_id_ptr, size_t evt_id_len), {
	let evt_id = UTF8ToString(evt_id_ptr, evt_id_len);
	disable_event(evt_id);
});

// TODO this seems to only return the last 32 bits of the time.
EM_JS(long, js_get_time_ms, (), {
	return alexgames_get_time_ms();
});

EM_JS(void, js_store_data, (void *L, const char *key_ptr, const uint8_t *val_ptr, size_t val_len), {
	let key_str = UTF8ToString(key_ptr);

	if (window.localStorage == null) {
		console.error("Can not store key ", key_str, ", localStorage is null");
		return;
	}
	/*
	let val_ary = new Array(val_len);
	for (let i=0; i<val_len; i++) {
		let signed_byte = getValue(val_ptr + i, 'i8');
		if (signed_byte < 0) {
			unsigned_byte = 256 + signed_byte;
		} else {
			unsigned_byte = signed_byte;
		}
		val_ary[i] = unsigned_byte;
	*/

	let val_js_str = "";
	for (let i=0; i<val_len; i++) {
		let signed_byte = getValue(val_ptr + i, 'i8');
		if (signed_byte < 0) {
			unsigned_byte = 256 + signed_byte;
		} else {
			unsigned_byte = signed_byte;
		}
		val_js_str += String.fromCharCode(unsigned_byte);
	}

	window.localStorage[key_str] = val_js_str;
});

EM_JS(size_t, js_read_stored_data, (void *L, const char *key_ptr, uint8_t *buff_out, size_t buff_max), {

	let key_str = UTF8ToString(key_ptr);

	if (window.localStorage == null) {
		console.error("window.localStorage == null, can not load stored_data key ", key_str);
		return -1;
	}

	let val = window.localStorage[key_str];
	//console.log("Received val: ", val);
	let rc;
	if (val === undefined) {
		rc = -1;
	} else {
		// the caller can supply a null pointer just to check if this data exists
		if (buff_out == 0) {
			return 1;
		}
		//rc = stringToUTF8(val, buff_out, buff_max);
		for (let i=0; i<val.length; i++) {
			if (i >= buff_max) {
				console.error("tried to read stored data > buff_max", val.length, buff_max);
				break;
			}
			setValue(buff_out + i, val.charCodeAt(i), 'i8');
			rc = i+1;
		}
	}
	return rc;
});

EM_JS(void, js_draw_extra_canvas, (const char *canvas_id_ptr, int y, int x, int width, int height), {
	let canvas_id_str = UTF8ToString(canvas_id_ptr);
	draw_extra_canvas(gfx, canvas_id_str, y, x, width, height);
});

EM_JS(void, js_new_extra_canvas, (const char *canvas_id), {
	let canvas_id_str = UTF8ToString(canvas_id);
	new_extra_canvas(gfx, canvas_id_str);
});
EM_JS(void, js_set_active_canvas, (const char *canvas_id), {
	let canvas_id_str = UTF8ToString(canvas_id);
	set_active_canvas(gfx, canvas_id_str);
});
EM_JS(void, js_delete_extra_canvases, (void), {
	delete_extra_canvases();
});

EM_JS(size_t, js_get_user_colour_pref, (char *colour_str_out, size_t max_colour_str_out_len), {
	let colour_pref_str_js = get_user_colour_pref();

	let i;
	for (i=0; i<colour_pref_str_js.length; i++) {
		if (i >= max_colour_str_out_len) {
			console.error("User colour pref str buff is not long enough");
			return -1;
		}
		setValue(colour_str_out + i, colour_pref_str_js.charCodeAt(i), 'i8');
	}
	setValue(colour_str_out + i, 0, 'i8');

	return colour_pref_str_js.length;
});

EM_JS(bool, js_is_feature_supported, (const char *feature_id, size_t feature_id_len), {
	// TODO:
	//   "draw_graphic_invert": figure out how to check if context.filter supports invert
	// or just return false on safari for now
	return false;
});

EM_JS(size_t, js_get_time_of_day, (char *time_str, size_t max_time_str_len), {
	let time_str_js = get_time_of_day();

	for (let i=0; i<time_str_js.length; i++) {
		if (i >= max_time_str_len) {
			console.error("Time string is not long enough");
			return -1;
		}
		setValue(time_str + i, time_str_js.charCodeAt(i), 'i8');
	}

	return time_str_js.length;
});

EM_JS(void, js_set_game_handle2, (const void *L, const char *game_id), {
	let game_id_str = UTF8ToString(game_id);
	set_game_handle(L, game_id_str);
});

void js_set_game_handle(const void *L, const char *game_id) {
	printf("emscripten_api.c: js_set_game_handle called with \"%s\"\n", game_id);
	// TODO this `g_game_id` global variable here is a hack, remove it
	// this caused a bad bug when starting a new game (solitaire) from a
	// solitaire game loaded from the history browser.
	snprintf(g_game_id, sizeof(g_game_id), "%s", game_id);
	js_set_game_handle2(L, game_id);
}

EM_JS(void, js_get_game_id, (const void *L, char *game_id_out, size_t game_id_out_len_max), {
	console.log("js_get_game_id called, returning gfx.game_id: ", gfx.game_id);
	write_str(game_id_out, game_id_out_len_max, gfx.game_id);
});

EM_JS(void, js_destroy_all, (void), {
	console.log("destroy_all called");
	destroy_all();
});

static int db_helper_get_new_session_id(void) {
	return saved_state_db_get_new_session_id(g_db_state_handler);
}

static int db_helper_get_last_session_id(const char *game_id) {
	return saved_state_db_get_last_session_id(g_db_state_handler, game_id);
}

static void db_helper_save_state(int session_id, const uint8_t *state, size_t state_len) {
	saved_state_db_save_state(g_db_state_handler, g_game_id, session_id, state, state_len);
}

static bool db_helper_has_saved_state_offset(int session_id, int move_id_offset) {
	return saved_state_db_has_saved_state_offset(g_db_state_handler, session_id, move_id_offset);
};

static int db_helper_get_saved_state_offset(int session_id, int move_id_offset, uint8_t *state, size_t state_len) {
	return saved_state_db_get_saved_state_offset(g_db_state_handler, session_id, move_id_offset, state, state_len);
}


const struct game_api_callbacks api_callbacks = {
	.set_game_handle = js_set_game_handle,
	.get_game_id = js_get_game_id,
	.draw_graphic = js_draw_graphic,
	.draw_line = js_draw_line,
	.draw_text = js_draw_text,
	.draw_rect = js_draw_rect,
	.draw_triangle = js_draw_triangle,
	.draw_circle = js_draw_circle,
	.draw_clear = js_draw_clear,
	.draw_refresh = js_draw_refresh,
	.send_message = js_send_message,
	.create_btn = js_create_btn,
	.set_btn_enabled = js_set_btn_enabled,
	.set_btn_visible = js_set_btn_visible,
	.hide_popup = js_hide_popup,
	.set_status_msg = js_set_status_msg,
	.set_status_err = js_set_status_err,
	//.show_popup_btns = js_show_popup,
	.show_popup = js_show_popup,
	.add_game_option = js_add_game_option,
	.prompt_string = js_prompt_string,
	.update_timer_ms = js_update_timer_ms,
	.delete_timer = js_delete_timer,
	.enable_evt = js_enable_evt,
	.disable_evt = js_disable_evt,
	.get_time_ms = js_get_time_ms,
	.get_time_of_day = js_get_time_of_day,
	.store_data  = js_store_data,
	.read_stored_data  = js_read_stored_data,
	.get_new_session_id = db_helper_get_new_session_id,
	.get_last_session_id = db_helper_get_last_session_id,
	.save_state         = db_helper_save_state,
	.has_saved_state_offset = db_helper_has_saved_state_offset,
	.get_saved_state_offset = db_helper_get_saved_state_offset,

	.draw_extra_canvas     = js_draw_extra_canvas,
	.new_extra_canvas      = js_new_extra_canvas,
	.set_active_canvas     = js_set_active_canvas,
	.delete_extra_canvases = js_delete_extra_canvases,
	.get_user_colour_pref  = js_get_user_colour_pref,
	.is_feature_supported  = js_is_feature_supported,

	.destroy_all           = js_destroy_all,
};

static void print_ver_info() {
	printf("AlexGames version %s, git hash = %s\n", PROJECT_VERSION, GIT_HEAD_HASH);
}

// Entry point from javascript
EMSCRIPTEN_KEEPALIVE
void *init_game_api(const char *game_str, int game_str_len) {
	printf("[init] emscripten_api.c: init_game_api called\n");
	snprintf(g_game_id, sizeof(g_game_id), "%s", game_str);

	set_game_dict_api(get_emscripten_game_dict_api());

	g_db_state_handler = saved_state_db_init(NULL, &api_callbacks);

	void *handle = alex_init_game(&api_callbacks, game_str, game_str_len);

	print_ver_info();
	return handle;
}

#if 0
// If you don't provide a main function, then it looks like the Lua main takes over
// and starts prompting for text via stdin, which causes a big popup in a browser.
// Though I don't actually know CMake allows for multiple main definitions like this.
int main(void) {
	print_ver_info();
}
#endif
