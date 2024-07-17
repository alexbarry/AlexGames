use bincode;

use crate::rust_game_api;

use crate::rust_game_api::{RustGameState, CANVAS_HEIGHT, CANVAS_WIDTH};

// TODO there must be a better way than this? This file is in the same directory
use crate::reversi::reversi_core;
use crate::reversi::reversi_core::{Pt, ReversiErr};

/*
impl rust_game_api::GameState for reversi_core::State {
}
*/

static BTN_ID_UNDO: &str = "btn_undo";
static BTN_ID_REDO: &str = "btn_redo";

fn rc_to_err_msg(err: ReversiErr) -> &'static str {
	match err {
		ReversiErr::InvalidMove => "Invalid move",
		ReversiErr::NotYourTurn => "Not your turn",
	}
}

fn update(handle: &mut RustGameState, _dt_ms: i32) {
	println!("rust: update called");
	//draw_state(&handle.game_state as reversi_core::State);
	draw_state(handle);
}


fn handle_user_clicked(handle: &mut RustGameState, pos_y: i32, pos_x: i32) {
	println!("From rust, user clicked {} {}", pos_y, pos_x);
	let cell_height = CANVAS_HEIGHT/(reversi_core::BOARD_SIZE as i32);
	let cell_width  = CANVAS_WIDTH/(reversi_core::BOARD_SIZE as i32);

	let cell_y = pos_y / cell_height;
	let cell_x = pos_x / cell_width;
	println!("User clicked cell {cell_y} {cell_x}");
	//handle.draw_rect("#ff0000", pos_y, pos_x, pos_y + 20, pos_x + 20);
	let rust_game_api::GameState::ReversiGameState(reversi_state) = &mut handle.game_state;
	let rc = reversi_core::player_move(reversi_state, reversi_state.player_turn, Pt{y: cell_y, x: cell_x});
	println!("player_move returned {:#?}", rc);
	if let Err(err) = rc {
		let msg = rc_to_err_msg(err);
		handle.set_status_err(msg);
	} else {
		save_state(handle);
	}
	draw_state(handle);
}

fn handle_btn_clicked(handle: &mut RustGameState, btn_id: &str) {
	println!("reversi handle_btn_clicked, btn_id=\"{}\"", btn_id);
	/*
	match btn_id {
		// TODO??
		//BTN_ID_UNDO => { load_state_offset(handle, -1); }
		//BTN_ID_REDO => { load_state_offset(handle,  1); }
		"btn_undo" => { load_state_offset(handle, -1); }
		"btn_redo" => { load_state_offset(handle,  1); }
		_ => {
			handle.set_status_err(&format!("Unhandled btn_id {}", btn_id));
		}
	}
	*/

	if btn_id == BTN_ID_UNDO {
		load_state_offset(handle, -1);
	} else if btn_id == BTN_ID_REDO {
		load_state_offset(handle,  1);
	} else {
		let err_msg = format!("Unhandled btn_id {}", btn_id);
		println!("{}", err_msg);
		handle.set_status_err(&err_msg);
	}
	draw_state(handle);
}

fn save_state(handle: &mut RustGameState) {
	let rust_game_api::GameState::ReversiGameState(reversi_state) = &handle.game_state;
	let session_id = reversi_state.session_id;
	let serialized_state = get_state(handle).expect("state is none?");
	unsafe {
		// TODO don't put session_id in the game state, make a separate struct for "state to be shared"
		// and other state that shouldn't be shared
		handle.callbacks.as_ref().expect("callbacks null?").save_state(session_id, serialized_state);
	}
}

fn load_state_offset(handle: &mut RustGameState, offset: i32) {
	println!("load_state_offset({})", offset);
	let rust_game_api::GameState::ReversiGameState(reversi_state) = &handle.game_state;
	let session_id = reversi_state.session_id;
	let saved_state = unsafe { handle.callbacks.as_ref().expect("callbacks null?").adjust_saved_state_offset(session_id, offset) };
	set_state(handle, &saved_state.expect("saved state is none from adjust_saved_state_offset?"));
}

fn set_state(handle: &mut RustGameState, serialized_state: &Vec<u8>) {
	println!("set_state");
	let reversi_state = bincode::deserialize::<reversi_core::State>(&serialized_state);
	if let Ok(reversi_state) = reversi_state {
		println!("Received game state: {:#?}", reversi_state);
		handle.game_state = rust_game_api::GameState::ReversiGameState(reversi_state);
	} else {
		handle.set_status_err(&format!("Error decoding state: {:?}", reversi_state));
	}
}

//fn start_game(_handle: &mut RustGameState) {
fn start_game(handle: &mut RustGameState, session_id_and_state: Option<(i32, Vec<u8>)>) {
	// TODO
	println!("rust: start called");

	if let Some(session_id_and_state) = session_id_and_state {
		let (session_id, state_serialized) = session_id_and_state;
		set_state(handle, &state_serialized);
		/*
		let reversi_state = bincode::deserialize::<reversi_core::State>(&state_serialized);
		if let Ok(reversi_state) = reversi_state {
			println!("Received game state: {:#?}", reversi_state);
			handle.game_state = rust_game_api::GameState::ReversiGameState(reversi_state);
		} else {
			handle.set_status_err(&format!("Error decoding state: {:?}", reversi_state));
		}
		*/
	} else if let Some(session_id) = unsafe { handle.callbacks.as_ref().expect("callbacks null?").get_last_session_id("reversi") } {
		load_state_offset(handle, 0);
		//let saved_state = handle.callbacks.adjust_saved_state_offset(session_id, 0);
		//let saved_state = unsafe { handle.callbacks.as_ref().expect("callbacks null?").adjust_saved_state_offset(session_id, 0) };
		//set_state(handle, &saved_state.expect("saved state is none from adjust_saved_state_offset?"));
	} else {
		let rust_game_api::GameState::ReversiGameState(reversi_state) = &mut handle.game_state;
		reversi_state.session_id = unsafe { handle.callbacks.as_ref().expect("callbacks null?").get_new_session_id() };
	}
}

fn draw_state(handle: &mut RustGameState) {
	//println!("rust: draw_state called");
	let board_size_flt = reversi_core::BOARD_SIZE as f64;
	let height = CANVAS_HEIGHT as f64;
	let width  = CANVAS_WIDTH as f64;


	/*
	let reversi_state: &reversi_core::State;
	if let rust_game_api::GameState::ReversiGameState(state) = &handle.game_state {
		reversi_state = state;
	} else {
		panic!("invalid game state passed to reversi draw_state");
	}
	*/
	let rust_game_api::GameState::ReversiGameState(reversi_state) = &handle.game_state;

	//let reversi_state = handle.game_state.downcast_ref::<reversi_core::State>();
	//let reversi_state = &handle.game_state as reversi_core::State;
	//let reversi_state = handle.game_state;

	let cell_height = height/board_size_flt;
	let cell_width  = width/board_size_flt;

	handle.draw_rect("#008800", 0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);

	let line_size = 1;
	for y in 1..reversi_core::BOARD_SIZE {
		let y = y as i32;
		let cell_height = cell_height as i32;
		handle.draw_line("#000000", line_size, y*cell_height, 0, y*cell_height, CANVAS_WIDTH);
	}
	for x in 1..reversi_core::BOARD_SIZE {
		let x = x as i32;
		let cell_width = cell_width as i32;
		handle.draw_line("#000000", 0, line_size, x*cell_width, CANVAS_HEIGHT, x*cell_width);
	}

	for y in 0..reversi_core::BOARD_SIZE {
		for x in 0..reversi_core::BOARD_SIZE {
			let y = y as f64;
			let x = x as f64;
			
			let y1 = (y/board_size_flt*height) as i32;
			let x1 = (x/board_size_flt*width) as i32;
			let y2 = ((y+1.0)/board_size_flt*height) as i32;
			let x2 = ((x+1.0)/board_size_flt*width) as i32;
			//handle.draw_rect(colour, y1, x1, y2, x2);
			let player_colour = match reversi_state.cell(Pt{y:y as i32, x:x as i32}) {
				reversi_core::CellState::PLAYER1 => Some("#dddddd"),
				reversi_core::CellState::PLAYER2 => Some("#333333"),
				_ => None,
			};
			if let Some(colour) = player_colour {
				let circ_y = (y1 as f64 +cell_height/2.0) as i32;
				let circ_x = (x1 as f64 +cell_height/2.0) as i32;
				let radius = (cell_height/2.0 - 3.0) as i32;

				handle.draw_circle(colour, "#000000", circ_y, circ_x, radius, 2);
			};
		}
	}

	let session_id = reversi_state.session_id;
	handle.set_btn_enabled(BTN_ID_UNDO, unsafe { handle.callbacks.as_ref().expect("callbacks null?").has_saved_state_offset(session_id, -1) } );
	handle.set_btn_enabled(BTN_ID_REDO, unsafe { handle.callbacks.as_ref().expect("callbacks null?").has_saved_state_offset(session_id,  1) } );
}

fn get_state(handle: &mut RustGameState) -> Option<Vec<u8>> {
	let rust_game_api::GameState::ReversiGameState(reversi_state) = &mut handle.game_state;

	// TODO this is huge, I bet the enum is encoded as 4 bytes
	// see if I can override it to make them only 2 bits each? Or
	// at least just 1 byte.
	// TODO also add a version number and abstract it into a function

	// TODO check what endianness I used in Lua games
	match bincode::serialize(reversi_state) {
		Ok(state_encoded) => { return Some(state_encoded); }
		Err(e) => {
			// TODO use format macro and pass this more useful string to the API
			println!("Error encoding state: {}", e);
			handle.set_status_err("Error encoding state");
			return None;
		}
	}
}

//fn init(_callbacks: &rust_game_api::Callbacks) -> Box <dyn rust_game_api::GameState> {
fn init(callbacks: *const rust_game_api::CCallbacksPtr) -> Box <rust_game_api::GameState> {
	let state = reversi_core::State::new();
	let state = rust_game_api::GameState::ReversiGameState(state);

	unsafe {
		// TODO make wrappers for all of these on the callbacks, I guess?
		// maybe change everything to call handle.callbacks.create_btn instead of
		// defining the wrappers being defined on the game state, which is made
		// at the common level, I guess.
		let callbacks = callbacks.as_ref().expect("callbacks null?");
		callbacks.create_btn(BTN_ID_UNDO, "Undo", 1);
		callbacks.create_btn(BTN_ID_REDO, "Redo", 1);
		callbacks.set_btn_enabled(BTN_ID_UNDO, false);
		callbacks.set_btn_enabled(BTN_ID_REDO, false);
	}

	return Box::from(state);
}

pub fn init_reversi(callbacks: *const rust_game_api::CCallbacksPtr) -> rust_game_api::GameApi {
	let api = rust_game_api::GameApi {
		init: init,
		start_game: start_game,
		update: update,
		handle_user_clicked: handle_user_clicked,
		handle_btn_clicked: handle_btn_clicked,
		get_state: get_state,
	};
	//println!("init_reversi returning {:#?}", api);

	api
}
