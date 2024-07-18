// Game:   Reversi
// Author: Alex Barry (github.com/alexbarry)
//
// TODO:
//  * network multiplayer
//  * make saved state smaller
//  * add version to saved state
//  * separate "session_id" from saved state struct
//  * highlight last move
//  * set_status_msg indicating whose turn is first

use bincode;

use crate::rust_game_api;

use crate::rust_game_api::{AlexGamesApi, CCallbacksPtr, CANVAS_HEIGHT, CANVAS_WIDTH};

// TODO there must be a better way than this? This file is in the same directory
use crate::reversi::reversi_core;
use crate::reversi::reversi_core::{Pt, ReversiErr};

/*
impl rust_game_api::GameState for reversi_core::State {
}
*/

static BTN_ID_UNDO: &str = "btn_undo";
static BTN_ID_REDO: &str = "btn_redo";

struct AlexGamesReversi {
	game_state: reversi_core::State,
	//callbacks: *mut rust_game_api::CCallbacksPtr,
	//callbacks: &'a rust_game_api::CCallbacksPtr,
	callbacks: &'static rust_game_api::CCallbacksPtr,
}

impl AlexGamesReversi {

fn rc_to_err_msg(err: ReversiErr) -> &'static str {
	match err {
		ReversiErr::InvalidMove => "Invalid move",
		ReversiErr::NotYourTurn => "Not your turn",
	}
}

fn save_state(&self) {
	//let rust_game_api::GameState::ReversiGameState(reversi_state) = &handle.game_state;
	let session_id = self.game_state.session_id;
	let serialized_state = self.get_state().expect("state is none?");
	unsafe {
		// TODO don't put session_id in the game state, make a separate struct for "state to be shared"
		// and other state that shouldn't be shared
		//self.callbacks.as_ref().expect("callbacks null?").save_state(session_id, serialized_state);
	}
	self.callbacks.save_state(session_id, serialized_state);
}

fn load_state_offset(&mut self, offset: i32) {
	println!("load_state_offset({})", offset);
	let session_id = self.game_state.session_id;
	//let saved_state = unsafe { self.callbacks.as_ref().expect("callbacks null?").adjust_saved_state_offset(session_id, offset) };
	let saved_state = self.callbacks.adjust_saved_state_offset(session_id, offset);
	self.set_state(&saved_state.expect("saved state is none from adjust_saved_state_offset?"));
}

fn set_state(&mut self, serialized_state: &Vec<u8>) {
	println!("set_state");
	let game_state = bincode::deserialize::<reversi_core::State>(&serialized_state);
	if let Ok(game_state) = game_state {
		println!("Received game state: {:#?}", game_state);
		self.game_state = game_state;
	} else {
		self.callbacks.set_status_err(&format!("Error decoding state: {:?}", game_state));
	}
}

fn draw_state(&self) {
	//println!("rust: draw_state called");
	let board_size_flt = reversi_core::BOARD_SIZE as f64;
	let height = CANVAS_HEIGHT as f64;
	let width  = CANVAS_WIDTH as f64;

	let mut bg_colour;
	let mut bg_line_colour;
	let mut piece_white_colour;
	let mut piece_black_colour;
	let mut piece_outline_colour;

	let user_colour_pref = self.callbacks.get_user_colour_pref();
	let user_colour_pref = &user_colour_pref as &str; // TODO why do I need to do this?
	println!("reversi user_colour_pref is '{}'", user_colour_pref);
	match user_colour_pref {
		"dark" => {
			bg_colour            = "#003300";
			bg_line_colour       = "#000000";
			piece_white_colour   = "#444444";
			piece_black_colour   = "#000000";
			piece_outline_colour = "#333333";

		}
		_ => {
			bg_colour            = "#008800";
			bg_line_colour       = "#000000";
			piece_white_colour   = "#dddddd";
			piece_black_colour   = "#333333";
			piece_outline_colour = "#000000";
		}
	}


	/*
	let reversi_state: &reversi_core::State;
	if let rust_game_api::GameState::ReversiGameState(state) = &handle.game_state {
		reversi_state = state;
	} else {
		panic!("invalid game state passed to reversi draw_state");
	}
	*/

	//let reversi_state = handle.game_state.downcast_ref::<reversi_core::State>();
	//let reversi_state = &handle.game_state as reversi_core::State;
	//let reversi_state = handle.game_state;

	let cell_height = height/board_size_flt;
	let cell_width  = width/board_size_flt;

	self.callbacks.draw_rect(bg_colour, 0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);

	let line_size = 1;
	for y in 1..reversi_core::BOARD_SIZE {
		let y = y as i32;
		let cell_height = cell_height as i32;
		self.callbacks.draw_line(bg_line_colour, line_size, y*cell_height, 0, y*cell_height, CANVAS_WIDTH);
	}
	for x in 1..reversi_core::BOARD_SIZE {
		let x = x as i32;
		let cell_width = cell_width as i32;
		self.callbacks.draw_line(bg_line_colour, 0, line_size, x*cell_width, CANVAS_HEIGHT, x*cell_width);
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
			let player_colour = match self.game_state.cell(Pt{y:y as i32, x:x as i32}) {
				reversi_core::CellState::PLAYER1 => Some(piece_white_colour),
				reversi_core::CellState::PLAYER2 => Some(piece_black_colour),
				_ => None,
			};
			if let Some(colour) = player_colour {
				let circ_y = (y1 as f64 +cell_height/2.0) as i32;
				let circ_x = (x1 as f64 +cell_height/2.0) as i32;
				let radius = (cell_height/2.0 - 3.0) as i32;

				self.callbacks.draw_circle(colour, piece_outline_colour, circ_y, circ_x, radius, 2);
			};
		}
	}

	let session_id = self.game_state.session_id;
	self.callbacks.set_btn_enabled(BTN_ID_UNDO, self.callbacks.has_saved_state_offset(session_id, -1));
	self.callbacks.set_btn_enabled(BTN_ID_REDO, self.callbacks.has_saved_state_offset(session_id,  1));
}

}

impl AlexGamesApi for AlexGamesReversi {


	fn callbacks(&self) -> *const CCallbacksPtr {
		self.callbacks
	}

	/*
	fn callbacks_ref(&self) -> &CCallbacksPtr {
		unsafe { self.callbacks.as_ref().expect("callbacks null?") }
	}
	*/

fn update(&mut self, _dt_ms: i32) {
	println!("rust: update called");
	//draw_state(&handle.game_state as reversi_core::State);
	self.draw_state();
}


fn handle_user_clicked(&mut self, pos_y: i32, pos_x: i32) {
	println!("From rust, user clicked {} {}", pos_y, pos_x);
	let cell_height = CANVAS_HEIGHT/(reversi_core::BOARD_SIZE as i32);
	let cell_width  = CANVAS_WIDTH/(reversi_core::BOARD_SIZE as i32);

	let cell_y = pos_y / cell_height;
	let cell_x = pos_x / cell_width;
	println!("User clicked cell {cell_y} {cell_x}");
	//handle.draw_rect("#ff0000", pos_y, pos_x, pos_y + 20, pos_x + 20);
	//let rust_game_api::GameState::ReversiGameState(reversi_state) = &mut handle.game_state;

	let player_turn = self.game_state.player_turn;
	let rc = reversi_core::player_move(&mut self.game_state, player_turn, Pt{y: cell_y, x: cell_x});
	println!("player_move returned {:#?}", rc);
	if let Err(err) = rc {
		let msg = AlexGamesReversi::rc_to_err_msg(err);
		self.callbacks.set_status_err(msg);
	} else {
		self.save_state();
	}
	self.draw_state();
}

fn handle_btn_clicked(&mut self, btn_id: &str) {
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
		self.load_state_offset(-1);
	} else if btn_id == BTN_ID_REDO {
		self.load_state_offset( 1);
	} else {
		let err_msg = format!("Unhandled btn_id {}", btn_id);
		println!("{}", err_msg);
		self.callbacks.set_status_err(&err_msg);
	}
	self.draw_state();
}



//fn start_game(_handle: &mut RustGameState) {
fn start_game(&mut self, session_id_and_state: Option<(i32, Vec<u8>)>) {
	// TODO
	println!("rust: start called");

	if let Some(session_id_and_state) = session_id_and_state {
		let (session_id, state_serialized) = session_id_and_state;
		self.set_state(&state_serialized);
		/*
		let reversi_state = bincode::deserialize::<reversi_core::State>(&state_serialized);
		if let Ok(reversi_state) = reversi_state {
			println!("Received game state: {:#?}", reversi_state);
			handle.game_state = rust_game_api::GameState::ReversiGameState(reversi_state);
		} else {
			handle.set_status_err(&format!("Error decoding state: {:?}", reversi_state));
		}
		*/
	} else if let Some(session_id) = self.callbacks.get_last_session_id("reversi") {
		self.load_state_offset(0);
		//let saved_state = handle.callbacks.adjust_saved_state_offset(session_id, 0);
		//let saved_state = unsafe { handle.callbacks.as_ref().expect("callbacks null?").adjust_saved_state_offset(session_id, 0) };
		//set_state(handle, &saved_state.expect("saved state is none from adjust_saved_state_offset?"));
	} else {
		self.game_state.session_id = self.callbacks.get_new_session_id();
	}
}

fn get_state(&self) -> Option<Vec<u8>> {
	// TODO this is huge, I bet the enum is encoded as 4 bytes
	// see if I can override it to make them only 2 bits each? Or
	// at least just 1 byte.
	// TODO also add a version number and abstract it into a function

	// TODO check what endianness I used in Lua games
	match bincode::serialize(&self.game_state) {
		Ok(state_encoded) => { return Some(state_encoded); }
		Err(e) => {
			// TODO use format macro and pass this more useful string to the API
			println!("Error encoding state: {}", e);
			self.callbacks.set_status_err("Error encoding state");
			return None;
		}
	}
}

//fn init(_callbacks: &rust_game_api::Callbacks) -> Box <dyn rust_game_api::GameState> {
fn init(&mut self, callbacks: *const rust_game_api::CCallbacksPtr) {
	self.game_state= reversi_core::State::new();

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
}


}

pub fn init_reversi(callbacks: *const rust_game_api::CCallbacksPtr) -> Box<dyn AlexGamesApi> {
	let mut reversi = AlexGamesReversi {
		game_state: reversi_core::State::new(),
		callbacks: unsafe { callbacks.as_ref().expect("callbacks null?") },
	};
	reversi.init(callbacks);
	Box::from(reversi)
}

