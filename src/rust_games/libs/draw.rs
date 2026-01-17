
use crate::rust_game_api::{CCallbacksPtr};

pub fn draw_rect_outline(callbacks: &CCallbacksPtr, colour: &str, width: i32, y1: i32, x1: i32, y2: i32, x2: i32) {
	callbacks.draw_line(colour, width, y1 - width/2, x1 - width/2, y2 + width/2, x1 - width/2);
	callbacks.draw_line(colour, width, y1, x1, y1, x2);
	callbacks.draw_line(colour, width, y1 - width/2, x2 + width/2, y2 + width/2, x2 + width/2);
	callbacks.draw_line(colour, width, y2, x1, y2, x2);
}
