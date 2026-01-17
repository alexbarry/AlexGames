
use crate::libs::cards::{self, Card};
use crate::free_cell::free_cell_core::{self, State};

const FREE_CELL_SERIALIZED_STATE_VERSION: u8 = 1;

fn read_bytes(serialized_data: &[u8], len: usize) -> (&[u8], &[u8]) {
	(&serialized_data[0..len], &serialized_data[len..])
}

fn read_array(serialized_data: &[u8]) -> Option<(&[u8], &[u8])> {
	if serialized_data.is_empty() {
		return None;
	}

	let len = serialized_data[0] as usize;

	if serialized_data.len() < len + 1 {
		panic!("Malformed data, expected {} more bytes, only had {}", len + 1, serialized_data.len());
	}

	let array = &serialized_data[1..len+1];
	let remaining = &serialized_data[len+1..];

	Some((array, remaining))
}

fn cards_to_bytearray(cards: &Vec<Card>) -> Vec<u8> {
	let mut output = Vec::with_capacity(cards.len() + 1);
	output.push(cards.len() as u8);
	output.extend(cards.iter().map(cards::card_to_num));
	output
}

pub fn serialize_state(game_state: &State) -> Vec<u8> {
	let mut serialized_state: Vec<u8> = Vec::new();

	serialized_state.push(FREE_CELL_SERIALIZED_STATE_VERSION);

	for cell in game_state.cells.iter() {
		serialized_state.push(cards::card_to_num_opt(cell));
	}

	for goal in game_state.goals.iter() {
		serialized_state.extend(cards_to_bytearray(&goal));
	}

	for play_col in game_state.play_area.iter() {
		serialized_state.extend(cards_to_bytearray(&play_col));
	}

	serialized_state
}

pub fn deserialize_state(mut serialized_state: &[u8]) -> State {
	let version = serialized_state[0];
	assert!(version == FREE_CELL_SERIALIZED_STATE_VERSION, "Unhandled serialized state version {}", version);

	let mut state = State::new();

	serialized_state = &serialized_state[1..];


	//let (cell_ary, serialized_state) = read_array(serialized_state).expect("no cell ary present?");
	let (cell_ary, mut serialized_state) = read_bytes(serialized_state, free_cell_core::BOARD_CELL_COUNT);
	state.cells = cell_ary.iter().map(|num: &u8| cards::num_to_card(*num)).collect::<Vec<Option<Card>>>().try_into().expect("cell ary not correct len?");

	for goal_idx in 0..free_cell_core::GOAL_COLUMN_COUNT {
		let (goal_col, new_serialized_state) = read_array(serialized_state).expect("goal ary missing?");
		serialized_state = new_serialized_state;
		state.goals[goal_idx] = goal_col.iter().map(|num: &u8| cards::num_to_card(*num).unwrap()).collect();
	}

	for col_idx in 0..free_cell_core::PLAY_AREA_COLUMN_COUNT {
		let (col, new_serialized_state) = read_array(serialized_state).expect("play area col ary missing?");
		serialized_state = new_serialized_state;
		state.play_area[col_idx] = col.iter().map(|num: &u8| cards::num_to_card(*num).unwrap()).collect();
	}

	state

}
