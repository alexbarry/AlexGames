use libc;
use core::slice;
use std::ffi::CString;
//use std::mem::transmute;

//use std::sync::Arc;

// TODO remove, this file shouldn't have to reference each game
use crate::reversi::reversi_core;

use libc::{c_int, c_char, size_t, c_void, c_long};

// TODO maybe change game_api.h to use int instead...
// apparently the official type in Rust libc for stdbool.h bool is TBD
// https://stackoverflow.com/a/47705543/9596600
type c_bool = bool;

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
	draw_clear: Option<unsafe extern "C" fn()>,
	draw_refresh: Option<unsafe extern "C" fn()>,

	send_message: Option<unsafe extern "C" fn(*const c_char, size_t, *const c_char, size_t)>,

	create_btn: Option<unsafe extern "C" fn(*const c_char, *const c_char, c_int)>,
	set_btn_enabled: Option<unsafe extern "C" fn(*const c_char, c_bool)>,
	set_btn_visible: Option<unsafe extern "C" fn(*const c_char, c_bool)>,
	hide_popup: Option<unsafe extern "C" fn()>,

	// TODO add params
	add_game_option: Option<unsafe extern "C" fn()>,

	set_status_msg: Option<unsafe extern "C" fn(*const c_char, size_t)>,
	set_status_err: Option<unsafe extern "C" fn(*const c_char, size_t)>,

	// TODO
	show_popup: Option<unsafe extern "C" fn()>,

	prompt_string: Option<unsafe extern "C" fn(*const c_char, size_t,
	                                           *const c_char, size_t)>,

	update_timer_ms: Option<unsafe extern "C" fn(c_int)>,
	delete_timer: Option<unsafe extern "C" fn(c_int)>,

	enable_evt: Option<unsafe extern "C" fn(*const c_char, size_t)>,
	disable_evt: Option<unsafe extern "C" fn(*const c_char, size_t)>,

	get_time_ms: Option<unsafe extern "C" fn() -> c_long>,
	get_time_of_day: Option<unsafe extern "C" fn(*mut c_char, size_t)>,

	store_data: Option<unsafe extern "C" fn(*mut c_void,
	                                        *const c_char,
	                                        *const u8, size_t)>,
	read_stored_data: Option<unsafe extern "C" fn(*mut c_void,
	                                              *const c_char, *mut u8, size_t) -> size_t>,
	get_new_session_id: Option<unsafe extern "C" fn() -> c_int>,
	get_last_session_id: Option<unsafe extern "C" fn(*const c_char) -> c_int>,

	save_state: Option<unsafe extern "C" fn(c_int, *const u8, size_t)>,
	has_saved_state_offset: Option<unsafe extern "C" fn(c_int, c_int) -> c_bool>,
	adjust_saved_state_offset: Option<unsafe extern "C" fn(c_int, c_int, *mut u8, size_t) -> size_t>,

	draw_extra_canvas: Option<unsafe extern "C" fn(*const c_char, c_int, c_int, c_int, c_int)>,
	new_extra_canvas: Option<unsafe extern "C" fn(*const c_char)>,
	set_active_canvas: Option<unsafe extern "C" fn(*const c_char)>,
	delete_extra_canvases: Option<unsafe extern "C" fn()>,

	//get_user_colour_pref: Option<unsafe extern "C" fn(*mut c_char, size_t) -> size_t>, // TODO
	get_user_colour_pref: Option<unsafe extern "C" fn(*mut u8, size_t) -> size_t>,

	is_feature_supported: Option<unsafe extern "C" fn(*const c_char, size_t) -> c_bool>,

	destroy_all: Option<unsafe extern "C" fn()>,
}

impl CCallbacksPtr {
	unsafe fn call_draw_rect(&self, fill: &str, y1: i32, x1: i32, y2: i32, x2: i32) {
		let fill_len = fill.len();
		let fill = CString::new(fill).expect("CString::new failed");
		if let Some(draw_rect) = self.draw_rect {
			draw_rect(fill.as_ptr() as *const c_char, fill_len,
			          y1, x1, y2, x2);
		} else {
			println!("draw_rect is null");
		}
	}

	unsafe fn call_draw_circle(&self, fill: &str, outline: &str, y: i32, x: i32, radius: i32, outline_width: i32) {
		let fill_len = fill.len();
		let fill = CString::new(fill).expect("CString::new failed");

		let outline_len = outline.len();
		let outline = CString::new(outline).expect("CString::new failed");
		if let Some(draw_circle) = self.draw_circle {
			//draw_circle(fill.as_ptr()    as *const c_char, fill.len(),
			//            outline.as_ptr() as *const c_char, outline.len(),
			draw_circle(fill.as_ptr()   , fill_len,
			            outline.as_ptr(), outline_len,
			            y, x, radius, outline_width);
		} else {
			println!("draw_circle is null");
		}
	}

	unsafe fn call_draw_line(&self, line_colour: &str, line_size: i32, y1: i32, x1: i32, y2: i32, x2: i32) {
		let line_colour_cstr = CString::new(line_colour).expect("CString::new failed");
		//let line_colour_cstr: *const c_char = [ '#', '0', '0', '8', '8', '0', '0', 0 as c_char ];
		//let line_colour_cstr = b"#008800\0";
		//println!("calling draw_line...");
		unsafe {
			if let Some(draw_line) = self.draw_line {
				//println!("calling ptr...");
				let line_colour_cstr = line_colour_cstr.as_ptr();
				//let line_colour_cstr = line_colour_cstr.as_bytes_with_nul();
				//let line_colour_cstr = line_colour_cstr as *const i8;
				(draw_line)(line_colour_cstr, line_size,
				            y1, x1, y2, x2);
				//println!("done calling ptr");
			} else {
				println!("draw_line is null");
			}
		}
		//println!("done calling draw_line!");
	}

	pub fn create_btn(&self, btn_id: &str, btn_text: &str, weight: i32) {
		let btn_id_cstr   = CString::new(btn_id).expect("CString::new failed");
		let btn_text_cstr = CString::new(btn_text).expect("CString::new failed");

		if let Some(create_btn) = self.create_btn {
			unsafe {
				(create_btn)(btn_id_cstr.as_ptr(), btn_text_cstr.as_ptr(), weight);
			}
		} else {
			println!("create_btn is null");
		}
	}

	pub fn set_btn_enabled(&self, btn_id: &str, is_enabled: bool) {
		let btn_id_cstr   = CString::new(btn_id).expect("CString::new failed");

		if let Some(set_btn_enabled) = self.set_btn_enabled {
			unsafe {
				(set_btn_enabled)(btn_id_cstr.as_ptr(), is_enabled);
			}
		} else {
			println!("set_btn_enabled is null");
		}
	}


	pub fn set_status_err(&self, msg: &str) {
		let msg_cstr = CString::new(msg).expect("CString::new failed");
		if let Some(set_status_err) = self.set_status_err {
			unsafe {
				(set_status_err)(msg_cstr.as_ptr(), msg.len());
			}
		} else {
			println!("set_status_err is null");
		}
	}
	pub fn set_status_msg(&self, msg: &str) {
		let msg_cstr = CString::new(msg).expect("CString::new failed");
		if let Some(set_status_msg) = self.set_status_msg {
			unsafe {
				(set_status_msg)(msg_cstr.as_ptr(), msg.len());
			}
		} else {
			println!("set_status_msg is null");
		}
	}

	pub fn get_new_session_id(&self) -> i32 {
		if let Some(get_new_session_id) = self.get_new_session_id {
			unsafe {
				return (get_new_session_id)();
			}
		} else {
			println!("get_new_session_id is null");
			return 0;
		}
	}

	pub fn get_last_session_id(&self, game_id: &str) -> Option<i32> {
		let game_id_cstr = CString::new(game_id).expect("CString::new failed");
		if let Some(get_last_session_id) = self.get_last_session_id {
			unsafe {
				let session_id = (get_last_session_id)(game_id_cstr.as_ptr());
				if session_id != -1 {
					return Some(session_id);
				}
			}
		} else {
			println!("get_last_session_id is null");
		}
		return None;
	}

	pub fn save_state(&self, session_id: i32, state: Vec<u8>) {
		if let Some(save_state) = self.save_state {
			unsafe {
				(save_state)(session_id, state.as_ptr(), state.len());
			}
		} else {
			println!("save_state is null");
		}
	}

	pub fn has_saved_state_offset(&self, session_id: i32, move_id_offset: i32) -> bool {
		if let Some(has_saved_state_offset) = self.has_saved_state_offset {
			unsafe {
				return (has_saved_state_offset)(session_id, move_id_offset);
			}
		} else {
			println!("has_saved_state_offset is null");
			return false;
		}
	}

	pub fn adjust_saved_state_offset(&self, session_id: i32, move_id_offset: i32) -> Option<Vec<u8>> {
		if let Some(adjust_saved_state_offset) = self.adjust_saved_state_offset {
			
			let buff_size = 16*1024; // TODO define a common constant in C for this max size
			let mut buffer: Vec<u8> = Vec::with_capacity(buff_size);
			let buff_ptr = buffer.as_mut_ptr();
			unsafe {
				let state_len = (adjust_saved_state_offset)(session_id, move_id_offset, buff_ptr, buff_size);
				if state_len > 0 {
					let state_vec = Vec::from_raw_parts(buff_ptr, state_len, state_len);
					return Some(state_vec);
				}
			}
		} else {
			println!("has_saved_state_offset is null");
		}
		return None;
	}

	pub fn get_user_colour_pref(&self) -> String {
		//return "dark"; // TODO
		if let Some(get_user_colour_pref) = self.get_user_colour_pref {
			let buff_size = 512;
			//let mut buffer: Vec<c_char> = Vec::with_capacity(buff_size); // TODO
			let mut buffer: Vec<u8> = Vec::with_capacity(buff_size);
			unsafe {
				let colour_pref_len = (get_user_colour_pref)(buffer.as_mut_ptr(), buff_size);
				if colour_pref_len > 0 {
					let slice = slice::from_raw_parts(buffer.as_ptr(), colour_pref_len);
					if let Ok(user_colour_pref) = std::str::from_utf8(slice) {
						println!("user_colour_pref is {}", user_colour_pref);
						return String::from(user_colour_pref);
					} else {
						println!("Error decoding user colour preference string");
					}
				}
			}
		} else {
			println!("get_user_colour_pref is null");
		}
		return String::from("light");
	}
}

#[derive(Debug)]
pub struct GameApi {
	pub init: fn(*const CCallbacksPtr) -> Box <GameState>,
	//pub start_game: fn(handle: &mut RustGameState, state: *const u8, state_len: size_t) -> (),
	pub start_game: fn(handle: &mut RustGameState, state: Option<(i32, Vec<u8>)>) -> (),
	pub update: fn(handle: &mut RustGameState, dt_ms: i32) -> (),
	pub handle_user_clicked: fn(handle: &mut RustGameState, pos_y: i32, pos_x: i32) -> (),
	pub handle_btn_clicked: fn(handle: &mut RustGameState, btn_id: &str) -> (),
	pub get_state: fn(handle: &mut RustGameState) -> Option<Vec<u8>>,
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

	pub fn draw_line(&self, line_colour: &str, line_size: i32, y1: i32, x1: i32, y2: i32, x2: i32) {
		unsafe {
			//self.callbacks.as_ref().expect("null ptr?").call_draw_line(line_colour, line_size, y1, x1, y2, x2);
			let callbacks = self.callbacks.as_ref();
			if let Some(callbacks) = callbacks {
				callbacks.call_draw_line(line_colour, line_size, y1, x1, y2, x2);
			}
		}
	}

	pub fn create_btn(&self, btn_id: &str, btn_text: &str, weight: i32) {
		unsafe {
			if let Some(callbacks) = self.callbacks.as_ref() {
				callbacks.create_btn(btn_id, btn_text, weight);
			}
		}
	}

	pub fn set_btn_enabled(&self, btn_id: &str, is_enabled: bool) {
		unsafe {
			if let Some(callbacks) = self.callbacks.as_ref() {
				callbacks.set_btn_enabled(btn_id, is_enabled);
			}
		}
	}
	pub fn set_status_msg(&self, msg: &str) {
		unsafe {
			if let Some(callbacks) = self.callbacks.as_ref() {
				callbacks.set_status_msg(msg);
			}
		}
	}

	pub fn set_status_err(&self, msg: &str) {
		unsafe {
			if let Some(callbacks) = self.callbacks.as_ref() {
				callbacks.set_status_err(msg);
			}
		}
	}
} 
