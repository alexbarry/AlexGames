// Game:   Reversi
// Author: Alex Barry (github.com/alexbarry)
//
// TODO:
//  * fix deserialization errors in reversi in wasm? I'm not sure I see it anymore. Check the wxWidgets build, I saw it there too
//  * network multiplayer
//  * either allow player to pass when they can't move, or auto skip to next player
//  * set_status_msg indicating whose turn is first


use crate::rust_game_api;

use crate::rust_game_api::{AlexGamesApi, CCallbacksPtr, CANVAS_HEIGHT, CANVAS_WIDTH, TextAlign, OptionType, OptionInfo};

// TODO there must be a better way than this? This file is in the same directory
use crate::reversi::reversi_core;
use crate::reversi::reversi_serialize;
use crate::reversi::reversi_core::{Pt, ReversiErr, CellState};

/*
impl rust_game_api::GameState for reversi_core::State {
}
*/

const BTN_ID_UNDO: &str = "btn_undo";
const BTN_ID_REDO: &str = "btn_redo";

const GAME_OPTION_NEW_GAME: &str = "option_id_new_game";


const score_text_size: i32 = 24;
const score_padding: i32 = 4;
const player_move_highlight_thickness: i32 = 4;
const text_box_size_y: i32 = score_text_size + 2 * score_padding;
const y_offset: i32 = text_box_size_y;

pub struct AlexGamesReversi {
    game_state: reversi_core::State,
	session_id: i32,
    //callbacks: *mut rust_game_api::CCallbacksPtr,
    //callbacks: &'a rust_game_api::CCallbacksPtr,
    callbacks: &'static rust_game_api::CCallbacksPtr,
}

fn draw_rect_outline(callbacks: &CCallbacksPtr, colour: &str, thickness: i32, y1: i32, x1: i32, y2: i32, x2: i32) {
		callbacks.draw_line(&colour,
		                    thickness,
		                    y1, x1 - thickness/2,
		                    y1, x2 + thickness/2);
		callbacks.draw_line(&colour,
		                    thickness,
		                    y1 - thickness/2, x1,
		                    y2 + thickness/2, x1);

		callbacks.draw_line(&colour,
		                    thickness,
		                    y2, x2 + thickness/2,
		                    y2, x1 - thickness/2);
		callbacks.draw_line(&colour,
		                    thickness,
		                    y2 + thickness/2, x2,
		                    y1 - thickness/2, x2);
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
        let session_id = self.session_id;
        let serialized_state = self.get_state().expect("state is none?");
        self.callbacks.save_state(session_id, serialized_state);
    }

    fn load_state_offset(&mut self, offset: i32) {
        println!("load_state_offset({})", offset);
        let session_id = self.session_id;
        let saved_state = self.callbacks.adjust_saved_state_offset(session_id, offset);
        let saved_state = saved_state.expect("saved state is none from adjust_saved_state_offset?");
        self.set_state(&saved_state, session_id);
    }

    fn set_state(&mut self, serialized_state: &Vec<u8>, session_id: i32) {
        let serialized_state_len = serialized_state.len();
        println!("set_state, serialized state len is {serialized_state_len}");
        //let game_state = bincode::deserialize::<reversi_core::State>(&serialized_state);
        let game_state = reversi_serialize::deserialize(&serialized_state);
        if let Ok(game_state) = game_state {
            println!("Received game state: {:#?}", game_state);
            self.game_state = game_state;
            self.session_id = session_id;
        } else {
            self.callbacks
                .set_status_err(&format!("Error decoding state: {:?}", game_state));
        }
    }

    fn draw_state(&self) {
        let callbacks = self.callbacks;
        let state = &self.game_state;
        callbacks.draw_clear();
        //println!("rust: draw_state called");
        let board_size_flt = reversi_core::BOARD_SIZE as f64;
        let height = CANVAS_HEIGHT as f64;
        let width = CANVAS_WIDTH as f64;

        let bg_colour;
        let bg_line_colour;
        let piece_white_colour;
        let piece_black_colour;
        let piece_outline_colour;

        let highlight_fill;
        let highlight_outline;

        let user_colour_pref = callbacks.get_user_colour_pref();
        let user_colour_pref = &user_colour_pref as &str; // TODO why do I need to do this?

        //println!("reversi user_colour_pref is '{}'", user_colour_pref);

		let score_bg_colour;

        let cell_height = height / board_size_flt;
        let cell_width = width / board_size_flt;
		let piece_radius = (cell_height / 2.0 - 3.0) as i32;

		let last_move_highlight_bg;
		let last_move_highlight_outline;
		let last_move_highlight_radius = piece_radius;
		let last_move_highlight_thickness = 2;


        match user_colour_pref {
            "dark" => {
                bg_colour = "#003300";
                bg_line_colour = "#000000";
                piece_white_colour = "#bbbbbb";
                piece_black_colour = "#000000";
                piece_outline_colour = "#555555";
				//score_bg_colour = "#222255";
				score_bg_colour = "#003300";

                highlight_fill = "#88880088";
                highlight_outline = "#888800";

				last_move_highlight_bg = "#88000088";
				last_move_highlight_outline = "#880000";
            }
            "very_dark" => {
                bg_colour = "#003300";
                bg_line_colour = "#000000";
                piece_white_colour = "#444444";
                piece_black_colour = "#000000";
                piece_outline_colour = "#333333";
				//score_bg_colour = "#222255";
				score_bg_colour = "#003300";

                highlight_fill = "#88880088";
                highlight_outline = "#888800";

				last_move_highlight_bg = "#88000088";
				last_move_highlight_outline = "#880000";
            }

            _ => {

                bg_colour = "#008800";
                bg_line_colour = "#000000";
                piece_white_colour = "#dddddd";
                piece_black_colour = "#333333";
                piece_outline_colour = "#000000";
				//score_bg_colour = "#888888";
                score_bg_colour = "#008800";

                highlight_fill = "#ffff0088";
                highlight_outline = "#ffff00";

				last_move_highlight_bg = "#88000088";
				last_move_highlight_outline = "#ff0000";
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


        callbacks.draw_rect(bg_colour, y_offset, 0, y_offset + CANVAS_HEIGHT, CANVAS_HEIGHT);

        let line_size = 1;
        for y in 1..reversi_core::BOARD_SIZE {
            let y = y as i32;
            let cell_height = cell_height as i32;
            callbacks.draw_line(
                bg_line_colour,
                line_size,
                y_offset + y * cell_height,
                0,
                y_offset + y * cell_height,
                CANVAS_WIDTH,
            );
        }
        for x in 1..reversi_core::BOARD_SIZE {
            let x = x as i32;
            let cell_width = cell_width as i32;
            callbacks.draw_line(
                bg_line_colour,
                0,
                y_offset + line_size,
                x * cell_width,
                y_offset + CANVAS_HEIGHT,
                x * cell_width,
            );
        }

        for y in 0..reversi_core::BOARD_SIZE {
            for x in 0..reversi_core::BOARD_SIZE {
                let pt = Pt {
                    y: y as i32,
                    x: x as i32,
                };
                let y = y as f64;
                let x = x as f64;

                let y1 = y_offset + (y / board_size_flt * height) as i32;
                let x1 = (x / board_size_flt * width) as i32;
                let player_colour = match state.cell(Pt {
                    y: y as i32,
                    x: x as i32,
                }) {
                    reversi_core::CellState::PLAYER1 => Some(piece_white_colour),
                    reversi_core::CellState::PLAYER2 => Some(piece_black_colour),
                    _ => None,
                };
                let circ_y = (y1 as f64 + cell_height / 2.0) as i32;
                let circ_x = (x1 as f64 + cell_height / 2.0) as i32;
                if let Some(colour) = player_colour {
                    let radius = (cell_height / 2.0 - 3.0) as i32;

                    callbacks.draw_circle(colour, piece_outline_colour, circ_y, circ_x, radius, 2);
					// TODO figure out a more concise way to do this
					if let Some(last_move) = state.last_move {
						if last_move == pt {
							callbacks.draw_circle(last_move_highlight_bg, last_move_highlight_outline,
							                      circ_y, circ_x,
							                      last_move_highlight_radius,
							                      last_move_highlight_thickness);
						}
					}
                } else if state.is_valid_move(self.game_state.player_turn, pt) {
                    let highlight_radius = 15;
                    let highlight_outline_width = 3;
                    callbacks.draw_circle(
                        highlight_fill,
                        highlight_outline,
                        circ_y,
                        circ_x,
                        highlight_radius,
                        highlight_outline_width,
                    );
                }
            }
        }

		let score1 = self.game_state.score(CellState::PLAYER1);
		let score2 = self.game_state.score(CellState::PLAYER2);
		//let score1_text_colour = "#ffffff";
		//let score2_text_colour = "#000000";
		let score1_text_colour = piece_white_colour;
		let score2_text_colour = piece_black_colour;
		let player_move_highlight_bg_colour = "#00ffff66";

		//let player_move_highlight_colour = "#ffff00";
		let player_move_highlight_colour = "#00ffff";
		let player_move_highlight_inner_offset = 0;
		let score_text_width = 32;

		let score1_pos_x = CANVAS_WIDTH/4;
		let score2_pos_x = CANVAS_WIDTH*3/4;
		let score1_rect_y1 = 0;
		let score1_rect_x1 = score1_pos_x - score_text_width/2 - score_padding;
		let score1_rect_y2 = score_text_size + 2*score_padding;
		let score1_rect_x2 = score1_pos_x + score_text_width/2 + score_padding;
		/*
		callbacks.draw_rect(score_bg_colour,
		                    score1_rect_y1, score1_rect_x1,
		                    score1_rect_y2, score1_rect_x2);
		*/
		callbacks.draw_circle(score_bg_colour, "#00000000", 
		                      (score1_rect_y1 + score1_rect_y2)/2,
		                      (score1_rect_x1 + score1_rect_x2)/2,
		                      score_text_size/2 + 2*score_padding, 0);
		if self.game_state.player_turn == CellState::PLAYER1 {
			callbacks.draw_rect(player_move_highlight_bg_colour,
			                    score1_rect_y1, score1_rect_x1,
			                    score1_rect_y2, score1_rect_x2);
			let score1_rect_y1 = score1_rect_y1 + player_move_highlight_inner_offset;
			let score1_rect_x1 = score1_rect_x1 + player_move_highlight_inner_offset;
			let score1_rect_y2 = score1_rect_y2 - player_move_highlight_inner_offset;
			let score1_rect_x2 = score1_rect_x2 - player_move_highlight_inner_offset;
			draw_rect_outline(callbacks,
			                  &player_move_highlight_colour,
			                  player_move_highlight_thickness,
			                  score1_rect_y1, score1_rect_x1,
			                  score1_rect_y2, score1_rect_x2);
		}
		let score2_rect_y1 = 0;
		let score2_rect_x1 = score2_pos_x - score_text_width/2 - score_padding;
		let score2_rect_y2 = score_text_size + 2*score_padding;
		let score2_rect_x2 = score2_pos_x + score_text_width/2 + score_padding;

		//callbacks.draw_rect(score_bg_colour,
		//                    0,
		//                    score2_pos_x - score_text_width/2 - score_padding,
		//                    score_text_size + 2*score_padding,
		//                    score2_pos_x + score_text_width/2 + score_padding);
		callbacks.draw_circle(score_bg_colour, "#00000000", 
		                      (score2_rect_y1 + score2_rect_y2)/2,
		                      (score2_rect_x1 + score2_rect_x2)/2,
		                      score_text_size/2 + 2*score_padding, 0);


		if self.game_state.player_turn == CellState::PLAYER2 {
			callbacks.draw_rect(player_move_highlight_bg_colour,
			                    score2_rect_y1, score2_rect_x1,
			                    score2_rect_y2, score2_rect_x2);

			let score2_rect_y1 = score2_rect_y1 + player_move_highlight_inner_offset;
			let score2_rect_x1 = score2_rect_x1 + player_move_highlight_inner_offset;
			let score2_rect_y2 = score2_rect_y2 - player_move_highlight_inner_offset;
			let score2_rect_x2 = score2_rect_x2 - player_move_highlight_inner_offset;
			draw_rect_outline(callbacks,
			                  &player_move_highlight_colour,
			                  player_move_highlight_thickness,
			                  score2_rect_y1, score2_rect_x1,
			                  score2_rect_y2, score2_rect_x2);
		}


		callbacks.draw_text(&format!("{}", score1),
		                    score1_text_colour,
		                    score_text_size + score_padding,
		                    score1_pos_x,
		                    score_text_size,
		                    TextAlign::Middle);
		callbacks.draw_text(&format!("{}", score2),
		                    score2_text_colour,
		                    score_text_size + score_padding,
		                    score2_pos_x,
		                    score_text_size,
		                    TextAlign::Middle);
							

        let session_id = self.session_id;
        callbacks.set_btn_enabled(
            BTN_ID_UNDO,
            callbacks.has_saved_state_offset(session_id, -1),
        );
        callbacks.set_btn_enabled(BTN_ID_REDO, callbacks.has_saved_state_offset(session_id, 1));

        callbacks.draw_refresh();
    }
}

impl AlexGamesApi for AlexGamesReversi {
    fn callbacks(&self) -> &CCallbacksPtr {
        self.callbacks
    }

    fn update(&mut self, _dt_ms: i32) {
        //println!("rust: update called");
        //draw_state(&handle.game_state as reversi_core::State);
        self.draw_state();
    }

    fn handle_user_clicked(&mut self, pos_y: i32, pos_x: i32) {
        println!("From rust, user clicked {} {}", pos_y, pos_x);
        let cell_height = CANVAS_HEIGHT / (reversi_core::BOARD_SIZE as i32);
        let cell_width = CANVAS_WIDTH / (reversi_core::BOARD_SIZE as i32);

        let cell_y = (pos_y - y_offset) / cell_height;
        let cell_x = pos_x / cell_width;
        println!("User clicked cell {cell_y} {cell_x}");
        //handle.draw_rect("#ff0000", pos_y, pos_x, pos_y + 20, pos_x + 20);
        //let rust_game_api::GameState::ReversiGameState(reversi_state) = &mut handle.game_state;

        let player_turn = self.game_state.player_turn;
        let rc = reversi_core::player_move(
            &mut self.game_state,
            player_turn,
            Pt {
                y: cell_y,
                x: cell_x,
            },
        );
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
        match btn_id {
            BTN_ID_UNDO => {
                self.load_state_offset(-1);
            }
            BTN_ID_REDO => {
                self.load_state_offset(1);
            }
            _ => {
                let err_msg = format!("Unhandled btn_id {}", btn_id);
                println!("{}", err_msg);
                self.callbacks.set_status_err(&err_msg);
                return;
            }
        }

        self.draw_state();
    }

    //fn start_game(_handle: &mut RustGameState) {
    fn start_game(&mut self, session_id_and_state: Option<(i32, Vec<u8>)>) {
        // TODO
        println!("rust: start called");

        if let Some(session_id_and_state) = session_id_and_state {
            let (session_id, state_serialized) = session_id_and_state;
            self.set_state(&state_serialized, session_id);
        } else if let Some(_session_id) = self.callbacks.get_last_session_id("reversi") {
            self.load_state_offset(0);
        } else {
            self.session_id = self.callbacks.get_new_session_id();
        }
    }

    fn get_state(&self) -> Option<Vec<u8>> {
        // TODO this is huge, I bet the enum is encoded as 4 bytes
        // see if I can override it to make them only 2 bits each? Or
        // at least just 1 byte.
        // TODO also add a version number and abstract it into a function

        // TODO check what endianness I used in Lua games
        //match bincode::serialize(&self.game_state) {
        match reversi_serialize::serialize(&self.game_state) {
            Ok(state_encoded) => {
				let test_state_decoded = reversi_serialize::deserialize(&state_encoded).unwrap();
				assert_eq!(self.game_state, test_state_decoded);
                return Some(state_encoded);
            },
            //Err(e) => {
            Err(..) => {
				/*
                // TODO use format macro and pass this more useful string to the API
                println!("Error encoding state: {}", e);
                self.callbacks.set_status_err("Error encoding state");
                return None;
				*/
				return None;
            }
        }
    }

	fn handle_game_option_evt(&mut self, option_id: &str, option_type: OptionType, value: i32) {
		match option_id {
			GAME_OPTION_NEW_GAME => {
				self.game_state = reversi_core::State::new();
				self.session_id = self.callbacks.get_new_session_id();
				self.save_state();
				self.draw_state();
			},
			_ => {
				panic!("Unhandled game option");
			},
		}
	}


    //fn init(_callbacks: &rust_game_api::Callbacks) -> Box <dyn rust_game_api::GameState> {
    fn init(&mut self, callbacks: &rust_game_api::CCallbacksPtr) {
        self.game_state = reversi_core::State::new();
        callbacks.create_btn(BTN_ID_UNDO, "Undo", 1);
        callbacks.create_btn(BTN_ID_REDO, "Redo", 1);
        callbacks.set_btn_enabled(BTN_ID_UNDO, false);
        callbacks.set_btn_enabled(BTN_ID_REDO, false);

		//callbacks.set_game_canvas_size(CANVAS_WIDTH, CANVAS_HEIGHT);
		callbacks.set_game_canvas_size(480, 480+32);

		callbacks.add_game_option(GAME_OPTION_NEW_GAME, &OptionInfo {
			option_type: OptionType::Button,
			label: "New Game".to_string(),
			value: 0,
		});
    }
}

pub fn init_reversi(
    callbacks: &'static rust_game_api::CCallbacksPtr,
) -> Box<dyn AlexGamesApi + 'static> {
    let mut reversi = AlexGamesReversi {
        game_state: reversi_core::State::new(),
		session_id: 0,
        callbacks: callbacks,
    };
    reversi.init(callbacks);
    Box::from(reversi)
}
