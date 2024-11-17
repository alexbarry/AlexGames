use std::collections::HashMap;

use crate::table_tennis::table_tennis_core::{State, Pt, Player, Side};
use crate::rust_game_api;
use crate::rust_game_api::{TimeMs, CANVAS_HEIGHT, CANVAS_WIDTH};

pub const FPS: i32 = 60;

pub struct TableTennisDraw {
    callbacks: &'static rust_game_api::CCallbacksPtr,
}

impl TableTennisDraw {
    pub fn new(callbacks: &'static rust_game_api::CCallbacksPtr) -> TableTennisDraw {
        let draw = TableTennisDraw {
            callbacks: callbacks,
        };

        draw
    }

	fn game_pt_to_draw_pt(game_pt: &Pt) -> Pt {
		Pt {
			y: game_pt.y * CANVAS_HEIGHT / 100,
			x: game_pt.x * CANVAS_WIDTH / 100,
		}
	}

    pub fn draw_state(&self, state: &State) {
		let callbacks = &self.callbacks;
        callbacks.draw_clear();

		let ball_pos = TableTennisDraw::game_pt_to_draw_pt(&state.ball);
		let ball_width  = 12;
		let ball_height = 12;
		let ball_colour = "#ff0000";

		callbacks.draw_rect(&ball_colour,
		                    ball_pos.y - ball_height/2,
		                    ball_pos.x - ball_width/2,
		                    ball_pos.y + ball_height/2,
		                    ball_pos.x + ball_width/2);

		let player_colour = ball_colour;
		let player_thickness = 12;
		let player1_pos1 = TableTennisDraw::game_pt_to_draw_pt(&state.get_player_pos(Player::PLAYER1, Side::TOP_LEFT));
		let player1_pos2 = TableTennisDraw::game_pt_to_draw_pt(&state.get_player_pos(Player::PLAYER1, Side::BOTTOM_RIGHT));
		let player2_pos1 = TableTennisDraw::game_pt_to_draw_pt(&state.get_player_pos(Player::PLAYER2, Side::TOP_LEFT));
		let player2_pos2 = TableTennisDraw::game_pt_to_draw_pt(&state.get_player_pos(Player::PLAYER2, Side::BOTTOM_RIGHT));

		callbacks.draw_rect(&player_colour,
		                    player1_pos1.y,
		                    player1_pos1.x,
		                    player1_pos2.y,
		                    player1_pos2.x);

		callbacks.draw_rect(&player_colour,
		                    player2_pos1.y,
		                    player2_pos1.x,
		                    player2_pos2.y,
		                    player2_pos2.x);

        callbacks.draw_refresh();
    }
}
