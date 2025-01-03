local two_player = require("libs/multiplayer/two_player")
local utils      = require("libs/utils")

local core       = require("games/checkers/checkers_core")
local draw       = require("games/checkers/checkers_draw")
local serialize  = require("games/checkers/checkers_serialize")

local alexgames = require("alexgames")
local alexgames_ai = require("alexgames.ai")

local height = 480
local width  = 480

draw.init(height, width)

local local_multiplayer = nil
local player_name_to_id = {}
local player = nil
local g_other_player = nil
local session_id = alexgames.get_new_session_id()
local state = core.new_state()
local g_ai = nil
local g_ai_iters_remaining = 0
--local g_ai_iters_per_move = 10000
local g_ai_iters_per_move = 3

-- Could reduce this to like 12 if there is no real animation,
-- it sets how many breaks we take between running AI processing, to avoid
-- blocking the UI thread
local FPS = 60
local MS_PER_FRAME = 1000/FPS

local GAME_OPTION_NEW_GAME = "game_option_new_game"

local BTN_ID_UNDO = "btn_undo"
local BTN_ID_REDO = "btn_redo"

-- Testing double jump logic and with a king
--[[
state.board = {
    {1,0,1,0,1,0,1,0,},
    {0,1,0,1,0,1,0,1,},
    {1,0,0,0,0,0,1,0,},
    {0,0,0,0,0,1,0,0,},
    {2,0,2,0,0,0,0,0,},
    {0,2,0,0,0,2,0,2,},
    {2,0,2,0,2,0,2,0,},
    {0,3,0,0,0,2,0,2,},
}
]]

function update()
	process_ai()
	draw.update(state)
	alexgames.set_btn_enabled(BTN_ID_UNDO, alexgames.has_saved_state_offset(session_id, -1))
	alexgames.set_btn_enabled(BTN_ID_REDO, alexgames.has_saved_state_offset(session_id,  1))
end

local function get_player()
	if local_multiplayer then
		return state.player_turn
	else
		return player
	end
end

function handle_user_clicked(coord_y, coord_x)
	local piece = draw.coords_to_piece_idx(coord_y, coord_x)
	local rc = core.player_move(state, get_player(), piece.y, piece.x)
	
	if rc ~= core.RC_SUCCESS then
		alexgames.set_status_err(core.rc_to_string(rc))
	else
		-- TODO this saves even when the player just selects something... that
		-- shouldn't count as a move.
		save_state()
		alexgames.set_status_msg("Waiting for other player to move")
		if not local_multiplayer then
			alexgames.send_message("all", string.format("move:%d,%d,%d", player, piece.y, piece.x))
		end
	end

	core.print_state(state)
	print(string.format("serialized state is: %s", utils.binstr_to_hr_str(serialize.serialize_state(state))))
	update()
end


local SELECT_PLAYER_POPUP_ID = "select_player"
local PLAYER_CHOICE_BTNS = {
	"Red",
	"Black",
}
local BTN_MAP = {
	[0] = core.PLAYER1,
	[1] = core.PLAYER2,
}

function handle_popup_btn_clicked(popup_id, btn_idx)
	if two_player.handle_popup_btn_clicked(popup_id, btn_idx) then
		-- handled
	else
		error(string.format("Unhandled popup_id=%s, btn_idx=%s", popup_id, btn_idx))
	end
end

local function broadcast_state(dst)
	alexgames.send_message(dst, "state:" .. serialize.serialize_state(state))
end

function handle_msg_received(src, msg)
	print("Recvd msg " .. msg)

	if two_player.handle_msg_received(src, msg) then
		return
	end

	local m = msg:gmatch("([^:]+):(.*)")
	if m == nil then
		print("Unable to parse header from msg " .. msg)
		return
	end
	local header, payload = m()

	if header == "move" then
		local m2 = payload:gmatch("(%d+),(%d+),(%d+)")
		if m2 == nil then
			error("Invalid \"move\" msg from " .. src)
			return
		end
		local player_idx, y, x = m2()
		player_idx = tonumber(player_idx)
		y = tonumber(y)
		x = tonumber(x)
		local rc = core.player_move(state, player_idx, y, x)
		if rc ~= core.RC_SUCCESS then
			alexgames.set_status_err("Other player made an invalid move")
		else
			alexgames.set_status_msg("Your move")
			update()
			save_state()
		end

	elseif header == "get_state" then
		broadcast_state(src)
	elseif header == "state" then
		local recvd_state = serialize.deserialize_state(payload)
		print("Recieved state:")
		core.print_state(recvd_state)
		state = recvd_state
		update()
		save_state()
	elseif header == "player_left" and src == "ctrl" then
	elseif header == "player_joined" then
	else
		error("Unhandled message: " .. header )
	end
end

function two_player_init()
	local args = {
		supports_local_multiplayer = true,
		title = "Choose piece colour",
		player_choices = PLAYER_CHOICE_BTNS,
		handle_multiplayer_type_choice = function (multiplayer_type)
			if multiplayer_type == two_player.MULTIPLAYER_TYPE_LOCAL then
				local_multiplayer = true
			elseif multiplayer_type == two_player.MULTIPLAYER_TYPE_NETWORK then
				local_multiplayer = false
			end
		end,
		choice_id_to_player_id = function (btn_id)
			return BTN_MAP[btn_id]
		end,
		player_name_to_id = player_name_to_id,
		player_id_to_nice_name = function (player_id)
			local player_colour = core.player_id_to_name(player_id)
			return utils.make_first_char_uppercase(player_colour)
		end,
		get_msg = function ()
			local msg = "Red moves first."
			if utils.table_len(player_name_to_id) == 0 then
				msg = msg .. "\nThe other player has not yet chosen."
			else
				--msg = msg .. string.format("The other player has chosen %s",
				--                           core.player_id_to_name(other_player))
				for player_name, player_id in pairs(player_name_to_id) do
					local player_colour = core.player_id_to_name(player_id)
					msg = msg .. string.format("\n%s is chosen by %s", utils.make_first_char_uppercase(player_colour), player_name)
				end
			end
			return msg
		end,
		handle_player_choice = function (player_name, player_id)
			local choice_str = core.player_id_to_name(player_id)
			print(string.format("handle_player_choice{ player_name=\"%s\", choice=%q (%q) }", player_name, player_id, choice_str))
			if player_name == two_player.LOCAL_PLAYER then
				player = player_id
			else
				g_other_player = player_id
			end
		end,

		need_reselect = function ()
			local this_player  = player
			local other_player = g_other_player

			return this_player == nil or this_player == other_player
		end,

		get_local_player_choice = function ()
			return player
		end
	}

	two_player.init(args)
end

local function load_state_move_offset(move_id_offset)
	local serialized_state = alexgames.adjust_saved_state_offset(session_id, move_id_offset)
	state = serialize.deserialize_state(serialized_state)
	init_ai()
	update()
	broadcast_state("all")
end

function handle_btn_clicked(btn_id)
	if btn_id == BTN_ID_UNDO then
		load_state_move_offset(-1)
	elseif btn_id == BTN_ID_REDO then
		load_state_move_offset(1)
	end
end

function start_game(session_id_arg, serialized_state)
	local last_sess_id = alexgames.get_last_session_id()
	if serialized_state then
		session_id = session_id_arg
		state = serialize.deserialize_state(serialized_state)
	elseif last_sess_id ~= nil then
		serialized_state = alexgames.adjust_saved_state_offset(last_sess_id, 0)
		session_id = last_sess_id
		state = serialize.deserialize_state(serialized_state)
	end
	init_ai()
	two_player_init()

	--alexgames.send_message("all", "player_joined:")
	alexgames.send_message("all", "get_state:")

	alexgames.add_game_option(GAME_OPTION_NEW_GAME, { label = "New Game", type = alexgames.OPTION_TYPE_BTN })

	alexgames.create_btn(BTN_ID_UNDO, "Undo", 1)
	alexgames.create_btn(BTN_ID_REDO, "Redo", 1)
end

function handle_game_option_evt(option_id)
	if option_id == GAME_OPTION_NEW_GAME then
		session_id = alexgames.get_new_session_id()
		state = core.new_state()
		init_ai()
		save_state()
		update()
		broadcast_state("all")
	end
end

function save_state()
	local serialized_state = serialize.serialize_state(state)
	alexgames.save_state(session_id, serialized_state)
end

function get_state()
	local serialized_state = serialize.serialize_state(state)
	print(string.format("lua: returning %d bytes of state", #serialized_state))
	return serialized_state
end

local x = true 

local function serialize_move_for_ai(move)
	return string.char(table.unpack({
		move.src.y,
		move.src.x,
		move.dst.y,
		move.dst.x,
	}))
end

local function deserialize_ai_move(serialized_move)
	local nums = {}
	for i=1,#serialized_move do
		table.insert(nums, string.byte(serialized_move, i))
	end

	local move = {
		src = {
			y = nums[1],
			x = nums[2],
		},
		dst = {
			y = nums[3],
			x = nums[4],
		},
	}
	return move
end

local test_move = {
	src = { y = 10, x = 20 },
	dst = { y = 30, x = 40 },
}
local test_move2 = deserialize_ai_move(serialize_move_for_ai(test_move))
print(string.format("1, y=%s, x=%s", test_move.src.x, test_move2.src.x))
print(string.format("2, y=%s, x=%s", test_move.src.y, test_move2.src.y))
print(string.format("3, y=%s, x=%s", test_move.dst.x, test_move2.dst.x))
print(string.format("4, y=%s, x=%s", test_move.dst.y, test_move2.dst.y))

-- TODO rename global `state` to `g_state` or something
function get_possible_moves(state_arg)
	if #state_arg == 0 then
		error("get_possible_moves received state of len 0")
		return {}
	end
	-- TODO need to favour moves that result in jumps, otherwise the random MCTS simulation will take forever to end.
	-- So maybe put them into two groups, shuffling each of them, and have MCTS go in order. Then other games will be responsible
	-- for shuffling their own moves?

	print("[ai] lua checkers get_possible_moves called")
	print("lua: get_possible_moves")
	state_arg = serialize.deserialize_state(state_arg)
	local moves = core.get_valid_moves(state_arg)
	print(string.format("get_possible_moves returned %d possib moves", #moves))
	for i, move in ipairs(moves) do
		print(string.format("get_possible_moves, move=%d { src=(%d,%d), dst=(%d,%d) }", i, move.src.y, move.src.x, move.dst.y, move.dst.x))
		moves[i] = serialize_move_for_ai(move)
	end

	--error("derp, test error")
	return moves
end

function get_player_turn(state_arg)
	return 1
end

local function copy_state(state_arg)
	-- TODO make a real copy function, this is probably a lot slower
	-- and certainly more error prone
	state_arg = serialize.serialize_state(state_arg)
	state_arg = serialize.deserialize_state(state_arg)
	return state_arg 
end

local i = 0
function apply_move(state_arg, move)
	state_arg = serialize.deserialize_state(state_arg)
	move = deserialize_ai_move(move)

	local rc

	rc = core.player_move(state_arg, state_arg.player_turn, move.src.y, move.src.x)
	if rc ~= core.RC_SUCCESS then
		error(string.format("apply_move step 1 resulted in error %d (%s)", rc, core.rc_to_string(rc)))
	end
	rc = core.player_move(state_arg, state_arg.player_turn, move.dst.y, move.dst.x)
	if rc ~= core.RC_SUCCESS then
		error(string.format("apply_move step 2 resulted in error %d (%s)", rc, core.rc_to_string(rc)))
	end

	state_arg = serialize.serialize_state(state_arg)
	print(string.format("[ai verbose] lua apply_move, returning state (%d bytes) %s", #state_arg, state_arg))

	return state_arg
end

function get_player_turn(state_arg)
	if #state_arg == 0 then
		error("get_player_turn received state len 0")
	end
	state_arg = serialize.deserialize_state(state_arg)

	return state_arg.player_turn
end

function init_ai()
	-- TODO only do this if AI is enabled
	g_ai = alexgames_ai.init(
		serialize.serialize_state(state)
	)
	g_ai_iters_remaining = g_ai_iters_per_move
end

function process_ai()
	local start_time_ms = alexgames.get_time_ms()
	local end_time_ms = start_time_ms + MS_PER_FRAME
	local ai_iters_per_call = 50
	while g_ai_iters_remaining > 0 and alexgames.get_time_ms() < end_time_ms do
		print(string.format("[ai] iters remaining: %d", g_ai_iters_remaining ))
		alexgames_ai.expand_tree(g_ai, ai_iters_per_call)
		g_ai_iters_remaining = g_ai_iters_remaining - ai_iters_per_call
	end

	if g_ai_iters_remaining <= 0 then
		local state_serialized = serialize.serialize_state(state)
		local move = alexgames_ai.get_move(g_ai, state_serialized)
		move = deserialize_ai_move(move)
		print(string.format("AI move is: src (%d,%d) dst(%d,%d)", move.src.y, move.src.x, move.dst.y, move.dst.x))
	end
end

alexgames.set_timer_update_ms(MS_PER_FRAME)
