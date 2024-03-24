local core = {}

core.ACTION_CHECK = "check"
core.ACTION_CALL  = "call"
core.ACTION_RAISE = "raise"
core.ACTION_FOLD  = "fold"

core.RC_SUCCESS       =  0
core.RC_BET_TOO_SMALL = -1

function core.action_to_string(action)
	if action.action == core.ACTION_RAISE then
		return string.format("(%s: %d)", action.action, action.param)
	else
		return string.format("(%s)", action.action)
	end
end

function core.rc_to_string(rc)
	local rc_strings = {
		[core.RC_SUCCESS]       = "Success",
		[core.RC_BET_TOO_SMALL] = "Bet too small",
	}
	return rc_strings[rc]
end

function core.add_player(state, name, chips)
	local player_state = {
		name   = name,
		chips  = chips,
		bet    = 0,
		folded = false,

		-- To be displayed in UI
		last_action = nil,
		last_bet    = nil,
	}
	table.insert(state.players, player_state)
end

function core.get_pot_string(pots)
	if #pots == 0 then return "0"
	else
		-- TODO This is a placeholder.
		-- I don't think it will actually be a list of integers like this,
		-- but I don't know what it will look like yet.
		-- I assume each side pot would need a list of players eligible to receive it.
		-- I don't actually know the rules... if someone goes all-in and creates a side pot, and wins,
		-- who gets the other pots? Are they returned?
		local s = ""
		if #pots > 1 then s = s .. "{" end
		for pot_idx, pot in ipairs(pots) do
			if pot_idx ~= 1 then
				s = s .. ', '
			end
			s = s .. pot
		end
		if #pots > 1 then s = s .. "}" end
		return s
	end
end

function core.new_state()
	local state = {
		pots        = {0},
		players     = {},
		min_bet     = 0,
		player_turn = 1,
		last_player_min_bet = nil,
	}

	return state
end

function core.print_state(state)
	print(string.format("players (len: %d) = {", #state.players))
	for player_idx, player_state in ipairs(state.players) do
		print(string.format("[%d] = { name: \"%s\", chips: %d, bet: %d, folded: %s }",
		                    player_idx, player_state.name,
		                    player_state.chips, player_state.bet, player_state.folded))
	end
	print("}")
end

local function get_player_name(state, player_idx)
	if state.players[player_idx] == nil then
		error(string.format("Player %s not found", player_idx), 2)
	end

	return string.format("%d (\"%s\")", player_idx, state.players[player_idx].name)
end

local function handle_player_bet(state, player_idx, bet)
	print(string.format("Player %s making bet %d", get_player_name(state, player_idx), bet))
	
	local action
	if bet < state.min_bet then
		return core.RC_BET_TOO_SMALL
	elseif bet == 0 then
		action = core.ACTION_CHECK
	elseif bet == state.min_bet then
		action = core.ACTION_CALL
	elseif bet > state.min_bet then
		action = core.ACTION_RAISE
	else
		-- I don't think this is possible unless bet is negative or something
		error(string.format("could not handle bet=%s, state.min_bet=%s", bet, state.min_bet))
	end

	local player_state = state.players[player_idx]
	local bet_increase = bet -- TODO should change this to "bet_increase"?
	player_state.bet         = player_state.bet + bet
	player_state.chips       = player_state.chips - bet
	player_state.last_action = action
	player_state.last_bet    = bet

	state.min_bet = bet
	-- TODO figure out how to handle side pots
	print(string.format("pots: %d, %s", #state.pots, state.pots))
	state.pots[1] = state.pots[1] + bet_increase
	if action == core.ACTION_RAISE then
		state.last_player_min_bet = player_idx
	end

	return core.RC_SUCCESS
end

local function next_player(state)
	print(string.format("Advancing to next player, after player %s", get_player_name(state, state.player_turn)))

	for _=1,#state.players do
		state.player_turn = (state.player_turn % #state.players) + 1

		if state.players[state.player_turn].folded then
			print(string.format("Skipping player %d (%s), as they folded",
			                    state.player_turn, state.players[state.player_turn].name))
			goto next_player
		else
			break
		end

		::next_player::
	end
	if state.players[state.player_turn].folded then
		-- TODO handle case where everyone has folded
	end
	print(string.format("Now it is player's turn: %s", get_player_name(state, state.player_turn)))

	-- TODO need something to call attention to the case where everyone has bet,
	-- to tell dealer to draw another card
end

function core.handle_action(state, action)
	if action.action == core.ACTION_CHECK then
		local rc = handle_player_bet(state, state.player_turn, 0)
		if rc ~= core.RC_SUCCESS then
			return rc
		end
		next_player(state)
	elseif action.action == core.ACTION_CALL then
		local rc = handle_player_bet(state, state.player_turn, state.min_bet)
		if rc ~= core.RC_SUCCESS then
			return rc
		end
		next_player(state)
	elseif action.action == core.ACTION_RAISE then
		local bet = action.param
		local rc = handle_player_bet(state, state.player_turn, bet)
		if rc ~= core.RC_SUCCESS then
			return rc
		end
		next_player(state)
	elseif action.action == core.ACTION_FOLD then
		print(string.format("Player %s has folded", get_player_name(state, state.player_turn)))
		state.players[state.player_turn].folded = true
		state.players[state.player_turn].last_action = core.ACTION_FOLD
		state.players[state.player_turn].last_bet    = 0
		next_player(state)
	else
		error(string.format("Unhandled action type %s", action.action))
		-- TODO notify remote player (client)
	end

	return core.RC_SUCCESS
end

return core
