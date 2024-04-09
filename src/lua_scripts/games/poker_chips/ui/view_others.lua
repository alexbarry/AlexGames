-- Author: Alex Barry (github.com/alexbarry)
local view_others = {}

local buttons = require("libs/ui/buttons")
local draw_more = require("libs/draw/draw_more")
local alexgames  = require("alexgames")

local core = require("games/poker_chips/poker_chips_core")

local g_ui_params = nil

local BTN_ID_CHOOSE_BET = "choose_bet"

local CURRENT_PLAYER_TEXT_ICON = ">"

local CURRENT_PLAYER_ICON_WIDTH =  20
local PLAYER_NAME_WIDTH         = 175
local PLAYER_ACTION_WIDTH       = 195
local PLAYER_CHIPS_WIDTH        =  50

local function btn_pressed(view_others_state, btn_id)
	if btn_id == BTN_ID_CHOOSE_BET then
		view_others_state.move_to_control_state()
	end
end

local function get_player_status(player_info)
	if player_info.last_action == nil then return ""
	elseif player_info.last_action == core.ACTION_CHECK then return "Check"
	elseif player_info.last_action == core.ACTION_CALL  then return "Call"
	elseif player_info.last_action == core.ACTION_RAISE then return string.format("Raise (+$%s)", player_info.last_bet)
	elseif player_info.last_action == core.ACTION_FOLD  then return "Folded"
	else
		return string.format("Unknown action \"%s\"", player_info.last_action)
	end
		
end

function view_others.init(ui_params, view_others_params)
	g_ui_params = ui_params
	local view_others_state = {
		buttons = buttons.new_state(),
		move_to_control_state = view_others_params.move_to_control_state,
		players = {
--[[
			{ name = "Alex",    action = "Checked",     chips = 135 },
			{ name = "Conor",   action = "Checked",     chips = 205 },
			{ name = "Justin",  action = "Raised +$30", chips =  55 },
			{ name = "Nick",    action = "Called +$30", chips = 175 },
			{ name = "Marc",    action = "Folded",      chips = 100 },
			{ name = "Liam",    action = "",            chips = 335 },
			{ name = "Pranav",  action = "",            chips = 220 },
			{ name = "Shubham", action = "",            chips =  95 },
--]]
		},
		player_turn = 6,
	}

	local button_height = 75

	buttons.new_button(view_others_state.buttons, {
		id              = BTN_ID_CHOOSE_BET,
		text            = "Choose Bet",
		bg_colour       = g_ui_params.BTN_BG_COLOUR,
		fg_colour       = g_ui_params.BTN_FG_COLOUR,
		outline_colour  = g_ui_params.BTN_OUTLINE_COLOUR,
		outline_width   = g_ui_params.BTN_OUTLINE_WIDTH,
		text_size       = g_ui_params.BTN_TEXT_SIZE,
		padding         = g_ui_params.padding,
		y_start         = g_ui_params.board_height - g_ui_params.margin - button_height,
		x_start         = g_ui_params.margin,
		y_end           = g_ui_params.board_height - g_ui_params.margin,
		x_end          = g_ui_params.board_width  - g_ui_params.margin,
		callback       = function (btn_id) btn_pressed(view_others_state, btn_id) end,
	})
	
	view_others_state.draw = function (view_others_state)
		local init_info_offset = g_ui_params.margin + g_ui_params.info_text_size
		local text_size = g_ui_params.info_text_size


		local min_bet_txt = string.format("Minimum Bet: %3d", view_others_state.min_bet)
		alexgames.draw_text(min_bet_txt, g_ui_params.BTN_FG_COLOUR,
		                     init_info_offset, g_ui_params.margin,
		                     text_size, 1)

		local pots_strs = string.format("Pot: %3s", core.get_pot_string(view_others_state.pots))
		alexgames.draw_text(pots_strs, g_ui_params.BTN_FG_COLOUR,
		                     init_info_offset, g_ui_params.board_width - g_ui_params.margin,
		                     text_size, -1)

		if #view_others_state.players == 0 then
			init_info_offset = init_info_offset + text_size + g_ui_params.margin
	
			alexgames.draw_text(string.format("Player count: %d", #view_others_state.players),
			                     g_ui_params.BTN_FG_COLOUR,
			                     init_info_offset, g_ui_params.margin,
			                     text_size, 1)
		end

		buttons.draw(view_others_state.buttons)
		local y_pos = g_ui_params.margin + text_size + init_info_offset
		for i, player_info in ipairs(view_others_state.players) do
			if view_others_state.last_player_min_bet == i then
				local line_y_pos = y_pos - math.floor(g_ui_params.padding/2) - text_size
				draw_more.draw_dashed_line(g_ui_params.BTN_FG_COLOUR, 1, nil, nil,
				                           line_y_pos, g_ui_params.margin,
				                           line_y_pos, g_ui_params.board_width - g_ui_params.margin)
			end 
			local text_colour
			if player_info.folded  then
				text_colour = g_ui_params.BTN_FG_COLOUR_FADED
			else
				text_colour = g_ui_params.BTN_FG_COLOUR
			end
			local x_pos = g_ui_params.margin
			if i == view_others_state.player_turn then
			alexgames.draw_text(CURRENT_PLAYER_TEXT_ICON, text_colour,
			                     y_pos, x_pos, text_size, 1)
			end
			x_pos = x_pos + CURRENT_PLAYER_ICON_WIDTH

			alexgames.draw_text(player_info.name, text_colour,
			                     y_pos, x_pos, text_size, 1)
			x_pos = x_pos + PLAYER_NAME_WIDTH

			if player_info.last_action ~= nil then
				local status = get_player_status(player_info)
				alexgames.draw_text(status, text_colour,
				                     y_pos, x_pos, text_size, 1)
			end
			x_pos = x_pos + PLAYER_ACTION_WIDTH

			x_pos = x_pos + PLAYER_CHIPS_WIDTH
			alexgames.draw_text(string.format("%4d", player_info.chips), text_colour,
			                     y_pos, x_pos, text_size, -1)

			y_pos = y_pos + text_size + g_ui_params.padding
		end
	end

	view_others_state.handle_user_clicked = function (view_others_state, pos_y, pos_x)
		buttons.on_user_click(view_others_state.buttons, pos_y, pos_x)
	end

	view_others_state.update = function (view_others_state, game_state)
		print("Updating view others state...")
		view_others_state.min_bet     = game_state.min_bet
		view_others_state.pots        = game_state.pots
		view_others_state.players     = game_state.players
		view_others_state.player_turn = game_state.player_turn
		view_others_state.last_player_min_bet = game_state.last_player_min_bet
		
	end

	return view_others_state
end

return view_others
