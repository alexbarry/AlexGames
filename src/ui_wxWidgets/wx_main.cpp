
#include<unordered_map>
#include<ctime>
#include<iostream>
#include<sstream>
#include<memory>
#include<mutex>
#include<deque>

#include "wx/wx.h"
#include "wx/defs.h"
#include "wx/sizer.h"
#include "wx/graphics.h"
#include "wx/filename.h"
#include "wx/imagpng.h"
#include "wx/popupwin.h"
#include "wx/wxprec.h"
#include "wx/cmdline.h"

#include "game_api.h"
#include "sqlite_saved_state.h"
#include "saved_state_db_c_api.h"
#include "c_dictionary.h"
#include "wx_game_popup.h"
#include "wx_network_ui.h"
#include "wx_network.h"

#define DEFAULT_PORT (55345)

#define ALEX_CUSTOM_MSG_ID (10100)

#define ARY_LEN(x) ( sizeof(x) / sizeof((x)[0]) )

#define NOT_IMPL() do {\
	fprintf(stderr, "%s not implemented %s:%d\n", __func__, __FILE__, __LINE__); \
	} while (0) \

static void wx_set_game_handle(const void *L, const char *game_id);
static void wx_get_game_id(const void *L, char *game_id_out, size_t game_id_out_max_len);
static void wx_draw_graphic(const char *img_id,
                            int y, int x,
                            int width, int height,
                            const struct draw_graphic_params *params);
static void wx_draw_line(const char *colour_str, int line_size, int y1, int x1, int y2, int x2);
static void wx_draw_text(const char *text_str, size_t text_str_len,
                  const char *colour_str, size_t colour_str_len,
                  int y, int x, int size, int align);
static void wx_draw_rect(const char *fill_colour_str, size_t fill_colour_len,
                  int y_start, int x_start,
                  int y_end  , int x_end);
static void wx_draw_triangle(const char *fill_colour_str,    size_t fill_colour_len,
                             int y1, int x1,
                             int y2, int x2,
                             int y3, int x3);
static void wx_draw_circle(const char *fill_colour_str,    size_t fill_colour_len,
                    const char *outline_colour_str, size_t outline_colour_len,
                    int y, int x, int radius, int outline_width);
static void wx_draw_clear(void);
static void wx_draw_refresh(void);
static void wx_send_message(const char *dst, size_t dst_len, const char *msg, size_t msg_len);
static void wx_create_btn(const char *btn_id_str, const char *btn_text_str, int weight);
static void wx_set_btn_enabled(const char *btn_id_str, bool enabled);
static void wx_set_btn_visible(const char *btn_id_str, bool visible);
static void wx_hide_popup(void);
static void wx_add_game_option(const char *option_id, const struct option_info *info);
static void wx_set_status_msg(const char *msg, size_t msg_len);
static void wx_set_status_err(const char *msg, size_t msg_len);
//static void wx_show_popup(const char *popup_id, size_t popup_id_str_len,
//                  const char *title, size_t title_len,
//                  const char *msg, size_t msg_len,
//                  const char * const *btn_str_ary, size_t ary_len);
static void wx_show_popup(void *L, const char *popup_id, size_t popup_id_str_len,
                          const struct popup_info *info);
static void wx_prompt_string(const char *prompt_title, size_t prompt_title_len,
                             const char *prompt_msg, size_t prompt_msg_len);
static int wx_update_timer_ms(int update_period_ms);
static void wx_delete_timer(int timer_handle);
static void wx_enable_evt(const char *evt_id_str, size_t evt_id_len);
static void wx_disable_evt(const char *evt_id_str, size_t evt_id_len);
static long wx_get_time_ms(void);
static size_t wx_get_time_of_day(char *time_str, size_t max_time_str_len);
static void wx_store_data(void *L, const char *key, const uint8_t *value, size_t value_len);
static size_t wx_read_stored_data(void *L, const char *key, uint8_t *value_out, size_t max_val_len);
static int wx_get_new_session_id(void);
static int wx_get_last_session_id(const char *game_id);
static void wx_save_state(int session_id, const uint8_t *state, size_t state_len);
static bool wx_has_saved_state_offset(int session_id, int move_id_offset);
static int wx_get_saved_state_offset(int session_id, int move_id_offset, uint8_t *state_out, size_t max_sate_out);
static void wx_draw_extra_canvas(const char *img_id,
	                             int y, int x,
	                             int width, int height);
static void wx_new_extra_canvas(const char *canvas_id);
static void wx_set_active_canvas(const char *canvas_id);
static void wx_delete_extra_canvases(void);
static size_t wx_get_user_colour_pref(char *colour_pref_out, size_t max_colour_pref_out_len);
static bool wx_is_feature_supported(const char *feature_id, size_t feature_id_len);


static void wx_draw_graphic_internal(const char *img_id, int y, int x, int width, int height, const struct draw_graphic_params *params);

static void wx_draw_rect_internal(const char *fill_colour_str, size_t fill_colour_len,
                  int y_start, int x_start,
                  int y_end  , int x_end);
static void wx_draw_text_internal(const char *text_str, size_t text_str_len,
                  const char *colour_str, size_t colour_str_len,
                  int y, int x, int size, int align);

static void wx_draw_circle_internal(const char *fill_colour_str,    size_t fill_colour_len,
                    const char *outline_colour_str, size_t outline_colour_len,
                    int y, int x, int radius);
static void wx_draw_line_internal(const char *colour_str, int line_width,
                         int y1, int x1,
                         int y2, int x2);



static void wx_destroy_all(void);

struct img_info {
	const char *img_id;
	const char *img_path;
};

// TODO need to convert these images to bmp
// does that mean no transparency?
static const struct img_info IMAGES_TABLE[] = {
	{ "board"               , "img/wooden_board.png"         },
	{ "piece_black"         , "img/black_piece.png"          },
	{ "piece_white"         , "img/white_piece.png"          },
	{ "piece_highlight"     , "img/piece_highlight.png"      },

	{ "piece_king_icon"     , "img/piece_king_icon.png"      },

	{ "card_diamonds"       , "img/cards/diamonds.png"       },
	{ "card_hearts"         , "img/cards/hearts.png"         },
	{ "card_spades"         , "img/cards/spades.png"         },
	{ "card_clubs"          , "img/cards/clubs.png"          },
	{ "card_blank"          , "img/cards/blank_card.png"     },
	{ "card_facedown"       , "img/cards/card_facedown.png"  },
	{ "card_highlight"      , "img/cards/card_highlight.png" },

	{ "more_info_btn"       , "img/more_info_btn.png"        },

	{ "minesweeper_mine" ,             "img/minesweeper/mine.png" },
	{ "minesweeper_box1" ,             "img/minesweeper/box1.png" },
	{ "minesweeper_box2" ,             "img/minesweeper/box2.png" },
	{ "minesweeper_box3" ,             "img/minesweeper/box3.png" },
	{ "minesweeper_box4" ,             "img/minesweeper/box4.png" },
	{ "minesweeper_box5" ,             "img/minesweeper/box5.png" },
	{ "minesweeper_box6" ,             "img/minesweeper/box6.png" },
	{ "minesweeper_box7" ,             "img/minesweeper/box7.png" },
	{ "minesweeper_box8" ,             "img/minesweeper/box8.png" },
	{ "minesweeper_box_unclicked"    , "img/minesweeper/box_unclicked.png" },
	{ "minesweeper_box_empty"        , "img/minesweeper/box_empty.png" },
	{ "minesweeper_box_flagged_red"  , "img/minesweeper/box_flagged_red.png" },
	{ "minesweeper_box_flagged_blue" , "img/minesweeper/box_flagged_blue.png" },

	{ "space_ship1" , "img/space/ship1.png" },
	{ "hospital_ui_dirpad" , "img/hospital/ui/dirpad.png" },
};

static const struct game_api_callbacks api = {
	wx_set_game_handle,
	wx_get_game_id,
	wx_draw_graphic,
	wx_draw_line,
	wx_draw_text,
	wx_draw_rect,
	wx_draw_triangle,
	wx_draw_circle,
	wx_draw_clear,
	wx_draw_refresh,
	wx_send_message,
	wx_create_btn,
	wx_set_btn_enabled,
	wx_set_btn_visible,
	wx_hide_popup,
	wx_add_game_option,
	wx_set_status_msg,
	wx_set_status_err,
	wx_show_popup,
	wx_prompt_string,
	wx_update_timer_ms,
	wx_delete_timer,
	wx_enable_evt,
	wx_disable_evt,
	wx_get_time_ms,
	wx_get_time_of_day,
	wx_store_data,
	wx_read_stored_data,
	wx_get_new_session_id,
	wx_get_last_session_id,
	wx_save_state,
	wx_has_saved_state_offset,
	wx_get_saved_state_offset,
	wx_draw_extra_canvas,
	wx_new_extra_canvas,
	wx_set_active_canvas,
	wx_delete_extra_canvases,
	wx_get_user_colour_pref,
	wx_is_feature_supported,
	wx_destroy_all,
};

class AlexGamesTimer;


std::mutex mutex;
void *L;
static char g_game_id[256];
static bool g_is_dark_mode = false;
static int g_timer_handle_idx = 1;
static std::unordered_map<int, AlexGamesTimer*> g_timers;
static unsigned long g_last_draw_board = 0;
static void *g_saved_state = nullptr;
static void *g_db_state_handler = NULL;

static bool g_key_enabled = false;
static bool g_mousemove_enabled = false;
static bool g_mouse_updown_enabled = false;

static void wx_mutex_take() {
	mutex.lock();
}

static void wx_mutex_release() {
	mutex.unlock();
}

std::unordered_map<std::string, wxBitmap> images_map(ARY_LEN(IMAGES_TABLE));

class MyFrame;

class MyCanvas: public wxScrolledWindow {
public:
    MyCanvas( MyFrame *parent );

    void OnPaint(wxPaintEvent &event);
    void OnMouseMove(wxMouseEvent &event);
    void OnMouseDown(wxMouseEvent &event);
    void OnMouseUp(wxMouseEvent &event);

	void handle_key_down_evt(wxKeyEvent &event);
	void handle_key_up_evt(wxKeyEvent &event);
	void ReDrawIfNeeded(void);


	//wxMemoryDC mdc;
	wxBitmap bmp;

	bool is_drawing = false;
private:
	bool meta_down = false;
	bool alt_down  = false;
    wxDECLARE_EVENT_TABLE();
};



class MyApp : public wxApp {
	public:
	virtual bool OnInit();

	virtual void OnInitCmdLine(wxCmdLineParser& parser);
	virtual bool OnCmdLineParsed(wxCmdLineParser& parser);
};

static const wxCmdLineEntryDesc g_cmdLineDesc[] = {
	{ wxCMD_LINE_SWITCH, "h", "help", "Prints help message.",
	  wxCMD_LINE_VAL_NONE, wxCMD_LINE_OPTION_HELP },
	{ wxCMD_LINE_OPTION, "g", "game", "Chooses game. Run this program without any arguments to list available games.",
	  wxCMD_LINE_VAL_STRING, wxCMD_LINE_PARAM_OPTIONAL },
	{ wxCMD_LINE_NONE },
};

enum {
    MENU_ITEM_START_GAME = wxID_HIGHEST,
    MENU_ITEM_GAME_SELECT,
    MENU_ITEM_NETWORK_SETTINGS,
};

class MyFrame : public wxFrame {
	public:
    MyFrame(const wxString& title);

    void OnQuit(wxCommandEvent& event);
    void OnAbout(wxCommandEvent& event);
	void StartGame(wxCommandEvent &event);
	void StartGame();
	void GameSelect(wxCommandEvent &event);
	void GameSelect();
	void ShowNetworkSettings();
	void ShowNetworkSettings(wxCommandEvent &event);
	MyCanvas *canvas;
	wxTextCtrl statusText;
	void new_button(const char *btn_id_str, const char *btn_text_str, int weight);
	void set_btn_enabled(const char *btn_id_str, bool is_enabled);
	void handle_msg_recvd(wxCommandEvent &evt);
	//void handle_key_evt(wxKeyEvent &evt);

	private:
	wxBoxSizer *sizer;
    wxDECLARE_EVENT_TABLE();
	std::unordered_map<std::string, wxButton*> buttons;
	wxBoxSizer *button_sizer;
};

wxBEGIN_EVENT_TABLE(MyFrame, wxFrame)
    EVT_MENU(wxID_EXIT,  MyFrame::OnQuit)
    EVT_MENU(wxID_ABOUT, MyFrame::OnAbout)
    EVT_MENU(MENU_ITEM_START_GAME,       MyFrame::StartGame)
    EVT_MENU(MENU_ITEM_GAME_SELECT,      MyFrame::GameSelect)
    EVT_MENU(MENU_ITEM_NETWORK_SETTINGS, MyFrame::ShowNetworkSettings)
	//EVT_KEY_DOWN(MyFrame::handle_key_evt)
	EVT_COMMAND(ALEX_CUSTOM_MSG_ID, wxEVT_COMMAND_TEXT_UPDATED, MyFrame::handle_msg_recvd)
wxEND_EVENT_TABLE()


class MyCanvas;

MyFrame       *g_frame         = nullptr;
NetworkPopup  *g_network_popup = nullptr;
GamePopup     *g_popup         = nullptr;
//wxDialog      *g_popup         = nullptr;
MyCanvas      *g_canvas        = nullptr;

class MyPopup : public wxDialog {
	public:
	MyPopup(wxFrame *parent, wxString popup_id_arg, wxString title, wxString text,
	        const char * const * btn_txts, int btn_count) :
	    wxDialog(parent, wxID_ANY, title,
	             wxDefaultPosition, wxSize(300, 400),
	             wxDEFAULT_DIALOG_STYLE | wxSTAY_ON_TOP),
		popup_id(popup_id_arg),
		txtTitle(this, wxID_ANY, title),
		txtBody(this, wxID_ANY, text),
		buttons(btn_count) {


		this->sizer = new wxBoxSizer(wxVERTICAL);
		//txtTitle.AppendText(title);
		sizer->Add(&txtTitle, 0);
		sizer->Add(&txtBody, 0);
		for (int i=0; i<btn_count; i++) {
			buttons[i] = new wxButton(this, wxID_ANY, wxString(btn_txts[i]));
			/*
			buttons[i]->Connect(wxID_ANY,
				wxEVT_COMMAND_BUTTON_CLICKED,
				wxObjectEventFunction([this, i](wxEvent &evt) {
					this->handle_button_clicked(i);
				}));
			*/
			//function <void (wxCommandEvent &)> clickHandler( bind(
			struct clickHandler {
				public:
				clickHandler(MyPopup *inst, int i) {
					this->inst = inst;
					this->i = i;
				}
				void operator()(wxCommandEvent &) const {
					inst->handle_button_clicked(i);
				}
				private:
				int i;
				MyPopup *inst;
			};
			struct clickHandler handler(this, i);
			buttons[i]->Bind(wxEVT_COMMAND_BUTTON_CLICKED, handler, wxID_ANY);
			sizer->Add(buttons[i], 0);
		}
		//sizer.Layout();
		this->SetSizer(sizer);
	}
	private:
	wxStaticText   txtTitle;
	wxStaticText   txtBody;
	wxBoxSizer     *sizer;
	std::vector<wxButton*> buttons;
	wxString popup_id;

	void handle_button_clicked(int i) {
		printf("popup button %d clicked\n", i);
		// TODO pass popup state as last parameter once dropdowns are implemented
		game_api->handle_popup_btn_clicked(L, popup_id.c_str(), i, nullptr);
		g_canvas->ReDrawIfNeeded();
	}
};

IMPLEMENT_APP(MyApp)



class Drawable {
	public:
	virtual void draw(void *L) = 0;
};

#if 0
class DrawableFromLambda : Drawable {
	public:
	DrawableFromLambda(void (*draw_lambda)(void *L)) {
		this->draw_lambda = draw_lambda;
	}
	virtual void draw(void *L) {
	}

	private:
	void (*draw_lambda)(void *L);
};
#endif

class DrawGraphicDrawable : public Drawable {
	public:
	DrawGraphicDrawable(const char *img_id, int y, int x, int height, int width, const struct draw_graphic_params *params) {
		this->img_id = img_id;
		this->y = y;
		this->x = x;
		this->height = height;
		this->width = width;
		this->params = *params;
	}
	virtual void draw(void *L) {
		wx_draw_graphic_internal(img_id.c_str(), y, x, height, width, &params);
	};

	private:
	std::string img_id;
	int y, x;
	int height, width;
	struct draw_graphic_params params;
};

class DrawRectDrawable : public Drawable {
	public:
	DrawRectDrawable(const char *fill_colour_str, size_t fill_colour_len,
                  int y_start, int x_start,
                  int y_end  , int x_end) {
		this->fill_colour = fill_colour_str;
		this->y_start = y_start;
		this->x_start = x_start;
		this->y_end = y_end;
		this->x_end = x_end;
	}

	virtual void draw(void *L) {
		wx_draw_rect_internal(fill_colour.c_str(), fill_colour.length(),
		                      y_start, x_start,
		                      y_end,   x_end);
	}

	private:
	std::string fill_colour;
	int y_start, x_start;
	int y_end,   x_end;
};

class DrawTextDrawable : public Drawable {
	public:
	DrawTextDrawable (const char *text_str,
                  const char *colour_str,
                  int y, int x, int size, int align) {
		this->text_str = text_str;
		this->colour_str = colour_str;
		this->y = y;
		this->x = x;
		this->size = size;
		this->align = align;
	}

	virtual void draw(void *L) {
		wx_draw_text_internal(text_str.c_str(), text_str.length(),
		                      colour_str.c_str(), colour_str.length(),
		                      y, x, size, align);
	}

	private:
	std::string text_str;
	std::string colour_str;
	int y, x, size, align;
};

class DrawCircleDrawable : public Drawable {
	public:
	DrawCircleDrawable(const char *fill_str, const char *outline_str, 
	                   int y, int x, int radius) {
		this->fill = fill_str;
		this->outline = outline_str;
		this->y = y;
		this->x = x;
		this->radius = radius;
	}

	virtual void draw(void *L) {
		wx_draw_circle_internal(fill.c_str(), fill.size(), outline.c_str(), outline.size(), y, x, radius);
	}

	private:
	std::string fill;
	std::string outline;
	int y, x, radius;
};

class DrawLineDrawable : public Drawable {
	public:
	DrawLineDrawable(const char *colour_str, int line_size, int y1, int x1, int y2, int x2) {
		this->colour = colour_str;
		this->line_size = line_size;
		this->y1 = y1;
		this->x1 = x1;
		this->y2 = y2;
		this->x2 = x2;
	}

	virtual void draw(void *L) {
		wx_draw_line_internal(colour.c_str(), line_size, y1, x1, y2, x2);
	}

	private:
	std::string colour;
	int line_size;
	int y1, x1, y2, x2;
};

// TODO how do you allow the queue to automatically handle freeing these?
std::deque<Drawable*> drawable_queue;


ServerThread *g_server_thread = nullptr;
ClientThread *g_client_thread = nullptr;

static int hex_char_to_int(char c) {
	if ('0' <= c && c <= '9') {
		return c - '0';
	} else if ('a' <= c && c <= 'f') {
		return c - 'a' + 10;
	} else if ('A' <= c && c <= 'F') {
		return c - 'A' + 10;
	} else {
		fprintf(stderr, "invalid hex char %c (%x)\n", c, c);
		return -1;
	}
}

static char hex_char2_to_byte(char c1, char c2) {
	return (hex_char_to_int(c1)<<4) | hex_char_to_int(c2);
}

static wxColour colour_str_to_wxColour(const char *colour_str) {
	if (colour_str == nullptr) {
		fprintf(stderr, "colour_str is null\n");
		return wxNullColour;
	}
	if (colour_str[0] == '#') {
		colour_str++;
	}
	int len = strlen(colour_str);
	if (len == 3) {
		return wxColour(hex_char_to_int(colour_str[0])*16, 
		                hex_char_to_int(colour_str[1])*16, 
		                hex_char_to_int(colour_str[2])*16);
	} else if (len == 6) {
		return wxColour(hex_char2_to_byte(colour_str[0], colour_str[1]),
		                hex_char2_to_byte(colour_str[2], colour_str[3]),
		                hex_char2_to_byte(colour_str[4], colour_str[5]));
	} else if (len == 8) {
		return wxColour(hex_char2_to_byte(colour_str[0], colour_str[1]),
		                hex_char2_to_byte(colour_str[2], colour_str[3]),
		                hex_char2_to_byte(colour_str[4], colour_str[5]),
		                hex_char2_to_byte(colour_str[6], colour_str[7]));
	} else {
		fprintf(stderr, "invalid colour len %d\n", len);
		return wxNullColour;
	}
}

static wxPen colour_str_to_wxPen(const char *colour_str, int width=1) {
	return wxPen(colour_str_to_wxColour(colour_str), width);
}


static void wx_set_game_handle(const void *L, const char *game_id) {
	// TODO
	NOT_IMPL();
}


static void wx_get_game_id(const void *L, char *game_id_out, size_t game_id_out_max_len) {
	strncpy(game_id_out, g_game_id, game_id_out_max_len);
}

static void wx_draw_graphic(const char *img_id,
                            int y, int x,
                            int width, int height,
                            const struct draw_graphic_params *params) {
	if (g_canvas == nullptr) { return; }

	Drawable *drawable = new DrawGraphicDrawable(img_id, y, x, width, height, params);
	drawable_queue.push_back(drawable);
}

static void wx_draw_graphic_internal(const char *img_id, int y, int x, int width, int height, const struct draw_graphic_params *params) {

	//wxPaintDC dc(g_canvas);
	wxMemoryDC dc;
	dc.SelectObject(g_canvas->bmp);

#if 0
	std::unique_ptr<wxGraphicsContext> gc(wxGraphicsContext::Create(dc));
	//wxGraphicsContext *gc = wxGraphicsContext::Create(dc);
	
	if (gc.get() == nullptr) {
		fprintf(stderr, "could not create graphics context?\n");
		return;
	}
#endif

	if (images_map.find(img_id) == images_map.end()) {
		fprintf(stderr, "could not find image_id \"%s\"\n", img_id);
		return;
	}

	wxBitmap &bmp = images_map.at(img_id);
	//if (!bmp.isOk()) {
	if (false) {
		fprintf(stderr, "bmp %s is not OK\n", img_id);
		return;
	}

	//printf("drawing graphic \"%s\"\n", img_id);

	// TODO cache these reszied bitmaps?
	// It seems like a waste to do this every time,
	// most of the time the same resized images are drawn
	wxImage image = bmp.ConvertToImage();
	image.Rescale(width, height);
	wxBitmap bmp_resized(image, 1);
	// TODO need to handle rotation! (params->angle_degrees)
	// In "31s" at least, the other player's cards should be rotated 180 degrees
	// about their top left corner (I think)
	// TODO need to handle params->flip_y and flip_x
	
	//dc.DrawBitmap(bmp_resized, x - width/2, y - height/2);
	dc.DrawBitmap(image, x - width/2, y - height/2);

	//g_canvas->Refresh();
	if (!g_canvas->is_drawing) {
		g_canvas->Update();
	}
}
static void wx_draw_line(const char *colour_str, int line_width,
                         int y1, int x1,
                         int y2, int x2) {
	Drawable *d = new DrawLineDrawable(colour_str, line_width, y1, x1, y2, x2);
	drawable_queue.push_back(d);
}

int clip(int val, int l_lim, int r_lim) {
	if (val < l_lim) { return l_lim; }
	if (val > r_lim) { return r_lim; }
	return val;
}

static void wx_draw_line_internal(const char *colour_str, int line_width,
                         int y1, int x1,
                         int y2, int x2) {
	if (g_canvas == nullptr) { return; }
	//wxPaintDC dc(g_canvas);
	//printf("using memory dc?\n");
	//wxMemoryDC &dc = g_canvas->mdc;
	wxMemoryDC dc;
	dc.SelectObject(g_canvas->bmp);
	wxGraphicsContext *gc = wxGraphicsContext::Create(dc);
	if (gc == nullptr) {
		fprintf(stderr, "could not create graphics context?\n");
		return;
	}

    gc->SetPen(colour_str_to_wxPen(colour_str, line_width));
    //gc->SetBrush(colour_str_to_wxColour(colour_str)); // TODO I just added this to test, is it right?
    //gc->SetBrush(wxBrush("pink"));

	wxGraphicsPath path = gc->CreatePath();
    path.MoveToPoint(x1, y1);
	path.AddLineToPoint(x2, y2);

	gc->StrokePath(path);
	delete gc;

	g_canvas->Refresh();
	//g_canvas->Update();

}
static void wx_draw_text(const char *text_str, size_t text_str_len,
                  const char *colour_str, size_t colour_str_len,
                  int y, int x, int size, int align) {
	Drawable *d = new DrawTextDrawable(text_str, colour_str, y, x, size, align);
	drawable_queue.push_back(d);
}

static void wx_draw_text_internal(const char *text_str, size_t text_str_len,
                  const char *colour_str, size_t colour_str_len,
                  int y, int x, int size, int align) {
	wxMemoryDC dc;
	dc.SelectObject(g_canvas->bmp);

	wxFont font(size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	dc.SetFont(font);
	dc.SetBackgroundMode(wxTRANSPARENT);
	wxColour colour = colour_str_to_wxColour(colour_str);
	//printf("drawing_text %s with colour %s, #%02x%02x%02x%02x\n", text_str, colour_str, colour.Red(), colour.Green(), colour.Blue(), colour.Alpha());
	dc.SetTextForeground(colour_str_to_wxColour(colour_str));
	y -= dc.GetCharHeight(); // TODO I guess this is how it is in html?
	if (align == 0) {
		x -= strlen(text_str) * dc.GetCharWidth()/2;
	}
	wxCoord width, height;
	dc.GetTextExtent(text_str, &width, &height);
#if 0
	if (align == TEXT_ALIGN_LEFT) {
		// do nothing, this is the default
	} else if (align == TEXT_ALIGN_CENTRE) {
		// TODO why does this look so bad for solitaire cards?
		// is this not the definition of centre alignment?
		x -= width/2;
	} else if (align == TEXT_ALIGN_RIGHT) {
		x -= width;
	} else {
		fprintf(stderr, "Unexpected text align value %d\n", align);
	}
	dc.DrawText(text_str, wxPoint(x, y));
#else
	wxRect text_pos(x, y, width, height);
	int wx_align = wxALIGN_TOP;
	if (align == TEXT_ALIGN_LEFT) {
		wx_align |= wxALIGN_LEFT;
	} else if (align == TEXT_ALIGN_CENTRE) {
		wx_align |= wxALIGN_CENTRE;
	} else if (align == TEXT_ALIGN_RIGHT) {
		wx_align |= wxALIGN_RIGHT;
	} else {
		wx_align |= wxALIGN_LEFT;
		fprintf(stderr, "Unexpected text align value %d\n", align);
	}
	dc.DrawLabel(text_str, text_pos, wx_align);
#endif
}
static void wx_draw_rect(const char *fill_colour_str, size_t fill_colour_len,
                  int y_start, int x_start,
                  int y_end  , int x_end) {
	if (g_canvas == nullptr) { return; }

	Drawable *drawable = new DrawRectDrawable(fill_colour_str, fill_colour_len, y_start, x_start, y_end, x_end);
	drawable_queue.push_back(drawable);
	
}

static void wx_draw_rect_internal(const char *fill_colour_str, size_t fill_colour_len,
                  int y_start, int x_start,
                  int y_end  , int x_end) {
	//wxPaintDC dc(g_canvas);
	//wxMemoryDC &dc = g_canvas->mdc;
	wxMemoryDC dc;
	dc.SelectObject(g_canvas->bmp);
	wxGraphicsContext *gc = wxGraphicsContext::Create(dc);
	if (gc == nullptr) {
		fprintf(stderr, "could not create graphics context?\n");
		return;
	}
    //gc->SetPen(wxPen("navy"));
    //gc->SetBrush(wxBrush("pink"));
    gc->SetPen(wxNullPen);
    gc->SetBrush(colour_str_to_wxColour(fill_colour_str));

	// wxGraphicsPath path = gc->CreatePath();
    gc->DrawRectangle(x_start, y_start, x_end - x_start, y_end - y_start);
	delete gc;

	g_canvas->Refresh();
	//g_canvas->Update();
}

static void wx_draw_circle(const char *fill_colour_str,    size_t fill_colour_len,
                    const char *outline_colour_str, size_t outline_colour_len,
                    int y, int x, int radius, int outline_width) {
	Drawable *drawable = new DrawCircleDrawable(fill_colour_str, outline_colour_str, y, x, radius);
	drawable_queue.push_back(drawable);
}

static void wx_draw_triangle(const char *fill_colour_str,    size_t fill_colour_len,
                             int y1, int x1,
                             int y2, int x2,
                             int y3, int x3) {
	// TODO
	NOT_IMPL();
}
static void wx_draw_circle_internal(const char *fill_colour_str,    size_t fill_colour_len,
                    const char *outline_colour_str, size_t outline_colour_len,
                    int y, int x, int radius) {
	//NOT_IMPL();
	wxMemoryDC dc;
	dc.SelectObject(g_canvas->bmp);

	wxGraphicsContext *gc = wxGraphicsContext::Create(dc);

    gc->SetBrush(colour_str_to_wxColour(fill_colour_str));
    gc->SetPen(colour_str_to_wxColour(outline_colour_str));

	//gc->DrawCircle(wxPoint(x, y), radius);
	wxGraphicsPath path = gc->CreatePath();
	path.AddCircle(x, y, radius);

	gc->StrokePath(path);

	delete gc;
}
static void wx_draw_clear(void) {
	while (!drawable_queue.empty()) {
		Drawable *d = drawable_queue.front();
		drawable_queue.pop_front();
		delete d;
	}
}

static void wx_draw_clear_internal(void) {
	wxMemoryDC dc;
	dc.SelectObject(g_canvas->bmp);
	dc.Clear();
}

static void wx_draw_refresh(void) {
	// TODO could trigger refresh here to be more efficient?
}
static void wx_send_message(const char *dst, size_t dst_len, const char *msg, size_t msg_len) {
	//NOT_IMPL();
	std::string dst_str(dst);
	printf("Trying to send message to %s, %.*s...\n", dst, msg_len, msg);
	if (g_server_thread != nullptr) {
		printf("sending to server thread\n");
		g_server_thread->send_message(dst, (const uint8_t *)msg, msg_len);
	} else if (g_client_thread != nullptr) {
		printf("sending to client thread\n");
		g_client_thread->send_message(dst, (const uint8_t *)msg, msg_len);
	} else {
		printf("Neither client nor server thread initialized!\n");
	}
}
static void wx_create_btn(const char *btn_id_str, const char *btn_text_str, int weight) {
	g_frame->new_button(btn_id_str, btn_text_str, weight);
}
static void wx_set_btn_enabled(const char *btn_id_str, bool enabled) {
	g_frame->set_btn_enabled(btn_id_str, enabled);
}
static void wx_set_btn_visible(const char *btn_id_str, bool visible) {
	NOT_IMPL();
}
static void wx_hide_popup(void) {
	if (g_popup != nullptr) {
		g_popup->Show(false);
		// TODO figure out how to destroy this. Calling either of the below
		// result in a heap error?
		//g_popup->Destroy();
		//delete g_popup;
		g_popup = nullptr;
	}
}


static void wx_add_game_option(const char *option_id, const struct option_info *info) {
	// TODO
	NOT_IMPL();
}

static std::string get_time_str() {
	std::time_t t = std::time(0);
	std::tm* now = std::localtime(&t);
	char s_buff[128];
	snprintf(s_buff, sizeof(s_buff), "%02d:%02d:%02d:",
	         now->tm_hour, now->tm_min, now->tm_sec);
	return std::string(s_buff);
}
static void wx_set_status_msg(const char *msg, size_t msg_len) {
	// reset style in case we set it to red earlier
#if 1
	if (!g_is_dark_mode) {
		g_frame->statusText.SetDefaultStyle(wxTextAttr(*wxBLACK));
	} else {
		g_frame->statusText.SetDefaultStyle(wxTextAttr(*wxWHITE));
	}
#else
	// This doesn't actually seem to work for dark mode on macOS.
	g_frame->statusText.SetDefaultStyle(g_frame->statusText.GetDefaultStyle());
#endif

	g_frame->statusText.AppendText(wxT("\n"));
	g_frame->statusText.AppendText(wxString(get_time_str()));
	g_frame->statusText.AppendText(wxString(msg, msg_len));
	//g_frame->statusText.SetDefaultStyle(wxTextAttr(*wxBLACK));
}
static void wx_set_status_err(const char *msg, size_t msg_len) {
	g_frame->statusText.SetDefaultStyle(wxTextAttr(*wxRED));
	g_frame->statusText.AppendText(wxT("\n"));
	g_frame->statusText.AppendText(wxString(get_time_str()));
	g_frame->statusText.AppendText(wxT("ERR:"));
	g_frame->statusText.AppendText(wxString(msg, msg_len));
}

static void wx_handle_popup_btn_clicked(void *L, const char *popup_id, int popup_btn_id, const struct popup_state *popup_state) {
	game_api->handle_popup_btn_clicked(L, popup_id, popup_btn_id, popup_state);
}

static void game_selection_wx_handle_popup_btn_clicked(void *L, const char *popup_id, int popup_btn_id, const struct popup_state *popup_state) {
	strncpy(g_game_id, alex_get_game_name(popup_btn_id), sizeof(g_game_id));
	printf("Game ID is: %s\n", g_game_id);

	//g_popup->Show(false);
	g_popup->Destroy();
	g_popup = nullptr;

	g_frame->StartGame();
}

static void wx_show_popup(void *L,
                          const char *popup_id_ptr, size_t popup_id_str_len,
                          const struct popup_info *info) {
	// TODO implement new API that allows for more than just buttons
	#if 1
		//NOT_IMPL();

		if (g_popup != nullptr) {
			wx_hide_popup();
		}

		// TODO if g_popup is not null, destroy it
		std::string popup_id(popup_id_ptr, popup_id_str_len);
		std::cout << "Initializing game popup with lua handle " << L << std::endl;
		g_popup = new GamePopup(g_frame, popup_id, info, L);
		g_popup->set_popup_btn_pressed_callback(wx_handle_popup_btn_clicked);
		g_popup->Show(true);
	#else

//static void wx_show_popup(const char *popup_id, size_t popup_id_str_len,
//                  const char *title, size_t title_len,
//                  const char *msg, size_t msg_len,
//                  const char * const *btn_str_ary, size_t ary_len) {
	// TODO if g_popup is not null, destroy it

	/*g_popup = new wxDialog(g_frame, wxID_ANY, wxString(title, title_len),
	             wxDefaultPosition, wxSize(300, 400),
	             wxDEFAULT_DIALOG_STYLE | wxSTAY_ON_TOP);
	*/
	g_popup = new MyPopup(g_frame,
	                      wxString(popup_id, popup_id_str_len),
	                      wxString(title, title_len),
	                      wxString(msg, msg_len),
	                      btn_str_ary, ary_len);
	//(new wxButton(g_popup, wxID_OK, wxT("Close")))->Centre();
	//g_popup->ShowModal();
	g_popup->Show();
#endif
}

static void wx_prompt_string(const char *prompt_title, size_t prompt_title_len,
                             const char *prompt_msg, size_t prompt_msg_len) {
	NOT_IMPL();
}

class AlexGamesTimer : public wxTimer {
	public:
	AlexGamesTimer(MyCanvas *myCanvas) {
		this->myCanvas = myCanvas;
	}
	void Notify() {
		myCanvas->ReDrawIfNeeded();
	}

	private:
	MyCanvas *myCanvas;
};

static void wx_delete_timer(int timer_handle) {
	if (g_timers.find(timer_handle) == g_timers.end()) {
		char msg[1024];
		int bytes_written = snprintf(msg, sizeof(msg), "%s: Timer handle %d not found!", __func__, timer_handle);
		wx_set_status_err(msg, bytes_written);
		std::cerr << msg << std::endl;
		return;
	}

	AlexGamesTimer *timer = g_timers[timer_handle];
	g_timers.erase(timer_handle);
	timer->Stop();
	delete timer;
}

static int wx_update_timer_ms(int update_period_ms) {
#if 0
	if (g_timer != nullptr) {
		g_timer->Stop();
		delete g_timer;
		g_timer = nullptr;
	}
#endif
	if (update_period_ms > 0) {
		AlexGamesTimer *timer = new AlexGamesTimer(g_frame->canvas);
		timer->Start(update_period_ms);
		int timer_handle = g_timer_handle_idx;
		g_timer_handle_idx++;
		g_timers[timer_handle] =  timer;
		return timer_handle;
	}
	return 0;
}



static void wx_enable_evt(const char *evt_id, size_t evt_id_len) {
	printf("%s(evt_id=\"%s\")\n", __func__, evt_id);
	//if (strcmp(evt_id, "key") == 0) {
	if (std::string("key") == evt_id) {
		g_key_enabled = true;
	} else if (std::string("mouse_move") == evt_id) {
		g_mousemove_enabled = true;
	} else if (std::string("mouse_updown") == evt_id) {
		g_mouse_updown_enabled = true;
	} else {
		fprintf(stderr, "%s: evt_id = \"%s\" not supported on this platform\n", __func__, evt_id);
	}
}

static void wx_disable_evt(const char *evt_id_str, size_t evt_id_len) {
	NOT_IMPL();
}

// TODO move stuff like this into a common C++ implementation that can be relied upon
// by any other C++ implementations that don't need to be overridden in a platform
// specific way.
// e.g. the database stuff should default to an sqlite3 implementation on most
// platforms besides emscripten/wasm
static long wx_get_time_ms(void) {
	namespace sc = std::chrono;
	auto time = sc::system_clock::now();
	auto since_epoch = time.time_since_epoch();
	auto millis = sc::duration_cast<sc::milliseconds>(since_epoch);
	return millis.count();
}

static size_t wx_get_time_of_day(char *time_str, size_t max_time_str_len) {
	NOT_IMPL();	
	return 0;
}

struct msg_recvd_msg {
	const char *src;
	size_t src_len;
	const uint8_t *msg;
	size_t msg_len;
};

static void wx_handle_msg_received(const char *src, size_t src_len,
                                   const uint8_t *msg, size_t msg_len) {
	// TODO thread hop

	struct msg_recvd_msg *evt_msg = (struct msg_recvd_msg*)malloc(sizeof(struct msg_recvd_msg));
	evt_msg->src     = src;
	evt_msg->src_len = src_len;
	evt_msg->msg     = msg;
	evt_msg->msg_len = msg_len;

	wxCommandEvent event(wxEVT_COMMAND_TEXT_UPDATED, ALEX_CUSTOM_MSG_ID);
	event.SetClientData(evt_msg);
	g_frame->GetEventHandler()->AddPendingEvent(event);
	
	//handle_msg_received(L, src, src_len, (const char*)msg, msg_len);
	//free((void*)msg);
}

static void wx_handle_client_connected(const char *client_name, size_t client_name_len) {
	static const char ctrl_src[] = "ctrl";
	char buff[1024];
	int msg_len = snprintf(buff, sizeof(buff), "player_joined:");
	// TODO is this actually used? I don't think "wait_for_players" lib uses it
	game_api->handle_msg_received(L, ctrl_src, sizeof(ctrl_src), buff, msg_len);
}

MyCanvas::MyCanvas(MyFrame *parent)
        : wxScrolledWindow(parent, wxID_ANY, wxDefaultPosition, wxDefaultSize,
                           wxHSCROLL | wxVSCROLL),
		  bmp(480, 480) {
}

void MyCanvas::OnPaint(wxPaintEvent &event) {
	// TODO removing the below line seems to fix the stuttering.
	// I'm not sure why. This shouldn't be re-entrant. Add logs here if is_drawing is true
	//if (is_drawing) { return; }

	this->is_drawing = true;
	int dt_ms = 0;
	int current_time_ms = wx_get_time_ms();
	if (g_last_draw_board != 0) {
		dt_ms = current_time_ms - g_last_draw_board;
	}
	g_last_draw_board = current_time_ms;
	//std::cout << "calling update with dt_ms=" << dt_ms << ", current_time=" << current_time_ms << std::endl;

	if (game_api != NULL && game_api->update != NULL) {
		game_api->update(L, dt_ms);
	} else {
		std::cerr << "Warning: game_api->update is not set, perhaps the game failed to load?" << std::endl;
	}

	wx_draw_clear_internal();
	if (g_is_dark_mode) {
		static const char COLOUR_BLACK[] = "#000000";
		wx_draw_rect_internal(COLOUR_BLACK, sizeof(COLOUR_BLACK),
		                      0, 0,
		                      480, 480);
	}
	for (auto drawable : drawable_queue) {
		drawable->draw(L);
	}

	wxPaintDC dc(this);
	dc.DrawBitmap(bmp, 0, 0);
	this->is_drawing = false;
	
}

void MyCanvas::ReDrawIfNeeded(void) {
	// TODO this seems to be needed on MacOS ... why?
	Refresh();
	Update();
}

void MyCanvas::OnMouseMove(wxMouseEvent &event) {
	if (!g_mousemove_enabled) {
		return;
	}
	// TODO get buttons and make sure it matches the same
	// format as HTML (and this should be defined
	// in game_api.h
	int buttons = 0;
	if (is_drawing) { return; }
	this->is_drawing = true;
	//printf("MyCanvas::OnMouseMove calling handle_mousemove\n");
	game_api->handle_mousemove(L, event.GetY(), event.GetX(), buttons);
	//printf("MyCanvas::OnMouseMove done calling handle_mousemove\n");
	//printf("MyCanvas::OnMouseMove calling g_canvas->Update()\n");
	g_canvas->Update();
	//printf("MyCanvas::OnMouseMove done calling g_canvas->Update()\n");
	this->is_drawing = false;

	event.Skip();
	ReDrawIfNeeded();
}
void MyCanvas::OnMouseDown(wxMouseEvent &event) {
	int buttons = 0; // TODO

	if (g_mouse_updown_enabled) {
		game_api->handle_mouse_evt(L, MOUSE_EVT_DOWN, event.GetY(), event.GetX(), buttons);
	}

	// TODO do something better with this
	game_api->handle_user_clicked(L, event.GetY(), event.GetX());
	event.Skip();
	ReDrawIfNeeded();
}
void MyCanvas::OnMouseUp(wxMouseEvent &event) {
	if (!g_mouse_updown_enabled) {
		return;
	}
	int buttons = 0; // TODO
	game_api->handle_mouse_evt(L, MOUSE_EVT_UP,   event.GetY(), event.GetX(), buttons);
	event.Skip();
	ReDrawIfNeeded();
}

wxBEGIN_EVENT_TABLE(MyCanvas, wxScrolledWindow)
    EVT_PAINT  (MyCanvas::OnPaint)
    EVT_MOTION (MyCanvas::OnMouseMove)
    EVT_LEFT_DOWN (MyCanvas::OnMouseDown)
    EVT_LEFT_UP (MyCanvas::OnMouseUp)
wxEND_EVENT_TABLE()




// frame constructor
MyFrame::MyFrame(const wxString& title)
       : wxFrame(NULL, wxID_ANY, title, wxDefaultPosition, wxSize(480,630)),
         //statusText(this, wxID_ANY)
         statusText(this, wxID_ANY, wxEmptyString, wxDefaultPosition, wxDefaultSize,
                    wxTE_MULTILINE | wxTE_RICH, 
		            wxDefaultValidator, wxTextCtrlNameStr)
{
	this->sizer = new wxBoxSizer(wxVERTICAL);
	this->button_sizer = new wxBoxSizer(wxHORIZONTAL);
    // set the frame icon
    //SetIcon(wxICON(sample));

	statusText.SetEditable(false);
	sizer->Add(&statusText, 1, wxEXPAND);

	this->canvas = new MyCanvas(this);
	g_canvas = this->canvas;
	sizer->Add(canvas, 7, wxEXPAND);

	sizer->Add(button_sizer, 0, wxEXPAND);

	this->SetSizer(sizer);

#if 1
    // create a menu bar
    wxMenu *fileMenu = new wxMenu;

    // the "About" item should be in the help menu
    wxMenu *helpMenu = new wxMenu;
    helpMenu->Append(wxID_ABOUT, "&About\tF1", "Show about dialog");
    fileMenu->Append(MENU_ITEM_START_GAME, "Start", "Start game");
    fileMenu->Append(MENU_ITEM_GAME_SELECT, "Select game", "Select different game");
    fileMenu->Append(MENU_ITEM_NETWORK_SETTINGS, "Network settings", "Host or join a server for multiplayer");

    fileMenu->Append(wxID_EXIT, "E&xit\tAlt-X", "Quit this program");

    // now append the freshly created menu to the menu bar...
    wxMenuBar *menuBar = new wxMenuBar();
    menuBar->Append(fileMenu, "&File");
    menuBar->Append(helpMenu, "&Help");

    // ... and attach this menu bar to the frame
    SetMenuBar(menuBar);
#endif // wxUSE_MENUS

#if 1
    // create a status bar just for fun (by default with 1 pane only)
    CreateStatusBar(2);
    SetStatusText("Welcome to wxWidgets!");
#endif // wxUSE_STATUSBAR
}


void MyFrame::new_button(const char *btn_id_str, const char *btn_text_str, int weight) {
	std::string btn_id(btn_id_str);
	wxButton *btn = new wxButton(this, wxID_ANY, wxString(btn_text_str));
	this->buttons[btn_id] = btn;
	this->button_sizer->Add(btn, weight);
	this->Layout();

	struct clickHandler {
		public:
		clickHandler(std::string btn_id) {
			this->btn_id = btn_id;
		}
		void operator()(wxCommandEvent &) const {
			game_api->handle_btn_clicked(L, btn_id.c_str());
			g_canvas->ReDrawIfNeeded();
		}
		private:
		std::string btn_id;
	};
	struct clickHandler handler(btn_id);
	buttons[btn_id]->Bind(wxEVT_COMMAND_BUTTON_CLICKED, handler, wxID_ANY);
}

void MyFrame::set_btn_enabled(const char *btn_id_str, bool is_enabled) {
	std::string btn_id(btn_id_str);
	auto btn_it = this->buttons.find(btn_id);
	if (btn_it == this->buttons.end()) {
		char msg[1024];
		int msg_len = snprintf(msg, sizeof(msg), "set_btn_enabled: btn_id \"%s\" not found", btn_id_str);
		wx_set_status_err(msg, msg_len);
		return;
	}

	wxButton *btn = btn_it->second;

	btn->Enable(is_enabled);
}


// event handlers

void MyFrame::OnQuit(wxCommandEvent& WXUNUSED(event))
{
    destroy_sqlite_saved_state(g_saved_state);
    // true is to force the frame to close
    Close(true);
}

void MyFrame::OnAbout(wxCommandEvent& WXUNUSED(event))
{
    wxMessageBox(wxString::Format
                 (
                    "Welcome to %s!\n"
                    "\n"
                    "This is the minimal wxWidgets sample\n"
                    "running under %s.",
                    wxVERSION_STRING,
                    wxGetOsDescription()
                 ),
                 "About wxWidgets minimal sample",
                 wxOK | wxICON_INFORMATION,
                 this);
}

void print_bin_str(const char *msg, const uint8_t *data, int len) {
	printf("%s: ", msg);
	for (int i=0; i<len; i++) {
		printf("%02x ", data[i]);
	}
	printf("\n");
}

void MyFrame::handle_msg_recvd(wxCommandEvent &evt) {
	std::cout << "handle_msg_recvd, handling message after thread hop" << std::endl;

	struct msg_recvd_msg *msg = (struct msg_recvd_msg*)evt.GetClientData();
	print_bin_str("handle_msg_recvd", msg->msg, msg->msg_len);
	game_api->handle_msg_received(L, msg->src, msg->src_len, (const char*)msg->msg, msg->msg_len);
	free((void*)msg->msg);
	free((void*)msg);
}

static std::string key_str(std::string prefix, char c) {
	char c_str[] = { c, 0 };
	return std::string(prefix) + std::string(c_str);
}

static std::string wx_key_event_to_alexgames_key_str(const wxKeyEvent& evt) {
	if ('A' <= evt.GetKeyCode() && evt.GetKeyCode() <= 'Z') {
		return key_str("Key", evt.GetKeyCode());
	} else if ('0' <= evt.GetKeyCode() && evt.GetKeyCode() <= '9') {
		return key_str("Digit", evt.GetKeyCode());
	} else if (WXK_F1 <= evt.GetKeyCode() && evt.GetKeyCode() <= WXK_F9) {
		return key_str("F", evt.GetKeyCode() - WXK_F1 + '1');
	}
	else if (evt.GetKeyCode() == WXK_F10) { return "F10"; }
	else if (evt.GetKeyCode() == WXK_F11) { return "F11"; }
	else if (evt.GetKeyCode() == WXK_F12) { return "F12"; }

	switch(evt.GetKeyCode()) {
		// is it possible to distinguish between left and right control/shift?
		// It looks like it can't be: https://wiki.wxwidgets.org/KeyCodes
		case WXK_CONTROL: return "ControlLeft"; 
		case WXK_SHIFT:   return "ShiftLeft";
		case WXK_ALT:
#if 0
			if (evt.GetModifiers() & wxMOD_ALT) {
				return "AltLeft"; 
			} else if (evt.GetModifiers() & wxMOD_META) {
				return "OSLeft"; 
			}
#endif
			// TODO dammit, meta and alt seem to map to the same key code
			// I guess I'd have to add state to track the modifiers?
			// I doubt most games should really be using these keys anyway
			return "AltLeft";

		case WXK_ESCAPE:  return "Escape"; 
		case WXK_TAB:     return "Tab"; 
		case WXK_SPACE:   return "Space";
		case WXK_RETURN:  return "Enter";
		case WXK_BACK:    return "Backspace";
		case WXK_UP:      return "ArrowUp";
		case WXK_LEFT:    return "ArrowLeft";
		case WXK_RIGHT:   return "ArrowRight";
		case WXK_DOWN:    return "ArrowDown";
		case '`':         return "Backquote";
		case '-':         return "Minus";
		case '=':         return "Equal";

		// ugh this is confusing, to me a "bracket" is `[`
		// But this is what HTML does, and perhaps following an existing (nearly universally supported?)
		// standard is better than inventing a new one.
		case '[':         return "BracketLeft";
		case ']':         return "BracketRight";

		case ';':         return "Semicolon";
		case '/':         return "Slash";
		case '\\':        return "Backslash";
		case '.':         return "Period";
		case ',':         return "Comma";
		case '\'':        return "Quote";
		default: return "";
	}
}

void MyCanvas::handle_key_down_evt(wxKeyEvent &evt) {
	if (!g_key_enabled) {
		return;
	}
	//LogEvent("KeyDown", evt);
	//std::cout << "MyCanvas::handle_key_down_evt " << evt.GetKeyCode() << std::endl;

	std::string key_code;
	if (evt.GetKeyCode() == WXK_ALT) {
		// It looks like there is a bug where the modifiers are cleared if you
		// press/release ctrl/alt/meta/shift in different orders.
		// I can see this when running the `keyboard` sample app in gtk wxWidgets on ArchLinux.
		// hmm unless it's a bug with my keyboard? Blah. I don't know who tracks the modifiers.
		// surely it isn't the keyboard.

		// For just meta and alt I was able to workaround it by implementing logic like below,
		// but this is too messy.
		// For now just don't handle alt or meta, games probably shouldn't be
		// getting the user to press those anyway.
		return;
#if 0
		bool now_alt_down  = (evt.GetModifiers() & wxMOD_ALT)  > 0;
		bool now_meta_down = (evt.GetModifiers() & wxMOD_META) > 0;

		if (now_alt_down != alt_down && 
		    now_meta_down != meta_down) {
			// I'm not sure if this is a bug or what, but
			// when trying the keyboard sample app in gtk wxWidgets on ArchLinux,
			// I see the meta modifier closed when releasing alt while holding meta.
			// (swapping meta and alt doesn't have this issue)
			key_code = "AltLeft";
			now_meta_down = this->meta_down;
		}
		else if (now_alt_down != alt_down) {
			key_code = "AltLeft";
		} else if (now_meta_down != meta_down) {
			key_code = "OSLeft";
		} else {
			fprintf(stderr, "%s err: prev: %b, %b; now: %b %b\n", __func__, alt_down, meta_down, now_alt_down, now_meta_down);
		}
		printf("%s, on processing keycode %s up, updating alt: %b, meta: %b. (prev alt %b, meta %b)\n", 
		       __func__, key_code.c_str(), now_alt_down, now_meta_down, alt_down, meta_down);

		this->alt_down  = now_alt_down;
		this->meta_down = now_meta_down;
#endif
	} else {
		key_code = wx_key_event_to_alexgames_key_str(evt);
		if (key_code.size() == 0) {
			std::cerr << "Handling for keycode " << evt.GetKeyCode() << " not defined." << std::endl;
			return;
		}
	}


	//std::cout << "Sending keydown \"" << key_code << "\" to game" << std::endl;
	game_api->handle_key_evt(L, "keydown", key_code.c_str());
	ReDrawIfNeeded();
}

void MyCanvas::handle_key_up_evt(wxKeyEvent &evt) {
	if (!g_key_enabled) {
		return;
	}
	//LogEvent("KeyDown", evt);
	//std::cout << "MyCanvas::handle_key_up_evt " << evt.GetKeyCode() << std::endl;

	std::string key_code;
	if (evt.GetKeyCode() == WXK_ALT) {
		// see the comment in handle_key_up_evt
		return;
#if 0
		bool now_alt_down  = (evt.GetModifiers() & wxMOD_ALT)  > 0;
		bool now_meta_down = (evt.GetModifiers() & wxMOD_META) > 0;

		if (now_alt_down != alt_down &&
		    now_meta_down != meta_down) {
			// TODO this seems like a bug
			key_code = "AltLeft";
			now_meta_down = this->meta_down;
		} else if (now_alt_down != alt_down) {
			key_code = "AltLeft";
		} else if (now_meta_down != meta_down) {
			key_code = "OSLeft";
		} else {
			fprintf(stderr, "%s err: prev: %b, %b; now: %b %b\n", __func__, alt_down, meta_down, now_alt_down, now_meta_down);
		}
		printf("%s, on processing keycode %s up, updating alt: %b, meta: %b. (prev alt %b, meta %b)\n", 
		       __func__, key_code.c_str(), now_alt_down, now_meta_down, alt_down, meta_down);
		this->alt_down  = now_alt_down;
		this->meta_down = now_meta_down;
#endif
	} else {
		key_code = wx_key_event_to_alexgames_key_str(evt);
		if (key_code.size() == 0) {
			std::cerr << "Handling for keycode " << evt.GetKeyCode() << " not defined." << std::endl;
			return;
		}
	}

	//std::cout << "Sending keyup   \"" << key_code << "\" to game" << std::endl;
	game_api->handle_key_evt(L, "keyup", key_code.c_str());

	ReDrawIfNeeded();
}

//void MyFrame::handle_key_evt(wxKeyEvent &evt) {
//	//LogEvent("KeyDown", evt);
//	std::cout << "MyFrame::handle_key_evt " << evt.GetKeyCode() << std::endl;
//}



static void load_images() {
    wxPathList pathList;

	// If this isn't called, loading PNGs will fail
	wxInitAllImageHandlers();
	
    pathList.Add(wxT("."));

	for (int i=0; i<ARY_LEN(IMAGES_TABLE); i++) {
		const char *rel_path_str = IMAGES_TABLE[i].img_path;
		char path_str[2048];
		if (strlen(ROOT_DIR) > 0) {
			snprintf(path_str, sizeof(path_str), "%s/%s", ROOT_DIR, rel_path_str);
		} else {
			snprintf(path_str, sizeof(path_str), "%s", rel_path_str);
		}
    	wxString path = pathList.FindValidPath(wxString(path_str));
		if (!path) {
			fprintf(stderr, "path %s not found\n", path_str);
			return;
		}
		//wxBitmap *bmp = new wxBitmap;
    	//bmp->LoadFile(path, wxBITMAP_TYPE_BMP);

		FILE *f = fopen(path_str, "rb");
		if (f == NULL) {
			fprintf(stderr, "Error opening file \"%s\"\n", path_str);
			continue;
		}
		fseek(f, 0L, SEEK_END);
		size_t f_size = ftell(f);
		fseek(f, 0L, SEEK_SET);
		void *f_data = malloc(f_size);
		size_t total_bytes_read = 0;
		size_t bytes_read;
		char *ptr = (char*)f_data;
		size_t bytes_requested = 1024;
		do {
			bytes_read = fread(ptr, 1, bytes_requested, f);
			ptr += bytes_read;
			total_bytes_read += bytes_read;
			//printf("read %d bytes\n", bytes_read);
		} while (bytes_read == bytes_requested);
		fclose(f);

		assert(total_bytes_read == f_size);
		wxBitmap bmp = wxBitmapHelpers::NewFromPNGData(f_data, f_size);

		/*
		for (int i=0; i<f_size; i++) {
			printf("%02x ", ((unsigned char*)f_data)[i]);
			if (i % 40 == 0 && i != 0) {
				printf("\n");
			}
		}
		*/

		free(f_data);
		if (!bmp.IsOk()) {
			fprintf(stderr, "Error loading bitmap \"%s\"\n", path_str);
			continue;
		}
		images_map[IMAGES_TABLE[i].img_id] = bmp;
	}

}

static void wx_store_data(void *L, const char *key, const uint8_t *value, size_t value_len) {
	set_value(g_saved_state, key, value, value_len);
}
static size_t wx_read_stored_data(void *L, const char *key, uint8_t *value_out, size_t max_val_len) {
	return get_value(g_saved_state, key, value_out, max_val_len);
}

static int wx_get_new_session_id(void) {
	return saved_state_db_get_new_session_id(g_db_state_handler);
}

static int wx_get_last_session_id(const char *game_id) {
	return saved_state_db_get_last_session_id(g_db_state_handler, game_id);
}

static void wx_save_state(int session_id, const uint8_t *state, size_t state_len) {
	saved_state_db_save_state(g_db_state_handler, g_game_id, session_id, state, state_len);
}

static bool wx_has_saved_state_offset(int session_id, int move_id_offset) {
	return saved_state_db_has_saved_state_offset(g_db_state_handler, session_id, move_id_offset);
}
static int wx_get_saved_state_offset(int session_id, int move_id_offset, uint8_t *state_out, size_t max_state_out) {
	return saved_state_db_get_saved_state_offset(g_db_state_handler, session_id, move_id_offset, state_out, max_state_out);
}
void wx_draw_extra_canvas(const char *img_id,
	                      int y, int x,
	                      int width, int height) {
	NOT_IMPL();
}
static void wx_new_extra_canvas(const char *canvas_id) {
	NOT_IMPL();
}
static void wx_set_active_canvas(const char *canvas_id) {
	NOT_IMPL();
}
static void wx_delete_extra_canvases(void) {
	NOT_IMPL();
}

static size_t wx_get_user_colour_pref(char *colour_pref_out, size_t max_colour_pref_out_len) {
#if 0
	static bool show_not_impl_msg = true;
	if (show_not_impl_msg) {
		NOT_IMPL();
		show_not_impl_msg = false;
	}
#endif
	size_t bytes_written = snprintf(colour_pref_out, max_colour_pref_out_len, g_is_dark_mode ? "dark" : "light");
	return bytes_written;
}


static bool wx_is_feature_supported(const char *feature_id, size_t feature_id_len) {
	return false;
}

static void wx_destroy_all(void) {
	NOT_IMPL();
}


static void host_server(const char *server_addr) {
	std::string port_str(server_addr);

	int port;
	if (port_str.size() > 0) {
		port = std::stoi(port_str);
	} else {
		port = DEFAULT_PORT;
	}

	printf("Host server on port %d\n", port);
	g_server_thread = new ServerThread(g_frame, port);
	wxThreadError rc = g_server_thread->Create();
	if (rc != wxTHREAD_NO_ERROR) {
		printf("Error creating thread\n");
		return;
	}

	g_server_thread->set_handle_msg_recvd_callback(wx_handle_msg_received);
	g_server_thread->set_client_connected_callback(wx_handle_client_connected);
	rc = g_server_thread->Run();

	if (rc != wxTHREAD_NO_ERROR) {
		printf("Error running thread\n");
		return;
	}
}

static void join_server(const char *server_addr) {

	std::string addr(server_addr);
	int port;

	int port_str_idx = addr.find(':');
	if (port_str_idx != std::string::npos) {
		std::string port_str = addr.substr(port_str_idx+1, addr.size() - port_str_idx-1);
		addr = addr.substr(0, port_str_idx);
		port = std::stoi(port_str);
	} else {
		port = DEFAULT_PORT;
	}

	printf("Join server at addr =\"%s\", port=%d\n", addr.c_str(), port);

	g_client_thread = new ClientThread(g_frame, addr, port);
	wxThreadError rc = g_client_thread->Create();
	if (rc != wxTHREAD_NO_ERROR) {
		printf("Error creating thread\n");
		return;
	}

	g_client_thread->set_handle_msg_recvd_callback(wx_handle_msg_received);
	rc = g_client_thread->Run();

	if (rc != wxTHREAD_NO_ERROR) {
		printf("Error running thread\n");
		return;
	}
}


void MyFrame::StartGame(wxCommandEvent &event) {
	StartGame();
}
void MyFrame::StartGame() {
	//static const char game_id[] = "go";
	//static const char game_id[] = "life";
	//static const char game_id[] = "31s";
	//static const char game_id[] = "solitaire";
	//static const char game_id[] = "card_sim";
	//static const char game_id[] = "life";
	//static const char game_id[] = "minesweeper";
	//static const char game_id[] = "snake";
	//static const char game_id[] = "word_mastermind";
	//L = start_lua_game(&api, get_lua_game_path(game_id, sizeof(game_id)));
	if (g_game_id[0] == '\0') {
		printf("Game not selected\n");
		// TODO show a game selection UI
		return;
	}
	L = alex_init_game(&api, g_game_id, strnlen(g_game_id, sizeof(g_game_id)));
	if (L == nullptr) {
		fprintf(stderr, "init_game returned nullptr\n");
		return;
	}

	game_api->start_game(L, -1, 0, 0);
	g_canvas->ReDrawIfNeeded();
}

static void dark_mode_init(void) {
	wxColour colour = wxSystemSettingsNative::GetColour(wxSYS_COLOUR_WINDOW);
	std::cout << "SYS_COLOUR_WINDOW returned: " << colour.GetAsString() << std::endl;
	if (colour.Red() < 128) {
		g_is_dark_mode = true;
	}
}

void MyApp::OnInitCmdLine(wxCmdLineParser& parser) {
	parser.SetDesc(g_cmdLineDesc);
	parser.SetSwitchChars(wxT("-"));
}

bool MyApp::OnCmdLineParsed(wxCmdLineParser& parser) {
	wxString game_val;
	if (parser.Found(wxT("game"), &game_val)) {
		// NOTE: you must cast c_str() to char* to use in vararg functions
		// See https://docs.wxwidgets.org/3.0/classwx_string.html
		// "Using wxString with vararg functions"
		printf("Found game param, game = \"%s\"\n", (const char*)game_val.c_str());
		strncpy(g_game_id, (const char*)game_val.c_str(), sizeof(g_game_id));
	} else {
		strncpy(g_game_id, "", sizeof(g_game_id));
		printf("Did not find game param\n");
	}

	return true;
}

void MyFrame::GameSelect(wxCommandEvent &event) {
	GameSelect();
}

void MyFrame::GameSelect() {
	const char popup_id[] = "game_selection";
	struct popup_info info = empty_popup_info();
	for (int game_idx=0; game_idx<alex_get_game_count(); game_idx++) {
		printf("%3d: %s\n", game_idx, alex_get_game_name(game_idx));
		popup_info_add_button(&info, game_idx, alex_get_game_name(game_idx));
	}
	printf("Sizeof popup_info: %d\n", sizeof(struct popup_info));
	g_popup = new GamePopup(g_frame, popup_id, &info, nullptr);
	g_popup->set_popup_btn_pressed_callback(game_selection_wx_handle_popup_btn_clicked);
	g_popup->Show(true);
	//g_popup->ShowModal();
}


void MyFrame::ShowNetworkSettings(wxCommandEvent &event) {
	ShowNetworkSettings();
}

void MyFrame::ShowNetworkSettings() {
	g_network_popup->set_default_port(DEFAULT_PORT);
	g_network_popup->set_host_server_callback(host_server);
	g_network_popup->set_join_server_callback(join_server);
	g_network_popup->Show(true);
}

bool MyApp::OnInit()
{
    // call the base class initialization method, currently it only parses a
    // few common command-line options but it could be do more in the future
    if ( !wxApp::OnInit() )
        return false;

	alexgames_set_mutex_take_func(wx_mutex_take);
	alexgames_set_mutex_release_func(wx_mutex_release);

	g_saved_state = init_sqlite_saved_state("alexgames_state.db");
	if (g_saved_state == nullptr) {
		std::cerr << "Error initializing saved state" << std::endl;
		return false;
	}

	g_db_state_handler = saved_state_db_init(NULL, &api);

	
#if 0
	printf("Building word dict from file...\n");
	void *dict_handle = build_word_dict_from_file("words-en.txt");
	printf("Done building bword dict from file, p=%p\n", dict_handle);
	struct word_dict_frame *dict_handle2 = (struct word_dict_frame*)dict_handle;
#endif

	load_images();

	wx_network_init();

	dark_mode_init();


    // create the main application window
    g_frame = new MyFrame("AlexGames");
	wxCommandEvent derp;

	std::cout << "connecting handle_key_evt to wxEVT_KEY_DOWN" << std::endl;
	g_frame->canvas->Connect(wxEVT_KEY_DOWN, wxKeyEventHandler(MyCanvas::handle_key_down_evt), nullptr, g_frame->canvas);
	g_frame->canvas->Connect(wxEVT_KEY_UP,   wxKeyEventHandler(MyCanvas::handle_key_up_evt), nullptr, g_frame->canvas);

	if (g_game_id[0] != '\0') {
		g_frame->StartGame(derp);
	} else {
		printf("Game not selected, please select a game from the popup shown.\n");
		g_frame->GameSelect();
	}

	g_network_popup = new NetworkPopup(g_frame);

    // and show it (the frames, unlike simple controls, are not shown when
    // created initially)
    g_frame->Show(true);

	//update(L);

    // success: wxApp::OnRun() will be called which will enter the main message
    // loop and the application will run. If we returned false here, the
    // application would exit immediately.
    return true;
}

// TODO I just made this define up when trying to build on windows.
// need to set it if the OS is actually windows.
//#warning "if you're on windows, need to fix this line"
#ifdef WIN32
int main(void) {
	return WinMain(0, 0, 0, 0);
}
#endif
