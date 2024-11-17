use std::ops::{Add, Mul};

#[derive(Copy, Clone, Debug, Hash, Eq, PartialEq)]
pub struct Pt_g<T> {
    pub x: T,
    pub y: T,
}

// TODO clean all of this up, I'm not using it right now
// but I'll probably want something similar later
trait Atan2 {
	fn atan2(self, other: Self) -> Self;
}

impl Atan2 for f64 {
	fn atan2(self, other: Self) -> Self {
		f64::atan2(self, other)
	}
}

impl Atan2 for i32 {
	fn atan2(self, other: Self) -> Self {
		i32::atan2(self, other)
	}
}

trait MagnitudeOps: Add<Output=Self> + Mul<Output=Self> + Sized {
	fn from_i32(val: i32) -> Self;
	fn from_f64(val: f64) -> Self;
	fn sqrt(self) -> Self;
	fn sin(val: f64) -> Self;
	fn cos(val: f64) -> Self;
}

impl MagnitudeOps for f64 {
	fn from_i32(val: i32) -> Self {
		val as f64
	}
	fn from_f64(val: f64) -> Self {
		val
	}
	fn sqrt(self) -> Self {
		self.sqrt()
	}
	fn sin(val: f64) -> Self {
		val.sin()
	}
	fn cos(val: f64) -> Self {
		val.cos()
	}
}

impl MagnitudeOps for i32 {
	fn from_i32(val: i32) -> Self {
		val
	}
	fn from_f64(val: f64) -> Self {
		val as i32
	}
	fn sqrt(self) -> Self {
		(self as f64).sqrt() as i32
	}
	fn sin(val: f64) -> Self {
		(val.sin().round() as i32)
	}
	fn cos(val: f64) -> Self {
		(val.cos().round() as i32)
	}
}



impl<T> Pt_g<T>
	where T: std::ops::Add<Output = T> +
	         std::ops::Mul<Output = T> +
	         Copy + Atan2 + MagnitudeOps, f64: From<T>
{

	pub fn from_mag_angle(mag: T, angle: T) -> Pt_g<T> {
		Pt_g {
			y: mag * T::sin(T::from_f64(angle.into()).into()),
			x: mag * T::cos(T::from_f64(angle.into()).into()),
		}
	}

    pub fn add(&self, arg: Pt_g<T>) -> Pt_g<T> {
        Pt_g {
            y: self.y + arg.y,
            x: self.x + arg.x,
        }
    }

    pub fn mult(&self, arg: T) -> Pt_g<T> {
        Pt_g {
            y: self.y * arg,
            x: self.x * arg,
        }
    }

    pub fn swap(&self) -> Pt_g<T> {
        Pt_g {
            y: self.x,
            x: self.y,
        }
    }

	pub fn angle(&self) -> T {
		self.y.atan2(self.x)
	}

	pub fn mag(&self) -> T {
		(self.x*self.x + self.y*self.y).sqrt()
	}
}

pub type Pt = Pt_g<i32>;
pub type Ptf = Pt_g<f64>;
