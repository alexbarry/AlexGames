
use std::collections::{HashSet, HashMap};

use crate::sudoku::sudoku_core::{self, State, Pt};



//fn get_pts_row(state: &State, y: i32) -> impl Iterator<Item = Pt> {
fn get_pts_row(state: &State, y: i32) -> Vec<Pt> {
	let size = state.size as i32;
	(0..size).map(move |x| Pt { y: y, x: x })
		.collect()
}

//fn get_pts_col(state: &State, x: i32) -> impl Iterator<Item = Pt> {
fn get_pts_col(state: &State, x: i32) -> Vec<Pt> {
	let size = state.size as i32;
	(0..size).map(move |y| Pt { y: y, x: x })
		.collect()
}

//fn get_pts_box(state: &State, pt: &Pt) -> impl Iterator<Item = Pt> {
fn get_pts_box(state: &State, pt: &Pt) -> Vec<Pt> {
	let pt = state.box_start_pt(pt);
	let box_size = state.box_size as i32;
	let y = pt.y;
	let x = pt.x;
	(0..box_size).flat_map(move |dy| 
		(0..box_size)
			.map(move |dx| Pt { y: y + dy, x: x + dx })
	)
		.collect()
}

//fn get_pts_box_from_id(state: &State, box_id: i32) -> impl Iterator<Item = Pt> {
fn get_pts_box_from_id(state: &State, box_id: i32) -> Vec<Pt> {
	let pt = state.box_start_pt_from_id(box_id);
	let box_size = state.box_size as i32;
	let y = pt.y;
	let x = pt.x;
	(0..box_size).flat_map(move |dy| 
		(0..box_size)
			.map(move |dx| Pt { y: y + dy, x: x + dx })
	)
	.collect()
}

//fn get_other_pts_in_row_col_box(state: &State, pt: &Pt) -> impl Iterator<Item = Pt> {
fn get_other_pts_in_row_col_box(state: &State, pt: &Pt) -> Vec<Pt> {
	let pt = pt.clone();
	get_pts_row(state, pt.y).into_iter()
		.chain(get_pts_col(state, pt.x))
		.chain(get_pts_box(state, &pt))
		.filter(move |pt2| *pt2 != pt)
		.collect()
}

fn get_other_vals_in_row_col_box(state: &State, pt: &Pt) -> HashSet<i8> {
	let mut vals: HashSet<i8> = HashSet::new();
	for pt in get_other_pts_in_row_col_box(state, pt) {
		let val = state.cell_val(pt.y, pt.x);
		if val != 0 {
			vals.insert(val);
		}
	}
	return vals;
}

///
/// ```
/// use alexgames_rust::sudoku::sudoku_core::{self, State, Pt};
/// use alexgames_rust::sudoku::sudoku_solve::pt_can_be_val;
/// 
/// let mut state = State::new(9);
/// state.board = vec![
///     vec![9,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
/// ];
/// assert_eq!(pt_can_be_val(&state, &Pt{ y: 3, x: 0}, 9), false);
/// ```
pub fn pt_can_be_val(state: &State, pt: &Pt, val: i8) -> bool {
	// println!("other_vals: {:?}, val: {:?}", get_other_vals_in_row_col_box(state, pt), val);
	if state.cell_val(pt.y, pt.x) != 0 {
		return false;
	}

	!get_other_vals_in_row_col_box(state, pt).contains(&val)
}

fn get_all_empty_pts(state: &State) -> Vec<Pt> {
	let size = state.size;
	(0..size).flat_map(|y| 
		(0..size).map(move |x| Pt { y: y as i32, x: x as i32})
	)
		.filter(|pt| state.cell_val(pt.y, pt.x) == 0)
		.collect()
}

fn check_valid_sudoku(state: &State) -> bool {
	let checks: Vec<(&str, fn(&State, i32) -> Vec<Pt>)>  = vec![
	//let checks = vec![
		("row", get_pts_row),
		("col", get_pts_col),
		("box", get_pts_box_from_id),
	];
	
	for (label, get_pts_func) in checks {
		for i in 0..(state.size as i8) {
			let vals: Vec<i8> =
				get_pts_func(&state, i as i32)
					.into_iter()
					.map(|pt| state.cell_val(pt.y, pt.x))
					.filter(|val| *val != 0)
					.collect();
			//let distinct_vals: HashSet<i8> = vals.clone().into_iter().collect();
			let mut counts = HashMap::new();
			for val in vals {
				*counts.entry(val).or_insert(0) += 1;
				if *counts.get(&val).unwrap() > 1 {
					//state.print();
					//println!("{} {} contains duplicate values {}", label, i, val);
					return false;
				}
			}
		}
	}

	return true;
}

fn get_possible_values(state: &State, pt: &Pt) -> Vec<i8> {
	let size = state.size as i8;
	let pts: Vec<Pt> = get_other_pts_in_row_col_box(&state, pt);
	let vals_present: HashSet<i8> = pts.iter().copied()
			.map(|pt| state.cell_val(pt.y, pt.x))
			.filter(|val| *val != 0)
			.collect();
	let remaining_vals: Vec<i8> = (1i8..=size).filter(|val| !vals_present.contains(&val)).collect();
	
	remaining_vals
}


fn find_init_possibs(state: &State) -> HashMap<Pt, Vec<i8>> {
	get_all_empty_pts(state)
		.into_iter()
		.map(|pt| (pt, get_possible_values(state, &pt)))
		.collect()
}


/// Checks if a cell is the only one within
/// its group that can take on a value, due to
/// all possibilities from another group ruling it out.
///
/// ```
/// use alexgames_rust::sudoku::sudoku_core::{self, State, Pt};
/// use alexgames_rust::sudoku::sudoku_solve::find_moves3a;
/// 
/// let mut activity = false;
/// let mut state = State::new(9);
/// state.board = vec![
///     vec![0,7,4, 1,5,3, 0,9,6],
///     vec![5,0,0, 4,6,0, 1,0,0],
///     vec![0,1,6, 0,2,0, 0,4,5],
///     //              ^
///     // One of the above cells must be a 7
///     // within this box.
///     
///     // (Note there is already a 7 here)
///     //          v
///     vec![0,0,0, 7,1,5, 4,6,8],
///     vec![1,0,7, 6,0,0, 0,5,0],
///     vec![6,0,0, 0,0,0, 0,1,0],
///     
///     // Therefore this val is the only cell 
///     // that can be a 7 in the below box.
///     //            V
///     vec![0,6,0, 0,0,0, 5,0,9],
///     vec![4,9,0, 5,8,6, 0,0,1],
///     vec![0,0,0, 2,9,0, 6,8,4],
/// ];
/// assert_eq!(find_moves3a(&state, None, &mut activity), vec![(Pt{y:6, x:4}, 7)]);
/// 
/// state.board = vec![
///     vec![9,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
/// ];
/// assert_eq!(find_moves3a(&state, None, &mut activity), vec![]);
/// ```
pub fn find_moves3a(state: &State, possibs: Option<&mut HashMap<Pt, Vec<i8>>>, activity: &mut bool) -> Vec<(Pt, i8)> {
	*activity = false;
	// find all remaining possible values that a cell can be.
	// Then look for cases where a value must fall within
	// cells in the same row/col/(maybe box), then remove that
	// possibility from other cells.
	// Then fill in any that are the only cell 

	// Second attempt at figuring this out:
	// * when checking if another cell in the row/col has
	//   a value, also check if the only place that box's
	//   value may go is within that row/col. Does that generalize
	//   for other groups?

	let possibs = if possibs.is_none() {
		&mut find_init_possibs(&state)
	} else {
		possibs.unwrap()
	};
	let size = state.size as i8;

	//println!("possibs before: (6,4){:?}", possibs[&Pt {y: 6, x: 4}]);
	//println!("possibs before: (6,5){:?}", possibs[&Pt {y: 6, x: 5}]);

	// find cases where all possibilities for a val are in the same col/row within a box
	// then remove that possibility from other boxes in the same col/row
	//
	// for each box, check if all possibilities are within a single row or col
	//  if found, remove those possibilities from the rest of the board.
	//  Then make any moves where only one possibility remains in a cell,
	//  or where the cell is the only one within that group that can
	//  be that val.

	// TODO For now just check the box, but I think this can be made generic?
	for box_id in 0..size {
		let box_id = box_id as i32;
		let box_start = state.box_start_pt_from_id(box_id.into());
		for y in box_start.y..(box_start.y + (state.box_size as i32)) {
			let other_rows_possibs: HashSet<i8> =
				get_pts_box_from_id(state, box_id)
					.into_iter()
					.filter(|pt| pt.y != y)
					.flat_map(|pt| possibs.get(&pt).unwrap_or(&Vec::new()).clone())
					.collect();
			let this_row_possibs: HashSet<i8> = 
				get_pts_box_from_id(state, box_id)
					.into_iter()
					.filter(|pt| pt.y == y)
					.flat_map(|pt| possibs.get(&pt).unwrap_or(&Vec::new()).clone())
					.collect();

			let only_this_col = this_row_possibs.difference(&other_rows_possibs);

			for val in only_this_col {
				let this_row_pts_in_other_boxes =
					get_pts_row(state, y.into())
						.into_iter()
						.filter(|pt| state.box_id(pt) != box_id);
				for pt in this_row_pts_in_other_boxes {
					if let Some(possibs) = possibs.get_mut(&pt) {
						let old_len = possibs.len();
						possibs.retain(|possib_val| possib_val != val);
						if old_len > possibs.len() {
							*activity = true;
						}
					}
				}
			}
		}

		// TODO do x too, same thing
		//for x in box_start.x..(box_start.x + state.box_size) {
		//}
	}

	for box_id in 0..size {
		let box_id = box_id as i32;
		let box_start = state.box_start_pt_from_id(box_id.into());
		for x in box_start.x..(box_start.x + (state.box_size as i32)) {
			let other_cols_possibs: HashSet<i8> =
				get_pts_box_from_id(state, box_id)
					.into_iter()
					.filter(|pt| pt.x != x)
					.flat_map(|pt| possibs.get(&pt).unwrap_or(&Vec::new()).clone())
					.collect();
			let this_col_possibs: HashSet<i8> = 
				get_pts_box_from_id(state, box_id)
					.into_iter()
					.filter(|pt| pt.x == x)
					.flat_map(|pt| possibs.get(&pt).unwrap_or(&Vec::new()).clone())
					.collect();

			let only_this_col = this_col_possibs.difference(&other_cols_possibs);

			for val in only_this_col {
				let this_col_pts_in_other_boxes =
					get_pts_col(state, x.into())
						.into_iter()
						.filter(|pt| state.box_id(pt) != box_id);
				for pt in this_col_pts_in_other_boxes {
					if let Some(possibs) = possibs.get_mut(&pt) {
						possibs.retain(|possib_val| possib_val != val);
					}
				}
			}
		}
	}
	//assert_eq!(find_moves1_from_possibs(possibs).len(), 0);
	let mut moves1 = find_moves1_from_possibs(possibs);
	// TODO don't call this here, call outside this function.
	moves1.append(&mut
	find_moves2_from_possibs(state, possibs)
	);
	moves1
}

type GetPtsFunc = fn(&State, i32) -> Vec<Pt>;

fn get_counts(state: &State, possibs: &HashMap<Pt, Vec<i8>>, get_pts_func: GetPtsFunc, group_id: i8) -> HashMap<i8, i8> {
	get_pts_func(state, group_id.into())
		.iter()
		.map(|pt| possibs.get(&pt).unwrap_or(&Vec::new()).clone())
		.flatten()
	    .fold(HashMap::new(), |mut acc, val| {
			*acc.entry(val).or_insert(0) += 1;
			acc
		})
}

fn get_row_id(_state: &State, pt: &Pt) -> i8 {
	pt.y as i8
}
fn get_col_id(_state: &State, pt: &Pt) -> i8 {
	pt.x as i8
}
fn get_box_id(state: &State, pt: &Pt) -> i8 {
	state.box_id(pt) as i8
}

/// If there are two vals within a group that can only fall within two cells,
/// then remove all other possibilities from those cells.
/// This may narrow down the number of possibilities enough to result in a move.
/// ```
/// use alexgames_rust::sudoku::sudoku_core::{self, State, Pt};
/// use alexgames_rust::sudoku::sudoku_solve::update_possibs_3b;
/// use std::collections::HashMap;
/// 
/// let state = State::new(9);
/// let mut possibs = HashMap::from([
///     // these two cells within the box are the only ones that can be a 2 or 3
/// 	(Pt{ y: 1, x: 0}, vec![2,3,4]),
/// 	(Pt{ y: 1, x: 1}, vec![2,3]),
/// 	(Pt{ y: 1, x: 3}, vec![3,4]),
/// 	(Pt{ y: 1, x: 8}, vec![2,8]),
/// ]);
/// let expected_possibs = HashMap::from([
/// 	(Pt{ y: 1, x: 0}, vec![2,3,4]), // TODO removes other possibility (4) from these two cells?
/// 	(Pt{ y: 1, x: 1}, vec![2,3]),
/// 	(Pt{ y: 1, x: 3}, vec![4]), // can't be a 3
/// 	(Pt{ y: 1, x: 8}, vec![8]), // can't be a 2
/// ]);

/// let activity = update_possibs_3b(&state, &mut possibs, true);
/// assert_eq!(possibs, expected_possibs);
/// assert_eq!(activity, true);
/// ```
pub fn update_possibs_3b(state: &State, possibs: &mut HashMap<Pt, Vec<i8>>, debug: bool) -> bool {
	let mut activity = false;
	let size = state.size as i8;

	let get_pts_funcs: Vec<(&str, fn(&State, i32) -> Vec<Pt>, fn(&State, &Pt) -> i8)>  = vec![
		("row", get_pts_row, get_row_id),
		("col", get_pts_col, get_col_id),
		("box", get_pts_box_from_id, get_box_id),
	];

	for (label, get_pts_func, _get_group_id_func) in &get_pts_funcs {
		for group_id in 0..size {
			//let counts = get_counts(state, possibs, get_pts_func, group_id);
			//for (val, count) in counts {
			//}

			// TODO: find 2 values that can only occur in 2 cells, and remove all other possibilities from those cells.
			// Maybe generalize this to more than 2.
			// How to compute that?
			// Either:
			//  * (skip to next one) find all vals with count 2, check if any of them occur within the same 2 points?
			//  * get all points that a vals occur within this group, find any that are
			//    equal? This generalizes to any number of vals/cells.
			let pts_by_val: HashMap<i8,HashSet<Pt>> = (0..size).map(|val| {
									(val, get_pts_func(state, group_id.into())
										.into_iter()
										.filter(|pt| possibs.get(&pt)
														.unwrap_or(&Vec::new())
														.contains(&val))
										.collect::<HashSet<_>>())
								})
								//.filter(|(val, pts)| pts.len() > 0)
								.collect();
			if debug {
				//println!("update_possibs_3b, {} {}: pts_by_val: {:?}", label, group_id, pts_by_val);
				println!("update_possibs_3b, {} {}: pts_by_val: {:?}", label, group_id, pts_by_val.iter().filter(|(val,pts)| pts.len() > 0).collect::<HashMap<_,_>>());
			}
			for (val1, pts1) in pts_by_val.iter() {
				let val1 = *val1;
				// TODO generalize this for val3, val4, etc...
				for val2 in 1i8..val1 {
					let pts2 = &pts_by_val[&val2];
					// TODO generalize this for pts2.len() > 2
					if pts1 == pts2 && pts1.len() == 2 {
						let pts = pts1;
						if debug {
							println!("update_possibs_3b found that {} and {} have same pts", val1, val2);
							// if they fall in the same row/col within this box, 
							// then remove the possibilities from the rest of the row/col?
							// TODO does this generalize?
						}
						//assert!(false);
						for (label2, get_pts_func2, get_group_id_func2) in &get_pts_funcs {
							if get_pts_func2 == get_pts_func {
								continue;
							}
							// if all the points are within the same group,
							// then remove these possibilities from the 
							// others cells within this group.
							let pts_within_group2 = pts.into_iter().map(|pt|get_group_id_func2(state, pt)).collect::<HashSet<_>>().len() == 1;
							let group2_id = get_group_id_func2(state, pts.iter().next().unwrap());
							//println!("update_possibs_3b {} {} within same {}: {} {}", val1, val2, label2, pts_within_group2, group2_id);
							if pts_within_group2 {
								for pt in get_pts_func2(state, group2_id.into()) {
									//println!("checking pt {:?}", pt);
									if pts.contains(&pt) {
										//println!("checking pt {:?}; pts.contains(pt!)", pt);
										continue;
									}
									//println!("possibs: {:?}", possibs);
									//println!("checking pt {:?};, about to call possibs.get_mut()", pt);
									if let Some(possibs) = possibs.get_mut(&pt) {
										//println!("checking if {:?} possibs {:?} contain val {} or {}", pt, possibs, val1, val2);
										if possibs.contains(&val1) {
											//println!("found that {:?} can not be a {} because there are already 2 other cells ({:?})  with the same 2 possible values, one of them must be it", pt, val1, pts1);
											possibs.retain(|val| *val != val1);
											activity = true;
										}
										if possibs.contains(&val2) {
											//println!("found that {:?} can not be a {} because there are already 2 other cells ({:?}) with the same 2 possible values, one of them must be it", pt, val2, pts2);
											possibs.retain(|val| *val != val2);
											activity = true;
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	activity
}

fn find_moves1_from_possibs(possibs: &HashMap<Pt, Vec<i8>>) -> Vec<(Pt, i8)> {
	possibs.iter().filter(|(_, &ref v)| v.len() == 1).map(|(&k, v)| (k, v[0])).collect()
}

// TODO refactor find_moves2 to use this instead
fn find_moves2_from_possibs(state: &State, possibs: &HashMap<Pt, Vec<i8>>) -> Vec<(Pt, i8)> {
	let size = state.size as i8;

	let mut game_moves: Vec<(Pt, i8)> = Vec::new();

	let get_pts_funcs: Vec<(&str, fn(&State, i32) -> Vec<Pt>)>  = vec![
	//let checks = vec![
		("row", get_pts_row),
		("col", get_pts_col),
		("box", get_pts_box_from_id),
	];

	for (label, get_pts_func) in get_pts_funcs {
	for group_id in 0..size {
		// Gets count of all possibilities within a box
		let counts = get_pts_func(state, group_id.into())
		             	.iter()
						.map(|pt| possibs.get(&pt).unwrap_or(&Vec::new()).clone())
		             	.flatten()
		             	.fold(HashMap::new(), |mut acc, val| {
							*acc.entry(val).or_insert(0) += 1;
							acc
						});
		for only_one_possib in counts.iter().filter(|(_, &v)| v == 1).map(|(&k, _)|k) {
			for pt in get_pts_func(state, group_id.into()) {
				if possibs.get(&pt).unwrap_or(&Vec::new()).iter().any(|val| *val == only_one_possib) {
					game_moves.push( (pt.clone(), only_one_possib));
				}
			}
		}
	}
	}
	game_moves
}



#[derive(Debug)]
pub struct Stats {
	guess_count: u32,
	wrong_guess_count: u32,

	valid_solution_count: Option<i32>,
}

impl Stats {
	pub fn new() -> Self {
		Self {
			guess_count: 0,
			wrong_guess_count: 0,

			valid_solution_count: None,
		}
	}
}
/// Checks if a cell is the only empty one within a group (box/row/col).
///
/// ```
/// use alexgames_rust::sudoku::sudoku_core::{self, State, Pt};
/// use alexgames_rust::sudoku::sudoku_solve::find_moves1;
/// 
/// let mut state = State::new(9);
/// state.board = vec![
///     vec![0,0,0, 1,0,0, 0,0,0],
///     vec![0,0,0, 2,0,0, 0,0,0],
///     vec![0,0,0, 3,0,0, 0,0,0],
///
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 5,0,0, 0,0,0],
///     vec![0,0,0, 6,0,0, 0,0,0],
///
///     vec![0,0,0, 7,0,0, 0,0,0],
///     vec![0,0,0, 8,0,0, 0,0,0],
///     vec![0,0,0, 9,0,0, 0,0,0],
/// ];
/// assert_eq!(find_moves1(&state, true), vec![(Pt{y: 3, x: 3}, 4)]);
///
/// state.board = vec![
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///
///     vec![0,0,0, 1,2,3, 0,0,0],
///     vec![0,0,0, 0,5,6, 0,0,0],
///     vec![0,0,0, 7,8,4, 0,0,0],
///
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
/// ];
/// assert_eq!(find_moves1(&state, true), vec![(Pt{y: 4, x: 3}, 9)]);
///
/// state.board = vec![
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![1,2,4, 0,5,6, 7,8,9],
///     vec![0,0,0, 0,0,0, 0,0,0],
///
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
/// ];
/// assert_eq!(find_moves1(&state, true), vec![(Pt{y: 4, x: 3}, 3)]);
/// ```
pub fn find_moves1(state: &State, debug: bool) -> Vec<(Pt, i8)> {
	let mut game_moves: Vec<(Pt, i8)> = Vec::new();
	for y in (0..state.size) {
		for x in (0..state.size) {
			let pt = Pt { y: y as i32, x: x as i32 };
			if state.cell_val(pt.y, pt.x) != 0 {
				continue;
			}
			let existing_vals = get_other_vals_in_row_col_box(&state, &pt);
			if existing_vals.len() == state.size - 1 {
				let remaining_vals: Vec<i8> = (1i8..=(state.size as i8)).filter(|val| !existing_vals.contains(val)).collect();
				assert!(remaining_vals.len() == 1);
				if debug {
					println!("y: {}, x: {} can only be one value; {:?} since others are filled in", y, x, remaining_vals);
				}
				game_moves.push( (pt.clone(), remaining_vals[0]));
			}
		}
	}
	game_moves
}

/// Checks if a cell is the only one within a group (box/row/col)
/// that can take on a value.
///
/// ```
/// use alexgames_rust::sudoku::sudoku_core::{self, State, Pt};
/// use alexgames_rust::sudoku::sudoku_solve::find_moves2;
/// 
/// let mut state = State::new(9);
/// state.board = vec![
///     vec![0,0,0, 3,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///
///     vec![0,0,0, 0,0,3, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,0],
///
///     vec![0,0,0, 0,0,0, 0,0,0],
///     vec![3,0,0, 0,0,0, 0,0,0],
///     vec![0,0,0, 0,0,0, 0,0,3],
/// ];
/// assert_eq!(find_moves2(&state, true), vec![(Pt{y: 6, x: 4}, 3)]);
/// ```
pub fn find_moves2(state: &State, debug: bool) -> Vec<(Pt, i8)> {
	let mut game_moves: Vec<(Pt, i8)> = Vec::new();
	let size = state.size as i8;

	//let checks = vec![
	let checks: Vec<(&str, fn(&State, i32) -> Vec<Pt>)>  = vec![
		( "row", get_pts_row ),
		( "col", get_pts_col ),
		( "box", get_pts_box_from_id ),
	];
	
	// TODO I think I made a mess of this at some point.
	// `pt_can_be_val` iterates through every row/box/col, so I'm not sure if I also
	// need to iterate through each of those in this function.
	for (label, get_pts_func) in checks {
		for i in 0..size {
			//println!("checking {} {}", label, i);
			let pts: Vec<Pt> = get_pts_func(&state, i as i32); //.collect();
			let vals_present: HashSet<i8> = pts.iter().copied()
				.map(|pt| state.cell_val(pt.y, pt.x))
				.filter(|val| *val != 0)
				.collect();
			let remaining_vals = (1..=size).filter(|val| !vals_present.contains(&val));
			for val in remaining_vals {
				let pts_can_be_val: Vec<Pt> = pts.iter().copied().filter(|pt| pt_can_be_val(&state, pt, val)).collect();
				if pts_can_be_val.len() == 1 {
					let pt = pts_can_be_val[0];
					if debug {
						println!("y: {}, x: {} is only one in this row/col/box that can take value {}", pt.y, pt.x, val);
					}
					game_moves.push((pt.clone(), val));
				}
			}
		}
	}

	game_moves
		.into_iter()
		.collect::<HashSet<_>>()
		.into_iter()
		.collect::<Vec<_>>()
}

fn find_min_possib_pt(state: &State) -> Option<(Pt, Vec<i8>)> {
	let mut min_possibs: Option<Vec<i8>> = None;
	let mut min_possibs_pt: Option<Pt> = None;

	let size = state.size as i8;

	for pt in get_all_empty_pts(&state) {
		// TODO should also use logic implemented in find_moves3a to find the best guess
		let pts: Vec<Pt> = get_other_pts_in_row_col_box(&state, &pt);
		let vals_present: HashSet<i8> = pts.iter().copied()
			.map(|pt| state.cell_val(pt.y, pt.x))
			.filter(|val| *val != 0)
			.collect();
		let remaining_vals: Vec<i8> = (1i8..=size).filter(|val| !vals_present.contains(&val)).collect();

		if min_possibs.clone().is_none_or(|val| remaining_vals.len() < val.len()) {
			min_possibs = Some(remaining_vals);
			min_possibs_pt = Some(pt);
		}
	}

	if min_possibs.is_some() {
		return Some((min_possibs_pt.unwrap(), min_possibs.unwrap()))
	} else {
		return None
	}
}

pub struct Params {
	pub debug: bool,
	pub find_all_valid_solutions: bool,
	pub guessing_allowed: bool,
}

impl Params {
	pub fn new() -> Self {
		Self {
			debug: false,
			find_all_valid_solutions: false,
			guessing_allowed: false,
		}
	}
}

pub fn solve(state: &State, depth: i32, stats: &mut Stats, params: &Params) -> bool {
	if params.debug {
		println!("##############");
		println!("#### solve (depth: {})", depth);
		println!("##############");
	}

	let mut state = state.clone();
	let mut activity = true;

	let apply_move = |state: &mut State, pt: &Pt, val: &i8, depth: i32| {
		assert!(state.cell_val(pt.y, pt.x) == 0 || state.cell_val(pt.y, pt.x) == *val);
		state.board[pt.y as usize][pt.x as usize] = *val;
	};

	while activity {
		activity = false;
		let mut game_moves: Vec<(Pt, i8)> = Vec::new();
		if params.debug {
			state.print();
		}

		{
			let mut game_moves1 = find_moves1(&state, params.debug);
			if game_moves1.len() > 0 {
				game_moves.append(&mut game_moves1);
				activity = true;
			}
		}

		if !activity {
			let mut game_moves2 = find_moves2(&state, params.debug);
			if game_moves2.len() > 0 {
				game_moves.append(&mut game_moves2);
				activity = true;
			}
		}



		if !activity {
			let mut possibs = find_init_possibs(&state);

			let mut activity_a = true;
			let mut activity_b = true;
			while activity_a || activity_b {
				//println!("trying findmoves 3a...");
				activity_a = false;
				activity_b = false;

				let mut game_moves3a = find_moves3a(&state, Some(&mut possibs), &mut activity_a);
				if game_moves3a.len() > 0 {
					//println!("Found {} game_moves from logic 3a", game_moves3a.len());
					//activity = true;
					//game_moves.append(&mut game_moves3a);
				}

				activity_b = update_possibs_3b(&state, &mut possibs, params.debug);
				//println!("activity_a {} activity_b {}", activity_a, activity_b);
			}

			let mut moves3 = find_moves1_from_possibs(&possibs);
			moves3.append(&mut
				find_moves2_from_possibs(&state, &possibs)
			);

			if moves3.len() > 0 {
				game_moves.append(&mut moves3);
				activity = true;
			}
		}

		// Guess if none of the above techniques can reveal any more information
		if !activity && params.guessing_allowed {
			if let Some((min_possibs_pt, min_possibs)) = find_min_possib_pt(&state) {
				if params.debug {
					println!("{} Best guess has {:?} possibilities at pt {:?}", " ".repeat(depth as usize), min_possibs, min_possibs_pt);
				}
				let mut found_valid_solution = false;
				for possib in min_possibs {
					let mut new_state = state.clone();
					for (pt, val) in game_moves.iter() {
						apply_move(&mut new_state, &pt, &val, depth);
					}
					let pt = min_possibs_pt;
					if params.debug {
						println!("{} Making guess {} at point {:?}", " ".repeat(depth as usize), possib, pt);
					}
					apply_move(&mut new_state, &pt, &possib, depth + 1);

					let solved = solve(&new_state, depth + 1, stats, params);
					if solved {
						if params.debug {
							println!("{} Guess {} at pt {:?} was correct!", " ".repeat(depth as usize), possib, pt);
						}
						stats.guess_count += 1;
						found_valid_solution = true;
						if !params.find_all_valid_solutions {
							return solved;
						} else {
							//if depth == 0 {
								// TODO not sure if this is actually right...
							//	*stats.valid_solution_count.get_or_insert(0) += 1;
							//}
							continue;
						}
					} else {
						stats.wrong_guess_count += 1;
						if params.debug {
							println!("{} Guess {} was wrong, trying next guess", " ".repeat(depth as usize), possib);
						}
					}
				}
				return found_valid_solution;
			}
		}

		for (pt, val) in game_moves.iter() {
			//assert!(state.cell_val(pt.y, pt.x) == 0 || state.cell_val(pt.y, pt.x) == *val);
			if state.cell_val(pt.y, pt.x) != 0 && state.cell_val(pt.y, pt.x) != *val {
				return false;
			}
			assert!(state.cell_val(pt.y, pt.x) == 0 || state.cell_val(pt.y, pt.x) == *val);
			apply_move(&mut state, pt, val, depth);

			if !check_valid_sudoku(&state) {
				return false;
			}
		}

		game_moves.clear();
	}


	if params.debug {
		state.print();
	}

	let solved = get_all_empty_pts(&state).len() == 0;

	solved && check_valid_sudoku(&state)
}
