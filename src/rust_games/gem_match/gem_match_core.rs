use rand::seq::SliceRandom;
use rand::thread_rng;

pub use crate::libs::point::Pt;

pub const BOARD_WIDTH: usize  = 8;
pub const BOARD_HEIGHT: usize = 8;


#[derive(Copy, Clone, Debug)]
pub enum GemType {
	SAPPHIRE,  // blue
	EMERALD,   // green
	RUBY,      // red
	AMETHYST,  // purple
	TOPAZ,     // yellow
	AMBER,     // orange
}

#[derive(Copy, Clone, Debug)]
pub struct GemInfo {
	pub gem_type: GemType,
}

#[derive(Copy, Clone, Debug)]
pub struct State {
	pub board: [[Option<GemInfo>; BOARD_WIDTH]; BOARD_HEIGHT],
}

impl State {
	pub fn new() -> State {
		let mut state = State {
			board: [[None; BOARD_WIDTH]; BOARD_HEIGHT],
		};

		let init_gems = [GemType::SAPPHIRE, GemType::EMERALD, GemType::RUBY, GemType::AMETHYST, GemType::TOPAZ];
		for row in state.board.iter_mut() {
			for cell in row.iter_mut() {
			    let mut rng = thread_rng();
			    let gem_info = GemInfo {
					gem_type: *init_gems.choose(&mut rng).expect("Subset cannot be empty"),
				};
				*cell = Some(gem_info);
				println!("gem_info: {:#?}", gem_info);
			}
		}

		return state;
	}
}

