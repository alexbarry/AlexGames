#include<stdbool.h>
#include<stdint.h>
#include<stddef.h>
#include<stdarg.h>
#include<stdio.h>

#ifndef GAME_API_H_
#define GAME_API_H_

#ifdef __cplusplus
extern "C" {
#endif

#define MOUSE_EVT_LEAVE (3)
#define MOUSE_EVT_DOWN      (2) // primary   mouse button (usually left)    down
#define MOUSE_EVT_UP        (1) // primary   mouse button (usually left)    up
// Note these are only sent if `enable_evt("mouse_alt_evt")` is called.
#define MOUSE_EVT_ALT_DOWN  (4) // secondary mouse button (usually right)   down
#define MOUSE_EVT_ALT_UP    (5) // secondary mouse button (usually right)   up
#define MOUSE_EVT_ALT2_DOWN (6) // third     mouse button (usually middle?) down
#define MOUSE_EVT_ALT2_UP   (7) // third     mouse button (usually middle?) up

#define TEXT_ALIGN_LEFT    (1)
#define TEXT_ALIGN_CENTRE  (0)
#define TEXT_ALIGN_CENTER  (TEXT_ALIGN_CENTRE)
#define TEXT_ALIGN_RIGHT  (-1)

#define GAME_UPLOAD_PATH "/upload/game1"

#define GAME_ID_UPLOADED "upload"

#define MAX_POPUP_TITLE_LEN      (128)
#define MAX_POPUP_MSG_LEN       (4096)
#define MAX_POPUP_BTN_TEXT_LEN   (256)
#define MAX_POPUP_DROPDOWN_LABEL (256)

#define MAX_POPUP_DRODOWN_OPTION_COUNT  (16)
#define MAX_POPUP_DROPDOWN_OPTION_LEN  (128)

#define MAX_POPUP_ITEMS       (64)


typedef int64_t touch_id_t;

//typedef uint64_t time_ms_t;
//typedef uint64_t time_ms_t;
// TODO when rust adds a wasm64-unknown-emscripten target,
// I think I can change this to uint64_t
typedef uint32_t time_ms_t;

struct touch_info {
	// TODO should make sure these aren't packed?
	touch_id_t id;
	double   y;
	double   x;
};

struct draw_graphic_params {
	int angle_degrees;

	/* flip graphic's y values, flipping across the x axis in the middle */
	bool flip_y;

	/* flip graphic's x values, flipping across the y axis in the middle */
	bool flip_x;

	/* dammit, this one isn't supported by Safari either. Maybe I should just
	 * loop through pixels and do some math, and just warn game authors to only
	 * use these for board games.
	 * 
	 * My only purpose for adding these was to support some dark/darker modes without
	 * adding new images. So if that's all others would use them for, then it's fine
	 * if this is a bit inefficient.
	 */
	int brightness_percent;

	/**
	 * (NOT READY YET) Invert image. Applied before brightness.
	 *
	 * Note: For HTML, this is achieved as CSS filter's "invert":
	 *           https://developer.mozilla.org/en-US/docs/Web/CSS/filter#invert
	 *       Which does not appear to be supported on Safari as of 2023-02-11.
	 *       So unfortunately you should just invert your images manually and include
	 *       a second copy for now.
	 *       It's easily achieved with a package like "imagemagic" via the command line:
	 *
	 *           convert your_image.png -channel RGB -negate output_inverted_image.png
	 *
	 * Plausibly this could be achieved on Safari by looping through each pixel and
	 * inverting them in Javascript, but that seems like it might be really inefficient
	 * for games that draw at ~60 frames per second.
	 */
	bool invert;
};


enum popup_item_type {
	POPUP_ITEM_TYPE_MSG = 1,
	POPUP_ITEM_TYPE_BTN,
	POPUP_ITEM_TYPE_DROPDOWN,
};

struct popup_item_info_msg {
	char msg[MAX_POPUP_MSG_LEN];
};

struct popup_item_info_btn {
	int  id;
	char text[MAX_POPUP_BTN_TEXT_LEN];
};

struct popup_item_info_dropdown {
	int  id;
	char label[MAX_POPUP_DROPDOWN_LABEL];
	int  option_count;
	char options[MAX_POPUP_DRODOWN_OPTION_COUNT][MAX_POPUP_DROPDOWN_OPTION_LEN];
};

union popup_item_info {
	struct popup_item_info_msg      msg;
	struct popup_item_info_btn      btn;
	struct popup_item_info_dropdown dropdown;
};

struct popup_item {
	enum  popup_item_type type;
	union popup_item_info info;
};

struct popup_info {
	char               title[MAX_POPUP_TITLE_LEN];
	int                item_count;
	struct popup_item  items[MAX_POPUP_ITEMS];
};

struct popup_state_item {
	uint32_t id;
	uint32_t selected;
};

/**
 * State of popup, sent to game API when popup button is clicked.
 * 
 * e.g. contains dropdown states
 */
struct popup_state {
	uint32_t items_count;
	struct popup_state_item items[MAX_POPUP_ITEMS];
};

enum option_type {
	OPTION_TYPE_BTN = 1,
	OPTION_TYPE_TOGGLE,
	// maybe add toggle buttons, dropdowns, maybe even text input?
};

struct option_info {
	enum option_type option_type;
	char label[MAX_POPUP_BTN_TEXT_LEN];
	/* only for OPTION_TYPE_TOGGLE */
	int value;
};

struct draw_graphic_params default_draw_graphic_params(void);

struct popup_info empty_popup_info(void);
void popup_info_add_button(struct popup_info *info, int btn_id, const char *btn_text);

struct game_api_callbacks {

	/**
	 * Called when a new game is selected (e.g. from history browser).
	 * This is basically what `init_lua_api` returns.
	 * TODO: consider replacing init_lua_api's return code with something like this.
	 */
	void (*set_game_handle)(const void *L, const char *game_id);
	void (*get_game_id)(const void *L, char *game_id_out, size_t game_id_out_len_max);

	/**
	 * Sets the game canvas size ratio.
	 *
	 * Note that in the web implementation the canvas is automatically scaled up to
	 * take up as much of the screen as possible, but maintaining the ratio.
	 */
	void (*set_canvas_size)(int width, int height);

	void (*draw_graphic)(const char *img_id,
	                     int y, int x,
	                     int width, int height,
	                     const struct draw_graphic_params *params);
	void (*draw_line)(const char *colour_str, int line_size, int y1, int x1, int y2, int x2);
	void (*draw_text)(const char *text_str, size_t text_str_len,
	                  const char *colour_str, size_t colour_str_len,
	                  int y, int x, int size, int align);
	void (*draw_rect)(const char *fill_colour_str, size_t fill_colour_len,
	                  int y_start, int x_start,
	                  int y_end  , int x_end);
	void (*draw_triangle)(const char *fill_colour_str, size_t fill_colour_len,
	                      int y1, int x1,
	                      int y2, int x2,
	                      int y3, int x3);
	void (*draw_circle)(const char *fill_colour_str,    size_t fill_colour_len,
	                    const char *outline_colour_str, size_t outline_colour_len,
	                    int y, int x, int radius, int outline_width);
	void (*draw_clear)(void);
	void (*draw_refresh)(void);
	void (*send_message)(const char *dst, size_t dst_len, const char *msg, size_t msg_len);
	void (*create_btn)(const char *btn_id_str, const char *btn_text_str, int weight);
	void (*set_btn_enabled)(const char *btn_id_str, bool enabled);
	void (*set_btn_visible)(const char *btn_id_str, bool visible);
	void (*hide_popup)(void);
	void (*add_game_option)(const char *option_id, const struct option_info *info);
	void (*set_status_msg)(const char *msg, size_t msg_len);
	void (*set_status_err)(const char *msg, size_t msg_len);
/*
	void (*show_popup_btns)(const char *popup_id, size_t popup_id_str_len,
	                  const char *title, size_t title_len,
	                  const char *msg, size_t msg_len,
	                  const char * const *btn_str_ary, size_t ary_len);
*/
	
	void (*show_popup)(void *L,
	                   const char *popup_id, size_t popup_id_str_len,
	                   const struct popup_info *info);
	/**
	 * Prompt the user to enter a string.
	 *
	 * On mobile, this shows a `div` with an `input` element and calls `.focus()`
	 * on it. This seems to result in different behaviour depending on where you call
	 * this from, on mobile. In both cases a popup is shown, but:
	 *     * if you call it from a user click event, the virtual keyboard is brought up
	 *     * but if you call it from elsewhere (e.g. init), the virtual keyboard is not
	 *       brought up.
	 *
	 * Generally this should be fine, it's possible that users would often prefer this
	 * behaviour.
	 *
	 * TODO: add an "id" to this, so that the game code doesn't need to add state to
	 *       figure out what string this is, and when the UI closes, etc.
	 */
	void (*prompt_string)(const char *prompt_title, size_t prompt_title_len,
	                      const char *prompt_msg,   size_t prompt_msg_len);

	/**
	 * Set a timer to call `update` every `update_period_ms` milliseconds.
	 *
	 * Returns a handle pointing to the timer. Pass this to `delete_timer` to
	 * stop it.
	 *
	 * I don't see why most games would need to ever set more than one concurrent timer.
	 * I did add support for this for the case where I had two separate animations which could
	 * either end at different times (and cancel their timer).
	 * But instead of actually having separate timers, I think it would be better to use a single
	 * timer and have multiple clients registering to use it.
	 */
	int (*update_timer_ms)(int update_period_ms);

	/**
	 * Deletes a timer by handle (returned by `update_timer_ms`).
	 * 
	 * Should cause a user-visible error if the timer was not found.
	 */
	void (*delete_timer)(int handle);
	void (*enable_evt)(const char *evt_id_str, size_t evt_id_len);
	void (*disable_evt)(const char *evt_id_str, size_t evt_id_len);
	// TODO change the return type of `get_time_ms` to `unsigned long` or whatever
	// time usually is.
	time_ms_t (*get_time_ms)(void);
	size_t (*get_time_of_day)(char *time_str, size_t max_time_str_len);
	void (*store_data)(void *L, const char *key, const uint8_t *value, size_t value_len);

	/**
	 * Read stored data from persistent storage.
	 *
	 * Note that value_out may be NULL, in which case this callback should only return
	 * a value greater than zero if the data exists, otherwise return zero.
	 */
	size_t (*read_stored_data)(void *L, const char *key, uint8_t *value_out, size_t max_val_len);

	/**
	 * Gets a new session ID, usually when the player is starting a new game.
	 * This lets the game code store the game's state in the database, and
	 * any new moves in that game will be stored together.
	 */
	int  (*get_new_session_id)(void);

	/**
	 * Gets the last session ID for the current game.
	 * This is useful for loading the last saved game if the
	 * user selects this game without loading it from the
	 * history browser.
	 */
	int  (*get_last_session_id)(const char *game_id);

	/**
	 * Saves state in a state database, so the player can browse old states
	 * to play game sessions that they didn't finish with.
	 *
	 * Should be called regularly by the game, whenever the game state changes in a
	 * significant way. (e.g. once per move in most board games)
	 */
	void (*save_state)(int session_id, const uint8_t *state, size_t state_len);

	/**
	 * Checks if there is state saved in the state database at move ID equal to
	 * current move plus `move_id_offset`.
	 *
	 * Meant to be used as part of providing "undo" and "redo" buttons, to decide
	 * when to disable them. ("undo" would be `move_id_offset` -1, "redo" would be 1)
	 */
	bool (*has_saved_state_offset)(int session_id, int move_id_offset);

	/**
	 * Reads saved state from current move ID plus move_id_offset,
	 * and adjusts the current move ID by `move_id_offset`.
	 *
	 * Meant to be used as part of providing "undo" and "redo" buttons. ("undo" would
	 * be move_id_offset -1, "redo" would be 1), and also for loading the last
	 * saved state when a game first starts.
	 *
	 * Returns number of bytes actually read. Returns a negative number if an
	 * error occurred.
	 *
	 * TODO: this could possibly be handled by the game platform itself, passing the last
	 *       saved state as a param to `start_game` instead.
	 *       Then each game wouldn't need to implement the slightly clunky behaviour of both
	 *       checking if state was passed to `start_game`, and then calling this API
	 *       to load previously saved state.
	 */
	int (*adjust_saved_state_offset)(int session_id, int move_id_offset, uint8_t *state, size_t state_len);

	/** Draws one of the extra canvases on the active canvas */
	void (*draw_extra_canvas)(const char *img_id,
	                          int y, int x,
	                          int width, int height);
	void (*new_extra_canvas)(const char *canvas_id);

	/**
	 * Sets the active canvas. Pass an empty string to restore the main (user visible) canvas.
	 * All draw APIs will draw on this canvas until `set_active_canvas` is called again.
	 */
	void (*set_active_canvas)(const char *canvas_id);

	void (*delete_extra_canvases)(void);

	size_t (*get_user_colour_pref)(char *colour_pref_out, size_t max_colour_pref_out_len);

	bool (*is_feature_supported)(const char *feature_id, size_t feature_id_len);

	/**
	 * Called when game is being cleaned up.
	 * Host must clean up everything that the game created: 
	 *     - destroy all buttons that were created
	 *     - delete any set timers
	 *
	 * I'm not sure yet if the game or the host should:
	 *     - call draw_clear() and draw_commit()
	 *     - call delete_extra_canvases()
	 *     - call hide_popup()
	 *
	 * The intention here is that game init could be called again, and there wouldn't
	 * be anything lingering from the previous game.
	 */
	void (*destroy_all)(void);
};


typedef void (*log_func_t)(const char *format, va_list args);

void set_alex_log_func(log_func_t log_func);
void set_alex_log_err_func(log_func_t log_func);

void alex_log(const char *format, ...);
void alex_log_err_va(const char *format, va_list va_args);
void alex_log_err(const char *format, ...);

void alex_log_err_user_visible(const struct game_api_callbacks *api, const char *format, ...);

struct game_api {
	/**
	 * Returns a handle that must be passed to the rest of these APIs.
	 */
	void* (*init_lua_api)(const struct game_api_callbacks *api_arg, const char *game_str, int game_str_len);

	void (*destroy_game)(void *L);

	
	/**
	 * Called to re-draw the board, or indicate the passage of time if
	 * a timer was set with `update_timer_ms`.
	 */
	void (*update)(void *L, int dt_ms);

	/**
	 * User enters a string.
	 *
	 * Currently only possible in web client after calling `prompt_string`, but in the future
	 * it seems nice to support this for keyboard only / command line style interfaces.
	 *
	 * e.g. For a board game like chess or go, allowing the user to never need to use the mouse
	 * would be nice, simply accepting row and column input as a string.
	 * I think this could even live side by side many games by default. Would be nice to encourage
	 * support of this API so that games could more easily be converted to command-line only interfaces,
	 * to be run outside the web client.
	 */
	void (*handle_user_string_input)(void *L, char *user_line, int str_len, bool is_cancelled);

	void (*handle_user_clicked)(void *L, int pos_y, int pos_x);
	void (*handle_mousemove)(void *L, int pos_y, int pos_x, int buttons);
	void (*handle_mouse_evt)(void *L, int mouse_evt_id, int pos_y, int pos_x, int buttons);
	void (*handle_wheel_changed)(void *L, int delta_y, int delta_x);

	/**
	 * User presses or releases a key.
	 *
	 * - evt_id   is "keyup" or "keydown", since that is the name of these events in HTML/JS.
	 * - key_code is compatible with HTML, e.g. "KeyA" for the A key, and "ArrowUp" for the up arrow.
	 *            See https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_code_values
	 *            However, some clients (e.g. wxWidgets) don't seem to be able to distinguish between certain 
	 *            keys, like left and right shift/control/alt.
	 *            At some point I plan on perhaps translating from "ShiftRight" to "ShiftLeft" or just "Shift",
	 *            so that games don't rely on behaviour that can't be easily supported by all platforms.
	 *
	 * return: true if the game does handle the key, false otherwise. This tells the client whether or not they should
	 *         handle it, e.g. if the user pressed a button to refresh their browser or open developer tools.
	 *         I personally don't think games should override any keys that usually correspond to browser meta actions,
	 *         unless it's a safety feature so the user doesn't accidentally refresh and lose their state.
	 *         But for that case, the game client should do it (e.g. the HTML page), and it should be configurable.
	 *         I may consider preventing games from getting these keys at all in the future, or at least from telling the browser
	 *         not to handle them.
	 *
	 * NOTE: be careful not to return false for the case of ignoring duplicate key presses.
	 *       If you hold the "up" or "down" arrow keys on a browser, after a second or so, they get repeated.
	 *       At some point in a game I wrote, I had added a check to `return false` if a duplicate key
	 *       event was sent. But then this meant the browser would not call `evt.preventDefault()` for these
	 *       duplicate arrow key preses, which caused the browser to scroll. This is generally not what you
	 *       want in a game where you use the arrow keys to move the player.
	 */
	bool (*handle_key_evt)(void *L, const char *evt_id, const char *key_code);
	void (*handle_touch_evt)(void *L,
	                         const char *evt_id_str, int evt_id_str_len, 
	                         void *changed_touches, int changed_touches_len);
	
	void (*handle_msg_received)(void *L, const char *msg_src, int msg_src_len, const char *msg, int len);
	void (*handle_btn_clicked)(void *L, const char *btn_id);
	void (*handle_popup_btn_clicked)(void *L, const char *popup_id, int btn_idx, const struct popup_state *popup_state);

	void (*handle_game_option_evt)(void *L, enum option_type option_type, const char *option_id, int value);

	/**
	 * Main entry point for games, either new or loaded from history (or URL param).
	 *
	 * Do anything in here that should be done when a player opens the game (e.g. start a new game
	 * if `saved_state` param is NULL, or load saved state if your game does not support the 
	 * normal saved state API, initialize buttons and events).
	 *
	 * session_id: Identifies which game session this is.
	 *             Games should only use this when calling the `save_state` APIs,
	 *             to tell the history browser which saved state to update.
	 *
	 * state:      serialized save state. Will be NULL if this is a new game, or
	 *             set if the game is loaded from the history browser or URL param.
	 * state_len:  length of `state` param in bytes.
	 *
	 */
	void (*start_game)(void *L, int session_id, const uint8_t *state, size_t state_len);

	/**
	 * Gets the current state of the game. Used to share the current game state
	 * via URL.
	 */
	size_t (*get_state)(void *L, uint8_t *state_out, size_t state_out_len);

	/**
	 * Gets the initial state of the game. Used to share via URL, so that
	 * if you enjoyed a randomly generated puzzle, you can share it with
	 * a friend (better to share the initial puzzle rather than the filled in one)
	 */
	size_t (*get_init_state)(void *L, uint8_t *state_out, size_t state_out_len);

	/** Should only be used for debugging */
	void (*lua_run_cmd)(void *L, const char *str, int string_len);
};

int alex_get_game_count();
const char *alex_get_game_name(int idx);

void alex_set_root_dir(const char *root_dir);
// TODO put internal functions like this in a separate header.
// need to distinguish between "functions called by lua_api.c" and
// "functions called by platform (wasm/wxWidgets/Android)
int alex_get_root_dir(char *scripts_dir_out, size_t scripts_dir_out_len);


void alex_set_status_err_vargs(const struct game_api_callbacks *api_callbacks, const char *format, ...);

// Called after selecting a game, to determine what APIs
// the platform's calls are passed to (e.g. either Lua,
// or a C++ game's custom handlers)
void set_game_api(const struct game_api *game_api_arg);

// Common entry point. Each platform's implementation of game_api.h
// must call this from their own initialization routine, passing
// callbacks to do things on their platform (e.g. draw graphics, send message)
void *alex_init_game(const struct game_api_callbacks *api_callbacks_arg,
                     const char *game_str, int game_str_len);

// TODO move this to a utils file
size_t popup_info_to_json_str_old(char *info_json_str, size_t info_json_str_len,
                              const char *title, size_t title_len,
                              const char *msg, size_t msg_len,
                              const char * const *btn_str_ary, size_t ary_len);

// TODO move this to a utils file
size_t popup_info_to_json_str(char *info_json_str, size_t info_json_str_len,
                              const struct popup_info *popup_info);
size_t option_info_to_json_str(char *json_str_out, const size_t max_json_str_out_len,
                               const struct option_info *option_info);

void alex_start_game_b64(const struct game_api *game_api, const struct game_api_callbacks *api_callbacks,
                         void *L,
                         int session_id,
                         const char *b64_enc_state, size_t b64_enc_state_len);

void alexgames_mutex_take();
void alexgames_mutex_release();
void alexgames_set_mutex_take_func(void (*func)(void));
void alexgames_set_mutex_release_func(void (*func)(void));

// I think these should go in emscripten_api.c?
FILE *alex_new_file(void *L, const char *fname);
void alex_write_to_file(void *L, FILE *f, const uint8_t *data, size_t data_len);
void alex_close_file(void *L, FILE *f);
void alex_dump_file(void *L, const char *fname);
void alex_unzip_file(void *L, const char *fname, const char *dst_name);

// TODO I'm not sure if it's cleaner to have each implementation call this,
// or expose only the functions like emscripten uses
extern const struct game_api *game_api;
#ifdef __cplusplus
}
#endif

#endif /* GAME_API_H_ */
