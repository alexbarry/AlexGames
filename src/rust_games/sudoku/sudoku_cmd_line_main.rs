

//mod sudoku_core;

use alexgames_rust::sudoku::sudoku_core::{self, Pt, State};
use alexgames_rust::sudoku::sudoku_solve;

const puzzles: [ [ [i8;9]; 9]; 0] = [
];



fn main() {
	let mut state = State::new(9);
	for puzzle in puzzles {
		state.board = puzzle.iter().map(|row| row.to_vec()).collect();
		//state.print();
		let mut stats = sudoku_solve::Stats::new();
		let params = sudoku_solve::Params::new();
		let solved = sudoku_solve::solve(&state, 0, &mut stats, &params);
		assert!(solved);
		println!("stats: {:?}", stats);
	}
}
