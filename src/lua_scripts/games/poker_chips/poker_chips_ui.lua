-- Author: Alex Barry (github.com/alexbarry)
local ui = {}

local alexgames = require("alexgames")
local ui_pane_bet_input   = require("games/poker_chips/ui/bet_input")
local ui_pane_control     = require("games/poker_chips/ui/control")
local ui_pane_view_others = require("games/poker_chips/ui/view_others")
local core = require("games/poker_chips/poker_chips_core")

local ui_params = {
	board_height = 480,
	board_width  = 480,
	margin = 20,
	padding             = 5,
	big_padding         = 15,
	BTN_TEXT_SIZE       = 24,
	BTN_BG_COLOUR       = '#ccccffaa',
	BTN_FG_COLOUR       = '#000000',
	BTN_FG_COLOUR_FADED = '#aaaaaa',
	BTN_OUTLINE_COLOUR  = '#000000',
	BTN_OUTLINE_WIDTH   = 1,
	BTN_TEXT_SIZE       = 24,
	info_text_size      = 18,

}

local function add_action(ui_state, action)
	table.insert(ui_state.actions, action)
end

local function init_control_menu()
end

function ui.init()
	local ui_state = {
		panes = {},
		actions = {},
	}

	ui_state.panes.view_others = ui_pane_view_others.init(ui_params, {
		move_to_control_state = function ()
			ui_state.active_state = ui_state.panes.control
		end,
	})

	ui_state.panes.bet_input = ui_pane_bet_input.init(ui_params, {
		move_to_control_state = function ()
			ui_state.active_state = ui_state.panes.control
		end,
		move_to_view_others_state = function ()
			ui_state.active_state = ui_state.panes.view_others
		end,

		add_action = function (action)
			add_action(ui_state, action)
		end,
	})

	ui_state.panes.control   = ui_pane_control.init(ui_params, {
		move_to_raise_state = function ()
			ui_state.active_state = ui_state.panes.bet_input
		end,
		move_to_view_others_state = function ()
			ui_state.active_state = ui_state.panes.view_others
		end,
		add_action = function (action)
			add_action(ui_state, action)
		end,
	})
	ui_state.active_state = ui_state.panes.view_others
	return ui_state
end

function ui.draw(ui_state)
	alexgames.draw_clear()
	ui_state.active_state.draw(ui_state.active_state)
end

function ui.update(ui_state, game_state, player_idx)
	print("ui.update called")
	for _, pane in pairs(ui_state.panes) do
		pane.update(pane, game_state, player_idx)
	end
end

function ui.handle_user_clicked(ui_state, y_pos, x_pos)
	ui_state.active_state.handle_user_clicked(ui_state.active_state, y_pos, x_pos)
	local actions = ui_state.actions
	ui_state.actions = {}
	return actions
end

return ui
