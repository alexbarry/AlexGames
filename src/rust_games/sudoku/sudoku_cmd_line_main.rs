

//mod sudoku_core;

use alexgames_rust::sudoku::sudoku_core::{self, Pt, State};
use alexgames_rust::sudoku::sudoku_solve;

const puzzles: [ [ [i8;9]; 9]; 0] = [
];

use rand_chacha::rand_core;
use rand::Rng;
use rand_core::{SeedableRng};
use rand_chacha::ChaCha12Rng;


fn solve_main() {

	let mut rng = ChaCha12Rng::from_seed(Default::default());

	let mut state = State::new(9);
	for (puzzle_idx, puzzle) in puzzles.iter().enumerate() {
		state.board = puzzle.iter().map(|row| row.to_vec()).collect();
		//state.print();
		let mut stats = sudoku_solve::Stats::new();
		let mut params = sudoku_solve::Params::new();
		//params.debug = true;
		//params.guessing_allowed = true;
		let mut solved = sudoku_solve::solve(&state, 0, &mut stats, &params, &mut rng);
		if solved.is_none() {
			//params.debug = true;
			solved = sudoku_solve::solve(&state, 0, &mut stats, &params, &mut rng);
			println!("Could not solve puzzle {}", puzzle_idx);
		}
		//assert!(solved);
		println!("stats: {:?}", stats);
	}
}

fn generate_main() {
	let mut state = State::new(9);

	let mut stats = sudoku_solve::Stats::new();
	let mut params = sudoku_solve::Params::new();
	//params.debug = true;
	params.guessing_allowed = true;

	//let mut rng = ChaCha12Rng::from_seed(Default::default());
	let mut seed = [0; 32];
	// seed[0] = 2;
	let mut rng = ChaCha12Rng::from_seed(seed);
	let solved = sudoku_solve::solve(&state, 0, &mut stats, &params, &mut rng);
	let solved = solved.expect("could not solve!");
	//solved.expect("could not solve!").print()

	solved.print();

	let mut gen_params = sudoku_solve::GenParams::new();
	//gen_params.debug = true;
	let generated_puzzle = sudoku_solve::hide_cells(&solved, &gen_params, &mut rng);
	generated_puzzle.print()
}

fn main() {
	//solve_main()
	generate_main()
}
