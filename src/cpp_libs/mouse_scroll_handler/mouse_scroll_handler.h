#include "game_api.h"

class MouseScrollHandler {

	public:
	int handle_mousemove(int pos_y, int pos_x, int buttons);
	void handle_mouse_evt(int mouse_evt_id, int pos_y, int pos_x);
	
	private:
	bool mouse_down = false;
	bool mouse_left = false;
	int last_mouse_y;
};
