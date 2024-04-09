-- Author: Alex Barry (github.com/alexbarry)
local alexgames  = require("alexgames")
local draw_shapes = require("libs/draw/draw_shapes")

local draw_celebration_anim = require("libs/draw/draw_celebration_anim")
local buttons = require("libs/ui/buttons")

local core = require("games/crossword_letters/crossword_letters_core")

local draw = {}

draw.ACTION_SUBMIT      = 1
draw.ACTION_HINT        = 2
draw.ACTION_NEW_PUZZLE  = 3
draw.ACTION_PREV_PUZZLE = 4
draw.ACTION_NEXT_PUZZLE = 5

local board_width  = 480
local board_height = 480


local BTN_ID_HINT   = "hint"
local BTN_ID_BKSP   = "bksp"
local BTN_ID_SUBMIT = "submit"

local SOFT_BTN_ID_PREV_PUZZLE = "prev_puzzle"
local SOFT_BTN_ID_NEXT_PUZZLE = "next_puzzle"

local SOFT_BTN_WIDTH  = 50
local SOFT_BTN_HEIGHT = 50
local SOFT_BTN_BG_COLOUR      = "#bbbbbb"
local SOFT_BTN_FG_COLOUR      = "#000000"
local SOFT_BTN_OUTLINE_WIDTH  = 2
local SOFT_BTN_TEXT_SIZE      = 12
local padding = 5


local CELL_SIZE    = 25
local PADDING  = 5
local TEXT_PADDING = 5
local CELL_TEXT_SIZE = 16

local crossword_y_offset = CELL_TEXT_SIZE + PADDING

local KEY_TEXT_SIZE = 24

local CELL_BG_COLOUR         = '#0088ee'
local CELL_BG_COLOUR_OUTLINE = '#000000'

KEY_USED_BG_COLOUR           = '#88888888'
KEY_USED_FG_COLOUR           = '#cccccc88'

local CELL_BG_COLOUR_OUTLINE_WIDTH = 2
local CELL_FG_COLOUR         = "#000000"

if alexgames.get_user_colour_pref() == "dark" or 
   alexgames.get_user_colour_pref() == "very_dark" then 
	CELL_BG_COLOUR         = '#002244'
	CELL_BG_COLOUR_OUTLINE = '#666666'
	CELL_BG_COLOUR_OUTLINE_WIDTH = 2
	CELL_FG_COLOUR         = "#888888"

	KEY_USED_BG_COLOUR     = '#111111'
	KEY_USED_FG_COLOUR     = '#333333'

	SOFT_BTN_BG_COLOUR  = "#333333"
	SOFT_BTN_FG_COLOUR  = "#888888"
end

local function get_soft_btn_params(params)
	return {
		id             = params.id,
		text           = params.text,
		bg_colour      = SOFT_BTN_BG_COLOUR,
		fg_colour      = SOFT_BTN_FG_COLOUR,
		outline_colour = SOFT_BTN_FG_COLOUR,
		outline_width  = SOFT_BTN_OUTLINE_WIDTH,
		btn_shape      = buttons.BTN_SHAPE_RECT,
		shape_param    = nil,
		text_size      = SOFT_BTN_TEXT_SIZE,
		padding        = PADDING,
		y_start        = params.y_start,
		x_start        = params.x_start,
		y_end          = params.y_end,
		x_end          = params.x_end,
		callback       = nil,
	}
end


function draw.init(params)
	local ui_state = {
		input_letters = {},
		crossword_width_cells = nil,
		keys_used = {},
		buttons = buttons.new_state(),
		num_puzzles = params.num_puzzles,
	}

	buttons.new_button(ui_state.buttons, get_soft_btn_params({
		id      = SOFT_BTN_ID_PREV_PUZZLE,
		text    = "<",
		y_start = PADDING,
		x_start = PADDING,
		y_end   = PADDING + SOFT_BTN_HEIGHT,
		x_end   = PADDING + SOFT_BTN_WIDTH,
	}))

	buttons.new_button(ui_state.buttons, get_soft_btn_params({
		id      = SOFT_BTN_ID_NEXT_PUZZLE,
		text    = ">",
		y_start = PADDING,
		x_start = board_width - SOFT_BTN_WIDTH,
		y_end   = PADDING + SOFT_BTN_HEIGHT,
		x_end   = board_width - PADDING,
	}))

	ui_state.anim = draw_celebration_anim.new_state({
		on_finish = function()
			alexgames.set_timer_update_ms(0)
		end
	})

	alexgames.create_btn(BTN_ID_HINT,   "Hint",      1)
	alexgames.create_btn(BTN_ID_BKSP,   "Backspace", 2)
	alexgames.create_btn(BTN_ID_SUBMIT, "Submit"   , 2)
	return ui_state
end

local function get_cell_pos(ui_state, y, x)
	local y_offset = CELL_TEXT_SIZE + 2*PADDING
	local x_offset = math.floor((board_width - CELL_SIZE * ui_state.crossword_width_cells)/2)
	local pos = {
		y_start = (y-1) * CELL_SIZE + PADDING + y_offset,
		x_start = (x-1) * CELL_SIZE + PADDING + x_offset,
		y_end   = (y  ) * CELL_SIZE + PADDING + y_offset,
		x_end   = (x  ) * CELL_SIZE + PADDING + x_offset,
	} 
	pos.y_text = pos.y_end - TEXT_PADDING
	pos.x_text = pos.x_start + math.floor((pos.x_end - pos.x_start)/2)
	return pos
end

local function get_letter_size(letters)
	return math.floor(board_width / #letters - TEXT_PADDING)
end

local function get_key_pos(key_idx, letter_size)
	local key_y_start = 15 * CELL_SIZE
	local key_y_end   = board_height - PADDING
	local key_x_start = TEXT_PADDING + (key_idx-1) * (letter_size + PADDING)
	local key_x_end   = key_x_start + letter_size

	local text_y = key_y_start + (key_y_end - key_y_start)/2 + KEY_TEXT_SIZE/2
	local text_x = TEXT_PADDING + (key_idx-1+0.5) * (letter_size + PADDING)

	return {
		y_start = key_y_start,
		y_end   = key_y_end,
		x_start = key_x_start,
		x_end   = key_x_end,
		text_y      = text_y,
		text_x      = text_x,
	}

end

local function get_keys_used_map(ui_state)
	local keys_used_map = {}
	for _, keys_used_idx in ipairs(ui_state.keys_used) do
		keys_used_map[keys_used_idx] = true
	end 

	return keys_used_map
end

function draw.draw_state(ui_state, game_state)
	alexgames.draw_clear()
	if game_state == nil then return end
	local puzzle_id = "?"
	if game_state.puzzle_id ~= nil then
		puzzle_id = game_state.puzzle_id
	end
	local puzzle_id_text = string.format("Puzzle %3s of %3d", puzzle_id, ui_state.num_puzzles)
	alexgames.draw_text(puzzle_id_text, CELL_FG_COLOUR,
	                     CELL_TEXT_SIZE + PADDING, board_width/2,
	                     CELL_TEXT_SIZE,
	                     alexgames.TEXT_ALIGN_CENTRE)
	local show_all = false
	--show_all = true -- TODO DO NOT SUBMIT
	local crossword_grid = core.get_filled_crossword_grid(game_state, show_all)
	ui_state.crossword_width_cells = #crossword_grid

	for y, row in ipairs(crossword_grid) do
		for x, cell in ipairs(row) do
			--print(string.format("drawing cell {y=%2d, x=%2d}, cell=%s", y, x, cell))
			local pos = get_cell_pos(ui_state, y, x)

			-- TODO find a better way to indicate empty cells
			if #cell > 0 then
				if cell == "?" then cell = ' ' end
				--cell = game_state.finished_crossword.grid[y][x]
				alexgames.draw_rect(CELL_BG_COLOUR,
				                     pos.y_start, pos.x_start,
				                     pos.y_end,   pos.x_end)
				draw_shapes.draw_rect_outline(CELL_BG_COLOUR_OUTLINE, CELL_BG_COLOUR_OUTLINE_WIDTH,
				                              pos.y_start, pos.x_start,
				                              pos.y_end,   pos.x_end)
				if cell ~= core.EMPTY then
					cell = string.upper(cell)
					alexgames.draw_text(cell, CELL_FG_COLOUR,
					                     pos.y_text, pos.x_text,
					                     CELL_TEXT_SIZE,
					                     alexgames.TEXT_ALIGN_CENTRE)
				end
			end
		end
	end

	local letter_size = get_letter_size(game_state.letters) 
	local keys_used_map = get_keys_used_map(ui_state)
	for letter_idx, letter in ipairs(game_state.letters) do

		local key_pos = get_key_pos(letter_idx, letter_size)
		local key_bg_colour
		local key_fg_colour

		if keys_used_map[letter_idx] then
			key_bg_colour = KEY_USED_BG_COLOUR
			key_fg_colour = KEY_USED_FG_COLOUR
		else
			key_bg_colour = CELL_BG_COLOUR
			key_fg_colour = CELL_FG_COLOUR
		end

		alexgames.draw_rect(key_bg_colour,
		                     key_pos.y_start, key_pos.x_start,
		                     key_pos.y_end,   key_pos.x_end)

		alexgames.draw_text(string.upper(letter), key_fg_colour,
		                     key_pos.text_y, key_pos.text_x,
		                     KEY_TEXT_SIZE,
		                     alexgames.TEXT_ALIGN_CENTRE)
	end

	local input_display_y_start = 14 * CELL_SIZE
	local input_word = draw.get_word(ui_state)
	input_word = string.upper(input_word)
	alexgames.draw_text(input_word, CELL_FG_COLOUR,
	                     input_display_y_start,
	                     board_width/2,
	                     KEY_TEXT_SIZE,
	                     alexgames.TEXT_ALIGN_CENTRE)

	buttons.draw(ui_state.buttons)

	local dt = 1000/60 -- TODO
	draw_celebration_anim.update(ui_state.anim, dt/1000)
	draw_celebration_anim.draw(ui_state.anim)

	alexgames.draw_refresh()
end

local function get_letter_idx(ui_state, game_state, letter_arg)
	local keys_used_map = get_keys_used_map(ui_state)
	for letter_idx, letter in ipairs(game_state.letters) do
		if keys_used_map[letter_idx] then
			goto next_letter
		end

		if string.lower(letter) == string.lower(letter_arg) then
			return letter_idx
		end

		::next_letter::
	end
end

local function add_to_keys_used_letter_idx(ui_state, game_state, letter_idx)
	local keys_used_map = get_keys_used_map(ui_state)
	if not keys_used_map[letter_idx] then
		table.insert(ui_state.keys_used, letter_idx)
	else
		letter_idx = get_letter_idx(ui_state, game_state, game_state.letters[letter_idx])
		if letter_idx ~= nil then
			table.insert(ui_state.keys_used, letter_idx)
		end
	end
end

local function get_letters_map(game_state)
	local letters_map = {}
	for _, letter in ipairs(game_state.letters) do
		if letters_map[letter] == nil then
			letters_map[letter] = 0
		end
		letters_map[letter] = letters_map[letter] + 1
	end

	return letters_map
end

function draw.input_letter(ui_state, game_state, letter, letter_idx)
	if letter == nil then
		error("draw.input_letter received nil `letter` arg", 2)
	end

	local letters_map = get_letters_map(game_state)


	if letters_map[string.lower(letter)] == nil then
		return core.RC_LETTER_NOT_AVAILABLE
	end

	-- keyboard input doesn't provide an index, but touch/mouse input does
	if letter_idx == nil then
		letter_idx = get_letter_idx(ui_state, game_state, letter)
	end

	if letter_idx == nil then
		return core.RC_LETTER_NOT_AVAILABLE
	end
	table.insert(ui_state.keys_used, letter_idx)

	table.insert(ui_state.input_letters, letter)
	return core.RC_SUCCESS
end

function draw.backspace(ui_state)
	table.remove(ui_state.keys_used)
	table.remove(ui_state.input_letters)
end

function draw.get_word(ui_state)
	local output = ""
	for _, letter in ipairs(ui_state.input_letters) do
		output = output .. letter
	end

	return output
end

function draw.clear_input(ui_state)
	ui_state.input_letters = {}
	ui_state.keys_used     = {}
end

function draw.handle_user_clicked(ui_state, game_state, pos_y, pos_x)
	local btn_id_pressed = buttons.on_user_click(ui_state.buttons, pos_y, pos_x)
	if btn_id_pressed ~= nil then
		if btn_id_pressed == SOFT_BTN_ID_PREV_PUZZLE then
			return draw.ACTION_PREV_PUZZLE
		elseif btn_id_pressed == SOFT_BTN_ID_NEXT_PUZZLE then
			return draw.ACTION_NEXT_PUZZLE
		else
			error(string.format("Unhandled soft button ID \"%s\"", btn_id_pressed))
		end
	end
	local letter_size = get_letter_size(game_state.letters)
	for letter_idx, letter in ipairs(game_state.letters) do
		local key_pos = get_key_pos(letter_idx, letter_size)
		if key_pos.y_start <= pos_y and pos_y <= key_pos.y_end and
		   key_pos.x_start <= pos_x and pos_x <= key_pos.x_end then
			draw.input_letter(ui_state, game_state, letter, letter_idx)
		end
	end
end

function draw.handle_btn_clicked(ui_state, btn_id)
	if btn_id == BTN_ID_SUBMIT then
		return draw.ACTION_SUBMIT
	elseif btn_id == BTN_ID_BKSP then
		draw.backspace(ui_state)
	elseif btn_id == BTN_ID_HINT then
		return draw.ACTION_HINT
	end
end

function draw.handle_popup_btn_clicked(popup_id, btn_id)
end

function draw.player_won(ui_state)
	draw_celebration_anim.fireworks_display(ui_state.anim)
	local dt = 1000/60 -- TODO
	alexgames.set_timer_update_ms(dt)
end

return draw
