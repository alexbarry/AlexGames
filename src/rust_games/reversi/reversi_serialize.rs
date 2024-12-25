//use bincode;

use crate::reversi::reversi_core;
use crate::reversi::reversi_core::{CellState, Pt, State, BOARD_SIZE};

use serde::{Deserialize, Serialize};

//use bitpacking::{BitPacker1x, BitPacker};
use crate::libs::bitpack;

use static_assertions::const_assert;

#[derive(Serialize, Deserialize, Debug)]
#[repr(u8)]
enum Version {
    // reserving 0-2 for the initial 264 byte version without a version code.
    // the first byte is the top left cell, which should be [0,2] for empty or player 1/2
    Version1 = 1,

    // added version code field, "last move" field, used fewer bytes per enum
    Version3 = 3,
}

//#[derive(Serialize, Deserialize, Debug)]
#[derive(Debug)]
struct StateWithMetadata {
    version: Version,
    state: State,
}

pub fn deserialize(serialized_state: &Vec<u8>) -> Result<State, ()> {
    // For this one, I forgot to add a version field and
    // used default serde bincode params which used 4 bytes per enum:
    // 8*8 u32 for the board, one u32 for the player turn, and one more u32 for the session ID
    if serialized_state.len() == 264 {
        return deserialize_v1(serialized_state);
    } else {
        let version = serialized_state[0];
        assert_eq!(version, 3);
        //let version: Version = version.try_into().unwrap();
        //assert_eq!(version, Version::Version3);

        let serialized_state = &serialized_state[1..serialized_state.len()];

        let val_count = BOARD_SIZE * BOARD_SIZE;
        let max_value = 2;
        let mut unpacked_bytes = Vec::<u8>::new();
        bitpack::bitunpack(
            &serialized_state,
            val_count,
            max_value,
            |byte_val: u8, _index: usize| {
                unpacked_bytes.push(byte_val);
            },
        );

        assert_eq!(unpacked_bytes.len(), BOARD_SIZE * BOARD_SIZE);

        let mut state = State::new();
        for y in 0..BOARD_SIZE {
            for x in 0..BOARD_SIZE {
                let i = y * BOARD_SIZE + x;
                state.board[y][x] = match unpacked_bytes[i] {
                    0 => CellState::EMPTY,
                    1 => CellState::PLAYER1,
                    2 => CellState::PLAYER2,
                    _ => {
                        panic!(
                            "Unexpected value {} when deserializing at pos {}",
                            unpacked_bytes[i], i
                        );
                    }
                };
            }
        }
        let more_data_byte = serialized_state[16]; // TODO get size of previous thing
        println!("received data byte {}", more_data_byte);
        state.player_turn = match (more_data_byte & (1 << 7)) > 0 {
            false => CellState::PLAYER1,
            true => CellState::PLAYER2,
        };
        let more_data_byte = more_data_byte & 0b1_111_111;
        assert_eq!(BOARD_SIZE - 1, 0b111);
        state.last_move = match more_data_byte {
            0b1_000_000 => None,
            _ => Some(Pt {
                y: (more_data_byte >> 3) as i32,
                x: (more_data_byte & 0b111) as i32,
            }),
        };
        Ok(state)
    }
}

pub fn serialize(state: &State) -> Result<Vec<u8>, ()> {
    let state_w_metadata = StateWithMetadata {
        version: Version::Version3,
        state: state.clone(),
    };

    let mut serialized = Vec::<u8>::new();
    serialized.push(state_w_metadata.version as u8);
    let max_val = 2;
    let val_count = BOARD_SIZE * BOARD_SIZE;
    let get_val = |i: usize| -> u8 {
        let y = i / BOARD_SIZE;
        let x = i % BOARD_SIZE;
        state_w_metadata.state.board[y][x] as u8
    };
    serialized.extend(&bitpack::bitpack(&get_val, val_count, max_val));
    let player_turn_serialized = match state_w_metadata.state.player_turn {
        CellState::PLAYER1 => 0u8,
        CellState::PLAYER2 => 1u8,
        CellState::EMPTY => {
            panic!("received 'empty' for player turn, invalid");
        }
    };
    let last_move_serialized = match state_w_metadata.state.last_move {
        Some(pt) => (pt.y as u8) << 3 | (pt.x as u8) << 0,
        None => 0b1000000,
    };

    serialized.push((player_turn_serialized << 7) | last_move_serialized);

    Ok(serialized)
}

const SIZEOF_U32: usize = 4;
const_assert!(BOARD_SIZE == 8);
// board, player turn, and session ID
const_assert!(SIZEOF_U32 * (BOARD_SIZE * BOARD_SIZE + 2) == 264);

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
            let i = (y * BOARD_SIZE + x) * SIZEOF_U32;
            assert_eq!(
                serialized_state[i + 1],
                0,
                "Expected byte {} to be zero, was {}",
                i + 1,
                serialized_state[i + 1]
            );
            assert_eq!(
                serialized_state[i + 2],
                0,
                "Expected byte {} to be zero, was {}",
                i + 2,
                serialized_state[i + 2]
            );
            assert_eq!(
                serialized_state[i + 3],
                0,
                "Expected byte {} to be zero, was {}",
                i + 3,
                serialized_state[i + 3]
            );

            let offset = 0;
            state.board[y][x] = match serialized_state[i + offset] {
                0 => CellState::EMPTY,
                1 => CellState::PLAYER1,
                2 => CellState::PLAYER2,
                _ => {
                    panic!(
                        "Expected byte {} to be between [0,2], was {}",
                        i + offset,
                        serialized_state[i + offset]
                    );
                }
            };
        }
    }

    let offset = SIZEOF_U32 * BOARD_SIZE * BOARD_SIZE;

    state.player_turn = match serialized_state[offset] {
        1 => CellState::PLAYER1,
        2 => CellState::PLAYER2,
        _ => {
            panic!(
                "Expected byte {} to be [1,2] for player turn, was {}",
                offset, serialized_state[offset]
            );
        }
    };
    assert_eq!(
        serialized_state[offset + 1],
        0,
        "Expected byte {} to be zero, was {}",
        offset + 1,
        serialized_state[offset + 1]
    );
    assert_eq!(
        serialized_state[offset + 2],
        0,
        "Expected byte {} to be zero, was {}",
        offset + 2,
        serialized_state[offset + 2]
    );
    assert_eq!(
        serialized_state[offset + 3],
        0,
        "Expected byte {} to be zero, was {}",
        offset + 3,
        serialized_state[offset + 3]
    );

    let offset = offset + SIZEOF_U32;
    let session_id_bytes = &serialized_state[offset..(offset + SIZEOF_U32)];
    let session_id_bytes: [u8; 4] = session_id_bytes.try_into().unwrap();
    let session_id = i32::from_le_bytes(session_id_bytes);

    println!("read session_id {}", session_id);

    let offset = offset + SIZEOF_U32;
    assert_eq!(
        offset, 264,
        "Expected to have parsed all 264 bytes but offset is {}",
        offset
    );

    Ok(state)
}
