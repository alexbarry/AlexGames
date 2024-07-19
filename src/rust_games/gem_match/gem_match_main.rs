use crate::gem_match::gem_match_core::{State, GemType, BOARD_WIDTH, BOARD_HEIGHT};

use crate::rust_game_api::{AlexGamesApi, CANVAS_HEIGHT, CANVAS_WIDTH, CCallbacksPtr};
use crate::rust_game_api;

pub struct AlexGamesGemMatch {
	state: State,
	callbacks: &'static rust_game_api::CCallbacksPtr,
}

impl AlexGamesGemMatch {

fn draw_state(&self) {
	let padding = 1.0;
	let cell_width  = (CANVAS_WIDTH as f64) / (BOARD_WIDTH as f64);
	let cell_height = (CANVAS_HEIGHT as f64) / (BOARD_HEIGHT as f64);
	let piece_radius = (f64::min(cell_width,cell_height)/2.0 - padding) as i32;
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
	
	fn handle_btn_clicked(&mut self, _btn_id: &str) {
	}
	
	fn start_game(&mut self, _session_id_and_state: Option<(i32, Vec<u8>)>) {
	}
	
	fn get_state(&self) -> Option<Vec<u8>> {
		None
	}



	fn init(&mut self, _callbacks: *const rust_game_api::CCallbacksPtr) {
		self.state = State::new(); 
	}
}

pub fn init_gem_match(callbacks: *const rust_game_api::CCallbacksPtr) -> Box<dyn AlexGamesApi> {
	let mut api = AlexGamesGemMatch {
		state: State::new(),
		callbacks: unsafe { callbacks.as_ref().expect("callbacks null?") },
	};

	api.init(callbacks);
	Box::from(api)
}
