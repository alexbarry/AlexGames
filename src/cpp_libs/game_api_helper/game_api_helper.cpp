
#include "game_api_helper.h"

void set_game_handle(const void *L, const char *game_id) {}
void get_game_id(const void *L, char *game_id_out, size_t game_id_out_len_max) {}
void set_canvas_size(int width, int height) {}
static void draw_graphic(const char *img_id,
                  int y, int x,
                  int width, int height,
                  const struct draw_graphic_params *params) {}
static void draw_line(const char *colour_str, int line_size, int y1, int x1, int y2, int x2) {}
static void draw_text(const char *text_str, size_t text_str_len,
                  const char *colour_str, size_t colour_str_len,
                  int y, int x, int size, int align) {}
static void draw_rect(const char *fill_colour_str, size_t fill_colour_len,
                  int y_start, int x_start,
                  int y_end  , int x_end) {}
static void draw_triangle(const char *fill_colour_str, size_t fill_colour_len,
                          int y1, int x1,
                          int y2, int x2,
                          int y3, int x3) {}
static void draw_circle(const char *fill_colour_str,    size_t fill_colour_len,
                    const char *outline_colour_str, size_t outline_colour_len,
                    int y, int x, int radius, int outline_width) {}

static void draw_clear(void) {}
static void draw_refresh(void) {}
static void send_message(const char *dst, size_t dst_len, const char *msg, size_t msg_len) {}
static void create_btn(const char *btn_id_str, const char *btn_text_str, int weight) {}
static void set_btn_enabled(const char *btn_id_str, bool enabled) {}
static void set_btn_visible(const char *btn_id_str, bool visible) {}
static void hide_popup(void) {}
static void set_status_msg(const char *msg, size_t msg_len) {}
static void set_status_err(const char *msg, size_t msg_len) {}
static void show_popup(void *L, const char *popup_id, size_t popup_id_str_len,
                       const struct popup_info *info) {}
//static void show_popup_btns(const char *popup_id, size_t popup_id_str_len,
//                            const char *title, size_t title_len,
//                            const char *msg, size_t msg_len,
//                            const char * const *btn_str_ary, size_t ary_len) {}
static void prompt_string(const char *prompt_title, size_t prompt_title_len,
	                      const char *prompt_msg,   size_t prompt_msg_len) {};
static void add_game_option(const char *option_id, const struct option_info *option_info) {}
static int update_timer_ms(int update_period_ms) { return 0; }
static void delete_timer(int handle) {}
static void enable_evt(const char *evt_id_str, size_t evt_id_len) {}
static void disable_evt(const char *evt_id_str, size_t evt_id_len) {}
static time_ms_t get_time_ms(void) { return 0; }
static size_t get_time_of_day(char *time_str, size_t max_time_str_len) { return 0; }

static void store_data(void *L, const char *key, const uint8_t *value, size_t value_len) {}
static size_t read_stored_data(void *L, const char *key, uint8_t *value_out, size_t max_val_len) { return -1; }


static int get_new_session_id(void) { return 0; }
static int get_last_session_id(const char *game_id) { return 0; }
static void save_state(int session_id, const uint8_t *state, size_t state_len) {}
static bool has_saved_state_offset(int session_id, int move_id_offset) { return false; }
static int adjust_saved_state_offset(int session_id, int move_id_offset, uint8_t *state, size_t state_len) { return 0; }


static void draw_extra_canvas(const char *img_id,
                          int y, int x,
                          int width, int height) {}
static void new_extra_canvas(const char *canvas_id) {}

static void set_active_canvas(const char *canvas_id) {}

static void delete_extra_canvases(void) {}

static size_t get_user_colour_pref(char *colour_pref_out, size_t max_colour_pref_out_len) {
	return snprintf(colour_pref_out, max_colour_pref_out_len, "");
}
static size_t get_multiplayer_session_id(char *colour_pref_out, size_t max_colour_pref_out_len) {
	return snprintf(colour_pref_out, max_colour_pref_out_len, "");
}
static bool is_multiplayer_session_id_needed() {
	return true;
}
static bool is_feature_supported(const char *feature_id, size_t feature_id_len) {
	return false;
}

static void destroy_all(void) {}


struct game_api_callbacks create_default_callbacks(void) {
	const struct game_api_callbacks callbacks = {
	set_game_handle,
	get_game_id,
    set_canvas_size,
		/* .draw_graphic           = */ draw_graphic,
		/* .draw_line              = */ draw_line,
		/* .draw_text              = */ draw_text,
		/* .draw_rect              = */ draw_rect,
		/* .draw_triangle          = */ draw_triangle,
		/* .draw_circle            = */ draw_circle,
		/* .draw_clear             = */ draw_clear,
		/* .draw_refresh           = */ draw_refresh,
		/* .send_message           = */ send_message,
		/* .create_btn             = */ create_btn,
		/* .set_btn_enabled        = */ set_btn_enabled,
		/* .set_btn_visible        = */ set_btn_visible,
		/* .hide_popup             = */ hide_popup,
		/* .add_game_option        = */ add_game_option,
		/* .set_status_msg         = */ set_status_msg,
		/* .set_status_err         = */ set_status_err,
		/* .show_popup             = */ show_popup,
		/* .prompt_string          = */ prompt_string,
		/* .update_timer_ms        = */ update_timer_ms,
		/* .delete_timer           = */ delete_timer,
		/* .enable_evt             = */ enable_evt,
		/* .disable_evt            = */ disable_evt,
		/* .get_time_ms            = */ get_time_ms,
		/* .get_time_of_day        = */ get_time_of_day,
		/* .store_data             = */ store_data,
		/* .read_stored_data       = */ read_stored_data,
		/* .get_new_session_id     = */ get_new_session_id,
		/* .get_last_session_id    = */ get_last_session_id,
		/* .save_state             = */ save_state,
		/* .has_saved_state_offset = */ has_saved_state_offset,
		/* .adjust_saved_state_offset = */ adjust_saved_state_offset,
		/* .draw_extra_canvas      = */ draw_extra_canvas,
		/* .new_extra_canvas       = */ new_extra_canvas,
		/* .set_active_canvas      = */ set_active_canvas,
		/* .delete_extra_canvases  = */ delete_extra_canvases,
		/* .get_user_colour_pref   = */ get_user_colour_pref,
		/* .is_multiplayer_session_id_needed = */ is_multiplayer_session_id_needed,
		/* .get_multiplayer_session_id = */ get_multiplayer_session_id,
		/* .is_feature_supported   = */ is_feature_supported,
		/* .destroy_all            = */ destroy_all,
	};
	return callbacks;
}
