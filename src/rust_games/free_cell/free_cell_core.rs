pub use crate::libs::point::Pt;

pub use crate::libs::cards::Card;
use crate::libs::cards::{self};

pub const BOARD_CELL_COUNT: usize = 4;
pub const GOAL_COLUMN_COUNT: usize = cards::SUIT_COUNT;
pub const PLAY_AREA_COLUMN_COUNT: usize = 8;

#[derive(Copy, Clone, Debug, PartialEq)]
pub enum CardPos {
    Cells(usize),
    Goals(usize),
    PlayArea(usize, usize),
}

#[derive(Clone, Debug, PartialEq)]
pub struct State {
    pub cells: [Option<Card>; BOARD_CELL_COUNT],
    pub goals: [Vec<Card>; cards::SUIT_COUNT],
    pub play_area: [Vec<Card>; PLAY_AREA_COLUMN_COUNT],
}

#[derive(Copy, Clone, Debug, PartialEq)]
pub enum Status {
    Success,
    InvalidMove,
    CellOccupied,
    InvalidGoalMove,
    MoveConsumedNeededCell,
}

#[derive(Copy, Clone, Debug, PartialEq)]
pub enum PlayAreaPickupStatus {
    Success,
    NoCards,
    NotEnoughFreeCells,
    NotInOrder,
}

impl State {
    pub fn new() -> Self {
        State {
            cells: std::array::from_fn(|_| None),
            goals: std::array::from_fn(|_| Vec::new()),
            play_area: std::array::from_fn(|_| Vec::new()),
        }
    }

    pub fn new_game(&mut self) {
        let mut deck = cards::new_deck();
        cards::shuffle_deck(&mut deck);

        self.set_cards(&State::new());

        let mut col_idx = 0;
        while deck.len() > 0 {
            let card = deck.pop().unwrap();
            self.play_area[col_idx].push(card);
            col_idx = (col_idx + 1) % PLAY_AREA_COLUMN_COUNT;
        }
    }

    pub fn can_pickup_play_area(&self, col_idx: usize, col_pos: usize) -> PlayAreaPickupStatus {
        if self.play_area[col_idx].len() < col_pos {
            return PlayAreaPickupStatus::NoCards;
        }
        let cards = self.play_area[col_idx][col_pos..].to_vec();
        if cards.len() as i32 > self.free_cell_count() + 1 {
            return PlayAreaPickupStatus::NotEnoughFreeCells;
        } else if self.play_area_in_order_card_count(col_idx) < cards.len() {
            return PlayAreaPickupStatus::NotInOrder;
        } else if cards.len() == 0 {
            return PlayAreaPickupStatus::NoCards;
        } else {
            return PlayAreaPickupStatus::Success;
        }
    }

    pub fn remove_card(&self, pos: CardPos) -> (Self, Vec<Card>) {
        let mut new_state = self.clone();
        match pos {
            CardPos::Cells(idx) => {
                let card = new_state.cells[idx];
                if let Some(card) = card {
                    new_state.cells[idx] = None;
                    return (new_state, vec![card]);
                } else {
                    return (new_state, vec![]);
                }
            }
            CardPos::Goals(idx) => {
                let card = new_state.goals[idx].pop();
                if let Some(card) = card {
                    return (new_state, vec![card]);
                } else {
                    return (new_state, vec![]);
                }
            }
            CardPos::PlayArea(col_idx, col_pos) => {
                if self.can_pickup_play_area(col_idx, col_pos) != PlayAreaPickupStatus::Success {
                    return (new_state, vec![]);
                }
                let cards = new_state.play_area[col_idx][col_pos..].to_vec();
                new_state.play_area[col_idx] = new_state.play_area[col_idx][..col_pos].to_vec();
                return (new_state, cards);
            }
        }
    }

    pub fn can_pickup(&self, pos: CardPos) -> bool {
        let (_, cards) = self.remove_card(pos);
        cards.len() > 0
    }

    fn set_cards(&mut self, new_state: &State) {
        self.cells = new_state.cells.clone();
        self.goals = new_state.goals.clone();
        self.play_area = new_state.play_area.clone();
    }

    pub fn free_cell_count(&self) -> i32 {
        let mut free_cells = 0;
        for cell in self.cells.iter() {
            if cell.is_none() {
                free_cells += 1;
            }
        }
        for play_col in self.play_area.iter() {
            if play_col.len() == 0 {
                free_cells += 1;
            }
        }
        return free_cells;
    }

    pub fn play_area_cards_in_order_until(&self, col_idx: usize) -> usize {
        let col = &self.play_area[col_idx];
        for col_pos in (1..col.len()).rev() {
            let card1 = col[col_pos];
            let card2 = col[col_pos - 1];
            if !cards::can_place_on_play_area(&card1, &card2) {
                return col_pos;
            }
        }
        return 0;
    }

    pub fn play_area_in_order_card_count(&self, col_idx: usize) -> usize {
        self.play_area[col_idx].len() - self.play_area_cards_in_order_until(col_idx)
    }

    pub fn apply_move(&mut self, src: CardPos, dst: CardPos) -> Status {
        match dst {
            CardPos::Cells(cell_idx) => {
                let (mut new_state, cards) = self.remove_card(src);
                if cards.len() == 1 && new_state.cells[cell_idx].is_none() {
                    let card = cards[0];
                    new_state.cells[cell_idx] = Some(card);
                    self.set_cards(&new_state);
                    return Status::Success;
                } else {
                    return Status::CellOccupied;
                }
            }
            CardPos::Goals(goal_idx) => {
                let (mut new_state, cards) = self.remove_card(src);
                let card = if cards.len() == 1 {
                    cards[0]
                } else {
                    return Status::InvalidGoalMove;
                };
                let goal_stack = &new_state.goals[goal_idx];
                if cards::can_place_on_goal(card, &goal_stack) {
                    new_state.goals[goal_idx].push(card);
                    self.set_cards(&new_state);
                    return Status::Success;
                } else {
                    return Status::InvalidGoalMove;
                }
            }
            CardPos::PlayArea(dst_col_idx, _) => {
                let (mut new_state, mut cards) = self.remove_card(src);
                if let CardPos::PlayArea(src_col_idx, _) = src {
                    if src_col_idx == dst_col_idx {
                        return Status::InvalidMove;
                    }
                }
                let free_cell_count = new_state.free_cell_count();
                let dst_col = &mut new_state.play_area[dst_col_idx];

                if !dst_col
                    .last()
                    .is_none_or(|dst_card| cards::can_place_on_play_area(&cards[0], &dst_card))
                {
                    return Status::InvalidMove;
                }

                if dst_col.last().is_none() && free_cell_count == cards.len() as i32 - 1 {
                    return Status::MoveConsumedNeededCell;
                }

                dst_col.append(&mut cards);
                self.set_cards(&new_state);
                return Status::Success;
            }
        }
    }

	fn get_auto_move_dst(&self, src: CardPos) -> Option<CardPos> {
		let (_, mut cards) = self.remove_card(src);
		let card = if cards.len() == 1 {
			cards[0]
		} else {
			return None;
		};

		for (goal_idx, goal_stack) in self.goals.iter().enumerate() {
			if cards::can_place_on_goal(card, &goal_stack) {
				return Some(CardPos::Goals(goal_idx));
			}
		}
		return None;
	}

	pub fn auto_move(&mut self, src: CardPos) -> Status {
		if let Some(dst) = self.get_auto_move_dst(src) {
			return self.apply_move(src, dst);
		} else {
			return Status::InvalidMove;
		}
	}

	pub fn can_autocomplete(&self) -> bool {
        for (col_idx, play_col) in self.play_area.iter().enumerate() {
        	if self.play_area_cards_in_order_until(col_idx) != 0 {
				return false;
			}
		}
        if self.play_area.iter().all(|col| col.len() == 0) {
			return false;
		}
		return true;
	}

	pub fn get_autocomplete_moves(&self) -> Vec<(CardPos, CardPos)> {
		let mut test_state = self.clone();
		let mut moves: Vec<(CardPos, CardPos)> = Vec::new();

		let mut activity = true;
		while activity {
			activity = false;
			for cell_idx in 0..test_state.cells.len() {
				let src = CardPos::Cells(cell_idx);
				let card = if let Some(card) = self.cells[cell_idx] {
					card
				} else {
					continue;
				};
				for goal_idx in 0..test_state.goals.len() {
					let goal_stack = &test_state.goals[goal_idx];
					if cards::can_place_on_goal(card, &goal_stack) {
						let dst = CardPos::Goals(goal_idx);
						let status = test_state.apply_move(src, dst);
						assert!(status == Status::Success);
						moves.push((src, dst));
						activity = true;
						break;
					}
				};
			}
			for col_idx in 0..test_state.play_area.len() {
				let col = &test_state.play_area[col_idx];
				if col.len() == 0 { continue; }
				let src = CardPos::PlayArea(col_idx, test_state.play_area[col_idx].len()-1);
				let card = col.last().unwrap();
				for (goal_idx, goal_stack) in test_state.goals.iter().enumerate() {
					if cards::can_place_on_goal(*card, &goal_stack) {
						let dst = CardPos::Goals(goal_idx);
						let status = test_state.apply_move(src, dst);
						assert!(status == Status::Success);
						moves.push((src, dst));
						activity = true;
						break;
					}
				}
			}
		}

		return moves;
	}

	pub fn game_won(&self) -> bool {
		for goal_stack in self.goals.iter() {
			if goal_stack.len() != 13 {
				return false;
			}
		}
		return true;
	}
}
