use crate::gem_match::gem_match_core::{State, GemType, BOARD_WIDTH, BOARD_HEIGHT};

use crate::rust_game_api::{AlexGamesApi, CANVAS_HEIGHT, CANVAS_WIDTH, CCallbacksPtr};
use crate::rust_game_api;

pub struct AlexGamesGemMatch {
	state: State,
	callbacks: &'static rust_game_api::CCallbacksPtr,
}

impl AlexGamesGemMatch {

fn draw_state(&self) {
	let padding = 2;
	let cell_width  = (CANVAS_WIDTH as f64) / (BOARD_WIDTH as f64);
	let cell_height = (CANVAS_WIDTH as f64) / (BOARD_WIDTH as f64);
	let outline_colour = "#000000";
	for (y, row) in self.state.board.iter().enumerate() {
		for (x, cell) in row.iter().enumerate() {
			if let Some(cell) = cell {
				let colour = match cell.gem_type {
					GemType::SAPPHIRE => ("#000088", "#0000ff"),
					GemType::EMERALD  => ("#00ff00", "#0000ff"),
					GemType::RUBY     => ("#ff0000", "#0000ff"),
					GemType::AMETHYST => ("#ff00ff", "#0000ff"),
					GemType::TOPAZ    => ("#ffff00", "#0000ff"),
					GemType::AMBER    => ("#ff8800", "#0000ff"),
				};
				let y = y as f64;
				let x = x as f64;

				let circ_y = (y+0.5)*cell_height;
				let circ_x = (x+0.5)*cell_width;

				self.callbacks.draw_circle(colour, outline_colour, circ_y as i32, circ_x as i32, (cell_width/2.0) as i32, 2);
			}
		}
	}
	
}

}


impl AlexGamesApi for AlexGamesGemMatch {
	fn callbacks(&self) -> *const CCallbacksPtr {
		self.callbacks
	}

	fn update(&mut self, dt_ms: i32) {
		self.draw_state();
	}

	fn handle_user_clicked(&mut self, pos_y: i32, pos_x: i32) {
	}
	
	fn handle_btn_clicked(&mut self, btn_id: &str) {
	}
	
	fn start_game(&mut self, session_id_and_state: Option<(i32, Vec<u8>)>) {
	}
	
	fn get_state(&self) -> Option<Vec<u8>> {
		None
	}



	fn init(&mut self, callbacks: *const rust_game_api::CCallbacksPtr) {
		self.state = State::new(); 
	}
}

pub fn test() {
	let state = State::new();
}

pub fn init_gem_match(callbacks: *const rust_game_api::CCallbacksPtr) -> Box<dyn AlexGamesApi> {
	let mut api = AlexGamesGemMatch {
		state: State::new(),
		callbacks: unsafe { callbacks.as_ref().expect("callbacks null?") },
	};

	api.init(callbacks);
	Box::from(api)
}
