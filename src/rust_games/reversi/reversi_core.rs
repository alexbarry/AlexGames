//use std::io;
use serde::{Serialize, Deserialize};

pub const BOARD_SIZE: usize = 8;

// TODO make htis serialize into something smaller, I think it might be 4 bytes now.
// Ideally just 2 bits if the serialization library can support that.
// If not, maybe port the code I wrote for minesweeper
#[derive(Copy, Clone, PartialEq, Eq, Serialize, Deserialize, Debug)]
pub enum CellState {
	EMPTY,
	PLAYER1,
	PLAYER2,
}

#[derive(Copy, Clone, PartialEq, Eq, Debug)]
pub enum ReversiErr {
	NotYourTurn,
	InvalidMove,
}

#[derive(Copy, Clone, Debug)]
pub struct Pt{pub y: i32, pub x: i32}


#[derive(Serialize, Deserialize, Debug)]
pub struct State {
	board: [[CellState; BOARD_SIZE]; BOARD_SIZE],
	pub player_turn: CellState,

	// TODO don't include in this state, make another state struct to include game metadata like this
	pub session_id: i32,
}

impl State {
	pub fn new() -> State {
		let mut state = State {
			board: [[CellState::EMPTY; BOARD_SIZE]; BOARD_SIZE],
			player_turn: CellState::PLAYER1,

			// TODO remove
			session_id: 0,
		};

		state.board[3][3] = CellState::PLAYER1;
		state.board[3][4] = CellState::PLAYER2;
		state.board[4][3] = CellState::PLAYER2;
		state.board[4][4] = CellState::PLAYER1;

		state
	}

	pub fn cell(&self, pt: Pt) -> CellState {
		self.board[pt.y as usize][pt.x as usize]
	}

	fn set_cell(&mut self, pt: Pt, cell: CellState) {
		self.board[pt.y as usize][pt.x as usize] = cell;
	}

	pub fn is_valid_move(&self, player: CellState, pt: Pt) -> bool {
		for dir in DIRS {
			let jumpable_piece_count = get_jumpable_pieces(self, player, pt, dir);
			if jumpable_piece_count > 0 {
				return true;
			}
		}
		return false;
	}
}

const DIRS: [(i32, i32); 8] = [
	( 0,  1),
	( 0, -1),
	( 1,  0),
	(-1,  0),

	( 1,  1),
	( 1, -1),
	(-1,  1),
	(-1, -1),
];


// TODO move to struct impl
pub fn _print_board(state: &State) {
	print!("  ");
	for x in 0..BOARD_SIZE {
		print!("{} ", x)
	}
	println!("");
	print!(" +");
	for _x in 0..(2*BOARD_SIZE-1) {
		print!("-");
	}
	print!("+");
	println!("");
	for y in 0..BOARD_SIZE {
		print!("{}|", y);
		for x in 0..BOARD_SIZE {
			match state.board[y][x] {
				CellState::EMPTY   => print!(" "),
				CellState::PLAYER1 => print!("x"),
				CellState::PLAYER2 => print!("o"),
			}
			print!("|");
		}
		println!("");
		if y < BOARD_SIZE-1 {
			print!(" |");
			for _x in 0..(2*BOARD_SIZE-1) {
				print!("-");
			}
			print!("|");
			println!("");
		}
	}
	print!(" +");
	for _x in 0..(2*BOARD_SIZE-1) {
		print!("-");
	}
	print!("+");
	println!("");
}

fn pos_in_range(pt: Pt) -> bool {
	( 0 <= pt.y && pt.y < BOARD_SIZE as i32) &&
	( 0 <= pt.x && pt.x < BOARD_SIZE as i32)
}

fn add_pt(pt: &Pt, dir: (i32, i32)) -> Pt {
	Pt{x: pt.x + dir.0, y: pt.y + dir.1}
}

fn other_player(player: CellState) -> CellState {
	match player {
		CellState::EMPTY   => { CellState::EMPTY /* TODO crash instead */ },
		CellState::PLAYER1 => { CellState::PLAYER2 },
		CellState::PLAYER2 => { CellState::PLAYER1 },
	}
}

// TODO move to struct impl
fn get_jumpable_pieces(state: &State, player: CellState, start_pt: Pt, dir: (i32, i32) ) -> i32 {
	let start_pt_copy = start_pt.clone();
	for i in 1..BOARD_SIZE {
		let pt = add_pt(&start_pt_copy, (dir.0 * i as i32, dir.1 * i as i32));
		if !pos_in_range(pt) { break; }
		let cell = state.cell(pt);
		//println!("dir={:?}, i={:?}, pt={:?}, cell={:?}", dir, i, pt, cell);
		if      cell == CellState::EMPTY     { break; }
		else if cell == player               { return i as i32 - 1; }
		else if cell == other_player(player) { continue; }
	}
	return 0;
}

// TODO move to struct impl
fn reverse_cells(state: &mut State, player: CellState, pt: Pt, dir: (i32, i32)) {
	for i in 1..BOARD_SIZE {
		let pt = add_pt(&pt, (dir.0 * i as i32, dir.1 * i as i32));
		if !pos_in_range(pt) { break; }
		let cell = state.cell(pt);
		if      cell == CellState::EMPTY     { return; }
		else if cell == player               { return; }
		else if cell == other_player(player) { 
			println!("reverse_cells: Setting {:?} to {:?}", pt, player);
			state.set_cell(pt, player);
		}
	}
}

// TODO move to struct impl
pub fn player_move(mut state: &mut State, player: CellState, pt: Pt) -> Result<(), ReversiErr> {
	if state.player_turn != player {
		return Err(ReversiErr::NotYourTurn);
	}

	if !pos_in_range(pt) {
		return Err(ReversiErr::InvalidMove);
	}

	if state.cell(pt) != CellState::EMPTY {
		return Err(ReversiErr::InvalidMove);
	}


	let pt = Pt{ y: pt.y, x: pt.x };

	let mut can_move = false;
	for dir in DIRS {
		let jumpable_piece_count = get_jumpable_pieces(&state, player, pt, dir);
		//println!("dir={:?}, jumpable_piece_count={}", dir, jumpable_piece_count);
		if jumpable_piece_count > 0 {
			reverse_cells(&mut state, player, pt, dir);
			can_move = true;
		}
	}

	if !can_move {
		return Err(ReversiErr::InvalidMove);
	}

	println!("player_move: setting cell {:?} to {:?}", pt, player);
	state.set_cell(pt, player);
	state.player_turn = other_player(state.player_turn);


	Ok(())
}
