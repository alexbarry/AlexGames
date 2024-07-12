use crate::rust_game_api;

use crate::rust_game_api::{RustGameState, CANVAS_HEIGHT, CANVAS_WIDTH};

// TODO there must be a better way than this? This file is in the same directory
use crate::reversi::reversi_core;
use crate::reversi::reversi_core::{Pt};

impl rust_game_api::GameState for reversi_core::State {
}

fn update(handle: &mut RustGameState, _dt_ms: i32) {
	println!("rust: update called");
	//draw_state(&handle.game_state as reversi_core::State);
	draw_state(handle);
}


fn handle_user_clicked(_handle: &mut RustGameState, pos_y: i32, pos_x: i32) {
	println!("From rust, user clicked {} {}", pos_y, pos_x);
	//handle.draw_rect("#ff0000", pos_y, pos_x, pos_y + 20, pos_x + 20);
}

fn start_game(_handle: &mut RustGameState) {
	// TODO
	println!("rust: start called");
}

fn draw_state(handle: &mut RustGameState) {
//fn draw_state(handle: &reversi_core::State) {
//fn draw_state() {
	let board_size_flt = reversi_core::BOARD_SIZE as f64;
	let height = CANVAS_HEIGHT as f64;
	let width  = CANVAS_WIDTH as f64;

	//let reversi_state = handle.game_state.downcast_ref::<reversi_core::State>();
	//let reversi_state = &handle.game_state as reversi_core::State;
	//let reversi_state = handle.game_state;

	let cell_height = height/board_size_flt;
	let cell_width  = width/board_size_flt;
	for y in 0..reversi_core::BOARD_SIZE {
		for x in 0..reversi_core::BOARD_SIZE {
			let colour;
			if (y*8 + x + y) % 2 == 0 {
				colour = "#000000";
			} else {
				colour = "#008800";
			}
			let y = y as f64;
			let x = x as f64;
			
			let y1 = (y/board_size_flt*height) as i32;
			let x1 = (x/board_size_flt*width) as i32;
			let y2 = ((y+1.0)/board_size_flt*height) as i32;
			let x2 = ((x+1.0)/board_size_flt*width) as i32;
			handle.draw_rect(colour, y1, x1, y2, x2);
			// TODO I'm not sure how to convert the generic game state to
			// the game specific game state.
			/*
			let player_colour = match handle.game_state.cell(Pt{y:y as i32, x:x as i32}) {
				reversi_core::CellState::PLAYER1 => Some("#dddddd"),
				reversi_core::CellState::PLAYER2 => Some("#333333"),
				_ => None,
			};
			if let Some(colour) = player_colour {
				handle.draw_circle(colour, "#000000", (y1 as f64 +cell_height/2.0) as i32, (x1 as f64 +cell_height/2.0) as i32, (cell_height/2.0 - 3.0) as i32, 2);
			};
			*/
		}
	}
}

//fn init(_callbacks: &rust_game_api::Callbacks) -> Box <dyn rust_game_api::GameState> {
fn init(_callbacks: *const rust_game_api::CCallbacksPtr) -> Box <dyn rust_game_api::GameState> {
	return Box::from(reversi_core::State::new());
}

pub fn init_reversi(_: *const rust_game_api::CCallbacksPtr) -> rust_game_api::GameApi {
	rust_game_api::GameApi {
		init: init,
		start_game: start_game,
		update: update,
		handle_user_clicked: handle_user_clicked,
	}
}
