// Game:   Reversi
// Author: Alex Barry (github.com/alexbarry)
//
// TODO:
//  * fix deserialization errors in reversi in wasm? I'm not sure I see it anymore. Check the wxWidgets build, I saw it there too
//  * network multiplayer
//  * either allow player to pass when they can't move, or auto skip to next player
//  * set_status_msg indicating whose turn is first

use crate::rust_game_api;

use crate::rust_game_api::{AlexGamesApi, CCallbacksPtr, OptionInfo, OptionType};

use crate::libs::ai::mcts;

// TODO there must be a better way than this? This file is in the same directory
use crate::reversi::reversi_core;
use crate::reversi::reversi_core::{CellState, Pt, ReversiErr};
use crate::reversi::reversi_draw;
use crate::reversi::reversi_serialize;

/*
impl rust_game_api::GameState for reversi_core::State {
}
*/

const FPS: i32 = 60;
const UPDATE_TIME_MS: i32 = 1000 / FPS;

pub struct AlexGamesReversi {
    game_state: reversi_core::State,
    session_id: i32,
    //callbacks: *mut rust_game_api::CCallbacksPtr,
    //callbacks: &'a rust_game_api::CCallbacksPtr,
    callbacks: &'static rust_game_api::CCallbacksPtr,

    ai_state: mcts::MCTSState<reversi_core::State, reversi_core::Pt>,

    draw: reversi_draw::DrawState,
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
        self.draw
            .draw_state(self.callbacks, &self.game_state, self.session_id);
    }
}

impl AlexGamesApi for AlexGamesReversi {
    fn callbacks(&self) -> &CCallbacksPtr {
        self.callbacks
    }

    fn update(&mut self, dt_ms: i32) {
        self.draw.update_state(self.callbacks, dt_ms);
        //println!("rust: update called");
        //draw_state(&handle.game_state as reversi_core::State);
        self.draw_state();
    }

    fn handle_user_clicked(&mut self, pos_y: i32, pos_x: i32) {
        println!("From rust, user clicked {} {}", pos_y, pos_x);
        if self.draw.is_animating() {
            println!("Ignoring user click because animations are in progress");
            return;
        }

        let cell = self.draw.draw_pos_to_cell(pos_y, pos_x);
        let cell_y = cell.y;
        let cell_x = cell.x;

        let player_turn = self.game_state.player_turn;
        println!("User clicked cell {cell_y} {cell_x}, player_turn={player_turn:?}");
        let old_game_state = self.game_state.clone();
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
            self.draw
                .add_animation(&old_game_state, &self.game_state, 500);
            // TODO need a delay between player's move and AI move
            // TODO only do this if AI multiplayer is chosen
            // TODO maybe an animation would make it easier?
            // Handle AI move
            if false && player_turn == CellState::PLAYER1 {
                self.draw.add_thinking_animation(&self.game_state, 1000);
                let old_game_state = self.game_state.clone();
                let ai_move = self
                    .ai_state
                    .get_move(self.game_state)
                    .expect("empty move from ai::get_move");
                println!("AI move is: {:?}", ai_move);
                let rc =
                    reversi_core::player_move(&mut self.game_state, CellState::PLAYER2, ai_move);
                if let Err(err) = rc {
                    panic!("Error from AI move: {:?}", err);
                }
                self.draw
                    .add_animation(&old_game_state, &self.game_state, 500);
            }

            self.save_state();
        }
        self.draw_state();
    }

    fn handle_btn_clicked(&mut self, btn_id: &str) {
        println!("reversi handle_btn_clicked, btn_id=\"{}\"", btn_id);
        match btn_id {
            reversi_draw::BTN_ID_UNDO => {
                self.load_state_offset(-1);
            }
            reversi_draw::BTN_ID_REDO => {
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
            }
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

    fn handle_game_option_evt(&mut self, option_id: &str, _option_type: OptionType, _value: i32) {
        match option_id {
            reversi_draw::GAME_OPTION_NEW_GAME => {
                self.game_state = reversi_core::State::new();
                self.session_id = self.callbacks.get_new_session_id();
                self.save_state();
                self.draw_state();
            }
            _ => {
                panic!("Unhandled game option");
            }
        }
    }

    //fn init(_callbacks: &rust_game_api::Callbacks) -> Box <dyn rust_game_api::GameState> {
    fn init(&mut self, callbacks: &rust_game_api::CCallbacksPtr) {
        self.game_state = reversi_core::State::new();
        callbacks.create_btn(reversi_draw::BTN_ID_UNDO, "Undo", 1);
        callbacks.create_btn(reversi_draw::BTN_ID_REDO, "Redo", 1);
        callbacks.set_btn_enabled(reversi_draw::BTN_ID_UNDO, false);
        callbacks.set_btn_enabled(reversi_draw::BTN_ID_REDO, false);

        //callbacks.set_game_canvas_size(CANVAS_WIDTH, CANVAS_HEIGHT);
        callbacks.set_game_canvas_size(480, 480 + 32);

        callbacks.add_game_option(
            reversi_draw::GAME_OPTION_NEW_GAME,
            &OptionInfo {
                option_type: OptionType::Button,
                label: "New Game".to_string(),
                value: 0,
            },
        );

        callbacks.update_timer_ms(UPDATE_TIME_MS);
    }
}

pub fn init_reversi(
    callbacks: &'static rust_game_api::CCallbacksPtr,
) -> Box<dyn AlexGamesApi + 'static> {
    let mut reversi = AlexGamesReversi {
        game_state: reversi_core::State::new(),
        session_id: 0,
        callbacks: callbacks,

        ai_state: mcts::MCTSState::init(mcts::MCTSParams {
            get_possible_moves: |game_state| {
                //println!("reversi_main: get_possible_moves called with state {:?}", game_state);
                game_state.get_valid_moves()
            },
        }),
        draw: reversi_draw::DrawState::new(),
    };
    reversi.init(callbacks);
    Box::from(reversi)
}
