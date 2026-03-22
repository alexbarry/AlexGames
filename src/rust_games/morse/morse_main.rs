

use crate::rust_game_api::{
    AlexGamesApi, CCallbacksPtr, MouseEvt, OptionInfo, OptionType, TextAlign, TouchInfo,
    CANVAS_HEIGHT, CANVAS_WIDTH, KeyEvt
};

use crate::morse::morse_draw::{self, Draw};
use crate::morse::morse_core::{self};

pub struct AlexGamesMorse {
	callbacks: &'static CCallbacksPtr,
	game_state: morse_core::State,
	draw: morse_draw::Draw,

	current_touch_id: Option<i64>,
}


impl AlexGamesApi for AlexGamesMorse {
    fn callbacks(&self) -> &CCallbacksPtr {
		self.callbacks
	}

    fn init(&mut self, callbacks: &'static CCallbacksPtr) {
		callbacks.enable_evt("mouse_updown");
		callbacks.enable_evt("key");
		callbacks.enable_evt("touch");
		callbacks.update_timer_ms(50);
	}

    fn start_game(&mut self, state: Option<(i32, Vec<u8>)>) {
	}

    fn handle_user_clicked(&mut self, pos_y: i32, pos_x: i32) {
	}

	fn handle_mouse_evt(&mut self, evt_id: MouseEvt, pos_y: i32, pos_x: i32, _buttons: i32) {
		println!("mouse_evt: {:?}", evt_id);
		match evt_id {
			MouseEvt::Down => {
				let time_ms = self.callbacks.get_time_ms();
				self.game_state.btn_down(time_ms);
			},
			MouseEvt::Up|MouseEvt::Leave => {
				let time_ms = self.callbacks.get_time_ms();
				self.game_state.btn_up(time_ms);
			},
			MouseEvt::AltDown|MouseEvt::AltUp|MouseEvt::Alt2Down|MouseEvt::Alt2Up => {
			},
		}
		self.draw.draw(&self.game_state);
	}

	fn handle_key_evt(&mut self, evt_id: KeyEvt, key_code: &str) -> bool {
		println!("key evt: {:#?} {:#?}", evt_id, key_code);
		if key_code == "Space" {
			match evt_id {
				KeyEvt::Down => {
					// ignore repeated key events
					if self.game_state.btn_is_down() {
						return true;
					}
					let time_ms = self.callbacks.get_time_ms();
					self.game_state.btn_down(time_ms);
				},
				KeyEvt::Up => {
					let time_ms = self.callbacks.get_time_ms();
					self.game_state.btn_up(time_ms);
				},
			}
			return true;
		} else {
			return false;
		}
	}

    fn handle_touch_evt(&mut self, evt_id: &str, touches: Vec<TouchInfo>) {
		for touch in touches.iter() {
			if self.current_touch_id.is_some_and(|current| current == touch.id) {
				match evt_id {
					"touchend" | "touchcancel" => {
						let time_ms = self.callbacks.get_time_ms();
						self.game_state.btn_up(time_ms);
						self.current_touch_id = None;
					},
					_ => {
						// ignore
					},
				}
			} else if self.current_touch_id.is_none() && evt_id == "touchstart" {
				self.current_touch_id = Some(touch.id);
				let time_ms = self.callbacks.get_time_ms();
				self.game_state.btn_down(time_ms);
			}
		}
	}

    fn update(&mut self, dt_ms: i32) {
		let time_ms = self.callbacks.get_time_ms();
		self.game_state.time_passed(time_ms);
		self.draw.draw(&self.game_state);
	}
}

pub fn init_morse(callbacks: &'static CCallbacksPtr) -> Box<dyn AlexGamesApi> {
	let mut game = AlexGamesMorse {
		callbacks,
		game_state: morse_core::State::new(),
		draw: morse_draw::Draw::new(callbacks),
		current_touch_id: None,

	};
	game.init(callbacks);

    Box::from(game)
}
