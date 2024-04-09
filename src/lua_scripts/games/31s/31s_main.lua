
local wait_for_players = require("libs/multiplayer/wait_for_players")
local game31s_draw = require("games/31s/31s_draw")
local game31s      = require("games/31s/31s_core")

local alexgames   = require("alexgames")
local show_buttons_popup = require("libs/ui/show_buttons_popup")

local utils = require("libs/utils")

local width = 480
local height = 480

local is_client = false
local players_joined = 1
local g_session_id = nil
local state = nil

-- This is the initial config for the host.
-- Always start off as the host, for now?
-- But someone else says that they're the host, believe them..?
local player = 1

-- player number to src
local players = {
	[1] = "You",
}
local player_name_to_idx = {
}

local BTN_ID_KNOCK = "knock"

local POPUP_ID_GAME_OVER = "game_over"
local POPUP_GAME_OVER_BTNS = {
	"New Game",
}

-- TODO:
--      * draw text near a player who has knocked
--      * highlight player whose move it is
--  * Show your IP address somewhere, or at least let you enter a custom name
--
--  Bugs:
--  * right now if a player joins during a game, it shows the popup message for "waiting for players" and interrupts
--    the game in progress, and prevents it from going forward.
--    This also happens simply if someone refreshes their browser
--     * solution: if someone leaves, ideally we'd have the option to either kick them or wait?
--       and if someone re-joins, they could take their place?
--     * but don't show a popup until it's the missing person's turn?

function init_ui()
	game31s_draw.init_ui(width, height)
	alexgames.create_btn(BTN_ID_KNOCK, "Knock", 1)
end


function update()
	game31s_draw.draw(state, player)
	--game31s.print_state(state)
end

function check_for_winners()
	if state == nil then
		return
	end

	local win_msg = nil

	if #state.winners == state.player_count then
		win_msg = string.format("Tie game. All players have the same score.")
	elseif #state.winners == 1 then
		win_msg = string.format("Player %d wins.", state.winners[1])
	else
		win_msg = string.format("Tie between these players: ")
		for _,winner in ipairs(state.winners) do
			win_msg = win_msg .. string.format("%d ", winner)
		end
	end

	if #state.winners > 0 then
		show_buttons_popup.show_popup(POPUP_ID_GAME_OVER,
		                              "Game over",
		                              "Game over!\n" .. win_msg,
		                              POPUP_GAME_OVER_BTNS
		                              );
	end
end

function handle_user_clicked(y,x)
	local ui_elem = game31s_draw.coords_to_ui_elem(y, x)
	if ui_elem == nil then
		return
	end
	local rc = game31s.SUCCESS
	print(string.format("handle_user_clicked, ui_elem = %d, y = %d, x = %d", ui_elem, y, x))
	if ui_elem == game31s_draw.DECK then
		if not is_client then
			rc = game31s.draw_from_deck(state, player)
		else
			alexgames.send_message("all", string.format("%s:%d,%d", game31s.MSG_DRAW, player, 1))
		end
	elseif ui_elem == game31s_draw.DISCARD then
		if not is_client then
			rc = game31s.draw_from_discard(state, player)
		else
			alexgames.send_message("all", string.format("%s:%d,%d", game31s.MSG_DRAW, player, 2))
		end
	elseif ui_elem == game31s_draw.STAGING_AREA then
		if not is_client then
			rc = game31s.player_discard_staged(state, player)
		else
			alexgames.send_message("all", string.format("%s:%d,%d", game31s.MSG_DISCARD, player, 0))
		end
	elseif ui_elem == game31s_draw.HAND_1 or
	       ui_elem == game31s_draw.HAND_2 or
	       ui_elem == game31s_draw.HAND_3 then
		local card_idx = ui_elem
		if not is_client then
			rc = game31s.player_swap_card(state, player, card_idx)
		else
			alexgames.send_message("all", string.format("%s:%d,%d", game31s.MSG_DISCARD, player, card_idx))
		end
	end
	
	if rc ~= game31s.SUCCESS then
		alexgames.set_status_err(game31s.err_code_to_str(rc))
	end

	update()
	check_for_winners()
	send_state_updates_if_host()
	game31s.print_state(state)
end

function handle_btn_clicked(btn_id)
	if btn_id == BTN_ID_KNOCK then
		if not is_client then
			local rc = game31s.player_knock(state, player)
			if rc == game31s.SUCCESS then
				send_state_updates_if_host()
				update()
			else
				alexgames.set_status_err(game31s.err_code_to_str(rc))
			end
		else
			alexgames.send_message("all", string.format("%s:%d", game31s.MSG_KNOCK, player))
		end
	else
		error("Unexpected button id " .. btn_id)
	end
end

local function start_host_game(players_arg, player_arg, player_name_to_idx_arg)
	players = players_arg
	player  = player_arg
	player_name_to_idx = player_name_to_idx_arg
	is_client = false
	new_game(#players)
	send_state_updates_if_host()
	update()
	game31s.print_state(state)

end

local function start_client_game(players_arg, player_arg, player_name_to_idx_arg)
	players = players_arg
	player  = player_arg
	player_name_to_idx = player_name_to_idx_arg
	is_client = true
end

function handle_popup_btn_clicked(popup_id, btn_idx)
	local handled = wait_for_players.handle_popup_btn_clicked(popup_id, btn_idx)
	if handled then
		return
	end
end


function send_state_updates_if_host()
	if is_client then
		return
	end

	if state == nil then
		return
	end

	for dst_player=1,state.player_count do
		if dst_player == player then
			goto next_player
		end
		local state_msg = "state:" .. game31s.serialize_state_for_client(state, dst_player)
		alexgames.send_message(players[dst_player], state_msg)
		print("Sending state msg: " .. state_msg)
		::next_player::
	end
end

function send_err(rc, other_player)
	if rc ~= game31s.SUCCESS then
		alexgames.send_message("all", string.format("err:%s", game31s.err_code_to_str(rc)))
	end
end

function handle_msg_received(src, msg)
	print("handle_msg_received (from src:" .. src .. "): " .. msg);

	local handled = wait_for_players.handle_msg_received(src, msg)
	if handled then
		return
	end

	local m = msg:gmatch("([^:]+):(.*)")
	local header, payload
	header, payload = m()


	if header == "state" then
		if is_client then
			state = game31s.deserialize_client_state(player, payload)
			print("Recvd state:")
			game31s.print_state(state)
		else
			print("Unexpected state update recvd: we are the host")
		end
	elseif header == game31s.MSG_DRAW then
		if state == nil then
			print("Can not process player move until game has started")
			return
		end
		if is_client then
			print("Unexpected game msg recvd by client")
			return
		end
		local m2 = payload:gmatch("(%d+),(%d+)")
		local other_player, draw_src
		other_player, draw_src = m2()
		other_player = tonumber(other_player)
		draw_src     = tonumber(draw_src)
		if other_player ~= player_name_to_idx[src] then
			local err_msg = (string.format("Received msg to move player %d from " ..
			                               "\"%s\" who is expected to be player %s",
			                               other_player, src, player_name_to_idx[src]))
			alexgames.set_status_err(err_msg)
			return
		end
		if draw_src == 1 then
			local rc = game31s.draw_from_deck(state, other_player)
			send_err(rc, other_player)
		elseif draw_src == 2 then
			local rc = game31s.draw_from_discard(state, other_player)
			send_err(rc, other_player)
		end
	elseif header == game31s.MSG_DISCARD then
		if state == nil then
			print("Can not process player move until game has started")
			return
		end
		if is_client then
			print("Unexpected game msg recvd by client")
			return
		end
		local m2 = payload:gmatch("(%d+),(%d+)")
		local other_player, discard_src
		other_player, discard_src = m2()
		other_player = tonumber(other_player)
		discard_src  = tonumber(discard_src)

		if other_player ~= player_name_to_idx[src] then
			local err_msg = (string.format("Received msg to move player %d from " ..
			                               "\"%s\" who is expected to be player %s",
			                               other_player, src, player_name_to_idx[src]))
			alexgames.set_status_err(err_msg)
			return
		end


		if discard_src == 0 then
			local rc = game31s.player_discard_staged(state, other_player)
			send_err(rc, other_player)
		else
			local rc = game31s.player_swap_card(state, other_player, discard_src)
			send_err(rc, other_player)
		end
	elseif header == "err" then
		alexgames.set_status_err(payload)
	elseif header == game31s.MSG_KNOCK then
		if state == nil then
			print("Can not process player move until game has started")
			return
		end

		local m2 = payload:gmatch("(%d+)")
		local other_player
		other_player = m2()
		other_player = tonumber(other_player)

		if other_player ~= player_name_to_idx[src] then
			local err_msg = (string.format("Received msg to move player %d from " ..
			                               "\"%s\" who is expected to be player %s",
			                               other_player, src, player_name_to_idx[src]))
			alexgames.set_status_err(err_msg)
			return
		end

		if is_client then
			print("Unexpected game msg recvd by client")
		else
			local rc = game31s.player_knock(state, other_player)
			send_err(rc, other_player)
		end
	else
		print(string.format("Unhandled message header \"%s\" from \"%s\"", header, msg))
	end
	send_state_updates_if_host()
	update()
	check_for_winners()
	if not is_client then
		game31s.print_state(state)
		-- only printing this to generate a preview...
		print(string.format("serialized state: %s", utils.binstr_to_hr_str(game31s.serialize_state_for_client(state, player))))
	end
end

function new_game(player_count)
	print(string.format("Starting game with %d players", #players))
	for player_idx,_ in ipairs(players) do
		print(string.format("   %d: %s", player_idx, players[player_idx]))
	end
	state = game31s.new_game(player_count)
	game31s.print_state(state)
	check_for_winners()
end


function start_game(session_id, serialized_state)
	if serialized_state then
		g_session_id = session_id
		state = game31s.deserialize_client_state(player, serialized_state)
	end
	wait_for_players.init(players, player, start_host_game, start_client_game)
	print("... waiting ... ")

	init_ui()
end
