--[[
-- This library allows for 0 or more players to join a game hosted by a player.
--
-- It is best suited for games where the players don't need to pick a role (e.g.
-- black or white pieces in a game like chess), they will simply be e.g. "Player 2"
--
--]]

local wait_for_players = {}

local alex_c_api = require("alex_c_api")
local show_buttons_popup = require("libs/ui/show_buttons_popup")

local POPUP_ID_WAITING_FOR_PLAYERS = "waiting_for_players"
-- Only the host can start the game
local POPUP_WAITING_FOR_PLAYERS_HOST_BTNS = {
	"Start game",
}


local players    = nil
local player     = nil
local player_name_to_idx = {}
local is_client  = nil
local start_game_host_func  = nil
local start_game_client_func = nil

function wait_for_players.init(players_arg, player_arg,
                               start_game_host_arg, start_game_client_arg)
                               
	players   = players_arg
	player    = player_arg
	is_client = false
	start_game_host_func = start_game_host_arg
	start_game_client_func = start_game_client_arg 

	alex_c_api.set_status_msg("Waiting for players to join as host")
	wait_for_players.show_waiting_for_players_popup()
	alex_c_api.send_message("all", string.format("joined:"))
end

local function get_vacant_player_spot(players)
	local idx = 1
	while true do
		if players[idx] == nil then
			return idx
		end
		idx = idx + 1
	end
end


function wait_for_players.is_host_tentative()
	return not is_client
end

function wait_for_players.players_tentative()
	print("returning players count ", #players)
	return players
end

function wait_for_players.show_waiting_for_players_popup()
	local body_txt = string.format("Players joined: %d", #players)
	print("Player is %q", player)
	for player_id, player_ip in pairs(players) do
		local more_info = ""
		if player_id == player then
			if is_client then
				more_info = "(you) "
			else
				more_info = "(you, host) "
			end
		end
		print(string.format("Player %d: %s%s", player_id, more_info, player_ip))
		body_txt = body_txt .. string.format("\nPlayer %d: %s%s", player_id, more_info, player_ip)
	end

	local btns = {}
	if is_client then
		body_txt = body_txt .. "\nWaiting for host to start the game"
	else
		btns = POPUP_WAITING_FOR_PLAYERS_HOST_BTNS
	end
	show_buttons_popup.show_popup(POPUP_ID_WAITING_FOR_PLAYERS,
	                      "Waiting for players",
	                      body_txt,
	                      btns)
end

function wait_for_players.handle_popup_btn_clicked(popup_id, btn_idx)
	if popup_id == POPUP_ID_WAITING_FOR_PLAYERS then
		if btn_idx == 0 then
			alex_c_api.send_message("all", "start_game:")
			start_game_host_func(players, player, player_name_to_idx)
			alex_c_api.hide_popup()
			return true
		end
	end
	return false
end

local function become_client_player(player_idx, player_name)
	alex_c_api.set_status_msg(string.format("You are player %d (client), %s", player_idx, player_name))
	is_client = true
	player = player_idx
	players = { [player_idx] = "You" }
	-- I don't remember why I left this comment... it was originally on the 31's game main
	-- TODO call some game31s API to return client state
end


function wait_for_players.handle_msg_received(src, msg)
	local m = msg:gmatch("([^:]+):(.*)")
	local header, payload
	header, payload = m()

	if header == "player" then
		local m = payload:gmatch("(%d+),(.*)")
		local new_player_idx, new_player_name = m()
		become_client_player(tonumber(new_player_idx), new_player_name)
		wait_for_players.show_waiting_for_players_popup()
	elseif header == "clear_players" then
		if is_client then
			print("Clearing players")
			player = nil
			players = {}
		end
	elseif header == "add_player" then
		local m = payload:gmatch("(%d+),(.*)")
		local new_player_idx, new_player_name = m()
		new_player_idx = tonumber(new_player_idx)
		alex_c_api.set_status_msg(string.format("Player %d joined from %s", new_player_idx, new_player_name))
		players[new_player_idx] = new_player_name
		player_name_to_idx[new_player_name] = new_player_idx
		wait_for_players.show_waiting_for_players_popup()
	elseif header == "player_left" then
		if src ~= "ctrl" then
			error("Received 'player_left' message from another player")
			return
		end
		local player_left_name = payload
		local player_left_idx = player_name_to_idx[player_left_name]
		local player_left_msg = string.format("Player %s \"%s\" left", player_left_idx, player_left_name)
		alex_c_api.set_status_msg(player_left_msg)
		if player_left_idx == nil then
			print(string.format("Player leaving \"%s\" is not in players map", player_left_name))
			return
		end
		table.remove(players, player_left_idx)
		player_name_to_idx[player_left_name] = nil

		alex_c_api.send_message("all", "clear_players:")
		-- Must update all players with their number, since
		-- they've changed (if player 2 leaves, player 3 will now be player 2)
		for player_idx,_ in ipairs(players) do
			local player_name = players[player_idx]
			alex_c_api.send_message(player_name, string.format("player:%d,%s", player_idx, player_name))
		end
		for player_idx,_ in ipairs(players) do
			alex_c_api.send_message("all", string.format("add_player:%d,%s", player_idx, players[player_idx]))
		end
		wait_for_players.show_waiting_for_players_popup()
	elseif header == "joined" then
		if not is_client then
			players_joined = get_vacant_player_spot(players)
			local new_player_idx = players_joined
			-- TODO will need to let new players choose their player idx
			players[new_player_idx] = src
			player_name_to_idx[src] = new_player_idx

			-- TODO don't show this if the game has started?
			wait_for_players.show_waiting_for_players_popup()

			alex_c_api.send_message(src, string.format("player:%d,%s", new_player_idx, src))
			for player_id, player_name in pairs(players) do
				if player_id == new_player_idx then
					goto next_player
				end
				if player_name == "You" then
					player_name = "Host"
				end
				alex_c_api.send_message(src, string.format("add_player:%d,%s", player_id, player_name))
				::next_player::
			end
			-- Should loop through existing players and tell only this new one
			-- who else has already joined
			alex_c_api.send_message("all", string.format("add_player:%d,%s", new_player_idx, src))
			alex_c_api.set_status_msg(string.format("Player %d joined from %s", new_player_idx, src))

			-- TODO originally, in 31's, I called this here.
			-- Need to re-examine all this if a game is ongoing...
			-- send_state_updates_if_host()
		end
	elseif header == "start_game" then
		if is_client then
			alex_c_api.hide_popup()
			start_game_client_func(players, player, player_name_to_idx)
		end
	else
		return false
	end

	return true
end

return wait_for_players
