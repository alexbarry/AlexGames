use crate::rust_game_api;

use crate::rust_game_api::{RustGameState, CANVAS_HEIGHT, CANVAS_WIDTH};

// TODO there must be a better way than this? This file is in the same directory
use crate::reversi::reversi_core;
use crate::reversi::reversi_core::{Pt, ReversiErr};

/*
impl rust_game_api::GameState for reversi_core::State {
}
*/

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
	}
	draw_state(handle);
}

fn start_game(_handle: &mut RustGameState) {
	// TODO
	println!("rust: start called");
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
}

//fn init(_callbacks: &rust_game_api::Callbacks) -> Box <dyn rust_game_api::GameState> {
fn init(_callbacks: *const rust_game_api::CCallbacksPtr) -> Box <rust_game_api::GameState> {
	let state = reversi_core::State::new();
	let state = rust_game_api::GameState::ReversiGameState(state);
	return Box::from(state);
}

pub fn init_reversi(_: *const rust_game_api::CCallbacksPtr) -> rust_game_api::GameApi {
	let api = rust_game_api::GameApi {
		init: init,
		start_game: start_game,
		update: update,
		handle_user_clicked: handle_user_clicked,
	};
	println!("init_reversi returning {:#?}", api);

	api
}
