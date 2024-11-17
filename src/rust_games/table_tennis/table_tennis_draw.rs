use std::collections::HashMap;

use crate::table_tennis::table_tennis_core::{State};
use crate::rust_game_api;
use crate::rust_game_api::{TimeMs, CANVAS_HEIGHT, CANVAS_WIDTH};

pub const FPS: i32 = 60;

pub struct TableTennisDraw {
    callbacks: &'static rust_game_api::CCallbacksPtr,
}

impl TableTennisDraw {
    pub fn new(callbacks: &'static rust_game_api::CCallbacksPtr) -> TableTennisDraw {
        let draw = TableTennisDraw {
            callbacks: callbacks,
        };

        draw
    }

    pub fn draw_state(&self, latest_state: &State) {
        self.callbacks.draw_clear();


        self.callbacks.draw_refresh();
    }
}
