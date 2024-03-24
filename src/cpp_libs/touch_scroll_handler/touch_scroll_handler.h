#include<stdint.h>

#include "game_api.h"

struct TouchScrollHandlerPoint {
	double y;
	double x;
};

class TouchScrollHandler {
	public:
	struct TouchScrollHandlerPoint handle_touch_evt(const char *evt_id_str, int evt_id_str_len, 
	                                                void *changed_touches, int changed_touches_len);

	private:
	bool active_touch_present = false;
	touch_id_t active_touch;
	double prev_touch_screen_y_pos;
	double prev_touch_screen_x_pos;

};
