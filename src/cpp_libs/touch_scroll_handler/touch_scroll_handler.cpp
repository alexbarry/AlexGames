#include <string>
#include <iostream>

#include "touch_scroll_handler.h"

static struct TouchScrollHandlerPoint CreateTouchScrollHandlerPoint(double y, double x) {
	struct TouchScrollHandlerPoint pt;
	pt.y = y;
	pt.x = x;
	return pt;
}

struct TouchScrollHandlerPoint TouchScrollHandler::handle_touch_evt(const char *evt_id_str, int evt_id_str_len, 
                                                                    void *changed_touches, int changed_touches_len) {
	std::string evt_id(evt_id_str);

	struct touch_info *touches = (struct touch_info *)changed_touches;

	//std::cout << "handle_touch_evt, id=" << evt_id << ", touch_len:" << changed_touches_len << std::endl;

	if (this->active_touch_present) {
		for (int i=0; i<changed_touches_len; i++) {
			if (touches[i].id == this->active_touch) {
				if (evt_id == "touchmove") {
					double diff_y = touches[i].y - this->prev_touch_screen_y_pos;
					double diff_x = touches[i].x - this->prev_touch_screen_x_pos;
					this->prev_touch_screen_y_pos = touches[i].y;
					this->prev_touch_screen_x_pos = touches[i].x;
					return CreateTouchScrollHandlerPoint(diff_y, diff_x);
				} else if (evt_id == "touchend" || evt_id == "touchcancel" /* TODO? */ ) {
					this->active_touch_present = false;
					this->active_touch = 0;
				}
			}
		}
	} else {
		if (evt_id == "touchstart" && changed_touches_len > 0) {
			this->active_touch = touches[0].id;
			this->prev_touch_screen_y_pos = touches[0].y;
			this->prev_touch_screen_x_pos = touches[0].x;
			this->active_touch_present = true;
		}
	}
	//return 0;
	return CreateTouchScrollHandlerPoint(0, 0);

}
