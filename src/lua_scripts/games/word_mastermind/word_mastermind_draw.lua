local draw = {}

local alex_c_api = require("alex_c_api")

local core                  = require("games/word_mastermind/word_mastermind_core")

local draw_keyboard         = require("libs/draw/draw_keyboard")
local draw_celebration_anim = require("libs/draw/draw_celebration_anim")
local draw_shapes           = require("libs/draw/draw_shapes")
local show_buttons_popup    = require("libs/ui/show_buttons_popup")

draw.ACTION_NEW_GAME      = 1
draw.ACTION_CUSTOM_PUZZLE = 2

local BTN_ID_CUSTOM_PUZZLE = "custom_puzzle"
local BTN_ID_NEW_GAME      = "new_game"

local POPUP_ID_NEW_GAME_CONFIRM      = "popup_new_game_confirm"
local POPUP_ID_CUSTOM_PUZZLE_CONFIRM = "popup_custom_puzzle_confirm"

local OUTLINE_WIDTH = 1
local CHAR_TEXT_COLOUR          = '#ffffff'
local CHAR_TEXT_COLOUR_UNKNOWN  = '#000000'
local CHAR_BG_COLOUR_POS_KNOWN  = '#008800'
local CHAR_BG_COLOUR_CHAR_KNOWN = '#aaaa00'
local CHAR_BG_COLOUR_UNUSED     = '#444444'
local CHAR_BG_COLOUR_UNKNOWN    = '#ffffff'

if alex_c_api.get_user_colour_pref() == "dark" or 
   alex_c_api.get_user_colour_pref() == "very_dark" then
	CHAR_TEXT_COLOUR          = '#888888'
	CHAR_TEXT_COLOUR_UNKNOWN  = '#888888'
	CHAR_BG_COLOUR_POS_KNOWN  = '#003300'
	CHAR_BG_COLOUR_CHAR_KNOWN = '#333300'
	CHAR_BG_COLOUR_UNUSED     = '#000000'
	CHAR_BG_COLOUR_UNKNOWN    = '#222222'
end

local BG_COLOURS = {
	[core.LETTER_PRESENT_IN_WORD] = CHAR_BG_COLOUR_CHAR_KNOWN,
	[core.LETTER_PRESENT_IN_POS]  = CHAR_BG_COLOUR_POS_KNOWN,
	[core.LETTER_UNUSED]          = CHAR_BG_COLOUR_UNUSED,
	[core.LETTER_UNKNOWN]         = CHAR_BG_COLOUR_UNKNOWN,
}

local FG_COLOURS = {
	[core.LETTER_PRESENT_IN_WORD] = CHAR_TEXT_COLOUR,
	[core.LETTER_PRESENT_IN_POS]  = CHAR_TEXT_COLOUR,
	[core.LETTER_UNUSED]          = CHAR_TEXT_COLOUR,
	[core.LETTER_UNKNOWN]         = CHAR_TEXT_COLOUR_UNKNOWN,
}

local TEXT_SIZE = 32
local padding = 10

-- TODO this might be the first game that requires me to increase the height of the canvas
local board_width = 480
local board_height = 480

local text_start_x = math.floor((board_width - (TEXT_SIZE + padding) * 5)/2)
local big_text_size_y = (TEXT_SIZE + padding) * 6 + 2*padding

function draw.init()
	local draw_state = {
		user_input = {},
		anim = draw_celebration_anim.new_state({
			on_finish = function ()
				alex_c_api.set_timer_update_ms(0)
			end,
		})
	}

	alex_c_api.create_btn(BTN_ID_CUSTOM_PUZZLE, "New Custom Puzzle", 1)
	alex_c_api.create_btn(BTN_ID_NEW_GAME,      "New Game", 1)

	return draw_state
end

local function draw_word(game_state, pos, word, score)

	local padding   = 10

	x_pos = padding
	y_pos = padding + (TEXT_SIZE + padding) * (pos-1)

	local chars = {}
	if word == nil then
		for _=1,game_state.word_len do
			table.insert(chars, " ")
		end
	else
		for i=1,#word do
			table.insert(chars, word:sub(i,i))
		end
	end

	for char_idx, char in ipairs(chars) do
		x_pos = text_start_x + (TEXT_SIZE + padding) * (char_idx-1 + 0.5)
		local bg_colour = CHAR_BG_COLOUR_UNUSED
		local bg_outline_colour = CHAR_TEXT_COLOUR
		local fg_colour = CHAR_TEXT_COLOUR
		if score then
			local char_score = score[char_idx]
			if char_score ~= nil then
				bg_colour = BG_COLOURS[char_score]
			end
			
		end
		if bg_colour == CHAR_BG_COLOUR_UNKNOWN then
			fg_colour = CHAR_TEXT_COLOUR_UNKNOWN
		end
		local rect_y1 = y_pos + padding/2
		local rect_x1 = x_pos - (TEXT_SIZE + padding/2)/2
		local rect_y2 = y_pos + TEXT_SIZE + padding/2
		local rect_x2 = x_pos + (TEXT_SIZE+padding/2)/2
		alex_c_api.draw_rect(bg_colour,
		                     rect_y1, rect_x1,
		                     rect_y2, rect_x2)
		draw_shapes.draw_rect_outline(bg_outline_colour, OUTLINE_WIDTH,
		                              rect_y1, rect_x1,
		                              rect_y2, rect_x2)
		alex_c_api.draw_text(string.upper(char), fg_colour,
		                     y_pos + TEXT_SIZE, x_pos,
		                     math.floor(0.7*TEXT_SIZE),
		                     alex_c_api.TEXT_ALIGN_CENTRE)
	end
end

local function get_key_bg_colours(game_state)
	local bg_colours = {}
	for key, key_state in pairs(game_state.letter_states) do
		if key_state ~= nil then
			bg_colours[key] = BG_COLOURS[key_state]
		end
	end
	return bg_colours
end

local function get_key_fg_colours(game_state)
	local bg_colours = {}
	for key, key_state in pairs(game_state.letter_states) do
		if key_state ~= nil then
			bg_colours[key] = FG_COLOURS[key_state]
		end
	end
	return bg_colours
end


local function get_keyboard_params(game_state)
	return {
		y_start = big_text_size_y,
		x_start = 0,
		y_end   = board_height,
		x_end   = board_width,
		key_bg_colours = get_key_bg_colours(game_state),
		key_bg_colour_default = CHAR_BG_COLOUR_UNKNOWN,
		key_fg_colours = get_key_fg_colours(game_state),
		key_fg_colour_default = CHAR_TEXT_COLOUR_UNKNOWN,
	}
end

function draw.draw_state(ui_state, game_state, dt_ms)
	alex_c_api.draw_clear()
	if game_state == nil then return end
	for i=1,game_state.max_guesses do
		if i <= #game_state.guesses then
			local guess = game_state.guesses[i]
			draw_word(game_state, i, guess.word, guess.score)
		elseif i == 1+#game_state.guesses and #ui_state.user_input > 0 then
			local word = ""
			local score = {}
			for _, c in ipairs(ui_state.user_input) do
				word = word .. c
				table.insert(score, core.LETTER_UNKNOWN)
			end
			while #word < game_state.word_len do
				word = word .. " "
				table.insert(score, core.LETTER_UNUSED)
			end
			draw_word(game_state, i, word, score)
		else
			-- otherwise, draw empty squares
			draw_word(game_state, i, nil)
		end
	end
	draw_keyboard.draw_keyboard(get_keyboard_params(game_state))


	if dt_ms ~= 0 then
		draw_celebration_anim.update(ui_state.anim, dt_ms/1000.0)
	end
	draw_celebration_anim.draw(ui_state.anim)
	alex_c_api.draw_refresh()
end

local function handle_enter(ui_state)
	local word = ""
	for _, c in ipairs(ui_state.user_input) do
		word = word .. c
	end
	return word
end

local function handle_bksp(ui_state)
	table.remove(ui_state.user_input)
end

function draw.handle_user_clicked(ui_state, game_state, pos_y, pos_x)
	if game_state.game_over then
		return
	end
	local keyboard_params = get_keyboard_params(game_state)
	local key_pressed = draw_keyboard.get_key_pressed(keyboard_params, pos_y, pos_x)
	if key_pressed == nil then
		return
	end
	print(string.format("User pressed soft key %s", key_pressed))
	if key_pressed == draw_keyboard.SPECIAL_KEY_ENTER then
		print("user pressed enter!!!")
		return handle_enter(ui_state)
	elseif key_pressed == draw_keyboard.SPECIAL_KEY_BKSP then
		handle_bksp(ui_state)
	elseif #ui_state.user_input < game_state.word_len then
		table.insert(ui_state.user_input, key_pressed)
	end
end

function draw.clear_user_input(ui_state)
	ui_state.user_input = {}
end


function draw.handle_key_evt(ui_state, game_state, evt_id, key_code)
	local key_status = {
		handled    = false,
		guess_word = nil,
	}
	if game_state.game_over then
		return key_status
	end
	if evt_id == "keydown" then
		if key_code == "Enter" then
			key_status.handled = true
			key_status.guess_word = handle_enter(ui_state)
		elseif key_code == "Backspace" then
			key_status.handled = true
			handle_bksp(ui_state)
		else 
			local user_input_letter = string.match(key_code, "Key(%a)")
			if user_input_letter then
				key_status.handled = true
				if #ui_state.user_input < game_state.word_len then
					user_input_letter = string.lower(user_input_letter)
					table.insert(ui_state.user_input, user_input_letter)
				end
			end
		end
	end
	return key_status
end

function draw.player_won(ui_state)
	draw_celebration_anim.fireworks_display(ui_state.anim)
	alex_c_api.set_timer_update_ms(1000/60)
end

function draw.handle_btn_pressed(game_state, ui_state, btn_id)
	if btn_id == BTN_ID_NEW_GAME then
		if game_state and game_state.game_over then
			return draw.ACTION_NEW_GAME
		else
			-- TODO now I definitely need to implement the history browser for this game
			show_buttons_popup.show_popup(POPUP_ID_NEW_GAME_CONFIRM, "Start New Game?",
			                              "Are you sure you want to start a new game?\n" ..
			                              "Current progress can be resumed " ..
			                              "from the \"Load Autosaved Game\" in the options.",
			                              {"New Game", "Cancel"})
		end
	elseif btn_id == BTN_ID_CUSTOM_PUZZLE then
		if game_state and game_state.game_over then
			return draw.ACTION_CUSTOM_PUZZLE
		else
			show_buttons_popup.show_popup(POPUP_ID_CUSTOM_PUZZLE_CONFIRM, "Generate custom puzzle?",
			                              "Are you sure you want to generate a custom puzzle?\n" ..
			                              "Current progress can be resumed " ..
			                              "from the \"Load Autosaved Game\" in the options.",
			                              {"Generate custom puzzle", "Cancel"})
		end
	end
end

function draw.handle_popup_btn_pressed(game_state, ui_state, popup_id, btn_id)
	if popup_id == POPUP_ID_NEW_GAME_CONFIRM then
		alex_c_api.hide_popup()
		if btn_id == 0 then
			return draw.ACTION_NEW_GAME
		elseif btn_id == 1 then
		else
			error(string.format("Unhandled btn_id %d for popup %s", btn_id, popup_id))
		end
	elseif popup_id == POPUP_ID_CUSTOM_PUZZLE_CONFIRM then
		alex_c_api.hide_popup()
		if btn_id == 0 then
			return draw.ACTION_CUSTOM_PUZZLE
		elseif btn_id == 1 then
			alex_c_api.hide_popup()
		else
			error(string.format("Unhandled btn_id %d for popup %s", btn_id, popup_id))
		end
	else
		print(string.format("Popup id %s not handled", popup_id))
	end
end


return draw
