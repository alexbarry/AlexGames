
use crate::sudoku::sudoku_core::{self, State, Pt, CellInfo};

use std::collections::HashSet;

use bitvec::prelude::{BitVec, Lsb0};

// TODO:
// * store "mode" as part of state, at least for storing saved data.
//   For sharing, this could be dropped to save some bits.

const VERSION1: u8 = 1;
const VERSION2: u8 = 2;

const CURRENT_VERSION: u8 = VERSION2;

fn pt_id(state: &State, pt: &Pt) -> u8 {
	let size = state.size as i32;
	let pt_id = (pt.y * size + pt.x) as u8;
	assert_eq!(pt, &pt_from_pt_id(state, pt_id));
	pt_id
}

fn pt_from_pt_id(state: &State, pt_id: u8) -> Pt {
	let pt_id = pt_id as i32;
	let size = state.size as i32;
	Pt {
		y: pt_id / size,
		x: pt_id % size,
	}
}

fn serialize_notes(state: &State, pt: &Pt) -> Vec<u8> {
	let pt_id = pt_id(state, pt);
	let mut notes = state.user_input_notes[pt.y as usize][pt.x as usize].clone();
	notes.sort();

	assert!(state.size == 9);
	// store bits 0..8 in a u8, will handle 9 separately
	let notes_bits_1_to_8 = (0..8).fold(0u8, |acc, bit_idx| {
		let val = bit_idx + 1;
		let bit = if notes.contains(&val) { 1 } else { 0 };
		acc | (bit << bit_idx)
	});
	let notes_bit_9 = if notes.contains(&9) { 1 } else { 0 };

	// 7 bits for pt_id (up to 81)
	// 1 bit for note for val 9
	//
	// 8 bits for notes 1-8
	assert!( (pt_id & 0x80) == 0);
	let output = vec![ pt_id | (notes_bit_9<<7), notes_bits_1_to_8 ];
	assert_eq!((*pt, notes.clone()), deserialize_notes(state, &output));

	output
}

fn deserialize_notes(state: &State, serialized_note: &[u8]) -> (Pt, Vec<i8>) {
	if serialized_note.len() != 2 {
		panic!("expected 2 bytes passed to deserialize_notes");
	}

	assert!(state.size == 9);

	let pt_id = serialized_note[0] & 0x7f;
	let pt = pt_from_pt_id(state, pt_id);
	let note_bit_9 = (serialized_note[0] >> 7) & 1;

	let notes_bits_1_to_8 = serialized_note[1];
	if pt.y == 8 && pt.x == 7 {
		println!("notes_bits_1_to_8 = {}", notes_bits_1_to_8);
	}
	if notes_bits_1_to_8 != 0 {
		println!("notes_bits_1_to_8 = {}, pt {:?}", notes_bits_1_to_8, pt);
	}
	let mut notes: Vec<i8> = (0u8..8).map(|bit_idx| {
		let val = (bit_idx + 1) as i8;
		if (notes_bits_1_to_8 & (1<<bit_idx) ) != 0 {
			val
		} else {
			0
		}
	})
	.filter(|val| *val != 0)
	.collect();
	notes.sort();

	if note_bit_9 != 0 {
		notes.push(9);
	}

	(pt, notes)
}

pub fn serialize(state: &sudoku_core::State) -> Vec<u8> {
    let mut serialized_state: Vec<u8> = Vec::new();

    serialized_state.push(CURRENT_VERSION);
    serialized_state.push(state.size.try_into().unwrap());

	assert!(state.size < 16);
	let mut board_serialized =
		state.board.iter()
			.flatten()
			.map(|cell_info| cell_info.val)
			.collect::<Vec<_>>()
			.chunks(2)
			.map(|chunk| {
				let a = (chunk[0] & 0xf) as u8;
				let b = (chunk.get(1).copied().unwrap_or(0) & 0xf) as u8;
	
				(a << 4) | b
			})
			.collect::<Vec<_>>();
	assert_eq!(board_serialized.len(), (state.size*state.size).div_ceil(2));
	serialized_state.append(&mut board_serialized);

	let revealed_bitvec_flat: BitVec<u8, Lsb0> = state.board
		.iter()
		.flatten()
		.map(|cell_info| cell_info.revealed)
		.collect();
	let mut revealed_bitvec_flat: Vec<u8> = revealed_bitvec_flat.to_vec().into();
	assert_eq!(revealed_bitvec_flat.len(), bool_u8_ary_size(state.size*state.size));
	serialized_state.append(&mut revealed_bitvec_flat);

	assert!(state.size == 9);
	let mut user_input_serialized = (0..state.size).flat_map(move |y| {
		(0..state.size).flat_map(move |x| {
			let user_input_val = state.user_input[y][x];
			let pt_id = pt_id(state, &Pt {y: y as i32, x: x as i32});
			if user_input_val != 0 {
				return vec![ pt_id , user_input_val as u8 ];
			} else {
				return vec![]
			}
		})
	}).collect::<Vec<_>>();

	serialized_state.push(user_input_serialized.len().try_into().unwrap());
	serialized_state.append(&mut user_input_serialized);

	let mut user_notes_serialized = (0..state.size).flat_map(move |y| {
		(0..state.size).flat_map(move |x| {
			let user_input_notes = &state.user_input_notes[y][x];
			let pt = Pt {y: y as i32, x: x as i32};
			if user_input_notes.len() > 0 {
				return serialize_notes(&state, &pt);
			} else {
				return vec![]
			}
		})
	}).collect::<Vec<_>>();

	serialized_state.push(user_notes_serialized.len().try_into().unwrap());
	serialized_state.append(&mut user_notes_serialized);

	serialized_state.push(match state.mode {
		sudoku_core::Mode::EnterStartingVal => 1,
		sudoku_core::Mode::EnterCellVal => 2,
		sudoku_core::Mode::EnterCellNotes => 3,
	});

	serialized_state
}

fn bool_u8_ary_size(size: usize) -> usize {
	size.div_ceil(8)
}

pub fn deserialize(mut serialized_state: &[u8]) -> sudoku_core::State {
	let version = serialized_state[0];

	if version == VERSION1 {
		// ok
	} else if version == VERSION2 {
		// ok
	} else {
		panic!("Unhandled version {}", version);
	}
    serialized_state = &serialized_state[1..];

	let size = serialized_state[0] as usize;
    serialized_state = &serialized_state[1..];

    let mut state = State::new(size.into());

	let board_len_bytes = (size*size).div_ceil(2);

	let board: Vec<Vec<CellInfo>> = serialized_state[..board_len_bytes]
					.into_iter()
					.flat_map(|byte| {
						let val1 = (byte>>4) & 0xf;
						let val2 = (byte) & 0xf;
						[ val1 as i8, val2 as i8 ]
					})
					.take(size*size)
					.collect::<Vec<_>>()
					.chunks(size.into())
					.map(|chunk| chunk.into_iter().map(|val| CellInfo { val: *val, revealed: *val != 0}).collect())
					.collect();
	assert_eq!(board.len(), size);
	assert_eq!(board[0].len(), size);
    serialized_state = &serialized_state[board_len_bytes..];

	state.board = board;

	if version >= VERSION2 {
		let len = bool_u8_ary_size(size*size);
		let revealed_flat_u8 = &serialized_state[..len];
		serialized_state = &serialized_state[len..];

		let mut revealed_flat = BitVec::<u8, Lsb0>::from_slice(revealed_flat_u8);
		revealed_flat.truncate(size*size);

		let revealed: Vec<Vec<bool>> = revealed_flat
			.chunks(size)
			.map(|row| row.iter().by_vals().collect())
			.collect();
		assert_eq!(state.board.len(), revealed.len());
		for y in 0..state.board.len() {
			assert_eq!(state.board[y].len(), revealed[y].len());
			for x in 0..state.board[y].len() {
				state.board[y][x].revealed = revealed[y][x];
			}
		}
		
	} else if version == VERSION1 {
		/*
		let revealed = state.board.clone()
			.into_iter()
			.map(|row| row.into_iter().map(|cell| cell != 0).collect())
			.collect();
		*/
	}

	let user_input_bytes_len = serialized_state[0] as usize;
    serialized_state = &serialized_state[1..];

	let user_input: Vec<(Pt, i8)> = serialized_state[..user_input_bytes_len]
		//.into_iter()
		.chunks_exact(2)
		.map(|input_bytes| {
			let pt_id = input_bytes[0];
			let val = input_bytes[1];
			( pt_from_pt_id(&state, pt_id), val as i8)
		})
		.collect();
	for (pt, val) in user_input {
		state.user_input[pt.y as usize][pt.x as usize] = val;
	}
    serialized_state = &serialized_state[user_input_bytes_len..];

	let user_input_notes_bytes_len = serialized_state[0] as usize;
    serialized_state = &serialized_state[1..];
	let user_input_notes: Vec<(Pt, Vec<i8>)> = serialized_state[..user_input_notes_bytes_len]
		//.into_iter()
		.chunks_exact(2)
		.map(|input_bytes| {
			deserialize_notes(&state, input_bytes)
		})
		.collect();
	for (pt, val) in user_input_notes {
		state.user_input_notes[pt.y as usize][pt.x as usize] = val;
	}
    serialized_state = &serialized_state[user_input_notes_bytes_len..];

	if serialized_state.len() > 0 {
		let mode_byte = serialized_state[0];
		let mode = match mode_byte {
			1 => sudoku_core::Mode::EnterStartingVal,
			2 => sudoku_core::Mode::EnterCellVal,
			3 => sudoku_core::Mode::EnterCellNotes,
			_ => panic!("unexpected mode value {:?}", mode_byte),
		};
		
		state.mode = mode;
		serialized_state = &serialized_state[1..];
	}

	assert_eq!(serialized_state.len(), 0);

	state
}
