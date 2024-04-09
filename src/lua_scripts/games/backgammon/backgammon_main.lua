-- Game:   Backgammon
-- author: Alex Barry (github.com/alexbarry)
--[[
TODO:
* players take turns rolling dice to decide who goes first?
* limit number of checkers on UI in each column to 6 or so, then show "+n"
* change piece highlights to yellow for "select a piece to move",
* then highlight selected piece in blue
* investigate errors


The network multiplayer sequence is mostly:
* local user presses the screen to make a move,
* local game handles the move, draws on the screen, and
* send move to remote player
* remote player handles the move and updates the screen

Dice rolling is handled by one player serving as "host"
(let's call the other player "client"),
currently it is the player that selected {black or white}
first:
* when the host player rolls the dice, they send the "dice" (CMD_DICE) command.
  This causes the remote player to call core.roll(state, game, dice_vals = <vals received>).
  The core game logic should behave the same as if the local player rolled, but
  instead of using its own random number generator, it uses the received dice values.
* when a client player rolls the dice:
      - client sends the "roll request" (CMD_ROLL_REQ) command and do nothing else locally for now
      - host should respond with CMD_DICE, which will cause the client player to roll
        with the provided dice value

# Host rolls the dice

            host                            client
            player 1                        player 2
             |                                 |
     roll    |                                 |
    request  |                                 |
             |                                 |
 core.roll(  |                                 |
   player=1, |                                 |
   vals=nil) |                                 |
             |                                 |
 (this       |                                 |
  generates  |                                 |
  dice vals) |                                 |
             |                                 |
             | ---> CMD_ROLL, dice vals ------>| core.roll(player=1, vals)
             |                                 |
             |                                 | (this advances game
             |                                 |  state but uses the
             |                                 |  provided dice vals
             |                                 |  instead of generating
             |                                 |  any)
             |                                 |

# Client rolls the dice

            host                            client
            player 1                        player 2
             |                                 |
             |                                 |  roll
             |                                 |  request
             | <------- CMD_ROLL_REQ <-------- |
 core.roll(  |                                 |
   player=2, |                                 |
   vals=nil) |                                 |
             |                                 |
 (this       |                                 |
  generates  |                                 |
  dice vals) |                                 |
             | ----> CMD_DICE, dice_vals ----> | core.roll(vals)
             |                                 |
             |                                 |
             |                                 |
  
--]]
local core = require("games/backgammon/backgammon_core")
local draw = require("games/backgammon/backgammon_draw")
local serialize = require("games/backgammon/backgammon_serialize")

local two_player = require("libs/multiplayer/two_player")
local utils = require("libs/utils")

local alexgames = require("alexgames")

local session_id = alexgames.get_new_session_id()
local state = core.new_game()

-- I uncomment this when testing bearing off, without having to play a full game
--[[
state.board = {
	{
		{},
		{},
		{},
		{},
		{},
		{},

		{},
		{},
		{},
		{2,2,2,2,2,2,2,2,2},
		{},
		{},
	},

	{
		{},
		{},
		{},
		{},
		{},
		{},

		{},
		{},
		{},
		{1,1,1,1,1,1,1,1,1},
		{},
		{},
	},
}
--]]

local player = nil
local local_multiplayer = nil
local is_host = true -- TODO set this
local player_name_to_id = {}
local g_other_player = nil
local invalid_dst_in_a_row = 0

local GAME_OPTION_NEW_GAME = "option_new_game"

local POPUP_ID_SELECT_PLAYER = "popup_select_player"
local PLAYER_CHOICE_BTNS = {
	core.get_player_name(core.PLAYER_WHITE),
	core.get_player_name(core.PLAYER_BLACK),
}
local BTN_MAP = {
	[0] = core.PLAYER_WHITE,
	[1] = core.PLAYER_BLACK,
}

local function get_player()
	if local_multiplayer then
		return state.player_turn
	else
		return player
	end
end

local function save_state()
	local serialized_state = serialize.serialize_state(state)
	alexgames.save_state(session_id, serialized_state)
end

function update()
	core.increment_move_timer(state)
	draw.draw_state(state, session_id, get_player())
	print(string.format("Game state is %d", state.game_state))
	--core.print_state(state)
	--alexgames.set_status_msg(core.get_status_msg(state))
end

local function handle_rc(rc)
	print(string.format("handle_rc(rc=%s(%s))", rc, core.get_err_msg(rc)))
	if rc ~= core.SUCCESS then
		local err_msg = core.get_err_msg(rc)
		if rc == core.INVALID_DST then
			invalid_dst_in_a_row = invalid_dst_in_a_row + 1
			if invalid_dst_in_a_row  >= 3 then
				err_msg = err_msg .. " (To change your selected piece, press the " ..
				                     "middle of the board or the currently selected piece)"
			end
		else
			invalid_dst_in_a_row = 0
		end
		alexgames.set_status_err(err_msg)
	else
		invalid_dst_in_a_row = 0
		local msg = core.get_status_msg(state)
		alexgames.set_status_msg(msg)

		-- TODO only do this if a move was actually made
		if rc == core.SUCCESS then
			save_state()
		end
	end
end

local function double_request(player)
	alexgames.set_status_msg(string.format("%s has proposed doubling the value of winning the match.", core.get_player_name(player)))
	local rc = core.double_request(state, get_player())
	draw.double_request(state)
	return rc
end


local game_msg_prefix    = "backgammon"

local CMD_TOUCH          = "touch"
local CMD_DOUBLE_REQUEST = "double_request"
local CMD_ROLL           = "roll"
local CMD_ROLL_REQ       = "roll_request"
local CMD_ACK_INIT       = "ack_init"
local CMD_ACK_CANT_MOVE  = "ack_cant_move" -- TODO combine with the other ack
local CMD_UNSELECT       = "unselect"

local CMD_DICE           = "dice"

-- This should be called when the user presses the "roll" button.
-- It either does the roll locally, or sends a message and shows "waiting"
-- to the user until the dice values are received from the host player.
function roll_request(state, player)
	if local_multiplayer or two_player.am_first_player() then
		local request_is_local = (player == get_player())
		local for_player_str = nil
		if request_is_local then
			for_player_str = string.format("for local player %s", player)
		else
			for_player_str = string.format("on behalf of player %s", player)
		end
		print(string.format("We are player 1 of %d, rolling dice (%s) and broadcasting value", two_player.get_player_count(), for_player_str))
		local rc = core.roll(state, player)
		if rc == core.SUCCESS then
			if state.dice_vals ~= nil then
				print(string.format("dice_vals len is %d, vals: %s", #state.dice_vals, utils.ary_to_str(state.dice_vals)))
			else
				print(string.format("dice_vals == nil"))
			end
			if request_is_local then
				send_cmd(CMD_ROLL, player, state.dice_vals)
			else
				send_cmd(CMD_DICE, player, state.dice_vals)
			end
		end

		return rc
	else
		-- this is a bit awkward, but we don't want to let
		-- the remote player send the roll command if it isn't their turn
		if state.player_turn ~= get_player() then
			return core.NOT_YOUR_TURN
		end
		print(string.format("We are not player 1 of %d, send a cmd to roll and hope the other player sends us the dice value", two_player.get_player_count()))
		send_cmd(CMD_ROLL_REQ, player)
		state.dice_vals = {}
		state.dice_loading = true
		-- when CMD_DICE is received, we'll call core.roll(state, player, dice_vals)
		-- to act as if this player rolled, but providing the dice values sent by the
		-- other player
		return core.SUCCESS
	end
end

function send_cmd(cmd, player, params)
	local params_str = ""
	if params ~= nil then
		params_str = table.concat(params, ",")
	end
	local msg = string.format("%s:%s,%s,%s", game_msg_prefix, cmd, player, params_str)
	print(string.format("sending msg %s", msg))
	--print(string.format("pieces were: cmd (%s), player (%s), params_str(%s)", cmd, player, params_str))
	alexgames.send_message("all", msg)
end

local function str_ary_to_number_ary(str_ary)
	local num_ary = {}
	for _, s in ipairs(str_ary) do
		table.insert(num_ary, tonumber(s))
	end
	return num_ary
end

local function parse_cmd(cmd_str)
	local cmd_pieces = utils.gmatch_to_list("([^,]+)", cmd_str)
	local cmd, player_str = table.unpack(cmd_pieces, 1, 2)
	local params = {table.unpack(cmd_pieces, 3)}
	params = str_ary_to_number_ary(params)
	--print(string.format("params type=%s, val=%s", type(params), params))

	--print(string.format("parsed cmd to: %s %s %s (cmd_pieces was %s)", cmd, player_str, params, utils.ary_to_str(cmd_pieces)))
	return cmd, tonumber(player_str), params
end

local function handle_cmd(cmd, player, params)
	print(string.format("handle_cmd(cmd=%s, player=%s, params=%s)", cmd, player, utils.ary_to_str(params)))
	if cmd == CMD_TOUCH then
		local coords = nil
		if params ~= nil and #params > 0 then
			coords = { y = params[1], x = params[2] }
		end
		return core.player_touch(state, player, coords)
	elseif cmd == CMD_DOUBLE_REQUEST then
		return double_request(player)
	elseif cmd == CMD_ACK_INIT then
		return core.ack_init(state, player)
	elseif cmd == CMD_ACK_CANT_MOVE then
		return core.player_cant_move_ack(state, player)
	elseif cmd == CMD_UNSELECT then
		if player ~= state.player_turn then
			error(string.format("Player %s tried to unselect when not their turn", player))
		end
		state.player_selected = nil
		return core.SUCCESS
	elseif cmd == CMD_DICE or
	       cmd == CMD_ROLL then
		local dice_vals = params

		if dice_vals == nil then
			error(string.format("Received cmd %s without dice val params", cmd))
		end


		rc = core.roll(state, player, dice_vals)
		state.dice_loading = false
		print(string.format("Dice vals are now: %s", utils.ary_to_str(state.dice_vals)))
		update()
		return rc
	elseif cmd == CMD_ROLL_REQ then
		rc = roll_request(state, player)
		handle_rc(rc)
		update()
	else
		error(string.format("Unhandled cmd \"%s\"", cmd))
	end
end

local function send_and_handle_cmd(cmd, player, params)
	if cmd == CMD_ROLL or cmd == CMD_ROLL_REQ then
		error("send_and_handle_cmd does not handle CMD_ROLL")
	end

	local rc = handle_cmd(cmd, player, params)
	if rc == core.SUCCESS then
		send_cmd(cmd, player, params)
	end
	print(string.format("cmd %s returned status %s (%s)", cmd, rc, core.get_err_msg(rc)))

	return rc
end


function handle_user_clicked(pos_y, pos_x)
	local can_bear_off = core.player_can_bear_off(state, get_player())
	-- NOTE that this can be "middle" too
	local sel_coords = draw.screen_coords_to_board_coords(pos_y, pos_x, can_bear_off)

	local btn_clicked = draw.handle_user_clicked(pos_y, pos_x)

	if not btn_clicked then
		local params = nil
		if sel_coords ~= nil then
			params = {sel_coords.y, sel_coords.x}
		end
		local rc = send_and_handle_cmd(CMD_TOUCH, get_player(), params)
		handle_rc(rc)
	end
	draw.draw_state(state, session_id, get_player())
	--core.print_state(state)

end

local function load_state(session_id_arg, serialized_state)
	session_id = session_id_arg
	state = serialize.deserialize_state(serialized_state)
end

local function load_saved_state_offset(move_id_offset)
	local serialized_state = alexgames.get_saved_state_offset(session_id, move_id_offset)
	if serialized_state == nil then
		error(string.format("get_saved_state_offset(offset=%d) returned nil", move_id_offset))
	end
	load_state(session_id, serialized_state)
	update()
end

function handle_btn_clicked(btn_id)
	print("handle_btn_clicked: " .. btn_id)
	local rc
	if btn_id == draw.BTN_ID_CANT_MOVE then
		rc = send_and_handle_cmd(CMD_ACK_CANT_MOVE, get_player())
		draw.draw_state(state, session_id, get_player())
	elseif btn_id == draw.BTN_ID_UNDO then
		load_saved_state_offset(-1)
		-- TODO broadcast state
	elseif btn_id == draw.BTN_ID_REDO then
		load_saved_state_offset(1)
		-- TODO broadcast state
	elseif btn_id == draw.BTN_ID_DOUBLE_REQUEST then
		rc = send_and_handle_cmd(CMD_DOUBLE_REQUEST, get_player())
	elseif btn_id == draw.BTN_ID_ROLL then
		--rc = send_and_handle_cmd(CMD_ROLL, get_player())
		rc = roll_request(state, get_player())
		update()
	elseif btn_id == draw.BTN_ID_ACK then
		rc = send_and_handle_cmd(CMD_ACK_INIT, get_player())
		update()
	elseif btn_id == draw.BTN_ID_UNSELECT then
		rc = send_and_handle_cmd(CMD_UNSELECT, get_player())
		update()
	else
		error(string.format("unhandled btn_id=%s", btn_id))
	end
	handle_rc(rc)
end

function handle_popup_btn_clicked(popup_id, btn_id)
	if two_player.handle_popup_btn_clicked(popup_id, btn_id) then
		-- do nothing
	elseif popup_id == draw.POPUP_ID_DOUBLE_REQUEST then
		local accepted = nil
		if btn_id == draw.DOUBLE_REQUEST_BTN_ACCEPT then
			accepted = true
		elseif btn_id == draw.DOUBLE_REQUEST_BTN_DECLINE then
			accepted = false
		else
			error(string.format("Unhandled popup btn id %s, in popup id %s", btn_id, popup_id))
		end
		core.double_response(state, get_player(), accepted)
		alexgames.hide_popup()
		update()
	else
		error(string.format("Unhandled popup_id = %s", popup_id))
	end
end

local function new_game()
	alexgames.set_status_msg("Starting new game")
	session_id = alexgames.get_new_session_id()
	state = core.new_game()
	update()
end

function handle_game_option_evt(option_id)
	if option_id == GAME_OPTION_NEW_GAME then
		new_game()
		alexgames.send_message("all", "derp hello world test to see if this is sent to sender")
	else
		error(string.format("unhandled game option id %s", option_id))
	end
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

	if header == game_msg_prefix then
		local params = {parse_cmd(payload)}
		--print(string.format("params len: %d", #params))
		--print(string.format("Received game cmd %s", utils.ary_to_str(params)))
		local rc = handle_cmd(table.unpack(params))
		handle_rc(rc)
		update()
	-- TODO handle "game_cmd" messages, call handle_cmd
	elseif false then
--[[
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
		local coords = { y = y, x = x }
		local rc = core.player_touch(state, player_idx, coords)
		handle_rc(rc,  true)

		if rc ~= core.SUCCESS then
			alexgames.set_status_err("Other player made an invalid move")
		else
			alexgames.set_status_msg("Your move")
			update()
			save_state()
		end

--]]
	elseif header == "get_state" then
		alexgames.send_message(src, "state:" .. serialize.serialize_state(state))
	elseif header == "state" then
		local recvd_state = serialize.deserialize_state(payload)
		print("Recieved state:")
		--core.print_state(recvd_state)
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
			local player_colour = core.get_player_name(player_id)
			return utils.make_first_char_uppercase(player_colour)
		end,
		get_msg = function ()
			local msg = ""
			if utils.table_len(player_name_to_id) == 0 then
				msg = msg .. "\nThe other player has not yet chosen."
			else
				--msg = msg .. string.format("The other player has chosen %s",
				--                            core.player_id_to_name(other_player))
				for player_name, player_id in pairs(player_name_to_id) do
					local player_colour = core.get_player_name(player_id)
					msg = msg .. string.format("\n%s is chosen by %s", utils.make_first_char_uppercase(player_colour), player_name)
				end
			end
			return msg
		end,
		handle_player_choice = function (player_name, player_id)
			local choice_str = core.get_player_name(player_id)
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

function get_state()
	return serialize.serialize_state(state)
end


function start_game(session_id_arg, serialized_state)
	if serialized_state ~= nil then
		load_state(session_id_arg, serialized_state)
	else
		local last_sess_id = alexgames.get_last_session_id()
		if last_sess_id ~= nil then
			serialized_state = alexgames.get_saved_state_offset(last_sess_id, 0)
			if serialized_state ~= nil then
				load_state(last_sess_id, serialized_state)
			end
		end
	end

	-- TODO ideally the draw library could handle the button presses, forward a
	-- generic event to main which could be passed to the core API
	--draw.init(state)

	-- TODO call new game if no loaded state

	alexgames.add_game_option(GAME_OPTION_NEW_GAME, { label = "New game", type = alexgames.OPTION_TYPE_BTN })

	alexgames.set_timer_update_ms(1000)

	local msg = core.get_status_msg(state)
	alexgames.set_status_msg(msg)

	alexgames.send_message("all", "get_state:")
	two_player_init()
end

-- TODO ideally the draw library could handle the button presses, forward a
-- generic event to main which could be passed to the core API
draw.init(state, {
	handle_btn_clicked = handle_btn_clicked,
})
