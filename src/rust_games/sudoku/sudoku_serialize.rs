
use crate::sudoku::sudoku_core::{self, State, Pt};

// TODO:
// * add user input, perhaps in same format as notes?
// * add notes, probably with pt using 4 bits for y, 4 for x, and 9 for notes
//   actually should convert pt value to (y*9+x) into 7 bits, then can use extra bit for bit 9 of notes

const VERSION: u8 = 1;

pub fn serialize(state: &sudoku_core::State) -> Vec<u8> {
    let mut serialized_state: Vec<u8> = Vec::new();

    serialized_state.push(VERSION);
    serialized_state.push(state.size.try_into().unwrap());

	assert!(state.size < 16);
	let mut board_serialized =
		state.board.iter()
			.flatten()
			.collect::<Vec<_>>()
			.chunks(2)
			.map(|chunk| {
				let a = (chunk[0] & 0xf) as u8;
				let b = (chunk.get(1).copied().unwrap_or(&0) & 0xf) as u8;
	
				(a << 4) | b
			})
			.collect::<Vec<_>>();
	assert_eq!(board_serialized.len(), (state.size*state.size).div_ceil(2));
	serialized_state.append(&mut board_serialized);

	serialized_state
}

pub fn deserialize(mut serialized_state: &[u8]) -> sudoku_core::State {
	let version = serialized_state[0];
    assert!(
        version == VERSION,
        "Unhandled serialized state version {}",
        version
    );
    serialized_state = &serialized_state[1..];

	let size = serialized_state[0] as usize;
    serialized_state = &serialized_state[1..];

	let board_len_bytes = (size*size).div_ceil(2);

	assert_eq!(serialized_state.len(), board_len_bytes);
	let board: Vec<Vec<i8>> = serialized_state[..board_len_bytes]
					.into_iter()
					.flat_map(|byte| {
						let val1 = (byte>>4) & 0xf;
						let val2 = (byte) & 0xf;
						[ val1 as i8, val2 as i8 ]
					})
					.take(size*size)
					.collect::<Vec<_>>()
					.chunks(size.into())
					.map(|chunk| chunk.to_vec())
					.collect();
	assert_eq!(board.len(), size);
	assert_eq!(board[0].len(), size);

    let mut state = State::new(size.into());
	state.board = board;

	state
}
