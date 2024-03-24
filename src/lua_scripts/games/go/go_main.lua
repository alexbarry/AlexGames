local two_player = require("libs/multiplayer/two_player")
local utils      = require("libs/utils")
local show_buttons_popup = require("libs/ui/show_buttons_popup")

local go      = require("games/go/go_core")
local go_ui   = require("games/go/go_ui")
local go_ctrl = require("games/go/go_ctrl")

local alex_c_api = require("alex_c_api");

-- e.g. either 9x9, 13x13, or 19x19
local go_game_size = 19
local local_multiplayer = nil
local session_id = alex_c_api.get_new_session_id()
local state = go.new_game(go_game_size)

-- state was received either from another player or
-- explicitly loaded
local state_init = false

-- if this is true, then the user explicitly loaded saved state from
-- URL or history browser, don't prompt them to start a new game
local state_loaded = false

local ctrl_state = go_ctrl.new_state()
-- TODO have a C API to get height/width of canvas, or maybe
-- set it?
local height = 480
local width = 480
go_ui.init_ui(session_id, go_game_size, width, height)
alex_c_api.send_message("all", "get_state:")
alex_c_api.set_status_msg("Choose piece colour")

local PLAYER_CHOICE_POPUP_ID = "choose_player_colour"
local PLAYER_CHOICE_BTNS = {
	"Black",
	"White",
}
local PLAYER_CHOICE_BTNS_MAP = {
	[0] = go.PLAYER1,
	[1] = go.PLAYER2,
}

local POPUP_ID_GAME_SIZE_SELECTION = "game_size_sel"
local POPUP_GAME_SIZE_SEL_BTNS = {
	"9x9",
	"13x13",
	"19x19",
}
local POPUP_GAME_SIZE_SEL_BTNS_TO_SIZE = {
	9, 13, 19
}


local POPUP_ID_START_NEW_GAME_PROMPT = "new_game_prompt"
local POPUP_GAME_SIZE_NEW_GAME_PROMPT = {
	"Start new game",
	"Continue saved game",
}

local function get_player()
	if local_multiplayer then
		return state.player_turn
	else
		return go_ctrl.get_player(ctrl_state)
	end
end

local PLAYER_IDX_TO_BTN_IDX_MAP = utils.reverse_map(PLAYER_CHOICE_BTNS_MAP)

local OPTION_ID_NEW_GAME = "opt_new_game"

-- maps player IP/name to player ID
local player_name_to_id = {
}

-- adding test for ko
--[[
state.board = {
	{ 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 1, 2, 0, 0, 0},
	{ 0, 0, 0, 1, 0, 1, 2, 0, 0},
	{ 0, 0, 0, 0, 1, 2, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{ 0, 0, 0, 0, 0, 0, 0, 0, 0},
}
--]]

function handle_user_string_input(row_col)
	local m = row_col:gmatch"(%a+)%s*(%d+)"
	-- todo raise error if inputs like "aaa5" are given (currently this is interpreted as "a5")
	local row
	local col
	row, col = m()
	if row == nil or col == nil then
		return nil
	end
	col = tonumber(col)
	row = string.byte(row:upper()) - string.byte('A') + 1
	local rc = go.player_move(state, get_player(), row, col)
	return rc
end

function draw_board() 
	if state ~= nil then
		go_ui.draw_board(session_id, state.board, state.last_move_y, state.last_move_x)
	end
end

function get_user_input()
	io.write(string.format("Move player %d (%s), enter row letter and column number (e.g. \"E5\")>> ",
		state.player_turn, go.player_num_to_char(state.player_turn)))
	local s = io.read("*l")
	return s
end

local function save_state()
	alex_c_api.save_state(session_id, go.serialize_state(state))
end

function get_state()
	return go.serialize_state(state)
end

function handle_user_clicked(pos_y, pos_x)
	local pos = go_ui.user_pos_to_piece_idx(pos_y, pos_x)
	local player = get_player()
	local rc = go.player_move(state, player, pos.y, pos.x)
	if rc == go.SUCCESS then
		if not local_multiplayer then
			alex_c_api.send_message("all", string.format("move:%d,%d,%d", player, pos.y, pos.x));
			alex_c_api.set_status_err("")
		end
		save_state()
	else
		alex_c_api.set_status_err(go.err_code_to_str(rc))
	end
	draw_board()
	update_status_msg_turn(state, ctrl_state)
end

local function broadcast_state()
	alex_c_api.send_message("all", "state:"..go.serialize_state(state))
end

local function set_state(state_arg)
	print("set_state called")
	state_init = true
	state = state_arg
end

function handle_msg_received(src, msg)
	print("handle_msg_received (from src:" .. src .. "): " .. msg);

	if local_multiplayer then
		return
	end

	if two_player.handle_msg_received(src, msg) then
		return
	end

	local m = msg:gmatch("([^:]+):(.*)")
	local header, payload
	header, payload = m()

	if header == "move" then
		local m = payload:gmatch"(%d+),(%d+),(%d+)"
		local player, row, col
		player, row, col = m()
		player = tonumber(player)
		row = tonumber(row)
		col = tonumber(col)
		print(string.format("Received player=%s, row=%s, col=%d", player, row, col))

		if player == go_ctrl.get_player(ctrl_state) then
			-- TODO make UI visible message for this case?
			print(string.format("Received message for move from wrong player"))
			return
		end
		go.player_move(state, player, row, col)
		alex_c_api.set_status_err("")
		draw_board()
		update_status_msg_turn(state, ctrl_state)
		save_state()
	elseif header == "get_state" then
		broadcast_state()
	elseif header == "state" then
		local new_state = go.deserialize_state(payload)
		-- TODO check with user if they want to overwrite their state with
		-- this (possibly unsolicited!!) state from the other player
		set_state(new_state)
		if go_ui.get_board_piece_size() ~= #new_state.board then
			go_ui.set_board_piece_size(#new_state.board)
		end
		draw_board()
		alex_c_api.set_status_err("")
		update_status_msg_turn(state, ctrl_state)
	elseif header == "player_left" and src == "ctrl" then
		-- do nothing
	else
		print("Unexpected message header: \""..header.."\"")
	end
end

local function load_saved_state_offset(move_id_offset)
	local serialized_state = alex_c_api.get_saved_state_offset(session_id, move_id_offset)
	if serialized_state == nil then
		error(string.format("get_saved_state_offset(offset=%d) returned nil", move_id_offset))
	end
	internal_load_state(session_id, serialized_state)
	draw_board()
end

local function handle_pass(player)
	local rc = go.player_pass(state, player)
	if rc ~= go.SUCCESS then
		alex_c_api.set_status_err(go.err_code_to_str(rc))
	else
		draw_board()
		save_state()
		update_status_msg_turn(state, ctrl_state)

		-- TODO This is lazy, I should implement a string to indicate this move
		broadcast_state()
	end
end

function handle_btn_clicked(btn_id)
	print("handle_btn_clicked: "..btn_id)
	if btn_id == go_ui.BTN_ID_UNDO then
		load_saved_state_offset(-1)
		broadcast_state()
	elseif btn_id == go_ui.BTN_ID_REDO then
		load_saved_state_offset(1)
		broadcast_state()
	elseif btn_id == go_ui.BTN_ID_PASS then
		local player = get_player()
		handle_pass(player)
	else
		error(string.format("Unhandled button pressed \"%s\"", btn_id))
	end
end

local function get_player_name(player_arg)
	for name, player_idx in pairs(player_name_to_id) do
		if player_arg == player_idx then return name end
	end
	return "nil"
end

function update_status_msg_turn(state, ctrl_state)
	if state == nil then return end

	local display_name = go.player_idx_to_colour_name(state.player_turn)
	if not local_multiplayer then
		display_name = string.format("%s (%s)", display_name, get_player_name(state.player_turn))
	end
	alex_c_api.set_status_msg(string.format("Waiting for %s to move", display_name))
	print(string.format("State is now: %s", utils.binstr_to_hr_str(go.serialize_state(state))))
end

function handle_popup_btn_clicked(popup_id, btn_idx)
	if two_player.handle_popup_btn_clicked(popup_id, btn_idx) then
		-- handled, no action here
	elseif popup_id == POPUP_ID_GAME_SIZE_SELECTION then
		local desired_game_size = POPUP_GAME_SIZE_SEL_BTNS_TO_SIZE[btn_idx+1]
		alex_c_api.hide_popup()
		alex_c_api.set_status_msg(string.format("Setting board size to %s", desired_game_size))
		set_state(go.new_game(desired_game_size))
		go_ui.set_board_piece_size(desired_game_size)
		print(string.format("state.board: %s", state.board))
		draw_board()
		broadcast_state()
	elseif popup_id == POPUP_ID_START_NEW_GAME_PROMPT then
		if btn_idx == 0 then
			state_init = false
			prompt_game_size()
		elseif btn_idx == 1 then
			alex_c_api.hide_popup()
		else
			error(string.format("popup btn_idx %s not handled for start new game prompt", btn_idx))
		end
	else
		print(string.format("Unexpected popup_id \"%s\"", popup_id));
		alex_c_api.hide_popup()
	end
end

-- "internal" means "not called by game engine", it should
-- only be called by other functions within this file.
-- Originally I had a "load_state" function as part of the API,
-- but I combined it with start_game. So I'm changing this name to
-- avoid confusing myself when grepping to see if I updated all the games.
function internal_load_state(session_id_arg, serialized_state)
	session_id = session_id_arg
	local loaded_state = go.deserialize_state(serialized_state)
	go_ui.set_board_piece_size(#loaded_state.board)
	state_loaded = true
	set_state(loaded_state)
end

local function prompt_new_game()
	show_buttons_popup.show_popup(POPUP_ID_START_NEW_GAME_PROMPT, "Start new game",
	                              "Start a new game, or load saved state?",
	                              POPUP_GAME_SIZE_NEW_GAME_PROMPT)
end

local function prompt_game_size()
	-- if previous state was already loaded, then don't prompt game size and overwrite 
	-- the loaded game
	if state_init and state_loaded then
		return
	end

	if not state_init then
		show_buttons_popup.show_popup(POPUP_ID_GAME_SIZE_SELECTION, "Choose game size",
		                              "Choose one of the below game sizes.",
		                              POPUP_GAME_SIZE_SEL_BTNS)
	end
end

function two_player_init()
	local args = {
		title = "Choose piece colour",
		supports_local_multiplayer = true,
		player_choices = PLAYER_CHOICE_BTNS,
		handle_multiplayer_type_choice = function (multiplayer_type)
			if multiplayer_type == two_player.MULTIPLAYER_TYPE_LOCAL then
				local_multiplayer = true
				prompt_game_size()
			elseif multiplayer_type == two_player.MULTIPLAYER_TYPE_NETWORK then
				local_multiplayer = false
			end
		end,
		choice_id_to_player_id = function (btn_id)
			return PLAYER_CHOICE_BTNS_MAP[btn_id]
		end,
		player_name_to_id = player_name_to_id,
		player_id_to_nice_name = function (player_id)
			local player_colour = go.player_idx_to_colour_name(player_id)
			return utils.make_first_char_uppercase(player_colour)
		end,
		get_msg = function ()
			local msg = "Black moves first."
			--local other_player = go_ctrl.get_other_player(ctrl_state)
			if utils.table_len(player_name_to_id) == 0 then
				msg = msg .. "\nThe other player has not yet chosen."
			else
				--msg = msg .. string.format("The other player has chosen %s",
				--                           go.player_idx_to_colour_name(other_player))
				for player_name, player_id in pairs(player_name_to_id) do
					local player_colour = go.player_idx_to_colour_name(player_id)
					msg = msg .. string.format("\n%s is chosen by %s", utils.make_first_char_uppercase(player_colour), player_name)
				end
			end
			return msg
		end,
		handle_player_choice = function (player_name, player_id)
			local choice_str = go.player_idx_to_colour_name(player_id)
			print(string.format("handle_player_choice{ player_name=\"%s\", choice=%q (%q) }", player_name, player_id, choice_str))
			if player_name == two_player.LOCAL_PLAYER then
				go_ctrl.player_chosen(ctrl_state, player_id)
				update_status_msg_turn(state, ctrl_state)
			else
				go_ctrl.other_player_chosen(ctrl_state, player_id)

			end

			if player_name == two_player.LOCAL_PLAYER and go_ctrl.get_other_player(ctrl_state) == nil then
				prompt_game_size()
			end
			print(string.format("we are %q, other player is %q",
			      go_ctrl.get_player(ctrl_state), go_ctrl.get_other_player(ctrl_state)))
		end,

		need_reselect = function ()
			local this_player  = go_ctrl.get_player(ctrl_state)
			local other_player = go_ctrl.get_other_player(ctrl_state)

			-- print(string.format("needs_reselect { this_player = %q, other_player = %q }", this_player, this_player == other_player))
			return this_player == nil or this_player == other_player
		end,

		get_local_player_choice = function ()
			return go_ctrl.get_player(ctrl_state)
		end
	}

	two_player.init(args)
end

function handle_game_option_evt(option_id)
	if option_id == OPTION_ID_NEW_GAME then
		-- TODO remove these bools, this is ugly. At least do the check outside of
		-- where the function is called
		state_init = false
		state_loaded = false
		prompt_game_size()
	else
		error(string.format("Unhandled option_id %s", option_id))
	end
end

function start_game(session_id, state_serialized)
	if state_serialized ~= nil then
		internal_load_state(session_id, state_serialized)
	else
		local session_id = alex_c_api.get_last_session_id()
		if session_id ~= nil then
			state_serialized = alex_c_api.get_saved_state_offset(session_id, 0)
			internal_load_state(session_id, state_serialized)
		end
	end

	-- Note that this sets who the player on this device is,
	-- and without it, the player arg is nil and the game can't progress
	two_player_init()

	alex_c_api.add_game_option(OPTION_ID_NEW_GAME, { type = alex_c_api.OPTION_TYPE_BTN, label = "New Game"})
end

function lua_main()
	while true do
		print_board()
		::read_input::
		local user_input = get_user_input()
		local rc = handle_user_string_input(user_input)
		if rc ~= go.SUCCESS then
			print('Error: '.. go.err_code_to_str(rc))
			goto read_input
		end
	end
end
