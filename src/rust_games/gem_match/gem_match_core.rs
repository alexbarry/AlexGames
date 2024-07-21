use rand::seq::SliceRandom;
use rand::thread_rng;

pub use crate::libs::point::Pt;

pub const BOARD_WIDTH: usize  = 8;
pub const BOARD_HEIGHT: usize = 8;


const DIRS: [Pt; 2] = [
	Pt{y:  1, x: 0},
	Pt{y:  0, x: 1},
];

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct GemsInARow {
	pub pt: Pt,
	pub dir: Pt,
	pub len: i32,
}


#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum GemType {
	SAPPHIRE,  // blue
	EMERALD,   // green
	RUBY,      // red
	AMETHYST,  // purple
	TOPAZ,     // yellow
	AMBER,     // orange
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum GemMatchErr {
	InvalidMove,
	
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct GemInfo {
	pub gem_type: GemType,
}

#[derive(Copy, Clone, Debug)]
pub struct State {
	pub board: [[GemInfo; BOARD_WIDTH]; BOARD_HEIGHT],
}

impl State {
	pub fn new() -> State {
		let mut state = State {
			board: [[GemInfo{gem_type: GemType::SAPPHIRE}; BOARD_WIDTH]; BOARD_HEIGHT],
		};

		let init_gems = [GemType::SAPPHIRE, GemType::EMERALD, GemType::RUBY, GemType::AMETHYST, GemType::TOPAZ];
		for row in state.board.iter_mut() {
			for cell in row.iter_mut() {
			    let mut rng = thread_rng();
			    let gem_info = GemInfo {
					gem_type: *init_gems.choose(&mut rng).expect("Subset cannot be empty"),
				};
				*cell = gem_info;
				println!("gem_info: {:#?}", gem_info);
			}
		}

		return state;
	}

	fn get_gem(&self, pt: Pt) -> Result<GemInfo, ()> {
		let x = pt.x as usize;
		let y = pt.y as usize;
		if 0 <= y && y < self.board.len() &&
		   0 <= x && x < self.board[0].len() {
			return Ok(self.board[y][x]);
		} else {
			return Err(());
		}
	}

	fn set_gem(&mut self, pt: Pt, gem_info: GemInfo) -> Result<(),()> {
		println!("move_gems: set_gem pt({:?}), gem_info={:?}", pt, gem_info);
		let x = pt.x as usize;
		let y = pt.y as usize;

		if 0 <= y && y < self.board.len() &&
		   0 <= x && x < self.board[0].len() {
			self.board[y][x] = gem_info;
			Ok(())
		} else {
			Err(())
		}
		
	}

	fn swap_gems(&mut self, pt1: Pt, pt2: Pt) -> Result<(),()> {
		let gem1;
		if let Ok(gem1_val) = self.get_gem(pt1) {
			gem1 = gem1_val;
		} else {
			println!("move_gems: err getting gem1");
			return Err(());
		}

		let gem2;
		if let Ok(gem2_val) = self.get_gem(pt2) {
			gem2 = gem2_val;
		} else {
			println!("move_gems: err getting gem2");
			return Err(());
		}

		self.set_gem(pt1, gem2).expect("error setting pt1?");
		self.set_gem(pt2, gem1).expect("error setting pt2?");

		Ok(())
	}

	pub fn has_three_or_more_in_a_row_at_pt(&self, pt: Pt) -> bool {
		let gem = self.get_gem(pt);
		'dir_loop: for dir in DIRS.iter() {
			let mut gems_in_a_row = 0;
			for i in -2..=2 {
				let pt2 = pt.add(dir.mult(i));
				let gem2 = self.get_gem(pt2);
				if gem == gem2 {
					gems_in_a_row += 1;
				} else {
					gems_in_a_row = 0;
				}
				println!("move_gems: src={:?}, pt={:?} now 'in a row' count is {}", pt, pt2, gems_in_a_row);
				if gems_in_a_row >= 3 {
					return true;
				}
			}
		}
		return false;
	}

	pub fn find_all_three_or_more_in_a_row(&self) -> Vec<GemsInARow> {
		let mut matches: Vec<GemsInARow> = Vec::new();
		'dir_loop: for dir in DIRS.iter() {
			let (limit1, limit2, other_dir) = match dir {
				Pt{y: 1, x: 0} => (BOARD_WIDTH,  BOARD_HEIGHT, Pt{y: 0, x: 1}, ),
				Pt{y: 0, x: 1} => (BOARD_HEIGHT, BOARD_WIDTH,  Pt{y: 1, x: 0}, ),
				_ => { panic!("unhandled direction"); }
			};
			for i1 in 0..limit1 {
				let mut gems_in_a_row = 1;
				let mut start_pt: Option<Pt> = None;
				let mut prev_pt: Option<Pt> = None;
				let mut prev_gem: Option<GemInfo> = None;
				let start = other_dir.mult(i1 as i32);
				for i2 in 0..limit2 {
					let pt = start.add(dir.mult(i2 as i32));
					let gem = self.get_gem(pt).unwrap();
					if let Some(prev_gem) = prev_gem {
						if prev_gem == gem {
							if gems_in_a_row == 1 {
								start_pt = prev_pt;
							}
							gems_in_a_row += 1;
						} else {
							if gems_in_a_row >= 3 {
								matches.push(GemsInARow {
									pt: start_pt.unwrap(),
									dir: *dir,
									len: gems_in_a_row,
								});
							}
							gems_in_a_row = 1;
						}
					} else {
						gems_in_a_row = 1;
					}
					if i2 == limit2 - 1 && gems_in_a_row >= 3 {
						matches.push(GemsInARow {
							pt: start_pt.unwrap(),
							dir: *dir,
							len: gems_in_a_row,
						});
					}
					prev_pt = Some(pt);
					prev_gem = Some(gem);
				}
			}
		}
		matches
	}

	pub fn move_gems(&mut self, pt: Pt, dir: Pt) -> Result<(), GemMatchErr> {
		println!("move_gems called with pt={:?}, dir={:?}", pt, dir);
		let pt2 = pt.add(dir);
		let mut copy = self.clone();

		println!("move_gems: swap_gems");
		if let Err(_) = copy.swap_gems(pt, pt2) {
			println!("move_gems: error calling swap_gems");
			return Err(GemMatchErr::InvalidMove);
		}

		for (y, row) in copy.board.iter().enumerate() {
			print!("{} ", y);
			for (_x, cell) in row.iter().enumerate() {
				let val = match cell.gem_type {
					GemType::SAPPHIRE => "s",
					GemType::EMERALD  => "e",
					GemType::RUBY     => "r",
					GemType::AMETHYST => "a",
					GemType::TOPAZ    => "t",
					GemType::AMBER    => "m",
				};
				print!("{} ", val);
			}
			println!("");
		}

		println!("move_gems: checking for three in a row");
		if !copy.has_three_or_more_in_a_row_at_pt(pt) && !copy.has_three_or_more_in_a_row_at_pt(pt2) {
			println!("move_gems: no three in a row!");
			return Err(GemMatchErr::InvalidMove);
		}
		println!("move_gems: found three in a row");

		*self = copy;
		Ok(())
	}
}

