#include "button_helper.h"

ButtonHelper::ButtonHelper(void *handle) {
	this->handle = handle;
}

ButtonInfo ButtonInfo::fromSize(std::string text, int y_start, int x_start, int y_size, int x_size, btn_id_t btn_id, button_callback_t callback) {
	ButtonInfo btn_info;
	btn_info.text = text;
	btn_info.y_start = y_start;
	btn_info.x_start = x_start;
	btn_info.y_end   = y_start + y_size;
	btn_info.x_end   = x_start + x_size;
	btn_info.btn_id  = btn_id;
	btn_info.callback = callback;
	return btn_info;
}

void ButtonHelper::new_button(ButtonInfo btn_info) {
	this->button_info.push_back(btn_info);
}

bool ButtonHelper::handle_user_pressed(int y_pos, int x_pos) {
	for (auto btn_info : this->button_info) {
		if (btn_info.y_start <= y_pos && y_pos <= btn_info.y_end &&
		    btn_info.x_start <= x_pos && x_pos <= btn_info.x_end) {
			btn_info.callback(this->handle, btn_info.btn_id);
			return true;
		}
	}
	return false;
}


bool ButtonHelper::handle_touch_evt(std::string evt_id,
	                            const struct touch_info *changed_touches,
								int changed_touches_len) {
	TouchPress press_info = touch_press_handler.handle_touch_evt(evt_id,
	                                                             changed_touches,
	                                                             changed_touches_len);
	if (press_info.pressed) {
		return this->handle_user_pressed(press_info.y, press_info.x);
	}
	return false;
}

void ButtonHelper::draw_buttons(const struct game_api_callbacks *callbacks) {
	for (auto btn_info : this->button_info) {
		int y_centre = btn_info.y_start + (btn_info.y_end - btn_info.y_start)/2;
		int x_centre = btn_info.x_start + (btn_info.x_end - btn_info.x_start)/2;
		callbacks->draw_rect(btn_colour.c_str(),    btn_colour.size(),
		                     btn_info.y_start, btn_info.x_start,
		                     btn_info.y_end,   btn_info.x_end);
		#if 0
		struct draw_graphic_params params = default_draw_graphic_params();
		callbacks->draw_graphic("more_info_btn",
		                        btn_info.y_start, btn_info.x_start,
		                        btn_info.x_end - btn_info.x_start,
		                        btn_info.y_end - btn_info.y_start, &params);
		#endif
		callbacks->draw_text(btn_info.text.c_str(), btn_info.text.size(),
		                     btn_text_colour.c_str(), btn_text_colour.size(),
		                     y_centre + btn_text_size/2, x_centre, btn_text_size, 0);
	}
}
