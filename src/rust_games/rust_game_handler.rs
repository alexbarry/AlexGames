
fn init_reversi(_callbacks: *const u8) -> *const u8 {
	// TODO
	let data: u8 = 0;
	println!("Hello from the init_reversi function!");
	return &data;
}

fn get_rust_game_init_func(game_id: &str) -> Option<fn(*const u8) -> *const u8> {
	return match game_id {
		"reversi" => Some(init_reversi),
		_         => None,
	}
}

fn c_str_to_str(str_ptr: *const u8, str_len: usize) -> String {
	let bytes_slice = unsafe { std::slice::from_raw_parts(str_ptr, str_len) };

	let str_slice = std::str::from_utf8(bytes_slice).expect("could not convert C string to string");

	return String::from(str_slice);
}

#[no_mangle]
pub extern fn rust_game_supported(game_str_ptr: *const u8, game_str_len: usize) -> bool {
	let game_id = c_str_to_str(game_str_ptr, game_str_len);

	println!("Game ID is {}, hello from rust!", game_id);

	return get_rust_game_init_func(&game_id).is_some();
}

#[no_mangle]
pub extern fn start_rust_game(game_str_ptr: *const u8, game_str_len: usize, callbacks: *const u8) -> *const u8 {
	let game_id = c_str_to_str(game_str_ptr, game_str_len);

	println!("Game ID is {}, hello from rust!", game_id);

	let game_init_fn = get_rust_game_init_func(&game_id).expect("game id not handled");

	return game_init_fn(callbacks);
}
