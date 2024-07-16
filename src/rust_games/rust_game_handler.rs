mod rust_game_api;
mod reversi;

//use libc;
//use std::ffi::CString;
//use std::mem::transmute;

//use std::sync::Arc;

//use libc::{c_int, c_char, size_t};


use reversi::reversi_main;
use rust_game_api::{GameApi, RustGameState, CCallbacksPtr};

fn get_rust_game_init_func(game_id: &str) -> Option<fn(*const CCallbacksPtr) -> GameApi> {
	return match game_id {
		"reversi" => Some(reversi_main::init_reversi),
		_         => None,
	}
}

fn c_str_to_str(str_ptr: *const u8, str_len: usize) -> String {
	let bytes_slice = unsafe { std::slice::from_raw_parts(str_ptr, str_len) };

	let str_slice = std::str::from_utf8(bytes_slice).expect("could not convert C string to string");

	return String::from(str_slice);
}

#[no_mangle]
pub extern "C" fn rust_game_api_handle_user_clicked(handle: &mut RustGameState, pos_y: i32, pos_x: i32) {
	println!("rust_handle_user_clicked: {} {}", pos_y, pos_x);
	println!("rust_handle_user_clicked: {:#?}", handle.api.handle_user_clicked);
	(handle.api.handle_user_clicked)(handle, pos_y, pos_x);
}

#[no_mangle]
pub extern "C" fn rust_game_api_update(handle: &mut RustGameState, dt_ms: i32) {
	println!("rust_update: {} (dbg: {:#?}, {:#?}", dt_ms, handle.api, handle.api.update);
	(handle.api.update)(handle, dt_ms);
}

#[no_mangle]
pub extern "C" fn rust_game_api_start_game(handle: &mut RustGameState, _session_id: i32, _state: *const u8, _state_len: usize) {
	println!("rust_game_api_start_game");
	(handle.api.start_game)(handle);
}


fn c_ptr_to_callbacks(callbacks: *const u8) -> *const CCallbacksPtr {
	let callbacks = callbacks as *const CCallbacksPtr;
	return callbacks;
}

#[no_mangle]
pub extern "C" fn rust_game_supported(game_str_ptr: *const u8, game_str_len: usize) -> bool {
	let game_id = c_str_to_str(game_str_ptr, game_str_len);

	println!("Game ID is {}, hello from rust!", game_id);

	return get_rust_game_init_func(&game_id).is_some();
}

#[no_mangle]
pub extern "C" fn start_rust_game_rust(game_str_ptr: *const u8, game_str_len: usize, callbacks: *const CCallbacksPtr) -> *mut RustGameState {
	let game_id = c_str_to_str(game_str_ptr, game_str_len);

	println!("Game ID is {}, hello from rust!", game_id);

	let game_init_fn = get_rust_game_init_func(&game_id).expect("game id not handled by rust");

	//let callbacks = c_ptr_to_callbacks(callbacks);

	let api = game_init_fn(callbacks);

	println!("from start_rust_game_rust: rust_handle_user_clicked: {:#?}", api.handle_user_clicked);

	let game_state = (api.init)(callbacks);
	let game_state = *game_state;

	//let handle = &mut RustGameState {
	let handle = RustGameState {
		api:        api,
		callbacks:  callbacks,
		game_state: game_state,
	};

	let handle = Box::new(handle);
	// TODO need to add a free function on destroy game
	return Box::into_raw(handle);
}
