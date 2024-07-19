use crate::gem_match::gem_match_core::{State, GemType, BOARD_WIDTH, BOARD_HEIGHT, Pt};

use crate::rust_game_api::{AlexGamesApi, CANVAS_HEIGHT, CANVAS_WIDTH, CCallbacksPtr, MouseEvt};
use crate::rust_game_api;

use crate::libs::swipe_tracker;
use crate::libs::swipe_tracker::{CursorEvt, SwipeEvt, CursorEvtType};

pub struct AlexGamesGemMatch {
	state: State,
	callbacks: &'static rust_game_api::CCallbacksPtr,

	swipe_tracker: swipe_tracker::SwipeTracker,
	mouse_down: bool,
}

struct GemAnimation {
	src_cell: Pt,
	dst_cell: Pt,
	progress: f64,
	total_time_ms: i32,
}


const FPS: i32 = 60;


const cell_width:  f64 = (CANVAS_WIDTH as f64) / (BOARD_WIDTH as f64);
const cell_height: f64 = (CANVAS_HEIGHT as f64) / (BOARD_HEIGHT as f64);

fn cell_size() -> f64 {
	f64::min(cell_width, cell_height)
}

impl AlexGamesGemMatch {

fn draw_state(&self) {
	let padding = 1.0;
	let piece_radius = (cell_size()/2.0 - padding) as i32;
	let piece_outline_width = 2;
	for (y, row) in self.state.board.iter().enumerate() {
		for (x, cell) in row.iter().enumerate() {
			if let Some(cell) = cell {
				let (colour, outline_colour) = match cell.gem_type {
					GemType::SAPPHIRE => ("#0f52ba", "#000088" ),
					//GemType::EMERALD  => ("#50c878", "#008800" ),
					GemType::EMERALD  => ("#30c858", "#008800" ),
					GemType::RUBY     => ("#9b111e", "#440000" ),
					GemType::AMETHYST => ("#9966cc", "#440044" ),
					GemType::TOPAZ    => ("#ffd700", "#888866" ),
					GemType::AMBER    => ("#ff8800", "#442200" ),
				};
				let y = y as f64;
				let x = x as f64;

				let circ_y = (y+0.5)*cell_height;
				let circ_x = (x+0.5)*cell_width;

				self.callbacks.draw_circle(colour, outline_colour,
				                           circ_y as i32, circ_x as i32,
				                           piece_radius, piece_outline_width);
			}
		}
	}
	
}

fn handle_swipe(&self, evt: SwipeEvt) {
	println!("handle_swipe: {:#?}", evt);
}



}


impl AlexGamesApi for AlexGamesGemMatch {
	fn callbacks(&self) -> *const CCallbacksPtr {
		self.callbacks
	}

	fn update(&mut self, _dt_ms: i32) {
		self.draw_state();
	}

	fn handle_user_clicked(&mut self, _pos_y: i32, _pos_x: i32) {
	}

	fn handle_mousemove(&mut self, pos_y: i32, pos_x: i32, _buttons: i32) {
		let swipe_evt = self.swipe_tracker.handle_cursor_evt(CursorEvt{
			evt_type: CursorEvtType::Move,
			pos: Pt{y: pos_y, x: pos_x},
		});
		if let Some(swipe_evt) = swipe_evt {
			self.handle_swipe(swipe_evt);
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
	}
}

pub fn init_gem_match(callbacks: *const rust_game_api::CCallbacksPtr) -> Box<dyn AlexGamesApi> {
	let mut api = AlexGamesGemMatch {
		state: State::new(),
		callbacks: unsafe { callbacks.as_ref().expect("callbacks null?") },
	
		swipe_tracker: swipe_tracker::SwipeTracker::new(cell_size() as i32 / 2),
		mouse_down: false,
	};

	api.init(callbacks);
	Box::from(api)
}
