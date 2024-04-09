local core = require("games/crib/crib_core")
local draw = require("games/crib/crib_draw")
local crib_serialize = require("games/crib/crib_serialize")
local alexgames = require("alexgames")

local wait_for_players = require("libs/multiplayer/wait_for_players")


-- TODO next steps:
--  end game when first player reaches 121?
--
--
--  bug fixes:
--      * award a point for last card?
--      * jack of suit? See what other points are missing
--      * check wikipedia page for any behaviour that I missed
--      * for hand {K K 5 5} with {J} as cut_deck_card, there are 8 matches (6 fifteens and 2 pairs).
--        Need to add a separate page or something. 5 can be displayed comfortably


local g_session_id = nil
local state = nil
local players = {
	[1] = "You",
}
local player = 1
local is_client = false
local player_name_to_idx = {}

core.print_state(state)

local ui_state = draw.init(480, 480)

function new_game(player_count)
	g_session_id = alexgames.get_new_session_id()
	state = core.new_game(player_count)
end

function send_state_updates_if_host()
	if is_client then
		return
	end

	if state == nil then
		return
	end

	print("sending state to other players")

	for dst_player, player_name in pairs(players) do
		if dst_player == player then
			goto next_player
		end
		local state_msg = "state:" .. crib_serialize.serialize_client_state(state, dst_player)
		alexgames.send_message(player_name, state_msg)
		::next_player::
	end
end

function draw_board()
	if state == nil then
		return
	end
	if state.state == core.states.PICK_DISCARD and #state.hands[player] ~= core.CARDS_PER_HAND then
		local msg = core.get_discard_status_str(state, player)
		alexgames.set_status_msg(msg)
	else
		-- TODO why is this here?
		print(string.format("Unhandled state %s", state.state))
	end
	draw.draw(state, ui_state, player)
end

function handle_move(action)
	if not is_client then
		local rc = core.handle_move(state, player, action)
		if rc ~= core.RC_SUCCESS then
			alexgames.set_status_err(core.rc_to_str(rc))
		end
	else
		send_move_msg(action)
	end
end

function send_move_msg(action)
	local msg = "move:"..string.format("%d",action.action)
	if action.action == core.actions.HAND then
		msg = msg .. string.format(",%d", action.idx)
	end
	print("Sending message: " .. msg)
	alexgames.send_message("all", msg) -- TODO maybe only message the host
end

function handle_recv_move(src, payload)
	local src_player = player_name_to_idx[src]

	if src_player == nil then
		error(string.format("Unexpected move from non player %s", src_player))
	end

	local m = payload:gmatch("(%d+)(.*)")
	if m == nil then
		error("Expected move message to start with ascii base 10 int")
	end
	local action = {}
	local action_type, data = m()
	action_type = tonumber(action_type)

	action.action = action_type

	if action_type == core.actions.HAND then
		m = data:gmatch(",(%d+)")
		if m == nil then
			error("invalid data" .. data)
		end
		local idx = m()
		action.idx = tonumber(idx)
	elseif action_type == core.actions.DISCARD_CONFIRM then
		-- pass
	elseif action_type == core.actions.CANT_MOVE_ACCEPT then
		-- pass
	elseif action_type == core.actions.NEXT then
		-- pass
	else
		error(string.format("Unhandled action_type %s", action_type))
	end
	core.handle_move(state, src_player, action)
end

function handle_btn_clicked(btn_id)
	local rc = nil
	if btn_id == draw.BTN_ID_DISCARD then
		handle_move({ action = core.actions.DISCARD_CONFIRM })
		alexgames.set_status_msg("Waiting for other players to discard")
	elseif btn_id == draw.BTN_ID_PASS then
		handle_move({ action = core.actions.CANT_MOVE_ACCEPT})
	elseif btn_id == draw.BTN_ID_NEXT then
		handle_move({ action = core.actions.NEXT})
	else
		error(string.format("Unhandled btn_id %s", btn_id))
	end
	draw_board()
	save_state()
	core.print_state(state)
	send_state_updates_if_host()
end

function handle_user_clicked(coord_y, coord_x)
	if state == nil then
		return
	end
	local action = draw.coords_to_action(state, ui_state, player, coord_y, coord_x)
	local rc = nil
	if action.action_type == draw.ACTION_TYPE_GAME then
		if action.action == nil then
			print("No action")
			-- do nothing
		else
			handle_move(action)
		end
	elseif action.action_type == draw.ACTION_TYPE_UI then
		draw.handle_ui_action(ui_state, action)
	end
	draw_board()
	save_state()
	core.print_state(state)
	send_state_updates_if_host()
end

local function start_host_game(players_arg, player_arg, player_name_to_idx_arg)
	print("Starting game as host")
	players = players_arg
	player  = player_arg
	player_name_to_idx = player_name_to_idx_arg
	is_client = false
	if state == nil then
		new_game(#players)
	end
	send_state_updates_if_host()
	draw_board()
	core.print_state(state)
end

local function start_client_game(players_arg, player_arg, player_name_to_idx_arg)
	print("Starting game as client")
	players = players_arg
	player  = player_arg
	player_name_to_idx = player_name_to_idx_arg
	is_client = true
	-- no need to draw board here, a state update should soon follow
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
		if not is_client then
			error("Received state as host")
		end
		print("Received state")
		state = crib_serialize.deserialize_client_state(payload)
		core.print_state(state)
	elseif header == "player_joined" or
	       header == "player_left" then
		-- ignore I guess?
	elseif header == "move" then
		handle_recv_move(src, payload)
	else
		error(string.format("Unhandled message %s", header))
	end

	send_state_updates_if_host()
	draw_board()
	core.print_state(state)
	save_state()
end 

function handle_popup_btn_clicked(popup_id, btn_idx)
	local handled = wait_for_players.handle_popup_btn_clicked(popup_id, btn_idx)
	if handled then
		return
	end
end

function save_state()
	if state == nil then return end
	-- Only the host can save the state
	if not is_client then
		local serialized_state = crib_serialize.serialize_state(state)
		alexgames.save_state(g_session_id, serialized_state)
	end
end


function start_game(session_id, serialized_state)
	-- TODO need to implement load state
	-- which needs proper state serialization for all players (not one client)
	if serialized_state then
		g_session_id = session_id
		state = crib_serialize.deserialize_state(serialized_state, true)
	end
	wait_for_players.init(players, player, start_host_game, start_client_game)
end
