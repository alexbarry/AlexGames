
use crate::sudoku::sudoku_core::{self, State, CellContents, Mode};

use std::collections::HashMap;

use crate::rust_game_api::{
    CCallbacksPtr, TextAlign
};

use crate::libs::point::Pt;
use crate::libs::draw;
pub use crate::libs::celebrations::fireworks::FireworksState;

pub const CANVAS_HEIGHT: i32 = 620;
pub const CANVAS_WIDTH: i32 = 480;

pub struct DrawState {
	pub immediately_show_mistakes: Option<bool>,
	pub mistakes: HashMap<Pt, i8>,


	fireworks_state: FireworksState,
	animation_timer_handle: Option<i32>,

	callbacks: &'static CCallbacksPtr,
	TEXT_FONT_SIZE: i32,
	TEXT_SMALLER_FONT_SIZE: i32,
	TEXT_TIMER_FONT_SIZE: i32,
	TEXT_NOTE_FONT_SIZE: i32,
	LINE_THICKNESS: i32,
	LINE_GROUP_THICKNESS: i32,
}

#[derive(PartialEq)]
pub enum ButtonId {
	DoneEnteringStartingVals,
	Erase,
	Val(i32),
	ToggleNotes,
}

struct CellPos {
	y1: i32,
	x1: i32,

	y2: i32,
	x2: i32,

	y_start: i32,
	x_start: i32,
	y_end: i32,
	x_end: i32,

	y_middle: i32,
	x_middle: i32,

	cell_size: i32,
	padding: i32,

	button_buffer: i32,

}

struct BtnPos {
	y1: i32,
	x1: i32,
	y2: i32,
	x2: i32,

	y_text: i32,
	x_text: i32,
	font_size: i32,
}

fn format_time_elapsed(time_secs: i32) -> String {
	let secs = time_secs % 60;
	let mins = time_secs / 60;
	let hours = mins / 60;
	let mins = mins - hours * 60;

	let mins_str = if hours == 0 {
		format!("{}", mins)
	}  else {
		format!("{:02}", mins)
	};
	let hours_str = if hours > 0 {
		format!("{}:", hours)
	} else {
		"".to_string()
	};
	format!("{}{}:{:02}", hours_str, mins_str, secs)
}

impl DrawState {
	pub fn new(callbacks: &'static CCallbacksPtr) -> Self {
		Self {
			immediately_show_mistakes: None,
			mistakes: HashMap::new(),
			fireworks_state: FireworksState::new(),

			animation_timer_handle: None,

			callbacks: callbacks,

			TEXT_FONT_SIZE: 32,
			TEXT_SMALLER_FONT_SIZE: 16,
			TEXT_TIMER_FONT_SIZE: 12,
			TEXT_NOTE_FONT_SIZE: 14,
			LINE_THICKNESS: 1,
			LINE_GROUP_THICKNESS: 4,
		}
	}

	pub fn update_anim_state(&mut self, dt_ms: i32) {
        let mut fireworks_complete = self.fireworks_state.update(dt_ms);

		if fireworks_complete {
			if let Some(timer_handle) = self.animation_timer_handle {
            	self.callbacks.delete_timer(timer_handle);
				self.animation_timer_handle = None;
			}
		}
	}

	pub fn start_win_animation(&mut self) {
        // TODO only do this in a single place, and not if the timer is already running?
        let FPS = 60;
		if self.animation_timer_handle.is_none() {
        	self.animation_timer_handle = Some(self.callbacks.update_timer_ms(1000 / FPS));
		}
        self.fireworks_state.start_animation();
	}

	fn cell_pos(&self, game_state: &State, y: i32, x: i32) -> CellPos {
		let game_size = game_state.size as i32;

		let timer_space = 20;

		let button_buffer = 120;
		let cell_size = (CANVAS_WIDTH.min(CANVAS_HEIGHT - button_buffer))/game_size;
		let padding = (cell_size - self.TEXT_FONT_SIZE)/2;

		let y_start = self.LINE_THICKNESS + timer_space;
		let y_end   = CANVAS_HEIGHT - button_buffer;

		let x_start = 1;
		let x_end   = CANVAS_WIDTH - self.LINE_THICKNESS;

		let cell_pos_y = |y| y_start + cell_size * y;
		let cell_pos_x = |x| x_start + cell_size * x;

		let y_middle = cell_pos_y(y) + cell_size - padding;
		let x_middle = cell_pos_x(x) + cell_size/2;

		CellPos {
			y1: cell_pos_y(y),
			x1: cell_pos_x(x),
			y2: cell_pos_y(y+1),
			x2: cell_pos_x(x+1),

			y_start: y_start,
			x_start: x_start,
			y_end:   y_end,
			x_end:   x_end,

			y_middle: y_middle,
			x_middle: x_middle,

			cell_size: cell_size,
			padding: padding,

			button_buffer: button_buffer,
		}
	}

	fn cell_note_offset(&self, game_state: &State, val: i8) -> Pt {
		let val = val as i32;
		let cell_info = self.cell_pos(game_state, 0, 0);
		let cell_size = cell_info.cell_size as i32;
		let size = game_state.size as i32;
		let box_size = game_state.box_size as i32;
		let val = val - 1;
		let cell_size_w_padding = cell_size - 3;
		let padding_y = -1;
		let padding_x = 8;
		Pt {
			y: val/box_size * cell_size/3 - cell_size/2 + padding_y,
			x: (val % box_size) * cell_size/3 - cell_size/2 + padding_x,
		}
	}

	fn val_btn_width(&self, game_state: &State) -> i32 {
		let all_btn_width = CANVAS_WIDTH;
		all_btn_width / (game_state.size as i32)
	}

	fn button_pos(&self, game_state: &State, btn: &ButtonId) -> BtnPos {
		let cell_pos_info = self.cell_pos(game_state, 0, 0);

		let x_start = 0;
		let btn_width = self.val_btn_width(game_state);
		let padding = 5;
		let line_thickness = 1;

		let row1_buttons = self.get_buttons_row1(game_state);
		let row1_btn_width = CANVAS_WIDTH/(row1_buttons.len() as i32);

		if let ButtonId::Val(btn_val) = *btn {
			let btn_val = btn_val - 1;
			let x1 = x_start + btn_width * (btn_val);
			let mut x2 = x_start + btn_width * (btn_val+1);
			if btn_val + 1 == game_state.size.try_into().unwrap() {
				x2 = CANVAS_WIDTH;
			}
			BtnPos {
				y1: CANVAS_HEIGHT - cell_pos_info.button_buffer/2,
				y2: CANVAS_HEIGHT - line_thickness,
				x1: x1,
				x2: x2,
	
				y_text: CANVAS_HEIGHT - line_thickness - cell_pos_info.button_buffer/4 + self.TEXT_FONT_SIZE/2,
				x_text: x_start + ( (btn_width as f32) * (btn_val as f32 + 0.5) ) as i32,
				font_size: self.TEXT_FONT_SIZE,
			}
		} else if *btn == ButtonId::Erase {
			let y2 = CANVAS_HEIGHT - cell_pos_info.button_buffer/2;
			BtnPos {
				y1: CANVAS_HEIGHT - cell_pos_info.button_buffer + padding,
				y2: y2,
				x1: x_start,
				x2: x_start + row1_btn_width,
				y_text: y2 - (cell_pos_info.button_buffer/2 - self.TEXT_FONT_SIZE)/2,
				x_text: (x_start + CANVAS_WIDTH/2)/2,
				font_size: self.TEXT_FONT_SIZE,
			}

		} else if *btn == ButtonId::ToggleNotes ||
		          *btn == ButtonId::DoneEnteringStartingVals {
			let y2 = CANVAS_HEIGHT - cell_pos_info.button_buffer/2;
			let font_size = if *btn == ButtonId::DoneEnteringStartingVals { self.TEXT_SMALLER_FONT_SIZE } else { self.TEXT_FONT_SIZE };
			BtnPos {
				y1: CANVAS_HEIGHT - cell_pos_info.button_buffer + padding,
				y2: y2,
				x1: x_start + row1_btn_width,
				x2: CANVAS_WIDTH,
				y_text: y2 - (cell_pos_info.button_buffer/2 - font_size)/2,
				x_text: x_start + 3*CANVAS_WIDTH/4,
				font_size: font_size,
			}
		} else {
			BtnPos {
				y1: 0,
				y2: 0,
				x1: 0,
				x2: 0,
				y_text: 0,
				x_text: 0,
				font_size: self.TEXT_FONT_SIZE,
			}
		}
	}

	pub fn pos_to_cell(&self, game_state: &State, y_pos: i32, x_pos: i32) -> Option<Pt> {
		let pos_info = self.cell_pos(game_state, 0, 0);

		let y_idx = (y_pos - pos_info.y_start) / pos_info.cell_size;
		let x_idx = (x_pos - pos_info.x_start) / pos_info.cell_size;

		let game_size = game_state.size as i32;
		if !(0 <= y_idx && y_idx < game_size &&
		     0 <= x_idx && x_idx < game_size) {
			return None
		}

		Some(Pt {
			y: y_idx,
			x: x_idx,
		})
	}

	pub fn pos_to_btn(&self, game_state: &State, y_pos: i32, x_pos: i32) -> Option<ButtonId> {
		for btn_id in self.get_buttons(game_state) {
			let btn_pos = self.button_pos(game_state, &btn_id);
			if btn_pos.y1 <= y_pos && y_pos <= btn_pos.y2 &&
			   btn_pos.x1 <= x_pos && x_pos <= btn_pos.x2 {
				return Some(btn_id);
			}
		}
		return None;
	}

	fn get_buttons(&self, game_state: &State) -> Vec<ButtonId> {
		let game_size = game_state.size as i32;
		self.get_buttons_row1(game_state)
			.into_iter()
			.chain(
				self.get_buttons_row2(game_state).into_iter()
			)
			.collect()
	}
	fn get_buttons_row1(&self, game_state: &State) -> Vec<ButtonId> {
		vec![
			ButtonId::Erase,
			if game_state.mode == Mode::EnterStartingVal {
				 ButtonId::DoneEnteringStartingVals
			} else {
				 ButtonId::ToggleNotes
			},
		]
	}
	fn get_buttons_row2(&self, game_state: &State) -> Vec<ButtonId> {
		let game_size = game_state.size as i32;
		(1..=game_size).map(|val| ButtonId::Val(val))
			.collect()
	}

    pub fn draw_state(&mut self, callbacks: &'static CCallbacksPtr, mut state: &State) {
		callbacks.draw_clear();

		let is_dark_mode = callbacks.get_user_colour_pref() == "dark";

		let LINE_COLOUR = "#888";
		let TEXT_COLOUR = if !is_dark_mode { "#000" } else { "#fff" };
		let TEXT_COLOUR_DISABLED = if !is_dark_mode { "#8888" } else { "#8888" };
		let TEXT_COLOUR_CONFLICT = "#f00";
		let TEXT_COLOUR_USER = if !is_dark_mode { "#00a" } else { "#88f" };
		let SELECTED_BG = if !is_dark_mode { "#0084" } else { "#44cc" };
		let SELECTED2_BG = if !is_dark_mode { "#0082" } else { "#228c" };
		let SELECTED3_BG = if !is_dark_mode { "#0081" } else { "#116c" };
		let CONFLICT_BG = if !is_dark_mode {"#f003" } else { "#f003" };
		let STARTING_VAL_BG = if !is_dark_mode { "#c8c8c888" } else { "#282828" };
		let NORMAL_CELL_BG = if !is_dark_mode { "#e8e8e888" } else { "#000" };
		let same_val_border_colour = if !is_dark_mode { "#000" } else { "#888" };
		let border_thickness = 2;

		let game_size = state.size as i32;

		/*
		let button_buffer = 100;
		let cell_size = (CANVAS_WIDTH.min(CANVAS_HEIGHT) - button_buffer)/game_size;
		let padding = (cell_size - TEXT_FONT_SIZE)/2;

		let y_start = LINE_THICKNESS;
		let y_end   = CANVAS_HEIGHT - button_buffer;

		let x_start = button_buffer/2;
		let x_end   = CANVAS_WIDTH - button_buffer/2 - LINE_THICKNESS;

		let cell_pos_y = |y| y_start + cell_size * y;
		let cell_pos_x = |x| x_start + cell_size * x;
		*/

		let cell_pos_y = |y| {
			self.cell_pos(state, y, 0).y1
		};
		let cell_pos_x = |x| {
			self.cell_pos(state, 0, x).x1
		};
		

		let mut highlight_err = state.get_conflicts(self.immediately_show_mistakes.unwrap_or(true));
		for (pt, _) in self.mistakes.clone() {
			highlight_err.insert(pt);
		}

		for y in 0..game_size {
			for x in 0..game_size {
				let pt = Pt {y: y as i32, x: x as i32};
				let highlight_err = highlight_err.contains(&pt);
				let pos_info = self.cell_pos(state, y, x);
				let cell = state.val(y, x);
				let cell_val = match cell {
					CellContents::Empty => 0,
					CellContents::StartingVal(val) => val,
					CellContents::UserInputVal(val) => val,
				};
				let starting_val = matches!(cell, CellContents::StartingVal(_));
				if starting_val {
					callbacks.draw_rect(&STARTING_VAL_BG, pos_info.y1, pos_info.x1, pos_info.y2, pos_info.x2)
				} else {
					callbacks.draw_rect(&NORMAL_CELL_BG, pos_info.y1, pos_info.x1, pos_info.y2, pos_info.x2)
				}
				let bg_colour = if state.cell_selected(y,x) {
					Some(SELECTED_BG)
				} else if cell_val != 0 && state.selected.is_some_and(|pt| state.cell_val(pt.y,pt.x) == cell_val) {
					Some(SELECTED2_BG)
				} else if state.selected.is_some_and(|pt| pt.y == y || pt.x == x || state.box_id(&pt) == state.box_id(&Pt {y: y as i32, x: x as i32})) {
					Some(SELECTED3_BG)
				} else if highlight_err {
					Some(CONFLICT_BG)
				} else {
					None
				};
				if let Some(bg_colour) = bg_colour {
					callbacks.draw_rect(&bg_colour, pos_info.y1, pos_info.x1, pos_info.y2, pos_info.x2)
				}
				let text_colour = if highlight_err {
					TEXT_COLOUR_CONFLICT
				} else if starting_val {
					TEXT_COLOUR
				} else {
					TEXT_COLOUR_USER
				};
				if cell_val != 0 {
					let num_str = format!("{}", cell_val);
					callbacks.draw_text(&num_str, &text_colour, pos_info.y_middle, pos_info.x_middle, self.TEXT_FONT_SIZE, TextAlign::Middle);
				} else {
					let notes = state.cell_notes(y,x);
					for note_val in notes.iter() {
						// TODO add offset based on val
						let note_offset = self.cell_note_offset(state, *note_val);
						let note_txt = format!("{}", note_val);
						callbacks.draw_text(&note_txt, &TEXT_COLOUR_USER, pos_info.y_middle + note_offset.y, pos_info.x_middle + note_offset.x, self.TEXT_NOTE_FONT_SIZE, TextAlign::Middle);
					}
					// TODO
				}
			}
		}

		for y in 0..=game_size {
			let pos_info = self.cell_pos(state, y, 0);
			let y_pos = pos_info.y1;
			//let y_pos = cell_pos_y(y);
			let thickness = if y as usize % state.box_size == 0 && y != 0 && y != game_size {
				self.LINE_GROUP_THICKNESS
			} else {
				self.LINE_THICKNESS
			};
			callbacks.draw_line(&LINE_COLOUR, thickness, y_pos, pos_info.x_start, y_pos, pos_info.x_end);
		}
		for x in 0..=game_size {
			//let x_pos = cell_pos_x(x);
			let pos_info = self.cell_pos(state, 0, x);
			let x_pos = pos_info.x1;
			let thickness = if x as usize % state.box_size == 0 && x != 0 && x != game_size {
				self.LINE_GROUP_THICKNESS
			} else {
				self.LINE_THICKNESS
			};
			callbacks.draw_line(&LINE_COLOUR, thickness, pos_info.y_start, x_pos, pos_info.y_end, x_pos);
		}

		for y in 0..game_size {
			for x in 0..game_size {
				let cell = state.val(y, x);
				let pos_info = self.cell_pos(state, y, x);
				let starting_val = matches!(cell, CellContents::StartingVal(_));
				let cell_val = match cell {
					CellContents::Empty => 0,
					CellContents::StartingVal(val) => val,
					CellContents::UserInputVal(val) => val,
				};
				let border = if cell_val != 0 && state.selected.is_some_and(|pt| state.cell_val(pt.y, pt.x) == cell_val) {
					Some(same_val_border_colour)
				} else {
					None
				};
				if let Some(border) = border {
					draw::draw_rect_outline(callbacks, &border, border_thickness, pos_info.y1, pos_info.x1, pos_info.y2, pos_info.x2)
				}
			}
		}


		let taken_input_vals = state.get_taken_input_vals();
		let sel_val = state.get_selected_val(); 
		let notes_on = state.mode == Mode::EnterCellNotes;

		for btn_val in self.get_buttons(state) {
			let btn_pos = self.button_pos(state, &btn_val);
			draw::draw_rect_outline(callbacks, &LINE_COLOUR, self.LINE_THICKNESS, btn_pos.y1, btn_pos.x1, btn_pos.y2, btn_pos.x2);
			let mut disabled = false;
			let mut highlighted = false;
			let btn_text = match btn_val {
				ButtonId::Erase => "Clear".to_string(),
				ButtonId::Val(val) => {
					disabled = taken_input_vals.contains(&(val as i8));
					if let Some(sel_pt) = state.selected {
						let y = sel_pt.y as usize;
						let x = sel_pt.x as usize;
						if state.board[y][x].revealed {
							disabled = true;
						}
					}
					highlighted = sel_val.is_some_and(|sel_val| sel_val == val as i8);
					format!("{}", val)
				},
				ButtonId::ToggleNotes => {
					highlighted = notes_on;
					format!("Notes: {}", if notes_on { "on" } else { "off" })
				},
				ButtonId::DoneEnteringStartingVals => {
					format!("Finalize Custom Puzzle")
				},
			};
			if highlighted {
				callbacks.draw_rect(&SELECTED3_BG, btn_pos.y1, btn_pos.x1, btn_pos.y2, btn_pos.x2);
			}
			let text_colour = if !disabled {
				TEXT_COLOUR
			} else {
				TEXT_COLOUR_DISABLED
			};
			callbacks.draw_text(&btn_text, &text_colour, btn_pos.y_text, btn_pos.x_text, btn_pos.font_size, TextAlign::Middle);
		}

		let time_str = format_time_elapsed(state.time_elapsed_ms/1000);
		let padding = 3;
		callbacks.draw_text(&time_str, TEXT_COLOUR, self.TEXT_TIMER_FONT_SIZE + padding, CANVAS_WIDTH, self.TEXT_TIMER_FONT_SIZE, TextAlign::Right);

        self.fireworks_state.draw(callbacks);


		callbacks.draw_refresh();
	}
}
