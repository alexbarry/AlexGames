

pub use crate::libs::point::Pt;

use serde::{Serialize, Deserialize};

use std::collections::{HashSet, HashMap};

#[derive(PartialEq, Serialize, Deserialize, Debug, Clone)]
pub enum Mode {
	// only used when the user inputs their own puzzle
	EnterStartingVal,

	EnterCellVal,
	EnterCellNotes,
}

#[derive(PartialEq, Serialize, Deserialize, Debug, Clone)]
pub struct CellInfo {
	pub val: i8,
	pub revealed: bool,
}

impl CellInfo {
	pub const fn new(val: i8, revealed_int: i8) -> Self {
		assert!(revealed_int == 0 || revealed_int == 1);
		Self {
			val: val,
			revealed: revealed_int != 0,
		}
	}
}

// TODO manually implement serialization
#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub struct State {
	pub board: Vec<Vec<CellInfo>>,
	pub user_input: Vec<Vec<i8>>,
	pub user_input_notes: Vec<Vec<Vec<i8>>>,
	pub size: usize,
	pub box_size: usize,

	pub selected: Option<Pt>,

	pub mode: Mode,
	pub time_elapsed_ms: i32,
}

pub enum CellContents {
	Empty,
	StartingVal(i8),
	UserInputVal(i8),
}

impl State {
	pub fn new(size: usize) -> Self {
		Self {
			board: vec![vec![ CellInfo { val: 0, revealed: false}; size]; size],
			user_input: vec![vec![0; size]; size],
			user_input_notes: vec![vec![ vec![] ; size]; size],
			size: size,
			box_size: (size as f64).sqrt() as usize,

			selected: None,
			mode: Mode::EnterCellVal,
			time_elapsed_ms: 0,
		}
	}

	pub fn val(&self, y: i32, x: i32) -> CellContents {
		let y = y as usize;
		let x = x as usize;
		if self.board[y][x].revealed {
			CellContents::StartingVal(self.board[y][x].val)
		} else if self.user_input[y][x] != 0 {
			CellContents::UserInputVal(self.user_input[y][x])
		} else {
			CellContents::Empty
		}
	}

	pub fn cell_val(&self, y: i32, x: i32) -> i8 {
		match self.val(y, x) {
			CellContents::StartingVal(val) => val,
			CellContents::UserInputVal(val) => val,
			CellContents::Empty => 0,
		}
	}


	pub fn cell_notes(&self, y: i32, x: i32) -> &Vec<i8> {
		let y = y as usize;
		let x = x as usize;
		&self.user_input_notes[y][x]
	}

	pub fn cell_selected(&self, y: i32, x:i32) -> bool {
		if let Some(selected) = self.selected {
			return selected.y == y && selected.x == x;
		}

		return false
	}

	pub fn get_selected_val(&self) -> Option<i8> {
		if let Some(sel) = self.selected {
			let val = self.cell_val(sel.y, sel.x);
			if val != 0 {
				return Some(val)
			}
		}
		None
	}

	pub fn has_empty_cells(&self) -> bool {
		self.all_pts().into_iter().any(|pt| self.cell_val(pt.y, pt.x) == 0)
	}

	pub fn game_won(&self) -> bool {
		!self.has_empty_cells() && self.get_conflicts(true).len() == 0
	}

	pub fn box_id(&self, pt: &Pt) -> i32 {
		let box_size = self.box_size as i32;
		let box_y = pt.y / box_size;
		let box_x = pt.x / box_size;

		return box_y * box_size + box_x;
	}

	pub fn box_start_pt(&self, pt: &Pt) -> Pt {
		let box_size = self.box_size as i32;
		Pt {
			y: (pt.y / box_size) * box_size,
			x: (pt.x / box_size) * box_size,
		}
	}

	pub fn box_start_pt_from_id(&self, box_id: i32) -> Pt {
		let box_size = self.box_size as i32;
		Pt {
			y: (box_id / box_size) * box_size,
			x: (box_id % box_size) * box_size,
		}
	}

	pub fn box_pts_from_id(&self, box_id: i32) -> Vec<Pt> {
		let pt = self.box_start_pt_from_id(box_id);
		let box_size = self.box_size as i32;
		(0..box_size).flat_map(move |dy| 
			(0..box_size)
				.map(move |dx| Pt { y: pt.y + dy, x: pt.x + dx })
			)
			.collect()
	}

	pub fn set_selection(&mut self, sel: &Pt) {
		if self.selected.is_some_and(|cur_sel| cur_sel == *sel) {
			self.selected = None;
		} else {
			self.selected = Some(*sel);
		}
	}

	pub fn move_sel(&mut self, sel_change: &Pt) -> bool {
		// flip y axis, user input "up" versus internal storage 0,0 at top left
		let sel_change = Pt { y: -sel_change.y, x: sel_change.x };

		if self.selected.is_none() {
			let middle = (self.size/2) as i32;
			self.selected = Some(Pt { y: middle, x: middle });
		}

		let old_sel = self.selected.unwrap();

		let new_sel = old_sel.add(sel_change);

		let new_sel = self.clamp_pt(&new_sel);

		if old_sel == new_sel {
			return false;
		}

		self.selected = Some(new_sel);
		return true;
	}

	fn clamp_pt(&self, pt: &Pt) -> Pt {
		let size = self.size as i32;
		Pt {
			y: if pt.y < 0 { 0 } else if pt.y > size-1 { size-1 } else { pt.y },
			x: if pt.x < 0 { 0 } else if pt.x > size-1 { size-1 } else { pt.x },
		}
	}

	fn clear_notes_from_set_val(&mut self, pt: &Pt, val: i8) {
		for y in 0..self.size {
			self.user_input_notes[y][pt.x as usize].retain(|cell_val| *cell_val != val);
		}
		for x in 0..self.size {
			self.user_input_notes[pt.y as usize][x].retain(|cell_val| *cell_val != val);
		}
		let box_id = self.box_id(pt);
		for pt in self.box_pts_from_id(box_id) {
			self.user_input_notes[pt.y as usize][pt.x as usize].retain(|cell_val| *cell_val != val);
		}
		self.user_input_notes[pt.y as usize][pt.x as usize].clear();
	}

	pub fn set_val(&mut self, val: i8) {
		if let Some(selected) = self.selected {
			match self.mode {
				Mode::EnterStartingVal => {
					let cell_info = &mut self.board[selected.y as usize][selected.x as usize];
					cell_info.val = val;
					cell_info.revealed = true;
				},
				Mode::EnterCellVal => {
					self.user_input[selected.y as usize][selected.x as usize] = val;
					self.clear_notes_from_set_val(&selected, val);
				},
				Mode::EnterCellNotes => {
					let cell_notes = &mut self.user_input_notes[selected.y as usize][selected.x as usize];
					if val == 0 {
						cell_notes.clear();
					} else if cell_notes.contains(&val) {
						cell_notes.retain(|x| *x != val);
					} else {
						cell_notes.push(val);
					}
				},
			}
		}
	}

	pub fn erase(&mut self) {
		self.set_val(0);
	}

	pub fn toggle_notes(&mut self) {
		self.mode = match self.mode {
			Mode::EnterCellVal   => Mode::EnterCellNotes,
			Mode::EnterCellNotes => Mode::EnterCellVal,
			Mode::EnterStartingVal => Mode::EnterStartingVal,
		};
	}

	//fn get_pts_row(state: &State, y: i32) -> impl Iterator<Item = Pt> {
	pub fn get_pts_row(&self, y: i8) -> Vec<Pt> {
		let y = y as i32;
		let size = self.size as i32;
		(0..size).map(move |x| Pt { y: y, x: x })
			.collect()
	}

	//fn get_pts_col(state: &State, x: i32) -> impl Iterator<Item = Pt> {
	pub fn get_pts_col(&self, x: i8) -> Vec<Pt> {
		let x = x as i32;
		let size = self.size as i32;
		(0..size).map(move |y| Pt { y: y, x: x })
			.collect()
	}

	//fn get_pts_box(state: &State, pt: &Pt) -> impl Iterator<Item = Pt> {
	pub fn get_pts_box_from_id(&self, box_id: i8) -> Vec<Pt> {
		let pt = self.box_start_pt_from_id(box_id.into());
		let box_size = self.box_size as i32;
		let y = pt.y;
		let x = pt.x;
		(0..box_size).flat_map(move |dy| 
			(0..box_size)
				.map(move |dx| Pt { y: y + dy, x: x + dx })
		)
			.collect()
	}

	fn all_pts(&self) -> Vec<Pt> {
		(0..self.size).flat_map(move |y| 
			(0..self.size)
				.map(move |x| Pt { y: y as i32, x: x as i32 })
		).collect()
		
	}

	fn all_groups(&self) -> Vec<Vec<Pt>> {
		let size = self.size as i8;
		(0..size).map(|group_id| self.get_pts_row(group_id))
			.chain((0..size).map(|group_id| self.get_pts_col(group_id)))
			.chain((0..size).map(|group_id| self.get_pts_box_from_id(group_id)))
			.collect()
	}

	pub fn get_taken_input_vals(&self) -> HashSet<i8> {
		let mut taken = HashSet::new();
		if let Some(sel) = self.selected {
			for pt in self.get_pts_row(sel.y.try_into().unwrap()) {
				if pt == sel { continue; }
				taken.insert(self.cell_val(pt.y, pt.x));
			}
			for pt in self.get_pts_col(sel.x.try_into().unwrap()) {
				if pt == sel { continue; }
				taken.insert(self.cell_val(pt.y, pt.x));
			}
			for pt in self.get_pts_box_from_id(self.box_id(&sel).try_into().unwrap()) {
				if pt == sel { continue; }
				taken.insert(self.cell_val(pt.y, pt.x));
			}
		}
		taken.remove(&0);

		taken
	}

	pub fn get_mistakes(&self) -> HashMap<Pt, i8> {
		let mut mistakes = HashMap::new();
		for pt in self.all_pts() {
			let y = pt.y as usize;
			let x = pt.x as usize;
			if !self.board[y][x].revealed && self.user_input[y][x] != 0 && self.board[y][x].val != 0 {
				if self.board[y][x].val != self.user_input[y][x] {
					mistakes.insert(pt, self.board[y][x].val);
				}
			}
		}
		mistakes
	}

	pub fn get_conflicts(&self, show_mistakes: bool) -> HashSet<Pt> {
		let mut conflicts = HashSet::new();

		if show_mistakes {
			for pt in self.all_pts() {
				let y = pt.y as usize;
				let x = pt.x as usize;
				if !self.board[y][x].revealed && self.user_input[y][x] != 0 && self.board[y][x].val != 0 {
					if self.board[y][x].val != self.user_input[y][x] {
						conflicts.insert(pt);
					}
				}
			}
		}

		for group_pts in self.all_groups() {
			let mut counts: HashMap<i8, Vec<Pt>> = HashMap::new();
			for pt in group_pts {
				let val = self.cell_val(pt.y, pt.x);
				if val != 0 {
					counts.entry(val).or_default().push(pt.clone());
				}
			}
			for (val, pts) in counts {
				if pts.len() > 1 {
					for pt in pts {
						conflicts.insert(pt);
					}
				}
			}
		}

		conflicts
	}

	pub fn set_cells_from_int_vec(&mut self, cell_vals: &Vec<Vec<i8>>) {
		assert_eq!(self.board.len(), cell_vals.len());
		for y in 0..cell_vals.len() {
			assert_eq!(self.board[y].len(), cell_vals[y].len());
			for x in 0..cell_vals[y].len() {
				let val = cell_vals[y][x];
				self.board[y][x].val = val;
				self.board[y][x].revealed = (val != 0);
			}
		}
	}

	pub fn print(&self) {
		let box_size = self.box_size as i32;
		let game_size = self.size as i32;
	
		let print_row_border = || {
			for i in 0..game_size {
				if i % box_size == 0 {
					print!("+")
				}
				print!("-");
			}
			println!("+");
		};
	
		for y in 0..game_size {
			let y = y as i32;
			if y % box_size == 0 {
				print_row_border();
			}
			for x in 0..game_size {
				let x = x as i32;
				if x % box_size == 0 {
					print!("|")
				}
				let val = self.cell_val(y, x);
				if val == 0 {
					print!(" ");
				} else {
					print!("{}", val);
				}
			}
			println!("|");
		}
		print_row_border();
	}

	pub fn print_as_rust_code(&self, indent: usize) {
		let box_size = self.box_size;
		let game_size = self.size;
		let indent_str = " ".repeat(indent);
		//println!("{}vec![", indent_str);
		println!("{}[", indent_str);
		let indent2_str = " ".repeat(indent + 4);
		for y in 0..game_size {
			if y != 0 && y % box_size == 0 {
				println!("");
			}
			//print!("{}vec![", indent2_str);
			print!("{}[", indent2_str);
			for x in 0..game_size {
				if x != 0 && x % box_size == 0 {
					//print!("{:30}","");
					print!("  ");
				}
				//print!("{}", self.cell_val(y,x));
				let cell_info = &self.board[y][x];
				//print!("CellInfo::new({},{})", cell_info.val, if cell_info.revealed { 1 } else { 0 });
				print!("val({},{})", cell_info.val, if cell_info.revealed { 1 } else { 0 });
				if x < game_size-1 {
					print!(",");
				}
			}
			println!("],");
		}
		println!("{}],", indent_str);
		println!("");
	}
}
