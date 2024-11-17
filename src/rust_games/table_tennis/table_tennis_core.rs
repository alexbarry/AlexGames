// Author: Alex Barry (github.com/alexbarry)
// Game: "Table Tennis"

pub use crate::libs::point::Pt;

pub enum Player {
	PLAYER1,
	PLAYER2,
}

pub enum Side {
	TOP_LEFT,
	BOTTOM_RIGHT,
}

pub struct State {
	// bottom player, always human
	pub player1_pos: i32,

	// top player, can be AI?
	pub player2_pos: i32,

	pub player1_size: i32,
	pub player2_size: i32,

	pub player_thickness: i32,

	pub ball: Pt,

	pub game_board_size: Pt,
}

impl State {
	pub fn new(board_size: Pt) -> State {
		State {
			player1_pos: 50,
			player2_pos: 50,

			player1_size: 12,
			player2_size: 12,

			ball: Pt { y: 50, x: 50 },
			game_board_size: Pt {y: board_size.y, x: board_size.x},

			player_thickness: 2,
		}
	}

	pub fn get_player_pos(&self, player: Player, side: Side) -> Pt {
		Pt {
			y: match player {
				Player::PLAYER1 => 0,
				Player::PLAYER2 => self.game_board_size.y - self.player_thickness,
			} + match side {
				Side::TOP_LEFT =>  0,
				Side::BOTTOM_RIGHT => self.player_thickness,
			},
			x: match player {
				Player::PLAYER1 => self.player1_pos,
				Player::PLAYER2 => self.player2_pos,
			} + match side {
				Side::TOP_LEFT =>  -1,
				Side::BOTTOM_RIGHT => 1,
			} * match player {
				Player::PLAYER1 => self.player1_size,
				Player::PLAYER2 => self.player2_size,
			},
		}
	}
}

