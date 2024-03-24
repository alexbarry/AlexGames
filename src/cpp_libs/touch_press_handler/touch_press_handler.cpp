#include "touch_press_handler.h"

#include<sstream>
#include<string>

TouchPress TouchPress::NoTouch() {
	TouchPress info;
	info.pressed = false;
	return info;
}
TouchPress TouchPress::Touch(float y, float x) {
	TouchPress info;
	info.pressed = true;
	info.y = y;
	info.x = x;
	return info;
}

extern const game_api_callbacks* g_callbacks;

TouchPress TouchPressHandler::handle_touch_evt(std::string evt_id,
	                                           const struct touch_info *changed_touches,
	                                           int changed_touches_len) {
	for (int idx=0; idx<changed_touches_len; idx++) {
		const struct touch_info *touch = (changed_touches + idx);
		if (this->active_touch_present) {
		       if (this->active_touch.id == touch->id) {
					if (evt_id == "touchcancel" ||
					    (evt_id == "touchmove" &&
					     abs(touch->y - this->active_touch.y) > max_touch_move &&
			             abs(touch->x - this->active_touch.x) > max_touch_move)) {
						this->active_touch_present = false;
					} else if (evt_id == "touchend") {
						this->active_touch_present = false;
					     if (abs(touch->y - this->active_touch.y) < max_touch_move &&
			                 abs(touch->x - this->active_touch.x) < max_touch_move) {
							return TouchPress::Touch(touch->y, touch->x);
						}
					}
					
		       }
		} else {
			if (evt_id == "touchstart") {
				this->active_touch_present = true;
				this->active_touch = *touch;
			}	
		}
	}
	return TouchPress::NoTouch();
}

