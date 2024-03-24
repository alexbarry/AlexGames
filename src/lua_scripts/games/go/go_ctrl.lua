local go_ctrl = {}
-- This file should contain the state for things like deciding
-- if players have been chosen yet (whether the player choice UI should be shown),
-- and what player you are

function go_ctrl.new_state()
	return {
		player_choice = nil,
		other_player_choice = nil,
	}
end

function go_ctrl.player_chosen(ctrl_state, player_idx)
	print(string.format("Storing player choice of %q", player_idx))
	ctrl_state.player_choice = player_idx
end

function go_ctrl.other_player_chosen(ctrl_state, player_idx)
	ctrl_state.other_player_choice = player_idx
end

function go_ctrl.get_player(ctrl_state)
	return ctrl_state.player_choice
end

function go_ctrl.get_other_player(ctrl_state)
	return ctrl_state.other_player_choice
end

return go_ctrl
