
This is how I've been building (from project root):

	(cd src/rust_games/ && cargo build --target=wasm32-unknown-emscripten) && build/wasm/build.sh -- -j32

I think what I'm doing is mostly okay, once I figure out how to convert the generic
GameState trait into the reversi state.
