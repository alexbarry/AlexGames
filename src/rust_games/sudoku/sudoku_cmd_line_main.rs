

//mod sudoku_core;

use alexgames_rust::sudoku::sudoku_core::{self, Pt, State};
use alexgames_rust::sudoku::sudoku_solve;

const puzzles: [ [ [i8;9]; 9]; 0] = [
];



fn main() {
	let mut state = State::new(9);
	for (puzzle_idx, puzzle) in puzzles.iter().enumerate() {
		state.board = puzzle.iter().map(|row| row.to_vec()).collect();
		//state.print();
		let mut stats = sudoku_solve::Stats::new();
		let mut params = sudoku_solve::Params::new();
		params.debug = false;
		let mut solved = sudoku_solve::solve(&state, 0, &mut stats, &params);
		if !solved {
			//params.debug = true;
			//solved = sudoku_solve::solve(&state, 0, &mut stats, &params);
			println!("Could not solve puzzle {}", puzzle_idx);
		}
		//assert!(solved);
		println!("stats: {:?}", stats);
	}
}
