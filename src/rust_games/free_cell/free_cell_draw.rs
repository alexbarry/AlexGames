use crate::free_cell::free_cell_core::{self, CardPos, State};
use crate::libs::cards::{self, draw_card, Card, Rank, Suit, CARD_SIZE};

use crate::rust_game_api::{
    AlexGamesApi, CCallbacksPtr, OptionInfo, OptionType, TextAlign, CANVAS_HEIGHT, CANVAS_WIDTH,
};

pub use crate::libs::point::Pt;

const padding: i32 = 3;

const BG_COLOUR: &str = "#008800";
const PLAY_AREA_CARD_OFFSET_Y: i32 = 18;

const play_area_start_x: i32 = CANVAS_WIDTH
    - (free_cell_core::PLAY_AREA_COLUMN_COUNT as i32) * (CARD_SIZE.x + padding)
    - padding;
const play_area_start_y: i32 = 2 * padding + CARD_SIZE.y + 5 * padding;

pub struct DrawState {
    pub picked_up_card: Option<CardPos>,
    pub picked_up_card_pos: Option<Pt>,
}

impl DrawState {
    pub fn new() -> Self {
        DrawState {
            picked_up_card: None,
            picked_up_card_pos: None,
        }
    }
}

pub fn draw_state(callbacks: &'static CCallbacksPtr, mut state: &State, draw_state: &DrawState) {
    let mut picked_up_cards: Vec<Card> = vec![];
    let real_state = &state;
    let new_state = if let Some(picked_up_card) = draw_state.picked_up_card {
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
    callbacks.draw_clear();
    callbacks.draw_rect(BG_COLOUR, 0, 0, CANVAS_HEIGHT, CANVAS_WIDTH);
    //draw_card(callbacks, &card, &pt);

    for cell_idx in 0..free_cell_core::BOARD_CELL_COUNT {
        let pt = Pt {
            y: padding,
            x: padding + (cell_idx as i32) * (padding + CARD_SIZE.x),
        };
        if let Some(card) = state.cells[cell_idx] {
            cards::draw_card(callbacks, &card, &pt, false);
        } else {
            cards::draw_card_space(callbacks, &pt);
        }
    }

    for goal_idx in 0..free_cell_core::GOAL_COLUMN_COUNT {
        let pt = Pt {
            y: padding,
            x: CANVAS_WIDTH
                - (free_cell_core::GOAL_COLUMN_COUNT as i32 - goal_idx as i32)
                    * (padding + CARD_SIZE.x),
        };
        if let Some(card) = state.goals[goal_idx].last() {
            cards::draw_card(callbacks, &card, &pt, false);
        } else {
            cards::draw_card_space(callbacks, &pt);
        }
    }

    for i in 0..free_cell_core::PLAY_AREA_COLUMN_COUNT {
        let start_pt = Pt {
            y: play_area_start_y,
            x: play_area_start_x + (i as i32) * (CARD_SIZE.x + padding),
        };
        for (card_idx, card) in state.play_area[i].iter().enumerate() {
            let pt = start_pt.add(Pt {
                y: PLAY_AREA_CARD_OFFSET_Y * card_idx as i32,
                x: 0,
            });
            cards::draw_card(callbacks, &card, &pt, false);
        }
        let playable_idx = real_state.play_area_cards_in_order_until(i) as i32;
        if playable_idx > 0 {
            let overlay_y_end = match draw_state.picked_up_card {
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
        let start_pos = draw_state.picked_up_card_pos.as_ref().unwrap();
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
            cards::draw_card(callbacks, &card, &pos, true);
        }
    }

    callbacks.draw_refresh();
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
