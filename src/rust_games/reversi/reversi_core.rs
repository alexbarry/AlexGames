//use std::io;
use serde::{Deserialize, Serialize};
use std::fmt;
use std::hash::Hash;

pub const BOARD_SIZE: usize = 8;

// TODO make htis serialize into something smaller, I think it might be 4 bytes now.
// Ideally just 2 bits if the serialization library can support that.
// If not, maybe port the code I wrote for minesweeper
#[derive(Copy, Clone, PartialEq, Eq, Serialize, Deserialize, Debug)]
pub enum CellState {
    EMPTY,
    PLAYER1,
    PLAYER2,
}

#[derive(Copy, Clone, PartialEq, Eq, Debug)]
pub enum ReversiErr {
    NotYourTurn,
    InvalidMove,
}

#[derive(PartialEq, Eq, Copy, Clone, Debug, Hash)]
pub struct Pt {
    pub y: i32,
    pub x: i32,
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct State {
    pub board: [[CellState; BOARD_SIZE]; BOARD_SIZE],
    pub player_turn: CellState,

    pub last_move: Option<Pt>,
}

pub const MOVE_PASS: Pt = Pt { y: 9, x: 9 };

impl State {
    pub fn new() -> State {
        let mut state = State {
            board: [[CellState::EMPTY; BOARD_SIZE]; BOARD_SIZE],
            player_turn: CellState::PLAYER1,

            last_move: None,
        };

        state.board[3][3] = CellState::PLAYER1;
        state.board[3][4] = CellState::PLAYER2;
        state.board[4][3] = CellState::PLAYER2;
        state.board[4][4] = CellState::PLAYER1;

        state
    }

    pub fn score(&self, player: CellState) -> i32 {
        let mut score = 0;
        for y in 0..BOARD_SIZE {
            for x in 0..BOARD_SIZE {
                if self.board[y][x] == player {
                    score += 1;
                }
            }
        }
        return score;
    }

    pub fn cell(&self, pt: Pt) -> CellState {
        self.board[pt.y as usize][pt.x as usize]
    }

    fn set_cell(&mut self, pt: Pt, cell: CellState) {
        self.board[pt.y as usize][pt.x as usize] = cell;
    }

    pub fn is_valid_move(&self, player: CellState, pt: Pt) -> bool {
        if self.cell(pt) != CellState::EMPTY {
            return false;
        }

        for dir in DIRS {
            let jumpable_piece_count = get_jumpable_pieces(self, player, pt, dir);
            if jumpable_piece_count > 0 {
                return true;
            }
        }
        return false;
    }

    pub fn get_valid_moves(&self) -> Vec<Pt> {
        let mut moves = Vec::new();
        for y in 0..BOARD_SIZE {
            for x in 0..BOARD_SIZE {
                let pt = Pt {
                    y: y as i32,
                    x: x as i32,
                };
                if self.is_valid_move(self.player_turn, pt) {
                    moves.push(pt);
                }
            }
        }
        // Do this in the AI function instead
        // get_valid_moves is used to check if a pass is a valid option
        /*
                if moves.len() > 0 || self.board_full() {
                    moves
                } else {
                    vec![ MOVE_PASS ]
                }
        */

        moves
    }

    pub fn board_full(&self) -> bool {
        for y in 0..BOARD_SIZE {
            for x in 0..BOARD_SIZE {
                if self.board[y][x] != CellState::EMPTY {
                    return false;
                }
            }
        }
        return true;
    }
}

impl fmt::Display for State {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write_board_to_fmt(self, f)
    }
}

//impl fmt::Debug for State {
//	fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//		write_board_to_fmt(self, f)
//	}
//}

const DIRS: [(i32, i32); 8] = [
    (0, 1),
    (0, -1),
    (1, 0),
    (-1, 0),
    (1, 1),
    (1, -1),
    (-1, 1),
    (-1, -1),
];

// TODO move to struct impl
pub fn _print_board(state: &State) {
    print!("{}", state);
}
fn write_board_to_fmt(state: &State, f: &mut fmt::Formatter) -> fmt::Result {
    write!(f, "  ")?;
    for x in 0..BOARD_SIZE {
        write!(f, "{} ", x)?;
    }
    write!(f, "\n")?;
    write!(f, " +")?;
    for _x in 0..(2 * BOARD_SIZE - 1) {
        write!(f, "-")?;
    }
    write!(f, "+")?;
    write!(f, "\n")?;
    for y in 0..BOARD_SIZE {
        write!(f, "{}|", y)?;
        for x in 0..BOARD_SIZE {
            match state.board[y][x] {
                CellState::EMPTY => write!(f, " ")?,
                CellState::PLAYER1 => write!(f, "x")?,
                CellState::PLAYER2 => write!(f, "o")?,
            }
            write!(f, "|")?;
        }
        write!(f, "\n")?;
        if y < BOARD_SIZE - 1 {
            write!(f, " |")?;
            for _x in 0..(2 * BOARD_SIZE - 1) {
                write!(f, "-")?;
            }
            write!(f, "|")?;
            write!(f, "\n")?;
        }
    }
    write!(f, " +")?;
    for _x in 0..(2 * BOARD_SIZE - 1) {
        write!(f, "-")?;
    }
    write!(f, "+")?;
    write!(f, "\n")?;

    Ok(())
}

fn pos_in_range(pt: Pt) -> bool {
    (0 <= pt.y && pt.y < BOARD_SIZE as i32) && (0 <= pt.x && pt.x < BOARD_SIZE as i32)
}

fn add_pt(pt: &Pt, dir: (i32, i32)) -> Pt {
    Pt {
        x: pt.x + dir.0,
        y: pt.y + dir.1,
    }
}

fn other_player(player: CellState) -> CellState {
    match player {
        CellState::EMPTY => {
            CellState::EMPTY /* TODO crash instead */
        }
        CellState::PLAYER1 => CellState::PLAYER2,
        CellState::PLAYER2 => CellState::PLAYER1,
    }
}

// TODO move to struct impl
fn get_jumpable_pieces(state: &State, player: CellState, start_pt: Pt, dir: (i32, i32)) -> i32 {
    let start_pt_copy = start_pt.clone();
    for i in 1..BOARD_SIZE {
        let pt = add_pt(&start_pt_copy, (dir.0 * i as i32, dir.1 * i as i32));
        if !pos_in_range(pt) {
            break;
        }
        let cell = state.cell(pt);
        //println!("dir={:?}, i={:?}, pt={:?}, cell={:?}", dir, i, pt, cell);
        if cell == CellState::EMPTY {
            break;
        } else if cell == player {
            return i as i32 - 1;
        } else if cell == other_player(player) {
            continue;
        }
    }
    return 0;
}

// TODO move to struct impl
fn reverse_cells(state: &mut State, player: CellState, pt: Pt, dir: (i32, i32)) {
    for i in 1..BOARD_SIZE {
        let pt = add_pt(&pt, (dir.0 * i as i32, dir.1 * i as i32));
        if !pos_in_range(pt) {
            break;
        }
        let cell = state.cell(pt);
        if cell == CellState::EMPTY {
            return;
        } else if cell == player {
            return;
        } else if cell == other_player(player) {
            //println!("reverse_cells: Setting {:?} to {:?}", pt, player);
            state.set_cell(pt, player);
        }
    }
}

// TODO move to struct impl
pub fn player_move(mut state: &mut State, player: CellState, pt: Pt) -> Result<(), ReversiErr> {
    if state.player_turn != player {
        return Err(ReversiErr::NotYourTurn);
    }

    if pt == MOVE_PASS {
        //println!("Player tried to pass...");
        if (&state).get_valid_moves().len() > 0 {
            //println!("pass failed because valid moves len > 0!");
            return Err(ReversiErr::InvalidMove);
        } else {
            //println!("pass succeeded");
            state.player_turn = other_player(state.player_turn);
            return Ok(());
        }
    }

    if !pos_in_range(pt) {
        return Err(ReversiErr::InvalidMove);
    }

    if state.cell(pt) != CellState::EMPTY {
        return Err(ReversiErr::InvalidMove);
    }

    let pt = Pt { y: pt.y, x: pt.x };

    let mut can_move = false;
    for dir in DIRS {
        let jumpable_piece_count = get_jumpable_pieces(&state, player, pt, dir);
        //println!("dir={:?}, jumpable_piece_count={}", dir, jumpable_piece_count);
        if jumpable_piece_count > 0 {
            reverse_cells(&mut state, player, pt, dir);
            can_move = true;
        }
    }

    if !can_move {
        return Err(ReversiErr::InvalidMove);
    }

    //println!("player_move: setting cell {:?} to {:?}", pt, player);
    state.set_cell(pt, player);
    state.last_move = Some(pt);
    state.player_turn = other_player(state.player_turn);

    Ok(())
}
