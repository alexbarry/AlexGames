use crate::libs::point::Pt;

#[derive(Copy, Clone, Debug)]
pub enum CursorEvtType {
	Down,
	Up,
	Move,
	Cancel,
}

#[derive(Copy, Clone, Debug)]
pub struct CursorEvt {
	pub evt_type: CursorEvtType,
	pub pos: Pt,
} 

#[derive(Copy, Clone, Debug)]
pub struct SwipeEvt {
	pub pos: Pt,
	pub dir: Pt,
}

pub struct SwipeTracker {
	cursor_down: bool,
	swipe_threshold: i32,
	start: Option<Pt>,
}

fn dir_of(val: i32) -> i32 {
	if val < 0 { -1 }
	else { 1 }
}
impl SwipeTracker {

	pub fn new(swipe_threshold: i32) -> SwipeTracker {
		SwipeTracker {
			cursor_down:     false,
			start:           None,
			swipe_threshold: swipe_threshold,
		}
	}

	pub fn reset_state_on_swipe(&mut self) {
		self.cursor_down = false;
		self.start = None;
	}
	
	pub fn handle_cursor_evt(&mut self, evt: CursorEvt) -> Option<SwipeEvt> {
		if self.cursor_down {
			match evt.evt_type {
				CursorEvtType::Up
				|CursorEvtType::Cancel => {
					self.cursor_down = false;
					self.start = None;
				},
				CursorEvtType::Move => {
					let start = self.start.unwrap();
					let dx = evt.pos.x - start.x;
					let dy = evt.pos.y - start.y;
					if dx.abs() > self.swipe_threshold {
						self.reset_state_on_swipe();
						return Some(SwipeEvt{pos: start, dir: Pt{y: 0, x: dir_of(dx)}});
					}
					if (start.y - evt.pos.y).abs() > self.swipe_threshold {
						self.reset_state_on_swipe();
						return Some(SwipeEvt{pos: start, dir: Pt{y:dir_of(dy), x: 0}});
					}
				}
				_ => (),
			}
		} else {
			match evt.evt_type {
				CursorEvtType::Down => {
					self.cursor_down = true;
					self.start = Some(evt.pos);
				}
				_ => (),
			}
		}
		return None;
	}

}
