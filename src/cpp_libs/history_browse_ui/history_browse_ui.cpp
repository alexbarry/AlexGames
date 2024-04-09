#include<string.h>

#include "game_api.h"
#include "lua_api.h"
#include "history_browse_ui.h"
#include "touch_scroll_handler.h"
#include "mouse_scroll_handler.h"
#include "saved_state_db.h"
#include "game_api_helper.h"
#include "button_helper.h"
#include <string>
#include <iostream>
#include <vector>
#include <memory>
#include<sstream>
#include<algorithm>

// TODO:
// * handle clicking on a game to jump to the next UI pane (to browse moves within that game session)
// * maybe for now, just immediately load that game with saved state
// * use `save_state` in the remaining Lua games
// * put a button for this somewhere on the HTML page

// TODO how come in solitaire, when I load a saved game state, picking up {a card without any hidden cards behind it}
// results in the card being offset quite a bit down? (Exactly one card length)

// TODO getting "save_state: invalid session_id" when loading older games.
// Need to update the database to handle writing to any old state... though
// be careful. Need to handle this case:
// * open a new game in one tab, this generates a session ID (but doesn't write to it yet, I think)
// * open another game in a separate tab, this would get the same session ID (I think).
// maybe the fix is to only request a session ID the first time state is actually saved?
//
// TODO need to only save state on important moves.
//
// may also end up storing a delta of state rather than the whole thing... we'll see how much storage space
// this thing uses. Seems like 5 MB could be eaten away pretty quickly if you play a couple solitaire games
// that are 200 moves each, and their state is 82 bytes or so per move.
//
// TODO need to draw a scroll bar
//
// TODO right now if you click and drag with a mouse, when releasing, it presses the button
//
// TODO need to handle touch control
//
// TODO need to make sure that all the games properly support loading saved state,
// for local or network multiplayer.
// One example: when a player leaves and rejoins in crib, and the host starts a new game, it starts a new game.
// Need to add a "resume game" in addition to a "start new game" button.
//
// TODO add a button on the HTML page to bring up the history browse UI

static void* init_lib(const struct game_api_callbacks *api_arg, const char *game_str, int game_str_len);
static void destroy_game(void *L);
static void update(void *L, int dt_ms);
static void handle_user_string_input(void *L, char *user_line, int str_len, bool is_cancelled);
static void handle_user_clicked(void *L, int pos_y, int pos_x);
static void handle_mousemove(void *L, int pos_y, int pos_x, int buttons);
static void handle_mouse_evt(void *L, int mouse_evt_id, int pos_y, int pos_x, int buttons);
static bool handle_key_evt(void *L, const char *evt_id, const char *key_code);
static void handle_wheel_changed(void *L, int delta_y, int delta_x);
static void handle_touch_evt(void *L,
                             const char *evt_id_str, int evt_id_str_len, 
                             void *changed_touches, int changed_touches_len);
static void handle_msg_received(void *L, const char *msg_src, int msg_src_len, const char *msg, int len);
static void handle_btn_clicked(void *L, const char *btn_id);
static void handle_popup_btn_clicked(void *L, const char *popup_id, int btn_idx, const struct popup_state *popup_state);
static void handle_game_option_evt(void *L, enum option_type option_type, const char *option_id, int value);
static void start_game(void *L, int session_id, const uint8_t *state, size_t state_len);
static void lua_run_cmd(void *L, const char *str, int string_len);

#define MAX_GAME_STATE_SIZE (64*1024)



static const struct game_api my_game_api = {
	/* .init_lua_api             = */ init_lib,
	/* .destroy_game             = */ destroy_game,
	/* .update               = */ update,
	/* .handle_user_string_input = */ handle_user_string_input,
	/* .handle_user_clicked      = */ handle_user_clicked,
	/* .handle_mousemove         = */ handle_mousemove,
	/* .handle_mouse_evt         = */ handle_mouse_evt,
	/* .handle_wheel_changed     = */ handle_wheel_changed,
	/* .handle_key_evt           = */ handle_key_evt,
	/* .handle_touch_evt         = */ handle_touch_evt,
	/* .handle_msg_received      = */ handle_msg_received,
	/* .handle_btn_clicked       = */ handle_btn_clicked,
	/* .handle_popup_btn_clicked = */ handle_popup_btn_clicked,
	/* .handle_game_option_evt   = */ handle_game_option_evt,
	/* .start_game               = */ start_game,
	/* .get_state                = */ NULL,
	/* .get_init_state           = */ NULL,
	/* .lua_run_cmd              = */ lua_run_cmd
};

static const game_api_callbacks* g_callbacks;

//static void set_status_msg(std::string msg) {
//	g_callbacks->set_status_msg(msg.c_str(), msg.size());
//}


extern const struct game_api lua_game_api;

typedef struct {
	const char *game_id;
	const char *state;
} game_state;

#define MAX(a, b) \
	( (a) >= (b) ? (a) : (b) )

#define MIN(a, b) \
	( (a) <= (b) ? (a) : (b) )

const int session_preview_size = 200;
const int spacing = 15;
const int CANVAS_HEIGHT = 480;
const int CANVAS_WIDTH  = 480;

enum move_select_btn_id {
	BTN_ID_FIRST,
	BTN_ID_PREV,
	BTN_ID_NEXT,
	BTN_ID_LAST,

	BTN_ID_BACK,
};


static void nice_draw_rect(std::string colour, int y_start, int x_start, int y_end, int x_end) {
	g_callbacks->draw_rect(colour.c_str(), colour.length(), y_start, x_start, y_end, x_end);
}

static void draw_text_nice(std::string text, std::string colour, int y_pos, int x_pos, int size, int align) {
	g_callbacks->draw_text(text.c_str(), text.length(),
	                       colour.c_str(), colour.length(),
	                       y_pos, x_pos, size, align);
}

class HistoryPreviewEntry {
	public:
	std::string canvas_id;
	std::string game_id;
	std::string date_str;
	uint32_t move_count;
	uint32_t session_id;
};


enum user_action {
	USER_ACTION_NONE,
	USER_ACTION_LOAD_GAME,
};

class history_browse_state;

class HistoryBrowseWindow {
	public:
	virtual void update(void *L, int dt_ms) = 0;

	/** handle_user_pressed means "mouse click or touch presses determined to be a click (rather than swipe)" */
	virtual enum user_action handle_user_pressed(history_browse_state *state, int pos_y, int pos_x) = 0;

	virtual void handle_mousemove(history_browse_state *state, int pos_y, int pos_x, int buttons) = 0;
	virtual void handle_mouse_evt(history_browse_state *state, int mouse_evt_id, int pos_y, int pos_x, int buttons) = 0;
	virtual void handle_wheel_changed(history_browse_state *state, int delta_y, int delta_x) = 0;

	/**
	 * handle_touch_evt should handle scrolling, and convert touches to presses, then pass presses
	 * to `handle_user_pressed`.
	 *
	 * It should not try to handle any presses itself (e.g. passing events to the button helper), it should
	 * rely on handle_user_pressed to do that.
	 */
	virtual bool handle_touch_evt(history_browse_state *state, std::string evt_id_str,
                                  void *changed_touches, int changed_touches_len) = 0;
};

class SessionSelectState : public HistoryBrowseWindow {
	public:
	SessionSelectState(void *state) {};
	void update(void *L, int dt_ms);
	enum user_action handle_user_pressed(history_browse_state *state, int pos_y, int pos_x);
	void handle_mousemove(history_browse_state *state, int pos_y, int pos_x, int buttons);
	void handle_mouse_evt(history_browse_state *state, int mouse_evt_id, int pos_y, int pos_x, int buttons);
	void handle_wheel_changed(history_browse_state *state, int delta_y, int delta_x);
	bool handle_touch_evt(history_browse_state *state, std::string evt_id_str,
	                      void *changed_touches, int changed_touches_len);

	void generate_state_previews(history_browse_state *state);
	
	private:
	TouchScrollHandler touch_scroll_handler;
	MouseScrollHandler mouse_scroll_handler;
	TouchPressHandler touch_press_handler;
	std::vector<HistoryPreviewEntry*> history_preview_entries;
	// TODO rename these to scroll_y_pos / max_scroll_y_pos
	int y_pos = 0;
	int max_y_pos = 0;
};

class MoveSelectState : public HistoryBrowseWindow {
	public:
	MoveSelectState(void *state) :
		move_select_button_helper(state)
		{}
	void update(void *L, int dt_ms);
	enum user_action handle_user_pressed(history_browse_state *state, int pos_y, int pos_x);
	void init_buttons(history_browse_state *state);
	void handle_mousemove(history_browse_state *state, int pos_y, int pos_x, int buttons) {}
	void handle_mouse_evt(history_browse_state *state, int mouse_evt_id, int pos_y, int pos_x, int buttons) {}
	void handle_wheel_changed(history_browse_state *state, int delta_y, int delta_x) {}
	bool handle_touch_evt(history_browse_state *state, std::string evt_id_str,
                                  void *changed_touches, int changed_touches_len);

	private:
	TouchPressHandler touch_press_handler;
	ButtonHelper move_select_button_helper;
};

class history_browse_state {

	public:
	history_browse_state(void *L, const struct game_api_callbacks *api_callbacks) :
		db(L, api_callbacks),
		session_select_state(this),
		move_select_state(this) {}
	//std::unique_ptr<SavedStateDb> db;
	SavedStateDb db;
	SessionSelectState session_select_state;
	MoveSelectState    move_select_state;

	int session_id_selected;
	int move_id_selected;

	HistoryBrowseWindow *window = &session_select_state;

	std::string text_colour = "#000000";

	const int padding = 5;
	const int text_size = 18;
	const int date_text_size = 14;
	const int info_size = CANVAS_HEIGHT/8;
	//const int move_preview_size = MIN(CANVAS_WIDTH, CANVAS_HEIGHT) - MAX(info_size, 2*padding);
	const int move_preview_size = MIN(CANVAS_WIDTH, CANVAS_HEIGHT) - (info_size + 3*padding + text_size + date_text_size);

	const int info_y_pos = 2*padding + move_preview_size;
	//const int info_btn_y_start = info_y_pos;
	const int button_size_y = info_size - 4*padding;
	//const int text_info_y_pos = info_btn_y_start + button_size_y/2 + text_size/2;
	const int move_preview_y_start = button_size_y + 2*padding;
	const int info_btn_y_start = move_preview_y_start + move_preview_size + padding;
	const int text_info_y_pos = info_btn_y_start + button_size_y/2 + text_size/2;

	//const int move_preview_y_start = 2*padding + text_size;

	const std::string button_colour = "#aaaaaa";
	const int session_select_button_y_size = session_preview_size + 2*padding;
};

static void preview_draw_graphic(const char *img_id,
                  int y, int x,
                  int width, int height,
                  const struct draw_graphic_params *params) {
	g_callbacks->draw_graphic(img_id, y, x, width, height, params);
}
static void preview_draw_line(const char *colour_str, int line_size, int y1, int x1, int y2, int x2) {
	g_callbacks->draw_line(colour_str, line_size, y1, x1, y2, x2);
}
static void preview_draw_text(const char *text_str, size_t text_str_len,
                  const char *colour_str, size_t colour_str_len,
                  int y, int x, int size, int align) {
	g_callbacks->draw_text(text_str, text_str_len, colour_str, colour_str_len, y, x, size, align);
}
static void preview_draw_rect(const char *fill_colour_str, size_t fill_colour_len,
                  int y_start, int x_start,
                  int y_end  , int x_end) {
	g_callbacks->draw_rect(fill_colour_str, fill_colour_len, y_start, x_start, y_end, x_end);
}
static void preview_draw_circle(const char *fill_colour_str,    size_t fill_colour_len,
                    const char *outline_colour_str, size_t outline_colour_len,
                    int y, int x, int radius, int outline_width) {
	g_callbacks->draw_circle(fill_colour_str, fill_colour_len, outline_colour_str, outline_colour_len, y, x, radius, outline_width);
}
static void preview_draw_clear(void) {
	g_callbacks->draw_clear();
}
static void preview_draw_refresh(void) {
	g_callbacks->draw_refresh();
}

static void preview_set_status_err(const char *msg, size_t msg_len) {
	g_callbacks->set_status_err(msg, msg_len);
}

static size_t preview_get_user_colour_pref(char *colour_pref_out, size_t max_colour_pref_out_len) {
	return g_callbacks->get_user_colour_pref(colour_pref_out, max_colour_pref_out_len);
}

static std::string get_preview_canvas_name(int i) {
	char canvas_name[32];
	snprintf(canvas_name, sizeof(canvas_name), "state_preview_%03d", i);
	return std::string(canvas_name);
}

// TODO This feels like a bad hack.
//
// First of all, the handle `L` should ideally contain the game ID, I think. I just don't want to
// go and change everything right now to expect some intermediate game handle instead of
// the raw Lua handle. Maybe in the future that would make sense, and then more of the 
// game engine code could be defined in common code in C, rather than by the implementation
// itself.
//
// Secondly, games should only need their own game ID right now for one reason: to
// load the last session ID. But games should never need that for the history browser,
// which is only initializing games to preview specific saved state.
// Many games don't even call `get_last_session_id()` if serialized state is passed
// as an argument. But then the code gets a bit nested and weird, so I don't want to
// require all games to do that.
//
// An alternative hack could be to simply check if we're in the history browser and
// then not raise the user visible error `api->get_game_id() returned empty string`.
static const char *g_preview_game_id;
static void preview_get_game_id(const void *L, char *game_id_out, size_t game_id_out_len_max) {
	strncpy(game_id_out, g_preview_game_id, game_id_out_len_max);
}


static const struct game_api_callbacks create_preview_draw_callbacks(void) {
	// TODO is there really no way to get decent inheritance like this with C function pointers in C++??
	struct game_api_callbacks callbacks = create_default_callbacks();
	callbacks.draw_graphic = preview_draw_graphic;
	callbacks.draw_line    = preview_draw_line;
	callbacks.draw_text    = preview_draw_text;
	callbacks.draw_rect    = preview_draw_rect;
	callbacks.draw_circle  = preview_draw_circle;
	callbacks.draw_clear   = preview_draw_clear;
	callbacks.draw_refresh = preview_draw_refresh;
	callbacks.set_status_err = preview_set_status_err;
	callbacks.get_user_colour_pref = preview_get_user_colour_pref;
	callbacks.get_game_id  = preview_get_game_id;

	return callbacks;
}

extern const struct game_api lua_game_api;

static bool load_game(history_browse_state *state) {
	{
		char msg[] = "Loading saved game...";
		g_callbacks->set_status_msg(msg, sizeof(msg));
	}
	bool rc = false;
	std::cout << "load_game" << std::endl;
	int session_id = state->session_id_selected;
	int move_id    = state->move_id_selected;
	// TODO use unique_ptr for this instead of goto... 
	uint8_t *saved_game_state = new uint8_t[MAX_GAME_STATE_SIZE];
	std::cout << "reading saved state..." << std::endl;
	size_t saved_game_state_len = state->db.read_state(session_id, move_id, saved_game_state, MAX_GAME_STATE_SIZE);
	if (saved_game_state_len == -1) {
		std::cout << "error reading saved state, aborting" << std::endl;
		goto err;
	}
	std::cout << "read saved state into buffer" << std::endl;


	{
		char game_id[128];
		char date_str[64];
		uint32_t move_count;
		std::cout << "Reading state info ..." << std::endl;
		state->db.read_state_info(session_id,
		                          game_id,  sizeof(game_id),
		                          date_str, sizeof(date_str),
		                          &move_count);
	
		const char *fpath = get_lua_game_path(game_id, strlen(game_id));
		if (fpath == NULL) {
			char msg[64];
			int msg_len = snprintf(msg, sizeof(msg), "Unhandled state preview game_id=\"%s\"\n", game_id);
			g_callbacks->set_status_err(msg, msg_len);
			goto err;
		}

		g_callbacks->destroy_all();
		set_game_api(NULL);

		g_callbacks->set_game_handle(NULL, "unset"); // TODO
		void *L = start_lua_game(g_callbacks, fpath);
		printf("[init] setting game handle to \"%s\"\n", game_id);
		g_callbacks->set_game_handle(L, game_id);

		lua_game_api.start_game(L, session_id, saved_game_state, saved_game_state_len);
		lua_game_api.update(L, 0);
		rc = true;

	}

	err:
	std::cout << "freeing saved state buffer" << std::endl;
	free(saved_game_state);
	return rc;
}

void SessionSelectState::generate_state_previews(history_browse_state *state) {
	const struct game_api_callbacks preview_draw_callbacks = create_preview_draw_callbacks();

	uint8_t *saved_game_state = new uint8_t[MAX_GAME_STATE_SIZE];
	for (int i=0; i<10; i++) {
		int session_id = state->db.get_new_session_id() - 1 - i;
		printf("Checking for stored state with session_id=%d\n", session_id);

		std::string canvas_id = get_preview_canvas_name(i);
		g_callbacks->new_extra_canvas(canvas_id.c_str());
		g_callbacks->set_active_canvas(canvas_id.c_str());
		
		uint32_t move_id = state->db.get_next_move_id(session_id);
		size_t saved_game_state_len = state->db.read_state(session_id, move_id, saved_game_state, MAX_GAME_STATE_SIZE);
		printf("Read %zu bytes of state for session_id=%d\n", saved_game_state_len, session_id);
		if (saved_game_state_len == -1) {
			printf("Aborting saved state read, reached the end\n");
			break;
		}

		char game_id[128];
		game_id[0] = '\0';
		g_preview_game_id = game_id;
		//char (&game_id)[sizeof(g_preview_game_id)] = g_preview_game_id;
		char date_str[64];
		uint32_t move_count;
		state->db.read_state_info(session_id,
                                   game_id,  sizeof(game_id),
                                   date_str, sizeof(date_str),
                                   &move_count);
		if (game_id[0] == '\0') {
			char msg[] = "db.read_state_info did not return a game ID";
			fprintf(stderr, "%s\n", msg);
			g_callbacks->set_status_err(msg, sizeof(msg));
		}
	
		// TODO need to get game ID from DB, then figure out game path from that somehow
		//void *L = init_lua_game(&preview_draw_callbacks, "games/solitaire/solitaire_main.lua");
		const char *fpath = get_lua_game_path(game_id, strlen(game_id));
		if (fpath == NULL) {
			char msg[64];
			int msg_len = snprintf(msg, sizeof(msg), "Unhandled state preview game_id=\"%s\"\n", game_id);
			fprintf(stderr, "Unhandled state preview game_id=\"%s\", sess=%d, date=%s\n", game_id, session_id, date_str);
			g_callbacks->set_status_err(msg, msg_len);
			continue;
		}

		{
		void *L = init_lua_game(&preview_draw_callbacks, fpath);
		//uint8_t saved_game_state[MAX_GAME_STATE_SIZE];
		lua_game_api.start_game(L, session_id, saved_game_state, saved_game_state_len);
		lua_game_api.update(L, 0);

		lua_game_api.destroy_game(L);
		g_preview_game_id = nullptr;
		//destroy_lua_game(L);
		}

		HistoryPreviewEntry *preview = new HistoryPreviewEntry();
		// TODO also need to store some info in db like date last played, move number
		preview->canvas_id = canvas_id;
		preview->game_id  = game_id;
		preview->date_str = date_str;
		preview->session_id = session_id;
		preview->move_count  = move_count;
		this->history_preview_entries.push_back(preview);
	}

	// Sort history_preview_entries by date, i.e. sort by last played rather than
	// when the session was first created.
	// e.g. if the player resumes a game that they started a while ago, it will
	// now show at the top.
	struct
	{
		bool operator() (const HistoryPreviewEntry *l_arg, const HistoryPreviewEntry *r_arg) const {
			const std::string &l_date = l_arg->date_str;
			const std::string &r_date = r_arg->date_str;
	
			return strcmp(l_date.c_str(), r_date.c_str()) > 0;

		}
	} history_preview_sort;

	std::sort(this->history_preview_entries.begin(), this->history_preview_entries.end(),
	         history_preview_sort);


	this->max_y_pos = MAX((int)(this->history_preview_entries.size()) * (session_preview_size + spacing) - CANVAS_HEIGHT, 0);
	free(saved_game_state);
	g_callbacks->set_active_canvas("");
}

static void btn_clicked(void *handle, btn_id_t btn_id) {
	history_browse_state *state = (history_browse_state *)handle;

	const int max_move_id = state->db.get_next_move_id(state->session_id_selected);

	switch(btn_id) {
		case BTN_ID_FIRST: state->move_id_selected = 0;  break;
		case BTN_ID_PREV:  if (state->move_id_selected > 0) { state->move_id_selected--; }  break;
		case BTN_ID_NEXT:  if (state->move_id_selected < max_move_id) { state->move_id_selected++; }  break;
		case BTN_ID_LAST:  state->move_id_selected = max_move_id; break;
		case BTN_ID_BACK:
			//state->window = WINDOW_SELECT_SESSION;
			state->window = &state->session_select_state;
		break;
	}
}

void MoveSelectState::init_buttons(history_browse_state *state) {
	// TODO also show a back button to go back to session selector...
	// TODO need to add some more space for buttons to select move, display current/total moves, etc

	const int button_size_x = (CANVAS_WIDTH - 2*state->padding)/6;
	const int button_padding = 5;
	const int button_size_y = state->button_size_y;

	const int info_btn_y_start = state->info_btn_y_start;

	this->move_select_button_helper.new_button(ButtonInfo::fromSize("|<", // "first",
	                                            info_btn_y_start, button_padding,
	                                            button_size_y, button_size_x, BTN_ID_FIRST, btn_clicked));
	this->move_select_button_helper.new_button(ButtonInfo::fromSize("<", // "prev",
	                                            info_btn_y_start, 2*button_padding + button_size_x,
	                                            button_size_y, button_size_x, BTN_ID_PREV, btn_clicked));
	this->move_select_button_helper.new_button(ButtonInfo::fromSize(">", // "next",
	                                            info_btn_y_start, CANVAS_WIDTH - 3*button_padding - 2*button_size_x,
	                                            button_size_y, button_size_x, BTN_ID_NEXT, btn_clicked));
	this->move_select_button_helper.new_button(ButtonInfo::fromSize(">|", //"last",
	                                            info_btn_y_start, CANVAS_WIDTH - 2*button_padding - button_size_x,
	                                            button_size_y, button_size_x, BTN_ID_LAST, btn_clicked));

	this->move_select_button_helper.new_button(ButtonInfo::fromSize("Back", //"last",
	                                            state->padding, state->padding,
	                                            button_size_y, button_size_x, BTN_ID_BACK, btn_clicked));
}

static bool is_dark_mode(const struct game_api_callbacks *callbacks) {
	char buff[128];
	int str_len = callbacks->get_user_colour_pref(buff, sizeof(buff));

	std::string colour_pref_str(buff, str_len);

	if (colour_pref_str == "dark") {
		return true;
	}

	return false;
} 

static void* init_lib(const struct game_api_callbacks *api_arg, const char *game_str, int game_str_len) {
	g_callbacks = api_arg;


	//static const char key_evt_type[] = "key";
	//g_callbacks->enable_evt(key_evt_type, sizeof(key_evt_type));

	static const char key_evt_type[]   = "key";
	static const char touch_evt_type[] = "touch";
	static const char mouse_move_evt_type[] = "mouse_move";
	static const char mouse_updown_evt_type[] = "mouse_updown";
	static const char wheel_evt_type[] = "wheel";

	g_callbacks->enable_evt(key_evt_type, sizeof(key_evt_type));
	g_callbacks->enable_evt(touch_evt_type, sizeof(touch_evt_type));
	g_callbacks->enable_evt(mouse_move_evt_type, sizeof(mouse_move_evt_type));
	g_callbacks->enable_evt(mouse_updown_evt_type, sizeof(mouse_updown_evt_type));
	g_callbacks->enable_evt(wheel_evt_type, sizeof(wheel_evt_type));

	(void)nice_draw_rect;

	// TODO definitely shouldn't need to do this...
	set_game_api(&my_game_api);

	g_callbacks->set_active_canvas("");

	void *L = nullptr;
	history_browse_state *state = new history_browse_state(L, g_callbacks);
	state->text_colour = is_dark_mode(g_callbacks) ? "#cccccc" : "#000000";
	state->db.refresh_internal_state();

	state->move_select_state.init_buttons(state);

	state->session_select_state.generate_state_previews(state);

	return state;
}


static void destroy_game(void *L) {
	// TODO?
	// should I be doing this? I don't think this API is actually ever called, unless
	// you could ever load a saved "history browser" state from within the history browser
	// g_callbacks->destroy_all();
}

void SessionSelectState::update(void *L, int dt_ms) {
	history_browse_state *state = (history_browse_state*)L;

	int offset = this->y_pos;

	std::string session_id_btn_colour;
	if (is_dark_mode(g_callbacks)) {
		session_id_btn_colour = "#33333388";
	} else {
		session_id_btn_colour = "#aaaaaa88";
	}

	g_callbacks->draw_clear();

	if (this->history_preview_entries.size() == 0) {
		std::cout << "Found history entries: " << this->history_preview_entries.size() << std::endl;
		draw_text_nice("History entries found: 0", state->text_colour,
		               CANVAS_HEIGHT/2 - state->text_size/2,
		               CANVAS_WIDTH/2,
		               state->text_size,
		               TEXT_ALIGN_CENTRE);
	}


	for (int i=0; i<this->history_preview_entries.size(); i++) {
		HistoryPreviewEntry *preview = this->history_preview_entries[i];
		int y_start = state->padding + i*(session_preview_size + spacing) + offset;
		int x_start = state->padding;
		//int button_y_size = session_preview_size + 2*state->padding;
		int button_y_size = state->session_select_button_y_size;
		int button_x_size = CANVAS_WIDTH - 2*state->padding;
		nice_draw_rect(session_id_btn_colour, y_start, x_start, y_start + button_y_size, x_start + button_x_size);
		g_callbacks->draw_extra_canvas(preview->canvas_id.c_str(),
		                               y_start + state->padding, x_start + state->padding,
		                               session_preview_size,
		                               session_preview_size);
		// TODO store a better name in `preview`
		char preview_title[128];
		snprintf(preview_title, sizeof(preview_title), "%s (moves: %d)", preview->game_id.c_str(), preview->move_count);
		draw_text_nice(preview_title, state->text_colour,
		               state->padding + offset + i*(session_preview_size + spacing) + session_preview_size/2 - 3*state->text_size/2,
		               session_preview_size + 3*state->padding, state->text_size, 1);
		draw_text_nice(preview->date_str, state->text_colour,
		               state->padding + offset + i*(session_preview_size + spacing) + session_preview_size/2 + state->text_size/2,
		               session_preview_size + 3*state->padding, state->date_text_size, 1);
	}
}

void MoveSelectState::update(void *L_arg, int dt_ms) {
	history_browse_state *state = (history_browse_state*)L_arg;
	const struct game_api_callbacks preview_draw_callbacks = create_preview_draw_callbacks();
	const char *move_preview_canvas_id = "select_move_preview";

	uint8_t *saved_game_state = new uint8_t[MAX_GAME_STATE_SIZE];
	g_callbacks->new_extra_canvas(move_preview_canvas_id);
	g_callbacks->set_active_canvas(move_preview_canvas_id);
	int session_id = state->session_id_selected;
	size_t saved_game_state_len = state->db.read_state(session_id, state->move_id_selected, saved_game_state, MAX_GAME_STATE_SIZE);
	if (saved_game_state_len == -1) {
		// TODO?
		return;
	}
	char game_id[128];
	char date_str[64];
	uint32_t move_count;

	state->db.read_state_info(session_id,
	                          game_id,  sizeof(game_id),
	                          date_str, sizeof(date_str),
	                          &move_count);

	const char *fpath = get_lua_game_path(game_id, strlen(game_id));
	if (fpath == NULL) {
		char msg[64];
		int msg_len = snprintf(msg, sizeof(msg), "Unhandled state preview game_id=\"%s\"\n", game_id);
		g_callbacks->set_status_err(msg, msg_len);
		return;
	}

	void *L = init_lua_game(&preview_draw_callbacks, fpath);
	//uint8_t saved_game_state[MAX_GAME_STATE_SIZE];
	lua_game_api.start_game(L, session_id, saved_game_state, saved_game_state_len);
	lua_game_api.update(L, 0);

	free(saved_game_state);
	destroy_lua_game(L);
	g_callbacks->set_active_canvas("");

	g_callbacks->draw_clear();
	// TODO also show a back button to go back to session selector...
	// TODO need to add some more space for buttons to select move, display current/total moves, etc
	//const int move_preview_size = MIN(CANVAS_WIDTH, CANVAS_HEIGHT) - MAX(state->info_size + 3*state->padding + state->text_size, 2*state->padding);
	const int move_preview_size = state->move_preview_size;
	//const int move_preview_size = MIN(CANVAS_WIDTH, CANVAS_HEIGHT) - 2*state->padding;
	//char title[128];
	//snprintf(title, sizeof(title), "%s (%s)", game_id, date_str);
	draw_text_nice(game_id, state->text_colour,
	               state->padding + state->text_size,
	               CANVAS_WIDTH/2,
	               state->text_size, 0);
	draw_text_nice(date_str, state->text_colour,
	               2*state->padding + 2*state->text_size,
	               CANVAS_WIDTH/2,
	               state->date_text_size, 0);
	g_callbacks->draw_extra_canvas(move_preview_canvas_id,
	                               state->move_preview_y_start, (CANVAS_WIDTH - move_preview_size)/2,
	                               move_preview_size, move_preview_size);


	char move_txt[128];
	snprintf(move_txt, sizeof(move_txt), "%3d/%3d", state->move_id_selected, move_count);
	draw_text_nice(move_txt, state->text_colour, state->text_info_y_pos, CANVAS_WIDTH/2, state->text_size, 0);

	this->move_select_button_helper.draw_buttons(g_callbacks);
}

static void update(void *L, int dt_ms) {
	history_browse_state *state = (history_browse_state *)L;

	g_callbacks->draw_clear();
	state->window->update(L, dt_ms);
#if 0
	switch (state->window) {
		case WINDOW_SELECT_SESSION:
			draw_select_session(state);
		break;
		case WINDOW_SELECT_MOVE:
			//draw_select_session(state);
			draw_select_move(state);
			(void)draw_select_move;
		break;
	}
#endif

}

static double clip(double min_val, double val, double max_val) {
	if (val <= min_val) { return min_val; }
	else if (val >= max_val) { return max_val; }
	else { return val; }
}

enum user_action SessionSelectState::handle_user_pressed(history_browse_state *state, int pos_y, int pos_x) {
	int item_selected = (-this->y_pos + pos_y) / (state->session_select_button_y_size + state->padding);
	if (item_selected >= history_preview_entries.size()) {
		return USER_ACTION_NONE;
	}
	state->session_id_selected = this->history_preview_entries.at(item_selected)->session_id;
	state->move_id_selected    = state->db.get_next_move_id(state->session_id_selected);

	// TODO consider returning an action to switch windows
	state->window = &state->move_select_state;
	return USER_ACTION_NONE;
}

enum user_action MoveSelectState::handle_user_pressed(history_browse_state *state, int pos_y, int pos_x) {
	this->move_select_button_helper.handle_user_pressed(pos_y, pos_x);
	if (state->move_preview_y_start <= pos_y && pos_y <= state->move_preview_y_start + state->move_preview_size) {
		return USER_ACTION_LOAD_GAME;
	}

	return USER_ACTION_NONE;
}

static void handle_user_string_input(void *L, char *user_line, int str_len, bool is_cancelled) {}

static void handle_user_action(void *L, enum user_action action) {
	history_browse_state *state = (history_browse_state *)L;
	switch (action) {
		case USER_ACTION_LOAD_GAME: {
			bool rc = load_game(state);
			// Can **not** fallthrough to update(L) here, because
			// update should now point to the Lua draw board (not the history draw board),
			// and even if it is changed to game_api->update(L), the L is wrong too -- that
			// still points to the history browse state, but we've changed to use the new Lua game's
			// state
			if (rc) {
				{
					char msg[] = "Successfully loaded game state!";
					g_callbacks->set_status_msg(msg, sizeof(msg));
				}
				delete state;

				return;
			} else {
				const char msg[] = "Error loading saved state";
				g_callbacks->set_status_err(msg, sizeof(msg));
			}
			break;
		}

		case USER_ACTION_NONE:
			update(L, 0);
			break;
	}
}
static void handle_user_clicked(void *L, int pos_y, int pos_x) {
	// TODO this event seems to be sent even when the user clicks and drags to scroll.
	// This is not ideal, and users may not even realize that they have the option to use
	// the mouse wheel.

	history_browse_state *state = (history_browse_state *)L;

	enum user_action action = state->window->handle_user_pressed(state, pos_y, pos_x);
	handle_user_action(L, action);
}



static void handle_mousemove(void *L, int pos_y, int pos_x, int buttons) {
	history_browse_state *state = (history_browse_state *)L;
	state->window->handle_mousemove(state, pos_y, pos_x, buttons);
}

void SessionSelectState::handle_mousemove(history_browse_state *state, int pos_y, int pos_x, int buttons) {
	int diff = this->mouse_scroll_handler.handle_mousemove(pos_y, pos_x, buttons);

	if (diff != 0) {
		this->y_pos += diff;
		this->y_pos = clip(-this->max_y_pos, this->y_pos, 0);
		update(state, 0);
	}
}

static void handle_mouse_evt(void *L, int mouse_evt_id, int pos_y, int pos_x, int buttons) {
	history_browse_state *state = (history_browse_state *)L;
	state->window->handle_mouse_evt(state, mouse_evt_id, pos_y, pos_x, buttons);
}

void SessionSelectState::handle_mouse_evt(history_browse_state *state, int mouse_evt_id, int pos_y, int pos_x, int buttons) {
	std::cout << "handle_mouse_evt history browse ui" << std::endl;
	this->mouse_scroll_handler.handle_mouse_evt(mouse_evt_id, pos_y, pos_x);
}

static bool handle_key_evt(void *L, const char *evt_id, const char *key_code) {
	//history_browse_state *state = (history_browse_state *)L;
	update(L, 0);
	return false;
}

static void handle_wheel_changed(void *L, int delta_y, int delta_x) {
	history_browse_state *state = (history_browse_state *)L;
	state->window->handle_wheel_changed(state, delta_y, delta_x);
}

void SessionSelectState::handle_wheel_changed(history_browse_state *state, int delta_y, int delta_x) {
	this->y_pos += -delta_y;
	this->y_pos = clip(-this->max_y_pos, this->y_pos, 0);
	update(state, 0);
	//printf("handle_wheel_changed{ dy = %d, dx = %d }\n", delta_y, delta_x);
}

static void handle_touch_evt(void *L,
                             const char *evt_id_str, int evt_id_str_len, 
                             void *changed_touches, int changed_touches_len) {
	history_browse_state *state = (history_browse_state *)L;
	bool activity = state->window->handle_touch_evt(state, std::string(evt_id_str), changed_touches, changed_touches_len);
	// TODO maybe don't do this, game may have changed
	if (activity) {
		update(L, 0);
	}
}

bool SessionSelectState::handle_touch_evt(history_browse_state *state, std::string evt_id_str,
                                          void *changed_touches, int changed_touches_len) {
	bool activity = false;
	TouchScrollHandlerPoint diff = this->touch_scroll_handler.handle_touch_evt(evt_id_str.c_str(), evt_id_str.size(),
	                                                                           changed_touches, changed_touches_len);
	this->y_pos += diff.y;
	this->y_pos = clip(-this->max_y_pos, this->y_pos, 0);
	if (diff.y != 0) {
		activity |= true;
	}
	
	TouchPress press_info = touch_press_handler.handle_touch_evt(evt_id_str, (struct touch_info*)changed_touches, changed_touches_len);
	if (press_info.pressed) {
		handle_user_pressed(state, press_info.y, press_info.x);
		activity |= true;
	}
	return activity;
}


bool MoveSelectState::handle_touch_evt(history_browse_state *state, std::string evt_id_str,
                                          void *changed_touches, int changed_touches_len) {
	TouchPress press_info = this->touch_press_handler.handle_touch_evt(evt_id_str,
	                                                                   (struct touch_info*)changed_touches,
	                                                                   changed_touches_len);
	if (press_info.pressed) {
		enum user_action action = handle_user_pressed(state, press_info.y, press_info.x);
		handle_user_action((void*)state, action);
	}
	return false;
}
static void handle_msg_received(void *L, const char *msg_src, int msg_src_len, const char *msg, int len) {}
static void handle_btn_clicked(void *L, const char *btn_id) {}
static void handle_popup_btn_clicked(void *L, const char *popup_id, int btn_idx, const struct popup_state *popup_state) {}
static void handle_game_option_evt(void *L, enum option_type option_type, const char *option_id, int value) {}
static void start_game(void *L, int session_id, const uint8_t *state, size_t state_len) {}
static void lua_run_cmd(void *L, const char *str, int string_len) {}


const struct game_api *get_history_browse_api(void) {
	return &my_game_api;
}
