use crate::rust_game_api::{AlexGamesApi, CANVAS_HEIGHT, CANVAS_WIDTH, CCallbacksPtr, MouseEvt};
use crate::rust_game_api;

use crate::libs::swipe_tracker;
use crate::libs::swipe_tracker::{CursorEvt, SwipeEvt, CursorEvtType};

use crate::gem_match::gem_match_core::{State, GemType, BOARD_WIDTH, BOARD_HEIGHT, Pt, GemsInARow};
use crate::gem_match::gem_match_draw::{GemMatchDraw, cell_size, FPS};

pub struct AlexGamesGemMatch {
	state: State,
	draw: GemMatchDraw,

	callbacks: &'static rust_game_api::CCallbacksPtr,

	swipe_tracker: swipe_tracker::SwipeTracker,
}

impl AlexGamesGemMatch {
	fn handle_swipe(&mut self, evt: SwipeEvt) {
		let cell_pos = self.draw.screen_pos_to_cell_pos(evt.pos);
		let move_result = self.state.move_gems(cell_pos, evt.dir);
		println!("handle_swipe, result={:#?}", move_result);
		if let Ok(_) = move_result {
			println!("[move] swap");
			self.draw.handle_swipe_swap_animation(evt.pos, evt.dir);
			//self.draw.handle_swipe_bad_move(evt.pos, evt.dir);
		} else {
			println!("[move] bad_move");
			self.draw.handle_swipe_bad_move(evt.pos, evt.dir);
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
		//println!("update called");
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
	};

	api.init(callbacks);
	Box::from(api)
}
