-- Author: Alex Barry (github.com/alexbarry)
local bet_input = {}

local soft_numpad = require("libs/ui/soft_numpad")
local buttons = require("libs/ui/buttons")

local core = require("games/poker_chips/poker_chips_core")

local alexgames  = require("alexgames")


local g_ui_params = nil

local BTN_ID_ADJ_MINUS_5 = "adjust_minus5"
local BTN_ID_ADJ_MINUS_1 = "adjust_minus1"
local BTN_ID_ADJ_PLUS_1  = "adjust_plus1"
local BTN_ID_ADJ_PLUS_5  = "adjust_plus5"

local BTN_ID_SUBMIT_BET  = "submit_bet"
local BTN_ID_BACK        = "back"

BTN_ADJ_ID_TO_AMOUNT = {
	[BTN_ID_ADJ_MINUS_5] = -5,
	[BTN_ID_ADJ_MINUS_1] = -1,
	[BTN_ID_ADJ_PLUS_1]  =  1,
	[BTN_ID_ADJ_PLUS_5]  =  5,
}

local function get_numpad_val(numpad_val)
	if #numpad_val == 0 then return 0
	else
		return tonumber(numpad_val)
	end
end

local function adjust_bet(bet_input_state, inc)
	local bet_val = get_numpad_val(soft_numpad.get_val(bet_input_state.numpad))
	bet_val = tonumber(bet_val) + inc
	-- TODO need to get numpad val, or update numpad val here
	if bet_val < 0 then
		bet_val = 0
	elseif bet_val > bet_input_state.max_bet then
		bet_val = bet_input_state.max_bet
	end

	soft_numpad.set_val(bet_input_state.numpad, bet_val)
end

local function new_button(buttons_state, params)
	if params.callback == nil then
		error(string.format("missing callback"), 2)
	end
	buttons.new_button(buttons_state, {
		id             = params.id,
		text           = params.text,
		bg_colour      = g_ui_params.BTN_BG_COLOUR,
		fg_colour      = g_ui_params.BTN_FG_COLOUR,
		outline_colour = g_ui_params.BTN_OUTLINE_COLOUR,
		outline_width  = g_ui_params.BTN_OUTLINE_WIDTH,
		btn_shape      = params.btn_shape,
		shape_param    = params.shape_param,
		text_size      = g_ui_params.BTN_TEXT_SIZE,
		padding        = g_ui_params.padding,
		y_start        = params.y_start,
		x_start        = params.x_start,
		y_end          = params.y_end,
		x_end          = params.x_end,
		callback       = params.callback,

	})
end


local function bet_input_button_pressed(bet_input_state, btn_id)
	if BTN_ADJ_ID_TO_AMOUNT[btn_id] then
		local inc = BTN_ADJ_ID_TO_AMOUNT[btn_id]
		adjust_bet(bet_input_state, inc)
	elseif btn_id == BTN_ID_SUBMIT_BET then
		bet_input_state.add_action({
			action              = core.ACTION_RAISE,
			param               = get_numpad_val(soft_numpad.get_val(bet_input_state.numpad)),
			on_success_callback = function () 
				soft_numpad.set_val(bet_input_state.numpad, "")
				bet_input_state.move_to_view_others_state()	
			end,
			})
	elseif btn_id == BTN_ID_BACK then
		bet_input_state.move_to_control_state()
	end
	bet_input_state.draw(bet_input_state)
end

function bet_input.init(ui_params, bet_input_params)
	g_ui_params = ui_params
	top_info_height = 50
	num_button_rows = 7
	local button_y_size = math.floor((g_ui_params.board_height - 2*g_ui_params.margin - top_info_height - g_ui_params.big_padding)/num_button_rows)
	
	local BACK_BUTTON_WIDTH = 135

	local ADJUST_BUTTON_Y_START = g_ui_params.margin + top_info_height
	local CENTRE_MONEY_INDICATOR_WIDTH = 150
	local CENTRE_MONEY_INDICATOR_X_MIDDLE = math.floor(g_ui_params.board_width/2)
	local ADJUST_BUTTON_HEIGHT = 75
	local ADJUST_BUTTON_HEIGHT = button_y_size
	
	local BET_BUTTON_HEIGHT = button_y_size
	
	
	local NUMPAD_Y_START     = ADJUST_BUTTON_Y_START + ADJUST_BUTTON_HEIGHT + g_ui_params.big_padding
	local NUMPAD_Y_END       = g_ui_params.board_height - g_ui_params.margin - BET_BUTTON_HEIGHT
	
	
	local BTN_SUBMIT_BET_Y_START = NUMPAD_Y_END + g_ui_params.padding
	local BTN_SUBMIT_BET_Y_END   = g_ui_params.board_height - g_ui_params.margin

	local bet_input_state = {
		-- TODO
		max_bet = 100,
		chips   = 135,
		pots     =  {30},
		move_to_control_state     = bet_input_params.move_to_control_state,
		move_to_view_others_state = bet_input_params.move_to_view_others_state,
		add_action                = bet_input_params.add_action,
	}
	bet_input_state.numpad = soft_numpad.init({
		y_start = NUMPAD_Y_START,
		y_end   = NUMPAD_Y_END,

		x_start = g_ui_params.margin,
		x_end   = g_ui_params.board_width - g_ui_params.margin,

		btn_bg_colour  = g_ui_params.BTN_BG_COLOUR,
		btn_fg_colour  = g_ui_params.BTN_FG_COLOUR,
		outline_colour = g_ui_params.BTN_OUTLINE_COLOUR,
		outline_width  = g_ui_params.BTN_OUTLINE_WIDTH,
	})

	local callback = function (btn_id)
		bet_input_button_pressed(bet_input_state, btn_id)
	end

	local adjust_button_width = math.floor((g_ui_params.board_width-2*g_ui_params.margin - CENTRE_MONEY_INDICATOR_WIDTH)/4)
	bet_input_state.buttons = buttons.new_state()

	new_button(bet_input_state.buttons, {
		id   = BTN_ID_BACK,
		text = 'Back',
		y_start = g_ui_params.margin,
		y_end   = g_ui_params.margin + top_info_height - g_ui_params.padding,
		x_start = g_ui_params.margin,
		x_end   = g_ui_params.margin + BACK_BUTTON_WIDTH,

		callback    = callback,
	})

	--buttons.new_button(bet_input_state.buttons, {
	new_button(bet_input_state.buttons, {
		id   = BTN_ID_ADJ_MINUS_5,
		text = '-5',
		y_start = ADJUST_BUTTON_Y_START,
		y_end   = ADJUST_BUTTON_Y_START + ADJUST_BUTTON_HEIGHT,
		x_start = g_ui_params.margin,
		x_end   = g_ui_params.margin + adjust_button_width,

		btn_shape   = buttons.BTN_SHAPE_TRIANGLE,
		shape_param = true,
		callback    = callback,
	})
	new_button(bet_input_state.buttons, {
		id   = BTN_ID_ADJ_MINUS_1,
		text = '-1',
		y_start = ADJUST_BUTTON_Y_START,
		y_end   = ADJUST_BUTTON_Y_START + ADJUST_BUTTON_HEIGHT,
		x_start = g_ui_params.margin + adjust_button_width + g_ui_params.padding,
		x_end   = g_ui_params.margin + 2*adjust_button_width + g_ui_params.padding,

		btn_shape   = buttons.BTN_SHAPE_TRIANGLE,
		shape_param = true,
		callback    = callback,
	})
	new_button(bet_input_state.buttons, {
		id   = BTN_ID_ADJ_PLUS_1,
		text = '+1',
		y_start = ADJUST_BUTTON_Y_START,
		y_end   = ADJUST_BUTTON_Y_START + ADJUST_BUTTON_HEIGHT,
		x_start = g_ui_params.board_width - g_ui_params.margin - 2*adjust_button_width - 2*g_ui_params.padding,
		x_end   = g_ui_params.board_width - g_ui_params.margin -   adjust_button_width - 2*g_ui_params.padding,

		btn_shape   = buttons.BTN_SHAPE_TRIANGLE,
		shape_param = false,
		callback    = callback,
	})
	new_button(bet_input_state.buttons, {
		id   = BTN_ID_ADJ_PLUS_5,
		text = '+5',
		y_start = ADJUST_BUTTON_Y_START,
		y_end   = ADJUST_BUTTON_Y_START + ADJUST_BUTTON_HEIGHT,
		x_start = g_ui_params.board_width - g_ui_params.margin - adjust_button_width - g_ui_params.padding,
		x_end   = g_ui_params.board_width - g_ui_params.margin - 0*adjust_button_width - g_ui_params.padding,

		btn_shape   = buttons.BTN_SHAPE_TRIANGLE,
		shape_param = false,
		callback    = callback,
	})

	new_button(bet_input_state.buttons, {
		id   = BTN_ID_SUBMIT_BET,
		text = 'Submit bet',
		y_start = BTN_SUBMIT_BET_Y_START,
		y_end   = BTN_SUBMIT_BET_Y_END,
		x_start = g_ui_params.margin,
		x_end   = g_ui_params.board_width - g_ui_params.margin,
		callback    = callback,
	})
	bet_input_state.draw = function (bet_input_state)
		soft_numpad.draw(bet_input_state.numpad)
		buttons.draw(bet_input_state.buttons)
		local numpad_val = get_numpad_val(soft_numpad.get_val(bet_input_state.numpad))
		local bet_val_str = string.format("$%s", numpad_val)
		local text_size = 18
		local text_y_start = math.floor(ADJUST_BUTTON_Y_START + ADJUST_BUTTON_HEIGHT/2 + text_size/2)
		alexgames.draw_text(bet_val_str, '#000000', text_y_start, CENTRE_MONEY_INDICATOR_X_MIDDLE, text_size, 0)
		alexgames.draw_text(string.format("Your chips: $%d", bet_input_state.chips), '#000000',
		                     g_ui_params.margin + text_size, g_ui_params.margin + BACK_BUTTON_WIDTH + g_ui_params.padding, text_size, 1)
		alexgames.draw_text(string.format("Pot: %s", core.get_pot_string(bet_input_state.pots)), '#000000',
		                     g_ui_params.margin + text_size, g_ui_params.board_width - g_ui_params.margin, text_size, -1)
	end
	bet_input_state.handle_user_clicked = function(bet_input_state, y_pos, x_pos)
		soft_numpad.on_user_click(bet_input_state.numpad, y_pos, x_pos)
		buttons.on_user_click(bet_input_state.buttons, y_pos, x_pos)
	end

	bet_input_state.update = function (bet_input_state, game_state, player_idx)
		print(string.format("bet_input_state(player_idx=%d)", player_idx))
		bet_input_state.max_bet = game_state.players[player_idx].chips
		bet_input_state.chips   = game_state.players[player_idx].chips
		bet_input_state.pots    = game_state.pots
	end
	return bet_input_state
end

return bet_input
