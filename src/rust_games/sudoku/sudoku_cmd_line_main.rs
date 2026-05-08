

//mod sudoku_core;

use alexgames_rust::sudoku::sudoku_core::{self, Pt, State};
use alexgames_rust::sudoku::sudoku_solve;



fn main() {
	let mut state = State::new(9);
	state.print();
	let mut stats = sudoku_solve::Stats::new();
	sudoku_solve::solve(&state, 0, &mut stats);
	println!("stats: {:?}", stats);
}
