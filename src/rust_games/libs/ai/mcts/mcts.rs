use rand::Rng;

// TODO move these structs to the general AI crate,
// and maybe make a "random" implementation of AI,
// then make MCTS separate


//pub struct MCTSParams<GameState> {
pub struct MCTSParams<GameState, GameMove> {
	//get_game_state: fn(GameState) -> String,
	pub get_possible_moves: fn(GameState) -> Vec<GameMove>,
}

pub struct MCTSState<GameState, GameMove> {
	get_possible_moves: fn(GameState) -> Vec<GameMove>,

}

impl<GameState, GameMove> MCTSState<GameState, GameMove>
	where
		GameState: Copy + std::fmt::Debug,
		GameMove: Copy + std::fmt::Debug,
{

	pub fn init(params: MCTSParams<GameState, GameMove>) -> MCTSState<GameState, GameMove> {
		MCTSState::<GameState, GameMove> {
			get_possible_moves: params.get_possible_moves,
		}
	}

	pub fn get_move(&self, game_state: GameState) -> Option<GameMove> {
		let moves = (self.get_possible_moves)(game_state);
		//println!("AI get_move called with state: {:?}", game_state);
		//println!("AI get_move found {} possible moves", moves.len());

		let random_index = rand::thread_rng().gen_range(0..moves.len());
		return Some(moves[random_index]);
	}

	fn get_possible_moves(&self, game_state: GameState) -> Vec<GameMove> {
		return (self.get_possible_moves)(game_state);
	}
}

