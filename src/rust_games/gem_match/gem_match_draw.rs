use std::collections::HashMap;

use crate::libs::swipe_tracker::{CursorEvt, SwipeEvt, CursorEvtType};

use crate::gem_match::gem_match_core::{State, GemType, BOARD_WIDTH, BOARD_HEIGHT, Pt};
use crate::gem_match::gem_match_main::{AlexGamesGemMatch};
use crate::rust_game_api::{AlexGamesApi, CANVAS_HEIGHT, CANVAS_WIDTH, CCallbacksPtr, MouseEvt, TimeMs};
use crate::rust_game_api;

const cell_width:  f64 = (CANVAS_WIDTH as f64) / (BOARD_WIDTH as f64);
const cell_height: f64 = (CANVAS_HEIGHT as f64) / (BOARD_HEIGHT as f64);

pub const FPS: i32 = 60;

pub struct GemMatchDraw {
	gem_pos_adjustments_by_pos: HashMap<Pt, Vec<GemAnimation>>,

	callbacks: &'static rust_game_api::CCallbacksPtr,
}

pub fn cell_size() -> f64 {
	f64::min(cell_width, cell_height)
}

fn progress_fn_smoothstep(x: f64) -> f64 {
	3.0*x*x - 2.0*x*x
}

#[derive(Debug)]
struct GemAnimation {
	id: i32,

	src_cell: Pt,
	dst_cell: Pt,
	init_offset: Option<Pt>,
	progress: f64,
	progress_fn: fn(f64) -> f64,
	total_time_ms: TimeMs,
	start_time_ms: TimeMs,
}

impl GemAnimation {
	fn is_current(&self, time_ms: TimeMs) -> bool {
		return (self.start_time_ms <= time_ms &&
		   time_ms < self.start_time_ms + self.total_time_ms);
	}
}

impl GemMatchDraw {

	pub fn new(callbacks: &'static rust_game_api::CCallbacksPtr) -> GemMatchDraw {
		let mut draw = GemMatchDraw {
			callbacks: callbacks,
			gem_pos_adjustments_by_pos: HashMap::new(),
			//gem_pos_adjustments: Vec::new(),
		};
		for y in 0..BOARD_HEIGHT {
			for x in 0..BOARD_WIDTH {
				let pt = Pt{y: y as i32, x: x as i32};
				draw.gem_pos_adjustments_by_pos.insert(pt, Vec::new());
			}
		}

		draw
	}

pub fn draw_state(&self, state: &State) {
	self.callbacks.draw_clear();
	let padding = 1.0;
	let piece_radius = (cell_size()/2.0 - padding) as i32;
	let piece_outline_width = 2;
	for (y, row) in state.board.iter().enumerate() {
		for (x, cell) in row.iter().enumerate() {
			let pt = Pt{y: y as i32, x: x as i32};
			let (colour, outline_colour) = match cell.gem_type {
				GemType::SAPPHIRE => ("#0f52ba", "#000088" ),
				//GemType::EMERALD  => ("#50c878", "#008800" ),
				GemType::EMERALD  => ("#30c858", "#008800" ),
				GemType::RUBY     => ("#9b111e", "#440000" ),
				GemType::AMETHYST => ("#9966cc", "#440044" ),
				GemType::TOPAZ    => ("#ffd700", "#888866" ),
				GemType::AMBER    => ("#ff8800", "#442200" ),
			};
			let y = y as f64;
			let x = x as f64;

			let mut circ_y = (y+0.5)*cell_height;
			let mut circ_x = (x+0.5)*cell_width;

			let time_ms = self.callbacks.get_time_ms();
			let adjustments = self.gem_pos_adjustments_by_pos.get(&pt).unwrap();
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
				let mut dx = (adjustment.dst_cell.x as f64 - x - offset.x as f64)*progress;
				let mut dy = (adjustment.dst_cell.y as f64 - y - offset.y as f64)*progress;

				let dy = (dy + offset.y as f64) * cell_height;
				let dx = (dx + offset.x as f64) * cell_width;
				//println!("anim {}, progress {:.2}, dy={}, dx={}; offset=({}, {})", adjustment.id, progress, dy, dx, offset.y, offset.x);
				circ_y += dy;
				circ_x += dx;
			}

			self.callbacks.draw_circle(colour, outline_colour,
			                           circ_y as i32, circ_x as i32,
			                           piece_radius, piece_outline_width);
		}
	}

	let matches = state.find_all_three_or_more_in_a_row();
	for match_val in matches {
		let y1 = match_val.pt.y as f64 * cell_size();
		let x1 = match_val.pt.x as f64 * cell_size();
		let end_pt = match_val.pt.add(match_val.dir.mult(match_val.len));
		let end_pt = end_pt.add(match_val.dir.swap());
		let y2 = (end_pt.y as f64 + 0.0) * cell_size();
		let x2 = (end_pt.x as f64 + 0.0) * cell_size();
		self.callbacks.draw_rect("#ffff0055", y1 as i32, x1 as i32, y2 as i32, x2 as i32);
		self.callbacks.draw_line("#00ffff", 3, y1 as i32, x1 as i32, y1 as i32, x2 as i32);
		self.callbacks.draw_line("#00ffff", 3, y1 as i32, x1 as i32, y2 as i32, x1 as i32);
		self.callbacks.draw_line("#00ffff", 3, y2 as i32, x2 as i32, y1 as i32, x2 as i32);
		self.callbacks.draw_line("#00ffff", 3, y2 as i32, x2 as i32, y2 as i32, x1 as i32);
	}

	
	self.callbacks.draw_refresh();
}

pub fn update_animations(&mut self, dt_ms: i32) {
	//for anim in self.gem_pos_adjustments.iter() {
	let mut to_delete = Vec::<Pt>::new();
	let time_ms = self.callbacks.get_time_ms();
	//println!("update_animations, time_ms={}", time_ms);
	//println!("checking for animations within current time_ms ({})", time_ms);
	for (pt, anims) in self.gem_pos_adjustments_by_pos.iter_mut() {
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

pub fn screen_pos_to_cell_pos(&self, pt: Pt) -> Pt {
	let cell_size = cell_size() as i32;
	Pt{
		y: pt.y/cell_size,
		x: pt.x/cell_size,
	}
}

fn add_animation(&mut self, anim: GemAnimation) {
	//let anim = Rc::new(anim);
	//self.gem_pos_adjustments.push(Rc::clone(&anim));
	println!("adding animation with start_time_ms {}, total_time {}", anim.start_time_ms, anim.total_time_ms);
	self.gem_pos_adjustments_by_pos.get_mut(&anim.src_cell).expect("empty?").push(anim);
}

pub fn handle_swipe_bad_move(&mut self, pos: Pt, dir: Pt) {
	println!("handle_swipe_bad_move");

	let swipe_cell = self.screen_pos_to_cell_pos(pos);
	let dst_cell = swipe_cell.add(dir);

	let time_ms = self.callbacks.get_time_ms();
	let anim_duration_ms = 400;

	self.add_animation(GemAnimation{
		id: 1,
		src_cell: swipe_cell,
		dst_cell: dst_cell,
		init_offset: None,
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms,
		total_time_ms: anim_duration_ms,
	});
	self.add_animation(GemAnimation{
		id: 2,
		src_cell: dst_cell,
		dst_cell: swipe_cell,
		init_offset: None,
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms,
		total_time_ms: anim_duration_ms,
	});

	self.add_animation(GemAnimation{
		id: 3,
		src_cell: swipe_cell,
		dst_cell: swipe_cell,
		init_offset: Some(dir.mult(1)),
		//init_offset: None,
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms + anim_duration_ms,
		total_time_ms: anim_duration_ms,
	});
	self.add_animation(GemAnimation{
		id: 4,
		src_cell: dst_cell,
		dst_cell: dst_cell,
		init_offset: Some(dir.mult(-1)),
		//init_offset: None,
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms + anim_duration_ms,
		total_time_ms: anim_duration_ms,
	});

}

pub fn handle_swipe_swap_animation(&mut self, pos: Pt, dir: Pt) {
	println!("handle_swipe_swap_animation");
	let swipe_cell = self.screen_pos_to_cell_pos(pos);
	let dst_cell = swipe_cell.add(dir);

	let time_ms = self.callbacks.get_time_ms();
	let anim_duration_ms = 400;

	// TODO this isn't great, I'll have to figure out how to animate this. May need to save the state along with animations.

/*
	self.add_animation(GemAnimation{
		id: 10,
		src_cell: swipe_cell,
		dst_cell: dst_cell,
		init_offset: Some(dir.mult(-1)),
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms,
		total_time_ms: anim_duration_ms,
	});
	self.add_animation(GemAnimation{
		id: 11,
		src_cell: dst_cell,
		dst_cell: swipe_cell,
		init_offset: Some(dir.mult(1)),
		progress: 0.0,
		progress_fn: progress_fn_smoothstep,
		start_time_ms: time_ms,
		total_time_ms: anim_duration_ms,
	});
*/
}



}
