#[derive(Copy, Clone, Debug, Hash, Eq, PartialEq)]
pub struct Pt {
	pub x: i32,
	pub y: i32,
}

impl Pt {
	pub fn add(&self, arg: Pt) -> Pt {
		Pt{
			y: self.y + arg.y,
			x: self.x + arg.x,
		}
	}

	pub fn mult(&self, arg: i32) -> Pt {
		Pt{
			y: self.y * arg,
			x: self.x * arg,
		}
	}

	pub fn swap(&self) -> Pt {
		Pt{ y: self.x, x: self.y }
	}
}
