
use crate::rust_game_api::{
    AlexGamesApi, CCallbacksPtr, MouseEvt, OptionInfo, OptionType, TextAlign, TouchInfo,
    CANVAS_HEIGHT, CANVAS_WIDTH,
};

use crate::morse::morse_core::{self};


pub struct Draw {
	callbacks: &'static CCallbacksPtr,
}

impl Draw {

	pub fn new(callbacks: &'static CCallbacksPtr) -> Self {
		Draw {
			callbacks
		}
	}
		
	pub fn draw(&self, game_state: &morse_core::State) {
			self.callbacks.draw_clear();

			let BTN_RADIUS_OFF = 50;
			let BTN_RADIUS_ON = 100;
			let BTN_OUTLINE_THICKNESS_ON = 10;
			let PADDING = 10;

			let btn_pos_y = CANVAS_HEIGHT - BTN_RADIUS_ON - BTN_OUTLINE_THICKNESS_ON - PADDING;
			let btn_pos_x = CANVAS_WIDTH/2;

			let (fill, outline, outline_thickness, btn_radius) = if !game_state.btn_is_down() {
				("#888", "#888", 3, BTN_RADIUS_OFF)
			} else {
				//("#aa0", "#ff0", BTN_OUTLINE_THICKNESS_ON, BTN_RADIUS_ON)
				("#aa01", "#ff01", BTN_OUTLINE_THICKNESS_ON, BTN_RADIUS_ON)
			};
			self.callbacks.draw_circle(&fill, &outline, btn_pos_y, btn_pos_x, btn_radius, outline_thickness);

			let txt_colour = "#888";
			let txt_size = 32;
			let txt_padding = 5;
			let txt_pos_y = txt_size + txt_padding;
			let txt_pos_y2 = txt_pos_y * 2;
			//let txt_pos_x = txt_padding;
			let txt_pos_x = CANVAS_WIDTH/2;

			let text_readable = game_state.get_text_readable();
			self.callbacks.draw_text(&text_readable, &txt_colour, txt_pos_y, txt_pos_x, txt_size, TextAlign::Right);
			let text_morse_dits = game_state.get_text_morse_dits();
			self.callbacks.draw_text(&text_morse_dits, &txt_colour, txt_pos_y2, txt_pos_x, txt_size, TextAlign::Right);

			self.callbacks.draw_refresh();
	}
	
}
