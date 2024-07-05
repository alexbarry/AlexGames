//use std::os::raw::{c_char, c_int, c_uchar};

use web_sys::console;


extern "C" {
	fn alexgames_print(str_ptr: *const u8, str_len: usize);
}

fn my_print(s: &str) {
	unsafe {
		alexgames_print(s.as_ptr(), s.len());
	}
}

#[macro_export]
macro_rules! my_println {
    ($($arg:tt)*) => {
		// TODO figure out how to get this working, I was getting linker errors
		// when I tried to use it. I'm not sure where the library is that
		// contains dependencies like this
        console::log_1(&format!($($arg)*).into());
        //my_print(&format!($($arg)*));
    }
}

/*
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
*/

#[no_mangle]
//pub extern "C" fn rust_game_supported(game_str_ptr: *const u8, game_str_len: usize) -> bool {
pub extern "C" fn rust_game_supported() {
	my_print("Hello from rust!");
	my_println!("Here's another print from rust, but using web-sys console!");
	//my_print("(not macro) Here's another print from rust, but using web-sys console!");
	//let my_tmp_str = format!("Hello world!");
	let my_tmp_str = ("Hello world!");
	my_print(&my_tmp_str);
	my_print("Hello from rust again! Why does the above macro fail??");
	//println!("Hello from rust!");
/*
	let game_id = c_str_to_str(game_str_ptr, game_str_len);

	println!("Game ID is {}, hello from rust!", game_id);

	return get_rust_game_init_func(&game_id).is_some();
*/
}

/*

#[no_mangle]
pub extern "C" fn start_rust_game(game_str_ptr: *const u8, game_str_len: usize, callbacks: *const u8) -> *const u8 {
	let game_id = c_str_to_str(game_str_ptr, game_str_len);

	println!("Game ID is {}, hello from rust!", game_id);

	let game_init_fn = get_rust_game_init_func(&game_id).expect("game id not handled");

	return game_init_fn(callbacks);
}
*/
