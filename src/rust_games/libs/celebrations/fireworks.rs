use crate::rust_game_api::{
    AlexGamesApi, CCallbacksPtr, OptionInfo, OptionType, TextAlign, CANVAS_HEIGHT, CANVAS_WIDTH,
};

use rand::Rng;
use std::collections::VecDeque;

use crate::libs::point::Pt;


static FIREWORKS_COLOURS: &[&'static str] = &[
	"#fd7678",
	"#76fd78",
	"#7676fd",
	"#fd76fd",
	"#fdfd76",
	"#76fdfd",
	"#fdfdfd",
];

const MAX_PARTICLE_TRAILS: usize = 20;

pub struct FireworksState {
	fireworks: Vec<SingleFireworkState>,
	time_to_fade_overlay_away_ms: i32,
}

struct SingleFireworkState {
	time_to_detonate_ms: Option<i32>,
	time_to_fade_away_ms: i32,
	time_remaining_to_max_radius_ms: i32,
	pos: Pt,
	particles: Vec<FireworkParticle>,

	time_to_max_radius_ms: i32,
	radius: i32,
	segments: i32,
	colour: &'static str,
}

struct FireworkParticle {
	pos_y: f32,
	pos_x: f32,
	velocity_y: f32,
	velocity_x: f32,

	particle_trails: VecDeque<FireworkParticleTrail>,
}

struct FireworkParticleTrail {
	start: Pt,
	end: Pt,
}

impl FireworksState {
	pub fn new() -> Self {
		FireworksState {
			fireworks: Vec::new(),
			time_to_fade_overlay_away_ms: 0,
		}
	}

	pub fn start_animation(&mut self) {
		let mut rng = rand::thread_rng();

		for _ in 0..20 {
			self.fireworks.push(SingleFireworkState::new(&mut rng));
		}

		self.time_to_fade_overlay_away_ms = 3500;
	}

	pub fn update(&mut self, dt_ms: i32) -> bool {
		for firework in self.fireworks.iter_mut() {
			firework.update(dt_ms);
		}
		self.fireworks.retain(|f| f.time_to_fade_away_ms > 0);
		self.time_to_fade_overlay_away_ms -= dt_ms;
		if self.time_to_fade_overlay_away_ms < 0 {
			self.time_to_fade_overlay_away_ms = 0;
			return true;
		}
		return false;
	}

	pub fn in_progress(&self) -> bool {
		self.time_to_fade_overlay_away_ms > 0 || self.fireworks.len() != 0
	}


	pub fn draw(&self, callbacks: &CCallbacksPtr) {

		self.draw_overlay(callbacks);
		for firework in self.fireworks.iter() {
			firework.draw(callbacks);
		}
	}

	fn draw_overlay(&self, callbacks: &CCallbacksPtr) {
		let brightness = 0x7f;
		let brightness = if self.time_to_fade_overlay_away_ms < 1000 {
			brightness * self.time_to_fade_overlay_away_ms / 1000
		} else {
			brightness
		};
		if brightness > 0 {
			let overlay_colour = &format!("#000000{:02x}", brightness);
			callbacks.draw_rect(overlay_colour, 0, 0, CANVAS_HEIGHT, CANVAS_WIDTH);
		}
	}
}

impl SingleFireworkState {
	fn new(rng: &mut rand::rngs::ThreadRng) -> Self {
		let y_start = 0;
		let y_end = CANVAS_HEIGHT - 100;
		let padding_y = 50;
		let padding_x = 10;
		SingleFireworkState {
			time_to_detonate_ms: Some(rng.gen_range(0..1500)),
			time_to_fade_away_ms: 2000,
			time_remaining_to_max_radius_ms: 0,
			pos: Pt { y: rng.gen_range(y_start..y_end), x: rng.gen_range(padding_x..(CANVAS_WIDTH-padding_x))},
			particles: Vec::new(),

			time_to_max_radius_ms: rng.gen_range(500..1000),
			radius: rng.gen_range(100..500),
			segments: rng.gen_range(6..20), // TODO this should be a function of radius, maybe min or max angle
			colour: FIREWORKS_COLOURS[rng.gen_range(0..FIREWORKS_COLOURS.len())],
		}
	}

	fn update(&mut self, dt_ms: i32) {
		if let Some(mut time_to_detonate_ms) = self.time_to_detonate_ms {
			time_to_detonate_ms -= dt_ms;
			if time_to_detonate_ms <= 0 {
				self.time_to_detonate_ms = None;
				self.detonate();
			} else {
				self.time_to_detonate_ms = Some(time_to_detonate_ms);
			}
		} else {
			for particle in self.particles.iter_mut() {
				let prev_pos = Pt { y: particle.pos_y as i32, x: particle.pos_x as i32 };
				particle.update(dt_ms);
				let new_pos = Pt { y: particle.pos_y as i32, x: particle.pos_x as i32 };

				particle.particle_trails.push_back( FireworkParticleTrail {
					start: prev_pos,
					end: new_pos,
				});
				while particle.particle_trails.len() >= MAX_PARTICLE_TRAILS {
					particle.particle_trails.pop_front();
				}
			}
			self.time_to_fade_away_ms -= dt_ms;
		}
	}

	fn detonate(&mut self) {
		for seg_idx in 0..self.segments {
			let speed = (self.radius as f32) / 1000.0;
			let angle = 2.0*std::f32::consts::PI * (seg_idx as f32) / (self.segments as f32);

			let particle = FireworkParticle {
				pos_y: self.pos.y as f32,
				pos_x: self.pos.x as f32,
				velocity_y: speed * angle.cos(),
				velocity_x: speed * angle.sin(),

				particle_trails: VecDeque::new(),
			};
			self.particles.push(particle);
		}
	}

	fn draw(&self, callbacks: &CCallbacksPtr) {
		//if self.particles.len() < 2 {
		//	return;
		//}

		//for i in 0..(self.particles.len()-1) {
		for particle in self.particles.iter() {
		for (idx, trail) in particle.particle_trails.iter().enumerate() {
			let firework_pixel_size = 2;
			 //println!("drawing firework at pos ({} {}) -> ({} {})", trail.start.y, trail.start.x, trail.end.y, trail.end.x);
			let brightness = (MAX_PARTICLE_TRAILS - idx) as f32 / MAX_PARTICLE_TRAILS as f32;
			let brightness = brightness * (0xff as f32);
			let brightness = if brightness < 0.0 { 0.0 } else if brightness > 255.0 { 255.0 } else { brightness };
			let brightness = brightness as i32;
			let brightness = if self.time_to_fade_away_ms < 500 {
				self.time_to_fade_away_ms * brightness / 500
			} else {
				brightness
			};
			let brightness = brightness as u8;
			let colour = format!("{}{:02x}", self.colour, brightness);
			callbacks.draw_line(&colour, firework_pixel_size,
			                    trail.start.y, trail.start.x, trail.end.y, trail.end.x);
			//callbacks.draw_rect(self.colour, 
			//                    trail.start.y, trail.start.x, trail.end.y, trail.end.x);
		}
		}
	}
}

impl FireworkParticle {
	fn update(&mut self, dt_ms: i32) {
		let dt_ms = dt_ms as f32;
		let gravity = -0.2/1000.0;
		let drag = 0.05;

		self.pos_y += self.velocity_y * dt_ms;
		self.pos_x += self.velocity_x * dt_ms;

		self.velocity_y = (self.velocity_y - gravity * dt_ms) * (1.0 - drag);
		self.velocity_x = self.velocity_x * (1.0 - drag);
	}
}
