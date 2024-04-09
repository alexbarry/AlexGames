local draw = {}

local alexgames = require("alexgames")

local core = require("games/crossword_builder/crossword_builder_core")

local letter_tiles = require("libs/letter_tiles")

draw.ACTION_SUBMIT = 1

local BTN_ID_SUBMIT = "submit"

local board_height = 480
local board_width  = 480

local GRID_BG_COLOUR = '#000000'
local GRID_LINE_COLOUR = '#888888'
local KEY_BACKGROUND_COLOUR = '#333388'
local COLOUR = '#888888'
local TEXT_SIZE = 18
local TEXT_SIZE_SCORE = 8

if false then
	GRID_BG_COLOUR = '#bb6644'
	GRID_LINE_COLOUR = '#000000'
	KEY_BACKGROUND_COLOUR = '#ee8800'
	COLOUR = '#000000'
else
	GRID_BG_COLOUR = '#bb6644'
	GRID_LINE_COLOUR = '#000000'
	KEY_BACKGROUND_COLOUR = '#ff8800'
	COLOUR = '#000000'
end


local padding = 5


local function get_large_piece_params()
	return {
		size            = 45,
		main_text_size  = 20,

		text_colour     = COLOUR,
		outline_colour  = COLOUR,
		background_colour = KEY_BACKGROUND_COLOUR,
		line_width      = 1,

		score_text_size =  8,
		padding_small   =  2,
		padding         = 5,

		show_score      = true,
		get_letter_points = core.get_letter_points,
	}
end

local function get_board_piece_params()
	return {
		size            = 23,
		main_text_size  = 18,

		outline_colour  = COLOUR,
		text_colour     = COLOUR,
		background_colour = KEY_BACKGROUND_COLOUR,

		highlight_colour = '#ffff00',
		highlight_width  = 2,

		score_text_size =  8,
		padding_small   =  2,
		padding         = 5,

		line_width      = 2,

		show_score      = false,
		--get_letter_points = core.get_letter_points,
	}
end


local KEY_WIDTH = 50
local KEY_HEIGHT = KEY_WIDTH

local KEY_POS_Y = board_height - get_large_piece_params().size + padding

function draw.init(game_state)
	local draw_state = {
		tiles = nil,
	}

	draw_state.tiles = letter_tiles.new_state({
		--touch_cursor_offset_y = -50,
		--touch_cursor_offset_x = 50,
		touch_cursor_offset_y = -65,
		--touch_cursor_offset_y = -45,
		touch_cursor_offset_x = 0,
	})
	letter_tiles.add_letter_row(draw_state.tiles, game_state.players[1].letters, { y = KEY_POS_Y, x = 480/2 }, get_large_piece_params())
	local y_count = game_state.grid_size_y
	local x_count = game_state.grid_size_x
	letter_tiles.add_grid(draw_state.tiles, {
		y_pos   = padding,
		x_pos   = math.floor(board_width - letter_tiles.get_grid_y_size(y_count, get_board_piece_params()))/2,
		y_count = y_count,
		x_count = x_count,
		bg_colour   = GRID_BG_COLOUR,
		line_colour = GRID_LINE_COLOUR,
		tile_params = get_board_piece_params(),
	})

	alexgames.create_btn(BTN_ID_SUBMIT, "Submit", 1)
	print("hello world")
	alexgames.set_btn_enabled(BTN_ID_SUBMIT, false)

	--draw_state.tiles.grids[1].tiles[2][1] = "F"
	--draw_state.tiles.grids[1].tiles[2][2] = "A"
	--draw_state.tiles.grids[1].tiles[2][3] = "C"
	--draw_state.tiles.grids[1].tiles[2][4] = "E"
	--draw_state.tiles.grids[1].tiles[2][5] = "D"
	return draw_state
end


function draw.draw(draw_state)
	alexgames.draw_clear()

	local params = get_large_piece_params()

	letter_tiles.draw(draw_state.tiles)

--[[
	local words = words_lib.get_words_made_from_letters(LANGUAGE, letters, 3, -1)

	for _, word in ipairs(words) do
		local freq = words_lib.get_word_freq(LANGUAGE, word)
		print(string.format("%-8s, %e", word, freq))
	end
--]]


	alexgames.set_btn_enabled(BTN_ID_SUBMIT, #draw_state.tiles.placed_tiles > 0)
	alexgames.draw_refresh()

end

function draw.handle_mouse_evt(draw_state, evt_id, pos_y, pos_x, params)
	letter_tiles.handle_mouse_evt(draw_state.tiles, evt_id, pos_y, pos_x, params)
end

function draw.handle_mousemove(draw_state, pos_y, pos_x, params)
	letter_tiles.handle_mousemove(draw_state.tiles, pos_y, pos_x, params)
end

function draw.handle_touch_evt(draw_state, evt_id, changed_touches)
	touch_to_mouse_evts.handle_touch_evt(draw_state.touch_to_mouse_evts, evt_id, changed_touches)
end

function draw.handle_btn_clicked(draw_state, btn_id)
	if btn_id == BTN_ID_SUBMIT then
		return draw.ACTION_SUBMIT
	end
end

function draw.get_placed_tiles(draw_state)
	return letter_tiles.get_placed_tiles(draw_state.tiles)
end


function draw.update_state(draw_state, game_state)
	letter_tiles.clear_placed_tiles(draw_state.tiles)
	letter_tiles.set_grid(draw_state.tiles, 1, game_state.grid)
	letter_tiles.set_row(draw_state.tiles, 1, game_state.players[1].letters)
end

return draw
