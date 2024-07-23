use rand::seq::SliceRandom;
use rand::thread_rng;

pub use crate::libs::point::Pt;

pub const BOARD_WIDTH: usize  = 8;
pub const BOARD_HEIGHT: usize = 8;

type Board<T> = [[T; BOARD_WIDTH]; BOARD_HEIGHT];


const DIRS: [Pt; 2] = [
	Pt{y:  1, x: 0},
	Pt{y:  0, x: 1},
];

// Indicates a group of three or more gems in a row.
#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct GemsInARow {
	pub pt: Pt,
	pub dir: Pt,
	pub len: i32,
}

impl GemsInARow {
	pub fn end_pt(&self) -> Pt {
		self.pt.add(self.dir.mult(self.len - 1))
	}
}

// Indicates all the changes after a player moves, so that
// they can be animated by gem_match_draw.rs
#[derive(Debug, PartialEq, Eq)]
pub struct GemChanges {
	pub swipe_cell: Pt,
	pub dst_cell: Pt,

	// these are the gem positions that are removed from the previous state (when a move is made)
	pub to_remove: Vec<GemsInARow>,

	// these are the offsets that new gems would have fallen from, from the new state.
	pub fallen_distance: Board<Option<usize>>,
}

impl GemChanges {
	fn new(swipe_cell: Pt, dst_cell: Pt) -> GemChanges {
		GemChanges {
			swipe_cell: swipe_cell,
			dst_cell: dst_cell,
			to_remove: Vec::new(),
			fallen_distance: [[None; BOARD_WIDTH]; BOARD_HEIGHT],
		}
	}
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum GemType {
	SAPPHIRE,  // blue
	EMERALD,   // green
	RUBY,      // red
	AMETHYST,  // purple
	TOPAZ,     // yellow
	//AMBER,     // orange
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
	pub board: Board<Option<GemInfo>>,
}

impl State {
	pub fn new() -> State {
		let mut state = State {
			board: [[Some(GemInfo{gem_type: GemType::SAPPHIRE}); BOARD_WIDTH]; BOARD_HEIGHT],
		};

		let init_gems = [GemType::SAPPHIRE, GemType::EMERALD, GemType::RUBY, GemType::AMETHYST, GemType::TOPAZ];
		for row in state.board.iter_mut() {
			for cell in row.iter_mut() {
			    let mut rng = thread_rng();
			    let gem_info = GemInfo {
					gem_type: *init_gems.choose(&mut rng).expect("Subset cannot be empty"),
				};
				*cell = Some(gem_info);
				//println!("gem_info: {:#?}", gem_info);
			}
		}

		return state;
	}

	fn get_gem(&self, pt: Pt) -> Result<GemInfo, ()> {
		let x = pt.x as usize;
		let y = pt.y as usize;
		if y < self.board.len() &&
		   x < self.board[0].len() {
			let gem_info = self.board[y][x].unwrap();
			return Ok(gem_info);
		} else {
			return Err(());
		}
	}

	fn set_gem(&mut self, pt: Pt, gem_info: Option<GemInfo>) {
		println!("move_gems: set_gem pt({:?}), gem_info={:?}", pt, gem_info);
		let x = pt.x as usize;
		let y = pt.y as usize;

		if y < self.board.len() &&
		   x < self.board[0].len() {
			self.board[y][x] = gem_info;
		} else {
			panic!("invalid dimensions {:?}", pt);
		}
		
	}

	// Should only be called externally in the draw code, on a copy,
	// for animations.
	// The main game logic should only ever call move_gems
	pub fn swap_gems(&mut self, pt1: Pt, pt2: Pt) -> Result<(),()> {
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

		self.set_gem(pt1, Some(gem2));
		self.set_gem(pt2, Some(gem1));

		Ok(())
	}

	pub fn has_three_or_more_in_a_row_at_pt(&self, pt: Pt) -> bool {
		let gem = self.get_gem(pt);
		for dir in DIRS.iter() {
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
		for dir in DIRS.iter() {
			let other_dir = dir.swap();
			let (limit1, limit2) = match dir {
				Pt{y: 1, x: 0} => (BOARD_WIDTH,  BOARD_HEIGHT),
				Pt{y: 0, x: 1} => (BOARD_HEIGHT, BOARD_WIDTH ),
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

	fn remove_matches(&mut self, changes_out: &mut Vec<GemsInARow>) {
		println!("remove_matches");
		let matches = self.find_all_three_or_more_in_a_row();
		for match_val in matches {
			changes_out.push(match_val);
			let start = match_val.pt;
			let dir = match_val.dir;
			for i in 0..match_val.len {
				let pt = start.add(dir.mult(i));
				//self.set_gem(pt, None);
				//self.set_gem(pt, Some(GemInfo{gem_type: GemType::SAPPHIRE}));
				self.set_gem(pt, None);
			}
		}
		println!("done remove_matches");
	}

	fn calc_fallen_distance(&mut self, fallen_distance: &mut Board<Option<usize>>) {
		for x in 0..BOARD_WIDTH {
			let mut fall_count = 0;
			for y in 0..BOARD_HEIGHT {
				if let Some(_) = self.board[y][x] {
					println!("found something");
					// do nothing
				} else {
					println!("found empty!");
					fall_count += 1;
				}
				if fall_count > 0 {
					println!("setting fall_count to {} for {} {}", fall_count, y, x);
					fallen_distance[y][x] = Some(fall_count);
				}
			}
		}
	}


	fn fall_and_add_new_gems(&mut self, fall_distance: &mut Board<Option<usize>>) {
	    let mut rng = thread_rng();
		let init_gems = [GemType::SAPPHIRE, GemType::EMERALD, GemType::RUBY, GemType::AMETHYST, GemType::TOPAZ];

		for x in 0..BOARD_WIDTH {
			for y in (0..BOARD_HEIGHT).rev() {
				if let None = self.board[y][x] {
					let mut y2: Option<usize> = None;
					for y in (0..y).rev() {
						if let Some(_) = self.board[y][x] {
							y2 = Some(y);
							break;
						}
					}
					if let Some(y2) = y2 {
						self.board[y][x] = self.board[y2][x];
						self.board[y2][x] = None;
						fall_distance[y][x] = Some(y - y2);
					}
				}
			}

			for y in (0..BOARD_HEIGHT).rev() {
				if let None = self.board[y][x] {
					let gem = *init_gems.choose(&mut rng).expect("Subset cannot be empty");

					self.board[y][x] = Some(GemInfo{gem_type:gem});
					//fall_distance[y][x] = Some(2*(y));
					fall_distance[y][x] = Some(2*y+1);
				}
			}

		}
	}

	// Returns a list of changes, to be animated by gem_match_draw.rs
	pub fn move_gems(&mut self, pt: Pt, dir: Pt) -> Result<GemChanges, GemMatchErr> {
		let pt2 = pt.add(dir);
		let mut copy = self.clone();

		if let Err(_) = copy.swap_gems(pt, pt2) {
			return Err(GemMatchErr::InvalidMove);
		}

		if !copy.has_three_or_more_in_a_row_at_pt(pt) && !copy.has_three_or_more_in_a_row_at_pt(pt2) {
			println!("move_gems: no three in a row!");
			return Err(GemMatchErr::InvalidMove);
		}

		*self = copy;

		let mut changes = GemChanges::new(pt, pt2);
		self.remove_matches(&mut changes.to_remove);

		// should populate a 2D array of "how many columns down did this gem move"
		// this is pretty simple, it's just a matter of counting the number of empty cells below each
		// cell.

		// Then use that on the *final* state to reverse their motion, and animate them to the destination (their real position).
		// And actually, the new gems will be treated the exact same way.
		/*
		self.calc_fallen_distance(&mut changes.fallen_distance);

		for (y, row) in changes.fallen_distance.iter().enumerate() {
			print!("{} ", y);
			for (_x, cell) in row.iter().enumerate() {
				print!("{} ", cell.unwrap_or(0));
			}
			println!("");
		}
		*/


		self.fall_and_add_new_gems(&mut changes.fallen_distance);

		self._print_board();

		return Ok(changes);
	}

	pub fn _print_board(&self) {
		for (y, row) in self.board.iter().enumerate() {
			print!("{} ", y);
			for (_x, cell) in row.iter().enumerate() {
				let val = match cell {
					Some(cell) => match cell.gem_type {
						GemType::SAPPHIRE => "b",
						GemType::EMERALD  => "g",
						GemType::RUBY     => "r",
						GemType::AMETHYST => "p",
						GemType::TOPAZ    => "y",
						//GemType::AMBER    => "o",
					},
					None => " ",
				};
				print!("{} ", val);
			}
			println!("");
		}

	}
}

