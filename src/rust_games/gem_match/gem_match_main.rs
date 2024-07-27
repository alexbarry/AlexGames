// Author: Alex Barry (github.com/alexbarry)
// Game: "Gem Match"
//
// TODO:
// * disable input while animating
// * make shapes look like gems, not circles
//
// * implement saved state /share/undo/redo
//
// * refactor the touch to cursor event thing into a common library,
// * maybe make the "touch to cursor event" thing default behaviour, so
//   games that support mouse events will also get free touch handling.
// * change touch event IDs from strings to an enum
// * remove unsafe in all games, pass reference to callbacks instead of pointer
// * maybe use macro to generate callback wrappers
// * add default implementation to all callbacks
//
// * fix animations coming out of order, I think I need to make the end times
//   equal, rather than the start times.
//
// * maybe, in addition to fading out, make gems move from their original position to the new piece that was moved to make the match, or just have them go towards the centre
//
//
// 

use crate::rust_game_api::{AlexGamesApi, CCallbacksPtr, MouseEvt};
use crate::rust_game_api;

use crate::libs::swipe_tracker;
use crate::libs::swipe_tracker::{CursorEvt, SwipeEvt, CursorEvtType};

use crate::gem_match::gem_match_core::{State, Pt};
use crate::gem_match::gem_match_draw::{GemMatchDraw, cell_size, FPS};

pub struct AlexGamesGemMatch {
	state: State,
	draw: GemMatchDraw,

	callbacks: &'static rust_game_api::CCallbacksPtr,

	swipe_tracker: swipe_tracker::SwipeTracker,

	current_touch_id: Option<i64>,
}

impl AlexGamesGemMatch {
	fn handle_swipe(&mut self, evt: SwipeEvt) {
		let prev_state = self.state;
		let cell_pos = self.draw.screen_pos_to_cell_pos(evt.pos);
		let move_result = self.state.move_gems(cell_pos, evt.dir);
		prev_state._print_board();
		println!("handle_swipe, result={:#?}", move_result);
		if let Ok(move_result) = move_result {
			self.draw.handle_move_updates(&move_result, &prev_state, &self.state);
			//self.draw.handle_swipe_bad_move(evt.pos, evt.dir);
		} else {
			self.draw.handle_swipe_bad_move(evt.pos, evt.dir, &self.state);
		}

		let matches = self.state.find_all_three_or_more_in_a_row();
		for match_val in matches {
			println!("match: {:?}", match_val);
		}
	}
}



impl AlexGamesApi for AlexGamesGemMatch {
	fn callbacks(&self) -> *const CCallbacksPtr {
		self.callbacks
	}

	fn update(&mut self, dt_ms: i32) {
		self.draw.update_animations(dt_ms);
		self.draw.draw_state(&self.state);
	}

	fn handle_user_clicked(&mut self, _pos_y: i32, _pos_x: i32) {
		// TODO REMOVE
		let matches = self.state.find_all_three_or_more_in_a_row();
		for match_val in matches {
			println!("match: {:?}", match_val);
		}
	}

	fn handle_mousemove(&mut self, pos_y: i32, pos_x: i32, _buttons: i32) {
		let swipe_evt = self.swipe_tracker.handle_cursor_evt(CursorEvt{
			evt_type: CursorEvtType::Move,
			pos: Pt{y: pos_y, x: pos_x},
		});
		if let Some(swipe_evt) = swipe_evt {
			self.handle_swipe(swipe_evt);
			self.draw.draw_state(&self.state);
		}
	}
	

	fn handle_mouse_evt(&mut self, evt_id: MouseEvt, pos_y: i32, pos_x: i32, _buttons: i32) {
		let cursor_evt_type = match evt_id {
			MouseEvt::Down  => Some(CursorEvtType::Down),
			MouseEvt::Up    => Some(CursorEvtType::Up),
			MouseEvt::Leave => Some(CursorEvtType::Cancel),
			_ => None,
		};
		if let Some(cursor_evt_type) = cursor_evt_type {
			let swipe_evt = self.swipe_tracker.handle_cursor_evt(CursorEvt{
				evt_type: cursor_evt_type,
				pos: Pt{y: pos_y, x: pos_x},
			});
			if let Some(swipe_evt) = swipe_evt {
				self.handle_swipe(swipe_evt);
			}
		}
	}

	fn handle_touch_evt(&mut self, evt_id: &str, touches: Vec<rust_game_api::TouchInfo>) {
		let cursor_evt_type = match evt_id {
			"touchstart"   => CursorEvtType::Down,
			"touchend"     => CursorEvtType::Up,
			"touchmove"    => CursorEvtType::Move,
			"touchcancel"  => CursorEvtType::Cancel,
			_ => { panic!("unhandled touch evt {}", evt_id); },
		};

		let cursor_evt = (|| {
			for touch in touches.iter() {
				if let Some(current_touch_id) = self.current_touch_id {
					if touch.id == current_touch_id {
						if evt_id == "touchend" {
							self.current_touch_id = None;
						}
						return Some(CursorEvt{
							evt_type: cursor_evt_type,
							pos: Pt{y: touch.y as i32, x: touch.x as i32},
						});
					}
				} else if evt_id == "touchstart" {
					self.current_touch_id = Some(touch.id);
					return Some(CursorEvt{
						evt_type: cursor_evt_type,
						pos: Pt{y: touch.y as i32, x: touch.x as i32},
					});
				}
			}
			return None;
		})();

		if let Some(cursor_evt) = cursor_evt {
			println!("cursor: {:?}", cursor_evt);
			let swipe_evt = self.swipe_tracker.handle_cursor_evt(cursor_evt);
			if let Some(swipe_evt) = swipe_evt {
				self.handle_swipe(swipe_evt);
			}
		}




	}

	fn handle_btn_clicked(&mut self, _btn_id: &str) {
	}
	
	fn start_game(&mut self, _session_id_and_state: Option<(i32, Vec<u8>)>) {
	}
	
	fn get_state(&self) -> Option<Vec<u8>> {
		None
	}



	fn init(&mut self, callbacks: *const rust_game_api::CCallbacksPtr) {
		self.state = State::new(); 
		let callbacks = unsafe { callbacks.as_ref().expect("callbacks null?") };
		callbacks.enable_evt("mouse_move");
		callbacks.enable_evt("mouse_updown");
		callbacks.enable_evt("touch");
		callbacks.update_timer_ms(1000/FPS);
	}
}

pub fn init_gem_match(callbacks: *const rust_game_api::CCallbacksPtr) -> Box<dyn AlexGamesApi> {
	let callbacks = unsafe { callbacks.as_ref().expect("callbacks null?") };
	let mut api = AlexGamesGemMatch {
		state: State::new(),
		callbacks: callbacks,

		draw: GemMatchDraw::new(callbacks),
	
		swipe_tracker: swipe_tracker::SwipeTracker::new(cell_size() as i32 / 3),

		current_touch_id: None,
	};

	api.init(callbacks);
	Box::from(api)
}
