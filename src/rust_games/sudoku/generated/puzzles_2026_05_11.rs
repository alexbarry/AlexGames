
use crate::sudoku::sudoku_core::CellInfo;

const fn val(val: i8, revealed_int: i8) -> CellInfo {
        CellInfo::new(val, revealed_int)
}

#[rustfmt::skip]
pub const puzzles: [ [[CellInfo;9];9]; 200] = [
    // Puzzle 1 of 200
    [
        [val(7,0),val(9,0),val(8,0),  val(6,0),val(5,0),val(3,0),  val(2,0),val(4,1),val(1,0)],
        [val(4,0),val(1,0),val(2,0),  val(7,0),val(8,1),val(9,1),  val(6,0),val(5,0),val(3,0)],
        [val(3,1),val(5,0),val(6,0),  val(4,0),val(1,0),val(2,0),  val(9,0),val(8,1),val(7,0)],

        [val(2,0),val(6,0),val(4,1),  val(5,1),val(3,1),val(7,0),  val(8,0),val(1,0),val(9,0)],
        [val(1,0),val(7,0),val(9,0),  val(8,0),val(6,0),val(4,0),  val(5,1),val(3,0),val(2,1)],
        [val(8,1),val(3,0),val(5,0),  val(2,1),val(9,0),val(1,0),  val(4,0),val(7,1),val(6,0)],

        [val(9,1),val(2,0),val(7,1),  val(1,1),val(4,0),val(5,0),  val(3,1),val(6,0),val(8,0)],
        [val(6,1),val(4,0),val(3,0),  val(9,0),val(7,0),val(8,1),  val(1,0),val(2,0),val(5,0)],
        [val(5,0),val(8,1),val(1,0),  val(3,1),val(2,1),val(6,0),  val(7,1),val(9,0),val(4,1)],
    ],

    // Puzzle 2 of 200
    [
        [val(1,0),val(3,0),val(6,0),  val(9,1),val(2,0),val(7,1),  val(8,0),val(5,0),val(4,0)],
        [val(7,0),val(8,1),val(4,0),  val(1,0),val(5,0),val(6,0),  val(9,1),val(3,0),val(2,1)],
        [val(9,0),val(5,1),val(2,0),  val(8,0),val(3,1),val(4,1),  val(1,0),val(7,0),val(6,0)],

        [val(5,0),val(6,1),val(1,1),  val(7,0),val(9,0),val(2,0),  val(4,0),val(8,1),val(3,1)],
        [val(2,1),val(4,1),val(7,0),  val(3,0),val(1,0),val(8,0),  val(6,0),val(9,0),val(5,0)],
        [val(3,0),val(9,0),val(8,0),  val(4,1),val(6,0),val(5,1),  val(7,0),val(2,1),val(1,1)],

        [val(4,0),val(7,0),val(5,0),  val(2,0),val(8,1),val(1,0),  val(3,0),val(6,1),val(9,0)],
        [val(8,0),val(2,0),val(3,1),  val(6,1),val(4,0),val(9,0),  val(5,0),val(1,0),val(7,1)],
        [val(6,0),val(1,1),val(9,0),  val(5,0),val(7,0),val(3,0),  val(2,0),val(4,0),val(8,0)],
    ],

    // Puzzle 3 of 200
    [
        [val(2,1),val(7,1),val(1,0),  val(8,1),val(6,0),val(4,0),  val(5,0),val(3,0),val(9,0)],
        [val(9,0),val(6,0),val(8,0),  val(2,1),val(5,0),val(3,0),  val(7,1),val(1,0),val(4,1)],
        [val(3,0),val(4,0),val(5,1),  val(1,0),val(9,0),val(7,0),  val(2,0),val(6,0),val(8,1)],

        [val(5,0),val(2,1),val(3,1),  val(4,0),val(8,0),val(9,0),  val(6,1),val(7,0),val(1,0)],
        [val(4,0),val(8,1),val(6,0),  val(7,1),val(2,1),val(1,1),  val(3,0),val(9,0),val(5,1)],
        [val(1,0),val(9,0),val(7,0),  val(6,0),val(3,1),val(5,0),  val(8,0),val(4,1),val(2,0)],

        [val(7,0),val(5,0),val(9,0),  val(3,1),val(4,0),val(2,0),  val(1,0),val(8,1),val(6,0)],
        [val(8,1),val(1,1),val(2,0),  val(9,0),val(7,0),val(6,0),  val(4,1),val(5,0),val(3,0)],
        [val(6,1),val(3,0),val(4,0),  val(5,1),val(1,0),val(8,0),  val(9,1),val(2,0),val(7,0)],
    ],

    // Puzzle 4 of 200
    [
        [val(4,0),val(1,0),val(9,0),  val(3,0),val(5,1),val(2,0),  val(6,1),val(7,0),val(8,0)],
        [val(7,0),val(8,0),val(5,0),  val(9,1),val(1,1),val(6,0),  val(4,1),val(3,0),val(2,1)],
        [val(6,0),val(2,0),val(3,1),  val(8,0),val(7,0),val(4,0),  val(9,0),val(5,0),val(1,1)],

        [val(8,0),val(3,0),val(7,0),  val(6,0),val(2,1),val(9,1),  val(5,0),val(1,0),val(4,0)],
        [val(1,1),val(9,0),val(4,0),  val(7,0),val(3,1),val(5,0),  val(2,1),val(8,0),val(6,1)],
        [val(2,0),val(5,1),val(6,1),  val(4,1),val(8,0),val(1,0),  val(7,0),val(9,0),val(3,0)],

        [val(9,0),val(6,1),val(8,0),  val(5,1),val(4,0),val(3,0),  val(1,0),val(2,0),val(7,1)],
        [val(3,0),val(4,1),val(2,0),  val(1,0),val(9,1),val(7,1),  val(8,0),val(6,0),val(5,0)],
        [val(5,0),val(7,0),val(1,1),  val(2,0),val(6,0),val(8,0),  val(3,1),val(4,0),val(9,0)],
    ],

    // Puzzle 5 of 200
    [
        [val(5,1),val(2,0),val(8,1),  val(3,0),val(1,0),val(7,0),  val(6,1),val(9,0),val(4,0)],
        [val(9,0),val(1,0),val(7,0),  val(2,0),val(6,1),val(4,1),  val(5,0),val(8,0),val(3,0)],
        [val(6,0),val(3,0),val(4,0),  val(5,0),val(9,1),val(8,0),  val(2,1),val(1,0),val(7,0)],

        [val(7,1),val(6,0),val(9,0),  val(1,1),val(3,0),val(2,1),  val(4,1),val(5,1),val(8,1)],
        [val(1,1),val(8,0),val(2,0),  val(7,0),val(4,0),val(5,0),  val(3,0),val(6,0),val(9,1)],
        [val(4,0),val(5,0),val(3,1),  val(9,0),val(8,0),val(6,0),  val(7,0),val(2,1),val(1,0)],

        [val(8,0),val(4,1),val(1,0),  val(6,0),val(5,0),val(3,0),  val(9,0),val(7,0),val(2,0)],
        [val(2,1),val(9,0),val(6,1),  val(4,1),val(7,0),val(1,1),  val(8,0),val(3,1),val(5,0)],
        [val(3,0),val(7,0),val(5,0),  val(8,1),val(2,0),val(9,0),  val(1,1),val(4,0),val(6,0)],
    ],

    // Puzzle 6 of 200
    [
        [val(7,1),val(4,0),val(5,1),  val(2,0),val(1,1),val(8,0),  val(6,1),val(9,0),val(3,0)],
        [val(1,1),val(9,0),val(6,0),  val(4,1),val(5,0),val(3,0),  val(2,1),val(7,0),val(8,1)],
        [val(8,0),val(2,1),val(3,1),  val(6,0),val(7,0),val(9,0),  val(4,0),val(5,1),val(1,0)],

        [val(2,0),val(8,0),val(4,0),  val(9,0),val(6,1),val(5,1),  val(1,1),val(3,0),val(7,0)],
        [val(5,1),val(6,1),val(7,0),  val(1,1),val(3,1),val(4,0),  val(9,0),val(8,0),val(2,1)],
        [val(9,1),val(3,0),val(1,0),  val(7,0),val(8,0),val(2,0),  val(5,0),val(4,1),val(6,0)],

        [val(6,0),val(7,0),val(9,0),  val(8,1),val(4,0),val(1,0),  val(3,0),val(2,0),val(5,0)],
        [val(3,0),val(1,0),val(2,0),  val(5,0),val(9,0),val(7,1),  val(8,0),val(6,0),val(4,0)],
        [val(4,0),val(5,0),val(8,0),  val(3,0),val(2,1),val(6,0),  val(7,1),val(1,0),val(9,0)],
    ],

    // Puzzle 7 of 200
    [
        [val(2,0),val(7,1),val(6,1),  val(4,0),val(1,1),val(9,0),  val(3,0),val(5,0),val(8,0)],
        [val(5,0),val(9,0),val(4,0),  val(3,0),val(2,1),val(8,1),  val(1,0),val(6,1),val(7,0)],
        [val(1,0),val(8,0),val(3,0),  val(6,0),val(7,1),val(5,0),  val(9,1),val(2,0),val(4,0)],

        [val(7,0),val(6,1),val(1,0),  val(8,0),val(5,0),val(3,0),  val(2,0),val(4,1),val(9,0)],
        [val(8,1),val(4,0),val(2,0),  val(1,0),val(9,1),val(7,0),  val(5,0),val(3,1),val(6,0)],
        [val(9,0),val(3,0),val(5,0),  val(2,0),val(4,0),val(6,0),  val(7,1),val(8,0),val(1,0)],

        [val(6,0),val(2,0),val(9,1),  val(7,0),val(3,0),val(4,0),  val(8,1),val(1,1),val(5,0)],
        [val(3,0),val(5,1),val(8,0),  val(9,1),val(6,1),val(1,0),  val(4,0),val(7,0),val(2,0)],
        [val(4,1),val(1,0),val(7,0),  val(5,1),val(8,0),val(2,1),  val(6,1),val(9,0),val(3,0)],
    ],

    // Puzzle 8 of 200
    [
        [val(3,0),val(1,1),val(4,1),  val(6,0),val(2,0),val(9,0),  val(8,1),val(5,0),val(7,0)],
        [val(2,1),val(8,0),val(7,0),  val(4,0),val(1,0),val(5,1),  val(6,1),val(9,0),val(3,0)],
        [val(9,0),val(5,0),val(6,0),  val(3,0),val(7,1),val(8,0),  val(2,0),val(4,0),val(1,1)],

        [val(6,1),val(4,0),val(2,1),  val(8,0),val(9,0),val(1,0),  val(7,0),val(3,0),val(5,0)],
        [val(1,0),val(9,0),val(3,0),  val(5,0),val(6,0),val(7,1),  val(4,0),val(8,0),val(2,0)],
        [val(8,1),val(7,0),val(5,1),  val(2,0),val(3,0),val(4,1),  val(1,0),val(6,0),val(9,1)],

        [val(4,0),val(3,0),val(1,0),  val(7,0),val(5,0),val(6,1),  val(9,0),val(2,0),val(8,1)],
        [val(7,0),val(2,1),val(8,0),  val(9,1),val(4,0),val(3,0),  val(5,0),val(1,0),val(6,0)],
        [val(5,1),val(6,0),val(9,0),  val(1,0),val(8,0),val(2,1),  val(3,1),val(7,1),val(4,0)],
    ],

    // Puzzle 9 of 200
    [
        [val(4,0),val(6,0),val(8,1),  val(7,1),val(2,0),val(3,0),  val(1,0),val(5,1),val(9,1)],
        [val(3,0),val(2,0),val(1,0),  val(5,1),val(9,0),val(8,1),  val(7,0),val(6,0),val(4,0)],
        [val(9,1),val(7,0),val(5,0),  val(1,0),val(6,0),val(4,0),  val(3,1),val(2,1),val(8,0)],

        [val(1,0),val(8,0),val(6,0),  val(9,1),val(4,0),val(7,1),  val(2,0),val(3,0),val(5,1)],
        [val(7,0),val(3,0),val(9,0),  val(2,0),val(8,0),val(5,0),  val(4,0),val(1,0),val(6,0)],
        [val(5,1),val(4,0),val(2,1),  val(6,0),val(3,1),val(1,0),  val(9,1),val(8,0),val(7,0)],

        [val(2,0),val(5,0),val(4,0),  val(3,0),val(7,0),val(6,1),  val(8,0),val(9,0),val(1,0)],
        [val(6,0),val(9,0),val(7,1),  val(8,0),val(1,0),val(2,1),  val(5,0),val(4,1),val(3,0)],
        [val(8,0),val(1,1),val(3,1),  val(4,0),val(5,0),val(9,0),  val(6,1),val(7,0),val(2,0)],
    ],

    // Puzzle 10 of 200
    [
        [val(4,0),val(1,1),val(9,0),  val(5,0),val(7,1),val(6,0),  val(8,0),val(2,1),val(3,1)],
        [val(7,0),val(3,0),val(8,0),  val(9,1),val(4,0),val(2,0),  val(5,1),val(6,0),val(1,0)],
        [val(5,0),val(6,0),val(2,0),  val(8,0),val(3,1),val(1,0),  val(9,1),val(4,0),val(7,1)],

        [val(8,1),val(9,0),val(5,1),  val(7,0),val(2,0),val(3,0),  val(4,1),val(1,0),val(6,1)],
        [val(1,0),val(4,1),val(3,0),  val(6,0),val(9,0),val(5,1),  val(7,0),val(8,0),val(2,0)],
        [val(2,0),val(7,1),val(6,1),  val(1,0),val(8,0),val(4,1),  val(3,0),val(5,0),val(9,0)],

        [val(3,1),val(8,1),val(4,1),  val(2,0),val(1,0),val(9,0),  val(6,0),val(7,1),val(5,0)],
        [val(6,0),val(2,0),val(7,1),  val(3,0),val(5,0),val(8,0),  val(1,0),val(9,1),val(4,1)],
        [val(9,0),val(5,1),val(1,0),  val(4,0),val(6,0),val(7,0),  val(2,0),val(3,1),val(8,0)],
    ],

    // Puzzle 11 of 200
    [
        [val(7,0),val(4,0),val(6,0),  val(8,1),val(1,0),val(9,0),  val(3,1),val(5,0),val(2,0)],
        [val(8,0),val(9,1),val(2,0),  val(3,0),val(6,0),val(5,0),  val(1,0),val(4,0),val(7,0)],
        [val(1,1),val(5,1),val(3,0),  val(7,0),val(4,0),val(2,1),  val(6,1),val(8,0),val(9,0)],

        [val(3,1),val(7,0),val(9,1),  val(6,1),val(5,0),val(1,1),  val(4,0),val(2,0),val(8,0)],
        [val(5,0),val(1,0),val(4,0),  val(2,0),val(8,0),val(3,1),  val(7,0),val(9,0),val(6,0)],
        [val(6,0),val(2,0),val(8,1),  val(4,0),val(9,1),val(7,0),  val(5,0),val(1,1),val(3,0)],

        [val(9,0),val(8,0),val(7,0),  val(5,0),val(3,1),val(4,0),  val(2,1),val(6,0),val(1,1)],
        [val(4,0),val(3,0),val(1,0),  val(9,1),val(2,1),val(6,0),  val(8,0),val(7,1),val(5,0)],
        [val(2,0),val(6,1),val(5,1),  val(1,0),val(7,0),val(8,0),  val(9,0),val(3,0),val(4,0)],
    ],

    // Puzzle 12 of 200
    [
        [val(2,0),val(9,0),val(8,1),  val(1,0),val(7,1),val(6,0),  val(5,0),val(4,0),val(3,1)],
        [val(3,0),val(6,0),val(4,1),  val(5,0),val(9,0),val(8,0),  val(2,0),val(7,1),val(1,0)],
        [val(5,1),val(7,0),val(1,0),  val(2,1),val(3,0),val(4,0),  val(9,0),val(8,0),val(6,0)],

        [val(6,0),val(2,0),val(3,1),  val(7,0),val(4,0),val(5,0),  val(1,0),val(9,1),val(8,0)],
        [val(9,0),val(8,1),val(5,0),  val(3,0),val(6,0),val(1,1),  val(4,0),val(2,0),val(7,1)],
        [val(1,0),val(4,1),val(7,1),  val(8,1),val(2,0),val(9,1),  val(3,0),val(6,1),val(5,0)],

        [val(8,0),val(3,0),val(9,0),  val(4,0),val(1,0),val(7,1),  val(6,0),val(5,0),val(2,0)],
        [val(4,1),val(5,0),val(2,1),  val(6,1),val(8,1),val(3,0),  val(7,0),val(1,0),val(9,0)],
        [val(7,0),val(1,1),val(6,0),  val(9,0),val(5,1),val(2,0),  val(8,0),val(3,0),val(4,1)],
    ],

    // Puzzle 13 of 200
    [
        [val(9,1),val(5,0),val(7,0),  val(8,0),val(4,0),val(3,0),  val(6,0),val(2,0),val(1,1)],
        [val(8,1),val(3,0),val(2,0),  val(6,0),val(1,0),val(7,0),  val(9,0),val(5,1),val(4,1)],
        [val(1,0),val(4,0),val(6,1),  val(9,0),val(2,1),val(5,0),  val(7,0),val(8,0),val(3,0)],

        [val(5,0),val(8,0),val(9,1),  val(3,1),val(6,0),val(2,0),  val(1,0),val(4,1),val(7,0)],
        [val(2,0),val(7,1),val(4,0),  val(1,1),val(9,0),val(8,0),  val(3,0),val(6,0),val(5,0)],
        [val(6,0),val(1,0),val(3,0),  val(7,0),val(5,1),val(4,0),  val(8,1),val(9,0),val(2,0)],

        [val(3,0),val(2,1),val(1,0),  val(5,1),val(8,1),val(6,0),  val(4,0),val(7,1),val(9,0)],
        [val(7,0),val(6,0),val(5,0),  val(4,1),val(3,0),val(9,1),  val(2,1),val(1,0),val(8,0)],
        [val(4,0),val(9,0),val(8,0),  val(2,0),val(7,0),val(1,1),  val(5,0),val(3,1),val(6,0)],
    ],

    // Puzzle 14 of 200
    [
        [val(7,0),val(1,1),val(4,0),  val(8,0),val(6,0),val(5,1),  val(3,1),val(2,0),val(9,1)],
        [val(8,0),val(9,0),val(3,0),  val(2,0),val(1,1),val(4,0),  val(7,0),val(6,1),val(5,1)],
        [val(5,0),val(6,0),val(2,1),  val(3,0),val(9,0),val(7,0),  val(1,0),val(4,0),val(8,0)],

        [val(9,0),val(3,1),val(8,1),  val(5,0),val(4,0),val(1,0),  val(6,0),val(7,0),val(2,1)],
        [val(4,1),val(5,1),val(7,0),  val(6,0),val(2,0),val(9,0),  val(8,0),val(1,0),val(3,0)],
        [val(6,0),val(2,0),val(1,1),  val(7,1),val(8,0),val(3,1),  val(9,1),val(5,0),val(4,0)],

        [val(1,0),val(4,0),val(6,0),  val(9,1),val(3,0),val(2,1),  val(5,0),val(8,0),val(7,0)],
        [val(2,0),val(7,0),val(9,1),  val(1,1),val(5,0),val(8,0),  val(4,1),val(3,1),val(6,0)],
        [val(3,0),val(8,0),val(5,0),  val(4,0),val(7,1),val(6,0),  val(2,0),val(9,0),val(1,0)],
    ],

    // Puzzle 15 of 200
    [
        [val(5,0),val(4,1),val(6,0),  val(9,0),val(1,0),val(3,0),  val(7,1),val(8,0),val(2,0)],
        [val(3,1),val(1,0),val(2,0),  val(7,0),val(4,0),val(8,1),  val(6,0),val(5,0),val(9,0)],
        [val(9,1),val(7,0),val(8,1),  val(2,1),val(6,1),val(5,0),  val(3,0),val(4,1),val(1,0)],

        [val(6,0),val(8,0),val(9,0),  val(5,0),val(7,0),val(2,1),  val(4,0),val(1,0),val(3,0)],
        [val(2,0),val(3,0),val(1,1),  val(6,0),val(8,0),val(4,0),  val(9,1),val(7,0),val(5,1)],
        [val(7,0),val(5,0),val(4,0),  val(3,1),val(9,0),val(1,0),  val(2,0),val(6,1),val(8,0)],

        [val(4,0),val(2,0),val(5,1),  val(8,0),val(3,0),val(7,1),  val(1,1),val(9,0),val(6,0)],
        [val(1,0),val(6,0),val(3,0),  val(4,0),val(5,1),val(9,0),  val(8,1),val(2,0),val(7,0)],
        [val(8,1),val(9,0),val(7,0),  val(1,0),val(2,0),val(6,1),  val(5,0),val(3,1),val(4,0)],
    ],

    // Puzzle 16 of 200
    [
        [val(5,0),val(6,0),val(7,0),  val(2,1),val(4,0),val(3,0),  val(1,0),val(9,0),val(8,0)],
        [val(4,0),val(1,1),val(3,0),  val(6,1),val(8,1),val(9,1),  val(5,0),val(7,0),val(2,0)],
        [val(8,0),val(2,0),val(9,0),  val(7,0),val(1,1),val(5,0),  val(4,0),val(3,1),val(6,0)],

        [val(6,0),val(5,1),val(2,1),  val(9,0),val(3,0),val(8,0),  val(7,1),val(1,0),val(4,0)],
        [val(3,1),val(7,0),val(4,1),  val(5,0),val(6,1),val(1,1),  val(2,1),val(8,0),val(9,1)],
        [val(9,0),val(8,0),val(1,0),  val(4,0),val(7,0),val(2,0),  val(3,0),val(6,0),val(5,0)],

        [val(7,0),val(3,0),val(6,1),  val(8,0),val(5,1),val(4,0),  val(9,0),val(2,0),val(1,1)],
        [val(1,0),val(9,1),val(5,0),  val(3,0),val(2,0),val(6,0),  val(8,0),val(4,1),val(7,0)],
        [val(2,0),val(4,0),val(8,0),  val(1,0),val(9,1),val(7,1),  val(6,0),val(5,1),val(3,1)],
    ],

    // Puzzle 17 of 200
    [
        [val(4,1),val(9,1),val(8,0),  val(1,0),val(2,0),val(3,0),  val(6,0),val(5,0),val(7,0)],
        [val(2,0),val(1,1),val(6,0),  val(5,0),val(4,1),val(7,0),  val(9,0),val(8,1),val(3,1)],
        [val(3,0),val(5,0),val(7,0),  val(8,0),val(9,0),val(6,1),  val(2,1),val(4,0),val(1,1)],

        [val(5,0),val(4,0),val(1,0),  val(9,1),val(3,1),val(2,0),  val(8,0),val(7,0),val(6,1)],
        [val(6,0),val(7,0),val(2,1),  val(4,0),val(1,0),val(8,0),  val(3,0),val(9,0),val(5,0)],
        [val(8,1),val(3,0),val(9,0),  val(6,0),val(7,0),val(5,1),  val(4,0),val(1,0),val(2,0)],

        [val(7,0),val(8,0),val(4,0),  val(2,0),val(6,1),val(1,1),  val(5,1),val(3,0),val(9,0)],
        [val(9,1),val(2,0),val(3,0),  val(7,0),val(5,0),val(4,0),  val(1,0),val(6,1),val(8,0)],
        [val(1,1),val(6,0),val(5,0),  val(3,1),val(8,0),val(9,0),  val(7,0),val(2,0),val(4,0)],
    ],

    // Puzzle 18 of 200
    [
        [val(2,0),val(8,1),val(7,0),  val(3,1),val(9,0),val(6,1),  val(4,0),val(1,0),val(5,1)],
        [val(3,1),val(6,0),val(9,0),  val(5,0),val(4,1),val(1,0),  val(8,0),val(2,0),val(7,0)],
        [val(5,0),val(4,0),val(1,0),  val(2,0),val(8,0),val(7,0),  val(3,0),val(6,1),val(9,1)],

        [val(4,0),val(1,0),val(5,1),  val(8,0),val(6,0),val(2,1),  val(7,0),val(9,1),val(3,0)],
        [val(7,0),val(3,0),val(8,0),  val(9,0),val(1,1),val(5,0),  val(2,1),val(4,0),val(6,0)],
        [val(9,0),val(2,0),val(6,1),  val(4,0),val(7,1),val(3,0),  val(5,0),val(8,0),val(1,1)],

        [val(8,0),val(9,0),val(3,1),  val(1,1),val(5,0),val(4,0),  val(6,0),val(7,0),val(2,1)],
        [val(6,0),val(5,1),val(4,1),  val(7,1),val(2,0),val(9,0),  val(1,0),val(3,0),val(8,0)],
        [val(1,0),val(7,1),val(2,0),  val(6,1),val(3,0),val(8,0),  val(9,0),val(5,0),val(4,0)],
    ],

    // Puzzle 19 of 200
    [
        [val(4,0),val(1,0),val(6,1),  val(2,0),val(8,1),val(9,0),  val(3,1),val(7,0),val(5,1)],
        [val(5,1),val(2,1),val(9,0),  val(6,0),val(7,0),val(3,0),  val(1,1),val(4,0),val(8,0)],
        [val(3,1),val(7,0),val(8,1),  val(5,0),val(4,0),val(1,0),  val(2,0),val(6,0),val(9,0)],

        [val(9,0),val(5,0),val(3,0),  val(4,1),val(1,0),val(6,0),  val(8,0),val(2,1),val(7,0)],
        [val(7,0),val(6,0),val(1,0),  val(8,1),val(3,1),val(2,0),  val(9,1),val(5,0),val(4,0)],
        [val(8,0),val(4,1),val(2,0),  val(9,0),val(5,0),val(7,0),  val(6,0),val(3,0),val(1,1)],

        [val(6,0),val(8,1),val(5,0),  val(3,0),val(9,0),val(4,1),  val(7,1),val(1,0),val(2,1)],
        [val(2,0),val(9,0),val(7,1),  val(1,1),val(6,1),val(5,0),  val(4,0),val(8,0),val(3,0)],
        [val(1,0),val(3,0),val(4,1),  val(7,0),val(2,0),val(8,0),  val(5,0),val(9,1),val(6,1)],
    ],

    // Puzzle 20 of 200
    [
        [val(1,0),val(9,0),val(7,0),  val(3,0),val(4,0),val(6,1),  val(5,0),val(2,0),val(8,0)],
        [val(6,0),val(3,0),val(4,0),  val(2,0),val(8,0),val(5,0),  val(7,0),val(1,0),val(9,1)],
        [val(2,0),val(5,1),val(8,0),  val(7,1),val(1,1),val(9,0),  val(6,1),val(4,0),val(3,1)],

        [val(9,1),val(4,0),val(1,0),  val(8,0),val(6,1),val(3,0),  val(2,0),val(5,1),val(7,0)],
        [val(7,0),val(6,0),val(5,0),  val(9,0),val(2,1),val(1,1),  val(8,1),val(3,1),val(4,0)],
        [val(8,0),val(2,0),val(3,0),  val(5,0),val(7,0),val(4,1),  val(9,0),val(6,0),val(1,0)],

        [val(4,0),val(7,1),val(2,0),  val(1,0),val(5,0),val(8,1),  val(3,0),val(9,0),val(6,0)],
        [val(3,1),val(8,0),val(6,0),  val(4,1),val(9,0),val(2,0),  val(1,0),val(7,1),val(5,1)],
        [val(5,0),val(1,0),val(9,1),  val(6,0),val(3,1),val(7,0),  val(4,0),val(8,0),val(2,1)],
    ],

    // Puzzle 21 of 200
    [
        [val(8,1),val(1,0),val(3,1),  val(9,0),val(6,0),val(4,0),  val(5,1),val(2,0),val(7,0)],
        [val(6,0),val(7,0),val(5,0),  val(1,0),val(8,0),val(2,1),  val(4,0),val(9,0),val(3,1)],
        [val(4,0),val(9,0),val(2,1),  val(5,1),val(3,0),val(7,0),  val(1,0),val(8,1),val(6,0)],

        [val(2,0),val(5,0),val(4,0),  val(8,1),val(1,1),val(6,0),  val(3,0),val(7,1),val(9,0)],
        [val(1,0),val(8,0),val(7,0),  val(3,0),val(4,1),val(9,1),  val(2,1),val(6,1),val(5,0)],
        [val(3,0),val(6,0),val(9,1),  val(2,0),val(7,0),val(5,1),  val(8,0),val(1,0),val(4,0)],

        [val(7,1),val(4,0),val(1,0),  val(6,0),val(2,1),val(3,1),  val(9,0),val(5,0),val(8,0)],
        [val(9,0),val(2,1),val(6,0),  val(4,0),val(5,0),val(8,0),  val(7,0),val(3,0),val(1,1)],
        [val(5,1),val(3,0),val(8,0),  val(7,0),val(9,0),val(1,0),  val(6,1),val(4,1),val(2,0)],
    ],

    // Puzzle 22 of 200
    [
        [val(1,0),val(3,0),val(6,0),  val(2,0),val(4,0),val(8,1),  val(9,0),val(7,0),val(5,1)],
        [val(8,0),val(9,0),val(5,0),  val(7,0),val(6,1),val(3,0),  val(1,0),val(4,0),val(2,0)],
        [val(7,1),val(4,1),val(2,1),  val(9,0),val(1,0),val(5,0),  val(6,0),val(3,1),val(8,0)],

        [val(9,0),val(7,0),val(4,1),  val(8,0),val(5,0),val(6,1),  val(3,0),val(2,0),val(1,0)],
        [val(3,0),val(6,0),val(8,1),  val(1,0),val(7,1),val(2,1),  val(5,0),val(9,1),val(4,0)],
        [val(5,1),val(2,0),val(1,0),  val(3,0),val(9,0),val(4,0),  val(8,1),val(6,0),val(7,1)],

        [val(4,0),val(8,0),val(9,0),  val(6,0),val(2,0),val(1,0),  val(7,0),val(5,0),val(3,0)],
        [val(6,0),val(5,0),val(3,1),  val(4,1),val(8,0),val(7,0),  val(2,0),val(1,1),val(9,1)],
        [val(2,0),val(1,0),val(7,0),  val(5,1),val(3,0),val(9,0),  val(4,0),val(8,0),val(6,0)],
    ],

    // Puzzle 23 of 200
    [
        [val(4,0),val(2,0),val(7,0),  val(8,0),val(9,1),val(3,0),  val(1,0),val(6,0),val(5,0)],
        [val(1,0),val(3,1),val(8,1),  val(5,1),val(6,0),val(2,0),  val(9,0),val(7,0),val(4,0)],
        [val(6,0),val(9,0),val(5,1),  val(7,0),val(1,1),val(4,1),  val(3,1),val(8,0),val(2,0)],

        [val(5,0),val(7,1),val(6,1),  val(9,0),val(3,0),val(1,0),  val(4,0),val(2,0),val(8,1)],
        [val(8,0),val(1,0),val(2,0),  val(6,0),val(4,0),val(7,1),  val(5,0),val(3,0),val(9,1)],
        [val(3,1),val(4,0),val(9,0),  val(2,0),val(8,0),val(5,0),  val(6,1),val(1,0),val(7,0)],

        [val(2,1),val(6,0),val(4,1),  val(3,0),val(7,0),val(9,0),  val(8,0),val(5,0),val(1,0)],
        [val(9,0),val(5,1),val(3,0),  val(1,1),val(2,0),val(8,0),  val(7,0),val(4,1),val(6,0)],
        [val(7,0),val(8,0),val(1,1),  val(4,0),val(5,1),val(6,1),  val(2,0),val(9,1),val(3,0)],
    ],

    // Puzzle 24 of 200
    [
        [val(7,1),val(5,1),val(3,0),  val(2,0),val(8,1),val(9,0),  val(1,1),val(4,0),val(6,0)],
        [val(2,0),val(1,0),val(8,1),  val(6,0),val(4,0),val(3,1),  val(5,1),val(9,1),val(7,0)],
        [val(4,0),val(6,1),val(9,0),  val(1,0),val(5,0),val(7,0),  val(8,0),val(3,1),val(2,0)],

        [val(1,0),val(9,0),val(4,1),  val(8,0),val(3,0),val(6,0),  val(2,1),val(7,0),val(5,0)],
        [val(5,0),val(8,0),val(6,0),  val(7,1),val(2,0),val(4,0),  val(3,0),val(1,0),val(9,0)],
        [val(3,1),val(2,0),val(7,1),  val(5,0),val(9,1),val(1,0),  val(4,0),val(6,1),val(8,1)],

        [val(9,0),val(7,0),val(5,1),  val(3,1),val(1,0),val(2,0),  val(6,0),val(8,0),val(4,0)],
        [val(8,0),val(4,1),val(1,0),  val(9,1),val(6,0),val(5,0),  val(7,0),val(2,0),val(3,0)],
        [val(6,1),val(3,0),val(2,0),  val(4,0),val(7,0),val(8,1),  val(9,1),val(5,1),val(1,0)],
    ],

    // Puzzle 25 of 200
    [
        [val(5,0),val(9,1),val(6,1),  val(2,1),val(3,0),val(4,0),  val(7,1),val(8,0),val(1,0)],
        [val(2,0),val(8,0),val(4,0),  val(5,1),val(7,0),val(1,0),  val(3,0),val(6,0),val(9,0)],
        [val(7,1),val(1,0),val(3,0),  val(8,1),val(9,0),val(6,0),  val(5,1),val(2,0),val(4,1)],

        [val(9,0),val(6,0),val(5,0),  val(4,0),val(8,0),val(3,1),  val(1,0),val(7,0),val(2,0)],
        [val(4,0),val(3,1),val(7,1),  val(1,0),val(2,1),val(5,0),  val(6,0),val(9,0),val(8,0)],
        [val(8,1),val(2,1),val(1,0),  val(9,0),val(6,0),val(7,0),  val(4,1),val(5,0),val(3,0)],

        [val(1,1),val(7,0),val(9,0),  val(6,0),val(4,0),val(8,0),  val(2,0),val(3,1),val(5,1)],
        [val(3,0),val(4,0),val(2,0),  val(7,1),val(5,0),val(9,1),  val(8,0),val(1,1),val(6,1)],
        [val(6,0),val(5,0),val(8,1),  val(3,0),val(1,0),val(2,0),  val(9,0),val(4,0),val(7,0)],
    ],

    // Puzzle 26 of 200
    [
        [val(8,0),val(7,0),val(6,0),  val(4,1),val(5,0),val(3,0),  val(2,0),val(1,0),val(9,0)],
        [val(1,1),val(9,1),val(3,1),  val(7,0),val(6,1),val(2,0),  val(5,1),val(4,0),val(8,0)],
        [val(2,1),val(5,0),val(4,0),  val(1,0),val(8,0),val(9,0),  val(7,0),val(3,0),val(6,0)],

        [val(4,1),val(3,0),val(5,0),  val(2,1),val(7,0),val(6,0),  val(8,0),val(9,0),val(1,1)],
        [val(9,0),val(2,0),val(8,1),  val(3,1),val(4,1),val(1,0),  val(6,0),val(7,0),val(5,0)],
        [val(7,0),val(6,1),val(1,0),  val(5,0),val(9,1),val(8,0),  val(4,0),val(2,0),val(3,1)],

        [val(5,0),val(4,0),val(9,0),  val(6,0),val(3,1),val(7,1),  val(1,0),val(8,1),val(2,0)],
        [val(6,0),val(8,1),val(2,0),  val(9,1),val(1,0),val(4,0),  val(3,0),val(5,1),val(7,0)],
        [val(3,1),val(1,0),val(7,0),  val(8,0),val(2,0),val(5,1),  val(9,0),val(6,0),val(4,1)],
    ],

    // Puzzle 27 of 200
    [
        [val(5,0),val(8,0),val(6,0),  val(3,1),val(1,0),val(2,0),  val(9,0),val(4,0),val(7,0)],
        [val(2,0),val(1,0),val(4,1),  val(7,0),val(5,1),val(9,1),  val(8,1),val(6,0),val(3,0)],
        [val(7,0),val(9,0),val(3,0),  val(4,0),val(8,1),val(6,0),  val(1,0),val(2,0),val(5,1)],

        [val(1,0),val(3,0),val(5,1),  val(6,0),val(9,1),val(8,1),  val(2,0),val(7,1),val(4,1)],
        [val(4,0),val(7,0),val(8,0),  val(2,0),val(3,0),val(1,0),  val(6,1),val(5,0),val(9,0)],
        [val(6,0),val(2,1),val(9,1),  val(5,1),val(4,0),val(7,0),  val(3,0),val(1,0),val(8,0)],

        [val(9,0),val(4,1),val(1,0),  val(8,0),val(6,0),val(5,0),  val(7,0),val(3,0),val(2,0)],
        [val(8,0),val(5,1),val(2,0),  val(1,1),val(7,1),val(3,0),  val(4,0),val(9,1),val(6,0)],
        [val(3,1),val(6,0),val(7,1),  val(9,0),val(2,0),val(4,0),  val(5,0),val(8,0),val(1,1)],
    ],

    // Puzzle 28 of 200
    [
        [val(7,0),val(9,0),val(6,1),  val(4,0),val(2,0),val(3,0),  val(5,0),val(8,0),val(1,1)],
        [val(3,0),val(5,0),val(2,1),  val(1,0),val(8,1),val(9,0),  val(4,0),val(6,1),val(7,0)],
        [val(8,1),val(1,0),val(4,1),  val(6,0),val(7,0),val(5,1),  val(3,0),val(9,0),val(2,0)],

        [val(5,1),val(7,0),val(8,0),  val(2,1),val(3,0),val(6,0),  val(1,0),val(4,0),val(9,1)],
        [val(4,0),val(2,0),val(1,0),  val(9,1),val(5,0),val(7,0),  val(6,0),val(3,0),val(8,0)],
        [val(6,0),val(3,0),val(9,0),  val(8,0),val(4,1),val(1,0),  val(7,1),val(2,1),val(5,0)],

        [val(1,1),val(8,1),val(7,0),  val(3,0),val(6,1),val(2,0),  val(9,0),val(5,0),val(4,1)],
        [val(9,1),val(4,0),val(3,0),  val(5,1),val(1,0),val(8,0),  val(2,0),val(7,0),val(6,0)],
        [val(2,0),val(6,0),val(5,0),  val(7,0),val(9,0),val(4,0),  val(8,1),val(1,0),val(3,0)],
    ],

    // Puzzle 29 of 200
    [
        [val(9,1),val(6,0),val(8,1),  val(4,0),val(1,0),val(2,1),  val(3,0),val(5,1),val(7,0)],
        [val(4,0),val(1,0),val(2,1),  val(5,0),val(7,0),val(3,0),  val(8,0),val(6,1),val(9,0)],
        [val(3,0),val(5,0),val(7,1),  val(9,1),val(6,0),val(8,1),  val(1,0),val(4,0),val(2,1)],

        [val(6,0),val(7,0),val(9,0),  val(1,1),val(3,0),val(4,0),  val(2,0),val(8,0),val(5,1)],
        [val(5,0),val(2,0),val(1,0),  val(7,0),val(8,1),val(6,0),  val(9,0),val(3,0),val(4,1)],
        [val(8,0),val(3,0),val(4,0),  val(2,0),val(9,0),val(5,1),  val(7,1),val(1,1),val(6,0)],

        [val(7,0),val(4,0),val(5,0),  val(8,0),val(2,0),val(1,0),  val(6,0),val(9,1),val(3,0)],
        [val(2,0),val(8,1),val(3,1),  val(6,1),val(4,1),val(9,0),  val(5,0),val(7,0),val(1,0)],
        [val(1,0),val(9,0),val(6,1),  val(3,1),val(5,0),val(7,1),  val(4,0),val(2,0),val(8,0)],
    ],

    // Puzzle 30 of 200
    [
        [val(3,0),val(8,0),val(2,1),  val(7,0),val(6,1),val(9,0),  val(1,1),val(4,0),val(5,1)],
        [val(5,0),val(1,0),val(7,1),  val(3,0),val(4,0),val(8,1),  val(2,0),val(9,1),val(6,0)],
        [val(9,0),val(4,1),val(6,0),  val(2,1),val(1,0),val(5,0),  val(8,0),val(3,0),val(7,0)],

        [val(4,1),val(5,0),val(1,0),  val(6,1),val(8,1),val(7,0),  val(3,0),val(2,0),val(9,0)],
        [val(6,1),val(2,0),val(9,0),  val(1,0),val(5,1),val(3,0),  val(4,0),val(7,1),val(8,0)],
        [val(8,0),val(7,0),val(3,0),  val(4,0),val(9,0),val(2,0),  val(5,0),val(6,0),val(1,1)],

        [val(1,1),val(6,0),val(5,1),  val(9,1),val(2,1),val(4,0),  val(7,1),val(8,0),val(3,0)],
        [val(7,0),val(9,0),val(4,0),  val(8,0),val(3,0),val(1,1),  val(6,1),val(5,0),val(2,0)],
        [val(2,1),val(3,1),val(8,0),  val(5,0),val(7,0),val(6,0),  val(9,1),val(1,0),val(4,0)],
    ],

    // Puzzle 31 of 200
    [
        [val(2,0),val(7,0),val(9,0),  val(6,0),val(1,1),val(5,1),  val(3,0),val(8,1),val(4,0)],
        [val(4,0),val(5,0),val(1,1),  val(8,0),val(3,1),val(9,0),  val(7,0),val(2,1),val(6,0)],
        [val(6,1),val(3,0),val(8,0),  val(4,0),val(7,0),val(2,0),  val(5,1),val(9,0),val(1,1)],

        [val(9,0),val(1,1),val(3,1),  val(7,0),val(8,0),val(4,0),  val(2,1),val(6,0),val(5,0)],
        [val(8,0),val(2,1),val(5,0),  val(9,1),val(6,0),val(3,0),  val(1,1),val(4,1),val(7,0)],
        [val(7,0),val(6,0),val(4,1),  val(2,0),val(5,0),val(1,0),  val(9,0),val(3,0),val(8,1)],

        [val(1,0),val(4,0),val(6,0),  val(3,0),val(2,1),val(7,1),  val(8,0),val(5,1),val(9,0)],
        [val(5,1),val(9,0),val(2,0),  val(1,0),val(4,0),val(8,1),  val(6,1),val(7,0),val(3,0)],
        [val(3,1),val(8,1),val(7,0),  val(5,0),val(9,0),val(6,0),  val(4,0),val(1,0),val(2,0)],
    ],

    // Puzzle 32 of 200
    [
        [val(6,1),val(7,1),val(3,0),  val(9,1),val(2,0),val(4,0),  val(8,0),val(5,0),val(1,0)],
        [val(9,0),val(4,1),val(2,0),  val(1,1),val(8,1),val(5,0),  val(3,0),val(6,0),val(7,0)],
        [val(1,0),val(8,0),val(5,0),  val(7,0),val(6,0),val(3,0),  val(4,0),val(2,1),val(9,0)],

        [val(7,1),val(2,0),val(9,0),  val(5,0),val(1,0),val(8,1),  val(6,0),val(4,1),val(3,0)],
        [val(3,0),val(6,0),val(8,0),  val(4,0),val(7,0),val(2,0),  val(1,0),val(9,1),val(5,1)],
        [val(5,0),val(1,1),val(4,0),  val(6,1),val(3,0),val(9,0),  val(2,0),val(7,0),val(8,1)],

        [val(8,1),val(5,0),val(1,0),  val(2,1),val(9,0),val(6,1),  val(7,0),val(3,0),val(4,0)],
        [val(2,0),val(9,1),val(7,1),  val(3,0),val(4,0),val(1,1),  val(5,1),val(8,0),val(6,0)],
        [val(4,1),val(3,1),val(6,0),  val(8,0),val(5,0),val(7,0),  val(9,1),val(1,0),val(2,0)],
    ],

    // Puzzle 33 of 200
    [
        [val(5,1),val(6,0),val(9,1),  val(2,0),val(8,0),val(7,0),  val(4,1),val(1,0),val(3,0)],
        [val(3,0),val(7,0),val(2,0),  val(1,1),val(4,0),val(5,0),  val(9,1),val(6,0),val(8,1)],
        [val(8,0),val(1,0),val(4,0),  val(3,0),val(6,0),val(9,0),  val(7,1),val(5,0),val(2,1)],

        [val(2,1),val(4,1),val(5,1),  val(6,1),val(7,1),val(3,0),  val(1,0),val(8,0),val(9,0)],
        [val(7,0),val(8,0),val(3,0),  val(5,0),val(9,1),val(1,0),  val(2,0),val(4,0),val(6,0)],
        [val(6,1),val(9,0),val(1,0),  val(8,1),val(2,0),val(4,0),  val(5,0),val(3,1),val(7,0)],

        [val(1,0),val(2,0),val(7,1),  val(4,0),val(3,1),val(6,0),  val(8,0),val(9,0),val(5,1)],
        [val(9,0),val(5,0),val(6,1),  val(7,1),val(1,0),val(8,0),  val(3,0),val(2,0),val(4,0)],
        [val(4,1),val(3,1),val(8,0),  val(9,0),val(5,0),val(2,1),  val(6,0),val(7,0),val(1,0)],
    ],

    // Puzzle 34 of 200
    [
        [val(6,1),val(2,0),val(3,0),  val(5,0),val(7,0),val(9,0),  val(1,1),val(8,0),val(4,1)],
        [val(4,0),val(9,0),val(5,0),  val(8,0),val(2,1),val(1,0),  val(7,0),val(3,1),val(6,1)],
        [val(8,0),val(1,0),val(7,0),  val(6,0),val(4,0),val(3,1),  val(9,1),val(5,0),val(2,0)],

        [val(1,0),val(7,1),val(6,1),  val(4,1),val(3,0),val(8,0),  val(5,0),val(2,0),val(9,1)],
        [val(5,1),val(4,0),val(2,1),  val(9,0),val(1,0),val(6,0),  val(8,0),val(7,1),val(3,1)],
        [val(3,0),val(8,0),val(9,0),  val(7,0),val(5,1),val(2,0),  val(6,0),val(4,0),val(1,0)],

        [val(2,1),val(5,0),val(4,0),  val(1,1),val(9,0),val(7,1),  val(3,0),val(6,0),val(8,0)],
        [val(9,1),val(3,0),val(8,0),  val(2,0),val(6,0),val(5,0),  val(4,1),val(1,1),val(7,1)],
        [val(7,0),val(6,0),val(1,0),  val(3,0),val(8,0),val(4,1),  val(2,0),val(9,0),val(5,1)],
    ],

    // Puzzle 35 of 200
    [
        [val(4,1),val(6,0),val(3,0),  val(7,0),val(1,0),val(5,0),  val(2,0),val(8,0),val(9,0)],
        [val(9,1),val(1,0),val(2,0),  val(4,0),val(8,1),val(3,0),  val(7,1),val(6,0),val(5,0)],
        [val(8,0),val(7,0),val(5,1),  val(9,0),val(2,1),val(6,0),  val(1,0),val(3,1),val(4,0)],

        [val(2,0),val(3,1),val(7,0),  val(5,1),val(9,0),val(4,0),  val(6,1),val(1,1),val(8,1)],
        [val(5,0),val(9,0),val(8,0),  val(6,0),val(7,0),val(1,0),  val(3,1),val(4,0),val(2,0)],
        [val(1,0),val(4,0),val(6,0),  val(2,0),val(3,0),val(8,1),  val(9,0),val(5,1),val(7,1)],

        [val(6,0),val(8,1),val(9,1),  val(3,0),val(5,0),val(7,1),  val(4,0),val(2,1),val(1,1)],
        [val(7,0),val(5,0),val(4,1),  val(1,1),val(6,0),val(2,0),  val(8,0),val(9,0),val(3,0)],
        [val(3,0),val(2,1),val(1,0),  val(8,0),val(4,1),val(9,0),  val(5,0),val(7,0),val(6,0)],
    ],

    // Puzzle 36 of 200
    [
        [val(7,1),val(4,0),val(2,1),  val(1,1),val(8,0),val(5,0),  val(6,1),val(9,0),val(3,0)],
        [val(5,1),val(3,0),val(8,0),  val(2,0),val(6,0),val(9,1),  val(7,1),val(4,0),val(1,0)],
        [val(6,0),val(1,0),val(9,1),  val(4,0),val(7,0),val(3,0),  val(5,1),val(8,1),val(2,1)],

        [val(1,1),val(9,0),val(3,0),  val(7,0),val(4,1),val(8,0),  val(2,0),val(5,1),val(6,0)],
        [val(4,0),val(6,0),val(5,0),  val(3,1),val(2,0),val(1,0),  val(9,1),val(7,0),val(8,0)],
        [val(8,0),val(2,0),val(7,1),  val(5,0),val(9,1),val(6,0),  val(1,0),val(3,0),val(4,1)],

        [val(3,0),val(5,0),val(4,1),  val(6,1),val(1,0),val(7,0),  val(8,0),val(2,0),val(9,0)],
        [val(2,1),val(8,1),val(6,0),  val(9,0),val(5,0),val(4,0),  val(3,0),val(1,1),val(7,0)],
        [val(9,0),val(7,0),val(1,0),  val(8,0),val(3,1),val(2,0),  val(4,1),val(6,0),val(5,0)],
    ],

    // Puzzle 37 of 200
    [
        [val(2,0),val(7,0),val(4,0),  val(6,0),val(5,0),val(1,0),  val(3,0),val(8,0),val(9,1)],
        [val(5,0),val(3,1),val(8,0),  val(9,0),val(7,0),val(4,1),  val(6,1),val(2,0),val(1,0)],
        [val(9,0),val(1,0),val(6,0),  val(2,0),val(8,0),val(3,0),  val(5,1),val(7,1),val(4,0)],

        [val(4,1),val(9,1),val(2,0),  val(8,0),val(3,0),val(6,1),  val(7,1),val(1,1),val(5,1)],
        [val(3,1),val(6,1),val(5,0),  val(7,0),val(1,1),val(9,0),  val(8,0),val(4,1),val(2,0)],
        [val(7,0),val(8,1),val(1,0),  val(4,0),val(2,0),val(5,0),  val(9,0),val(3,1),val(6,0)],

        [val(6,0),val(5,1),val(7,1),  val(1,0),val(4,0),val(8,0),  val(2,0),val(9,1),val(3,1)],
        [val(8,1),val(4,0),val(3,0),  val(5,0),val(9,0),val(2,1),  val(1,0),val(6,0),val(7,0)],
        [val(1,0),val(2,0),val(9,0),  val(3,0),val(6,1),val(7,0),  val(4,0),val(5,0),val(8,0)],
    ],

    // Puzzle 38 of 200
    [
        [val(1,0),val(9,0),val(6,1),  val(5,0),val(7,0),val(3,1),  val(8,0),val(4,0),val(2,0)],
        [val(2,0),val(4,0),val(8,0),  val(9,0),val(1,1),val(6,0),  val(7,0),val(5,1),val(3,0)],
        [val(5,0),val(7,1),val(3,0),  val(4,0),val(2,0),val(8,0),  val(1,0),val(9,1),val(6,1)],

        [val(9,1),val(6,0),val(7,0),  val(1,0),val(4,1),val(2,0),  val(3,0),val(8,0),val(5,0)],
        [val(3,1),val(1,0),val(2,1),  val(7,0),val(8,0),val(5,1),  val(4,0),val(6,1),val(9,0)],
        [val(8,1),val(5,0),val(4,0),  val(6,1),val(3,0),val(9,0),  val(2,0),val(7,0),val(1,0)],

        [val(4,0),val(8,0),val(9,0),  val(3,1),val(5,0),val(1,0),  val(6,0),val(2,0),val(7,0)],
        [val(7,0),val(3,0),val(5,1),  val(2,0),val(6,0),val(4,0),  val(9,0),val(1,1),val(8,0)],
        [val(6,0),val(2,1),val(1,1),  val(8,1),val(9,1),val(7,0),  val(5,0),val(3,0),val(4,1)],
    ],

    // Puzzle 39 of 200
    [
        [val(7,0),val(9,0),val(8,0),  val(2,0),val(3,0),val(1,0),  val(5,0),val(6,1),val(4,0)],
        [val(2,0),val(6,0),val(5,0),  val(9,1),val(4,1),val(8,0),  val(3,0),val(1,1),val(7,0)],
        [val(1,0),val(3,0),val(4,1),  val(5,1),val(6,1),val(7,1),  val(2,0),val(9,0),val(8,0)],

        [val(8,1),val(1,0),val(2,1),  val(3,0),val(9,1),val(4,1),  val(7,0),val(5,0),val(6,0)],
        [val(5,0),val(4,1),val(3,1),  val(6,0),val(7,0),val(2,1),  val(9,0),val(8,0),val(1,1)],
        [val(6,0),val(7,0),val(9,0),  val(8,0),val(1,0),val(5,0),  val(4,0),val(2,0),val(3,0)],

        [val(9,0),val(8,1),val(1,1),  val(4,0),val(2,0),val(3,1),  val(6,0),val(7,1),val(5,1)],
        [val(4,0),val(2,0),val(7,0),  val(1,0),val(5,1),val(6,0),  val(8,0),val(3,0),val(9,1)],
        [val(3,1),val(5,1),val(6,0),  val(7,0),val(8,1),val(9,0),  val(1,0),val(4,0),val(2,0)],
    ],

    // Puzzle 40 of 200
    [
        [val(9,0),val(6,1),val(8,1),  val(1,0),val(3,0),val(2,0),  val(5,0),val(4,0),val(7,0)],
        [val(7,1),val(2,0),val(5,0),  val(6,0),val(8,0),val(4,0),  val(1,1),val(9,1),val(3,1)],
        [val(4,0),val(3,0),val(1,0),  val(5,0),val(7,0),val(9,1),  val(6,0),val(8,0),val(2,0)],

        [val(6,1),val(4,1),val(3,0),  val(8,0),val(5,0),val(7,0),  val(2,0),val(1,0),val(9,1)],
        [val(1,1),val(5,1),val(2,1),  val(3,0),val(9,1),val(6,1),  val(8,0),val(7,0),val(4,1)],
        [val(8,0),val(9,0),val(7,0),  val(4,0),val(2,1),val(1,0),  val(3,0),val(6,1),val(5,0)],

        [val(5,0),val(1,1),val(9,0),  val(2,1),val(4,0),val(8,1),  val(7,0),val(3,0),val(6,0)],
        [val(2,0),val(7,0),val(6,0),  val(9,0),val(1,0),val(3,0),  val(4,1),val(5,0),val(8,0)],
        [val(3,0),val(8,0),val(4,0),  val(7,1),val(6,0),val(5,1),  val(9,0),val(2,1),val(1,0)],
    ],

    // Puzzle 41 of 200
    [
        [val(6,0),val(7,0),val(9,0),  val(8,0),val(3,0),val(5,1),  val(2,1),val(4,0),val(1,0)],
        [val(1,0),val(2,0),val(4,0),  val(9,0),val(6,1),val(7,0),  val(3,0),val(5,1),val(8,0)],
        [val(5,0),val(3,0),val(8,1),  val(2,0),val(1,1),val(4,0),  val(6,0),val(9,1),val(7,0)],

        [val(2,1),val(9,0),val(6,1),  val(1,0),val(4,1),val(3,0),  val(8,1),val(7,0),val(5,0)],
        [val(3,0),val(1,0),val(5,0),  val(7,1),val(8,0),val(9,0),  val(4,0),val(6,0),val(2,0)],
        [val(8,0),val(4,0),val(7,0),  val(6,0),val(5,1),val(2,0),  val(9,0),val(1,1),val(3,1)],

        [val(7,1),val(8,1),val(3,0),  val(5,0),val(9,0),val(6,0),  val(1,0),val(2,0),val(4,0)],
        [val(9,0),val(5,1),val(1,1),  val(4,0),val(2,1),val(8,0),  val(7,0),val(3,0),val(6,1)],
        [val(4,0),val(6,1),val(2,0),  val(3,1),val(7,0),val(1,0),  val(5,0),val(8,0),val(9,0)],
    ],

    // Puzzle 42 of 200
    [
        [val(1,0),val(4,0),val(7,1),  val(2,0),val(9,0),val(5,0),  val(8,0),val(6,1),val(3,0)],
        [val(6,0),val(9,0),val(2,0),  val(3,1),val(8,0),val(7,0),  val(1,0),val(5,0),val(4,1)],
        [val(5,1),val(8,1),val(3,0),  val(6,1),val(1,0),val(4,0),  val(9,1),val(2,1),val(7,0)],

        [val(2,0),val(7,0),val(5,0),  val(4,0),val(6,0),val(9,0),  val(3,1),val(8,1),val(1,0)],
        [val(4,1),val(3,0),val(1,0),  val(5,0),val(2,0),val(8,1),  val(6,0),val(7,0),val(9,1)],
        [val(8,0),val(6,1),val(9,1),  val(7,1),val(3,0),val(1,1),  val(5,0),val(4,1),val(2,0)],

        [val(3,0),val(2,0),val(8,0),  val(9,0),val(7,1),val(6,0),  val(4,0),val(1,0),val(5,1)],
        [val(7,0),val(5,0),val(6,1),  val(1,0),val(4,0),val(3,0),  val(2,0),val(9,1),val(8,0)],
        [val(9,1),val(1,0),val(4,1),  val(8,0),val(5,0),val(2,1),  val(7,0),val(3,0),val(6,0)],
    ],

    // Puzzle 43 of 200
    [
        [val(6,0),val(8,1),val(1,1),  val(9,1),val(2,0),val(4,0),  val(7,0),val(3,0),val(5,0)],
        [val(9,0),val(4,1),val(5,0),  val(7,0),val(1,0),val(3,0),  val(6,0),val(8,0),val(2,1)],
        [val(7,0),val(2,0),val(3,0),  val(6,1),val(5,1),val(8,1),  val(4,0),val(1,0),val(9,0)],

        [val(5,1),val(7,0),val(6,0),  val(4,0),val(3,0),val(1,1),  val(2,0),val(9,0),val(8,0)],
        [val(4,1),val(1,1),val(2,1),  val(8,0),val(9,0),val(5,0),  val(3,0),val(6,1),val(7,0)],
        [val(3,0),val(9,0),val(8,0),  val(2,0),val(7,0),val(6,0),  val(5,1),val(4,0),val(1,0)],

        [val(1,0),val(6,1),val(9,0),  val(5,0),val(4,1),val(7,1),  val(8,0),val(2,1),val(3,1)],
        [val(8,1),val(3,1),val(7,0),  val(1,0),val(6,0),val(2,1),  val(9,0),val(5,0),val(4,1)],
        [val(2,0),val(5,0),val(4,0),  val(3,0),val(8,0),val(9,0),  val(1,0),val(7,0),val(6,0)],
    ],

    // Puzzle 44 of 200
    [
        [val(5,0),val(3,0),val(6,1),  val(2,0),val(1,0),val(4,1),  val(7,0),val(8,0),val(9,0)],
        [val(7,0),val(4,0),val(2,1),  val(9,1),val(6,0),val(8,0),  val(3,0),val(5,1),val(1,0)],
        [val(8,0),val(9,0),val(1,0),  val(7,0),val(3,1),val(5,0),  val(2,1),val(4,0),val(6,0)],

        [val(4,1),val(5,0),val(3,0),  val(6,0),val(8,1),val(2,0),  val(1,0),val(9,0),val(7,0)],
        [val(6,0),val(2,1),val(9,1),  val(5,0),val(7,0),val(1,1),  val(8,0),val(3,0),val(4,0)],
        [val(1,0),val(7,0),val(8,1),  val(3,0),val(4,1),val(9,0),  val(5,1),val(6,0),val(2,0)],

        [val(2,0),val(6,1),val(7,0),  val(4,0),val(5,0),val(3,0),  val(9,1),val(1,1),val(8,0)],
        [val(9,0),val(1,1),val(5,0),  val(8,1),val(2,1),val(6,0),  val(4,0),val(7,1),val(3,0)],
        [val(3,1),val(8,0),val(4,1),  val(1,0),val(9,0),val(7,0),  val(6,0),val(2,0),val(5,0)],
    ],

    // Puzzle 45 of 200
    [
        [val(2,0),val(6,0),val(8,0),  val(5,0),val(4,0),val(7,0),  val(1,0),val(9,1),val(3,0)],
        [val(5,1),val(7,1),val(3,0),  val(1,1),val(2,0),val(9,0),  val(8,0),val(6,1),val(4,0)],
        [val(1,1),val(9,0),val(4,1),  val(6,1),val(3,1),val(8,0),  val(5,1),val(2,0),val(7,1)],

        [val(3,0),val(5,1),val(7,0),  val(8,0),val(1,0),val(2,1),  val(6,0),val(4,0),val(9,1)],
        [val(8,0),val(1,0),val(2,1),  val(4,0),val(9,1),val(6,0),  val(3,0),val(7,0),val(5,0)],
        [val(9,0),val(4,0),val(6,1),  val(7,0),val(5,0),val(3,0),  val(2,0),val(1,1),val(8,0)],

        [val(6,0),val(3,0),val(1,0),  val(9,0),val(8,0),val(4,0),  val(7,0),val(5,0),val(2,1)],
        [val(4,0),val(8,1),val(5,1),  val(2,0),val(7,0),val(1,0),  val(9,0),val(3,0),val(6,0)],
        [val(7,1),val(2,0),val(9,0),  val(3,1),val(6,0),val(5,0),  val(4,0),val(8,0),val(1,1)],
    ],

    // Puzzle 46 of 200
    [
        [val(6,0),val(7,0),val(8,1),  val(1,1),val(4,0),val(3,0),  val(5,0),val(2,0),val(9,1)],
        [val(1,0),val(3,0),val(5,0),  val(9,0),val(6,1),val(2,0),  val(8,0),val(7,1),val(4,1)],
        [val(9,0),val(4,0),val(2,1),  val(7,1),val(8,0),val(5,0),  val(3,1),val(6,0),val(1,0)],

        [val(3,0),val(8,1),val(1,0),  val(6,0),val(7,0),val(9,0),  val(2,1),val(4,0),val(5,0)],
        [val(4,1),val(5,0),val(6,0),  val(2,0),val(3,1),val(8,0),  val(1,0),val(9,0),val(7,0)],
        [val(2,0),val(9,0),val(7,0),  val(4,1),val(5,0),val(1,0),  val(6,1),val(8,1),val(3,0)],

        [val(8,0),val(1,1),val(4,0),  val(3,0),val(2,0),val(7,0),  val(9,0),val(5,0),val(6,0)],
        [val(7,1),val(2,0),val(3,0),  val(5,0),val(9,1),val(6,1),  val(4,1),val(1,0),val(8,0)],
        [val(5,1),val(6,0),val(9,1),  val(8,0),val(1,0),val(4,0),  val(7,0),val(3,0),val(2,0)],
    ],

    // Puzzle 47 of 200
    [
        [val(7,1),val(1,0),val(8,0),  val(3,0),val(4,0),val(5,0),  val(9,0),val(6,1),val(2,0)],
        [val(2,1),val(3,0),val(9,0),  val(1,1),val(7,0),val(6,0),  val(4,1),val(8,0),val(5,0)],
        [val(5,0),val(6,0),val(4,0),  val(2,1),val(9,0),val(8,0),  val(3,1),val(1,0),val(7,0)],

        [val(8,0),val(2,0),val(5,1),  val(6,0),val(1,0),val(3,0),  val(7,1),val(4,0),val(9,0)],
        [val(1,0),val(7,0),val(6,1),  val(9,1),val(5,1),val(4,0),  val(8,0),val(2,0),val(3,0)],
        [val(4,1),val(9,1),val(3,0),  val(7,0),val(8,0),val(2,1),  val(6,0),val(5,0),val(1,1)],

        [val(9,0),val(4,0),val(2,0),  val(8,0),val(3,1),val(1,0),  val(5,0),val(7,0),val(6,0)],
        [val(6,1),val(5,0),val(7,0),  val(4,0),val(2,0),val(9,0),  val(1,0),val(3,0),val(8,0)],
        [val(3,0),val(8,1),val(1,1),  val(5,0),val(6,0),val(7,1),  val(2,1),val(9,0),val(4,1)],
    ],

    // Puzzle 48 of 200
    [
        [val(6,0),val(9,1),val(5,1),  val(4,0),val(2,1),val(1,1),  val(8,0),val(3,0),val(7,0)],
        [val(2,0),val(4,0),val(1,1),  val(7,0),val(8,0),val(3,0),  val(5,1),val(6,0),val(9,0)],
        [val(8,1),val(3,0),val(7,0),  val(5,0),val(6,1),val(9,1),  val(4,0),val(2,1),val(1,0)],

        [val(5,0),val(2,0),val(8,0),  val(1,0),val(9,0),val(6,0),  val(3,0),val(7,1),val(4,0)],
        [val(1,0),val(7,0),val(3,1),  val(8,0),val(4,0),val(2,0),  val(9,0),val(5,0),val(6,1)],
        [val(4,1),val(6,1),val(9,0),  val(3,1),val(7,1),val(5,0),  val(1,0),val(8,0),val(2,1)],

        [val(7,0),val(5,0),val(2,1),  val(9,0),val(1,1),val(8,0),  val(6,0),val(4,0),val(3,1)],
        [val(3,0),val(1,0),val(4,0),  val(6,0),val(5,0),val(7,0),  val(2,0),val(9,0),val(8,0)],
        [val(9,1),val(8,0),val(6,0),  val(2,0),val(3,0),val(4,1),  val(7,1),val(1,1),val(5,0)],
    ],

    // Puzzle 49 of 200
    [
        [val(2,1),val(7,0),val(3,1),  val(5,0),val(6,0),val(8,0),  val(4,1),val(9,1),val(1,1)],
        [val(9,0),val(4,0),val(1,0),  val(7,1),val(2,0),val(3,0),  val(6,0),val(8,0),val(5,0)],
        [val(6,0),val(5,0),val(8,0),  val(4,0),val(9,0),val(1,0),  val(7,0),val(2,1),val(3,0)],

        [val(5,0),val(3,0),val(4,1),  val(9,0),val(1,1),val(6,0),  val(2,0),val(7,0),val(8,0)],
        [val(7,0),val(8,0),val(9,1),  val(3,0),val(5,0),val(2,0),  val(1,0),val(4,1),val(6,0)],
        [val(1,0),val(6,0),val(2,0),  val(8,1),val(7,0),val(4,0),  val(5,1),val(3,0),val(9,0)],

        [val(3,0),val(1,1),val(7,0),  val(2,0),val(8,1),val(5,0),  val(9,0),val(6,0),val(4,0)],
        [val(4,0),val(2,0),val(5,1),  val(6,1),val(3,1),val(9,0),  val(8,0),val(1,0),val(7,1)],
        [val(8,0),val(9,0),val(6,1),  val(1,0),val(4,1),val(7,0),  val(3,0),val(5,0),val(2,1)],
    ],

    // Puzzle 50 of 200
    [
        [val(1,0),val(9,0),val(5,0),  val(4,0),val(3,0),val(7,0),  val(8,0),val(6,0),val(2,1)],
        [val(4,0),val(3,0),val(6,1),  val(2,0),val(9,1),val(8,0),  val(7,1),val(1,0),val(5,1)],
        [val(8,0),val(7,0),val(2,1),  val(1,1),val(5,0),val(6,0),  val(9,1),val(4,1),val(3,0)],

        [val(5,1),val(1,0),val(9,0),  val(8,1),val(6,1),val(2,1),  val(4,0),val(3,1),val(7,0)],
        [val(7,0),val(4,1),val(8,0),  val(3,1),val(1,0),val(5,0),  val(6,0),val(2,1),val(9,0)],
        [val(6,0),val(2,0),val(3,0),  val(7,0),val(4,0),val(9,0),  val(5,0),val(8,0),val(1,0)],

        [val(3,0),val(8,1),val(1,0),  val(9,0),val(7,0),val(4,1),  val(2,0),val(5,0),val(6,0)],
        [val(9,0),val(5,1),val(4,0),  val(6,0),val(2,0),val(3,1),  val(1,1),val(7,0),val(8,0)],
        [val(2,1),val(6,0),val(7,0),  val(5,1),val(8,0),val(1,0),  val(3,0),val(9,1),val(4,0)],
    ],

    // Puzzle 51 of 200
    [
        [val(5,0),val(3,1),val(6,0),  val(8,0),val(1,0),val(2,1),  val(9,0),val(4,0),val(7,0)],
        [val(8,0),val(2,1),val(4,1),  val(7,0),val(3,0),val(9,0),  val(5,0),val(6,0),val(1,1)],
        [val(1,0),val(9,1),val(7,0),  val(5,0),val(4,1),val(6,1),  val(3,0),val(2,0),val(8,0)],

        [val(4,0),val(7,0),val(9,0),  val(3,0),val(6,1),val(8,0),  val(1,1),val(5,1),val(2,1)],
        [val(6,1),val(5,1),val(3,0),  val(1,0),val(2,0),val(7,1),  val(8,0),val(9,1),val(4,0)],
        [val(2,0),val(8,0),val(1,0),  val(4,0),val(9,1),val(5,0),  val(6,0),val(7,0),val(3,1)],

        [val(9,0),val(1,0),val(5,0),  val(2,0),val(8,1),val(4,0),  val(7,1),val(3,1),val(6,0)],
        [val(3,0),val(6,0),val(2,1),  val(9,0),val(7,0),val(1,0),  val(4,0),val(8,0),val(5,1)],
        [val(7,1),val(4,1),val(8,0),  val(6,0),val(5,0),val(3,0),  val(2,0),val(1,0),val(9,0)],
    ],

    // Puzzle 52 of 200
    [
        [val(5,0),val(6,1),val(8,0),  val(1,0),val(3,0),val(4,1),  val(7,0),val(2,1),val(9,1)],
        [val(7,0),val(2,1),val(9,0),  val(6,0),val(5,1),val(8,0),  val(1,0),val(4,0),val(3,0)],
        [val(4,0),val(3,0),val(1,0),  val(9,1),val(2,0),val(7,0),  val(6,1),val(8,1),val(5,0)],

        [val(9,0),val(4,1),val(2,1),  val(7,0),val(6,0),val(5,1),  val(3,1),val(1,0),val(8,1)],
        [val(6,1),val(7,0),val(5,0),  val(8,0),val(1,1),val(3,0),  val(2,0),val(9,0),val(4,0)],
        [val(1,1),val(8,0),val(3,0),  val(2,0),val(4,0),val(9,0),  val(5,1),val(6,0),val(7,0)],

        [val(8,0),val(1,1),val(7,1),  val(5,0),val(9,0),val(2,0),  val(4,0),val(3,0),val(6,0)],
        [val(3,0),val(5,0),val(6,0),  val(4,0),val(8,1),val(1,0),  val(9,0),val(7,0),val(2,1)],
        [val(2,0),val(9,0),val(4,0),  val(3,1),val(7,0),val(6,1),  val(8,1),val(5,0),val(1,0)],
    ],

    // Puzzle 53 of 200
    [
        [val(4,0),val(3,0),val(7,1),  val(6,1),val(1,0),val(5,0),  val(8,0),val(9,1),val(2,0)],
        [val(8,1),val(9,0),val(2,0),  val(7,0),val(4,1),val(3,0),  val(5,1),val(1,0),val(6,0)],
        [val(6,0),val(5,0),val(1,0),  val(8,0),val(9,0),val(2,0),  val(3,0),val(7,0),val(4,0)],

        [val(1,1),val(7,1),val(8,0),  val(5,0),val(6,0),val(9,1),  val(4,0),val(2,1),val(3,1)],
        [val(2,1),val(4,0),val(3,0),  val(1,1),val(8,0),val(7,1),  val(6,0),val(5,0),val(9,1)],
        [val(5,1),val(6,0),val(9,0),  val(3,0),val(2,0),val(4,0),  val(7,0),val(8,0),val(1,0)],

        [val(9,0),val(2,0),val(5,0),  val(4,0),val(3,1),val(8,1),  val(1,0),val(6,0),val(7,1)],
        [val(7,0),val(1,1),val(4,0),  val(9,0),val(5,1),val(6,0),  val(2,1),val(3,0),val(8,0)],
        [val(3,0),val(8,0),val(6,0),  val(2,0),val(7,1),val(1,0),  val(9,0),val(4,1),val(5,0)],
    ],

    // Puzzle 54 of 200
    [
        [val(6,0),val(4,0),val(9,1),  val(1,0),val(7,0),val(2,1),  val(5,1),val(3,0),val(8,0)],
        [val(8,0),val(5,0),val(7,1),  val(3,1),val(6,1),val(9,0),  val(2,0),val(4,1),val(1,0)],
        [val(2,1),val(3,0),val(1,0),  val(8,0),val(5,0),val(4,1),  val(7,0),val(9,0),val(6,0)],

        [val(4,1),val(7,0),val(5,0),  val(2,0),val(8,1),val(1,0),  val(9,0),val(6,1),val(3,0)],
        [val(9,0),val(1,1),val(6,0),  val(5,1),val(3,1),val(7,0),  val(8,0),val(2,0),val(4,0)],
        [val(3,0),val(8,0),val(2,0),  val(9,0),val(4,0),val(6,0),  val(1,0),val(5,0),val(7,0)],

        [val(5,0),val(2,0),val(3,1),  val(4,1),val(1,0),val(8,0),  val(6,0),val(7,0),val(9,1)],
        [val(7,0),val(9,1),val(8,1),  val(6,0),val(2,0),val(3,0),  val(4,0),val(1,1),val(5,1)],
        [val(1,1),val(6,0),val(4,0),  val(7,0),val(9,0),val(5,0),  val(3,0),val(8,0),val(2,1)],
    ],

    // Puzzle 55 of 200
    [
        [val(9,0),val(2,0),val(7,1),  val(6,1),val(8,1),val(1,0),  val(5,0),val(4,0),val(3,0)],
        [val(5,0),val(4,0),val(1,0),  val(9,1),val(7,0),val(3,0),  val(2,0),val(6,0),val(8,0)],
        [val(3,0),val(8,1),val(6,0),  val(5,0),val(2,1),val(4,0),  val(7,0),val(9,1),val(1,1)],

        [val(7,0),val(1,0),val(4,1),  val(2,1),val(6,0),val(5,1),  val(3,1),val(8,1),val(9,0)],
        [val(6,0),val(9,0),val(5,1),  val(7,0),val(3,0),val(8,0),  val(4,0),val(1,0),val(2,0)],
        [val(8,0),val(3,1),val(2,0),  val(4,0),val(1,0),val(9,0),  val(6,0),val(7,1),val(5,0)],

        [val(2,1),val(7,0),val(9,0),  val(1,0),val(5,1),val(6,0),  val(8,1),val(3,0),val(4,1)],
        [val(1,0),val(6,1),val(8,0),  val(3,0),val(4,0),val(2,0),  val(9,0),val(5,0),val(7,0)],
        [val(4,1),val(5,0),val(3,0),  val(8,1),val(9,0),val(7,0),  val(1,1),val(2,0),val(6,1)],
    ],

    // Puzzle 56 of 200
    [
        [val(3,0),val(7,1),val(6,0),  val(5,0),val(9,0),val(4,1),  val(2,0),val(1,1),val(8,0)],
        [val(4,0),val(5,1),val(9,0),  val(2,0),val(8,1),val(1,1),  val(7,0),val(6,0),val(3,0)],
        [val(8,0),val(1,0),val(2,0),  val(7,1),val(3,1),val(6,0),  val(4,0),val(9,1),val(5,0)],

        [val(1,0),val(2,0),val(7,0),  val(6,0),val(5,1),val(3,0),  val(8,1),val(4,0),val(9,0)],
        [val(6,1),val(9,1),val(8,0),  val(4,0),val(2,0),val(7,0),  val(5,1),val(3,0),val(1,0)],
        [val(5,0),val(3,0),val(4,1),  val(8,1),val(1,0),val(9,0),  val(6,1),val(2,0),val(7,0)],

        [val(7,0),val(4,0),val(3,0),  val(1,0),val(6,1),val(8,0),  val(9,1),val(5,0),val(2,0)],
        [val(2,1),val(6,0),val(1,0),  val(9,0),val(7,0),val(5,1),  val(3,1),val(8,0),val(4,0)],
        [val(9,0),val(8,0),val(5,0),  val(3,0),val(4,1),val(2,0),  val(1,0),val(7,0),val(6,1)],
    ],

    // Puzzle 57 of 200
    [
        [val(8,1),val(7,0),val(9,0),  val(6,0),val(3,0),val(5,1),  val(1,0),val(2,0),val(4,0)],
        [val(5,0),val(2,1),val(6,0),  val(4,1),val(1,0),val(9,1),  val(3,1),val(7,1),val(8,0)],
        [val(4,0),val(3,0),val(1,0),  val(8,1),val(2,0),val(7,0),  val(6,0),val(5,0),val(9,1)],

        [val(1,0),val(4,0),val(7,0),  val(5,0),val(9,0),val(2,0),  val(8,0),val(6,0),val(3,0)],
        [val(3,0),val(5,0),val(2,0),  val(1,1),val(6,1),val(8,0),  val(9,0),val(4,0),val(7,1)],
        [val(9,1),val(6,0),val(8,0),  val(7,0),val(4,0),val(3,1),  val(5,1),val(1,0),val(2,0)],

        [val(7,0),val(9,0),val(5,1),  val(2,0),val(8,0),val(6,0),  val(4,0),val(3,1),val(1,1)],
        [val(6,0),val(1,1),val(3,0),  val(9,1),val(7,1),val(4,1),  val(2,0),val(8,0),val(5,0)],
        [val(2,1),val(8,0),val(4,1),  val(3,0),val(5,0),val(1,0),  val(7,0),val(9,0),val(6,0)],
    ],

    // Puzzle 58 of 200
    [
        [val(8,0),val(4,0),val(7,0),  val(9,0),val(5,1),val(2,0),  val(6,1),val(3,1),val(1,0)],
        [val(9,0),val(2,0),val(1,0),  val(6,0),val(7,0),val(3,0),  val(5,0),val(8,0),val(4,1)],
        [val(6,0),val(3,1),val(5,0),  val(4,0),val(8,1),val(1,0),  val(9,0),val(7,1),val(2,1)],

        [val(1,0),val(9,0),val(3,0),  val(7,1),val(4,1),val(8,0),  val(2,0),val(6,0),val(5,0)],
        [val(4,1),val(5,1),val(8,1),  val(1,1),val(2,0),val(6,0),  val(7,0),val(9,0),val(3,0)],
        [val(7,0),val(6,1),val(2,1),  val(5,0),val(3,0),val(9,1),  val(1,0),val(4,0),val(8,0)],

        [val(2,0),val(7,0),val(6,0),  val(8,0),val(1,1),val(4,0),  val(3,0),val(5,0),val(9,0)],
        [val(3,0),val(8,1),val(9,1),  val(2,0),val(6,0),val(5,0),  val(4,1),val(1,0),val(7,0)],
        [val(5,1),val(1,0),val(4,1),  val(3,0),val(9,0),val(7,1),  val(8,1),val(2,0),val(6,0)],
    ],

    // Puzzle 59 of 200
    [
        [val(9,0),val(7,1),val(3,1),  val(1,0),val(2,0),val(4,0),  val(5,0),val(6,0),val(8,0)],
        [val(5,0),val(4,1),val(8,0),  val(9,0),val(6,1),val(7,0),  val(3,1),val(2,1),val(1,0)],
        [val(6,0),val(2,1),val(1,0),  val(8,1),val(5,0),val(3,0),  val(7,0),val(9,1),val(4,0)],

        [val(3,0),val(8,0),val(7,0),  val(5,0),val(9,0),val(2,0),  val(1,0),val(4,0),val(6,1)],
        [val(2,0),val(6,0),val(5,0),  val(4,0),val(1,1),val(8,0),  val(9,0),val(3,1),val(7,1)],
        [val(1,1),val(9,0),val(4,1),  val(3,0),val(7,0),val(6,0),  val(8,1),val(5,0),val(2,0)],

        [val(4,0),val(5,0),val(9,0),  val(2,0),val(8,0),val(1,0),  val(6,0),val(7,0),val(3,0)],
        [val(7,0),val(1,0),val(2,0),  val(6,1),val(3,0),val(9,1),  val(4,1),val(8,0),val(5,0)],
        [val(8,1),val(3,1),val(6,1),  val(7,1),val(4,0),val(5,0),  val(2,0),val(1,0),val(9,0)],
    ],

    // Puzzle 60 of 200
    [
        [val(6,0),val(8,0),val(1,0),  val(2,0),val(3,0),val(7,1),  val(5,1),val(9,0),val(4,1)],
        [val(7,0),val(3,1),val(4,0),  val(1,0),val(5,1),val(9,0),  val(2,0),val(8,0),val(6,0)],
        [val(9,1),val(2,0),val(5,1),  val(6,0),val(4,0),val(8,0),  val(3,1),val(7,0),val(1,1)],

        [val(5,0),val(6,0),val(7,1),  val(8,0),val(9,0),val(2,1),  val(1,0),val(4,1),val(3,0)],
        [val(1,1),val(4,0),val(8,0),  val(5,0),val(6,1),val(3,1),  val(7,0),val(2,1),val(9,1)],
        [val(3,1),val(9,0),val(2,0),  val(4,0),val(7,0),val(1,0),  val(6,0),val(5,0),val(8,0)],

        [val(8,1),val(7,1),val(9,0),  val(3,0),val(1,0),val(5,0),  val(4,0),val(6,1),val(2,1)],
        [val(2,0),val(1,0),val(6,0),  val(7,0),val(8,1),val(4,0),  val(9,1),val(3,0),val(5,0)],
        [val(4,0),val(5,0),val(3,1),  val(9,0),val(2,1),val(6,1),  val(8,0),val(1,0),val(7,0)],
    ],

    // Puzzle 61 of 200
    [
        [val(2,0),val(5,0),val(9,1),  val(4,1),val(6,0),val(7,0),  val(3,0),val(8,0),val(1,0)],
        [val(8,0),val(3,0),val(1,0),  val(5,0),val(9,0),val(2,1),  val(4,1),val(6,0),val(7,0)],
        [val(6,0),val(7,1),val(4,0),  val(3,0),val(8,1),val(1,0),  val(2,1),val(5,0),val(9,0)],

        [val(3,1),val(6,0),val(5,1),  val(9,0),val(4,1),val(8,0),  val(7,1),val(1,0),val(2,0)],
        [val(7,0),val(4,0),val(8,0),  val(2,1),val(1,0),val(5,0),  val(9,0),val(3,1),val(6,1)],
        [val(1,1),val(9,0),val(2,0),  val(7,0),val(3,0),val(6,0),  val(5,0),val(4,0),val(8,1)],

        [val(5,1),val(1,0),val(7,0),  val(8,1),val(2,0),val(3,1),  val(6,0),val(9,0),val(4,0)],
        [val(4,1),val(2,0),val(6,0),  val(1,0),val(5,0),val(9,0),  val(8,0),val(7,0),val(3,1)],
        [val(9,0),val(8,0),val(3,0),  val(6,0),val(7,1),val(4,0),  val(1,1),val(2,0),val(5,0)],
    ],

    // Puzzle 62 of 200
    [
        [val(1,0),val(5,0),val(2,0),  val(3,0),val(6,0),val(9,0),  val(4,0),val(7,1),val(8,0)],
        [val(7,0),val(4,0),val(8,1),  val(5,0),val(2,0),val(1,0),  val(3,1),val(9,0),val(6,0)],
        [val(9,1),val(3,1),val(6,0),  val(8,0),val(7,0),val(4,1),  val(1,0),val(2,1),val(5,0)],

        [val(2,1),val(9,0),val(1,0),  val(4,0),val(8,0),val(3,0),  val(6,0),val(5,1),val(7,0)],
        [val(5,0),val(6,0),val(4,1),  val(1,0),val(9,0),val(7,0),  val(2,0),val(8,1),val(3,1)],
        [val(3,1),val(8,0),val(7,0),  val(6,1),val(5,0),val(2,0),  val(9,1),val(1,0),val(4,0)],

        [val(6,0),val(2,0),val(3,0),  val(7,1),val(1,1),val(5,0),  val(8,0),val(4,0),val(9,1)],
        [val(8,0),val(7,0),val(9,1),  val(2,1),val(4,0),val(6,0),  val(5,1),val(3,0),val(1,0)],
        [val(4,0),val(1,0),val(5,0),  val(9,0),val(3,1),val(8,1),  val(7,0),val(6,1),val(2,0)],
    ],

    // Puzzle 63 of 200
    [
        [val(1,1),val(6,0),val(3,0),  val(4,0),val(7,0),val(5,1),  val(2,1),val(9,1),val(8,1)],
        [val(8,1),val(7,0),val(5,0),  val(1,0),val(9,0),val(2,0),  val(4,0),val(6,0),val(3,1)],
        [val(2,1),val(4,0),val(9,0),  val(8,0),val(6,1),val(3,0),  val(1,0),val(7,1),val(5,0)],

        [val(5,0),val(8,0),val(1,0),  val(6,0),val(3,1),val(4,0),  val(7,1),val(2,0),val(9,0)],
        [val(4,0),val(3,1),val(7,1),  val(2,0),val(5,0),val(9,0),  val(6,0),val(8,0),val(1,1)],
        [val(6,0),val(9,0),val(2,0),  val(7,0),val(8,1),val(1,0),  val(5,0),val(3,0),val(4,1)],

        [val(9,0),val(2,1),val(8,0),  val(5,0),val(4,0),val(6,1),  val(3,0),val(1,0),val(7,0)],
        [val(7,0),val(1,1),val(4,0),  val(3,1),val(2,0),val(8,0),  val(9,0),val(5,0),val(6,0)],
        [val(3,0),val(5,0),val(6,0),  val(9,1),val(1,0),val(7,1),  val(8,0),val(4,1),val(2,0)],
    ],

    // Puzzle 64 of 200
    [
        [val(9,0),val(6,1),val(2,0),  val(7,1),val(8,0),val(1,0),  val(5,1),val(3,1),val(4,0)],
        [val(7,1),val(1,1),val(4,0),  val(9,1),val(3,0),val(5,0),  val(2,0),val(8,0),val(6,0)],
        [val(8,0),val(5,0),val(3,0),  val(6,0),val(2,0),val(4,1),  val(7,0),val(9,0),val(1,0)],

        [val(1,0),val(4,0),val(6,0),  val(2,1),val(9,0),val(8,0),  val(3,0),val(7,0),val(5,0)],
        [val(3,0),val(2,0),val(9,1),  val(1,0),val(5,1),val(7,0),  val(4,0),val(6,0),val(8,1)],
        [val(5,0),val(7,0),val(8,1),  val(4,0),val(6,1),val(3,1),  val(1,1),val(2,1),val(9,0)],

        [val(2,0),val(8,0),val(7,0),  val(5,0),val(4,0),val(9,0),  val(6,1),val(1,0),val(3,0)],
        [val(4,0),val(3,1),val(1,0),  val(8,0),val(7,0),val(6,0),  val(9,1),val(5,0),val(2,0)],
        [val(6,0),val(9,0),val(5,1),  val(3,0),val(1,0),val(2,1),  val(8,0),val(4,1),val(7,0)],
    ],

    // Puzzle 65 of 200
    [
        [val(3,1),val(7,0),val(2,0),  val(4,0),val(9,0),val(5,1),  val(1,0),val(6,0),val(8,1)],
        [val(6,0),val(1,0),val(4,1),  val(8,0),val(7,1),val(3,0),  val(5,1),val(9,0),val(2,0)],
        [val(9,0),val(8,0),val(5,0),  val(6,0),val(1,1),val(2,0),  val(4,0),val(3,0),val(7,0)],

        [val(5,0),val(6,0),val(7,1),  val(9,0),val(3,1),val(8,0),  val(2,0),val(4,0),val(1,0)],
        [val(2,0),val(9,0),val(3,0),  val(1,0),val(4,1),val(7,0),  val(6,0),val(8,0),val(5,1)],
        [val(1,1),val(4,0),val(8,0),  val(5,0),val(2,0),val(6,1),  val(3,0),val(7,0),val(9,1)],

        [val(4,0),val(3,1),val(1,0),  val(7,0),val(5,1),val(9,1),  val(8,0),val(2,1),val(6,0)],
        [val(7,0),val(2,0),val(6,1),  val(3,0),val(8,0),val(1,0),  val(9,0),val(5,0),val(4,0)],
        [val(8,1),val(5,0),val(9,1),  val(2,0),val(6,0),val(4,1),  val(7,1),val(1,1),val(3,0)],
    ],

    // Puzzle 66 of 200
    [
        [val(6,1),val(7,0),val(4,1),  val(9,1),val(1,0),val(8,0),  val(5,0),val(3,0),val(2,1)],
        [val(8,1),val(9,0),val(3,1),  val(2,1),val(5,0),val(4,0),  val(7,1),val(6,1),val(1,0)],
        [val(1,0),val(5,0),val(2,1),  val(7,0),val(3,0),val(6,0),  val(9,0),val(4,0),val(8,1)],

        [val(5,0),val(8,0),val(1,0),  val(6,0),val(2,1),val(7,1),  val(4,0),val(9,1),val(3,0)],
        [val(7,0),val(2,0),val(6,0),  val(3,0),val(4,0),val(9,0),  val(8,1),val(1,0),val(5,1)],
        [val(4,0),val(3,0),val(9,0),  val(1,0),val(8,0),val(5,0),  val(2,0),val(7,0),val(6,0)],

        [val(3,0),val(4,1),val(8,0),  val(5,0),val(7,1),val(1,1),  val(6,1),val(2,0),val(9,0)],
        [val(2,0),val(6,0),val(5,0),  val(4,0),val(9,0),val(3,1),  val(1,0),val(8,0),val(7,1)],
        [val(9,0),val(1,1),val(7,0),  val(8,0),val(6,1),val(2,0),  val(3,1),val(5,1),val(4,0)],
    ],

    // Puzzle 67 of 200
    [
        [val(2,1),val(3,0),val(7,0),  val(9,0),val(8,0),val(6,1),  val(4,0),val(5,0),val(1,1)],
        [val(1,0),val(4,1),val(6,0),  val(2,0),val(3,0),val(5,1),  val(7,0),val(8,0),val(9,1)],
        [val(8,1),val(9,0),val(5,0),  val(7,1),val(1,0),val(4,0),  val(6,0),val(2,0),val(3,0)],

        [val(6,1),val(2,0),val(8,0),  val(1,0),val(5,0),val(7,1),  val(9,0),val(3,0),val(4,0)],
        [val(3,0),val(7,1),val(9,1),  val(8,0),val(4,1),val(2,0),  val(1,0),val(6,1),val(5,0)],
        [val(5,0),val(1,1),val(4,0),  val(6,0),val(9,0),val(3,0),  val(2,0),val(7,1),val(8,1)],

        [val(4,0),val(6,0),val(1,0),  val(5,0),val(7,0),val(8,0),  val(3,0),val(9,1),val(2,0)],
        [val(9,0),val(8,0),val(2,1),  val(3,0),val(6,0),val(1,0),  val(5,1),val(4,1),val(7,0)],
        [val(7,0),val(5,1),val(3,0),  val(4,1),val(2,0),val(9,0),  val(8,0),val(1,1),val(6,1)],
    ],

    // Puzzle 68 of 200
    [
        [val(5,0),val(6,1),val(9,1),  val(2,0),val(7,0),val(1,1),  val(4,0),val(3,0),val(8,0)],
        [val(2,0),val(8,0),val(3,0),  val(5,1),val(6,0),val(4,0),  val(1,0),val(9,1),val(7,0)],
        [val(7,1),val(4,1),val(1,0),  val(3,1),val(8,1),val(9,0),  val(6,0),val(5,0),val(2,1)],

        [val(6,0),val(1,1),val(4,1),  val(9,0),val(3,0),val(7,0),  val(8,0),val(2,0),val(5,0)],
        [val(8,0),val(7,0),val(2,1),  val(4,1),val(1,0),val(5,0),  val(3,0),val(6,1),val(9,1)],
        [val(3,1),val(9,0),val(5,0),  val(8,0),val(2,0),val(6,0),  val(7,0),val(1,1),val(4,0)],

        [val(4,0),val(5,0),val(6,0),  val(1,0),val(9,0),val(8,0),  val(2,0),val(7,0),val(3,0)],
        [val(9,1),val(2,0),val(7,0),  val(6,1),val(4,0),val(3,1),  val(5,1),val(8,0),val(1,0)],
        [val(1,0),val(3,0),val(8,1),  val(7,1),val(5,0),val(2,0),  val(9,0),val(4,0),val(6,0)],
    ],

    // Puzzle 69 of 200
    [
        [val(3,0),val(6,0),val(2,1),  val(9,1),val(4,0),val(7,1),  val(5,0),val(1,0),val(8,0)],
        [val(8,0),val(5,1),val(1,1),  val(3,0),val(2,0),val(6,0),  val(7,0),val(9,0),val(4,0)],
        [val(9,0),val(4,0),val(7,0),  val(1,0),val(8,1),val(5,1),  val(6,0),val(2,1),val(3,0)],

        [val(5,0),val(3,1),val(8,0),  val(2,0),val(1,0),val(4,0),  val(9,0),val(6,1),val(7,0)],
        [val(7,0),val(1,1),val(6,0),  val(5,0),val(9,0),val(8,1),  val(4,0),val(3,0),val(2,1)],
        [val(4,1),val(2,1),val(9,1),  val(7,0),val(6,1),val(3,0),  val(1,0),val(8,0),val(5,1)],

        [val(1,0),val(8,0),val(4,1),  val(6,0),val(7,0),val(2,0),  val(3,0),val(5,1),val(9,0)],
        [val(2,0),val(9,0),val(3,0),  val(4,0),val(5,0),val(1,1),  val(8,1),val(7,0),val(6,0)],
        [val(6,0),val(7,1),val(5,0),  val(8,0),val(3,1),val(9,1),  val(2,0),val(4,0),val(1,1)],
    ],

    // Puzzle 70 of 200
    [
        [val(2,0),val(5,1),val(1,1),  val(3,0),val(7,1),val(4,0),  val(8,0),val(9,1),val(6,0)],
        [val(7,0),val(3,0),val(6,0),  val(8,0),val(9,0),val(1,0),  val(4,0),val(5,1),val(2,1)],
        [val(8,0),val(4,1),val(9,0),  val(5,0),val(6,1),val(2,1),  val(1,0),val(7,0),val(3,0)],

        [val(1,0),val(7,0),val(2,1),  val(9,1),val(8,1),val(6,0),  val(3,0),val(4,0),val(5,0)],
        [val(4,0),val(6,0),val(3,1),  val(7,1),val(1,0),val(5,0),  val(2,0),val(8,1),val(9,0)],
        [val(9,0),val(8,0),val(5,0),  val(4,0),val(2,0),val(3,1),  val(7,0),val(6,0),val(1,1)],

        [val(6,0),val(1,1),val(7,1),  val(2,0),val(4,1),val(9,0),  val(5,0),val(3,0),val(8,0)],
        [val(3,0),val(2,0),val(8,0),  val(6,1),val(5,0),val(7,0),  val(9,1),val(1,0),val(4,0)],
        [val(5,1),val(9,0),val(4,0),  val(1,0),val(3,0),val(8,1),  val(6,0),val(2,0),val(7,0)],
    ],

    // Puzzle 71 of 200
    [
        [val(7,0),val(6,0),val(3,1),  val(8,0),val(2,1),val(4,0),  val(1,0),val(9,0),val(5,1)],
        [val(2,0),val(9,0),val(1,0),  val(3,1),val(5,0),val(7,0),  val(6,0),val(4,1),val(8,0)],
        [val(8,0),val(5,0),val(4,1),  val(6,1),val(1,1),val(9,0),  val(3,0),val(2,0),val(7,0)],

        [val(1,1),val(4,0),val(2,0),  val(5,0),val(9,1),val(3,0),  val(8,0),val(7,1),val(6,1)],
        [val(5,1),val(8,0),val(7,0),  val(2,0),val(6,0),val(1,0),  val(4,1),val(3,0),val(9,0)],
        [val(9,1),val(3,0),val(6,0),  val(7,1),val(4,0),val(8,0),  val(5,0),val(1,1),val(2,0)],

        [val(3,0),val(1,1),val(8,0),  val(9,0),val(7,0),val(6,0),  val(2,0),val(5,0),val(4,0)],
        [val(4,0),val(2,0),val(9,0),  val(1,0),val(8,0),val(5,0),  val(7,1),val(6,1),val(3,1)],
        [val(6,1),val(7,0),val(5,0),  val(4,0),val(3,0),val(2,1),  val(9,0),val(8,1),val(1,0)],
    ],

    // Puzzle 72 of 200
    [
        [val(5,1),val(6,0),val(9,0),  val(4,0),val(3,0),val(7,0),  val(2,1),val(8,0),val(1,0)],
        [val(1,0),val(2,0),val(4,0),  val(5,0),val(6,0),val(8,0),  val(7,0),val(9,1),val(3,1)],
        [val(8,0),val(7,1),val(3,1),  val(9,0),val(1,0),val(2,0),  val(6,1),val(4,0),val(5,0)],

        [val(6,0),val(3,0),val(8,0),  val(2,0),val(7,1),val(4,0),  val(5,1),val(1,1),val(9,0)],
        [val(2,0),val(1,1),val(5,0),  val(6,1),val(8,1),val(9,1),  val(3,1),val(7,0),val(4,0)],
        [val(4,0),val(9,0),val(7,0),  val(3,0),val(5,0),val(1,0),  val(8,0),val(2,0),val(6,1)],

        [val(7,1),val(4,0),val(6,1),  val(8,0),val(9,0),val(5,1),  val(1,0),val(3,0),val(2,0)],
        [val(9,0),val(5,0),val(1,1),  val(7,0),val(2,0),val(3,0),  val(4,0),val(6,0),val(8,0)],
        [val(3,0),val(8,1),val(2,0),  val(1,0),val(4,1),val(6,0),  val(9,1),val(5,0),val(7,1)],
    ],

    // Puzzle 73 of 200
    [
        [val(7,0),val(8,0),val(1,0),  val(9,0),val(5,0),val(2,0),  val(4,1),val(6,0),val(3,0)],
        [val(5,1),val(2,1),val(9,0),  val(3,1),val(6,0),val(4,0),  val(7,0),val(1,1),val(8,1)],
        [val(4,0),val(6,1),val(3,0),  val(8,0),val(1,0),val(7,0),  val(9,0),val(5,0),val(2,1)],

        [val(1,0),val(7,0),val(4,1),  val(6,0),val(9,0),val(8,0),  val(3,0),val(2,0),val(5,0)],
        [val(6,0),val(3,0),val(2,0),  val(7,1),val(4,0),val(5,1),  val(1,0),val(8,0),val(9,0)],
        [val(8,1),val(9,1),val(5,0),  val(2,1),val(3,1),val(1,0),  val(6,0),val(4,0),val(7,0)],

        [val(2,0),val(4,0),val(8,0),  val(1,0),val(7,0),val(3,0),  val(5,0),val(9,1),val(6,1)],
        [val(9,0),val(5,1),val(7,0),  val(4,0),val(2,0),val(6,0),  val(8,0),val(3,1),val(1,0)],
        [val(3,1),val(1,0),val(6,0),  val(5,1),val(8,1),val(9,0),  val(2,0),val(7,1),val(4,1)],
    ],

    // Puzzle 74 of 200
    [
        [val(7,0),val(9,1),val(3,0),  val(4,0),val(2,0),val(6,0),  val(8,0),val(5,1),val(1,1)],
        [val(2,0),val(8,0),val(6,0),  val(5,0),val(7,1),val(1,0),  val(9,0),val(3,0),val(4,0)],
        [val(1,1),val(5,0),val(4,0),  val(9,1),val(8,1),val(3,0),  val(6,1),val(7,0),val(2,0)],

        [val(9,1),val(6,0),val(1,1),  val(7,1),val(5,0),val(8,0),  val(4,0),val(2,0),val(3,0)],
        [val(3,0),val(7,1),val(8,1),  val(2,0),val(6,0),val(4,1),  val(1,0),val(9,0),val(5,0)],
        [val(5,1),val(4,0),val(2,0),  val(3,0),val(1,0),val(9,0),  val(7,0),val(8,0),val(6,1)],

        [val(4,0),val(3,1),val(7,1),  val(6,0),val(9,0),val(5,0),  val(2,0),val(1,1),val(8,0)],
        [val(6,0),val(1,0),val(9,0),  val(8,0),val(3,0),val(2,1),  val(5,0),val(4,1),val(7,0)],
        [val(8,0),val(2,1),val(5,0),  val(1,0),val(4,1),val(7,0),  val(3,0),val(6,0),val(9,1)],
    ],

    // Puzzle 75 of 200
    [
        [val(7,0),val(3,0),val(2,1),  val(5,0),val(9,0),val(1,0),  val(4,0),val(6,0),val(8,0)],
        [val(1,1),val(5,1),val(9,1),  val(8,1),val(4,0),val(6,0),  val(2,0),val(7,1),val(3,0)],
        [val(6,0),val(8,0),val(4,1),  val(3,0),val(2,0),val(7,0),  val(1,0),val(5,0),val(9,1)],

        [val(8,1),val(2,0),val(1,0),  val(7,1),val(3,0),val(9,0),  val(5,1),val(4,0),val(6,1)],
        [val(3,1),val(6,0),val(7,0),  val(1,0),val(5,0),val(4,1),  val(8,1),val(9,0),val(2,0)],
        [val(4,0),val(9,1),val(5,0),  val(6,0),val(8,0),val(2,0),  val(3,0),val(1,1),val(7,0)],

        [val(2,1),val(7,0),val(8,0),  val(9,0),val(1,1),val(5,1),  val(6,0),val(3,0),val(4,0)],
        [val(9,0),val(1,0),val(3,0),  val(4,1),val(6,1),val(8,0),  val(7,0),val(2,0),val(5,0)],
        [val(5,1),val(4,0),val(6,1),  val(2,0),val(7,0),val(3,1),  val(9,0),val(8,0),val(1,0)],
    ],

    // Puzzle 76 of 200
    [
        [val(6,0),val(9,0),val(3,1),  val(2,0),val(5,0),val(4,1),  val(1,0),val(7,0),val(8,0)],
        [val(1,1),val(7,0),val(4,0),  val(3,0),val(8,0),val(9,0),  val(2,0),val(5,1),val(6,0)],
        [val(8,0),val(2,1),val(5,1),  val(6,0),val(1,0),val(7,1),  val(9,0),val(3,0),val(4,0)],

        [val(5,0),val(3,0),val(2,0),  val(4,0),val(7,0),val(8,0),  val(6,0),val(1,0),val(9,1)],
        [val(9,0),val(1,0),val(8,0),  val(5,0),val(6,1),val(3,1),  val(4,1),val(2,1),val(7,0)],
        [val(7,0),val(4,0),val(6,0),  val(1,1),val(9,0),val(2,0),  val(5,1),val(8,1),val(3,0)],

        [val(4,1),val(6,0),val(1,0),  val(7,0),val(3,0),val(5,0),  val(8,0),val(9,0),val(2,0)],
        [val(2,0),val(8,1),val(7,1),  val(9,1),val(4,0),val(1,0),  val(3,0),val(6,0),val(5,0)],
        [val(3,1),val(5,0),val(9,0),  val(8,1),val(2,0),val(6,1),  val(7,0),val(4,1),val(1,1)],
    ],

    // Puzzle 77 of 200
    [
        [val(5,0),val(6,1),val(2,0),  val(4,0),val(9,0),val(8,1),  val(7,0),val(3,0),val(1,0)],
        [val(4,0),val(1,0),val(8,1),  val(6,0),val(3,0),val(7,0),  val(2,1),val(5,1),val(9,0)],
        [val(3,0),val(7,0),val(9,0),  val(5,1),val(1,1),val(2,0),  val(8,0),val(4,1),val(6,0)],

        [val(1,0),val(2,0),val(4,0),  val(3,1),val(6,0),val(5,1),  val(9,0),val(8,0),val(7,1)],
        [val(9,1),val(8,0),val(3,0),  val(7,1),val(4,0),val(1,0),  val(6,0),val(2,1),val(5,1)],
        [val(7,0),val(5,0),val(6,1),  val(2,0),val(8,0),val(9,0),  val(4,1),val(1,1),val(3,0)],

        [val(2,0),val(9,0),val(5,1),  val(1,1),val(7,0),val(4,0),  val(3,0),val(6,1),val(8,0)],
        [val(8,1),val(3,1),val(1,0),  val(9,1),val(2,0),val(6,0),  val(5,1),val(7,0),val(4,0)],
        [val(6,0),val(4,0),val(7,0),  val(8,0),val(5,0),val(3,0),  val(1,0),val(9,0),val(2,0)],
    ],

    // Puzzle 78 of 200
    [
        [val(6,0),val(5,0),val(3,1),  val(8,0),val(1,0),val(7,0),  val(9,0),val(2,0),val(4,0)],
        [val(7,1),val(9,0),val(2,0),  val(4,0),val(3,0),val(5,0),  val(1,1),val(8,1),val(6,0)],
        [val(1,0),val(8,0),val(4,1),  val(2,1),val(9,0),val(6,1),  val(7,1),val(3,0),val(5,0)],

        [val(4,0),val(6,1),val(5,0),  val(1,0),val(7,1),val(8,0),  val(3,1),val(9,0),val(2,0)],
        [val(9,0),val(2,0),val(7,0),  val(3,1),val(6,0),val(4,1),  val(8,0),val(5,0),val(1,0)],
        [val(8,1),val(3,0),val(1,1),  val(9,0),val(5,0),val(2,1),  val(4,0),val(6,1),val(7,0)],

        [val(3,0),val(4,0),val(6,0),  val(7,1),val(2,0),val(9,0),  val(5,0),val(1,1),val(8,0)],
        [val(2,0),val(7,0),val(9,1),  val(5,0),val(8,1),val(1,0),  val(6,0),val(4,1),val(3,0)],
        [val(5,0),val(1,0),val(8,0),  val(6,1),val(4,0),val(3,0),  val(2,0),val(7,0),val(9,1)],
    ],

    // Puzzle 79 of 200
    [
        [val(2,0),val(4,1),val(9,1),  val(3,0),val(7,0),val(8,0),  val(1,1),val(6,0),val(5,0)],
        [val(8,0),val(5,0),val(3,0),  val(6,0),val(9,1),val(1,0),  val(2,1),val(7,0),val(4,0)],
        [val(1,0),val(7,1),val(6,1),  val(4,0),val(2,0),val(5,0),  val(8,0),val(9,0),val(3,1)],

        [val(7,0),val(1,0),val(4,1),  val(5,0),val(8,0),val(6,1),  val(9,1),val(3,0),val(2,0)],
        [val(5,1),val(6,0),val(2,0),  val(9,0),val(1,0),val(3,1),  val(4,1),val(8,0),val(7,1)],
        [val(9,0),val(3,0),val(8,0),  val(7,0),val(4,0),val(2,1),  val(6,0),val(5,0),val(1,0)],

        [val(6,0),val(2,0),val(1,0),  val(8,0),val(5,1),val(7,0),  val(3,1),val(4,0),val(9,0)],
        [val(4,0),val(8,0),val(5,1),  val(1,0),val(3,0),val(9,0),  val(7,0),val(2,0),val(6,1)],
        [val(3,1),val(9,0),val(7,0),  val(2,1),val(6,0),val(4,1),  val(5,0),val(1,0),val(8,1)],
    ],

    // Puzzle 80 of 200
    [
        [val(4,1),val(6,0),val(8,1),  val(5,1),val(2,0),val(3,0),  val(7,0),val(1,0),val(9,1)],
        [val(1,0),val(3,0),val(2,0),  val(8,1),val(7,0),val(9,0),  val(4,0),val(6,0),val(5,1)],
        [val(9,0),val(5,0),val(7,1),  val(1,0),val(4,1),val(6,0),  val(2,0),val(3,1),val(8,0)],

        [val(3,0),val(2,0),val(9,0),  val(4,1),val(5,0),val(1,1),  val(6,1),val(8,0),val(7,0)],
        [val(5,1),val(7,0),val(6,0),  val(9,0),val(3,1),val(8,0),  val(1,0),val(4,1),val(2,1)],
        [val(8,0),val(4,0),val(1,1),  val(2,0),val(6,0),val(7,1),  val(5,0),val(9,0),val(3,0)],

        [val(2,0),val(8,1),val(3,1),  val(6,0),val(1,0),val(5,0),  val(9,0),val(7,0),val(4,0)],
        [val(6,1),val(9,0),val(5,0),  val(7,0),val(8,0),val(4,0),  val(3,0),val(2,0),val(1,0)],
        [val(7,0),val(1,0),val(4,0),  val(3,0),val(9,0),val(2,0),  val(8,1),val(5,1),val(6,0)],
    ],

    // Puzzle 81 of 200
    [
        [val(3,0),val(5,0),val(6,0),  val(7,1),val(4,0),val(9,0),  val(2,0),val(1,0),val(8,1)],
        [val(4,1),val(7,0),val(2,0),  val(3,0),val(1,0),val(8,0),  val(9,0),val(6,1),val(5,0)],
        [val(9,0),val(1,0),val(8,0),  val(2,0),val(6,0),val(5,0),  val(7,0),val(4,1),val(3,1)],

        [val(7,1),val(9,0),val(3,0),  val(1,1),val(2,0),val(4,1),  val(5,1),val(8,0),val(6,0)],
        [val(8,0),val(4,0),val(5,0),  val(6,0),val(9,1),val(7,0),  val(3,0),val(2,0),val(1,0)],
        [val(6,0),val(2,0),val(1,1),  val(5,1),val(8,1),val(3,0),  val(4,1),val(7,0),val(9,1)],

        [val(1,0),val(3,1),val(4,1),  val(9,0),val(7,0),val(6,0),  val(8,0),val(5,1),val(2,0)],
        [val(5,0),val(6,0),val(7,0),  val(8,1),val(3,1),val(2,0),  val(1,0),val(9,0),val(4,0)],
        [val(2,1),val(8,0),val(9,0),  val(4,0),val(5,0),val(1,1),  val(6,1),val(3,0),val(7,0)],
    ],

    // Puzzle 82 of 200
    [
        [val(7,0),val(1,0),val(8,0),  val(6,0),val(3,0),val(5,0),  val(4,0),val(9,0),val(2,1)],
        [val(4,0),val(2,0),val(5,1),  val(1,0),val(9,1),val(8,0),  val(6,1),val(7,0),val(3,0)],
        [val(3,1),val(6,0),val(9,0),  val(7,0),val(2,0),val(4,0),  val(1,0),val(5,0),val(8,0)],

        [val(1,0),val(8,1),val(7,0),  val(3,0),val(5,0),val(6,1),  val(2,0),val(4,0),val(9,0)],
        [val(2,0),val(5,0),val(6,0),  val(4,0),val(8,0),val(9,0),  val(7,1),val(3,1),val(1,1)],
        [val(9,0),val(4,0),val(3,1),  val(2,1),val(1,1),val(7,0),  val(5,1),val(8,0),val(6,0)],

        [val(5,0),val(3,0),val(4,1),  val(9,1),val(6,0),val(2,0),  val(8,0),val(1,1),val(7,1)],
        [val(8,0),val(9,1),val(2,0),  val(5,0),val(7,0),val(1,0),  val(3,0),val(6,0),val(4,1)],
        [val(6,1),val(7,1),val(1,0),  val(8,1),val(4,0),val(3,0),  val(9,0),val(2,1),val(5,0)],
    ],

    // Puzzle 83 of 200
    [
        [val(7,0),val(5,0),val(1,0),  val(3,1),val(8,0),val(4,1),  val(9,0),val(2,1),val(6,1)],
        [val(6,1),val(9,0),val(8,1),  val(1,0),val(2,0),val(7,0),  val(3,0),val(5,0),val(4,0)],
        [val(4,1),val(3,0),val(2,0),  val(5,0),val(9,0),val(6,0),  val(8,1),val(7,1),val(1,0)],

        [val(5,1),val(2,0),val(6,0),  val(8,0),val(4,0),val(1,0),  val(7,0),val(9,0),val(3,0)],
        [val(8,0),val(4,1),val(9,0),  val(7,1),val(6,0),val(3,0),  val(5,1),val(1,0),val(2,1)],
        [val(1,0),val(7,0),val(3,1),  val(9,1),val(5,0),val(2,0),  val(6,0),val(4,0),val(8,0)],

        [val(9,0),val(1,1),val(4,0),  val(6,0),val(7,0),val(8,0),  val(2,0),val(3,1),val(5,0)],
        [val(3,0),val(6,0),val(7,1),  val(2,0),val(1,1),val(5,0),  val(4,0),val(8,1),val(9,0)],
        [val(2,0),val(8,0),val(5,0),  val(4,1),val(3,1),val(9,1),  val(1,0),val(6,0),val(7,1)],
    ],

    // Puzzle 84 of 200
    [
        [val(6,0),val(9,0),val(2,0),  val(5,1),val(4,0),val(7,0),  val(8,0),val(1,0),val(3,0)],
        [val(5,0),val(4,1),val(1,1),  val(6,0),val(3,0),val(8,0),  val(9,0),val(2,0),val(7,1)],
        [val(3,0),val(8,0),val(7,0),  val(9,1),val(2,1),val(1,1),  val(6,0),val(5,1),val(4,1)],

        [val(1,0),val(5,0),val(4,0),  val(2,0),val(7,1),val(6,0),  val(3,1),val(9,1),val(8,1)],
        [val(8,0),val(6,1),val(9,1),  val(4,1),val(1,0),val(3,0),  val(5,1),val(7,0),val(2,0)],
        [val(2,0),val(7,1),val(3,0),  val(8,0),val(5,0),val(9,0),  val(1,0),val(4,0),val(6,0)],

        [val(9,0),val(1,0),val(8,0),  val(7,0),val(6,0),val(4,0),  val(2,0),val(3,1),val(5,0)],
        [val(4,0),val(3,1),val(5,0),  val(1,1),val(8,0),val(2,0),  val(7,0),val(6,0),val(9,1)],
        [val(7,1),val(2,1),val(6,0),  val(3,0),val(9,1),val(5,0),  val(4,0),val(8,1),val(1,0)],
    ],

    // Puzzle 85 of 200
    [
        [val(8,0),val(3,1),val(2,0),  val(4,0),val(1,1),val(7,0),  val(5,0),val(9,0),val(6,0)],
        [val(9,1),val(6,0),val(5,1),  val(8,0),val(3,0),val(2,0),  val(4,0),val(7,1),val(1,0)],
        [val(7,0),val(4,0),val(1,0),  val(5,1),val(9,0),val(6,1),  val(8,0),val(2,0),val(3,0)],

        [val(2,0),val(5,1),val(9,0),  val(3,1),val(6,0),val(8,0),  val(7,0),val(1,0),val(4,1)],
        [val(1,0),val(8,1),val(3,0),  val(7,1),val(5,0),val(4,0),  val(2,0),val(6,0),val(9,1)],
        [val(4,0),val(7,1),val(6,0),  val(1,1),val(2,1),val(9,0),  val(3,0),val(5,1),val(8,1)],

        [val(3,0),val(9,0),val(7,1),  val(6,0),val(4,0),val(5,1),  val(1,1),val(8,0),val(2,1)],
        [val(6,0),val(1,0),val(8,0),  val(2,0),val(7,0),val(3,0),  val(9,0),val(4,1),val(5,1)],
        [val(5,0),val(2,0),val(4,1),  val(9,0),val(8,1),val(1,0),  val(6,1),val(3,0),val(7,0)],
    ],

    // Puzzle 86 of 200
    [
        [val(6,1),val(5,1),val(8,0),  val(2,1),val(1,0),val(9,1),  val(4,0),val(3,0),val(7,0)],
        [val(9,1),val(2,1),val(3,0),  val(5,0),val(7,1),val(4,0),  val(8,0),val(6,0),val(1,0)],
        [val(1,0),val(7,0),val(4,0),  val(3,0),val(6,0),val(8,1),  val(9,0),val(5,1),val(2,0)],

        [val(7,1),val(9,0),val(5,0),  val(1,0),val(8,1),val(3,1),  val(6,1),val(2,0),val(4,0)],
        [val(2,1),val(8,0),val(1,0),  val(6,1),val(4,0),val(5,1),  val(3,0),val(7,0),val(9,1)],
        [val(4,0),val(3,0),val(6,0),  val(9,0),val(2,0),val(7,0),  val(5,0),val(1,0),val(8,0)],

        [val(3,1),val(1,1),val(9,0),  val(4,1),val(5,0),val(2,1),  val(7,0),val(8,1),val(6,0)],
        [val(8,1),val(4,0),val(2,0),  val(7,0),val(3,0),val(6,0),  val(1,1),val(9,0),val(5,0)],
        [val(5,0),val(6,0),val(7,1),  val(8,0),val(9,0),val(1,0),  val(2,0),val(4,1),val(3,0)],
    ],

    // Puzzle 87 of 200
    [
        [val(3,1),val(9,0),val(5,1),  val(8,0),val(2,0),val(1,1),  val(7,0),val(6,0),val(4,0)],
        [val(7,0),val(2,0),val(8,0),  val(3,1),val(4,0),val(6,0),  val(1,0),val(9,0),val(5,0)],
        [val(4,1),val(1,0),val(6,0),  val(7,0),val(5,0),val(9,1),  val(2,1),val(3,0),val(8,0)],

        [val(6,1),val(5,0),val(7,0),  val(4,0),val(8,1),val(3,0),  val(9,0),val(2,0),val(1,1)],
        [val(9,0),val(3,0),val(4,1),  val(6,0),val(1,0),val(2,0),  val(5,0),val(8,0),val(7,0)],
        [val(2,0),val(8,0),val(1,0),  val(9,0),val(7,1),val(5,1),  val(3,0),val(4,1),val(6,0)],

        [val(1,1),val(4,0),val(2,0),  val(5,0),val(9,0),val(8,0),  val(6,0),val(7,1),val(3,1)],
        [val(5,0),val(7,0),val(3,0),  val(2,1),val(6,1),val(4,0),  val(8,0),val(1,1),val(9,0)],
        [val(8,0),val(6,0),val(9,1),  val(1,0),val(3,0),val(7,1),  val(4,1),val(5,1),val(2,0)],
    ],

    // Puzzle 88 of 200
    [
        [val(5,0),val(6,1),val(2,1),  val(4,0),val(3,0),val(7,0),  val(1,0),val(9,0),val(8,0)],
        [val(7,1),val(3,1),val(9,0),  val(8,0),val(1,1),val(6,0),  val(4,0),val(2,0),val(5,0)],
        [val(8,0),val(4,0),val(1,0),  val(2,0),val(9,1),val(5,1),  val(6,0),val(3,0),val(7,1)],

        [val(1,1),val(7,0),val(8,0),  val(3,1),val(2,0),val(9,0),  val(5,0),val(4,0),val(6,0)],
        [val(3,0),val(2,0),val(6,0),  val(7,1),val(5,0),val(4,0),  val(9,0),val(8,0),val(1,1)],
        [val(4,0),val(9,0),val(5,0),  val(6,1),val(8,1),val(1,0),  val(3,1),val(7,0),val(2,0)],

        [val(6,1),val(1,0),val(4,1),  val(9,1),val(7,0),val(2,0),  val(8,1),val(5,0),val(3,0)],
        [val(9,0),val(8,1),val(7,0),  val(5,0),val(6,0),val(3,0),  val(2,1),val(1,1),val(4,1)],
        [val(2,0),val(5,0),val(3,0),  val(1,0),val(4,0),val(8,0),  val(7,0),val(6,0),val(9,1)],
    ],

    // Puzzle 89 of 200
    [
        [val(8,0),val(2,1),val(1,0),  val(9,0),val(7,0),val(5,1),  val(6,1),val(3,0),val(4,0)],
        [val(9,0),val(3,0),val(7,0),  val(6,0),val(8,1),val(4,1),  val(2,0),val(1,0),val(5,0)],
        [val(5,0),val(4,0),val(6,1),  val(1,0),val(2,0),val(3,0),  val(8,1),val(7,0),val(9,1)],

        [val(3,0),val(7,0),val(8,1),  val(2,1),val(5,0),val(6,0),  val(9,1),val(4,0),val(1,0)],
        [val(2,0),val(9,0),val(4,1),  val(8,0),val(1,1),val(7,0),  val(3,1),val(5,0),val(6,1)],
        [val(6,0),val(1,0),val(5,0),  val(3,1),val(4,0),val(9,1),  val(7,0),val(8,0),val(2,0)],

        [val(4,0),val(6,1),val(9,0),  val(7,1),val(3,0),val(1,0),  val(5,0),val(2,1),val(8,0)],
        [val(7,0),val(5,0),val(2,0),  val(4,1),val(6,0),val(8,0),  val(1,0),val(9,0),val(3,0)],
        [val(1,0),val(8,1),val(3,0),  val(5,0),val(9,1),val(2,0),  val(4,0),val(6,0),val(7,1)],
    ],

    // Puzzle 90 of 200
    [
        [val(2,1),val(1,1),val(9,0),  val(7,0),val(5,0),val(4,0),  val(8,0),val(6,0),val(3,1)],
        [val(8,0),val(5,0),val(3,1),  val(6,0),val(9,0),val(1,0),  val(2,0),val(7,1),val(4,0)],
        [val(6,1),val(7,0),val(4,0),  val(3,0),val(2,0),val(8,0),  val(9,1),val(5,0),val(1,0)],

        [val(7,1),val(3,0),val(1,1),  val(5,0),val(4,1),val(9,0),  val(6,0),val(2,1),val(8,1)],
        [val(4,0),val(8,1),val(5,0),  val(1,0),val(6,0),val(2,0),  val(7,1),val(3,0),val(9,0)],
        [val(9,0),val(6,1),val(2,0),  val(8,0),val(3,0),val(7,0),  val(4,0),val(1,1),val(5,0)],

        [val(3,1),val(9,0),val(8,1),  val(2,1),val(1,1),val(6,0),  val(5,1),val(4,0),val(7,1)],
        [val(5,0),val(4,0),val(6,0),  val(9,0),val(7,1),val(3,0),  val(1,0),val(8,0),val(2,1)],
        [val(1,0),val(2,0),val(7,0),  val(4,1),val(8,0),val(5,0),  val(3,1),val(9,1),val(6,0)],
    ],

    // Puzzle 91 of 200
    [
        [val(5,1),val(7,0),val(1,0),  val(6,1),val(2,0),val(8,0),  val(3,0),val(9,0),val(4,0)],
        [val(3,0),val(8,1),val(2,0),  val(4,1),val(9,0),val(7,0),  val(1,0),val(5,0),val(6,0)],
        [val(9,0),val(6,0),val(4,0),  val(3,0),val(5,0),val(1,1),  val(7,1),val(2,1),val(8,0)],

        [val(1,1),val(3,0),val(9,1),  val(2,0),val(7,1),val(4,0),  val(6,1),val(8,0),val(5,0)],
        [val(6,1),val(4,0),val(8,0),  val(5,1),val(1,0),val(9,0),  val(2,1),val(7,1),val(3,0)],
        [val(2,0),val(5,0),val(7,0),  val(8,0),val(3,0),val(6,0),  val(4,0),val(1,0),val(9,1)],

        [val(7,0),val(9,0),val(6,0),  val(1,1),val(4,0),val(5,1),  val(8,0),val(3,0),val(2,0)],
        [val(8,0),val(2,0),val(5,0),  val(7,0),val(6,1),val(3,1),  val(9,1),val(4,0),val(1,1)],
        [val(4,1),val(1,0),val(3,0),  val(9,0),val(8,1),val(2,0),  val(5,0),val(6,1),val(7,0)],
    ],

    // Puzzle 92 of 200
    [
        [val(4,1),val(6,1),val(5,1),  val(3,0),val(7,0),val(8,0),  val(1,1),val(9,0),val(2,1)],
        [val(7,0),val(8,0),val(3,1),  val(2,0),val(9,0),val(1,0),  val(4,0),val(5,1),val(6,1)],
        [val(2,0),val(1,0),val(9,0),  val(4,0),val(6,0),val(5,0),  val(3,0),val(8,0),val(7,0)],

        [val(9,0),val(4,0),val(8,0),  val(6,0),val(2,1),val(7,0),  val(5,0),val(3,0),val(1,0)],
        [val(3,1),val(5,1),val(2,0),  val(1,0),val(4,0),val(9,0),  val(7,0),val(6,0),val(8,1)],
        [val(1,0),val(7,1),val(6,0),  val(5,0),val(8,0),val(3,1),  val(9,1),val(2,1),val(4,1)],

        [val(6,1),val(9,1),val(1,0),  val(7,1),val(5,0),val(2,0),  val(8,1),val(4,1),val(3,0)],
        [val(5,0),val(3,0),val(4,0),  val(8,1),val(1,0),val(6,0),  val(2,1),val(7,1),val(9,0)],
        [val(8,0),val(2,0),val(7,0),  val(9,0),val(3,0),val(4,0),  val(6,0),val(1,0),val(5,1)],
    ],

    // Puzzle 93 of 200
    [
        [val(7,1),val(4,1),val(1,0),  val(8,0),val(6,0),val(2,0),  val(5,0),val(3,1),val(9,0)],
        [val(3,0),val(8,0),val(5,1),  val(1,0),val(7,0),val(9,0),  val(4,0),val(6,0),val(2,1)],
        [val(9,0),val(2,1),val(6,1),  val(5,0),val(4,0),val(3,1),  val(1,0),val(7,0),val(8,0)],

        [val(2,0),val(5,0),val(9,1),  val(4,0),val(1,1),val(6,0),  val(3,0),val(8,1),val(7,0)],
        [val(8,0),val(3,1),val(4,0),  val(2,1),val(9,0),val(7,1),  val(6,1),val(5,0),val(1,0)],
        [val(1,0),val(6,1),val(7,0),  val(3,0),val(8,0),val(5,0),  val(9,1),val(2,0),val(4,0)],

        [val(6,0),val(1,0),val(8,1),  val(7,0),val(5,1),val(4,1),  val(2,0),val(9,0),val(3,0)],
        [val(4,0),val(9,0),val(2,0),  val(6,0),val(3,1),val(8,0),  val(7,0),val(1,1),val(5,0)],
        [val(5,0),val(7,0),val(3,0),  val(9,1),val(2,0),val(1,0),  val(8,0),val(4,0),val(6,1)],
    ],

    // Puzzle 94 of 200
    [
        [val(5,0),val(1,0),val(6,0),  val(7,0),val(3,1),val(8,0),  val(9,0),val(4,0),val(2,0)],
        [val(4,1),val(3,0),val(2,0),  val(6,1),val(9,1),val(1,0),  val(8,0),val(5,0),val(7,1)],
        [val(8,0),val(7,1),val(9,0),  val(4,0),val(2,1),val(5,1),  val(1,0),val(3,0),val(6,0)],

        [val(9,0),val(2,0),val(8,1),  val(5,0),val(6,0),val(4,0),  val(7,0),val(1,1),val(3,0)],
        [val(7,0),val(4,1),val(3,1),  val(1,0),val(8,1),val(2,0),  val(6,0),val(9,0),val(5,1)],
        [val(6,1),val(5,0),val(1,0),  val(9,1),val(7,0),val(3,0),  val(2,0),val(8,0),val(4,1)],

        [val(2,0),val(8,0),val(7,0),  val(3,0),val(5,0),val(9,0),  val(4,1),val(6,1),val(1,1)],
        [val(1,0),val(6,0),val(5,1),  val(8,0),val(4,0),val(7,1),  val(3,0),val(2,0),val(9,0)],
        [val(3,1),val(9,1),val(4,0),  val(2,0),val(1,0),val(6,0),  val(5,0),val(7,1),val(8,0)],
    ],

    // Puzzle 95 of 200
    [
        [val(2,0),val(5,1),val(6,0),  val(9,0),val(4,0),val(3,0),  val(7,0),val(1,0),val(8,0)],
        [val(4,0),val(9,1),val(7,1),  val(2,1),val(8,0),val(1,1),  val(5,0),val(3,0),val(6,0)],
        [val(1,1),val(3,0),val(8,0),  val(6,1),val(5,0),val(7,0),  val(9,0),val(4,0),val(2,0)],

        [val(5,0),val(4,1),val(9,1),  val(3,0),val(1,0),val(8,1),  val(6,0),val(2,0),val(7,1)],
        [val(6,1),val(2,0),val(1,0),  val(7,0),val(9,1),val(5,0),  val(3,0),val(8,0),val(4,0)],
        [val(8,0),val(7,0),val(3,1),  val(4,1),val(2,1),val(6,0),  val(1,0),val(9,0),val(5,0)],

        [val(3,0),val(1,1),val(2,0),  val(5,0),val(6,0),val(4,0),  val(8,0),val(7,1),val(9,1)],
        [val(7,0),val(6,0),val(4,0),  val(8,0),val(3,0),val(9,0),  val(2,1),val(5,1),val(1,0)],
        [val(9,0),val(8,1),val(5,0),  val(1,1),val(7,0),val(2,0),  val(4,0),val(6,0),val(3,1)],
    ],

    // Puzzle 96 of 200
    [
        [val(8,0),val(5,1),val(4,0),  val(7,0),val(6,0),val(2,0),  val(9,0),val(1,0),val(3,1)],
        [val(9,0),val(2,0),val(1,0),  val(8,1),val(3,0),val(5,0),  val(7,0),val(6,1),val(4,0)],
        [val(7,0),val(3,0),val(6,0),  val(4,1),val(1,0),val(9,0),  val(5,1),val(8,0),val(2,0)],

        [val(3,0),val(7,1),val(2,0),  val(9,1),val(4,0),val(1,0),  val(6,0),val(5,1),val(8,0)],
        [val(1,0),val(4,0),val(9,1),  val(5,0),val(8,0),val(6,0),  val(3,1),val(2,1),val(7,0)],
        [val(5,0),val(6,0),val(8,0),  val(3,0),val(2,1),val(7,0),  val(1,1),val(4,0),val(9,0)],

        [val(2,0),val(8,1),val(7,1),  val(1,0),val(5,0),val(3,1),  val(4,1),val(9,0),val(6,0)],
        [val(6,0),val(9,0),val(5,1),  val(2,1),val(7,1),val(4,0),  val(8,0),val(3,0),val(1,1)],
        [val(4,1),val(1,0),val(3,1),  val(6,0),val(9,0),val(8,0),  val(2,0),val(7,0),val(5,0)],
    ],

    // Puzzle 97 of 200
    [
        [val(3,1),val(7,0),val(5,0),  val(2,0),val(9,0),val(6,0),  val(1,1),val(4,0),val(8,0)],
        [val(8,1),val(4,0),val(2,0),  val(3,0),val(5,1),val(1,0),  val(9,0),val(6,1),val(7,0)],
        [val(6,1),val(1,0),val(9,1),  val(8,0),val(4,0),val(7,0),  val(3,1),val(2,0),val(5,0)],

        [val(1,0),val(9,0),val(7,1),  val(6,0),val(2,0),val(8,0),  val(4,1),val(5,0),val(3,0)],
        [val(4,0),val(2,0),val(3,0),  val(5,1),val(1,0),val(9,0),  val(8,0),val(7,0),val(6,0)],
        [val(5,0),val(6,0),val(8,0),  val(4,1),val(7,0),val(3,1),  val(2,0),val(9,1),val(1,0)],

        [val(2,0),val(3,1),val(4,1),  val(7,0),val(8,0),val(5,0),  val(6,0),val(1,0),val(9,0)],
        [val(9,1),val(5,0),val(6,0),  val(1,0),val(3,0),val(2,1),  val(7,0),val(8,1),val(4,0)],
        [val(7,0),val(8,0),val(1,1),  val(9,0),val(6,1),val(4,0),  val(5,0),val(3,0),val(2,1)],
    ],

    // Puzzle 98 of 200
    [
        [val(8,1),val(2,0),val(3,1),  val(7,1),val(6,0),val(1,0),  val(4,0),val(9,0),val(5,1)],
        [val(6,1),val(9,0),val(5,0),  val(8,0),val(4,1),val(3,1),  val(1,0),val(7,0),val(2,1)],
        [val(7,0),val(1,0),val(4,0),  val(5,0),val(2,1),val(9,0),  val(3,0),val(6,0),val(8,0)],

        [val(4,0),val(7,1),val(1,0),  val(9,0),val(5,0),val(6,0),  val(8,0),val(2,1),val(3,1)],
        [val(9,0),val(5,0),val(2,1),  val(1,0),val(3,0),val(8,1),  val(6,1),val(4,0),val(7,0)],
        [val(3,0),val(6,0),val(8,1),  val(4,1),val(7,0),val(2,0),  val(9,0),val(5,0),val(1,0)],

        [val(2,0),val(8,1),val(7,0),  val(6,0),val(1,0),val(4,0),  val(5,1),val(3,0),val(9,0)],
        [val(1,1),val(3,0),val(6,1),  val(2,0),val(9,1),val(5,0),  val(7,0),val(8,0),val(4,1)],
        [val(5,1),val(4,0),val(9,0),  val(3,0),val(8,0),val(7,1),  val(2,0),val(1,1),val(6,0)],
    ],

    // Puzzle 99 of 200
    [
        [val(3,0),val(1,1),val(7,0),  val(4,1),val(9,0),val(6,0),  val(2,1),val(8,0),val(5,1)],
        [val(5,0),val(6,0),val(4,0),  val(8,0),val(7,0),val(2,0),  val(3,0),val(9,0),val(1,1)],
        [val(2,0),val(8,0),val(9,1),  val(3,0),val(5,0),val(1,1),  val(4,0),val(6,0),val(7,0)],

        [val(1,1),val(4,1),val(2,0),  val(6,0),val(3,0),val(9,0),  val(7,1),val(5,0),val(8,1)],
        [val(6,0),val(9,1),val(5,0),  val(2,1),val(8,0),val(7,0),  val(1,0),val(4,0),val(3,0)],
        [val(8,0),val(7,1),val(3,0),  val(1,0),val(4,0),val(5,0),  val(9,1),val(2,1),val(6,0)],

        [val(7,0),val(2,0),val(1,0),  val(9,0),val(6,1),val(8,1),  val(5,0),val(3,0),val(4,1)],
        [val(9,0),val(3,0),val(8,1),  val(5,0),val(1,0),val(4,1),  val(6,1),val(7,0),val(2,0)],
        [val(4,1),val(5,1),val(6,0),  val(7,0),val(2,0),val(3,0),  val(8,0),val(1,0),val(9,1)],
    ],

    // Puzzle 100 of 200
    [
        [val(9,1),val(5,1),val(4,0),  val(7,0),val(2,0),val(6,0),  val(1,0),val(8,0),val(3,0)],
        [val(2,0),val(1,0),val(8,0),  val(5,0),val(9,0),val(3,0),  val(6,0),val(7,1),val(4,0)],
        [val(3,0),val(7,0),val(6,0),  val(4,1),val(8,0),val(1,0),  val(2,1),val(9,0),val(5,0)],

        [val(4,1),val(6,0),val(5,0),  val(8,0),val(3,1),val(9,0),  val(7,0),val(2,0),val(1,1)],
        [val(1,0),val(2,1),val(9,0),  val(6,0),val(7,0),val(5,1),  val(4,0),val(3,0),val(8,1)],
        [val(7,1),val(8,0),val(3,1),  val(1,0),val(4,1),val(2,0),  val(5,0),val(6,0),val(9,1)],

        [val(5,0),val(3,0),val(1,0),  val(9,0),val(6,0),val(7,1),  val(8,0),val(4,0),val(2,0)],
        [val(6,0),val(4,0),val(2,1),  val(3,1),val(1,1),val(8,1),  val(9,0),val(5,1),val(7,1)],
        [val(8,0),val(9,1),val(7,0),  val(2,1),val(5,0),val(4,0),  val(3,1),val(1,0),val(6,0)],
    ],

    // Puzzle 101 of 200
    [
        [val(8,0),val(2,0),val(5,1),  val(1,1),val(7,0),val(4,0),  val(6,1),val(9,0),val(3,0)],
        [val(7,0),val(1,0),val(9,0),  val(3,0),val(6,0),val(2,0),  val(8,1),val(5,1),val(4,0)],
        [val(3,0),val(6,0),val(4,0),  val(8,0),val(9,1),val(5,0),  val(1,0),val(7,0),val(2,1)],

        [val(4,0),val(9,0),val(2,1),  val(7,0),val(8,1),val(1,0),  val(5,0),val(3,0),val(6,0)],
        [val(1,0),val(5,0),val(7,1),  val(6,0),val(2,0),val(3,1),  val(9,1),val(4,1),val(8,0)],
        [val(6,1),val(3,0),val(8,0),  val(4,1),val(5,0),val(9,1),  val(2,0),val(1,0),val(7,0)],

        [val(5,1),val(7,0),val(6,1),  val(9,0),val(3,0),val(8,0),  val(4,1),val(2,0),val(1,0)],
        [val(2,1),val(4,1),val(3,0),  val(5,0),val(1,1),val(6,0),  val(7,0),val(8,0),val(9,0)],
        [val(9,0),val(8,0),val(1,0),  val(2,1),val(4,0),val(7,1),  val(3,0),val(6,1),val(5,0)],
    ],

    // Puzzle 102 of 200
    [
        [val(1,0),val(3,0),val(9,1),  val(4,1),val(8,0),val(7,0),  val(2,1),val(5,1),val(6,0)],
        [val(7,0),val(5,0),val(4,0),  val(6,0),val(3,0),val(2,0),  val(1,0),val(9,0),val(8,1)],
        [val(2,1),val(8,1),val(6,0),  val(1,1),val(9,0),val(5,0),  val(4,0),val(7,0),val(3,1)],

        [val(3,1),val(6,0),val(5,1),  val(9,0),val(4,0),val(8,0),  val(7,0),val(2,0),val(1,0)],
        [val(9,1),val(7,0),val(2,0),  val(5,0),val(6,1),val(1,1),  val(8,1),val(3,0),val(4,0)],
        [val(8,0),val(4,1),val(1,0),  val(2,0),val(7,0),val(3,0),  val(9,0),val(6,1),val(5,0)],

        [val(4,0),val(9,0),val(8,0),  val(3,1),val(2,1),val(6,1),  val(5,0),val(1,0),val(7,0)],
        [val(6,0),val(1,1),val(7,1),  val(8,0),val(5,0),val(9,1),  val(3,0),val(4,0),val(2,0)],
        [val(5,0),val(2,0),val(3,0),  val(7,0),val(1,0),val(4,0),  val(6,0),val(8,0),val(9,0)],
    ],

    // Puzzle 103 of 200
    [
        [val(7,0),val(5,0),val(4,0),  val(8,0),val(6,1),val(1,0),  val(3,1),val(9,1),val(2,0)],
        [val(6,1),val(9,0),val(8,0),  val(5,0),val(2,1),val(3,1),  val(4,0),val(7,0),val(1,0)],
        [val(1,1),val(3,0),val(2,0),  val(9,0),val(4,0),val(7,0),  val(8,0),val(6,0),val(5,0)],

        [val(2,0),val(1,0),val(5,1),  val(7,1),val(9,0),val(4,0),  val(6,0),val(8,1),val(3,1)],
        [val(3,0),val(6,0),val(7,1),  val(2,1),val(5,0),val(8,0),  val(9,1),val(1,0),val(4,0)],
        [val(8,0),val(4,0),val(9,1),  val(1,0),val(3,0),val(6,1),  val(2,0),val(5,1),val(7,0)],

        [val(5,0),val(8,0),val(3,1),  val(6,0),val(1,0),val(2,0),  val(7,0),val(4,1),val(9,0)],
        [val(9,0),val(2,0),val(6,1),  val(4,1),val(7,1),val(5,1),  val(1,0),val(3,0),val(8,0)],
        [val(4,0),val(7,1),val(1,0),  val(3,0),val(8,1),val(9,0),  val(5,0),val(2,0),val(6,0)],
    ],

    // Puzzle 104 of 200
    [
        [val(9,0),val(1,1),val(2,0),  val(5,1),val(3,0),val(7,0),  val(4,0),val(6,0),val(8,0)],
        [val(3,1),val(8,1),val(4,0),  val(2,1),val(1,1),val(6,0),  val(5,0),val(7,1),val(9,0)],
        [val(7,0),val(5,0),val(6,0),  val(9,0),val(8,0),val(4,1),  val(2,0),val(1,0),val(3,1)],

        [val(6,0),val(4,0),val(5,1),  val(3,0),val(7,0),val(8,0),  val(9,0),val(2,0),val(1,0)],
        [val(2,0),val(9,0),val(3,0),  val(6,1),val(5,0),val(1,0),  val(8,1),val(4,1),val(7,1)],
        [val(8,1),val(7,0),val(1,1),  val(4,0),val(9,0),val(2,0),  val(6,0),val(3,1),val(5,0)],

        [val(4,0),val(3,0),val(8,0),  val(1,0),val(6,0),val(5,0),  val(7,1),val(9,0),val(2,0)],
        [val(1,0),val(2,0),val(7,0),  val(8,1),val(4,0),val(9,1),  val(3,0),val(5,0),val(6,1)],
        [val(5,0),val(6,1),val(9,1),  val(7,0),val(2,0),val(3,1),  val(1,0),val(8,1),val(4,0)],
    ],

    // Puzzle 105 of 200
    [
        [val(6,1),val(3,0),val(8,0),  val(5,0),val(4,0),val(7,0),  val(1,1),val(2,0),val(9,1)],
        [val(9,0),val(5,1),val(2,1),  val(1,0),val(3,0),val(6,0),  val(8,1),val(7,0),val(4,0)],
        [val(7,0),val(1,0),val(4,0),  val(9,0),val(2,0),val(8,0),  val(6,0),val(5,0),val(3,1)],

        [val(1,0),val(8,1),val(6,0),  val(3,1),val(7,1),val(9,1),  val(2,0),val(4,0),val(5,0)],
        [val(5,1),val(4,1),val(9,0),  val(8,0),val(6,0),val(2,0),  val(3,0),val(1,0),val(7,0)],
        [val(3,0),val(2,0),val(7,0),  val(4,0),val(1,1),val(5,0),  val(9,1),val(6,0),val(8,0)],

        [val(4,0),val(9,0),val(3,1),  val(6,1),val(5,0),val(1,0),  val(7,0),val(8,0),val(2,0)],
        [val(2,0),val(6,0),val(5,0),  val(7,1),val(8,0),val(3,1),  val(4,0),val(9,0),val(1,0)],
        [val(8,0),val(7,0),val(1,1),  val(2,1),val(9,0),val(4,0),  val(5,1),val(3,0),val(6,0)],
    ],

    // Puzzle 106 of 200
    [
        [val(2,1),val(4,0),val(5,0),  val(1,0),val(9,0),val(3,1),  val(6,1),val(7,0),val(8,0)],
        [val(1,0),val(3,0),val(6,0),  val(2,0),val(8,0),val(7,0),  val(4,1),val(5,0),val(9,1)],
        [val(8,0),val(9,1),val(7,1),  val(4,0),val(6,0),val(5,0),  val(1,1),val(3,0),val(2,0)],

        [val(5,1),val(1,0),val(9,0),  val(6,0),val(4,1),val(8,0),  val(7,0),val(2,1),val(3,0)],
        [val(7,0),val(6,1),val(8,1),  val(3,0),val(1,1),val(2,0),  val(5,0),val(9,0),val(4,0)],
        [val(3,1),val(2,0),val(4,0),  val(5,1),val(7,0),val(9,0),  val(8,1),val(1,0),val(6,0)],

        [val(9,0),val(7,1),val(1,0),  val(8,0),val(2,1),val(4,0),  val(3,0),val(6,1),val(5,0)],
        [val(6,1),val(8,0),val(3,0),  val(9,0),val(5,1),val(1,0),  val(2,0),val(4,0),val(7,1)],
        [val(4,0),val(5,1),val(2,1),  val(7,0),val(3,0),val(6,0),  val(9,0),val(8,0),val(1,0)],
    ],

    // Puzzle 107 of 200
    [
        [val(7,0),val(9,1),val(4,1),  val(5,1),val(6,0),val(3,0),  val(2,0),val(8,1),val(1,0)],
        [val(5,1),val(3,0),val(1,0),  val(2,0),val(8,1),val(9,0),  val(6,0),val(7,0),val(4,0)],
        [val(6,1),val(2,0),val(8,0),  val(4,0),val(1,0),val(7,0),  val(9,0),val(3,1),val(5,0)],

        [val(3,0),val(4,0),val(5,0),  val(6,0),val(7,0),val(1,1),  val(8,0),val(2,0),val(9,1)],
        [val(9,1),val(6,0),val(7,0),  val(8,0),val(2,1),val(4,0),  val(1,0),val(5,0),val(3,1)],
        [val(1,0),val(8,1),val(2,1),  val(9,0),val(3,0),val(5,1),  val(7,1),val(4,0),val(6,0)],

        [val(8,0),val(5,1),val(6,0),  val(3,1),val(9,0),val(2,0),  val(4,0),val(1,1),val(7,0)],
        [val(2,1),val(1,0),val(3,1),  val(7,1),val(4,0),val(6,1),  val(5,0),val(9,0),val(8,0)],
        [val(4,0),val(7,0),val(9,0),  val(1,0),val(5,0),val(8,0),  val(3,0),val(6,1),val(2,0)],
    ],

    // Puzzle 108 of 200
    [
        [val(9,0),val(5,0),val(3,0),  val(4,0),val(6,0),val(2,1),  val(7,0),val(1,0),val(8,0)],
        [val(1,0),val(8,0),val(4,1),  val(7,0),val(3,0),val(9,0),  val(5,1),val(6,0),val(2,0)],
        [val(6,1),val(7,0),val(2,0),  val(1,0),val(5,0),val(8,0),  val(9,1),val(3,0),val(4,1)],

        [val(8,1),val(9,0),val(5,0),  val(3,1),val(4,0),val(7,0),  val(1,0),val(2,1),val(6,1)],
        [val(4,0),val(1,0),val(7,1),  val(6,0),val(2,0),val(5,0),  val(8,0),val(9,0),val(3,0)],
        [val(3,0),val(2,0),val(6,0),  val(8,1),val(9,1),val(1,0),  val(4,1),val(5,0),val(7,0)],

        [val(5,0),val(6,1),val(8,0),  val(2,1),val(1,0),val(4,0),  val(3,0),val(7,0),val(9,0)],
        [val(7,0),val(3,1),val(9,1),  val(5,1),val(8,0),val(6,0),  val(2,0),val(4,0),val(1,0)],
        [val(2,0),val(4,1),val(1,0),  val(9,0),val(7,1),val(3,0),  val(6,1),val(8,1),val(5,0)],
    ],

    // Puzzle 109 of 200
    [
        [val(9,0),val(5,0),val(1,1),  val(8,0),val(4,0),val(6,0),  val(2,0),val(3,1),val(7,0)],
        [val(2,0),val(6,1),val(8,1),  val(3,0),val(7,1),val(1,1),  val(4,0),val(9,1),val(5,0)],
        [val(3,1),val(4,0),val(7,0),  val(5,0),val(9,0),val(2,0),  val(8,0),val(6,1),val(1,0)],

        [val(4,0),val(3,0),val(2,0),  val(6,0),val(5,0),val(7,0),  val(1,1),val(8,1),val(9,0)],
        [val(7,1),val(8,0),val(9,0),  val(1,0),val(3,0),val(4,0),  val(5,1),val(2,0),val(6,0)],
        [val(5,0),val(1,1),val(6,1),  val(9,1),val(2,0),val(8,0),  val(7,0),val(4,1),val(3,0)],

        [val(1,0),val(2,0),val(3,1),  val(4,1),val(6,0),val(5,1),  val(9,0),val(7,0),val(8,1)],
        [val(8,0),val(9,1),val(4,0),  val(7,0),val(1,0),val(3,0),  val(6,0),val(5,0),val(2,0)],
        [val(6,0),val(7,0),val(5,0),  val(2,0),val(8,1),val(9,0),  val(3,1),val(1,0),val(4,1)],
    ],

    // Puzzle 110 of 200
    [
        [val(4,1),val(1,0),val(2,0),  val(8,0),val(6,0),val(9,0),  val(7,0),val(3,0),val(5,1)],
        [val(9,0),val(7,1),val(8,1),  val(4,0),val(3,1),val(5,0),  val(1,1),val(2,0),val(6,0)],
        [val(5,0),val(3,1),val(6,1),  val(2,0),val(7,0),val(1,1),  val(9,0),val(8,0),val(4,1)],

        [val(8,1),val(9,0),val(1,0),  val(6,0),val(4,0),val(2,0),  val(3,1),val(5,1),val(7,0)],
        [val(7,1),val(2,0),val(5,0),  val(9,1),val(8,0),val(3,0),  val(6,0),val(4,0),val(1,0)],
        [val(3,1),val(6,0),val(4,1),  val(5,0),val(1,1),val(7,0),  val(8,0),val(9,1),val(2,1)],

        [val(6,0),val(5,0),val(3,0),  val(7,1),val(2,0),val(8,0),  val(4,0),val(1,1),val(9,1)],
        [val(1,0),val(4,0),val(9,1),  val(3,0),val(5,1),val(6,0),  val(2,0),val(7,0),val(8,0)],
        [val(2,1),val(8,0),val(7,0),  val(1,0),val(9,0),val(4,1),  val(5,0),val(6,0),val(3,0)],
    ],

    // Puzzle 111 of 200
    [
        [val(1,0),val(4,0),val(7,1),  val(6,0),val(8,0),val(2,1),  val(3,1),val(9,0),val(5,0)],
        [val(6,0),val(2,0),val(8,0),  val(3,0),val(5,1),val(9,0),  val(1,0),val(7,0),val(4,1)],
        [val(5,0),val(3,1),val(9,0),  val(1,1),val(4,1),val(7,0),  val(6,0),val(2,0),val(8,0)],

        [val(8,0),val(5,0),val(3,1),  val(7,0),val(9,1),val(4,0),  val(2,1),val(6,0),val(1,1)],
        [val(9,0),val(1,0),val(6,1),  val(2,1),val(3,0),val(8,0),  val(4,0),val(5,0),val(7,0)],
        [val(2,1),val(7,1),val(4,0),  val(5,0),val(1,0),val(6,0),  val(8,0),val(3,0),val(9,1)],

        [val(4,0),val(8,1),val(2,0),  val(9,0),val(7,1),val(3,1),  val(5,0),val(1,0),val(6,0)],
        [val(7,0),val(6,0),val(5,0),  val(4,1),val(2,0),val(1,0),  val(9,0),val(8,0),val(3,0)],
        [val(3,0),val(9,0),val(1,0),  val(8,0),val(6,1),val(5,1),  val(7,0),val(4,1),val(2,1)],
    ],

    // Puzzle 112 of 200
    [
        [val(2,0),val(5,1),val(1,0),  val(6,0),val(3,1),val(9,1),  val(8,1),val(4,0),val(7,0)],
        [val(3,1),val(7,1),val(6,0),  val(4,0),val(8,0),val(2,0),  val(1,0),val(5,0),val(9,0)],
        [val(4,1),val(8,0),val(9,0),  val(1,1),val(7,0),val(5,0),  val(6,0),val(3,0),val(2,1)],

        [val(8,0),val(9,1),val(4,0),  val(7,0),val(2,0),val(6,0),  val(3,1),val(1,0),val(5,0)],
        [val(6,1),val(1,0),val(7,1),  val(3,0),val(5,1),val(4,1),  val(9,1),val(2,0),val(8,0)],
        [val(5,0),val(3,0),val(2,0),  val(8,1),val(9,0),val(1,1),  val(7,0),val(6,0),val(4,0)],

        [val(1,1),val(2,1),val(5,0),  val(9,0),val(6,0),val(7,1),  val(4,0),val(8,0),val(3,0)],
        [val(7,0),val(4,0),val(8,0),  val(5,1),val(1,0),val(3,0),  val(2,0),val(9,0),val(6,0)],
        [val(9,0),val(6,0),val(3,1),  val(2,0),val(4,1),val(8,0),  val(5,1),val(7,1),val(1,0)],
    ],

    // Puzzle 113 of 200
    [
        [val(5,0),val(2,0),val(4,1),  val(1,0),val(6,0),val(3,0),  val(7,0),val(8,1),val(9,0)],
        [val(6,1),val(7,0),val(9,1),  val(2,0),val(8,1),val(5,0),  val(3,1),val(1,0),val(4,1)],
        [val(3,0),val(8,0),val(1,1),  val(4,0),val(7,0),val(9,1),  val(2,0),val(5,1),val(6,0)],

        [val(2,1),val(3,0),val(7,0),  val(9,0),val(4,0),val(1,0),  val(8,0),val(6,1),val(5,1)],
        [val(1,0),val(6,0),val(5,0),  val(8,0),val(3,1),val(7,1),  val(4,0),val(9,0),val(2,0)],
        [val(9,0),val(4,1),val(8,0),  val(6,0),val(5,0),val(2,0),  val(1,0),val(3,0),val(7,1)],

        [val(8,1),val(5,1),val(3,0),  val(7,1),val(2,0),val(6,0),  val(9,0),val(4,1),val(1,0)],
        [val(4,0),val(1,0),val(2,0),  val(5,1),val(9,0),val(8,0),  val(6,0),val(7,1),val(3,0)],
        [val(7,0),val(9,0),val(6,0),  val(3,0),val(1,1),val(4,0),  val(5,0),val(2,0),val(8,0)],
    ],

    // Puzzle 114 of 200
    [
        [val(8,0),val(2,1),val(1,0),  val(6,0),val(5,1),val(9,0),  val(7,0),val(4,1),val(3,0)],
        [val(4,0),val(5,0),val(7,0),  val(8,0),val(3,1),val(1,0),  val(6,0),val(9,0),val(2,0)],
        [val(9,1),val(6,0),val(3,0),  val(2,0),val(7,0),val(4,0),  val(8,0),val(1,0),val(5,1)],

        [val(5,0),val(7,1),val(8,1),  val(9,1),val(6,0),val(2,0),  val(1,0),val(3,0),val(4,1)],
        [val(1,1),val(9,1),val(6,1),  val(3,0),val(4,1),val(7,0),  val(5,0),val(2,1),val(8,0)],
        [val(2,1),val(3,0),val(4,0),  val(1,1),val(8,0),val(5,0),  val(9,0),val(7,1),val(6,0)],

        [val(3,0),val(1,0),val(5,0),  val(4,1),val(9,0),val(6,0),  val(2,0),val(8,0),val(7,1)],
        [val(7,0),val(8,0),val(2,0),  val(5,0),val(1,0),val(3,1),  val(4,0),val(6,1),val(9,1)],
        [val(6,0),val(4,0),val(9,0),  val(7,0),val(2,1),val(8,0),  val(3,1),val(5,0),val(1,0)],
    ],

    // Puzzle 115 of 200
    [
        [val(2,1),val(9,0),val(4,0),  val(5,1),val(7,0),val(3,0),  val(6,0),val(1,0),val(8,0)],
        [val(1,0),val(8,0),val(3,0),  val(6,0),val(4,1),val(9,1),  val(7,1),val(2,0),val(5,1)],
        [val(6,1),val(5,0),val(7,0),  val(8,0),val(1,1),val(2,0),  val(4,1),val(3,0),val(9,0)],

        [val(7,0),val(4,1),val(5,0),  val(1,0),val(9,0),val(8,1),  val(3,0),val(6,1),val(2,0)],
        [val(3,0),val(1,0),val(6,0),  val(4,0),val(2,0),val(5,0),  val(8,0),val(9,0),val(7,0)],
        [val(8,1),val(2,1),val(9,1),  val(7,0),val(3,0),val(6,0),  val(5,0),val(4,0),val(1,1)],

        [val(9,1),val(7,1),val(8,1),  val(3,0),val(6,0),val(1,0),  val(2,1),val(5,0),val(4,0)],
        [val(4,0),val(6,0),val(2,0),  val(9,0),val(5,0),val(7,0),  val(1,0),val(8,0),val(3,0)],
        [val(5,0),val(3,0),val(1,1),  val(2,0),val(8,1),val(4,0),  val(9,0),val(7,0),val(6,1)],
    ],

    // Puzzle 116 of 200
    [
        [val(9,0),val(6,1),val(8,1),  val(7,1),val(4,1),val(5,1),  val(3,0),val(2,0),val(1,1)],
        [val(4,0),val(1,0),val(3,0),  val(2,0),val(9,0),val(8,1),  val(5,1),val(7,0),val(6,0)],
        [val(5,0),val(7,1),val(2,0),  val(1,0),val(3,1),val(6,0),  val(9,1),val(4,0),val(8,1)],

        [val(1,0),val(5,0),val(6,0),  val(9,1),val(2,0),val(7,0),  val(8,0),val(3,1),val(4,0)],
        [val(8,0),val(9,0),val(7,0),  val(4,1),val(6,1),val(3,0),  val(2,0),val(1,0),val(5,0)],
        [val(3,1),val(2,0),val(4,0),  val(8,0),val(5,1),val(1,0),  val(7,1),val(6,0),val(9,1)],

        [val(6,0),val(3,0),val(1,1),  val(5,1),val(8,1),val(2,0),  val(4,0),val(9,0),val(7,0)],
        [val(7,0),val(4,0),val(5,1),  val(3,0),val(1,0),val(9,0),  val(6,0),val(8,0),val(2,1)],
        [val(2,0),val(8,0),val(9,0),  val(6,0),val(7,1),val(4,0),  val(1,0),val(5,0),val(3,0)],
    ],

    // Puzzle 117 of 200
    [
        [val(1,0),val(6,0),val(8,0),  val(2,1),val(3,0),val(4,0),  val(9,1),val(7,1),val(5,0)],
        [val(4,1),val(5,0),val(2,0),  val(1,0),val(7,0),val(9,1),  val(6,0),val(3,0),val(8,1)],
        [val(3,1),val(9,0),val(7,0),  val(6,0),val(5,0),val(8,0),  val(4,0),val(2,1),val(1,0)],

        [val(5,0),val(3,1),val(6,0),  val(7,0),val(8,0),val(1,0),  val(2,1),val(4,0),val(9,0)],
        [val(2,0),val(8,0),val(1,0),  val(4,1),val(9,0),val(3,0),  val(5,0),val(6,1),val(7,0)],
        [val(9,0),val(7,1),val(4,0),  val(5,0),val(6,1),val(2,0),  val(8,0),val(1,1),val(3,0)],

        [val(6,0),val(4,0),val(9,0),  val(8,0),val(1,1),val(7,0),  val(3,0),val(5,0),val(2,0)],
        [val(8,1),val(1,0),val(5,1),  val(3,1),val(2,1),val(6,0),  val(7,1),val(9,1),val(4,0)],
        [val(7,1),val(2,0),val(3,1),  val(9,0),val(4,0),val(5,1),  val(1,0),val(8,0),val(6,1)],
    ],

    // Puzzle 118 of 200
    [
        [val(8,0),val(4,0),val(3,0),  val(6,0),val(5,1),val(7,1),  val(2,0),val(9,1),val(1,1)],
        [val(1,0),val(5,0),val(7,0),  val(9,0),val(8,0),val(2,1),  val(3,0),val(6,1),val(4,1)],
        [val(2,1),val(6,0),val(9,0),  val(1,0),val(4,0),val(3,0),  val(7,0),val(8,0),val(5,1)],

        [val(9,0),val(1,1),val(2,0),  val(4,1),val(7,1),val(5,0),  val(6,0),val(3,0),val(8,0)],
        [val(4,0),val(3,0),val(6,1),  val(8,0),val(1,0),val(9,0),  val(5,0),val(7,0),val(2,1)],
        [val(5,0),val(7,0),val(8,0),  val(2,0),val(3,1),val(6,0),  val(1,0),val(4,0),val(9,0)],

        [val(6,1),val(9,0),val(5,0),  val(3,0),val(2,0),val(8,1),  val(4,0),val(1,1),val(7,0)],
        [val(7,1),val(8,0),val(4,0),  val(5,0),val(6,1),val(1,1),  val(9,1),val(2,0),val(3,0)],
        [val(3,0),val(2,1),val(1,1),  val(7,0),val(9,1),val(4,0),  val(8,1),val(5,0),val(6,0)],
    ],

    // Puzzle 119 of 200
    [
        [val(3,1),val(2,0),val(5,1),  val(1,1),val(9,1),val(8,0),  val(6,0),val(4,0),val(7,0)],
        [val(4,0),val(7,0),val(1,0),  val(2,0),val(5,0),val(6,0),  val(9,0),val(8,1),val(3,1)],
        [val(9,1),val(8,0),val(6,0),  val(4,0),val(7,0),val(3,0),  val(5,1),val(2,0),val(1,0)],

        [val(5,0),val(6,0),val(2,0),  val(9,0),val(8,0),val(1,1),  val(3,0),val(7,1),val(4,0)],
        [val(1,0),val(4,1),val(8,1),  val(3,0),val(6,1),val(7,0),  val(2,0),val(5,0),val(9,1)],
        [val(7,0),val(9,0),val(3,0),  val(5,1),val(2,1),val(4,0),  val(8,1),val(1,0),val(6,1)],

        [val(6,0),val(1,1),val(9,0),  val(8,0),val(4,0),val(2,0),  val(7,0),val(3,1),val(5,1)],
        [val(2,0),val(5,0),val(4,1),  val(7,1),val(3,0),val(9,1),  val(1,0),val(6,0),val(8,0)],
        [val(8,1),val(3,0),val(7,0),  val(6,0),val(1,0),val(5,0),  val(4,0),val(9,0),val(2,0)],
    ],

    // Puzzle 120 of 200
    [
        [val(3,1),val(6,0),val(2,0),  val(5,1),val(1,0),val(9,0),  val(7,1),val(8,1),val(4,0)],
        [val(8,0),val(7,0),val(1,0),  val(6,0),val(3,0),val(4,1),  val(9,1),val(5,1),val(2,0)],
        [val(4,0),val(9,0),val(5,0),  val(2,1),val(7,0),val(8,0),  val(3,0),val(6,0),val(1,0)],

        [val(6,0),val(1,0),val(3,0),  val(4,0),val(9,1),val(2,0),  val(5,1),val(7,0),val(8,0)],
        [val(5,0),val(2,0),val(4,1),  val(8,0),val(6,1),val(7,1),  val(1,1),val(3,0),val(9,0)],
        [val(7,1),val(8,0),val(9,0),  val(3,1),val(5,0),val(1,0),  val(2,0),val(4,1),val(6,0)],

        [val(9,0),val(5,0),val(6,1),  val(1,0),val(8,0),val(3,0),  val(4,1),val(2,0),val(7,0)],
        [val(1,1),val(4,0),val(8,0),  val(7,0),val(2,1),val(5,0),  val(6,0),val(9,1),val(3,0)],
        [val(2,0),val(3,1),val(7,0),  val(9,0),val(4,0),val(6,0),  val(8,1),val(1,1),val(5,0)],
    ],

    // Puzzle 121 of 200
    [
        [val(2,1),val(1,1),val(9,0),  val(6,0),val(4,0),val(5,0),  val(8,0),val(3,1),val(7,0)],
        [val(5,0),val(6,0),val(7,1),  val(3,0),val(1,1),val(8,0),  val(4,0),val(2,0),val(9,0)],
        [val(3,1),val(8,0),val(4,1),  val(9,0),val(7,1),val(2,0),  val(1,0),val(6,1),val(5,1)],

        [val(8,1),val(5,1),val(3,1),  val(2,1),val(6,0),val(1,0),  val(7,0),val(9,0),val(4,1)],
        [val(7,0),val(4,0),val(2,0),  val(5,1),val(9,1),val(3,0),  val(6,0),val(1,0),val(8,0)],
        [val(6,1),val(9,0),val(1,1),  val(4,0),val(8,0),val(7,0),  val(3,1),val(5,0),val(2,0)],

        [val(9,0),val(2,0),val(8,0),  val(1,0),val(3,0),val(4,0),  val(5,0),val(7,1),val(6,0)],
        [val(4,1),val(3,0),val(6,0),  val(7,0),val(5,0),val(9,0),  val(2,1),val(8,0),val(1,1)],
        [val(1,1),val(7,0),val(5,1),  val(8,0),val(2,0),val(6,0),  val(9,0),val(4,0),val(3,0)],
    ],

    // Puzzle 122 of 200
    [
        [val(4,0),val(6,0),val(1,1),  val(9,0),val(2,0),val(7,1),  val(5,0),val(8,1),val(3,1)],
        [val(2,0),val(5,0),val(9,0),  val(3,1),val(8,1),val(6,0),  val(4,1),val(7,0),val(1,0)],
        [val(8,0),val(3,0),val(7,0),  val(5,0),val(1,0),val(4,0),  val(9,1),val(6,0),val(2,0)],

        [val(1,1),val(8,0),val(4,0),  val(6,0),val(9,1),val(3,0),  val(7,0),val(2,0),val(5,1)],
        [val(9,0),val(2,1),val(6,0),  val(7,0),val(5,0),val(1,0),  val(3,1),val(4,0),val(8,0)],
        [val(3,0),val(7,0),val(5,1),  val(8,1),val(4,0),val(2,0),  val(6,1),val(1,1),val(9,0)],

        [val(6,1),val(9,0),val(2,0),  val(4,1),val(3,0),val(8,1),  val(1,0),val(5,0),val(7,1)],
        [val(5,1),val(4,0),val(8,1),  val(1,1),val(7,0),val(9,0),  val(2,0),val(3,0),val(6,0)],
        [val(7,1),val(1,0),val(3,0),  val(2,0),val(6,0),val(5,0),  val(8,0),val(9,0),val(4,0)],
    ],

    // Puzzle 123 of 200
    [
        [val(9,0),val(8,0),val(1,0),  val(4,0),val(3,0),val(6,0),  val(2,0),val(5,0),val(7,0)],
        [val(5,1),val(6,0),val(7,0),  val(8,1),val(9,1),val(2,1),  val(4,0),val(3,0),val(1,1)],
        [val(2,1),val(3,0),val(4,0),  val(5,0),val(1,0),val(7,1),  val(6,1),val(9,0),val(8,0)],

        [val(7,0),val(1,0),val(5,1),  val(6,0),val(2,1),val(3,0),  val(9,1),val(8,0),val(4,1)],
        [val(6,1),val(9,1),val(3,0),  val(7,1),val(8,1),val(4,0),  val(1,1),val(2,0),val(5,1)],
        [val(4,0),val(2,0),val(8,0),  val(1,1),val(5,0),val(9,0),  val(3,0),val(7,1),val(6,0)],

        [val(8,1),val(4,1),val(9,0),  val(2,0),val(6,0),val(5,0),  val(7,0),val(1,0),val(3,0)],
        [val(1,0),val(7,1),val(2,0),  val(3,1),val(4,0),val(8,0),  val(5,0),val(6,0),val(9,1)],
        [val(3,0),val(5,0),val(6,0),  val(9,0),val(7,1),val(1,0),  val(8,0),val(4,0),val(2,0)],
    ],

    // Puzzle 124 of 200
    [
        [val(9,0),val(1,0),val(7,1),  val(4,0),val(3,1),val(5,0),  val(2,0),val(6,1),val(8,0)],
        [val(3,0),val(2,0),val(6,1),  val(8,0),val(1,0),val(7,0),  val(9,1),val(5,1),val(4,1)],
        [val(8,1),val(5,0),val(4,1),  val(2,0),val(9,1),val(6,0),  val(3,0),val(7,0),val(1,0)],

        [val(5,0),val(4,0),val(2,0),  val(3,0),val(7,0),val(1,1),  val(6,0),val(8,0),val(9,1)],
        [val(6,0),val(9,1),val(8,0),  val(5,0),val(2,1),val(4,1),  val(1,1),val(3,0),val(7,0)],
        [val(1,0),val(7,0),val(3,0),  val(9,0),val(6,0),val(8,0),  val(5,1),val(4,0),val(2,0)],

        [val(7,1),val(3,0),val(1,0),  val(6,1),val(8,0),val(9,0),  val(4,0),val(2,0),val(5,0)],
        [val(2,1),val(8,1),val(5,0),  val(1,0),val(4,0),val(3,0),  val(7,1),val(9,1),val(6,0)],
        [val(4,1),val(6,0),val(9,0),  val(7,0),val(5,0),val(2,0),  val(8,0),val(1,1),val(3,0)],
    ],

    // Puzzle 125 of 200
    [
        [val(5,1),val(4,1),val(6,0),  val(3,1),val(9,0),val(8,0),  val(1,1),val(7,0),val(2,0)],
        [val(2,0),val(9,1),val(3,0),  val(6,1),val(7,1),val(1,1),  val(4,0),val(8,0),val(5,1)],
        [val(1,0),val(7,0),val(8,0),  val(2,0),val(5,1),val(4,0),  val(9,1),val(6,0),val(3,0)],

        [val(7,0),val(8,1),val(2,1),  val(9,1),val(3,0),val(6,1),  val(5,0),val(4,1),val(1,0)],
        [val(4,0),val(6,1),val(1,0),  val(5,0),val(8,0),val(2,0),  val(3,0),val(9,1),val(7,0)],
        [val(3,0),val(5,0),val(9,0),  val(4,1),val(1,0),val(7,0),  val(6,0),val(2,1),val(8,1)],

        [val(6,0),val(2,0),val(7,1),  val(1,0),val(4,0),val(5,0),  val(8,0),val(3,0),val(9,0)],
        [val(9,1),val(1,1),val(4,1),  val(8,0),val(2,0),val(3,0),  val(7,1),val(5,1),val(6,0)],
        [val(8,0),val(3,1),val(5,0),  val(7,0),val(6,0),val(9,0),  val(2,0),val(1,0),val(4,0)],
    ],

    // Puzzle 126 of 200
    [
        [val(3,1),val(1,0),val(6,0),  val(2,1),val(4,0),val(8,1),  val(7,0),val(9,0),val(5,0)],
        [val(8,1),val(2,0),val(4,0),  val(5,1),val(9,0),val(7,1),  val(1,0),val(3,0),val(6,0)],
        [val(7,0),val(9,1),val(5,0),  val(3,0),val(1,0),val(6,0),  val(4,1),val(2,0),val(8,0)],

        [val(4,1),val(8,0),val(9,0),  val(7,0),val(5,1),val(3,0),  val(2,0),val(6,1),val(1,1)],
        [val(5,0),val(6,0),val(1,1),  val(9,0),val(2,1),val(4,0),  val(8,0),val(7,1),val(3,0)],
        [val(2,0),val(3,0),val(7,0),  val(8,1),val(6,1),val(1,0),  val(5,0),val(4,1),val(9,0)],

        [val(9,0),val(5,0),val(8,0),  val(6,0),val(7,0),val(2,0),  val(3,0),val(1,1),val(4,0)],
        [val(1,0),val(7,1),val(3,1),  val(4,1),val(8,0),val(9,0),  val(6,0),val(5,1),val(2,0)],
        [val(6,0),val(4,0),val(2,1),  val(1,1),val(3,0),val(5,0),  val(9,0),val(8,0),val(7,1)],
    ],

    // Puzzle 127 of 200
    [
        [val(6,0),val(5,1),val(3,0),  val(1,0),val(8,1),val(9,0),  val(4,0),val(2,0),val(7,0)],
        [val(1,1),val(7,1),val(9,1),  val(4,0),val(3,0),val(2,0),  val(6,0),val(8,0),val(5,0)],
        [val(2,0),val(4,1),val(8,0),  val(5,1),val(6,1),val(7,0),  val(1,0),val(9,0),val(3,0)],

        [val(8,1),val(6,0),val(1,0),  val(7,0),val(2,1),val(3,0),  val(5,0),val(4,0),val(9,1)],
        [val(7,0),val(9,1),val(4,1),  val(6,0),val(1,0),val(5,0),  val(8,0),val(3,0),val(2,1)],
        [val(5,1),val(3,1),val(2,0),  val(8,0),val(9,0),val(4,0),  val(7,0),val(1,0),val(6,1)],

        [val(3,0),val(1,0),val(7,0),  val(2,0),val(4,0),val(6,0),  val(9,0),val(5,1),val(8,0)],
        [val(9,0),val(8,0),val(6,1),  val(3,1),val(5,0),val(1,1),  val(2,0),val(7,0),val(4,1)],
        [val(4,0),val(2,0),val(5,0),  val(9,1),val(7,0),val(8,0),  val(3,1),val(6,0),val(1,1)],
    ],

    // Puzzle 128 of 200
    [
        [val(7,0),val(3,0),val(8,1),  val(9,0),val(6,1),val(5,0),  val(2,0),val(4,1),val(1,0)],
        [val(4,0),val(6,0),val(1,0),  val(2,1),val(8,0),val(7,1),  val(5,0),val(9,0),val(3,0)],
        [val(2,0),val(9,1),val(5,1),  val(1,0),val(4,0),val(3,1),  val(6,1),val(7,1),val(8,0)],

        [val(6,0),val(5,1),val(3,0),  val(8,0),val(7,0),val(4,0),  val(9,0),val(1,0),val(2,1)],
        [val(1,1),val(2,1),val(4,0),  val(6,0),val(3,0),val(9,0),  val(8,0),val(5,1),val(7,1)],
        [val(9,1),val(8,0),val(7,0),  val(5,0),val(2,0),val(1,1),  val(4,0),val(3,0),val(6,0)],

        [val(8,0),val(7,0),val(9,0),  val(4,1),val(1,0),val(2,0),  val(3,0),val(6,1),val(5,1)],
        [val(5,0),val(1,0),val(2,0),  val(3,1),val(9,0),val(6,0),  val(7,0),val(8,1),val(4,0)],
        [val(3,0),val(4,0),val(6,1),  val(7,0),val(5,0),val(8,0),  val(1,0),val(2,0),val(9,1)],
    ],

    // Puzzle 129 of 200
    [
        [val(9,0),val(7,0),val(4,0),  val(5,1),val(3,0),val(8,0),  val(1,1),val(2,0),val(6,0)],
        [val(5,1),val(6,1),val(1,1),  val(7,0),val(2,1),val(4,0),  val(9,0),val(3,0),val(8,1)],
        [val(8,1),val(2,0),val(3,0),  val(6,0),val(1,0),val(9,0),  val(7,0),val(4,0),val(5,0)],

        [val(6,0),val(4,1),val(2,0),  val(1,0),val(5,0),val(3,1),  val(8,1),val(7,0),val(9,0)],
        [val(1,1),val(8,0),val(9,1),  val(2,0),val(4,0),val(7,1),  val(6,0),val(5,0),val(3,0)],
        [val(3,0),val(5,0),val(7,1),  val(8,0),val(9,1),val(6,0),  val(2,1),val(1,0),val(4,0)],

        [val(2,1),val(9,1),val(5,0),  val(3,0),val(8,1),val(1,0),  val(4,0),val(6,1),val(7,0)],
        [val(7,0),val(1,0),val(8,0),  val(4,0),val(6,0),val(5,0),  val(3,1),val(9,0),val(2,0)],
        [val(4,0),val(3,0),val(6,0),  val(9,1),val(7,1),val(2,0),  val(5,0),val(8,0),val(1,0)],
    ],

    // Puzzle 130 of 200
    [
        [val(8,0),val(7,0),val(6,0),  val(4,0),val(1,0),val(9,0),  val(5,0),val(2,0),val(3,0)],
        [val(1,1),val(4,0),val(9,1),  val(3,1),val(5,0),val(2,0),  val(7,0),val(6,0),val(8,1)],
        [val(3,0),val(2,1),val(5,0),  val(8,0),val(6,1),val(7,0),  val(9,1),val(4,0),val(1,0)],

        [val(4,0),val(3,0),val(2,1),  val(5,0),val(9,0),val(1,1),  val(6,1),val(8,0),val(7,0)],
        [val(6,0),val(5,1),val(7,1),  val(2,0),val(8,0),val(3,0),  val(4,0),val(1,0),val(9,0)],
        [val(9,0),val(8,0),val(1,0),  val(7,1),val(4,1),val(6,0),  val(3,1),val(5,0),val(2,0)],

        [val(7,1),val(9,0),val(4,0),  val(1,0),val(2,1),val(5,0),  val(8,0),val(3,1),val(6,0)],
        [val(2,0),val(6,0),val(8,1),  val(9,1),val(3,0),val(4,0),  val(1,1),val(7,1),val(5,0)],
        [val(5,1),val(1,0),val(3,0),  val(6,1),val(7,0),val(8,0),  val(2,0),val(9,0),val(4,1)],
    ],

    // Puzzle 131 of 200
    [
        [val(6,0),val(3,0),val(4,1),  val(9,1),val(8,0),val(7,1),  val(2,0),val(1,0),val(5,0)],
        [val(1,0),val(2,0),val(9,0),  val(3,1),val(5,0),val(4,1),  val(6,0),val(7,1),val(8,1)],
        [val(8,1),val(7,1),val(5,0),  val(6,0),val(2,0),val(1,0),  val(4,0),val(9,0),val(3,1)],

        [val(2,1),val(6,1),val(7,0),  val(1,0),val(9,0),val(8,0),  val(5,0),val(3,0),val(4,0)],
        [val(3,0),val(4,1),val(1,0),  val(5,1),val(7,0),val(2,0),  val(8,1),val(6,0),val(9,0)],
        [val(9,0),val(5,0),val(8,0),  val(4,1),val(6,0),val(3,1),  val(7,0),val(2,0),val(1,1)],

        [val(7,0),val(9,0),val(3,1),  val(8,1),val(4,0),val(6,1),  val(1,1),val(5,0),val(2,0)],
        [val(4,0),val(1,0),val(2,1),  val(7,0),val(3,0),val(5,0),  val(9,1),val(8,0),val(6,0)],
        [val(5,0),val(8,1),val(6,0),  val(2,0),val(1,0),val(9,0),  val(3,0),val(4,0),val(7,0)],
    ],

    // Puzzle 132 of 200
    [
        [val(6,0),val(5,1),val(8,0),  val(3,0),val(9,0),val(7,1),  val(1,0),val(4,0),val(2,0)],
        [val(2,0),val(9,0),val(4,0),  val(6,0),val(5,0),val(1,0),  val(3,1),val(7,1),val(8,0)],
        [val(1,1),val(3,1),val(7,0),  val(4,0),val(2,0),val(8,1),  val(6,0),val(5,0),val(9,1)],

        [val(4,0),val(1,0),val(3,0),  val(9,0),val(8,0),val(2,1),  val(5,1),val(6,0),val(7,0)],
        [val(7,0),val(8,1),val(9,0),  val(1,0),val(6,1),val(5,1),  val(4,0),val(2,1),val(3,0)],
        [val(5,0),val(6,0),val(2,0),  val(7,0),val(3,0),val(4,0),  val(8,0),val(9,1),val(1,1)],

        [val(3,0),val(2,0),val(1,1),  val(5,0),val(4,1),val(9,0),  val(7,1),val(8,0),val(6,0)],
        [val(8,1),val(4,1),val(6,0),  val(2,0),val(7,0),val(3,0),  val(9,0),val(1,0),val(5,1)],
        [val(9,1),val(7,0),val(5,0),  val(8,1),val(1,0),val(6,1),  val(2,0),val(3,0),val(4,0)],
    ],

    // Puzzle 133 of 200
    [
        [val(4,0),val(1,0),val(6,0),  val(3,0),val(2,0),val(7,1),  val(5,0),val(9,1),val(8,0)],
        [val(3,0),val(5,0),val(7,1),  val(9,0),val(8,1),val(1,1),  val(2,1),val(4,0),val(6,1)],
        [val(9,1),val(8,0),val(2,0),  val(4,0),val(6,1),val(5,0),  val(3,0),val(1,0),val(7,0)],

        [val(2,0),val(3,0),val(4,1),  val(8,0),val(1,0),val(9,0),  val(6,0),val(7,0),val(5,1)],
        [val(8,1),val(7,0),val(5,0),  val(6,0),val(4,0),val(2,0),  val(9,1),val(3,1),val(1,0)],
        [val(6,1),val(9,0),val(1,0),  val(7,1),val(5,0),val(3,1),  val(4,0),val(8,0),val(2,1)],

        [val(7,0),val(6,0),val(8,0),  val(2,0),val(9,0),val(4,0),  val(1,0),val(5,1),val(3,0)],
        [val(5,0),val(4,1),val(3,0),  val(1,0),val(7,0),val(6,0),  val(8,0),val(2,0),val(9,0)],
        [val(1,1),val(2,1),val(9,0),  val(5,0),val(3,1),val(8,1),  val(7,1),val(6,0),val(4,0)],
    ],

    // Puzzle 134 of 200
    [
        [val(7,1),val(6,1),val(8,0),  val(2,0),val(9,1),val(3,0),  val(1,0),val(4,1),val(5,0)],
        [val(5,0),val(2,0),val(1,0),  val(8,0),val(4,1),val(7,1),  val(3,0),val(6,0),val(9,0)],
        [val(9,0),val(3,1),val(4,0),  val(1,0),val(5,0),val(6,0),  val(8,1),val(2,0),val(7,0)],

        [val(2,0),val(1,0),val(3,0),  val(5,0),val(6,0),val(4,0),  val(7,1),val(9,0),val(8,0)],
        [val(4,1),val(7,0),val(9,1),  val(3,0),val(2,0),val(8,1),  val(5,0),val(1,0),val(6,1)],
        [val(6,1),val(8,0),val(5,0),  val(9,0),val(7,0),val(1,0),  val(4,0),val(3,1),val(2,1)],

        [val(3,0),val(5,1),val(6,0),  val(4,1),val(8,0),val(9,0),  val(2,1),val(7,0),val(1,0)],
        [val(1,0),val(9,0),val(2,1),  val(7,0),val(3,0),val(5,0),  val(6,0),val(8,0),val(4,0)],
        [val(8,0),val(4,1),val(7,0),  val(6,1),val(1,1),val(2,0),  val(9,0),val(5,0),val(3,1)],
    ],

    // Puzzle 135 of 200
    [
        [val(9,1),val(6,1),val(8,0),  val(2,0),val(1,0),val(3,0),  val(7,0),val(4,1),val(5,0)],
        [val(3,0),val(1,1),val(7,1),  val(4,1),val(5,0),val(9,0),  val(8,0),val(6,1),val(2,1)],
        [val(4,0),val(5,0),val(2,1),  val(7,0),val(8,0),val(6,0),  val(1,0),val(9,0),val(3,1)],

        [val(6,0),val(8,0),val(3,0),  val(9,0),val(2,1),val(4,0),  val(5,1),val(7,0),val(1,0)],
        [val(2,0),val(7,0),val(9,1),  val(5,0),val(3,0),val(1,1),  val(6,1),val(8,1),val(4,0)],
        [val(1,0),val(4,1),val(5,0),  val(6,0),val(7,1),val(8,1),  val(3,0),val(2,0),val(9,1)],

        [val(7,1),val(9,0),val(6,0),  val(3,1),val(4,0),val(5,0),  val(2,1),val(1,1),val(8,0)],
        [val(5,1),val(2,0),val(1,0),  val(8,0),val(9,0),val(7,0),  val(4,0),val(3,0),val(6,0)],
        [val(8,0),val(3,0),val(4,0),  val(1,0),val(6,1),val(2,0),  val(9,0),val(5,0),val(7,0)],
    ],

    // Puzzle 136 of 200
    [
        [val(5,0),val(4,1),val(2,1),  val(9,1),val(1,1),val(6,0),  val(3,0),val(7,0),val(8,0)],
        [val(6,0),val(8,0),val(3,0),  val(4,0),val(5,0),val(7,1),  val(9,1),val(1,0),val(2,1)],
        [val(7,1),val(9,0),val(1,0),  val(8,0),val(3,1),val(2,0),  val(5,0),val(4,0),val(6,1)],

        [val(3,1),val(6,0),val(4,0),  val(5,0),val(8,0),val(1,0),  val(7,1),val(2,0),val(9,0)],
        [val(8,0),val(1,1),val(9,1),  val(7,0),val(2,1),val(4,0),  val(6,0),val(3,0),val(5,0)],
        [val(2,0),val(7,0),val(5,0),  val(6,0),val(9,0),val(3,0),  val(1,1),val(8,0),val(4,0)],

        [val(4,1),val(5,0),val(8,0),  val(1,0),val(7,1),val(9,0),  val(2,0),val(6,0),val(3,1)],
        [val(1,0),val(3,0),val(6,1),  val(2,1),val(4,0),val(5,1),  val(8,1),val(9,1),val(7,0)],
        [val(9,0),val(2,0),val(7,0),  val(3,0),val(6,0),val(8,0),  val(4,0),val(5,1),val(1,0)],
    ],

    // Puzzle 137 of 200
    [
        [val(2,0),val(8,0),val(4,0),  val(9,1),val(1,0),val(6,0),  val(5,0),val(7,1),val(3,0)],
        [val(5,1),val(6,1),val(1,1),  val(3,0),val(2,0),val(7,0),  val(4,0),val(9,1),val(8,1)],
        [val(9,0),val(7,0),val(3,1),  val(5,1),val(4,0),val(8,0),  val(6,0),val(2,0),val(1,0)],

        [val(1,1),val(9,0),val(8,0),  val(4,1),val(3,0),val(5,0),  val(2,1),val(6,0),val(7,1)],
        [val(6,0),val(3,1),val(7,0),  val(8,1),val(9,0),val(2,0),  val(1,0),val(5,0),val(4,0)],
        [val(4,0),val(2,0),val(5,0),  val(6,1),val(7,1),val(1,0),  val(8,1),val(3,0),val(9,0)],

        [val(8,1),val(4,1),val(2,0),  val(7,0),val(6,0),val(9,0),  val(3,0),val(1,0),val(5,1)],
        [val(3,0),val(1,0),val(9,0),  val(2,0),val(5,0),val(4,1),  val(7,0),val(8,0),val(6,0)],
        [val(7,0),val(5,0),val(6,1),  val(1,0),val(8,0),val(3,1),  val(9,0),val(4,0),val(2,0)],
    ],

    // Puzzle 138 of 200
    [
        [val(3,0),val(2,0),val(7,1),  val(5,0),val(1,0),val(9,1),  val(8,0),val(4,1),val(6,0)],
        [val(9,0),val(8,0),val(1,1),  val(3,1),val(4,0),val(6,0),  val(7,0),val(2,0),val(5,0)],
        [val(6,1),val(4,0),val(5,1),  val(7,1),val(2,1),val(8,0),  val(1,0),val(9,0),val(3,0)],

        [val(7,0),val(5,0),val(4,1),  val(6,0),val(3,0),val(2,0),  val(9,1),val(8,1),val(1,0)],
        [val(8,1),val(6,0),val(2,0),  val(9,0),val(5,1),val(1,1),  val(4,0),val(3,1),val(7,0)],
        [val(1,0),val(3,1),val(9,1),  val(4,0),val(8,0),val(7,0),  val(6,0),val(5,0),val(2,1)],

        [val(4,0),val(9,0),val(6,0),  val(2,1),val(7,0),val(3,0),  val(5,0),val(1,0),val(8,0)],
        [val(2,0),val(7,0),val(8,0),  val(1,1),val(9,1),val(5,0),  val(3,1),val(6,0),val(4,0)],
        [val(5,0),val(1,0),val(3,0),  val(8,0),val(6,0),val(4,1),  val(2,1),val(7,0),val(9,0)],
    ],

    // Puzzle 139 of 200
    [
        [val(3,0),val(2,1),val(1,0),  val(8,0),val(6,1),val(7,0),  val(4,0),val(5,1),val(9,0)],
        [val(9,0),val(8,0),val(4,0),  val(5,0),val(1,0),val(3,1),  val(7,0),val(2,1),val(6,0)],
        [val(5,1),val(6,0),val(7,1),  val(9,0),val(4,1),val(2,0),  val(3,1),val(1,0),val(8,1)],

        [val(6,0),val(7,0),val(9,0),  val(3,1),val(2,0),val(1,1),  val(5,0),val(8,0),val(4,0)],
        [val(2,0),val(5,0),val(8,0),  val(7,1),val(9,0),val(4,0),  val(6,0),val(3,0),val(1,0)],
        [val(4,0),val(1,0),val(3,0),  val(6,0),val(5,0),val(8,1),  val(9,1),val(7,0),val(2,1)],

        [val(1,1),val(4,0),val(6,0),  val(2,0),val(3,0),val(5,0),  val(8,0),val(9,0),val(7,0)],
        [val(8,0),val(9,1),val(5,1),  val(1,0),val(7,0),val(6,0),  val(2,0),val(4,0),val(3,1)],
        [val(7,1),val(3,1),val(2,0),  val(4,1),val(8,0),val(9,1),  val(1,1),val(6,0),val(5,0)],
    ],

    // Puzzle 140 of 200
    [
        [val(8,0),val(2,0),val(1,1),  val(9,1),val(5,1),val(3,0),  val(7,0),val(4,0),val(6,1)],
        [val(6,0),val(5,1),val(3,0),  val(2,0),val(7,0),val(4,0),  val(1,0),val(9,0),val(8,0)],
        [val(4,0),val(7,0),val(9,0),  val(6,1),val(1,0),val(8,0),  val(2,1),val(3,1),val(5,0)],

        [val(2,1),val(1,1),val(6,0),  val(8,0),val(4,0),val(5,0),  val(9,0),val(7,0),val(3,0)],
        [val(5,0),val(4,0),val(7,1),  val(3,0),val(9,0),val(1,0),  val(6,1),val(8,1),val(2,0)],
        [val(9,0),val(3,1),val(8,0),  val(7,0),val(2,1),val(6,1),  val(5,0),val(1,0),val(4,0)],

        [val(3,1),val(9,1),val(4,0),  val(1,0),val(6,0),val(2,0),  val(8,1),val(5,1),val(7,0)],
        [val(1,0),val(8,0),val(2,0),  val(5,1),val(3,0),val(7,0),  val(4,1),val(6,0),val(9,0)],
        [val(7,0),val(6,0),val(5,0),  val(4,0),val(8,1),val(9,1),  val(3,0),val(2,0),val(1,0)],
    ],

    // Puzzle 141 of 200
    [
        [val(4,0),val(9,0),val(2,1),  val(3,1),val(6,0),val(7,1),  val(8,1),val(1,0),val(5,0)],
        [val(6,1),val(5,0),val(8,0),  val(9,0),val(4,0),val(1,0),  val(2,0),val(3,1),val(7,0)],
        [val(7,0),val(3,0),val(1,0),  val(2,0),val(8,1),val(5,0),  val(6,0),val(4,0),val(9,0)],

        [val(9,0),val(4,1),val(6,1),  val(8,0),val(1,1),val(3,0),  val(7,0),val(5,0),val(2,1)],
        [val(1,1),val(8,1),val(7,0),  val(4,0),val(5,1),val(2,0),  val(3,1),val(9,0),val(6,0)],
        [val(3,0),val(2,0),val(5,0),  val(6,0),val(7,0),val(9,1),  val(1,0),val(8,0),val(4,1)],

        [val(8,0),val(7,1),val(4,0),  val(1,0),val(9,0),val(6,0),  val(5,0),val(2,0),val(3,0)],
        [val(2,0),val(6,0),val(9,1),  val(5,1),val(3,0),val(8,0),  val(4,0),val(7,0),val(1,0)],
        [val(5,0),val(1,0),val(3,1),  val(7,0),val(2,0),val(4,1),  val(9,0),val(6,1),val(8,0)],
    ],

    // Puzzle 142 of 200
    [
        [val(1,0),val(5,0),val(8,0),  val(4,1),val(3,0),val(7,1),  val(2,1),val(6,0),val(9,1)],
        [val(7,0),val(2,0),val(9,0),  val(8,1),val(5,0),val(6,0),  val(1,0),val(4,1),val(3,0)],
        [val(4,0),val(3,0),val(6,0),  val(1,0),val(2,1),val(9,1),  val(5,0),val(8,1),val(7,0)],

        [val(6,0),val(1,0),val(4,1),  val(9,1),val(7,0),val(5,0),  val(8,0),val(3,0),val(2,0)],
        [val(3,1),val(9,0),val(5,0),  val(2,1),val(8,0),val(1,0),  val(6,1),val(7,1),val(4,0)],
        [val(8,0),val(7,0),val(2,0),  val(6,0),val(4,0),val(3,1),  val(9,0),val(1,0),val(5,1)],

        [val(5,1),val(4,0),val(1,0),  val(3,0),val(6,0),val(2,1),  val(7,1),val(9,0),val(8,0)],
        [val(2,1),val(6,1),val(3,0),  val(7,0),val(9,1),val(8,0),  val(4,0),val(5,0),val(1,0)],
        [val(9,1),val(8,1),val(7,0),  val(5,0),val(1,1),val(4,0),  val(3,0),val(2,0),val(6,1)],
    ],

    // Puzzle 143 of 200
    [
        [val(7,0),val(6,0),val(5,0),  val(3,1),val(8,0),val(2,0),  val(1,1),val(4,0),val(9,0)],
        [val(2,0),val(9,1),val(4,0),  val(1,0),val(7,0),val(6,1),  val(8,0),val(3,1),val(5,1)],
        [val(3,0),val(8,0),val(1,1),  val(4,0),val(9,0),val(5,1),  val(7,1),val(6,0),val(2,1)],

        [val(1,0),val(5,0),val(8,0),  val(6,0),val(2,1),val(9,0),  val(4,0),val(7,0),val(3,0)],
        [val(9,0),val(4,0),val(7,1),  val(8,1),val(1,1),val(3,0),  val(2,0),val(5,0),val(6,0)],
        [val(6,1),val(2,0),val(3,0),  val(5,0),val(4,1),val(7,0),  val(9,0),val(8,1),val(1,0)],

        [val(4,1),val(3,1),val(2,0),  val(7,0),val(6,0),val(1,0),  val(5,0),val(9,1),val(8,0)],
        [val(8,0),val(1,0),val(6,1),  val(9,0),val(5,0),val(4,0),  val(3,0),val(2,0),val(7,1)],
        [val(5,0),val(7,0),val(9,0),  val(2,0),val(3,1),val(8,0),  val(6,0),val(1,0),val(4,0)],
    ],

    // Puzzle 144 of 200
    [
        [val(3,1),val(9,1),val(7,0),  val(1,0),val(4,1),val(6,0),  val(8,0),val(5,0),val(2,0)],
        [val(6,0),val(2,1),val(8,0),  val(5,1),val(9,0),val(3,0),  val(1,0),val(7,1),val(4,0)],
        [val(1,0),val(4,0),val(5,1),  val(7,0),val(2,0),val(8,1),  val(9,0),val(3,0),val(6,1)],

        [val(2,1),val(8,1),val(1,0),  val(6,0),val(3,0),val(7,0),  val(4,0),val(9,1),val(5,0)],
        [val(7,1),val(3,0),val(4,1),  val(9,1),val(5,0),val(2,0),  val(6,0),val(8,0),val(1,0)],
        [val(9,1),val(5,0),val(6,0),  val(4,0),val(8,0),val(1,1),  val(7,0),val(2,0),val(3,1)],

        [val(5,0),val(7,0),val(2,0),  val(8,0),val(1,1),val(4,0),  val(3,0),val(6,1),val(9,0)],
        [val(8,0),val(1,1),val(9,0),  val(3,1),val(6,0),val(5,1),  val(2,0),val(4,0),val(7,0)],
        [val(4,1),val(6,0),val(3,0),  val(2,0),val(7,1),val(9,0),  val(5,0),val(1,1),val(8,0)],
    ],

    // Puzzle 145 of 200
    [
        [val(9,0),val(7,1),val(6,0),  val(4,1),val(5,1),val(1,0),  val(2,0),val(8,0),val(3,0)],
        [val(1,1),val(3,0),val(5,1),  val(9,0),val(2,1),val(8,0),  val(4,0),val(7,0),val(6,1)],
        [val(4,0),val(2,0),val(8,0),  val(6,0),val(7,0),val(3,1),  val(5,0),val(9,0),val(1,1)],

        [val(8,0),val(4,1),val(3,0),  val(5,0),val(6,0),val(9,1),  val(1,0),val(2,0),val(7,0)],
        [val(2,1),val(5,0),val(1,0),  val(7,0),val(8,0),val(4,0),  val(3,1),val(6,0),val(9,1)],
        [val(7,1),val(6,0),val(9,0),  val(1,1),val(3,0),val(2,0),  val(8,0),val(5,1),val(4,0)],

        [val(6,1),val(9,0),val(4,0),  val(8,0),val(1,0),val(5,0),  val(7,1),val(3,1),val(2,0)],
        [val(3,0),val(8,0),val(7,0),  val(2,1),val(4,0),val(6,0),  val(9,1),val(1,0),val(5,1)],
        [val(5,0),val(1,1),val(2,0),  val(3,0),val(9,0),val(7,0),  val(6,0),val(4,1),val(8,0)],
    ],

    // Puzzle 146 of 200
    [
        [val(9,0),val(8,0),val(6,0),  val(5,0),val(4,0),val(7,0),  val(2,1),val(1,1),val(3,0)],
        [val(7,0),val(2,0),val(3,0),  val(6,1),val(9,1),val(1,0),  val(5,0),val(8,1),val(4,0)],
        [val(5,0),val(4,1),val(1,1),  val(8,1),val(2,1),val(3,0),  val(6,0),val(7,0),val(9,1)],

        [val(4,1),val(1,0),val(9,0),  val(3,0),val(6,1),val(2,0),  val(7,1),val(5,0),val(8,0)],
        [val(8,0),val(5,0),val(2,0),  val(7,0),val(1,0),val(9,1),  val(3,0),val(4,0),val(6,0)],
        [val(3,1),val(6,1),val(7,0),  val(4,0),val(8,0),val(5,0),  val(1,1),val(9,1),val(2,0)],

        [val(1,0),val(9,0),val(4,0),  val(2,1),val(5,0),val(6,0),  val(8,0),val(3,1),val(7,1)],
        [val(6,0),val(3,1),val(5,1),  val(9,0),val(7,0),val(8,1),  val(4,0),val(2,0),val(1,0)],
        [val(2,1),val(7,0),val(8,1),  val(1,0),val(3,0),val(4,0),  val(9,1),val(6,0),val(5,0)],
    ],

    // Puzzle 147 of 200
    [
        [val(2,0),val(9,1),val(1,0),  val(6,0),val(4,1),val(5,1),  val(7,0),val(8,0),val(3,0)],
        [val(5,0),val(6,0),val(3,1),  val(1,0),val(8,0),val(7,0),  val(2,1),val(9,0),val(4,0)],
        [val(7,0),val(4,0),val(8,1),  val(9,0),val(3,0),val(2,0),  val(5,0),val(6,1),val(1,0)],

        [val(4,1),val(5,1),val(9,0),  val(3,0),val(2,0),val(8,0),  val(6,0),val(1,0),val(7,0)],
        [val(3,0),val(1,0),val(7,1),  val(4,0),val(6,0),val(9,0),  val(8,1),val(5,1),val(2,0)],
        [val(6,0),val(8,0),val(2,0),  val(7,0),val(5,0),val(1,1),  val(4,0),val(3,0),val(9,1)],

        [val(1,1),val(7,0),val(4,0),  val(5,0),val(9,0),val(6,1),  val(3,0),val(2,0),val(8,1)],
        [val(9,0),val(2,0),val(5,0),  val(8,1),val(7,1),val(3,0),  val(1,1),val(4,0),val(6,0)],
        [val(8,1),val(3,0),val(6,0),  val(2,1),val(1,0),val(4,0),  val(9,1),val(7,1),val(5,1)],
    ],

    // Puzzle 148 of 200
    [
        [val(7,0),val(6,0),val(1,1),  val(5,1),val(4,1),val(9,1),  val(8,0),val(3,1),val(2,0)],
        [val(8,1),val(4,0),val(2,0),  val(7,0),val(1,0),val(3,0),  val(5,0),val(6,1),val(9,1)],
        [val(9,0),val(3,1),val(5,0),  val(2,0),val(8,0),val(6,0),  val(4,0),val(7,1),val(1,0)],

        [val(3,0),val(9,0),val(6,0),  val(1,1),val(5,0),val(8,0),  val(7,0),val(2,1),val(4,0)],
        [val(1,0),val(7,0),val(4,1),  val(9,0),val(6,0),val(2,0),  val(3,0),val(8,0),val(5,0)],
        [val(5,0),val(2,0),val(8,0),  val(3,1),val(7,0),val(4,0),  val(1,1),val(9,0),val(6,1)],

        [val(2,1),val(8,0),val(7,0),  val(4,0),val(9,0),val(5,0),  val(6,0),val(1,0),val(3,0)],
        [val(6,0),val(5,0),val(9,1),  val(8,0),val(3,0),val(1,1),  val(2,0),val(4,0),val(7,0)],
        [val(4,0),val(1,1),val(3,0),  val(6,1),val(2,1),val(7,1),  val(9,0),val(5,0),val(8,1)],
    ],

    // Puzzle 149 of 200
    [
        [val(2,0),val(8,0),val(9,1),  val(1,1),val(5,0),val(6,0),  val(7,0),val(3,0),val(4,1)],
        [val(6,0),val(1,1),val(7,0),  val(3,1),val(2,1),val(4,0),  val(5,0),val(9,1),val(8,0)],
        [val(3,0),val(4,0),val(5,0),  val(7,0),val(9,0),val(8,0),  val(2,1),val(1,0),val(6,0)],

        [val(8,0),val(9,1),val(6,0),  val(4,0),val(3,0),val(2,0),  val(1,1),val(7,0),val(5,0)],
        [val(7,1),val(3,0),val(4,0),  val(5,1),val(1,1),val(9,0),  val(8,1),val(6,0),val(2,1)],
        [val(5,1),val(2,0),val(1,0),  val(8,0),val(6,0),val(7,1),  val(3,1),val(4,0),val(9,0)],

        [val(4,1),val(6,0),val(3,0),  val(2,0),val(7,0),val(5,1),  val(9,0),val(8,1),val(1,0)],
        [val(1,0),val(5,1),val(8,0),  val(9,0),val(4,1),val(3,0),  val(6,1),val(2,0),val(7,0)],
        [val(9,0),val(7,0),val(2,0),  val(6,0),val(8,1),val(1,0),  val(4,0),val(5,0),val(3,0)],
    ],

    // Puzzle 150 of 200
    [
        [val(4,0),val(7,0),val(9,0),  val(3,0),val(1,1),val(6,1),  val(5,1),val(8,0),val(2,0)],
        [val(8,1),val(5,0),val(1,0),  val(4,1),val(7,0),val(2,0),  val(6,0),val(3,0),val(9,1)],
        [val(3,0),val(6,0),val(2,1),  val(8,1),val(9,0),val(5,0),  val(4,0),val(1,0),val(7,0)],

        [val(5,0),val(8,0),val(7,0),  val(1,0),val(6,0),val(3,0),  val(2,0),val(9,0),val(4,0)],
        [val(1,1),val(2,0),val(4,0),  val(7,0),val(8,1),val(9,1),  val(3,0),val(5,0),val(6,0)],
        [val(9,0),val(3,1),val(6,0),  val(2,1),val(5,1),val(4,0),  val(1,0),val(7,0),val(8,0)],

        [val(7,0),val(4,1),val(5,1),  val(6,0),val(3,0),val(8,0),  val(9,0),val(2,1),val(1,0)],
        [val(6,0),val(9,1),val(8,1),  val(5,0),val(2,0),val(1,0),  val(7,0),val(4,1),val(3,1)],
        [val(2,0),val(1,0),val(3,0),  val(9,0),val(4,0),val(7,1),  val(8,0),val(6,1),val(5,0)],
    ],

    // Puzzle 151 of 200
    [
        [val(3,1),val(4,0),val(5,0),  val(2,0),val(7,1),val(1,1),  val(9,0),val(6,0),val(8,0)],
        [val(6,0),val(2,1),val(1,0),  val(4,0),val(8,1),val(9,1),  val(5,0),val(3,0),val(7,0)],
        [val(9,0),val(7,0),val(8,0),  val(3,0),val(5,0),val(6,0),  val(4,0),val(1,0),val(2,1)],

        [val(5,0),val(6,0),val(9,1),  val(8,0),val(1,1),val(2,0),  val(3,1),val(7,0),val(4,0)],
        [val(7,1),val(3,0),val(4,0),  val(6,1),val(9,0),val(5,0),  val(2,0),val(8,0),val(1,0)],
        [val(1,0),val(8,1),val(2,0),  val(7,0),val(3,0),val(4,1),  val(6,1),val(5,0),val(9,1)],

        [val(8,0),val(5,1),val(3,1),  val(9,0),val(2,0),val(7,0),  val(1,0),val(4,1),val(6,0)],
        [val(4,0),val(9,1),val(7,0),  val(1,0),val(6,0),val(3,0),  val(8,1),val(2,1),val(5,0)],
        [val(2,1),val(1,0),val(6,0),  val(5,1),val(4,0),val(8,0),  val(7,0),val(9,0),val(3,0)],
    ],

    // Puzzle 152 of 200
    [
        [val(9,0),val(8,0),val(7,1),  val(1,0),val(2,0),val(3,0),  val(4,0),val(6,0),val(5,0)],
        [val(2,1),val(3,0),val(4,1),  val(5,0),val(9,0),val(6,1),  val(7,1),val(8,0),val(1,1)],
        [val(6,1),val(5,0),val(1,1),  val(8,1),val(4,0),val(7,0),  val(9,0),val(3,0),val(2,0)],

        [val(5,0),val(1,0),val(6,0),  val(9,0),val(7,0),val(2,0),  val(3,0),val(4,1),val(8,1)],
        [val(8,0),val(9,1),val(3,0),  val(6,0),val(5,1),val(4,0),  val(1,0),val(2,1),val(7,0)],
        [val(7,1),val(4,0),val(2,0),  val(3,1),val(8,0),val(1,0),  val(5,0),val(9,1),val(6,1)],

        [val(4,0),val(2,0),val(9,0),  val(7,0),val(1,0),val(8,1),  val(6,0),val(5,0),val(3,0)],
        [val(3,0),val(7,0),val(8,1),  val(4,0),val(6,0),val(5,0),  val(2,0),val(1,0),val(9,1)],
        [val(1,0),val(6,0),val(5,1),  val(2,1),val(3,1),val(9,0),  val(8,0),val(7,0),val(4,0)],
    ],

    // Puzzle 153 of 200
    [
        [val(1,1),val(7,0),val(3,0),  val(4,0),val(6,1),val(8,0),  val(5,0),val(9,1),val(2,1)],
        [val(6,0),val(8,0),val(9,0),  val(2,1),val(7,0),val(5,1),  val(4,0),val(1,0),val(3,0)],
        [val(2,0),val(5,0),val(4,0),  val(1,0),val(9,0),val(3,0),  val(8,1),val(7,0),val(6,0)],

        [val(3,0),val(4,0),val(1,0),  val(5,0),val(2,0),val(9,0),  val(7,0),val(6,1),val(8,0)],
        [val(5,1),val(9,0),val(2,0),  val(7,0),val(8,1),val(6,1),  val(1,0),val(3,1),val(4,1)],
        [val(7,1),val(6,1),val(8,0),  val(3,0),val(4,1),val(1,1),  val(9,0),val(2,0),val(5,0)],

        [val(8,0),val(3,0),val(6,0),  val(9,1),val(1,1),val(4,1),  val(2,0),val(5,1),val(7,0)],
        [val(4,0),val(1,0),val(7,0),  val(6,0),val(5,0),val(2,0),  val(3,1),val(8,0),val(9,0)],
        [val(9,0),val(2,1),val(5,0),  val(8,0),val(3,0),val(7,1),  val(6,1),val(4,0),val(1,0)],
    ],

    // Puzzle 154 of 200
    [
        [val(5,0),val(8,1),val(9,1),  val(4,0),val(6,1),val(1,0),  val(3,1),val(7,0),val(2,0)],
        [val(4,0),val(2,0),val(1,0),  val(8,1),val(3,0),val(7,0),  val(9,1),val(6,1),val(5,0)],
        [val(6,0),val(7,1),val(3,0),  val(2,1),val(5,0),val(9,1),  val(1,0),val(4,0),val(8,0)],

        [val(2,1),val(4,1),val(6,0),  val(7,0),val(1,0),val(8,0),  val(5,0),val(9,1),val(3,0)],
        [val(3,1),val(9,0),val(8,1),  val(6,0),val(4,0),val(5,0),  val(2,1),val(1,0),val(7,1)],
        [val(7,0),val(1,0),val(5,0),  val(9,0),val(2,0),val(3,0),  val(4,1),val(8,0),val(6,0)],

        [val(8,0),val(3,0),val(2,0),  val(1,0),val(9,0),val(6,0),  val(7,0),val(5,0),val(4,1)],
        [val(9,0),val(6,0),val(4,0),  val(5,1),val(7,0),val(2,1),  val(8,1),val(3,0),val(1,0)],
        [val(1,1),val(5,1),val(7,1),  val(3,0),val(8,0),val(4,0),  val(6,0),val(2,0),val(9,0)],
    ],

    // Puzzle 155 of 200
    [
        [val(2,0),val(3,0),val(5,1),  val(1,0),val(6,0),val(9,0),  val(8,1),val(7,1),val(4,0)],
        [val(4,0),val(8,0),val(7,0),  val(5,0),val(3,1),val(2,0),  val(1,0),val(9,0),val(6,0)],
        [val(6,0),val(9,1),val(1,0),  val(4,0),val(7,1),val(8,1),  val(5,0),val(3,0),val(2,1)],

        [val(9,0),val(2,0),val(4,0),  val(6,0),val(5,1),val(7,1),  val(3,0),val(1,0),val(8,0)],
        [val(7,1),val(5,0),val(6,0),  val(8,0),val(1,1),val(3,0),  val(2,0),val(4,1),val(9,1)],
        [val(3,1),val(1,1),val(8,0),  val(2,0),val(9,0),val(4,0),  val(7,0),val(6,1),val(5,0)],

        [val(8,0),val(4,1),val(9,1),  val(3,0),val(2,0),val(1,0),  val(6,0),val(5,0),val(7,1)],
        [val(1,0),val(6,1),val(2,0),  val(7,0),val(4,0),val(5,0),  val(9,0),val(8,1),val(3,0)],
        [val(5,1),val(7,0),val(3,0),  val(9,0),val(8,0),val(6,1),  val(4,0),val(2,0),val(1,1)],
    ],

    // Puzzle 156 of 200
    [
        [val(3,0),val(6,1),val(4,1),  val(2,0),val(1,0),val(5,0),  val(7,0),val(9,0),val(8,1)],
        [val(7,0),val(9,0),val(8,0),  val(4,1),val(6,0),val(3,0),  val(5,1),val(1,0),val(2,0)],
        [val(1,0),val(5,1),val(2,0),  val(7,1),val(9,0),val(8,0),  val(3,1),val(4,0),val(6,0)],

        [val(6,0),val(8,1),val(7,0),  val(9,0),val(5,0),val(4,0),  val(2,1),val(3,0),val(1,0)],
        [val(2,0),val(1,0),val(5,0),  val(6,1),val(3,1),val(7,0),  val(9,0),val(8,0),val(4,0)],
        [val(9,1),val(4,0),val(3,0),  val(8,0),val(2,0),val(1,1),  val(6,0),val(5,0),val(7,1)],

        [val(8,1),val(7,0),val(9,0),  val(3,0),val(4,0),val(2,1),  val(1,0),val(6,0),val(5,1)],
        [val(4,0),val(3,1),val(1,1),  val(5,0),val(7,1),val(6,0),  val(8,0),val(2,0),val(9,1)],
        [val(5,0),val(2,0),val(6,1),  val(1,0),val(8,1),val(9,0),  val(4,0),val(7,0),val(3,0)],
    ],

    // Puzzle 157 of 200
    [
        [val(3,1),val(5,0),val(6,0),  val(2,0),val(4,1),val(7,1),  val(8,0),val(9,0),val(1,0)],
        [val(4,1),val(7,1),val(2,0),  val(8,1),val(9,0),val(1,0),  val(5,1),val(6,0),val(3,0)],
        [val(1,0),val(8,0),val(9,0),  val(5,0),val(6,1),val(3,0),  val(4,0),val(2,1),val(7,0)],

        [val(6,0),val(9,1),val(8,0),  val(1,1),val(5,0),val(4,0),  val(3,0),val(7,1),val(2,1)],
        [val(5,0),val(4,0),val(7,1),  val(3,1),val(2,0),val(6,0),  val(9,0),val(1,0),val(8,1)],
        [val(2,0),val(1,1),val(3,0),  val(9,1),val(7,0),val(8,0),  val(6,0),val(5,1),val(4,0)],

        [val(9,0),val(3,0),val(4,0),  val(6,0),val(1,0),val(2,0),  val(7,0),val(8,0),val(5,0)],
        [val(7,0),val(6,1),val(1,0),  val(4,0),val(8,1),val(5,0),  val(2,1),val(3,0),val(9,0)],
        [val(8,1),val(2,0),val(5,0),  val(7,1),val(3,0),val(9,1),  val(1,0),val(4,0),val(6,1)],
    ],

    // Puzzle 158 of 200
    [
        [val(1,1),val(4,0),val(5,1),  val(9,0),val(8,1),val(6,0),  val(3,0),val(2,0),val(7,0)],
        [val(6,0),val(9,0),val(7,0),  val(2,0),val(1,0),val(3,1),  val(5,0),val(8,0),val(4,0)],
        [val(8,0),val(2,0),val(3,1),  val(7,1),val(4,0),val(5,0),  val(1,0),val(6,1),val(9,0)],

        [val(5,0),val(1,0),val(8,0),  val(4,0),val(6,0),val(2,0),  val(9,1),val(7,0),val(3,0)],
        [val(4,0),val(3,0),val(9,1),  val(5,1),val(7,1),val(8,0),  val(2,0),val(1,1),val(6,0)],
        [val(2,0),val(7,1),val(6,1),  val(1,0),val(3,0),val(9,0),  val(4,1),val(5,0),val(8,0)],

        [val(9,0),val(6,1),val(4,0),  val(8,0),val(2,1),val(1,1),  val(7,0),val(3,1),val(5,0)],
        [val(3,0),val(5,0),val(2,0),  val(6,0),val(9,1),val(7,0),  val(8,0),val(4,0),val(1,0)],
        [val(7,0),val(8,1),val(1,0),  val(3,0),val(5,1),val(4,0),  val(6,0),val(9,0),val(2,1)],
    ],

    // Puzzle 159 of 200
    [
        [val(6,0),val(4,1),val(9,1),  val(2,0),val(7,0),val(3,0),  val(8,1),val(1,0),val(5,1)],
        [val(1,0),val(3,0),val(2,0),  val(5,1),val(8,0),val(4,0),  val(9,0),val(7,0),val(6,1)],
        [val(8,1),val(5,0),val(7,1),  val(6,0),val(9,0),val(1,0),  val(2,0),val(4,1),val(3,0)],

        [val(3,0),val(6,0),val(8,0),  val(1,0),val(5,0),val(9,1),  val(4,1),val(2,0),val(7,0)],
        [val(7,0),val(2,0),val(4,0),  val(3,0),val(6,0),val(8,1),  val(1,1),val(5,1),val(9,1)],
        [val(5,0),val(9,0),val(1,1),  val(4,0),val(2,1),val(7,0),  val(3,0),val(6,0),val(8,0)],

        [val(2,0),val(8,0),val(3,0),  val(7,1),val(4,0),val(5,1),  val(6,0),val(9,1),val(1,1)],
        [val(9,0),val(7,0),val(6,0),  val(8,0),val(1,0),val(2,0),  val(5,0),val(3,1),val(4,0)],
        [val(4,1),val(1,0),val(5,0),  val(9,0),val(3,1),val(6,0),  val(7,0),val(8,0),val(2,0)],
    ],

    // Puzzle 160 of 200
    [
        [val(7,0),val(2,0),val(5,0),  val(6,1),val(1,0),val(8,1),  val(3,0),val(4,1),val(9,0)],
        [val(6,0),val(4,0),val(1,0),  val(9,0),val(5,1),val(3,0),  val(8,0),val(2,0),val(7,0)],
        [val(9,1),val(8,0),val(3,0),  val(7,0),val(2,1),val(4,1),  val(1,1),val(5,0),val(6,0)],

        [val(5,0),val(3,1),val(2,1),  val(4,0),val(7,0),val(6,0),  val(9,1),val(1,0),val(8,0)],
        [val(8,0),val(9,0),val(4,0),  val(1,0),val(3,0),val(5,0),  val(7,1),val(6,0),val(2,1)],
        [val(1,1),val(7,1),val(6,0),  val(2,0),val(8,0),val(9,0),  val(5,1),val(3,1),val(4,0)],

        [val(2,0),val(6,0),val(7,0),  val(5,1),val(9,1),val(1,0),  val(4,0),val(8,0),val(3,0)],
        [val(3,0),val(5,0),val(9,1),  val(8,1),val(4,0),val(2,1),  val(6,0),val(7,0),val(1,0)],
        [val(4,1),val(1,1),val(8,0),  val(3,0),val(6,0),val(7,1),  val(2,0),val(9,0),val(5,0)],
    ],

    // Puzzle 161 of 200
    [
        [val(2,1),val(8,1),val(6,0),  val(4,0),val(3,1),val(9,0),  val(1,0),val(7,1),val(5,0)],
        [val(5,0),val(3,0),val(7,0),  val(6,0),val(2,1),val(1,1),  val(9,1),val(8,0),val(4,1)],
        [val(9,1),val(4,0),val(1,0),  val(5,0),val(7,1),val(8,0),  val(2,0),val(3,0),val(6,1)],

        [val(8,0),val(1,0),val(4,1),  val(2,0),val(9,0),val(7,1),  val(5,0),val(6,1),val(3,0)],
        [val(3,1),val(9,1),val(5,0),  val(1,0),val(8,1),val(6,0),  val(7,0),val(4,0),val(2,0)],
        [val(6,0),val(7,1),val(2,0),  val(3,0),val(4,0),val(5,0),  val(8,0),val(1,0),val(9,0)],

        [val(1,0),val(5,1),val(9,0),  val(8,0),val(6,0),val(4,0),  val(3,1),val(2,0),val(7,0)],
        [val(7,0),val(6,0),val(3,0),  val(9,0),val(1,0),val(2,0),  val(4,1),val(5,0),val(8,0)],
        [val(4,0),val(2,0),val(8,1),  val(7,0),val(5,0),val(3,1),  val(6,0),val(9,0),val(1,1)],
    ],

    // Puzzle 162 of 200
    [
        [val(1,1),val(2,1),val(5,1),  val(7,1),val(6,0),val(3,1),  val(9,0),val(8,1),val(4,0)],
        [val(6,0),val(8,1),val(4,1),  val(2,0),val(9,0),val(5,1),  val(1,0),val(3,1),val(7,0)],
        [val(3,0),val(9,0),val(7,1),  val(8,0),val(1,0),val(4,0),  val(5,0),val(2,0),val(6,1)],

        [val(7,0),val(4,0),val(6,1),  val(5,0),val(3,0),val(2,1),  val(8,0),val(9,0),val(1,0)],
        [val(8,0),val(1,0),val(2,0),  val(6,0),val(4,0),val(9,0),  val(3,0),val(7,0),val(5,0)],
        [val(5,0),val(3,1),val(9,0),  val(1,0),val(8,1),val(7,0),  val(4,0),val(6,1),val(2,0)],

        [val(9,0),val(5,0),val(3,0),  val(4,1),val(7,0),val(6,0),  val(2,0),val(1,0),val(8,0)],
        [val(2,0),val(6,0),val(1,1),  val(9,1),val(5,0),val(8,0),  val(7,1),val(4,0),val(3,0)],
        [val(4,1),val(7,0),val(8,1),  val(3,1),val(2,1),val(1,0),  val(6,0),val(5,1),val(9,0)],
    ],

    // Puzzle 163 of 200
    [
        [val(3,0),val(5,0),val(2,0),  val(8,0),val(9,0),val(1,0),  val(7,0),val(6,0),val(4,0)],
        [val(1,1),val(4,0),val(7,1),  val(3,0),val(6,0),val(2,0),  val(5,1),val(9,1),val(8,0)],
        [val(9,0),val(6,0),val(8,0),  val(4,0),val(5,0),val(7,1),  val(3,0),val(1,0),val(2,1)],

        [val(7,0),val(2,0),val(4,0),  val(9,0),val(8,1),val(6,1),  val(1,1),val(3,0),val(5,0)],
        [val(6,1),val(3,0),val(9,0),  val(1,1),val(2,1),val(5,0),  val(4,1),val(8,0),val(7,0)],
        [val(5,1),val(8,1),val(1,0),  val(7,0),val(3,0),val(4,0),  val(9,0),val(2,0),val(6,0)],

        [val(4,0),val(7,0),val(6,1),  val(2,0),val(1,0),val(9,1),  val(8,1),val(5,1),val(3,0)],
        [val(8,0),val(9,1),val(5,0),  val(6,0),val(7,1),val(3,0),  val(2,0),val(4,0),val(1,0)],
        [val(2,1),val(1,0),val(3,0),  val(5,0),val(4,1),val(8,0),  val(6,1),val(7,0),val(9,0)],
    ],

    // Puzzle 164 of 200
    [
        [val(5,0),val(7,0),val(4,0),  val(8,0),val(6,0),val(3,1),  val(9,0),val(1,0),val(2,0)],
        [val(6,0),val(9,1),val(8,0),  val(1,0),val(2,0),val(4,0),  val(7,0),val(5,0),val(3,1)],
        [val(1,1),val(3,0),val(2,1),  val(9,0),val(5,0),val(7,1),  val(6,0),val(4,1),val(8,0)],

        [val(3,0),val(4,0),val(9,1),  val(5,0),val(7,0),val(8,0),  val(2,1),val(6,1),val(1,0)],
        [val(7,0),val(6,0),val(5,1),  val(4,1),val(1,0),val(2,1),  val(3,1),val(8,0),val(9,1)],
        [val(8,1),val(2,0),val(1,0),  val(3,0),val(9,0),val(6,0),  val(4,0),val(7,0),val(5,0)],

        [val(4,1),val(8,0),val(7,1),  val(2,0),val(3,0),val(1,1),  val(5,0),val(9,0),val(6,0)],
        [val(9,0),val(1,0),val(3,0),  val(6,0),val(4,1),val(5,0),  val(8,1),val(2,0),val(7,1)],
        [val(2,0),val(5,0),val(6,1),  val(7,1),val(8,0),val(9,1),  val(1,0),val(3,1),val(4,0)],
    ],

    // Puzzle 165 of 200
    [
        [val(8,1),val(9,1),val(6,0),  val(4,0),val(5,1),val(7,0),  val(2,1),val(3,0),val(1,0)],
        [val(1,0),val(5,0),val(7,0),  val(9,1),val(2,0),val(3,1),  val(8,0),val(6,0),val(4,0)],
        [val(4,1),val(2,1),val(3,0),  val(1,0),val(8,0),val(6,0),  val(7,0),val(9,0),val(5,0)],

        [val(3,0),val(8,0),val(5,0),  val(2,0),val(6,0),val(1,1),  val(9,0),val(4,0),val(7,1)],
        [val(7,0),val(4,0),val(9,0),  val(8,0),val(3,0),val(5,1),  val(6,0),val(1,1),val(2,1)],
        [val(6,0),val(1,0),val(2,0),  val(7,1),val(4,1),val(9,0),  val(3,1),val(5,0),val(8,0)],

        [val(5,1),val(6,0),val(8,1),  val(3,1),val(1,0),val(2,0),  val(4,0),val(7,1),val(9,1)],
        [val(2,0),val(7,1),val(1,0),  val(6,0),val(9,0),val(4,0),  val(5,0),val(8,1),val(3,0)],
        [val(9,0),val(3,0),val(4,1),  val(5,0),val(7,0),val(8,0),  val(1,1),val(2,0),val(6,0)],
    ],

    // Puzzle 166 of 200
    [
        [val(8,0),val(2,0),val(9,1),  val(3,0),val(1,1),val(4,0),  val(7,0),val(6,0),val(5,1)],
        [val(3,0),val(1,0),val(5,0),  val(7,1),val(2,0),val(6,1),  val(8,1),val(9,0),val(4,0)],
        [val(6,0),val(4,0),val(7,0),  val(9,0),val(5,0),val(8,1),  val(2,0),val(1,1),val(3,0)],

        [val(5,1),val(9,0),val(2,0),  val(4,0),val(8,0),val(1,0),  val(6,1),val(3,0),val(7,0)],
        [val(1,0),val(7,1),val(3,1),  val(6,0),val(9,0),val(5,0),  val(4,0),val(8,0),val(2,0)],
        [val(4,1),val(8,0),val(6,0),  val(2,0),val(3,1),val(7,0),  val(1,0),val(5,1),val(9,1)],

        [val(2,0),val(3,0),val(4,0),  val(8,0),val(6,1),val(9,0),  val(5,0),val(7,0),val(1,0)],
        [val(9,1),val(5,1),val(8,1),  val(1,0),val(7,0),val(2,0),  val(3,0),val(4,1),val(6,0)],
        [val(7,0),val(6,0),val(1,1),  val(5,1),val(4,0),val(3,0),  val(9,0),val(2,1),val(8,0)],
    ],

    // Puzzle 167 of 200
    [
        [val(1,1),val(3,0),val(6,1),  val(2,0),val(8,0),val(9,0),  val(4,1),val(7,0),val(5,0)],
        [val(5,0),val(7,1),val(8,0),  val(1,1),val(6,0),val(4,0),  val(3,0),val(2,0),val(9,1)],
        [val(9,0),val(4,1),val(2,0),  val(3,0),val(5,0),val(7,1),  val(8,1),val(1,0),val(6,0)],

        [val(8,0),val(9,1),val(1,0),  val(6,0),val(4,0),val(2,1),  val(7,1),val(5,1),val(3,0)],
        [val(2,1),val(6,0),val(3,0),  val(7,0),val(9,0),val(5,0),  val(1,0),val(4,0),val(8,0)],
        [val(7,0),val(5,0),val(4,1),  val(8,0),val(1,0),val(3,1),  val(6,0),val(9,0),val(2,0)],

        [val(6,0),val(2,0),val(9,0),  val(4,1),val(7,1),val(8,0),  val(5,0),val(3,0),val(1,1)],
        [val(3,1),val(8,0),val(7,0),  val(5,1),val(2,0),val(1,0),  val(9,0),val(6,1),val(4,0)],
        [val(4,0),val(1,0),val(5,0),  val(9,0),val(3,0),val(6,0),  val(2,1),val(8,1),val(7,0)],
    ],

    // Puzzle 168 of 200
    [
        [val(4,1),val(5,0),val(7,0),  val(6,0),val(3,0),val(2,1),  val(8,0),val(1,1),val(9,1)],
        [val(2,0),val(3,0),val(8,0),  val(5,0),val(9,0),val(1,1),  val(7,1),val(6,1),val(4,0)],
        [val(6,0),val(1,0),val(9,1),  val(7,1),val(8,0),val(4,0),  val(5,0),val(3,0),val(2,0)],

        [val(8,1),val(7,1),val(2,0),  val(3,0),val(6,1),val(9,0),  val(4,0),val(5,0),val(1,0)],
        [val(1,0),val(4,1),val(6,0),  val(8,0),val(2,0),val(5,1),  val(9,0),val(7,0),val(3,1)],
        [val(3,1),val(9,0),val(5,0),  val(4,0),val(1,0),val(7,0),  val(2,0),val(8,0),val(6,0)],

        [val(9,1),val(2,0),val(3,0),  val(1,1),val(7,0),val(8,0),  val(6,1),val(4,1),val(5,0)],
        [val(5,0),val(8,1),val(1,0),  val(2,0),val(4,1),val(6,0),  val(3,0),val(9,0),val(7,1)],
        [val(7,0),val(6,0),val(4,0),  val(9,1),val(5,0),val(3,1),  val(1,0),val(2,0),val(8,0)],
    ],

    // Puzzle 169 of 200
    [
        [val(1,0),val(3,1),val(8,0),  val(4,0),val(9,1),val(5,0),  val(6,0),val(2,0),val(7,0)],
        [val(9,0),val(7,0),val(2,1),  val(8,0),val(3,0),val(6,0),  val(5,1),val(4,1),val(1,0)],
        [val(4,0),val(6,0),val(5,0),  val(1,1),val(2,0),val(7,1),  val(3,0),val(9,0),val(8,0)],

        [val(5,1),val(4,0),val(1,0),  val(2,0),val(8,0),val(9,0),  val(7,1),val(6,1),val(3,0)],
        [val(3,0),val(9,0),val(6,0),  val(5,0),val(7,0),val(4,1),  val(8,1),val(1,0),val(2,0)],
        [val(2,0),val(8,0),val(7,1),  val(3,1),val(6,0),val(1,0),  val(4,0),val(5,0),val(9,0)],

        [val(6,1),val(2,0),val(4,0),  val(7,0),val(1,1),val(8,0),  val(9,0),val(3,1),val(5,0)],
        [val(7,0),val(5,1),val(3,0),  val(9,0),val(4,0),val(2,1),  val(1,0),val(8,0),val(6,0)],
        [val(8,1),val(1,1),val(9,0),  val(6,0),val(5,0),val(3,1),  val(2,0),val(7,0),val(4,1)],
    ],

    // Puzzle 170 of 200
    [
        [val(1,0),val(5,1),val(6,1),  val(8,0),val(7,1),val(9,0),  val(3,0),val(2,1),val(4,0)],
        [val(7,0),val(9,0),val(8,1),  val(2,1),val(3,1),val(4,0),  val(6,0),val(5,0),val(1,0)],
        [val(2,0),val(3,0),val(4,0),  val(6,0),val(1,0),val(5,0),  val(8,0),val(9,0),val(7,0)],

        [val(4,1),val(7,0),val(2,0),  val(3,0),val(9,1),val(6,0),  val(1,1),val(8,0),val(5,0)],
        [val(3,0),val(6,0),val(1,0),  val(4,0),val(5,0),val(8,1),  val(2,1),val(7,1),val(9,0)],
        [val(5,0),val(8,1),val(9,1),  val(7,0),val(2,1),val(1,0),  val(4,1),val(6,1),val(3,0)],

        [val(9,1),val(2,0),val(3,0),  val(1,1),val(8,0),val(7,0),  val(5,0),val(4,0),val(6,0)],
        [val(8,0),val(4,1),val(7,0),  val(5,1),val(6,0),val(3,1),  val(9,0),val(1,0),val(2,0)],
        [val(6,1),val(1,0),val(5,0),  val(9,0),val(4,0),val(2,0),  val(7,1),val(3,0),val(8,0)],
    ],

    // Puzzle 171 of 200
    [
        [val(5,0),val(4,0),val(7,1),  val(2,0),val(9,0),val(1,0),  val(6,0),val(8,0),val(3,0)],
        [val(3,0),val(8,1),val(9,0),  val(4,0),val(7,0),val(6,0),  val(1,1),val(2,0),val(5,1)],
        [val(6,1),val(2,1),val(1,0),  val(5,1),val(3,1),val(8,0),  val(9,1),val(7,0),val(4,0)],

        [val(4,0),val(5,1),val(8,0),  val(9,0),val(2,1),val(7,0),  val(3,1),val(1,1),val(6,0)],
        [val(7,0),val(9,1),val(6,0),  val(1,0),val(8,0),val(3,0),  val(4,0),val(5,0),val(2,0)],
        [val(2,0),val(1,0),val(3,0),  val(6,0),val(5,0),val(4,1),  val(7,1),val(9,0),val(8,0)],

        [val(9,1),val(6,1),val(4,0),  val(8,1),val(1,0),val(2,0),  val(5,0),val(3,0),val(7,0)],
        [val(8,0),val(7,0),val(5,0),  val(3,0),val(4,0),val(9,1),  val(2,1),val(6,0),val(1,0)],
        [val(1,0),val(3,1),val(2,0),  val(7,0),val(6,0),val(5,0),  val(8,0),val(4,1),val(9,0)],
    ],

    // Puzzle 172 of 200
    [
        [val(9,0),val(7,0),val(1,0),  val(6,0),val(5,1),val(4,1),  val(8,0),val(3,0),val(2,0)],
        [val(2,0),val(4,0),val(8,0),  val(9,0),val(1,0),val(3,1),  val(6,1),val(7,0),val(5,0)],
        [val(3,0),val(5,1),val(6,1),  val(2,0),val(8,0),val(7,0),  val(4,0),val(1,1),val(9,1)],

        [val(4,1),val(1,0),val(7,1),  val(8,0),val(3,1),val(5,0),  val(2,0),val(9,0),val(6,0)],
        [val(5,0),val(9,1),val(3,0),  val(4,0),val(6,0),val(2,1),  val(7,0),val(8,1),val(1,0)],
        [val(6,0),val(8,1),val(2,0),  val(7,0),val(9,0),val(1,0),  val(3,0),val(5,1),val(4,0)],

        [val(7,1),val(6,0),val(5,0),  val(1,0),val(2,0),val(8,1),  val(9,0),val(4,1),val(3,0)],
        [val(1,0),val(2,1),val(4,1),  val(3,0),val(7,0),val(9,0),  val(5,0),val(6,0),val(8,0)],
        [val(8,1),val(3,0),val(9,0),  val(5,1),val(4,0),val(6,0),  val(1,1),val(2,0),val(7,0)],
    ],

    // Puzzle 173 of 200
    [
        [val(1,0),val(8,0),val(5,0),  val(9,1),val(7,0),val(3,0),  val(2,0),val(6,1),val(4,0)],
        [val(3,0),val(9,0),val(4,1),  val(2,1),val(6,0),val(1,1),  val(5,0),val(7,0),val(8,0)],
        [val(2,0),val(6,1),val(7,1),  val(4,0),val(8,0),val(5,0),  val(3,1),val(1,1),val(9,0)],

        [val(8,0),val(7,0),val(1,0),  val(3,0),val(9,0),val(2,1),  val(4,1),val(5,0),val(6,1)],
        [val(4,0),val(2,0),val(9,1),  val(7,0),val(5,0),val(6,0),  val(1,0),val(8,0),val(3,0)],
        [val(5,1),val(3,0),val(6,0),  val(8,0),val(1,1),val(4,0),  val(9,0),val(2,1),val(7,1)],

        [val(7,1),val(1,1),val(8,0),  val(5,0),val(4,0),val(9,0),  val(6,0),val(3,1),val(2,0)],
        [val(6,0),val(4,0),val(3,1),  val(1,0),val(2,0),val(7,0),  val(8,1),val(9,0),val(5,1)],
        [val(9,0),val(5,1),val(2,0),  val(6,0),val(3,0),val(8,0),  val(7,0),val(4,0),val(1,0)],
    ],

    // Puzzle 174 of 200
    [
        [val(5,1),val(3,0),val(4,1),  val(6,1),val(1,0),val(7,1),  val(9,0),val(2,0),val(8,0)],
        [val(1,1),val(2,0),val(9,0),  val(4,0),val(5,0),val(8,0),  val(3,0),val(7,0),val(6,0)],
        [val(6,0),val(7,0),val(8,0),  val(2,1),val(9,1),val(3,0),  val(5,0),val(4,0),val(1,0)],

        [val(4,0),val(1,0),val(7,0),  val(5,0),val(3,1),val(2,0),  val(8,0),val(6,0),val(9,1)],
        [val(8,0),val(6,0),val(2,0),  val(1,0),val(7,0),val(9,1),  val(4,1),val(3,0),val(5,1)],
        [val(9,0),val(5,0),val(3,1),  val(8,1),val(6,1),val(4,0),  val(2,0),val(1,1),val(7,0)],

        [val(2,1),val(4,0),val(1,1),  val(7,0),val(8,0),val(5,1),  val(6,1),val(9,0),val(3,0)],
        [val(7,0),val(9,0),val(5,0),  val(3,0),val(2,0),val(6,0),  val(1,0),val(8,0),val(4,0)],
        [val(3,0),val(8,1),val(6,1),  val(9,0),val(4,1),val(1,0),  val(7,1),val(5,0),val(2,0)],
    ],

    // Puzzle 175 of 200
    [
        [val(7,0),val(5,0),val(6,1),  val(4,0),val(1,0),val(2,1),  val(3,0),val(9,1),val(8,0)],
        [val(9,0),val(3,0),val(1,0),  val(7,0),val(8,1),val(6,0),  val(4,0),val(5,0),val(2,1)],
        [val(2,0),val(4,0),val(8,0),  val(9,0),val(3,1),val(5,1),  val(6,0),val(1,0),val(7,0)],

        [val(1,0),val(2,1),val(9,1),  val(3,0),val(7,0),val(8,0),  val(5,0),val(6,1),val(4,0)],
        [val(8,1),val(7,0),val(5,1),  val(6,0),val(9,1),val(4,0),  val(2,0),val(3,0),val(1,0)],
        [val(3,1),val(6,0),val(4,1),  val(5,0),val(2,0),val(1,0),  val(7,0),val(8,0),val(9,0)],

        [val(4,0),val(8,0),val(7,1),  val(1,0),val(6,0),val(3,1),  val(9,1),val(2,0),val(5,0)],
        [val(5,0),val(1,0),val(3,1),  val(2,1),val(4,1),val(9,1),  val(8,1),val(7,0),val(6,1)],
        [val(6,0),val(9,0),val(2,0),  val(8,1),val(5,1),val(7,0),  val(1,0),val(4,0),val(3,0)],
    ],

    // Puzzle 176 of 200
    [
        [val(2,0),val(8,1),val(4,0),  val(9,0),val(6,0),val(5,0),  val(1,0),val(3,0),val(7,1)],
        [val(1,0),val(9,0),val(3,1),  val(7,0),val(8,0),val(2,1),  val(4,0),val(6,1),val(5,0)],
        [val(5,0),val(6,0),val(7,0),  val(3,0),val(4,0),val(1,0),  val(9,0),val(8,0),val(2,1)],

        [val(8,1),val(2,0),val(9,0),  val(1,1),val(3,0),val(6,0),  val(5,1),val(7,0),val(4,0)],
        [val(7,1),val(3,0),val(5,0),  val(8,1),val(9,1),val(4,0),  val(2,0),val(1,0),val(6,1)],
        [val(6,0),val(4,0),val(1,0),  val(5,1),val(2,1),val(7,0),  val(8,0),val(9,1),val(3,0)],

        [val(9,0),val(5,1),val(2,0),  val(6,0),val(1,1),val(3,1),  val(7,0),val(4,0),val(8,0)],
        [val(4,1),val(1,0),val(6,1),  val(2,0),val(7,1),val(8,0),  val(3,0),val(5,0),val(9,1)],
        [val(3,0),val(7,0),val(8,0),  val(4,0),val(5,0),val(9,0),  val(6,1),val(2,0),val(1,0)],
    ],

    // Puzzle 177 of 200
    [
        [val(4,1),val(8,0),val(3,0),  val(9,0),val(1,0),val(6,0),  val(7,1),val(2,0),val(5,1)],
        [val(5,0),val(2,1),val(1,0),  val(4,1),val(8,0),val(7,0),  val(6,0),val(9,1),val(3,0)],
        [val(6,0),val(7,0),val(9,1),  val(3,0),val(2,0),val(5,0),  val(4,0),val(8,0),val(1,0)],

        [val(9,0),val(3,1),val(8,0),  val(6,1),val(4,0),val(1,1),  val(5,1),val(7,0),val(2,0)],
        [val(1,0),val(4,1),val(5,1),  val(2,0),val(7,1),val(3,0),  val(9,0),val(6,0),val(8,0)],
        [val(2,0),val(6,0),val(7,1),  val(8,1),val(5,0),val(9,0),  val(1,1),val(3,0),val(4,0)],

        [val(3,0),val(1,0),val(4,0),  val(7,1),val(9,0),val(2,1),  val(8,0),val(5,0),val(6,0)],
        [val(7,0),val(5,1),val(2,0),  val(1,0),val(6,0),val(8,0),  val(3,0),val(4,0),val(9,1)],
        [val(8,0),val(9,0),val(6,0),  val(5,0),val(3,1),val(4,1),  val(2,1),val(1,1),val(7,0)],
    ],

    // Puzzle 178 of 200
    [
        [val(1,0),val(8,0),val(9,0),  val(2,0),val(3,0),val(4,1),  val(6,0),val(5,0),val(7,0)],
        [val(4,0),val(7,0),val(5,1),  val(9,1),val(6,0),val(1,1),  val(2,0),val(8,1),val(3,0)],
        [val(6,1),val(3,0),val(2,0),  val(8,0),val(7,1),val(5,0),  val(9,0),val(4,1),val(1,1)],

        [val(7,1),val(6,0),val(1,0),  val(3,0),val(4,1),val(9,0),  val(5,0),val(2,1),val(8,1)],
        [val(5,1),val(2,0),val(3,1),  val(7,0),val(8,0),val(6,1),  val(4,1),val(1,0),val(9,0)],
        [val(8,0),val(9,1),val(4,0),  val(1,0),val(5,0),val(2,0),  val(7,1),val(3,0),val(6,0)],

        [val(3,0),val(4,0),val(8,0),  val(5,1),val(9,0),val(7,0),  val(1,1),val(6,0),val(2,0)],
        [val(2,1),val(5,0),val(7,0),  val(6,0),val(1,0),val(8,1),  val(3,0),val(9,0),val(4,0)],
        [val(9,0),val(1,0),val(6,1),  val(4,0),val(2,0),val(3,0),  val(8,0),val(7,0),val(5,1)],
    ],

    // Puzzle 179 of 200
    [
        [val(1,0),val(2,0),val(6,1),  val(4,1),val(7,1),val(3,0),  val(5,0),val(8,0),val(9,1)],
        [val(4,0),val(9,1),val(7,0),  val(5,0),val(1,0),val(8,1),  val(3,0),val(6,0),val(2,1)],
        [val(8,1),val(5,0),val(3,0),  val(9,0),val(2,0),val(6,0),  val(1,0),val(7,1),val(4,0)],

        [val(6,1),val(7,0),val(1,0),  val(2,0),val(8,0),val(9,0),  val(4,0),val(3,0),val(5,0)],
        [val(2,0),val(3,0),val(5,1),  val(1,0),val(6,0),val(4,1),  val(7,1),val(9,0),val(8,1)],
        [val(9,1),val(8,1),val(4,0),  val(3,1),val(5,0),val(7,0),  val(6,0),val(2,1),val(1,1)],

        [val(3,1),val(4,0),val(8,0),  val(6,0),val(9,1),val(5,0),  val(2,0),val(1,0),val(7,0)],
        [val(5,0),val(1,1),val(9,1),  val(7,1),val(3,1),val(2,1),  val(8,0),val(4,0),val(6,0)],
        [val(7,0),val(6,0),val(2,0),  val(8,0),val(4,0),val(1,0),  val(9,0),val(5,1),val(3,0)],
    ],

    // Puzzle 180 of 200
    [
        [val(8,1),val(3,0),val(5,0),  val(1,0),val(7,0),val(6,0),  val(4,1),val(2,0),val(9,0)],
        [val(7,0),val(4,0),val(6,0),  val(9,1),val(3,1),val(2,0),  val(8,0),val(1,0),val(5,1)],
        [val(1,0),val(9,1),val(2,0),  val(4,0),val(5,1),val(8,1),  val(3,1),val(7,1),val(6,0)],

        [val(5,0),val(1,1),val(8,0),  val(2,1),val(4,0),val(7,0),  val(9,0),val(6,0),val(3,0)],
        [val(4,1),val(7,0),val(3,1),  val(8,0),val(6,0),val(9,0),  val(2,0),val(5,0),val(1,0)],
        [val(2,0),val(6,0),val(9,1),  val(5,0),val(1,0),val(3,0),  val(7,0),val(4,0),val(8,1)],

        [val(6,0),val(8,0),val(4,0),  val(7,0),val(9,1),val(5,0),  val(1,0),val(3,1),val(2,1)],
        [val(9,0),val(5,0),val(7,1),  val(3,1),val(2,0),val(1,1),  val(6,0),val(8,0),val(4,0)],
        [val(3,0),val(2,0),val(1,0),  val(6,1),val(8,0),val(4,0),  val(5,1),val(9,0),val(7,1)],
    ],

    // Puzzle 181 of 200
    [
        [val(4,1),val(3,0),val(7,0),  val(8,1),val(1,0),val(5,0),  val(6,0),val(2,0),val(9,0)],
        [val(9,0),val(2,0),val(6,0),  val(3,1),val(4,1),val(7,0),  val(1,0),val(8,0),val(5,1)],
        [val(5,1),val(1,0),val(8,0),  val(9,0),val(2,0),val(6,0),  val(3,0),val(4,1),val(7,1)],

        [val(6,0),val(8,0),val(3,0),  val(7,0),val(9,0),val(4,0),  val(2,1),val(5,1),val(1,0)],
        [val(1,1),val(7,1),val(9,1),  val(5,0),val(8,0),val(2,0),  val(4,0),val(3,0),val(6,0)],
        [val(2,0),val(4,1),val(5,0),  val(6,0),val(3,0),val(1,0),  val(7,0),val(9,0),val(8,0)],

        [val(8,0),val(6,1),val(2,0),  val(4,0),val(7,0),val(9,1),  val(5,0),val(1,0),val(3,0)],
        [val(3,0),val(5,0),val(1,0),  val(2,1),val(6,0),val(8,1),  val(9,0),val(7,1),val(4,1)],
        [val(7,0),val(9,0),val(4,0),  val(1,0),val(5,0),val(3,1),  val(8,1),val(6,1),val(2,1)],
    ],

    // Puzzle 182 of 200
    [
        [val(9,0),val(8,0),val(7,0),  val(6,0),val(4,1),val(5,0),  val(1,0),val(3,0),val(2,1)],
        [val(2,0),val(6,1),val(4,1),  val(3,0),val(8,0),val(1,0),  val(9,0),val(5,1),val(7,0)],
        [val(3,1),val(5,0),val(1,0),  val(2,1),val(9,0),val(7,1),  val(6,0),val(4,0),val(8,0)],

        [val(5,0),val(7,0),val(8,1),  val(1,0),val(3,1),val(6,1),  val(4,0),val(2,0),val(9,0)],
        [val(6,1),val(4,1),val(9,0),  val(5,0),val(2,1),val(8,0),  val(7,1),val(1,0),val(3,0)],
        [val(1,0),val(3,0),val(2,0),  val(4,1),val(7,0),val(9,0),  val(8,1),val(6,1),val(5,0)],

        [val(4,0),val(9,1),val(5,1),  val(7,0),val(6,0),val(2,0),  val(3,0),val(8,1),val(1,1)],
        [val(8,0),val(1,1),val(3,1),  val(9,1),val(5,0),val(4,0),  val(2,0),val(7,0),val(6,0)],
        [val(7,0),val(2,0),val(6,0),  val(8,0),val(1,1),val(3,0),  val(5,0),val(9,0),val(4,0)],
    ],

    // Puzzle 183 of 200
    [
        [val(9,0),val(6,1),val(8,1),  val(5,0),val(2,1),val(1,0),  val(3,0),val(7,0),val(4,0)],
        [val(4,0),val(7,1),val(3,0),  val(8,0),val(6,1),val(9,0),  val(1,1),val(2,0),val(5,0)],
        [val(5,1),val(2,0),val(1,1),  val(4,0),val(3,0),val(7,0),  val(9,0),val(8,1),val(6,0)],

        [val(8,0),val(5,0),val(6,1),  val(9,0),val(1,0),val(3,0),  val(7,1),val(4,1),val(2,0)],
        [val(7,1),val(3,0),val(9,1),  val(2,0),val(4,0),val(5,1),  val(8,0),val(6,0),val(1,1)],
        [val(1,0),val(4,0),val(2,0),  val(6,0),val(7,0),val(8,1),  val(5,0),val(3,0),val(9,0)],

        [val(3,0),val(9,1),val(4,1),  val(1,0),val(8,0),val(6,1),  val(2,0),val(5,1),val(7,0)],
        [val(6,0),val(1,0),val(7,0),  val(3,0),val(5,0),val(2,0),  val(4,1),val(9,1),val(8,0)],
        [val(2,0),val(8,0),val(5,0),  val(7,1),val(9,1),val(4,0),  val(6,0),val(1,0),val(3,0)],
    ],

    // Puzzle 184 of 200
    [
        [val(8,1),val(4,0),val(9,0),  val(3,1),val(5,1),val(1,0),  val(6,0),val(7,0),val(2,0)],
        [val(5,0),val(1,1),val(7,0),  val(2,0),val(6,1),val(9,0),  val(8,1),val(4,0),val(3,0)],
        [val(2,0),val(3,0),val(6,1),  val(7,0),val(8,0),val(4,0),  val(9,1),val(1,1),val(5,0)],

        [val(3,0),val(6,0),val(1,0),  val(5,1),val(9,0),val(7,0),  val(2,0),val(8,0),val(4,0)],
        [val(4,0),val(8,0),val(5,0),  val(1,0),val(2,0),val(3,0),  val(7,1),val(9,0),val(6,1)],
        [val(7,0),val(9,0),val(2,1),  val(8,0),val(4,1),val(6,1),  val(3,0),val(5,0),val(1,0)],

        [val(1,0),val(7,0),val(4,1),  val(9,1),val(3,0),val(2,1),  val(5,0),val(6,0),val(8,0)],
        [val(6,0),val(5,1),val(3,0),  val(4,0),val(7,1),val(8,1),  val(1,1),val(2,0),val(9,0)],
        [val(9,0),val(2,1),val(8,0),  val(6,0),val(1,0),val(5,0),  val(4,0),val(3,1),val(7,1)],
    ],

    // Puzzle 185 of 200
    [
        [val(5,0),val(8,1),val(4,1),  val(1,0),val(9,0),val(2,0),  val(3,0),val(6,0),val(7,0)],
        [val(6,1),val(1,0),val(3,0),  val(7,0),val(8,0),val(5,1),  val(9,0),val(4,1),val(2,0)],
        [val(2,0),val(7,1),val(9,1),  val(3,0),val(4,0),val(6,0),  val(8,0),val(5,1),val(1,1)],

        [val(3,1),val(9,0),val(7,0),  val(6,0),val(5,0),val(1,0),  val(4,0),val(2,1),val(8,0)],
        [val(1,0),val(2,0),val(8,0),  val(4,1),val(7,1),val(3,0),  val(5,1),val(9,0),val(6,0)],
        [val(4,0),val(6,1),val(5,0),  val(9,0),val(2,0),val(8,1),  val(7,1),val(1,0),val(3,0)],

        [val(9,0),val(3,1),val(2,0),  val(8,0),val(6,1),val(4,0),  val(1,0),val(7,0),val(5,0)],
        [val(8,0),val(4,0),val(6,0),  val(5,0),val(1,0),val(7,0),  val(2,1),val(3,0),val(9,1)],
        [val(7,0),val(5,1),val(1,0),  val(2,1),val(3,1),val(9,0),  val(6,0),val(8,0),val(4,0)],
    ],

    // Puzzle 186 of 200
    [
        [val(4,0),val(8,0),val(5,0),  val(1,1),val(2,0),val(6,0),  val(3,1),val(9,0),val(7,0)],
        [val(6,0),val(1,0),val(7,0),  val(8,1),val(3,1),val(9,0),  val(2,0),val(5,1),val(4,1)],
        [val(3,0),val(9,1),val(2,1),  val(5,0),val(7,1),val(4,0),  val(8,0),val(6,0),val(1,0)],

        [val(8,0),val(5,0),val(6,0),  val(4,0),val(9,0),val(3,0),  val(1,0),val(7,0),val(2,1)],
        [val(1,0),val(7,1),val(9,0),  val(2,0),val(5,1),val(8,0),  val(4,1),val(3,0),val(6,0)],
        [val(2,0),val(3,0),val(4,1),  val(6,0),val(1,0),val(7,0),  val(9,1),val(8,1),val(5,0)],

        [val(9,0),val(6,0),val(8,1),  val(7,0),val(4,0),val(1,0),  val(5,0),val(2,0),val(3,1)],
        [val(5,1),val(4,0),val(3,0),  val(9,0),val(6,1),val(2,0),  val(7,0),val(1,1),val(8,0)],
        [val(7,0),val(2,0),val(1,0),  val(3,1),val(8,0),val(5,0),  val(6,1),val(4,0),val(9,1)],
    ],

    // Puzzle 187 of 200
    [
        [val(2,0),val(8,1),val(5,0),  val(3,0),val(7,0),val(1,0),  val(9,0),val(6,0),val(4,0)],
        [val(7,1),val(6,1),val(9,1),  val(2,0),val(4,0),val(8,1),  val(1,0),val(3,1),val(5,0)],
        [val(3,0),val(4,0),val(1,0),  val(5,1),val(6,0),val(9,0),  val(2,1),val(8,0),val(7,1)],

        [val(9,0),val(7,1),val(4,0),  val(6,0),val(2,0),val(5,0),  val(3,0),val(1,0),val(8,0)],
        [val(5,0),val(2,0),val(3,0),  val(8,0),val(1,0),val(4,0),  val(6,1),val(7,0),val(9,0)],
        [val(8,0),val(1,0),val(6,0),  val(9,1),val(3,1),val(7,0),  val(4,0),val(5,1),val(2,0)],

        [val(6,1),val(9,0),val(2,0),  val(7,0),val(8,1),val(3,0),  val(5,0),val(4,0),val(1,1)],
        [val(1,1),val(3,1),val(8,0),  val(4,0),val(5,1),val(2,0),  val(7,1),val(9,0),val(6,1)],
        [val(4,0),val(5,0),val(7,0),  val(1,0),val(9,1),val(6,0),  val(8,1),val(2,1),val(3,0)],
    ],

    // Puzzle 188 of 200
    [
        [val(9,0),val(6,0),val(7,0),  val(3,0),val(2,0),val(5,0),  val(1,0),val(8,1),val(4,1)],
        [val(3,0),val(5,1),val(8,1),  val(4,1),val(1,0),val(6,1),  val(7,1),val(2,0),val(9,0)],
        [val(2,1),val(4,0),val(1,0),  val(8,0),val(9,1),val(7,0),  val(5,1),val(3,0),val(6,0)],

        [val(7,1),val(9,0),val(4,0),  val(5,0),val(8,0),val(3,1),  val(2,0),val(6,0),val(1,0)],
        [val(6,0),val(8,0),val(2,0),  val(9,0),val(7,1),val(1,0),  val(3,1),val(4,0),val(5,0)],
        [val(5,0),val(1,1),val(3,0),  val(2,0),val(6,0),val(4,0),  val(8,1),val(9,1),val(7,0)],

        [val(4,0),val(2,0),val(5,0),  val(7,1),val(3,0),val(9,0),  val(6,0),val(1,1),val(8,0)],
        [val(1,1),val(3,0),val(9,0),  val(6,1),val(5,1),val(8,0),  val(4,0),val(7,0),val(2,0)],
        [val(8,0),val(7,0),val(6,1),  val(1,1),val(4,0),val(2,0),  val(9,1),val(5,0),val(3,1)],
    ],

    // Puzzle 189 of 200
    [
        [val(7,0),val(8,0),val(4,0),  val(6,0),val(3,0),val(5,1),  val(2,0),val(9,0),val(1,0)],
        [val(3,1),val(1,1),val(9,1),  val(4,1),val(7,0),val(2,1),  val(6,0),val(5,0),val(8,0)],
        [val(6,0),val(2,0),val(5,0),  val(1,0),val(8,0),val(9,1),  val(4,0),val(3,0),val(7,1)],

        [val(9,0),val(7,0),val(2,0),  val(8,0),val(6,0),val(3,0),  val(1,0),val(4,0),val(5,1)],
        [val(4,1),val(5,1),val(1,1),  val(2,0),val(9,0),val(7,0),  val(8,0),val(6,1),val(3,1)],
        [val(8,0),val(3,0),val(6,0),  val(5,0),val(4,0),val(1,1),  val(9,1),val(7,1),val(2,0)],

        [val(5,0),val(6,0),val(7,1),  val(9,0),val(1,1),val(8,0),  val(3,0),val(2,1),val(4,1)],
        [val(2,0),val(9,1),val(8,1),  val(3,0),val(5,0),val(4,0),  val(7,0),val(1,0),val(6,0)],
        [val(1,0),val(4,0),val(3,1),  val(7,0),val(2,0),val(6,0),  val(5,0),val(8,0),val(9,0)],
    ],

    // Puzzle 190 of 200
    [
        [val(4,0),val(7,0),val(3,1),  val(9,1),val(2,0),val(1,0),  val(5,0),val(8,0),val(6,0)],
        [val(6,0),val(1,0),val(2,0),  val(5,0),val(7,0),val(8,1),  val(9,0),val(3,0),val(4,1)],
        [val(8,0),val(5,0),val(9,0),  val(4,0),val(6,0),val(3,0),  val(1,1),val(2,0),val(7,0)],

        [val(5,1),val(2,1),val(8,0),  val(1,0),val(4,1),val(6,1),  val(3,0),val(7,0),val(9,1)],
        [val(7,0),val(9,0),val(6,0),  val(8,1),val(3,0),val(2,0),  val(4,0),val(5,0),val(1,1)],
        [val(1,0),val(3,1),val(4,0),  val(7,0),val(9,0),val(5,0),  val(8,0),val(6,1),val(2,1)],

        [val(9,0),val(4,1),val(5,1),  val(2,0),val(8,0),val(7,0),  val(6,1),val(1,0),val(3,0)],
        [val(2,0),val(6,1),val(1,1),  val(3,0),val(5,0),val(9,1),  val(7,1),val(4,0),val(8,0)],
        [val(3,0),val(8,0),val(7,0),  val(6,0),val(1,0),val(4,1),  val(2,0),val(9,1),val(5,0)],
    ],

    // Puzzle 191 of 200
    [
        [val(2,0),val(1,0),val(4,0),  val(6,1),val(5,1),val(3,1),  val(9,0),val(7,1),val(8,0)],
        [val(7,1),val(8,0),val(6,1),  val(2,1),val(4,0),val(9,0),  val(3,0),val(1,0),val(5,0)],
        [val(3,0),val(9,1),val(5,0),  val(8,0),val(7,0),val(1,0),  val(2,0),val(6,0),val(4,1)],

        [val(1,0),val(5,1),val(3,1),  val(4,0),val(8,0),val(6,1),  val(7,0),val(9,0),val(2,0)],
        [val(4,1),val(6,0),val(2,0),  val(9,0),val(1,0),val(7,1),  val(8,0),val(5,0),val(3,0)],
        [val(8,1),val(7,0),val(9,1),  val(5,0),val(3,1),val(2,0),  val(6,0),val(4,1),val(1,0)],

        [val(9,0),val(3,0),val(7,1),  val(1,0),val(2,0),val(4,0),  val(5,0),val(8,1),val(6,0)],
        [val(6,0),val(4,0),val(8,0),  val(3,1),val(9,1),val(5,0),  val(1,0),val(2,1),val(7,0)],
        [val(5,1),val(2,1),val(1,0),  val(7,0),val(6,0),val(8,0),  val(4,1),val(3,0),val(9,0)],
    ],

    // Puzzle 192 of 200
    [
        [val(8,0),val(2,0),val(3,0),  val(5,1),val(4,1),val(7,1),  val(6,0),val(1,0),val(9,1)],
        [val(7,0),val(9,0),val(5,1),  val(3,0),val(1,0),val(6,1),  val(2,0),val(4,0),val(8,0)],
        [val(6,0),val(4,0),val(1,0),  val(2,0),val(9,0),val(8,0),  val(7,0),val(3,1),val(5,0)],

        [val(1,0),val(8,0),val(9,1),  val(7,0),val(3,1),val(4,0),  val(5,1),val(6,0),val(2,0)],
        [val(5,0),val(3,0),val(2,1),  val(1,0),val(6,0),val(9,0),  val(4,0),val(8,0),val(7,0)],
        [val(4,1),val(6,0),val(7,0),  val(8,1),val(5,0),val(2,0),  val(1,1),val(9,0),val(3,0)],

        [val(3,1),val(5,0),val(8,0),  val(6,0),val(2,0),val(1,1),  val(9,0),val(7,1),val(4,1)],
        [val(9,0),val(7,1),val(6,0),  val(4,0),val(8,0),val(5,1),  val(3,0),val(2,0),val(1,0)],
        [val(2,0),val(1,1),val(4,0),  val(9,1),val(7,0),val(3,0),  val(8,0),val(5,0),val(6,0)],
    ],

    // Puzzle 193 of 200
    [
        [val(9,0),val(7,0),val(6,0),  val(4,1),val(3,0),val(5,0),  val(1,0),val(2,1),val(8,0)],
        [val(2,0),val(4,0),val(1,1),  val(6,0),val(8,1),val(9,0),  val(7,1),val(3,1),val(5,0)],
        [val(5,1),val(8,1),val(3,0),  val(1,1),val(7,0),val(2,0),  val(9,0),val(6,0),val(4,1)],

        [val(3,1),val(1,0),val(5,0),  val(9,1),val(2,0),val(4,0),  val(8,1),val(7,1),val(6,0)],
        [val(8,0),val(6,0),val(4,0),  val(7,1),val(1,1),val(3,0),  val(2,0),val(5,0),val(9,0)],
        [val(7,0),val(2,1),val(9,1),  val(8,0),val(5,0),val(6,0),  val(4,0),val(1,1),val(3,0)],

        [val(6,0),val(5,1),val(7,1),  val(2,0),val(9,0),val(8,0),  val(3,0),val(4,0),val(1,0)],
        [val(4,0),val(9,0),val(2,0),  val(3,0),val(6,0),val(1,0),  val(5,0),val(8,0),val(7,0)],
        [val(1,0),val(3,0),val(8,0),  val(5,0),val(4,1),val(7,0),  val(6,1),val(9,0),val(2,1)],
    ],

    // Puzzle 194 of 200
    [
        [val(9,0),val(8,1),val(4,0),  val(7,0),val(5,0),val(3,1),  val(2,0),val(6,0),val(1,0)],
        [val(2,1),val(1,0),val(6,1),  val(4,0),val(9,0),val(8,0),  val(5,0),val(3,0),val(7,1)],
        [val(5,0),val(7,0),val(3,1),  val(1,0),val(6,1),val(2,0),  val(9,1),val(4,0),val(8,0)],

        [val(4,0),val(9,1),val(2,0),  val(8,0),val(3,0),val(7,0),  val(1,0),val(5,1),val(6,0)],
        [val(8,0),val(3,0),val(5,0),  val(9,0),val(1,0),val(6,1),  val(4,1),val(7,1),val(2,1)],
        [val(1,1),val(6,0),val(7,0),  val(5,0),val(2,0),val(4,0),  val(8,0),val(9,0),val(3,1)],

        [val(6,0),val(5,0),val(8,0),  val(2,1),val(7,1),val(9,0),  val(3,0),val(1,0),val(4,0)],
        [val(3,1),val(2,0),val(9,0),  val(6,0),val(4,0),val(1,1),  val(7,0),val(8,0),val(5,0)],
        [val(7,1),val(4,1),val(1,0),  val(3,1),val(8,0),val(5,0),  val(6,1),val(2,0),val(9,0)],
    ],

    // Puzzle 195 of 200
    [
        [val(8,1),val(5,0),val(3,1),  val(4,0),val(1,0),val(7,1),  val(6,1),val(2,0),val(9,0)],
        [val(1,0),val(9,0),val(4,1),  val(3,0),val(2,0),val(6,1),  val(5,1),val(8,0),val(7,0)],
        [val(7,0),val(2,0),val(6,0),  val(9,1),val(5,0),val(8,0),  val(1,0),val(3,0),val(4,0)],

        [val(4,0),val(6,1),val(8,0),  val(1,1),val(9,0),val(5,1),  val(3,0),val(7,0),val(2,1)],
        [val(5,0),val(1,0),val(2,0),  val(7,1),val(8,0),val(3,0),  val(9,0),val(4,1),val(6,0)],
        [val(3,0),val(7,0),val(9,0),  val(6,1),val(4,0),val(2,1),  val(8,1),val(1,1),val(5,0)],

        [val(2,1),val(8,0),val(1,0),  val(5,0),val(6,0),val(4,0),  val(7,0),val(9,0),val(3,0)],
        [val(9,0),val(3,1),val(5,0),  val(2,0),val(7,0),val(1,0),  val(4,0),val(6,0),val(8,0)],
        [val(6,1),val(4,1),val(7,0),  val(8,0),val(3,1),val(9,0),  val(2,0),val(5,0),val(1,1)],
    ],

    // Puzzle 196 of 200
    [
        [val(4,0),val(9,0),val(3,1),  val(1,0),val(5,1),val(2,0),  val(8,1),val(7,0),val(6,0)],
        [val(5,0),val(7,0),val(6,1),  val(3,0),val(4,0),val(8,0),  val(1,0),val(9,1),val(2,0)],
        [val(8,1),val(2,1),val(1,0),  val(9,1),val(6,0),val(7,0),  val(3,0),val(4,1),val(5,0)],

        [val(6,0),val(8,1),val(9,0),  val(2,0),val(7,0),val(5,1),  val(4,0),val(3,0),val(1,1)],
        [val(1,0),val(3,0),val(4,0),  val(6,0),val(8,1),val(9,0),  val(5,0),val(2,0),val(7,0)],
        [val(2,1),val(5,0),val(7,1),  val(4,0),val(1,1),val(3,1),  val(6,0),val(8,0),val(9,0)],

        [val(3,1),val(1,0),val(2,1),  val(8,0),val(9,0),val(6,1),  val(7,0),val(5,0),val(4,0)],
        [val(7,0),val(6,0),val(8,0),  val(5,0),val(2,0),val(4,0),  val(9,0),val(1,0),val(3,0)],
        [val(9,0),val(4,1),val(5,1),  val(7,1),val(3,0),val(1,0),  val(2,0),val(6,1),val(8,0)],
    ],

    // Puzzle 197 of 200
    [
        [val(7,0),val(5,0),val(1,1),  val(3,1),val(4,1),val(2,1),  val(8,0),val(9,1),val(6,1)],
        [val(9,1),val(6,1),val(3,0),  val(1,0),val(7,0),val(8,0),  val(2,0),val(5,0),val(4,0)],
        [val(4,0),val(2,0),val(8,0),  val(6,0),val(5,0),val(9,0),  val(3,0),val(7,1),val(1,0)],

        [val(1,0),val(3,0),val(6,0),  val(7,0),val(2,1),val(4,0),  val(9,0),val(8,0),val(5,1)],
        [val(2,0),val(7,1),val(5,0),  val(9,0),val(8,1),val(1,0),  val(4,0),val(6,1),val(3,0)],
        [val(8,0),val(9,0),val(4,1),  val(5,0),val(3,0),val(6,0),  val(1,0),val(2,0),val(7,0)],

        [val(3,0),val(8,1),val(7,0),  val(2,0),val(1,0),val(5,1),  val(6,0),val(4,0),val(9,0)],
        [val(6,0),val(1,0),val(2,1),  val(4,1),val(9,0),val(7,0),  val(5,0),val(3,1),val(8,0)],
        [val(5,1),val(4,0),val(9,0),  val(8,0),val(6,1),val(3,0),  val(7,1),val(1,0),val(2,1)],
    ],

    // Puzzle 198 of 200
    [
        [val(6,1),val(3,0),val(1,1),  val(9,0),val(7,1),val(8,0),  val(5,0),val(2,0),val(4,0)],
        [val(8,0),val(7,0),val(5,0),  val(1,0),val(2,0),val(4,0),  val(6,0),val(3,0),val(9,1)],
        [val(2,0),val(4,0),val(9,0),  val(5,0),val(3,0),val(6,1),  val(7,0),val(1,0),val(8,0)],

        [val(5,1),val(1,0),val(8,0),  val(6,0),val(4,1),val(2,1),  val(3,0),val(9,0),val(7,0)],
        [val(3,0),val(9,1),val(4,0),  val(7,1),val(5,0),val(1,0),  val(8,1),val(6,0),val(2,0)],
        [val(7,0),val(2,1),val(6,1),  val(8,0),val(9,0),val(3,0),  val(4,1),val(5,0),val(1,0)],

        [val(9,1),val(8,0),val(7,1),  val(2,0),val(6,0),val(5,0),  val(1,0),val(4,0),val(3,1)],
        [val(4,0),val(6,0),val(2,0),  val(3,0),val(1,1),val(7,1),  val(9,0),val(8,1),val(5,0)],
        [val(1,0),val(5,1),val(3,1),  val(4,0),val(8,1),val(9,0),  val(2,1),val(7,0),val(6,0)],
    ],

    // Puzzle 199 of 200
    [
        [val(7,1),val(3,0),val(4,0),  val(1,0),val(2,1),val(8,0),  val(9,0),val(5,0),val(6,0)],
        [val(6,1),val(9,1),val(2,0),  val(5,0),val(4,1),val(3,0),  val(1,0),val(8,1),val(7,1)],
        [val(5,0),val(1,0),val(8,0),  val(7,0),val(9,0),val(6,0),  val(4,0),val(3,0),val(2,0)],

        [val(1,0),val(4,0),val(7,1),  val(8,0),val(5,0),val(2,1),  val(6,1),val(9,0),val(3,1)],
        [val(9,0),val(8,0),val(6,1),  val(3,0),val(1,1),val(4,0),  val(2,1),val(7,0),val(5,0)],
        [val(3,1),val(2,0),val(5,0),  val(6,0),val(7,0),val(9,1),  val(8,0),val(4,1),val(1,0)],

        [val(2,0),val(5,0),val(9,0),  val(4,0),val(3,0),val(1,1),  val(7,1),val(6,0),val(8,0)],
        [val(4,1),val(6,0),val(3,0),  val(2,0),val(8,1),val(7,0),  val(5,0),val(1,1),val(9,1)],
        [val(8,0),val(7,0),val(1,0),  val(9,0),val(6,1),val(5,0),  val(3,0),val(2,0),val(4,1)],
    ],

    // Puzzle 200 of 200
    [
        [val(1,1),val(5,0),val(3,1),  val(9,0),val(4,0),val(7,0),  val(8,0),val(6,0),val(2,0)],
        [val(6,0),val(4,0),val(7,0),  val(5,1),val(8,1),val(2,0),  val(3,0),val(1,0),val(9,0)],
        [val(9,0),val(8,0),val(2,1),  val(6,0),val(1,0),val(3,0),  val(4,0),val(7,0),val(5,0)],

        [val(5,1),val(9,0),val(8,0),  val(2,1),val(6,0),val(1,1),  val(7,0),val(3,1),val(4,1)],
        [val(7,1),val(6,1),val(4,0),  val(3,0),val(5,0),val(8,0),  val(9,0),val(2,1),val(1,0)],
        [val(3,0),val(2,0),val(1,0),  val(4,0),val(7,0),val(9,1),  val(6,1),val(5,0),val(8,0)],

        [val(2,0),val(3,1),val(5,0),  val(7,1),val(9,0),val(4,0),  val(1,0),val(8,1),val(6,0)],
        [val(8,1),val(7,0),val(9,0),  val(1,0),val(2,0),val(6,1),  val(5,1),val(4,0),val(3,0)],
        [val(4,1),val(1,0),val(6,0),  val(8,0),val(3,0),val(5,1),  val(2,0),val(9,0),val(7,0)],
    ],

];
