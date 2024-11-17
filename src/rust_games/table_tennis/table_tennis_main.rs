// Author: Alex Barry (github.com/alexbarry)
// Game: "Table Tennis"
//

use std::collections::HashMap;

use crate::rust_game_api;
use crate::rust_game_api::{AlexGamesApi, CCallbacksPtr, MouseEvt};

use crate::table_tennis::table_tennis_draw::{TableTennisDraw, FPS};
use crate::table_tennis::table_tennis_core::{State, Pt, Player};

pub struct AlexGamesTableTennis {
    state: State,
    session_id: Option<i32>,
    draw: TableTennisDraw,

    callbacks: &'static rust_game_api::CCallbacksPtr,

    current_touch_id: Option<i64>,
	keys_down: HashMap<String, bool>,
}

impl AlexGamesTableTennis {

    fn save_state(&self) {
    }
}

impl AlexGamesApi for AlexGamesTableTennis {
    fn callbacks(&self) -> &CCallbacksPtr {
        self.callbacks
    }

    fn update(&mut self, dt_ms: i32) {


		let player = Player::PLAYER1;
		if *self.keys_down.get("ArrowLeft").unwrap_or(&false) ||
		   *self.keys_down.get("KeyH").unwrap_or(&false) {
			self.state.move_player(&player, -1, dt_ms);
		}
		if *self.keys_down.get("ArrowRight").unwrap_or(&false) ||
		   *self.keys_down.get("KeyL").unwrap_or(&false) {
			self.state.move_player(&player, 1, dt_ms);
		}

		let player = Player::PLAYER2;
		if *self.keys_down.get("KeyA").unwrap_or(&false) {
			self.state.move_player(&player, -1, dt_ms);
		}
		if *self.keys_down.get("KeyD").unwrap_or(&false) {
			self.state.move_player(&player, 1, dt_ms);
		}


		self.state.update(dt_ms);
        self.draw.draw_state(&self.state);
    }

    fn handle_user_clicked(&mut self, _pos_y: i32, _pos_x: i32) {}

    fn handle_mousemove(&mut self, pos_y: i32, pos_x: i32, _buttons: i32) {
    }

    fn handle_mouse_evt(&mut self, evt_id: MouseEvt, pos_y: i32, pos_x: i32, _buttons: i32) {
    }

    fn handle_touch_evt(&mut self, evt_id: &str, touches: Vec<rust_game_api::TouchInfo>) {
    }

	fn handle_key_evt(&mut self, key_evt: &str, key_code: &str) -> bool {
		if let Some(rc) = match key_code {
			"ArrowLeft"|"ArrowRight"
			|"KeyH"|"KeyL"
			|"KeyA"|"KeyD" => None,
			_ => Some(false),
		} {
			return rc;
		};

		self.keys_down.insert(key_code.to_string(), match key_evt {
			"keydown" => true,
			"keyup" => false,
			_ => panic!("unhandled key_event"),
		});
		
		true

	}

    fn start_game(&mut self, session_id_and_state: Option<(i32, Vec<u8>)>) {
    }

    fn get_state(&self) -> Option<Vec<u8>> {
		None
    }

    fn init(&mut self, callbacks: &rust_game_api::CCallbacksPtr) {
        callbacks.enable_evt("mouse_move");
        callbacks.enable_evt("mouse_updown");
        callbacks.enable_evt("touch");
        callbacks.enable_evt("key");
        callbacks.update_timer_ms(1000 / FPS);
    }
}

pub fn init_table_tennis(
    callbacks: &'static rust_game_api::CCallbacksPtr,
) -> Box<dyn AlexGamesApi + '_> {
    let mut api = AlexGamesTableTennis {
        state: State::new(Pt{ y: 100, x: 100 }),
        callbacks: callbacks,
        session_id: None,

        draw: TableTennisDraw::new(callbacks),

        current_touch_id: None,
		keys_down: HashMap::new(),
    };

    api.init(callbacks);
    Box::from(api)
}
