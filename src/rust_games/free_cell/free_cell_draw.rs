use crate::free_cell::free_cell_core::{self, CardPos, State};
use crate::libs::cards::{self, CardDraw, Card, Rank, Suit, CardDrawSize, CARD_SIZE_8_WIDE, DEFAULT_CARD_COLOURS_LIGHT, DEFAULT_CARD_COLOURS_DARK};

use crate::rust_game_api::{
    AlexGamesApi, CCallbacksPtr, OptionInfo, OptionType, TextAlign, CANVAS_HEIGHT, CANVAS_WIDTH,
};

pub use crate::libs::point::Pt;
pub use crate::libs::celebrations::fireworks::FireworksState;

const padding: i32 = 3;

const BG_COLOUR_LIGHT: &str = "#008800";
const BG_COLOUR_DARK: &str = "#004400";
const PLAY_AREA_CARD_OFFSET_Y: i32 = 18;

const CARD_DIMS: &'static CardDrawSize = &CARD_SIZE_8_WIDE;
const CARD_SIZE: Pt = Pt { y: CARD_DIMS.height, x: CARD_DIMS.width };
const play_area_start_x: i32 = CANVAS_WIDTH
    - (free_cell_core::PLAY_AREA_COLUMN_COUNT as i32) * (CARD_SIZE.x + padding)
    - padding;
const play_area_start_y: i32 = 2 * padding + CARD_SIZE.y + 5 * padding;

const INIT_TIME_PER_MOVE_ANIM_MS: i32 = 250;
const MIN_TIME_PER_MOVE_ANIM_MS: i32 = 100;

pub struct DrawState {
    pub picked_up_card: Option<CardPos>,
    pub picked_up_card_pos: Option<Pt>,

	draw_card: CardDraw,
	fireworks_state: FireworksState,

	anim_state: Option<State>,
	moves_to_anim: Vec<(CardPos, CardPos)>,
	anim_progress_ms: i32,
	time_per_move_anim_ms: i32,
}

impl DrawState {
    pub fn new() -> Self {
        DrawState {
            picked_up_card: None,
            picked_up_card_pos: None,

			draw_card: CardDraw {
				size: CARD_SIZE_8_WIDE,
				colours: None,
			},

			fireworks_state: FireworksState::new(),

			anim_state: None,
			moves_to_anim: Vec::new(),
			time_per_move_anim_ms: INIT_TIME_PER_MOVE_ANIM_MS,
			anim_progress_ms: 0,
        }
    }

pub fn start_win_animation(&mut self, callbacks: &CCallbacksPtr) {
	// TODO only do this in a single place, and not if the timer is already running?
	let FPS = 60;
   	callbacks.update_timer_ms(1000 / FPS);

	self.fireworks_state.start_animation();
}

pub fn autocomplete_in_progress(&self) -> bool {
	self.moves_to_anim.len() > 0
}

pub fn update_anims(&mut self, callbacks: &'static CCallbacksPtr, dt_ms: i32) {
	let mut fireworks_complete = self.fireworks_state.update(dt_ms);
	if self.moves_to_anim.len() > 0 {
		self.anim_progress_ms += dt_ms;
		if self.anim_progress_ms > self.time_per_move_anim_ms {
			let (src, dst) = self.moves_to_anim.remove(0); // TODO replace with VecDeque
			self.time_per_move_anim_ms -= 10;
			if self.time_per_move_anim_ms < MIN_TIME_PER_MOVE_ANIM_MS {
				self.time_per_move_anim_ms = MIN_TIME_PER_MOVE_ANIM_MS;
			}
			let status = self.anim_state.as_mut().unwrap().apply_move(src, dst);
			assert!(status == free_cell_core::Status::Success);
			self.anim_progress_ms = 0;
			if self.moves_to_anim.len() == 0 {
				self.anim_state = None;
				self.start_win_animation(callbacks);
				fireworks_complete = false;
			}
		}
	}
	if self.moves_to_anim.len() == 0 && fireworks_complete {
		callbacks.update_timer_ms(0);
	}
}

pub fn draw_state(&mut self, callbacks: &'static CCallbacksPtr, mut state: &State) {
    let mut picked_up_cards: Vec<Card> = vec![];
	let mut picked_up_card_pos = self.picked_up_card_pos;
    let real_state = &state;
    let new_state = if self.anim_state.is_some() && self.moves_to_anim.len() > 0 {
		let new_state = self.anim_state.clone().unwrap(); // TODO?
		let (src, dst) = self.moves_to_anim.first().unwrap();
		let (new_state, cards) = new_state.remove_card(*src);
		picked_up_cards = cards;
		let diff = get_pos(dst).sub(get_pos(src));
		let anim_progress = (self.anim_progress_ms as f32) / (self.time_per_move_anim_ms as f32);
		picked_up_card_pos = Some(get_pos(src).add(Pt {
			y: ((diff.y as f32) * anim_progress) as i32,
			x: ((diff.x as f32) * anim_progress) as i32,
		}).add(Pt {
			y: CARD_SIZE.y/2,
			x: CARD_SIZE.x/2,
		}));
		Some(new_state)
	} else if let Some(picked_up_card) = self.picked_up_card {
        let (new_state, cards) = state.remove_card(picked_up_card);
        picked_up_cards = cards;
        Some(new_state)
    } else {
        None
    };
    let state = if new_state.is_some() {
        new_state.as_ref().unwrap()
    } else {
        state
    };

	let bg_colour;
	let mut card_space_text_colour = &"#0006";
	let mut card_space_text_colour_goal = &"#0004";
	let draw_card = &mut self.draw_card;
	if callbacks.get_user_colour_pref() == "dark" {
		bg_colour = BG_COLOUR_DARK;
		draw_card.colours = Some(&DEFAULT_CARD_COLOURS_DARK);
	} else {
		card_space_text_colour = &"#0003";
		card_space_text_colour_goal = &"#0002";
		bg_colour = BG_COLOUR_LIGHT;
		draw_card.colours = Some(&DEFAULT_CARD_COLOURS_LIGHT);
	}


    callbacks.draw_clear();
    callbacks.draw_rect(bg_colour, 0, 0, CANVAS_HEIGHT, CANVAS_WIDTH);
    //draw_card(callbacks, &card, &pt);

    for cell_idx in 0..free_cell_core::BOARD_CELL_COUNT {
		/*
        let pt = Pt {
            y: padding,
            x: padding + (cell_idx as i32) * (padding + CARD_SIZE.x),
        };
		*/
		let pt = get_pos(&CardPos::Cells(cell_idx));
        if let Some(card) = state.cells[cell_idx] {
            draw_card.draw_card(callbacks, &card, &pt, false);
        } else {
            draw_card.draw_card_space(callbacks, &pt);
			//draw_card.draw_card_space_text(callbacks, &pt, TEXT_CELL, card_space_text_colour, 16);
			let pt = draw_card.card_centre(&pt);
			let text_size = 12;
			let text_padding = 2;
			callbacks.draw_text("FREE", card_space_text_colour, pt.y - 0*(text_size + text_padding), pt.x, text_size, TextAlign::Middle);
			callbacks.draw_text("CELL", card_space_text_colour, pt.y + (text_size + text_padding), pt.x, text_size, TextAlign::Middle);
        }
    }

    for goal_idx in 0..free_cell_core::GOAL_COLUMN_COUNT {
		/*
        let pt = Pt {
            y: padding,
            x: CANVAS_WIDTH
                - (free_cell_core::GOAL_COLUMN_COUNT as i32 - goal_idx as i32)
                    * (padding + CARD_SIZE.x),
        };
		*/
		let pt = get_pos(&CardPos::Goals(goal_idx));
        if let Some(card) = state.goals[goal_idx].last() {
            draw_card.draw_card(callbacks, &card, &pt, false);
        } else {
            draw_card.draw_card_space(callbacks, &pt);
			// TODO maybe check for existing placed cards, and update these accordingly
			// or restrict suits, and auto place in right one
			let text = cards::num_to_suit(goal_idx as i32).to_unicode_symbol();
			draw_card.draw_card_space_text(callbacks, &pt, text, card_space_text_colour_goal, 32);
        }
    }

    for i in 0..free_cell_core::PLAY_AREA_COLUMN_COUNT {
        let start_pt = Pt {
            y: play_area_start_y,
            x: play_area_start_x + (i as i32) * (CARD_SIZE.x + padding),
        };
		if state.play_area[i].len() == 0 {
            draw_card.draw_card_space(callbacks, &start_pt);
		}
        for (card_idx, card) in state.play_area[i].iter().enumerate() {
            let pt = start_pt.add(Pt {
                y: PLAY_AREA_CARD_OFFSET_Y * card_idx as i32,
                x: 0,
            });
			let pt = get_pos(&CardPos::PlayArea(i, card_idx));
            draw_card.draw_card(callbacks, &card, &pt, false);
        }
        let playable_idx = real_state.play_area_cards_in_order_until(i) as i32;
        if playable_idx > 0 {
            let overlay_y_end = match self.picked_up_card {
                Some(CardPos::PlayArea(col_idx, _)) if col_idx == i => {
                    start_pt.y
                        + PLAY_AREA_CARD_OFFSET_Y * (state.play_area[i].len() - 1) as i32
                        + CARD_SIZE.y
                }
                _ => start_pt.y + PLAY_AREA_CARD_OFFSET_Y * playable_idx,
            };
            callbacks.draw_rect(
                &"#00000044",
                start_pt.y,
                start_pt.x,
                overlay_y_end,
                start_pt.x + CARD_SIZE.x,
            );
        }
    }

    if picked_up_cards.len() > 0 {
        let start_pos = picked_up_card_pos.as_ref().unwrap();
        let start_pos = start_pos.add(Pt {
            y: -CARD_SIZE.y / 2,
            x: -CARD_SIZE.x / 2,
        });
        for (card_idx, card) in picked_up_cards.iter().enumerate() {
            let card_idx = card_idx as i32;
            let pos = start_pos.add(Pt {
                y: card_idx * PLAY_AREA_CARD_OFFSET_Y,
                x: 0,
            });
            draw_card.draw_card(callbacks, &card, &pos, true);
        }
    }

	self.fireworks_state.draw(callbacks);

    callbacks.draw_refresh();
}

	pub fn anim_moves(&mut self, callbacks: &'static CCallbacksPtr, game_state: &State, moves_to_anim: &Vec<(CardPos, CardPos)>) {
		self.anim_state = Some(game_state.clone());
		self.moves_to_anim = moves_to_anim.clone();

		let FPS = 60;
        callbacks.update_timer_ms(1000 / FPS);
	}


	pub fn reset_state(&mut self) {
		self.time_per_move_anim_ms = INIT_TIME_PER_MOVE_ANIM_MS;
	}
}

fn get_pos(card_pos: &CardPos) -> Pt {
	match card_pos {
		CardPos::Cells(cell_idx) => {
			Pt {
            	y: padding,
            	x: padding + (*cell_idx as i32) * (padding + CARD_SIZE.x),
			}
		}
		CardPos::Goals(goal_idx) => {
        	Pt {
            	y: padding,
	            x: CANVAS_WIDTH
	                - (free_cell_core::GOAL_COLUMN_COUNT as i32 - *goal_idx as i32)
	                    * (padding + CARD_SIZE.x),
        	}
		}
		CardPos::PlayArea(col_idx, card_idx) => {
			Pt {
	            y: play_area_start_y
                 + PLAY_AREA_CARD_OFFSET_Y * *card_idx as i32,
	            x: play_area_start_x + (*col_idx as i32) * (CARD_SIZE.x + padding),
	        }
		}
	}
}

pub fn cursor_pos_to_card_pos(state: &State, pos: Pt) -> Option<CardPos> {
    if pos.y < padding + CARD_SIZE.y {
        if pos.x < free_cell_core::BOARD_CELL_COUNT as i32 * (padding + CARD_SIZE.x) {
            let idx = pos.x / (CARD_SIZE.x as i32 + padding);
            return Some(CardPos::Cells(idx as usize));
        } else if pos.x
            > CANVAS_WIDTH - free_cell_core::GOAL_COLUMN_COUNT as i32 * (padding + CARD_SIZE.x)
        {
            let idx = free_cell_core::GOAL_COLUMN_COUNT as i32
                - 1
                - (CANVAS_WIDTH as i32 - pos.x) / (CARD_SIZE.x + padding);
            return Some(CardPos::Goals(idx as usize));
        }
    } else if pos.y > play_area_start_y {
        let col_idx = (pos.x - play_area_start_x) / (CARD_SIZE.x + padding);
        let col_idx = col_idx as usize;
        let col_pos = (pos.y - play_area_start_y) / PLAY_AREA_CARD_OFFSET_Y;
        let mut col_pos = col_pos as usize;

        if col_idx >= state.play_area.len() {
            return None;
        }

        if state.play_area[col_idx].len() == 0 {
        } else if col_pos > state.play_area[col_idx].len() - 1 {
            col_pos = state.play_area[col_idx].len() - 1;
            let pos_y = pos.y - play_area_start_y - (col_pos as i32) * PLAY_AREA_CARD_OFFSET_Y;
            if pos_y > CARD_SIZE.y {
                return None;
            }
        }

        return Some(CardPos::PlayArea(col_idx, col_pos));
    }

    return None;
}
