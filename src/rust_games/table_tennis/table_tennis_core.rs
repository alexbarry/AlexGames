// Author: Alex Barry (github.com/alexbarry)
// Game: "Table Tennis"

pub use crate::libs::point::Pt;

#[derive(Clone)]
pub enum Player {
	PLAYER1,
	PLAYER2,
}

#[derive(Clone)]
pub enum Side {
	TOP_LEFT,
	BOTTOM_RIGHT,
}

pub struct State {
	// bottom player, always human
	player1_pos: f64,

	// top player, can be AI?
	player2_pos: f64,

	player1_size: i32,
	player2_size: i32,
	player1_speed: i32,
	player2_speed: i32,

	pub player_thickness: i32,

	pub ball: Pt,

	pub game_board_size: Pt,
}

impl State {
	pub fn new(board_size: Pt) -> State {
		State {
			player1_pos: 50.0,
			player2_pos: 50.0,

			player1_size: 12,
			player2_size: 12,

			ball: Pt { y: 50, x: 50 },
			game_board_size: Pt {y: board_size.y, x: board_size.x},

			player_thickness: 2,

			// in game units per second
			player1_speed: 40,
			player2_speed: 40,
		}
	}

	pub fn get_player_pos(&self, player: &Player, side: &Side) -> Pt {
		Pt {
			y: match player {
				Player::PLAYER1 => self.game_board_size.y - self.player_thickness,
				Player::PLAYER2 => 0,
			} + match side {
				Side::TOP_LEFT =>  0,
				Side::BOTTOM_RIGHT => self.player_thickness,
			},
			x: match player {
				Player::PLAYER1 => self.player1_pos as i32,
				Player::PLAYER2 => self.player2_pos as i32,
			} + match side {
				Side::TOP_LEFT =>  -1,
				Side::BOTTOM_RIGHT => 1,
			} * match player {
				Player::PLAYER1 => self.player1_size,
				Player::PLAYER2 => self.player2_size,
			},
		}
	}

	pub fn move_player(&mut self, player: &Player, dir: i32, dt_ms: i32) {
		let dir = dir as f64;
		let player_speed = match player {
			Player::PLAYER1 => self.player1_speed,
			Player::PLAYER2 => self.player2_speed,
		} as f64;
		let dt_ms = dt_ms as f64;

		let player_pos = match player {
			Player::PLAYER1 => &mut self.player1_pos,
			Player::PLAYER2 => &mut self.player2_pos,
		};

		*player_pos += dir * player_speed * dt_ms / 1000.0;
		*player_pos = player_pos.clamp(0.0, 100.0);
	}
}

