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

use crate::sudoku::sudoku_core::{self, Pt, CellInfo};
use crate::sudoku::sudoku_draw::{self, DrawState, ButtonId};
use crate::sudoku::sudoku_serialize;
use crate::sudoku::generated::puzzles_2026_05_11;

const SUDOKU_SIZE: usize = 9;

const BTN_ID_UNDO: &'static str = "btn_id_undo";
const BTN_ID_REDO: &'static str = "btn_id_redo";

const OPTION_ID_LOAD_NEXT_PREGEN_PUZZLE: &'static str = "option_load_next_pregenerated_puzzle";
const ENTER_CUSTOM_GAME_OPTION_ID: &'static str = "option_new_custom_game";
const OPTION_ID_IMMEDIATELY_SHOW_MISTAKES: &'static str = "option_immediately_show_mistakes";
const OPTION_ID_CHECK_FOR_MISTAKES: &'static str = "option_check_for_mistakes";

const STORED_DATA_KEY_LAST_LOADED_PUZZLE_IDX: &'static str = "sudoku_last_loaded_puzzle1_idx";
const STORED_DATA_KEY_IMMEDIATELY_REVEAL_MISTAKES: &'static str = "sudoku_immediately_reveal_mistakes";

//const pregenerated_puzzles: &[[[i8;9];9]] = &puzzles_2026_05_11::puzzles;
const pregenerated_puzzles: &[[[CellInfo;9];9]] = &puzzles_2026_05_11::puzzles;


pub struct AlexGamesSudoku {
    callbacks: &'static CCallbacksPtr,

    game_state: sudoku_core::State,
	session_id: i32,
    draw_state: DrawState,

	prev_state: Option<Vec<u8>>,

	game_won: bool,
}

impl AlexGamesSudoku {
    fn draw_state(&mut self) {
        self.draw_state.draw_state(self.callbacks, &self.game_state);
		self.callbacks.set_btn_enabled(
			BTN_ID_UNDO,
			self.callbacks.has_saved_state_offset(self.session_id, -1),
		);
		self.callbacks.set_btn_enabled(
			BTN_ID_REDO,
			self.callbacks.has_saved_state_offset(self.session_id, 1),
		);
    }

    fn set_state(&mut self, serialized_state: &Vec<u8>, session_id: i32) {
        println!("set_state");
		/*
        let game_state = bincode::deserialize::<sudoku_core::State>(&serialized_state);
        if let Ok(game_state) = game_state {
            println!("Received game state: {:#?}", game_state);
            self.game_state = game_state;
            self.session_id = session_id;
        } else {
            self.callbacks
                .set_status_err(&format!("Error decoding state: {:?}", game_state));
        }
		*/

		self.game_state = sudoku_serialize::deserialize(serialized_state);
		self.session_id = session_id;
    }

	fn load_state_offset(&mut self, offset: i32) -> bool {
        let session_id = self.session_id;
		if !self.callbacks.has_saved_state_offset(session_id, offset) {
			return false;
		}
        let saved_state = self.callbacks.adjust_saved_state_offset(session_id, offset);
        let saved_state = saved_state.expect("saved state is none from adjust_saved_state_offset?");
        self.set_state(&saved_state, session_id);
		return true;
	}

	fn state_meaningfully_different(&self, state1: &Vec<u8>, state2: &Vec<u8>) -> bool {
		let mut state1 = sudoku_serialize::deserialize(state1);
		let mut state2 = sudoku_serialize::deserialize(state2);

		if state1.mode != sudoku_core::Mode::EnterStartingVal {
			state1.mode = sudoku_core::Mode::EnterCellVal;
		}
		state1.selected = None;
		if state2.mode != sudoku_core::Mode::EnterStartingVal {
			state2.mode = sudoku_core::Mode::EnterCellVal;
		}
		state2.selected = None;

		state1 != state2
	}


	fn save_state(&mut self) {
        let session_id = self.session_id;
        let serialized_state = self.get_state().expect("state is none?");
		let should_save_state = if let Some(prev_state) = &self.prev_state {
			self.state_meaningfully_different(&serialized_state, &prev_state)
		} else {
			true
		};
		if should_save_state {
			// TODO modify callbacks.save_state to take a reference
			self.callbacks.save_state(session_id, serialized_state.clone());
			self.prev_state = Some(serialized_state);
		}
	}

	fn enter_custom_game(&mut self) {
		self.game_won = false;
		self.game_state = sudoku_core::State::new(9);
		self.game_state.mode = sudoku_core::Mode::EnterStartingVal;
		self.save_state();
		self.draw_state();
	}

	fn get_last_loaded_puzzle_idx(&self) -> Option<i32> {
		let puzzle_idx = self.callbacks.read_stored_data_str(STORED_DATA_KEY_LAST_LOADED_PUZZLE_IDX);
		if let Some(puzzle_idx) = puzzle_idx {
			puzzle_idx.parse().ok()
		} else {
			// TODO could traverse generated puzzles and check if current puzzle is stored,
			// user could have sent a link from another device.
			None
		}
	}

	fn set_last_loaded_puzzle_idx(&mut self, puzzle_idx: usize) {
		let puzzle_idx = puzzle_idx.to_string();
		self.callbacks.store_data(STORED_DATA_KEY_LAST_LOADED_PUZZLE_IDX, puzzle_idx.as_bytes());
	}

	fn load_pregen_puzzle(&mut self, puzzle_idx: usize) {
		// just in case
		let puzzle_idx = puzzle_idx % pregenerated_puzzles.len();

		let puzzle = &pregenerated_puzzles[puzzle_idx];
		let mut new_state = sudoku_core::State::new(puzzle.len());
		for y in 0..puzzle.len() {
			for x in 0..puzzle[y].len() {
				new_state.board[y][x] = puzzle[y][x].clone();
				//new_state.board[y][x].val = puzzle[y][x];
				//new_state.board[y][x].revealed = puzzle[y][x] != 0;
			}
		}
		self.game_state = new_state;
		self.game_won = false;
	}

	fn load_next_pregen_puzzle(&mut self) {
		const _: () = assert!(pregenerated_puzzles.len() >= 200);

		let puzzle_idx = self.get_last_loaded_puzzle_idx().unwrap_or(0) as usize;
		let puzzle_idx = puzzle_idx + 1;

		if puzzle_idx >= pregenerated_puzzles.len() {
			self.callbacks.set_status_msg(&format!("NOTE: Already loaded all {} pre-generated puzzles, wrapping around to 0", pregenerated_puzzles.len()));
		} else {
			self.callbacks.set_status_msg(&format!("Loading pre-generated puzzle {} of {}.", puzzle_idx + 1, pregenerated_puzzles.len()));
		}
		let puzzle_idx = puzzle_idx % pregenerated_puzzles.len();

		self.set_last_loaded_puzzle_idx(puzzle_idx);
		self.load_pregen_puzzle(puzzle_idx);
        self.session_id = self.callbacks.get_new_session_id();
		self.draw_state();
		self.save_state();
	}

	fn get_immediately_show_mistakes_val_stored(&self) -> Option<bool> {
		let val_str = self.callbacks.read_stored_data_str(STORED_DATA_KEY_IMMEDIATELY_REVEAL_MISTAKES);
		if val_str.is_none() {
			return None
		}
		let val: i32 = val_str.unwrap().parse().unwrap();

		assert!(val == 0 || val == 1);

		Some(val != 0)
	}

	fn set_immediately_show_mistakes_stored(&self, value: bool) {
		let value = if value { 1 } else { 0 };
		let value: String = value.to_string();
		let val_str = self.callbacks.store_data(STORED_DATA_KEY_IMMEDIATELY_REVEAL_MISTAKES, value.as_bytes());
	}

	fn set_immediately_show_mistakes(&mut self, value: bool) {
		self.set_immediately_show_mistakes_stored(value);
		self.draw_state.immediately_show_mistakes = Some(value);
		self.draw_state();
	}

	fn get_immediately_show_mistakes_val(&self) -> bool {
		self.get_immediately_show_mistakes_val_stored().unwrap_or(true)
	}

	fn check_for_mistakes(&mut self) {
		let mistakes = self.game_state.get_mistakes();
		self.draw_state.mistakes = mistakes;
		self.draw_state();
	}

	fn erase_pressed(&mut self) {
		self.val_pressed(0);
	}

	fn val_pressed(&mut self, val: i8) {
		println!("val_pressed(val={})", val);
		let old_sel = self.game_state.selected;

		// If the user presses the same button that is already entered,
		// clear it. When I "highlighted" the current value, it looks
		// like a toggle button that can be untoggled.
		if val != 0 && self.game_state.get_selected_val().is_none_or(|sel_val| sel_val != val as i8) {
			self.game_state.set_val(val as i8)
		} else {
			self.game_state.erase()
		}

		let new_val = if let Some(sel) = old_sel {
			Some(self.game_state.user_input[sel.y as usize][sel.x as usize])
		} else {
			None
		};

		println!("old_sel={:?}, new_val={:?}", old_sel, new_val);
		if let Some(sel) = old_sel {
			let mistake_val = self.draw_state.mistakes.get(&sel);
			println!("old_sel={:?}, new_val={:?}, mistake_val={:?}", old_sel, new_val, mistake_val);
			if mistake_val.is_some() && mistake_val != new_val.as_ref() {
				self.draw_state.mistakes.remove(&sel);
			}
		}

		if !self.game_won && self.game_state.game_won() {
			self.game_won = true;
			self.draw_state.start_win_animation();
			self.callbacks.set_status_msg(&format!("Congratulations, you win!"));
		}
	}
}

impl AlexGamesApi for AlexGamesSudoku {
    fn callbacks(&self) -> &CCallbacksPtr {
        self.callbacks
    }
    fn init(&mut self, callbacks: &'static CCallbacksPtr) {
    }

    fn get_state(&self) -> Option<Vec<u8>> {
		/*
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
		*/

		let serialized_state = sudoku_serialize::serialize(&self.game_state);
		if true {
			let test_deserialized = sudoku_serialize::deserialize(&serialized_state);
			let mut test_this_state = self.game_state.clone();
			// TODO store as a hashset or something instead
			for notes_row in &mut test_this_state.user_input_notes {
				for mut notes in notes_row {
					notes.sort();
				}
			}
			test_this_state.selected = None;
			//test_this_state.mode = sudoku_core::Mode::EnterCellVal;
			assert_eq!(test_deserialized, test_this_state);
		}

		Some(serialized_state)
	}

    fn start_game(&mut self, saved_state: Option<(i32, Vec<u8>)>) {
		if let Some((session_id, state_serialized)) = saved_state {
			self.set_state(&state_serialized, session_id);
        } else if let Some(session_id) = self.callbacks.get_last_session_id("sudoku") {
			self.session_id = session_id;
            self.load_state_offset(0);
		} else {
			let idx = self.get_last_loaded_puzzle_idx().unwrap_or(0) as usize;
			self.load_pregen_puzzle(idx);
			self.session_id = self.callbacks.get_new_session_id();
			self.save_state();
		}
		self.game_won = self.game_state.game_won();
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
				"KeyU" | "KeyR" |
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

		let old_sel = self.game_state.selected;

		let rc = match key_code {
			"ArrowLeft" | "KeyH" => self.game_state.move_sel(&Pt {y:0, x:-1}),
			"ArrowRight" | "KeyL" => self.game_state.move_sel(&Pt {y:0, x:1}),
			"ArrowUp" | "KeyK" => self.game_state.move_sel(&Pt {y:1, x:0}),
			"ArrowDown" | "KeyJ" => self.game_state.move_sel(&Pt {y:-1, x:0}),
			"Space" => { self.game_state.toggle_notes(); true },
			"Backspace" | "KeyX" => { self.erase_pressed(); true },
			"Digit1" | "Numpad1" => { self.val_pressed(1); true },
			"Digit2" | "Numpad2" => { self.val_pressed(2); true },
			"Digit3" | "Numpad3" => { self.val_pressed(3); true },
			"Digit4" | "Numpad4" => { self.val_pressed(4); true },
			"Digit5" | "Numpad5" => { self.val_pressed(5); true },
			"Digit6" | "Numpad6" => { self.val_pressed(6); true },
			"Digit7" | "Numpad7" => { self.val_pressed(7); true },
			"Digit8" | "Numpad8" => { self.val_pressed(8); true },
			"Digit9" | "Numpad9" => { self.val_pressed(9); true },
			"KeyU" => { self.load_state_offset(-1) },
			"KeyR" => { self.load_state_offset(1) },
			_ => { false },
		};

		if rc {
			self.draw_state();
			self.save_state()
		}

		println!("returning {}", rc);
		return rc;
	}

    fn update(&mut self, dt_ms: i32) {
		self.draw_state.update_anim_state(dt_ms);
        self.draw_state();
    }

    fn handle_user_clicked(&mut self, pos_y: i32, pos_x: i32) {
		if let Some(cell) = self.draw_state.pos_to_cell(&self.game_state, pos_y, pos_x) {
			self.game_state.set_selection(&cell);
		} else if let Some(btn_id) = self.draw_state.pos_to_btn(&self.game_state, pos_y, pos_x) {
			match btn_id {
				ButtonId::Erase => self.erase_pressed(),
				ButtonId::Val(val) => self.val_pressed(val as i8),
				// TODO maybe this should be state within AlexGamesSudoku rather than core state
				ButtonId::ToggleNotes => self.game_state.toggle_notes(),
				ButtonId::DoneEnteringStartingVals => {
					self.game_state.mode = sudoku_core::Mode::EnterCellVal
				},
			}
		}
		self.draw_state();
		self.save_state()
	}

    fn handle_btn_clicked(&mut self, btn_id: &str) {
        match btn_id {
            BTN_ID_UNDO => self.load_state_offset(-1),
            BTN_ID_REDO => self.load_state_offset(1),
            _ => {
                panic!("Unhandled button ID {}", btn_id);
            }
		};
		self.draw_state();
	}

	fn handle_game_option_evt(&mut self, option_id: &str, option_type: OptionType, value: i32) {
		match option_id {
			// TODO show a popup to confirm or something
			ENTER_CUSTOM_GAME_OPTION_ID => self.enter_custom_game(),
			OPTION_ID_LOAD_NEXT_PREGEN_PUZZLE => self.load_next_pregen_puzzle(),
			OPTION_ID_IMMEDIATELY_SHOW_MISTAKES => self.set_immediately_show_mistakes(value != 0),
			OPTION_ID_CHECK_FOR_MISTAKES => self.check_for_mistakes(),
			&_ => {
				panic!("unhandled option id");
			}
		}
	}
}

pub fn init_sudoku(callbacks: &'static CCallbacksPtr) -> Box<dyn AlexGamesApi> {
    let mut game = AlexGamesSudoku {
        callbacks: callbacks,
        game_state: sudoku_core::State::new(SUDOKU_SIZE),
        draw_state: DrawState::new(callbacks),
		session_id: callbacks.get_new_session_id(),
		prev_state: None,

		game_won: false,
    };
    game.init(callbacks);
	game.draw_state.immediately_show_mistakes = Some(game.get_immediately_show_mistakes_val());

	callbacks.set_canvas_size(sudoku_draw::CANVAS_WIDTH, sudoku_draw::CANVAS_HEIGHT);

	callbacks.enable_evt("key");

	callbacks.create_btn(BTN_ID_UNDO, "Undo", 1);
	callbacks.create_btn(BTN_ID_REDO, "Redo", 1);

	callbacks.add_game_option(OPTION_ID_LOAD_NEXT_PREGEN_PUZZLE, &OptionInfo {
		option_type: OptionType::Button,
		label: "New Game (Load pre-generated puzzle)".to_string(),
		value: 0,
	});

	callbacks.add_game_option(ENTER_CUSTOM_GAME_OPTION_ID, &OptionInfo {
		option_type: OptionType::Button,
		label: "Enter Custom Game".to_string(),
		value: 0,
	});
	callbacks.add_game_option(OPTION_ID_IMMEDIATELY_SHOW_MISTAKES, &OptionInfo {
		option_type: OptionType::Toggle,
		label: "Immediately show mistakes".to_string(),
		value: if game.draw_state.immediately_show_mistakes.unwrap_or(true) { 1 } else { 0 },
	});

	callbacks.add_game_option(OPTION_ID_CHECK_FOR_MISTAKES, &OptionInfo {
		option_type: OptionType::Button,
		label: "Check for mistakes".to_string(),
		value: 0,
	});


    Box::from(game)
}
