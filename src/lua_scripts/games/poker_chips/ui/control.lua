-- Author: Alex Barry (github.com/alexbarry)
local control = {}

local buttons = require("libs/ui/buttons")
local alex_c_api  = require("alex_c_api")

local core = require("games/poker_chips/poker_chips_core")

local BTN_ID_VIEW_OTHERS_CHIPS = "view_others_chips"
local BTN_ID_CHECK  = "check"
local BTN_ID_CALL   = "call"
local BTN_ID_RAISE  = "raise"
local BTN_ID_FOLD   = "fold"

local g_ui_params = nil

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
		padding        = padding,
		y_start        = params.y_start,
		x_start        = params.x_start,
		y_end          = params.y_end,
		x_end          = params.x_end,
		callback       = params.callback,

	})
end

local function btn_pressed(control_state, btn_id)
	if btn_id == BTN_ID_VIEW_OTHERS_CHIPS then
		control_state.move_to_view_others_state()
	elseif btn_id == BTN_ID_CHECK then
		control_state.move_to_view_others_state()
		control_state.add_action({ action = core.ACTION_CHECK })
	elseif btn_id == BTN_ID_CALL then
		control_state.move_to_view_others_state()
		control_state.add_action({ action = core.ACTION_CALL })
	elseif btn_id == BTN_ID_RAISE then
		control_state.move_to_raise_state()
	elseif btn_id == BTN_ID_FOLD then
		control_state.move_to_view_others_state()
		control_state.add_action({ action = core.ACTION_FOLD })
	end
end

local function set_game_state(control_state, game_state, player_idx)
	buttons.set_enabled(control_state.buttons, BTN_ID_CHECK, game_state.min_bet == 0)
	buttons.set_enabled(control_state.buttons, BTN_ID_CALL,  game_state.min_bet > 0)
	local call_text = "Call"
	if game_state.min_bet > 0 then
		call_text = call_text .. string.format(" (+$%d)", game_state.min_bet)
	end
	buttons.set_text(control_state.buttons, BTN_ID_CALL, call_text)
end

function control.init(ui_params, control_params)
	g_ui_params = ui_params
	local control_state = {}
	control_state.buttons = buttons.new_state()
	control_state.move_to_raise_state       = control_params.move_to_raise_state
	control_state.move_to_view_others_state = control_params.move_to_view_others_state 
	control_state.add_action                = control_params.add_action

	local callback = function (btn_id) btn_pressed(control_state, btn_id) end
	local btn_infos = {
		{ id = BTN_ID_VIEW_OTHERS_CHIPS, text = 'View others\' chips', extra_space = g_ui_params.big_padding },
		{ id = BTN_ID_CHECK,             text = 'Check' },
		{ id = BTN_ID_CALL,              text = 'Call'  },
		{ id = BTN_ID_RAISE,             text = 'Raise' },
		{ id = BTN_ID_FOLD,              text = 'Fold'  },
	}
	local y_pos = 100
	local button_height = math.floor((g_ui_params.board_height - y_pos - g_ui_params.big_padding) / 5) - g_ui_params.padding
	for btn_idx, btn_info in ipairs(btn_infos) do
		new_button(control_state.buttons, {
			id   = btn_info.id,
			text = btn_info.text,
			y_start = y_pos,
			y_end   = y_pos + button_height,
			x_start = g_ui_params.margin,
			x_end   = g_ui_params.board_width - g_ui_params.margin,
			callback    = callback,
		})
		y_pos = y_pos + button_height + g_ui_params.padding
		if btn_info.extra_space ~= nil then
			y_pos = y_pos + btn_info.extra_space
		end
	end

	control_state.draw = function (control_state)
		buttons.draw(control_state.buttons)
	end

	control_state.handle_user_clicked = function (control_state, y_pos, x_pos)
		buttons.on_user_click(control_state.buttons, y_pos, x_pos)
	end

	control_state.update = function (control_state, game_state, player_idx)
		set_game_state(control_state, game_state, player_idx)
	end

	return control_state
end

return control
