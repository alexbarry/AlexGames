use crate::rust_game_api::{CCallbacksPtr, TextAlign, CANVAS_HEIGHT, CANVAS_WIDTH};

use crate::reversi::reversi_core;
use crate::reversi::reversi_core::{CellState, Pt};

const SCORE_TEXT_SIZE: i32 = 24;
const SCORE_PADDING: i32 = 4;
const PLAYER_MOVE_HIGHLIGHT_THICKNESS: i32 = 4;
const TEXT_BOX_SIZE_Y: i32 = SCORE_TEXT_SIZE + 2 * SCORE_PADDING;
const Y_OFFSET: i32 = TEXT_BOX_SIZE_Y;

pub const BTN_ID_UNDO: &str = "btn_undo";
pub const BTN_ID_REDO: &str = "btn_redo";

pub const GAME_OPTION_NEW_GAME: &str = "option_id_new_game";

struct AnimationKeyframe {
    prev_game_state: reversi_core::State,
    new_game_state: reversi_core::State,
    duration_ms: i32,
    time_elapsed_ms: i32,

    is_thinking: bool,
}

impl AnimationKeyframe {
    fn progress(&self) -> f32 {
        (self.time_elapsed_ms as f32) / (self.duration_ms as f32)
    }
}

pub struct DrawState {
    animation_queue: Vec<AnimationKeyframe>,
}

fn smoothstep(x: f64) -> f64 {
    3.0 * x * x - 2.0 * x * x
}

fn draw_rect_outline(
    callbacks: &CCallbacksPtr,
    colour: &str,
    thickness: i32,
    y1: i32,
    x1: i32,
    y2: i32,
    x2: i32,
) {
    callbacks.draw_line(
        &colour,
        thickness,
        y1,
        x1 - thickness / 2,
        y1,
        x2 + thickness / 2,
    );
    callbacks.draw_line(
        &colour,
        thickness,
        y1 - thickness / 2,
        x1,
        y2 + thickness / 2,
        x1,
    );

    callbacks.draw_line(
        &colour,
        thickness,
        y2,
        x2 + thickness / 2,
        y2,
        x1 - thickness / 2,
    );
    callbacks.draw_line(
        &colour,
        thickness,
        y2 + thickness / 2,
        x2,
        y1 - thickness / 2,
        x2,
    );
}

impl DrawState {
    pub fn add_animation(
        &mut self,
        old_state: &reversi_core::State,
        new_state: &reversi_core::State,
        duration_ms: i32,
    ) {
        self.animation_queue.push(AnimationKeyframe {
            prev_game_state: old_state.clone(),
            new_game_state: new_state.clone(),
            duration_ms: duration_ms,
            time_elapsed_ms: 0,
            is_thinking: false,
        });
    }

    pub fn add_thinking_animation(&mut self, state: &reversi_core::State, duration_ms: i32) {
        self.animation_queue.push(AnimationKeyframe {
            prev_game_state: state.clone(),
            new_game_state: state.clone(),
            duration_ms: duration_ms,
            time_elapsed_ms: 0,
            is_thinking: true,
        });
    }

    pub fn update_state(&mut self, _callbacks: &CCallbacksPtr, dt_ms: i32) {
        let mut dt_ms = dt_ms;
        while self.animation_queue.len() > 0 && dt_ms > 0 {
            let anim = &mut self.animation_queue[0];
            anim.time_elapsed_ms += dt_ms;

            if anim.time_elapsed_ms >= anim.duration_ms {
                dt_ms -= anim.time_elapsed_ms - anim.duration_ms;
                self.animation_queue.remove(0);
            } else {
                break;
            }
        }
    }

    pub fn draw_state(
        &self,
        callbacks: &CCallbacksPtr,
        state: &reversi_core::State,
        session_id: i32,
    ) {
        let (prev_state, new_state, progress, is_animating, is_thinking) =
            if self.animation_queue.len() > 0 {
                let anim = &self.animation_queue[0];
                (
                    &anim.prev_game_state,
                    &anim.new_game_state,
                    anim.progress(),
                    true,
                    anim.is_thinking,
                )
            } else {
                (state, state, 0.0, false, false)
            };
        //let callbacks = self.callbacks;
        //let state = &self.game_state;
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

                //last_move_highlight_bg = "#88000088";
                last_move_highlight_bg = "#88000044";
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

        callbacks.draw_rect(
            bg_colour,
            Y_OFFSET,
            0,
            Y_OFFSET + CANVAS_HEIGHT,
            CANVAS_HEIGHT,
        );

        let line_size = 1;
        for y in 1..reversi_core::BOARD_SIZE {
            let y = y as i32;
            let cell_height = cell_height as i32;
            callbacks.draw_line(
                bg_line_colour,
                line_size,
                Y_OFFSET + y * cell_height,
                0,
                Y_OFFSET + y * cell_height,
                CANVAS_WIDTH,
            );
        }
        for x in 1..reversi_core::BOARD_SIZE {
            let x = x as i32;
            let cell_width = cell_width as i32;
            callbacks.draw_line(
                bg_line_colour,
                0,
                Y_OFFSET + line_size,
                x * cell_width,
                Y_OFFSET + CANVAS_HEIGHT,
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

                let y1 = Y_OFFSET + (y / board_size_flt * height) as i32;
                let x1 = (x / board_size_flt * width) as i32;

                let state = if progress < 0.5 {
                    prev_state
                } else {
                    new_state
                };

                let player_colour = match state.cell(pt) {
                    reversi_core::CellState::PLAYER1 => Some(piece_white_colour),
                    reversi_core::CellState::PLAYER2 => Some(piece_black_colour),
                    _ => None,
                };
                let circ_y = (y1 as f64 + cell_height / 2.0) as i32;
                let circ_x = (x1 as f64 + cell_height / 2.0) as i32;
                if let Some(colour) = player_colour {
                    let progress = progress as f64;
                    let radius = (cell_height / 2.0 - 3.0) as i32;
                    let radius_frac = if prev_state.cell(pt) == new_state.cell(pt) {
                        1.0 as f64
                    } else if progress < 0.5 {
                        (0.5 - progress) / 0.5
                    } else {
                        (progress - 0.5) / 0.5
                    };
                    //let radius = smoothstep(radius) as i32;
                    let radius_frac = smoothstep(radius_frac);
                    let radius = ((radius as f64) * radius_frac) as i32;

                    callbacks.draw_circle(colour, piece_outline_colour, circ_y, circ_x, radius, 2);
                    // TODO figure out a more concise way to do this
                    if let Some(last_move) = state.last_move {
                        if last_move == pt {
                            callbacks.draw_circle(
                                last_move_highlight_bg,
                                last_move_highlight_outline,
                                circ_y,
                                circ_x,
                                last_move_highlight_radius,
                                last_move_highlight_thickness,
                            );
                        }
                    }
                } else if !is_animating && state.is_valid_move(state.player_turn, pt) {
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

        let score1 = state.score(CellState::PLAYER1);
        let score2 = state.score(CellState::PLAYER2);
        //let score1_text_colour = "#ffffff";
        //let score2_text_colour = "#000000";
        let score1_text_colour = piece_white_colour;
        let score2_text_colour = piece_black_colour;
        let player_move_highlight_bg_colour = "#00ffff66";

        //let player_move_highlight_colour = "#ffff00";
        let player_move_highlight_colour = "#00ffff";
        let player_move_highlight_inner_offset = 0;
        let score_text_width = 32;

        let score1_pos_x = CANVAS_WIDTH / 4;
        let score2_pos_x = CANVAS_WIDTH * 3 / 4;
        let score1_rect_y1 = 0;
        let score1_rect_x1 = score1_pos_x - score_text_width / 2 - SCORE_PADDING;
        let score1_rect_y2 = SCORE_TEXT_SIZE + 2 * SCORE_PADDING;
        let score1_rect_x2 = score1_pos_x + score_text_width / 2 + SCORE_PADDING;
        /*
        callbacks.draw_rect(score_bg_colour,
                            score1_rect_y1, score1_rect_x1,
                            score1_rect_y2, score1_rect_x2);
        */
        callbacks.draw_circle(
            score_bg_colour,
            "#00000000",
            (score1_rect_y1 + score1_rect_y2) / 2,
            (score1_rect_x1 + score1_rect_x2) / 2,
            SCORE_TEXT_SIZE / 2 + 2 * SCORE_PADDING,
            0,
        );
        if state.player_turn == CellState::PLAYER1 {
            callbacks.draw_rect(
                player_move_highlight_bg_colour,
                score1_rect_y1,
                score1_rect_x1,
                score1_rect_y2,
                score1_rect_x2,
            );
            let score1_rect_y1 = score1_rect_y1 + player_move_highlight_inner_offset;
            let score1_rect_x1 = score1_rect_x1 + player_move_highlight_inner_offset;
            let score1_rect_y2 = score1_rect_y2 - player_move_highlight_inner_offset;
            let score1_rect_x2 = score1_rect_x2 - player_move_highlight_inner_offset;
            draw_rect_outline(
                callbacks,
                &player_move_highlight_colour,
                PLAYER_MOVE_HIGHLIGHT_THICKNESS,
                score1_rect_y1,
                score1_rect_x1,
                score1_rect_y2,
                score1_rect_x2,
            );
        }
        let score2_rect_y1 = 0;
        let score2_rect_x1 = score2_pos_x - score_text_width / 2 - SCORE_PADDING;
        let score2_rect_y2 = SCORE_TEXT_SIZE + 2 * SCORE_PADDING;
        let score2_rect_x2 = score2_pos_x + score_text_width / 2 + SCORE_PADDING;

        //callbacks.draw_rect(score_bg_colour,
        //                    0,
        //                    score2_pos_x - score_text_width/2 - SCORE_PADDING,
        //                    SCORE_TEXT_SIZE + 2*SCORE_PADDING,
        //                    score2_pos_x + score_text_width/2 + SCORE_PADDING);
        callbacks.draw_circle(
            score_bg_colour,
            "#00000000",
            (score2_rect_y1 + score2_rect_y2) / 2,
            (score2_rect_x1 + score2_rect_x2) / 2,
            SCORE_TEXT_SIZE / 2 + 2 * SCORE_PADDING,
            0,
        );

        if state.player_turn == CellState::PLAYER2 {
            callbacks.draw_rect(
                player_move_highlight_bg_colour,
                score2_rect_y1,
                score2_rect_x1,
                score2_rect_y2,
                score2_rect_x2,
            );

            let score2_rect_y1 = score2_rect_y1 + player_move_highlight_inner_offset;
            let score2_rect_x1 = score2_rect_x1 + player_move_highlight_inner_offset;
            let score2_rect_y2 = score2_rect_y2 - player_move_highlight_inner_offset;
            let score2_rect_x2 = score2_rect_x2 - player_move_highlight_inner_offset;
            draw_rect_outline(
                callbacks,
                &player_move_highlight_colour,
                PLAYER_MOVE_HIGHLIGHT_THICKNESS,
                score2_rect_y1,
                score2_rect_x1,
                score2_rect_y2,
                score2_rect_x2,
            );
        }

        callbacks.draw_text(
            &format!("{}", score1),
            score1_text_colour,
            SCORE_TEXT_SIZE + SCORE_PADDING,
            score1_pos_x,
            SCORE_TEXT_SIZE,
            TextAlign::Middle,
        );
        callbacks.draw_text(
            &format!("{}", score2),
            score2_text_colour,
            SCORE_TEXT_SIZE + SCORE_PADDING,
            score2_pos_x,
            SCORE_TEXT_SIZE,
            TextAlign::Middle,
        );

        const THINKING_TEXT_SIZE: i32 = 24;
        if is_thinking {
            callbacks.draw_text(
                "Thinking...",
                "#888888",
                THINKING_TEXT_SIZE + SCORE_PADDING,
                CANVAS_WIDTH / 2,
                THINKING_TEXT_SIZE,
                TextAlign::Middle,
            );
        }

        callbacks.set_btn_enabled(
            BTN_ID_UNDO,
            callbacks.has_saved_state_offset(session_id, -1),
        );
        callbacks.set_btn_enabled(BTN_ID_REDO, callbacks.has_saved_state_offset(session_id, 1));

        callbacks.draw_refresh();
    }

    pub fn draw_pos_to_cell(&self, pos_y: i32, pos_x: i32) -> Pt {
        println!("From rust, user clicked {} {}", pos_y, pos_x);
        let cell_height = CANVAS_HEIGHT / (reversi_core::BOARD_SIZE as i32);
        let cell_width = CANVAS_WIDTH / (reversi_core::BOARD_SIZE as i32);

        let cell_y = (pos_y - Y_OFFSET) / cell_height;
        let cell_x = pos_x / cell_width;
        //handle.draw_rect("#ff0000", pos_y, pos_x, pos_y + 20, pos_x + 20);
        //let rust_game_api::GameState::ReversiGameState(reversi_state) = &mut handle.game_state;

        Pt {
            y: cell_y,
            x: cell_x,
        }
    }

    pub fn new() -> DrawState {
        DrawState {
            animation_queue: Vec::new(),
        }
    }
}
