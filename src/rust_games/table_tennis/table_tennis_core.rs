// Author: Alex Barry (github.com/alexbarry)
// Game: "Table Tennis"

pub use crate::libs::point::{Pt, Ptf};

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

	pub ball: Ptf,
	ball_velocity: Ptf,

	ball_speed_growth_fact: f64,

	pub game_board_size: Ptf,
	pub dir_to_start_ball: i32,
}

const init_ball_vel_y: f64 = 35.0;
const init_ball_vel_x: f64 = 10.0;

impl State {
	pub fn new(board_size: Pt) -> State {
		let board_size = Ptf { y: board_size.y as f64, x: board_size.x as f64 };
		State {
			player1_pos: 50.0,
			player2_pos: 50.0,

			player1_size: 12,
			player2_size: 12,

			ball: Ptf { y: board_size.y/2.0, x: board_size.x/2.0 },
			ball_velocity: Ptf { y: init_ball_vel_y, x: init_ball_vel_x },
			game_board_size: Ptf {y: board_size.y, x: board_size.x},

			player_thickness: 2,

			ball_speed_growth_fact: 4.0,
			dir_to_start_ball: 1,

			// in game units per second
			player1_speed: 80,
			player2_speed: 80,
		}
	}

	pub fn get_player_pos(&self, player: &Player, side: &Side) -> Pt {
		Pt {
			y: (match player {
				Player::PLAYER1 => self.game_board_size.y - self.player_thickness as f64,
				Player::PLAYER2 => 0.0,
			} + match side {
				Side::TOP_LEFT =>  0.0,
				Side::BOTTOM_RIGHT => self.player_thickness as f64,
			}) as i32,
			x: (match player {
				Player::PLAYER1 => self.player1_pos as i32,
				Player::PLAYER2 => self.player2_pos as i32,
			} + match side {
				Side::TOP_LEFT =>  -1,
				Side::BOTTOM_RIGHT => 1,
			} * match player {
				Player::PLAYER1 => self.player1_size,
				Player::PLAYER2 => self.player2_size,
			}) as i32,
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

	fn reset_ball_pos(&mut self) {
		// TODO toggle which direction it goes in
		self.ball_velocity = Ptf {
			y: init_ball_vel_y * self.dir_to_start_ball as f64,
			x: init_ball_vel_x,
		};
		self.ball = Ptf {
			y: self.game_board_size.y/2.0,
			x: self.game_board_size.x/2.0,
		};
		self.dir_to_start_ball *= -1;
	}

	fn within_player(&self, player: &Player, pos_x: f64) -> bool {
		let l = self.get_player_pos(player, &Side::TOP_LEFT).x as f64;
		let r = self.get_player_pos(player, &Side::BOTTOM_RIGHT).x as f64;

		return l <= pos_x && pos_x <= r;
	}

	fn mirror_ball_vec(&mut self, dir: f64, dist_to_centre_portion: f64) {
		let dist_to_centre_portion = dist_to_centre_portion.abs();
		//let dist_to_centre_portion = 1.0 - dist_to_centre_portion;
		self.ball_velocity.y *= -1.0;
		let old_speed = self.ball_velocity.x;
		let change = self.ball_speed_growth_fact * dist_to_centre_portion;
		self.ball_velocity.x *= change;
		println!("prev speed was {:e}, change is {}, new speed is {:e}", old_speed, change, self.ball_velocity.x);
	}

	pub fn update(&mut self, dt_ms: i32) {
		let dt_ms = dt_ms as f64;
		self.ball = self.ball.add(self.ball_velocity.mult(dt_ms/1000.0));

		let top_bound = self.player_thickness as f64;
		let bottom_bound = self.game_board_size.y - self.player_thickness as f64;
		if self.ball.y < top_bound {
			if self.within_player(&Player::PLAYER2, self.ball.x) {
				println!("ping");
				//self.ball_velocity.y *= -1.0;
				let dist_to_centre_position = (self.ball.x - self.player2_pos)/self.player2_size as f64;
				self.mirror_ball_vec(1.0, dist_to_centre_position);
				self.ball.y = top_bound;
			} else {
				println!("point for player1");
				// TODO point for a player
				self.reset_ball_pos()
			}
		} else if self.ball.y > bottom_bound {
			if self.within_player(&Player::PLAYER1, self.ball.x) {
				println!("pong");
				//self.ball_velocity.y *= -1.0;
				let dist_to_centre_position = (self.ball.x - self.player1_pos)/self.player1_size as f64;
				self.mirror_ball_vec(-1.0, dist_to_centre_position);
				self.ball.y = bottom_bound;
			} else {
				println!("point for player2");
				// TODO point for a player
				self.reset_ball_pos()
			}
		}

		if self.ball.x < 0.0 {
			self.ball.x = 0.0;
			self.ball_velocity.x *= -1.0;
		} else if self.ball.x > self.game_board_size.x {
			self.ball.x = self.game_board_size.x;
			self.ball_velocity.x *= -1.0;
		}
	}
}

