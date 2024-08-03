use std::collections::HashMap;

use crate::gem_match::gem_match_core::{State, GemType, BOARD_WIDTH, BOARD_HEIGHT, Pt, GemChanges};
use crate::rust_game_api::{CANVAS_HEIGHT, CANVAS_WIDTH, TimeMs};
use crate::rust_game_api;

const CELL_WIDTH:  f64 = (CANVAS_WIDTH as f64) / (BOARD_WIDTH as f64);
const CELL_HEIGHT: f64 = (CANVAS_HEIGHT as f64) / (BOARD_HEIGHT as f64);

pub const FPS: i32 = 60;

pub struct GemMatchDraw {
	//gem_pos_adjustments_by_pos: HashMap<Pt, Vec<GemAnimation>>,

	animation_queue: Vec<StateAnimation>,

	callbacks: &'static rust_game_api::CCallbacksPtr,
}

pub fn cell_size() -> f64 {
	f64::min(CELL_WIDTH, CELL_HEIGHT)
}

fn progress_fn_smoothstep(x: f64) -> f64 {
	3.0*x*x - 2.0*x*x
}

struct StateAnimation {
	label: String,
	state: State,
	gem_pos_adjustments_by_pos: HashMap<Pt, Vec<GemAnimation>>,
}

impl StateAnimation {
	fn new(label: &str, state: State) -> StateAnimation {
		let mut state_animation = StateAnimation {
			label: label.to_string(),
			state: state,
			gem_pos_adjustments_by_pos: HashMap::new(),
		};
		for y in 0..BOARD_HEIGHT {
			for x in 0..BOARD_WIDTH {
				let pt = Pt{y: y as i32, x: x as i32};
				state_animation.gem_pos_adjustments_by_pos.insert(pt, Vec::new());
			}
		}
		state_animation
	}


	// TODO move the time params to StateAnimation, not each individual gem
	fn is_current(&self, time_ms: TimeMs) -> bool {
		for y in 0..BOARD_HEIGHT {
			for x in 0..BOARD_WIDTH {
				let pt = Pt{y: y as i32, x: x as i32};
				let adjustment_vec = self.gem_pos_adjustments_by_pos.get(&pt).expect("empty?");
				for adjustment in adjustment_vec.iter() {
					//if let Some(adjustment) = adjustment {
						if adjustment.is_current(time_ms) {
							return true;
						}
					//}
				}
			}
		}
		return false;
	}

	fn add_animation(&mut self, anim: GemAnimation) {
		self.gem_pos_adjustments_by_pos.get_mut(&anim.src_cell).expect("empty?").push(anim);
	}

}

#[derive(Debug)]
struct GemAnimation {
	//id: i32,

	src_cell: Pt,
	dst_cell: Option<Pt>,
	init_offset: Option<Pt>,
	progress: f64,
	progress_fn: fn(f64) -> f64,
	total_time_ms: TimeMs,
	start_time_ms: TimeMs,
}

impl GemAnimation {
	fn is_current(&self, time_ms: TimeMs) -> bool {
		return self.start_time_ms <= time_ms &&
		       time_ms < self.start_time_ms + self.total_time_ms;
	}
}

impl GemMatchDraw {

	pub fn new(callbacks: &'static rust_game_api::CCallbacksPtr) -> GemMatchDraw {
		let draw = GemMatchDraw {
			callbacks: callbacks,
			animation_queue: Vec::<StateAnimation>::new(),
			//gem_pos_adjustments_by_pos: HashMap::new(),
			//gem_pos_adjustments: Vec::new(),
		};


		draw
	}

pub fn is_animating(&self) -> bool {
	self.animation_queue.len() > 0
}

fn draw_gem(&self, gem_type: GemType, circ_y: i32, circ_x: i32, alpha: f64, piece_radius: i32) {
	let piece_outline_width = 2;
	let user_colour_pref: &str = &self.callbacks.get_user_colour_pref();

	let is_dark_mode = match user_colour_pref {
		"light"            => false,
		"dark"|"very_dark" => true,
		_ => false,
	};
	let (colour, outline_colour) = match gem_type {
		GemType::SAPPHIRE => match is_dark_mode { false => ("#0f52ba", "#000088" ), true => ("#0f228a", "#000058" ), },
		//GemType::EMERALD  => ("#50c878", "#008800" ),
		GemType::EMERALD  => match is_dark_mode { false => ("#30c858", "#008800" ), true => ("#009828", "#005800" ), },
		GemType::RUBY     => match is_dark_mode { false => ("#9b111e", "#440000" ), true => ("#6b010e", "#140000" ), },
		GemType::AMETHYST => match is_dark_mode { false => ("#9966cc", "#440044" ), true => ("#69369c", "#140014" ), },
		GemType::TOPAZ    => match is_dark_mode { false => ("#ffd700", "#888866" ), true => ("#af7700", "#585866" ), },
		//GemType::AMBER    => ("#ff8800", "#442200" ),
	};

	let mut colour = colour.to_owned();
	colour.push_str(&format!("{:02x}", (alpha*0xff as f64) as i32));

	let mut outline_colour = outline_colour.to_owned();
	outline_colour.push_str(&format!("{:02x}", (alpha*0xff as f64) as i32));

	let circ_y = circ_y as i32;
	let circ_x = circ_x as i32;

	let y1 = circ_y - piece_radius;
	let y2 = circ_y + piece_radius;
	let x1 = circ_x - piece_radius;
	let x2 = circ_x + piece_radius;

	match gem_type {
		GemType::SAPPHIRE => {
			let piece_radius = piece_radius - 5;
			self.callbacks.draw_circle(&colour, &outline_colour,
			                        circ_y as i32, circ_x as i32,
			                        piece_radius, piece_outline_width);
		},
		GemType::EMERALD => {
			let tri_y1 = y1 + 5;
			let tri_x1 = x1 + 5;
			let tri_y2 = y1 + 5;
			let tri_x2 = x2 - 5;
			let tri_y3 = y2 - 5;
			let tri_x3 = circ_x;
			self.callbacks.draw_triangle(&colour,
			                             tri_y1, tri_x1,
			                             tri_y2, tri_x2,
			                             tri_y3, tri_x3);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, tri_y1, tri_x1, tri_y2, tri_x2);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, tri_y1, tri_x1, tri_y3, tri_x3);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, tri_y2, tri_x2, tri_y3, tri_x3);
		},
		GemType::RUBY =>  {
			let y1 = y1 + 5;
			let y2 = y2 - 5;
			let x1 = x1 + 5;
			let x2 = x2 - 5;
			self.callbacks.draw_rect(&colour, y1, x1, y2, x2);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, y1, x1, y1, x2);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, y1, x1, y2, x1);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, y2, x2, y1, x2);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, y2, x2, y2, x1);
		},

		GemType::AMETHYST => {
			let yy1 = y1;
			let xx1 = circ_x;

			let yy2 = circ_y;
			let xx2 = x1;

			let yy3 = y2;
			let xx3 = circ_x;

			let yy4 = circ_y;
			let xx4 = x2;

			let xx2 = xx2 + 10;
			let xx4 = xx4 - 10;

			self.callbacks.draw_triangle(&colour,
			                             yy1, xx1,
			                             yy2, xx2,
			                             circ_y, circ_x);
			self.callbacks.draw_triangle(&colour,
			                             yy2, xx2,
			                             yy3, xx3,
			                             circ_y, circ_x);
			self.callbacks.draw_triangle(&colour,
			                             yy3, xx3,
			                             yy4, xx4,
			                             circ_y, circ_x);
			self.callbacks.draw_triangle(&colour,
			                             yy4, xx4,
			                             yy1, xx1,
			                             circ_y, circ_x);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, yy1, xx1, yy2, xx2);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, yy2, xx2, yy3, xx3);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, yy3, xx3, yy4, xx4);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, yy4, xx4, yy1, xx1);

		},
		GemType::TOPAZ => {
			let yy1 = y1;
			let xx1 = circ_x;

			let yy2 = circ_y;
			let xx2 = x1;

			let yy3 = y2;
			let xx3 = circ_x;

			let yy4 = circ_y;
			let xx4 = x2;

			self.callbacks.draw_triangle(&colour,
			                             yy1, xx1,
			                             yy2, xx2,
			                             circ_y, circ_x);
			self.callbacks.draw_triangle(&colour,
			                             yy2, xx2,
			                             yy3, xx3,
			                             circ_y, circ_x);
			self.callbacks.draw_triangle(&colour,
			                             yy3, xx3,
			                             yy4, xx4,
			                             circ_y, circ_x);
			self.callbacks.draw_triangle(&colour,
			                             yy4, xx4,
			                             yy1, xx1,
			                             circ_y, circ_x);

			self.callbacks.draw_line(&outline_colour, piece_outline_width, yy1, xx1, yy2, xx2);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, yy2, xx2, yy3, xx3);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, yy3, xx3, yy4, xx4);
			self.callbacks.draw_line(&outline_colour, piece_outline_width, yy4, xx4, yy1, xx1);


		}
	};
	       		                    

}

pub fn draw_state(&self, latest_state: &State) {
	self.callbacks.draw_clear();
	let padding = 1.0;
	let piece_radius = (cell_size()/2.0 - padding) as i32;
	let state;
	let gem_pos_adjustments_by_pos;
	if let Some(anim_state) = self.animation_queue.first() {
		state = &anim_state.state;
		gem_pos_adjustments_by_pos = Some(&anim_state.gem_pos_adjustments_by_pos);
		println!("drawing anim {}", anim_state.label);
	} else {
		state = latest_state;
		gem_pos_adjustments_by_pos = None;
		//println!("drawing no anim");
	}
	for (y, row) in state.board.iter().enumerate() {
		for (x, cell) in row.iter().enumerate() {
			let cell = match cell {
				Some(cell) => cell,
				None => {
					continue;
				},
			};
			let pt = Pt{y: y as i32, x: x as i32};
			let y = y as f64;
			let x = x as f64;

			let mut circ_y = (y+0.5)*CELL_HEIGHT;
			let mut circ_x = (x+0.5)*CELL_WIDTH;
			let mut alpha  = 1.0;

			let time_ms = self.callbacks.get_time_ms();
			//let adjustments = self.gem_pos_adjustments_by_pos.get(&pt).unwrap();
			let empty_vec = Vec::new();
			let adjustments;
			if let Some(ref gem_pos_adjustments_by_pos) = gem_pos_adjustments_by_pos {
				adjustments = gem_pos_adjustments_by_pos.get(&pt).unwrap();
			} else {
				adjustments = &empty_vec;
			}
			for adjustment in adjustments {
				if !adjustment.is_current(time_ms) {
					continue;
				}
				let offset;
				if let Some(offset_val) = adjustment.init_offset {
					offset = Pt{y: offset_val.y as i32, x: offset_val.x as i32};
				} else {
					offset = Pt{y: 0, x: 0};
				}

				let progress = (adjustment.progress_fn)(adjustment.progress);
				//let progress = adjustment.progress;
				let dx;
				let dy;
				if let Some(dst_cell) = adjustment.dst_cell {
					dx = (dst_cell.x as f64 - x - offset.x as f64)*progress;
					dy = (dst_cell.y as f64 - y - offset.y as f64)*progress;
				} else {
					alpha = 1.0 - progress;
					dx = 0.0;
					dy = 0.0;
				}

				let dy = (dy + offset.y as f64) * CELL_HEIGHT;
				let dx = (dx + offset.x as f64) * CELL_WIDTH;
				//println!("anim {}, progress {:.2}, dy={}, dx={}; offset=({}, {})", adjustment.id, progress, dy, dx, offset.y, offset.x);
				circ_y += dy;
				circ_x += dx;
			}

			self.draw_gem(cell.gem_type, circ_y as i32, circ_x as i32, alpha, piece_radius);
		}
	}

	/*
	let matches = state.find_all_three_or_more_in_a_row();
	for match_val in matches {
		let padding = 5.0;
		let y1 = match_val.pt.y as f64 * cell_size() + padding;
		let x1 = match_val.pt.x as f64 * cell_size() + padding;
		// last cell in the match
		let end_pt = match_val.end_pt();
		// cell after the last one
		let end_pt = end_pt.add(match_val.dir);
		// add one cell in the perpendicular direction to make the rectangle have non zero width 
		let end_pt = end_pt.add(match_val.dir.swap());
		let y2 = (end_pt.y as f64 + 0.0) * cell_size() - padding;
		let x2 = (end_pt.x as f64 + 0.0) * cell_size() - padding;
		self.callbacks.draw_rect("#ffffff88", y1 as i32, x1 as i32, y2 as i32, x2 as i32);
		self.callbacks.draw_line("#00ffff", 3, y1 as i32, x1 as i32, y1 as i32, x2 as i32);
		self.callbacks.draw_line("#00ffff", 3, y1 as i32, x1 as i32, y2 as i32, x1 as i32);
		self.callbacks.draw_line("#00ffff", 3, y2 as i32, x2 as i32, y1 as i32, x2 as i32);
		self.callbacks.draw_line("#00ffff", 3, y2 as i32, x2 as i32, y2 as i32, x1 as i32);
	}
	*/

	
	self.callbacks.draw_refresh();
}

pub fn update_animations(&mut self, dt_ms: i32) {
	let time_ms = self.callbacks.get_time_ms();
	while let Some(anim_state) = self.animation_queue.first() {
		if !anim_state.is_current(time_ms) {
			let len = self.animation_queue.len();
			println!("removing non current anim state {} from queue, remaining len is {}", anim_state.label, len-1);
			self.animation_queue.remove(0);
		} else {
			break;
		}
	}

	//for anim in self.gem_pos_adjustments.iter() {
	if let Some(anim_state) = self.animation_queue.first_mut() {
		let mut to_delete = Vec::<Pt>::new();
		//println!("update_animations, time_ms={}", time_ms);
		//println!("checking for animations within current time_ms ({})", time_ms);
		for (pt, anims) in anim_state.gem_pos_adjustments_by_pos.iter_mut() {
			for anim in anims {
				if !anim.is_current(time_ms) {
					continue;
				}
				anim.progress += (dt_ms as f64)/(anim.total_time_ms as f64);
				if anim.progress >= 1.0 {
					anim.progress = 1.0;
					to_delete.push(*pt);
				}
			}
		}
	}
}

pub fn screen_pos_to_cell_pos(&self, pt: Pt) -> Pt {
	let cell_size = cell_size() as i32;
	Pt{
		y: pt.y/cell_size,
		x: pt.x/cell_size,
	}
}


pub fn handle_swipe_bad_move(&mut self, pos: Pt, dir: Pt, state: &State) {
	println!("handle_swipe_bad_move");

	let mut anim_state = StateAnimation::new("anim_bad", *state);

	let swipe_cell = self.screen_pos_to_cell_pos(pos);
	let dst_cell = swipe_cell.add(dir);

	let time_ms = self.callbacks.get_time_ms();
	let anim_duration_ms = 200;

	anim_state.add_animation(GemAnimation{
		//id: 1,
		src_cell: swipe_cell,
		dst_cell: Some(dst_cell),
		init_offset: None,
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms,
		total_time_ms: anim_duration_ms,
	});
	anim_state.add_animation(GemAnimation{
		//id: 2,
		src_cell: dst_cell,
		dst_cell: Some(swipe_cell),
		init_offset: None,
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms,
		total_time_ms: anim_duration_ms,
	});

	anim_state.add_animation(GemAnimation{
		//id: 3,
		src_cell: swipe_cell,
		dst_cell: Some(swipe_cell),
		init_offset: Some(dir.mult(1)),
		//init_offset: None,
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms + anim_duration_ms,
		total_time_ms: anim_duration_ms,
	});
	anim_state.add_animation(GemAnimation{
		//id: 4,
		src_cell: dst_cell,
		dst_cell: Some(dst_cell),
		init_offset: Some(dir.mult(-1)),
		//init_offset: None,
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms + anim_duration_ms,
		total_time_ms: anim_duration_ms,
	});

	self.animation_queue.push(anim_state);

}

pub fn handle_move_updates(&mut self, changes: &GemChanges, prev_state: &State, new_state: &State) {
	println!("handle_move_updates");
	let time_ms = self.callbacks.get_time_ms();

	let start_time_ms = time_ms;

	let move_duration_ms = 200;
	//let move_duration_ms = 750;
	let fade_duration_ms = 200;
	//let fade_duration_ms = 1000;
	let fall_time_ms: TimeMs = 175;
	//let fall_time_ms = 500;
	//let pause_time_ms = 1000;
	let pause_time_ms = 200;

	let time_stay_blank_ms = 5000 + fade_duration_ms; // TODO REMOVE


	let mut anim_state1 = StateAnimation::new("anim1", *prev_state);

	anim_state1.add_animation(GemAnimation{
		//id: 1,
		src_cell: changes.swipe_cell,
		dst_cell: Some(changes.dst_cell),
		init_offset: None,
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms,
		total_time_ms: move_duration_ms,
	});
	anim_state1.add_animation(GemAnimation{
		//id: 2,
		src_cell: changes.dst_cell,
		dst_cell: Some(changes.swipe_cell),
		init_offset: None,
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms,
		total_time_ms: move_duration_ms,
	});

	self.animation_queue.push(anim_state1);
	println!("added swipe anim starting at {}, ending {} later", time_ms - start_time_ms, move_duration_ms);
	let time_ms = time_ms + move_duration_ms;

	/*
	let swapped_state = {
		let mut state = *prev_state;
		state.swap_gems(changes.swipe_cell, changes.dst_cell).unwrap();
		state
	};
	*/

	let mut time_ms = time_ms;

	for (change_idx, changes_iter) in changes.changes.iter().enumerate() {

		if change_idx > 0 {
			let mut anim_state = StateAnimation::new(&format!("anim_pause{}", change_idx), changes_iter.prev_state);
			anim_state.add_animation(GemAnimation{
				src_cell: Pt{y: 1, x: 1},
				dst_cell: Some(Pt{y: 1, x: 1}),
				init_offset: None,
				progress: 1.0,
				progress_fn: progress_fn_smoothstep,
				start_time_ms: time_ms,
				total_time_ms: pause_time_ms,
			});
			self.animation_queue.push(anim_state);
			println!("added pause anim starting at {}, ending {} later", time_ms - start_time_ms, pause_time_ms);

			time_ms += pause_time_ms;
		}

		// TODO get state from `changes`

		let mut anim_state2 = StateAnimation::new(&format!("anim{}-2", change_idx), changes_iter.prev_state);
	
		for match_val in changes_iter.to_remove.iter() {
			let dir = match_val.dir;
			let start = match_val.pt; // TODO rename this field to "pos", I keep calling it that
			for i in 0..match_val.len {
				let pt = start.add(dir.mult(i));
				anim_state2.add_animation(GemAnimation{
					src_cell: pt,
					dst_cell: None,
					init_offset: None,
					progress: 0.0,
					progress_fn: progress_fn_smoothstep,
					start_time_ms: time_ms,
					total_time_ms: fade_duration_ms,
				});
	/*
				let time_ms = time_ms + fade_duration_ms;
				anim_state2.add_animation(GemAnimation{
					src_cell: pt,
					dst_cell: None,
					init_offset: None,
					progress: 1.0,
					progress_fn: progress_fn_smoothstep,
					start_time_ms: time_ms,
					total_time_ms: time_stay_blank_ms,
				});
	*/
			}
		}
	
		self.animation_queue.push(anim_state2);
		println!("added fade anim starting at {}, ending {} later", time_ms - start_time_ms, fade_duration_ms);

		//let time_ms = time_ms + fade_duration_ms + time_stay_blank_ms;
		time_ms = time_ms + fade_duration_ms;


		let mut anim_state3 = StateAnimation::new(&format!("anim{}-3", change_idx), changes_iter.new_state);
		//let end_time_ms = time_ms + 750;
		let max_fall_dist = {
			let mut max_fall_dist = 0;
			for y in 0..BOARD_HEIGHT {
				for x in 0..BOARD_WIDTH {
					let pt = Pt{y: y as i32, x: x as i32};
					let fall_distance = changes_iter.fallen_distance[y][x];
					if let Some(fall_distance) = fall_distance {
						if fall_distance > max_fall_dist {
							max_fall_dist = fall_distance;
						}
					}
				}
			}
			max_fall_dist as u32
		};
		//let max_fall_dist = 1;
		let mut max_board_fall_time_ms = 0;
		for x in 0..BOARD_WIDTH {
			let max_fall_dist = {
				let mut max_fall_dist = 0;
				for y in 0..BOARD_HEIGHT {
					if let Some(fall_distance) = changes_iter.fallen_distance[y][x] {
						if fall_distance > max_fall_dist {
							max_fall_dist = fall_distance;
						}
					}
				}
				max_fall_dist as TimeMs
			};
			for y in 0..BOARD_HEIGHT {
				let pt = Pt{y: y as i32, x: x as i32};
				let fall_distance = changes_iter.fallen_distance[y][x];
				if let Some(fall_distance) = fall_distance {
					let mut delay_dist = max_fall_dist - fall_distance as TimeMs;
					let delay_time_ms = (fall_time_ms * delay_dist) as TimeMs;
					let this_fall_time_ms = fall_time_ms * (fall_distance as TimeMs);
					if delay_time_ms > 0 {
						anim_state3.add_animation(GemAnimation{
							src_cell: pt,
							dst_cell: Some(Pt{y: pt.y-(fall_distance as i32), x: pt.x}),
							init_offset: None,
							progress: 1.0,
							progress_fn: progress_fn_smoothstep,
							start_time_ms: time_ms,
							total_time_ms: delay_time_ms,
						});
					}

					anim_state3.add_animation(GemAnimation{
						src_cell: pt,
						dst_cell: Some(pt),
						init_offset: Some(Pt{y: -(fall_distance as i32), x: 0}),
						progress: 0.0,
						progress_fn: progress_fn_smoothstep,
						//start_time_ms: time_ms,
						start_time_ms: time_ms + delay_time_ms,
						total_time_ms: this_fall_time_ms,
					});
					if this_fall_time_ms > max_board_fall_time_ms {
						max_board_fall_time_ms = this_fall_time_ms;
					}
				}
			}
		}

		self.animation_queue.push(anim_state3);
		time_ms += max_board_fall_time_ms;
	}
	println!("done handle_move_updates, len {}", self.animation_queue.len());
}



}
