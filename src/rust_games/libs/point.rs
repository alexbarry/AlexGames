
#[derive(Copy, Clone, Debug, Hash, Eq, PartialEq)]
pub struct Pt_g<T> {
    pub x: T,
    pub y: T,
}

impl<T> Pt_g<T>
	where T: std::ops::Add<Output = T> +
	         std::ops::Mul<Output = T> +
	         Copy,
{
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
}

pub type Pt = Pt_g<i32>;
pub type Ptf = Pt_g<f64>;
