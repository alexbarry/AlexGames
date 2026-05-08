/**
 * Sudoku
 * author: Alex Barry (github.com/alexbarry)
 *
 * TODO:
 * - clear notes when entering a value?
 * - clear other notes in box/row/etc when entering a value?
 * - better serialization
 * - undo/redo?
 * - solving code
 * - code to try hiding cells until the puzzle meets certain parameters
 * - pre-generate a bunch on desktop, include in code, done!
 *
 */
use crate::rust_game_api;

use std::collections::HashMap;

use crate::rust_game_api::{
    AlexGamesApi, CCallbacksPtr, MouseEvt, OptionInfo, OptionType, TextAlign, TouchInfo,
    CANVAS_HEIGHT, CANVAS_WIDTH, KeyEvt
};

use crate::sudoku::sudoku_core::{self, Pt};
use crate::sudoku::sudoku_draw::{self, DrawState, ButtonId};

const SUDOKU_SIZE: usize = 9;

pub struct AlexGamesSudoku {
    callbacks: &'static CCallbacksPtr,

    game_state: sudoku_core::State,
	session_id: i32,
    draw_state: DrawState,
}

impl AlexGamesSudoku {
    fn draw_state(&mut self) {
        self.draw_state.draw_state(self.callbacks, &self.game_state);
    }

    fn get_state(&self) -> Option<Vec<u8>> {
        match bincode::serialize(&self.game_state) {
            Ok(state_encoded) => {
                return Some(state_encoded);
            }
            Err(e) => {
                // TODO use format macro and pass this more useful string to the API
                println!("Error encoding state: {}", e);
                self.callbacks.set_status_err("Error encoding state");
                return None;
            }
        }
	}

    fn set_state(&mut self, serialized_state: &Vec<u8>, session_id: i32) {
        println!("set_state");
        let game_state = bincode::deserialize::<sudoku_core::State>(&serialized_state);
        if let Ok(game_state) = game_state {
            println!("Received game state: {:#?}", game_state);
            self.game_state = game_state;
            self.session_id = session_id;
        } else {
            self.callbacks
                .set_status_err(&format!("Error decoding state: {:?}", game_state));
        }
    }

	fn load_state_offset(&mut self, offset: i32) {
        let session_id = self.session_id;
        let saved_state = self.callbacks.adjust_saved_state_offset(session_id, offset);
        let saved_state = saved_state.expect("saved state is none from adjust_saved_state_offset?");
        self.set_state(&saved_state, session_id);
	}


	fn save_state(&self) {
        let session_id = self.session_id;
        let serialized_state = self.get_state().expect("state is none?");
        self.callbacks.save_state(session_id, serialized_state);
	}
}

impl AlexGamesApi for AlexGamesSudoku {
    fn callbacks(&self) -> &CCallbacksPtr {
        self.callbacks
    }
    fn init(&mut self, callbacks: &'static CCallbacksPtr) {
    }

    fn start_game(&mut self, saved_state: Option<(i32, Vec<u8>)>) {
		if let Some((session_id, state_serialized)) = saved_state {
			self.set_state(&state_serialized, session_id);
        } else if let Some(session_id) = self.callbacks.get_last_session_id("sudoku") {
			self.session_id = session_id;
            self.load_state_offset(0);
		}
    }

	fn handle_key_evt(&mut self, evt_id: KeyEvt, key_code: &str) -> bool {
		println!("handle_key_evt(evt_id={:?}, key_code={:?})", evt_id, key_code);
		if evt_id != KeyEvt::Up {
			return match key_code {
				"ArrowLeft" | "KeyH" |
				"ArrowRight" | "KeyL" |
				"ArrowUp" | "KeyK" |
				"ArrowDown" | "KeyJ" |
				"Space" |
				"Backspace" |
				"Digit1" | "Digit2" | "Digit3" |
				"Digit4" | "Digit5" | "Digit6" |
				"Digit7" | "Digit8" | "Digit9" |
				"Numpad1" | "Numpad2" | "Numpad3" |
				"Numpad4" | "Numpad5" | "Numpad6" |
				"Numpad7" | "Numpad8" | "Numpad9"
					=> { true },
				_ => { false },
			}
		}


		let rc = match key_code {
			"ArrowLeft" | "KeyH" => self.game_state.move_sel(&Pt {y:0, x:-1}),
			"ArrowRight" | "KeyL" => self.game_state.move_sel(&Pt {y:0, x:1}),
			"ArrowUp" | "KeyK" => self.game_state.move_sel(&Pt {y:1, x:0}),
			"ArrowDown" | "KeyJ" => self.game_state.move_sel(&Pt {y:-1, x:0}),
			"Space" => { self.game_state.toggle_notes(); true },
			"Backspace" | "KeyX" => { self.game_state.set_val(0); true },
			"Digit1" | "Numpad1" => { self.game_state.set_val(1); true },
			"Digit2" | "Numpad2" => { self.game_state.set_val(2); true },
			"Digit3" | "Numpad3" => { self.game_state.set_val(3); true },
			"Digit4" | "Numpad4" => { self.game_state.set_val(4); true },
			"Digit5" | "Numpad5" => { self.game_state.set_val(5); true },
			"Digit6" | "Numpad6" => { self.game_state.set_val(6); true },
			"Digit7" | "Numpad7" => { self.game_state.set_val(7); true },
			"Digit8" | "Numpad8" => { self.game_state.set_val(8); true },
			"Digit9" | "Numpad9" => { self.game_state.set_val(9); true },
			_ => { false },
		};

		if rc {
			self.draw_state();
		}

		println!("returning {}", rc);
		return rc;
	}

    fn update(&mut self, dt_ms: i32) {
        self.draw_state();
    }
    fn handle_user_clicked(&mut self, pos_y: i32, pos_x: i32) {
		if let Some(cell) = self.draw_state.pos_to_cell(&self.game_state, pos_y, pos_x) {
			self.game_state.set_selection(&cell);
		} else if let Some(btn_id) = self.draw_state.pos_to_btn(&self.game_state, pos_y, pos_x) {
			match btn_id {
				ButtonId::Erase => self.game_state.erase(),
				ButtonId::Val(val) => self.game_state.set_val(val as i8),
				// TODO maybe this should be state within AlexGamesSudoku rather than core state
				ButtonId::ToggleNotes => self.game_state.toggle_notes(),
			}
		}
		self.draw_state();
		self.save_state()
	}
}

pub fn init_sudoku(callbacks: &'static CCallbacksPtr) -> Box<dyn AlexGamesApi> {
    let mut game = AlexGamesSudoku {
        callbacks: callbacks,
        game_state: sudoku_core::State::new(SUDOKU_SIZE),
        draw_state: DrawState::new(),
		session_id: callbacks.get_new_session_id(),
    };
    game.init(callbacks);

	callbacks.enable_evt("key");

	// TODO need to generate a puzzle
	game.game_state.board = vec![
		vec![ 0, 0, 0,  0, 0, 0,  0, 0, 0 ],
		vec![ 0, 0, 0,  0, 0, 0,  0, 0, 0 ],
		vec![ 0, 0, 0,  0, 0, 0,  0, 0, 0 ],

		vec![ 0, 0, 0,  0, 0, 0,  0, 0, 0 ],
		vec![ 0, 0, 0,  0, 0, 0,  0, 0, 0 ],
		vec![ 0, 0, 0,  0, 0, 0,  0, 0, 0 ],

		vec![ 0, 0, 0,  0, 0, 0,  0, 0, 0 ],
		vec![ 0, 0, 0,  0, 0, 0,  0, 0, 0 ],
		vec![ 0, 0, 0,  0, 0, 0,  0, 0, 0 ],
	];

    Box::from(game)
}
