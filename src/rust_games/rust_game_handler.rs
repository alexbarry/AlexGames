mod rust_game_api;
mod reversi;

use std::ptr;
use std::slice;

//use libc;
use std::ffi::CString;
//use std::mem::transmute;

//use std::sync::Arc;

//use libc::{c_int, c_char, size_t};
use libc::{size_t, c_char};


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

// TODO these should use libc types (c_int, etc)
#[no_mangle]
pub extern "C" fn rust_game_api_handle_user_clicked(handle: &mut RustGameState, pos_y: i32, pos_x: i32) {
	println!("rust_handle_user_clicked: {} {}", pos_y, pos_x);
	println!("rust_handle_user_clicked: {:#?}", handle.api.handle_user_clicked);
	(handle.api.handle_user_clicked)(handle, pos_y, pos_x);
}

#[no_mangle]
pub extern "C" fn rust_game_api_handle_btn_clicked(handle: &mut RustGameState, btn_id_cstr: *const u8) {
	// TODO there must be a built in way to do this, but I don't have internet right now
	let byte_count = 1024;
	let mut str_end_pos: usize = 0;
	for i in 0..=byte_count {
		//if btn_id_cstr.wrapping_add(i) == std::ptr::null() {
		let val = unsafe { *btn_id_cstr.add(i) };
		println!("Checking i={}, val is {:#?}", i, val);
		if val == 0 {
			str_end_pos = i;
			println!("breaking");
			break;
		}
		if i == byte_count {
			println!("Could not find terminating null in first {} bytes of string passed to handle_btn_clicked", byte_count);
			return;
		}
	}
	let mut btn_id: &str;
	unsafe {
		let slice = slice::from_raw_parts(btn_id_cstr, str_end_pos);
		if let Ok(btn_id_val) = std::str::from_utf8(slice) {
			btn_id = btn_id_val;
		} else {
			println!("Error decoding btn_id string");
			return;
		}
	}
	(handle.api.handle_btn_clicked)(handle, btn_id);
}

#[no_mangle]
pub extern "C" fn rust_game_api_update(handle: &mut RustGameState, dt_ms: i32) {
	println!("rust_update: {} (dbg: {:#?}, {:#?}", dt_ms, handle.api, handle.api.update);
	(handle.api.update)(handle, dt_ms);
}

#[no_mangle]
pub extern "C" fn rust_game_api_start_game(handle: &mut RustGameState, session_id: i32, state_ptr: *const u8, state_len: usize) {
	println!("rust_game_api_start_game");
	let mut session_id_and_state: Option<(i32, Vec<u8>)> = None;
	if state_len > 0 {
		unsafe {
			let slice = slice::from_raw_parts(state_ptr, state_len);
			session_id_and_state = Some( (session_id, Vec::from(slice)) );
		}
	}
	(handle.api.start_game)(handle, session_id_and_state);
}

#[no_mangle]
pub extern "C" fn rust_game_api_get_state(handle: &mut RustGameState, state_out: *mut u8, state_out_max_len: size_t) -> size_t {
	println!("rust_game_api_get_state");
	let state = (handle.api.get_state)(handle);

	if !state.is_some() {
		return 0;
	}
	let state = state.expect("state should be some at this point");

	if state.len() > state_out_max_len {
		handle.set_status_err(&format!("get_state: state is {} bytes long but buffer is only {}", state_out_max_len, state.len()));
		// TODO can I return -1 here? I don't know if I even checked for this case
		// before.
		return 0;
	}

	unsafe {
		ptr::copy_nonoverlapping(state.as_ptr(), state_out, state.len()); 
	}

	return state.len();
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


#[no_mangle]
pub extern "C" fn rust_game_api_destroy_game(handle: *mut RustGameState) {
	// TODO call game specific destroy
	unsafe { Box::from_raw(handle); }
}
