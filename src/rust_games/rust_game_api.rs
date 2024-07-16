use libc;
//use std::ffi::CString;
//use std::mem::transmute;

//use std::sync::Arc;

// TODO remove, this file shouldn't have to reference each game
use crate::reversi::reversi_core;

use libc::{c_int, c_char, size_t, c_void};

pub const CANVAS_WIDTH:  i32 = 480;
pub const CANVAS_HEIGHT: i32 = 480;


#[repr(C)]
pub struct CCallbacksPtr {
	set_game_handle: Option<unsafe extern "C" fn(*mut c_void, *const c_char)>,
	get_game_id: Option<unsafe extern "C" fn(*mut c_void, *mut c_char, size_t)>,
	draw_graphic: Option<unsafe extern "C" fn(*const c_char, c_int, c_int, c_int, c_int, *mut c_void)>,
	draw_line: Option<unsafe extern "C" fn(*const c_char, c_int, c_int, c_int, c_int, c_int)>,
	draw_text: Option<unsafe extern "C" fn(*const c_char, size_t, *const c_char, size_t,
	                                       c_int, c_int, c_int, c_int)>,
	draw_rect: Option<unsafe extern "C" fn(*const c_char, size_t,
	                                       c_int, c_int, c_int, c_int)>,

	draw_triangle: Option<unsafe extern "C" fn(*const c_char, size_t,
	                                           c_int, c_int, c_int, c_int, c_int, c_int)>,
	draw_circle: Option<unsafe extern "C" fn(*const c_char, size_t,
	                                         *const c_char, size_t,
	                                         c_int, c_int, c_int, c_int)>,
}

impl CCallbacksPtr {
	unsafe fn call_draw_rect(&self, fill: &str, y1: i32, x1: i32, y2: i32, x2: i32) {
		if let Some(draw_rect) = self.draw_rect {
			draw_rect(fill.as_ptr() as *const c_char, fill.len(),
			          y1, x1, y2, x2);
		} else {
			println!("draw_rect is null");
		}
	}

	unsafe fn call_draw_circle(&self, fill: &str, outline: &str, y: i32, x: i32, radius: i32, outline_width: i32) {
		if let Some(draw_circle) = self.draw_circle {
			draw_circle(fill.as_ptr()    as *const c_char, fill.len(),
			            outline.as_ptr() as *const c_char, outline.len(),
			            y, x, radius, outline_width);
		} else {
			println!("draw_circle is null");
		}
	}
}

pub struct GameApi {
	pub init: fn(*const CCallbacksPtr) -> Box <GameState>,
	pub start_game: fn(handle: &mut RustGameState) -> (),
	pub update: fn(handle: &mut RustGameState, dt_ms: i32) -> (),
	pub handle_user_clicked: fn(handle: &mut RustGameState, pos_y: i32, pos_x: i32) -> (),
}

/*
pub trait GameState {
}
*/

// TODO this file shouldn't have to reference each game individually,
// figure out how to properly generalize this in rust like a void pointer
pub enum GameState {
	ReversiGameState(reversi_core::State),
}

pub struct RustGameState {
	pub api:       GameApi,
	pub callbacks: *const CCallbacksPtr,
	//pub game_state: Box<GameState>,
	pub game_state: GameState,
}

impl RustGameState {
/*
	pub fn draw_rect(&mut self, fill_colour: &str, y_start: i32, x_start: i32, y_end: i32, x_end: i32) {
		(self.callbacks.draw_rect)(fill_colour, y_start, x_start, y_end, x_end);
	}
*/
	//pub fn draw_rect(&mut self, fill_colour: &str, y_start: i32, x_start: i32, y_end: i32, x_end: i32) {
	pub fn draw_rect(&self, fill_colour: &str, y_start: i32, x_start: i32, y_end: i32, x_end: i32) {
		unsafe {
			self.callbacks.as_ref().expect("null ptr?").call_draw_rect(fill_colour, y_start, x_start, y_end, x_end);
		}
	}

	pub fn draw_circle(&self, fill_colour: &str, outline_colour: &str, y: i32, x: i32, radius: i32, outline_width: i32) {
		unsafe {
			self.callbacks.as_ref().expect("null ptr?").call_draw_circle(fill_colour, outline_colour, y, x, radius, outline_width);
		}
	}
} 
