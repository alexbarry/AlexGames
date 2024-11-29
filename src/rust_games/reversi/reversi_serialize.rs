
use crate::reversi::reversi_core;
use crate::reversi::reversi_core::{Pt, ReversiErr, CellState, State, BOARD_SIZE};

use static_assertions::const_assert;

pub fn deserialize(serialized_state: &Vec<u8>) -> Result<State, ()> {
	// For this one, I forgot to add a version field and
	// used default serde bincode params which used 4 bytes per enum:
	// 8*8 u32 for the board, one u32 for the player turn, and one more u32 for the session ID
	if serialized_state.len() == 264 {
		return deserialize_v1(serialized_state);
	} else {
		panic!("not implemented yet");
	}
}

const sizeof_u32: usize = 4;
const_assert!(BOARD_SIZE == 8);
// board, player turn, and session ID
const_assert!(sizeof_u32*(BOARD_SIZE*BOARD_SIZE + 2) == 264);

//#[derive(Serialize, Deserialize, Debug)]
//pub struct State {
//    bytes 0 to 4 * 8 * 8 are the board, 4 bytes per enum for some reason
//    pub board: [[CellState; BOARD_SIZE]; BOARD_SIZE],
//
//    4 bytes starting at 4*8*8 for the player turn
//    pub player_turn: CellState,
//
//    4 bytes starting at 4*8*8 + 4 for the session ID
//    pub session_id: i32,
//}
fn deserialize_v1(serialized_state: &Vec<u8>) -> Result<State, ()> {
	let mut state = reversi_core::State::new();

	for y in 0..BOARD_SIZE {
		for x in 0..BOARD_SIZE {
			let i = (y * BOARD_SIZE + x) * sizeof_u32;
			assert_eq!(serialized_state[i+1], 0, "Expected byte {} to be zero, was {}", i+1, serialized_state[i+1]);
			assert_eq!(serialized_state[i+2], 0, "Expected byte {} to be zero, was {}", i+2, serialized_state[i+2]);
			assert_eq!(serialized_state[i+3], 0, "Expected byte {} to be zero, was {}", i+3, serialized_state[i+3]);

			let offset = 0;
			state.board[y][x] = match serialized_state[i+offset] {
				0 => CellState::EMPTY,
				1 => CellState::PLAYER1,
				2 => CellState::PLAYER2,
				_ => { panic!("Expected byte {} to be between [0,2], was {}", i+offset, serialized_state[i+offset]); },
			};
		}
	}

	let offset = sizeof_u32 * BOARD_SIZE * BOARD_SIZE;

	state.player_turn = match serialized_state[offset] {
		1 => CellState::PLAYER1,
		2 => CellState::PLAYER2,
		_ => { panic!("Expected byte {} to be [1,2] for player turn, was {}", offset, serialized_state[offset]); },
	};
	assert_eq!(serialized_state[offset+1], 0, "Expected byte {} to be zero, was {}", offset+1, serialized_state[offset+1]);
	assert_eq!(serialized_state[offset+2], 0, "Expected byte {} to be zero, was {}", offset+2, serialized_state[offset+2]);
	assert_eq!(serialized_state[offset+3], 0, "Expected byte {} to be zero, was {}", offset+3, serialized_state[offset+3]);

	let offset = offset + sizeof_u32;
	let session_id_bytes = &serialized_state[offset..(offset + sizeof_u32)];
	let session_id_bytes: [u8; 4] = session_id_bytes.try_into().unwrap();
	let session_id = i32::from_le_bytes(session_id_bytes);

	println!("read session_id {}", session_id);

	let offset = offset + sizeof_u32;
	assert_eq!(offset, 264, "Expected to have parsed all 264 bytes but offset is {}", offset);

	Ok(state)
}
