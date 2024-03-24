#include "game_api.h"
#include "touch_press_handler.h"

#include<string>
#include<vector>

typedef int btn_id_t;
typedef void(*button_callback_t)(void *L, btn_id_t btn_id);

class ButtonInfo;

/**
 * Client registers button positions, this class can 
 * draw them, and handle detecting clicks on them.
 */
class ButtonHelper {

	public:
	ButtonHelper(void *handle);
	void new_button(ButtonInfo btn_info);
	bool handle_user_pressed(int y_pos, int x_pos);
	bool handle_touch_evt(std::string evt_id_str,
	                      const struct touch_info *changed_touches,
	                      int changed_touches_len);
	void draw_buttons(const struct game_api_callbacks *callbacks);

	private:

	std::string btn_colour      = "#aaaaaaaa";
	std::string btn_text_colour = "#000000";
	TouchPressHandler touch_press_handler;
	int btn_text_size = 18;
	void *handle;
	std::vector<ButtonInfo> button_info;

};

// private class
class ButtonInfo {
	public:
	static ButtonInfo fromSize(std::string text, int y_start, int x_start, int y_size, int x_size, btn_id_t btn_id, button_callback_t callback);
	std::string text;
	int y_start;
	int x_start;
	int y_end;
	int x_end;
	btn_id_t btn_id;
	button_callback_t callback;
};

