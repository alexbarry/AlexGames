local wait_for_players = require("libs/multiplayer/wait_for_players")
local alexgames = require("alexgames")

local core = require("games/card_sim/card_generic_core")
local draw = require("games/card_sim/card_generic_draw")
local serialize = require("games/card_sim/card_generic_serialize")

-- TODO if two players click the same card, then there is a big bug.
-- Need to remember two things when a player picks up a card: 
--    * who is holding the card,
--    * what touch ID (either 'mouse', or the ID from the touch event)
-- Also need to handle something when someone picks up a card... update the card_idx
-- of other players if they were holding that card?
--
-- Also will likely need to implement throttling.
--
-- Ideally would also implement client side control of the cards, so that I could just send 
-- the held card index and coordinates, instead of sending all the state
--
-- TODO I think there is a bug if you pick up a card, move the mouse off screen, then
-- click to pick up the card again, if another player has picked up a card since then?
-- When re-ordering cards, need to update all the player's card_idx.
-- Maybe remember cards by value, not position in array
--
-- TODO there is still an issue if two players pick up a card at the same time
--

local width  = 480
local height = 480

local MAX_MOVE_PERIOD_MS = 50
local throttled_count = 0


local args = {
	width = width,
	height = height,

	player_count = 2,

	card_height    = 70,
	card_width     = 40,
	card_font_size = 16,

	reveal_area = math.floor(height/5),
}

local players = {
	[1] = "You",
}
local player_name_to_idx = {}
local player = 1
local state = nil
local is_client = false


local function send_state_updates_if_host()
	if is_client then
		return
	end

	for i=1,#state.player_states do
		if i == player then
			goto next_player
		end
		local serialized_state = serialize.serialize_state_for_client(state, i)
		alexgames.send_message(players[i], "state:" .. serialized_state)
		::next_player::
	end
end


function draw_board()
	draw.draw(state, player)
end

alexgames.enable_evt("mouse_move")
alexgames.enable_evt("mouse_updown")

function handle_user_clicked(pos_y, pos_x)
end

local last_move_time = nil
function handle_mousemove(pos_y, pos_x)
	local time = alexgames.get_time_ms()
	if last_move_time ~= nil and time - last_move_time < MAX_MOVE_PERIOD_MS then
			throttled_count = throttled_count + 1
		return
	end
	last_move_time = time
	if not is_client then
		core.handle_mousemove(state, player, pos_y, pos_x)
	else
		alexgames.send_message("all", string.format("move:%d,%d,%s,%d,%d", player, 3, 'mouse', pos_y, pos_x))
	end
	send_state_updates_if_host()
	draw_board()
end

function handle_mouse_evt(evt_id, pos_y, pos_x)
	if not is_client then
		core.handle_mouse_evt(state, player, evt_id, pos_y, pos_x)
	else
		alexgames.send_message("all", string.format("move:%d,%d,%s,%d,%d", player, evt_id, 'mouse', pos_y, pos_x))
	end
	send_state_updates_if_host()
	draw_board()
end

local function handle_recvd_move(state, msg_player, msg_evt, msg_y, msg_x)
	if msg_evt == 1 or msg_evt == 2 then
		core.handle_mouse_evt(state, msg_player, msg_evt, msg_y, msg_x)
	elseif msg_evt == 3 then
		core.handle_mousemove(state, msg_player, msg_y, msg_x)
	else
		error("Unhandled evt_id " .. msg_evt)
	end
	send_state_updates_if_host()
	draw_board()
end

function handle_msg_received(src, msg)
	--print("handle_msg_received (from src:" .. src .. "): " .. msg);

	local handled = wait_for_players.handle_msg_received(src, msg)
	if handled then
		return
	end

	local m = msg:gmatch("([^:]+):(.*)")
	local header, payload
	header, payload = m()

	if header == "state" then
		local recvd_state = serialize.deserialize_client_state(payload)
		state = recvd_state
	elseif header == "move" then
		local other_player = player_name_to_idx[src]
		local m2 = payload:gmatch("(%d+),(%d+),([^,]+),(%d+),(%d+)")
		if m2 == nil then
			error("Invalid recvd payload " .. payload)
		end
		local msg_player, msg_evt, msg_input_src, msg_y, msg_x = m2()
		msg_player = tonumber(msg_player)
		msg_evt    = tonumber(msg_evt)
		msg_y      = tonumber(msg_y)
		msg_x      = tonumber(msg_x)
		handle_recvd_move(state, msg_player, msg_evt, msg_y, msg_x)
	elseif header == "player_joined" or
	       header == "player_left" then
		-- ignore I guess?
	else
		error("Unhandled msg: " .. msg)
	end
	draw_board()
end

function handle_popup_btn_clicked(popup_id, btn_idx)
	local handled = wait_for_players.handle_popup_btn_clicked(popup_id, btn_idx)
	if handled then
		return
	end

	error("Unhandled popup_btn_clicked")
end


local function new_game(player_count)
	state = core.init(args)
	draw.init(args)
end

local function start_host_game(players_arg, player_arg, player_name_to_idx_arg)
	print("Starting game as host")
	players = players_arg
	player  = player_arg
	player_name_to_idx = player_name_to_idx_arg
	is_client = false
	new_game(#players)
	send_state_updates_if_host()
	draw_board()
end

local function start_client_game(players_arg, player_arg, player_name_to_idx_arg)
	print("Starting game as client")
	players = players_arg
	player  = player_arg
	player_name_to_idx = player_name_to_idx_arg
	is_client = true
	-- no need to draw board here, a state update should soon follow
end

-- TODO I really don't want to have to serialize all of this...
function handle_touch_evt(evt_id, changed_touches)
	if evt_id == "touchmove" then
		local time = alexgames.get_time_ms()
		if last_move_time ~= nil and time - last_move_time < MAX_MOVE_PERIOD_MS then
			throttled_count = throttled_count + 1
			return
		end
		last_move_time = time
	end
	if not is_client then
		core.handle_touch_evt(state, player, evt_id, changed_touches)
	else
		local moves = core.touches_to_moves(state, player, evt_id, changed_touches)
		for _, move in ipairs(moves) do
			local move_msg = string.format("move:%d,%d,%s,%d,%d",
			                               move.player, move.move_type, move.input_src, move.y, move.x)
			alexgames.send_message("all", move_msg)
		end
	end
	send_state_updates_if_host()
	draw_board()
end


alexgames.enable_evt('touch')

wait_for_players.init(players, player, start_host_game, start_client_game)
draw.init(args)
