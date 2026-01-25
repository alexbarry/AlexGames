/**
 * Free Cell
 * author: Alex Barry (github.com/alexbarry)
 *
 */
use crate::rust_game_api;

use crate::rust_game_api::{
    AlexGamesApi, CCallbacksPtr, MouseEvt, OptionInfo, OptionType, TextAlign, TouchInfo,
    CANVAS_HEIGHT, CANVAS_WIDTH,
};

use crate::free_cell::free_cell_core::{self, CardPos, PlayAreaPickupStatus};
use crate::free_cell::free_cell_draw::{self, DrawState};
use crate::free_cell::free_cell_serialize;

use crate::libs::cards;
use crate::libs::point::Pt;

const BTN_ID_UNDO: &str = "btn_undo";
const BTN_ID_REDO: &str = "btn_redo";
const BTN_ID_AUTOCOMPLETE: &str = "btn_autocomplete";

const OPTION_ID_NEW_GAME: &str = "option_new_game";

const WIN_MSG: &'static str = "Congratulations, you win!";

pub struct AlexGamesFreeCell {
    callbacks: &'static CCallbacksPtr,

    game_state: free_cell_core::State,
    game_won_yet: bool,
    draw_state: DrawState,

    session_id: Option<i32>,
    current_touch_id: Option<i64>,
}

fn status_to_err_msg(status: free_cell_core::Status) -> Option<String> {
    match status {
        free_cell_core::Status::Success
        | free_cell_core::Status::InvalidMove
        | free_cell_core::Status::CellOccupied
        | free_cell_core::Status::InvalidGoalMove => None,
        free_cell_core::Status::MoveConsumedNeededCell => {
            Some("Not enough free cells to move this many cards to this cell".to_string())
        }
    }
}

impl AlexGamesFreeCell {
    fn draw_state(&mut self) {
        self.draw_state.draw_state(self.callbacks, &self.game_state);

        if let Some(session_id) = self.session_id {
            self.callbacks.set_btn_enabled(
                BTN_ID_UNDO,
                self.callbacks.has_saved_state_offset(session_id, -1),
            );
            self.callbacks.set_btn_enabled(
                BTN_ID_REDO,
                self.callbacks.has_saved_state_offset(session_id, 1),
            );

            self.callbacks
                .set_btn_enabled(BTN_ID_AUTOCOMPLETE, self.game_state.can_autocomplete());
        } else {
            self.callbacks.set_btn_enabled(BTN_ID_UNDO, false);
            self.callbacks.set_btn_enabled(BTN_ID_REDO, false);
        }
    }

    fn save_state(&mut self) {
        let session_id = self
            .session_id
            .unwrap_or_else(|| self.callbacks.get_new_session_id());
        let serialized_state = free_cell_serialize::serialize_state(&self.game_state);
        let test_state = free_cell_serialize::deserialize_state(&serialized_state);
        assert_eq!(test_state, self.game_state);
        self.session_id = Some(session_id);
        self.callbacks.save_state(session_id, serialized_state);
    }

    fn set_state(&mut self, serialized_state: &Vec<u8>) {
        let new_state = free_cell_serialize::deserialize_state(&serialized_state);
        self.game_state = new_state;
        self.draw_state();
    }

    fn set_state_offset(&mut self, offset: i32) {
        let serialized_state = self
            .callbacks
            .adjust_saved_state_offset(self.session_id.unwrap(), offset);
        if let Some(serialized_state) = serialized_state {
            self.set_state(&serialized_state);
        }
    }
}

impl AlexGamesApi for AlexGamesFreeCell {
    fn callbacks(&self) -> &CCallbacksPtr {
        self.callbacks
    }
    fn init(&mut self, callbacks: &'static CCallbacksPtr) {
        callbacks.enable_evt("mouse_updown");
        callbacks.enable_evt("mouse_move");
        callbacks.enable_evt("touch");

        callbacks.create_btn(BTN_ID_UNDO, "Undo", 1);
        callbacks.create_btn(BTN_ID_AUTOCOMPLETE, "Autocomplete", 1);
        callbacks.create_btn(BTN_ID_REDO, "Redo", 1);
        callbacks.set_btn_enabled(BTN_ID_UNDO, false);
        callbacks.set_btn_enabled(BTN_ID_AUTOCOMPLETE, false);
        callbacks.set_btn_enabled(BTN_ID_REDO, false);

        callbacks.add_game_option(
            OPTION_ID_NEW_GAME,
            &OptionInfo {
                option_type: OptionType::Button,
                label: "New Game".to_string(),
                value: 0,
            },
        );
    }
    fn start_game(&mut self, saved_state: Option<(i32, Vec<u8>)>) {
        let saved_state = if let Some(saved_state) = saved_state {
            Some(saved_state)
        } else {
            if let Some(session_id) = self.callbacks.get_last_session_id("free_cell") {
                let serialized_state = self.callbacks.adjust_saved_state_offset(session_id, 0);
                if let Some(serialized_state) = serialized_state {
                    Some((session_id, serialized_state))
                } else {
                    None
                }
            } else {
                None
            }
        };
        if let Some(saved_state) = saved_state {
            let (session_id, serialized_state) = saved_state;
            println!(
                "Loading {} bytes of saved state, session ID {}",
                serialized_state.len(),
                session_id
            );
            self.session_id = Some(session_id);
            self.set_state(&serialized_state);
        } else {
            println!("No saved state found, starting new game");
            self.game_state.new_game();
            self.save_state();
        }
    }
    fn update(&mut self, dt_ms: i32) {
        //self.callbacks.draw_rect(&"#ff0000", 50, 50, 250, 100);
        //free_cell_draw::draw_state(self.callbacks, &self.game_state.expect("game state is none?"));
        self.draw_state.update_anims(self.callbacks, dt_ms);
        if self.game_state.game_won()
            && !self.game_won_yet
            && !self.draw_state.autocomplete_in_progress()
        {
            self.game_won_yet = true;
            self.callbacks.set_status_msg(WIN_MSG);
        }
        self.draw_state();
    }
    fn handle_user_clicked(&mut self, pos_y: i32, pos_x: i32) {}

    fn handle_mouse_evt(&mut self, evt_id: MouseEvt, pos_y: i32, pos_x: i32, _buttons: i32) {
        let game_state = &mut self.game_state;
        let mouse_pos = Pt { y: pos_y, x: pos_x };
        let card_pos = free_cell_draw::cursor_pos_to_card_pos(game_state, mouse_pos);
        match evt_id {
            MouseEvt::Down => {
                if card_pos.is_some_and(|card_pos| game_state.can_pickup(card_pos)) {
                    self.draw_state.picked_up_card = card_pos;
                    self.draw_state.picked_up_card_pos = Some(mouse_pos);
                } else if let Some(CardPos::PlayArea(col_idx, col_pos)) = card_pos {
                    let msg = match game_state.can_pickup_play_area(col_idx, col_pos) {
                        PlayAreaPickupStatus::NotEnoughFreeCells => {
                            let free_cells = game_state.free_cell_count();
                            let card_pick_up_failure_count =
                                game_state.play_area[col_idx].len() - col_pos;
                            Some(format!(
                                "Can not pick up {} cards, only have {} free {}.",
                                card_pick_up_failure_count,
                                free_cells,
                                if free_cells == 1 { "cell" } else { "cells" }
                            ))
                        }
                        PlayAreaPickupStatus::NotInOrder => Some(format!(
                            "Can not pick up this card, cards below it are not in order."
                        )),
                        PlayAreaPickupStatus::NoCards | PlayAreaPickupStatus::Success => None,
                    };
                    if let Some(msg) = msg {
                        self.callbacks.set_status_err(&msg);
                    };
                }
            }
            MouseEvt::Up => {
                let src = self.draw_state.picked_up_card;
                let dst = card_pos;
                if src.is_some() && dst.is_some() {
                    let src = src.unwrap();
                    let dst = dst.unwrap();

                    let auto_move = if src == dst {
                        let src_pos = self.draw_state.picked_up_card_pos.unwrap();
                        if mouse_pos.sub(src_pos).mag() < 5 {
                            true
                        } else {
                            false
                        }
                    } else {
                        false
                    };

                    let move_status = if !auto_move {
                        game_state.apply_move(src, dst)
                    } else {
                        game_state.auto_move(src)
                    };

                    if move_status == free_cell_core::Status::Success {
                        if game_state.game_won() && !self.game_won_yet {
                            self.game_won_yet = true;
                            self.callbacks.set_status_msg(WIN_MSG);
                            self.draw_state.start_win_animation(self.callbacks);
                        }
                        self.save_state();
                    } else {
                        if let Some(msg) = status_to_err_msg(move_status) {
                            self.callbacks.set_status_err(&msg);
                        }
                    }
                }
                self.draw_state.picked_up_card = None;
                self.draw_state.picked_up_card_pos = None;
            }
            MouseEvt::Leave => {
                self.draw_state.picked_up_card = None;
                self.draw_state.picked_up_card_pos = None;
            }
            _ => {}
        }
        self.draw_state();
    }

    fn handle_touch_evt(&mut self, evt_id: &str, touches: Vec<TouchInfo>) {
        let mouse_evt_type = match evt_id {
            "touchstart" => Some(MouseEvt::Down),
            "touchend" => Some(MouseEvt::Up),
            "touchcancel" => Some(MouseEvt::Leave),
            _ => None,
        };

        let buttons = 0;

        for touch in touches.iter() {
            if let Some(current_touch_id) = self.current_touch_id {
                if touch.id == current_touch_id {
                    if evt_id == "touchend" {
                        self.current_touch_id = None;
                    }
                    if evt_id == "touchmove" {
                        self.handle_mousemove(touch.y as i32, touch.x as i32, buttons);
                    } else {
                        self.handle_mouse_evt(
                            mouse_evt_type.unwrap(),
                            touch.y as i32,
                            touch.x as i32,
                            buttons,
                        );
                    }
                }
            } else if evt_id == "touchstart" {
                self.current_touch_id = Some(touch.id);
                self.handle_mouse_evt(
                    mouse_evt_type.unwrap(),
                    touch.y as i32,
                    touch.x as i32,
                    buttons,
                );
            }
        }
    }

    fn handle_mousemove(&mut self, pos_y: i32, pos_x: i32, _buttons: i32) {
        if let Some(_) = self.draw_state.picked_up_card {
            self.draw_state.picked_up_card_pos = Some(Pt { y: pos_y, x: pos_x });
            self.draw_state();
        }
    }

    fn handle_btn_clicked(&mut self, btn_id: &str) {
        match btn_id {
            BTN_ID_UNDO => self.set_state_offset(-1),
            BTN_ID_REDO => self.set_state_offset(1),
            BTN_ID_AUTOCOMPLETE => {
                let autocomplete_moves = self.game_state.get_autocomplete_moves();
                self.draw_state
                    .anim_moves(self.callbacks, &self.game_state, &autocomplete_moves);
                println!(
                    "Got {} autocomplete moves: {}",
                    autocomplete_moves.len(),
                    autocomplete_moves
                        .iter()
                        .map(|m| format!("{:?}", m))
                        .collect::<Vec<_>>()
                        .join(", ")
                );

                for (src, dst) in autocomplete_moves.iter() {
                    let status = self.game_state.apply_move(*src, *dst);
                    assert!(status == free_cell_core::Status::Success);
                }

                self.save_state();
            }
            _ => {
                panic!("Unhandled button ID {}", btn_id);
            }
        }
    }

    fn handle_game_option_evt(&mut self, option_id: &str, option_type: OptionType, value: i32) {
        match option_id {
            OPTION_ID_NEW_GAME => {
                assert_eq!(option_type, OptionType::Button);
                self.callbacks.set_status_msg(&format!("Starting new game"));
                self.session_id = Some(self.callbacks.get_new_session_id());
                self.game_state.new_game();
                self.draw_state.reset_state();
                self.game_won_yet = true;
                self.save_state();
                self.draw_state();
            }
            _ => {
                panic!("Unhandled game option {}", option_id);
            }
        }
    }

    fn get_state(&self) -> Option<Vec<u8>> {
        return Some(free_cell_serialize::serialize_state(&self.game_state));
    }
}

pub fn init_free_cell(callbacks: &'static CCallbacksPtr) -> Box<dyn AlexGamesApi> {
    let mut game = AlexGamesFreeCell {
        callbacks: callbacks,
        game_state: free_cell_core::State::new(),
        game_won_yet: false,
        draw_state: DrawState::new(),
        session_id: None,

        current_touch_id: None,
    };
    game.init(callbacks);

    Box::from(game)
}
