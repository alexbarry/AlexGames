#pragma once
#include "game_api.h"

#include<string>

class TouchPress {
	public:
	static TouchPress NoTouch();
	static TouchPress Touch(float y, float x);
	bool pressed;
	float y;
	float x;
};

class TouchPressHandler {
	public:
	TouchPress handle_touch_evt(std::string evt_id_str,
	                            const struct touch_info *changed_touches,
	                            int changed_touches_len);

	private:
	bool active_touch_present = false;
	struct touch_info active_touch;
	int max_touch_move = 20;
};
