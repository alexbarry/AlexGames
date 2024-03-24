local ui = {}

local core = require("games/blue/blue_core")

local alex_c_api = require("alex_c_api")

ui.UI_STATE_VIEW_OTHER_PLAYERS = 1
ui.UI_STATE_SELECT_PILE        = 2
ui.UI_STATE_SELECT_PIECES      = 3
ui.UI_STATE_SELECT_DISCARDED_PIECES = 4
--ui.UI_STATE_PLACE_PIECES       = 4

ui.ACTION_CHANGE_UI_STATE      = 1
ui.ACTION_SELECT_PILE          = 2
ui.ACTION_SELECT_PIECE         = 3
ui.ACTION_PLACE_PIECE          = 4
ui.ACTION_SELECT_DISCARD_PILE  = 5
ui.ACTION_SELECT_DISCARD_PIECE_COLOUR = 6

function ui.new_state(game_state)
	return {
		game_state = game_state,
		ui_state              = ui.UI_STATE_VIEW_OTHER_PLAYERS,
		selected_pile         = nil,
		selected_piece_colour = nil,
	}
end

local function get_status_msg(state)
	if state.ui_state == ui.UI_STATE_VIEW_OTHER_PLAYERS then
		return "Select the piles when ready"
	elseif state.ui_state == ui.UI_STATE_SELECT_PILE then
		return "Select a pile"
	elseif state.ui_state == ui.UI_STATE_SELECT_PIECES then
		if state.selected_piece_colour == nil then
			return "Select a piece colour"
		else
			return "Select a destination row"
		end
	else
		return nil
	end
end

function ui.handle_action(ui_state, player, action, action_arg_idx)
	-- TODO consider clearing "selected_pile" and "selected_piece_colour" when back button is pressed
	if action == ui.ACTION_CHANGE_UI_STATE then
		ui_state.ui_state = action_arg_idx
		ui_state.selected_pile         = nil
		ui_state.selected_piece_colour = nil
	elseif action == ui.ACTION_SELECT_PILE then
		ui_state.ui_state = ui.UI_STATE_SELECT_PIECES
		ui_state.selected_pile = action_arg_idx
	elseif action == ui.ACTION_SELECT_DISCARD_PILE then
		ui_state.ui_state = ui.UI_STATE_SELECT_DISCARDED_PIECES
		ui_state.selected_pile = nil
	elseif action == ui.ACTION_SELECT_PIECE then
		--ui_state.ui_state = ui.UI_STATE_PLACE_PIECES
		ui_state.selected_piece_colour = action_arg_idx
	elseif action == ui.ACTION_PLACE_PIECE then
		local selected_pile
		if ui_state.ui_state == ui.UI_STATE_SELECT_PIECES then
			selected_pile = ui_state.selected_pile
		elseif ui_state.ui_state == ui.UI_STATE_SELECT_DISCARDED_PIECES then
			selected_pile = core.PILE_DISCARD
		end
		local rc = core.place_piece(ui_state.game_state, player,
		                            selected_pile, ui_state.selected_piece_colour, action_arg_idx)
		if rc == core.RC_SUCCESS then
			ui_state.ui_state              = ui.UI_STATE_VIEW_OTHER_PLAYERS
			ui_state.selected_pile         = nil
			ui_state.selected_piece_colour = nil
		else
			alex_c_api.set_status_err(core.rc_to_string(rc))
			return
		end
	elseif action == ui.ACTION_SELECT_DISCARD_PIECE_COLOUR then
		ui_state.selected_piece_colour = action_arg_idx
		print(string.format("set selected piece colour to %s", ui_state.selected_piece_colour))
	else
		error(string.format("unhandled action %s", action))
	end

	alex_c_api.set_status_msg(get_status_msg(ui_state))
	
end

return ui
