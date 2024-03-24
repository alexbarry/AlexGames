#include "mouse_scroll_handler.h"


int MouseScrollHandler::handle_mousemove(int pos_y, int pos_x, int buttons) {
	if (this->mouse_left) {
		if (buttons & 1) {
			this->mouse_left = false;
			this->last_mouse_y = pos_y;
		} else {
			this->mouse_down = false;
			this->mouse_left = false;
		}
	}

	if (this->mouse_down) {
		int diff = pos_y - this->last_mouse_y;
		this->last_mouse_y = pos_y;
		return diff;
	} else {
		return 0;
	}
}

void MouseScrollHandler::handle_mouse_evt(int mouse_evt_id, int pos_y, int pos_x) {
	if (mouse_evt_id == MOUSE_EVT_DOWN) {
		this->mouse_left = false;
		this->mouse_down = true;
		this->last_mouse_y = pos_y;
	} else if (mouse_evt_id == MOUSE_EVT_UP) {
		this->mouse_down = false;
	} else if (mouse_evt_id == MOUSE_EVT_LEAVE) {
		this->mouse_left = true;
	}
}

