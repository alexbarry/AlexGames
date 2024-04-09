local two_player = require("libs/multiplayer/two_player")
local utils      = require("libs/utils")

local wu      = require("games/wu/wu_core")
local wu_ui   = require("games/go/go_ui")
local wu_ctrl = require("games/wu/wu_ctrl")

local alexgames = require("alexgames");
local show_buttons_popup = require("libs/ui/show_buttons_popup")

local OPTION_ID_NEW_GAME = "opt_new_game"

-- e.g. either 9x9, 13x13, or 19x19
local session_id = alexgames.get_new_session_id()
local wu_game_size = 15
local state
local ctrl_state = wu_ctrl.new_state()
local local_multiplayer

local player_name_to_id = {}

-- TODO have a C API to get height/width of canvas, or maybe
-- set it?
local height = 480
local width = 480
wu_ui.init_ui(session_id, wu_game_size, width, height)

-- Do request state initially.
-- But on game over, whoever presses "new game" first is the one that should send state
-- so when you receive an event that says "new game", don't request state
-- but if you haven't yet received that message, then you should send your state
local request_state = true

local function get_player()
	if local_multiplayer then
		return state.player_turn
	else
		return wu_ctrl.get_player(ctrl_state)
	end
end

function new_game()
	state = wu.new_game(wu_game_size)
	alexgames.set_status_msg("Choose piece colour")
	if request_state then
		alexgames.send_message("all", "get_state:")
	else
		alexgames.send_message("all", "new_game:")
		send_state()
	end
	request_state = true
	update()
end

PLAYER_CHOICE_POPUP_ID = "choose_player_colour"
PLAYER_CHOICE_BTNS = {
	"Black",
	"White",
}
PLAYER_CHOICE_BTNS_MAP = {
	[0] = wu.PLAYER1,
	[1] = wu.PLAYER2,
}
PLAYER_IDX_TO_BTN_IDX_MAP = utils.reverse_map(PLAYER_CHOICE_BTNS_MAP)

GAME_OVER_POPUP_ID = "game_over"

function update() 
	wu_ui.update(session_id, state.board, state.last_move_y, state.last_move_x)
end

function first_char_upper(str)
	return str:sub(1,1):upper() .. str:sub(2,#str)
end

function check_for_winner()
	if state.winner ~= nil then
		local winner = wu.player_idx_to_colour_name(state.winner)
		local msg = string.format("Game over! %s wins.", first_char_upper(winner))
		request_state = false
		show_buttons_popup.show_popup(GAME_OVER_POPUP_ID,
		                              "Game over",
		                              msg,
		                              {"New game"})
		alexgames.set_status_msg(msg)
	end
end

function handle_user_clicked(pos_y, pos_x)
	local pos = wu_ui.user_pos_to_piece_idx(pos_y, pos_x)
	local player = get_player()
	local rc = wu.player_move(state, player, pos.y, pos.x)
	if rc == wu.SUCCESS then
		if not local_multiplayer then
			alexgames.send_message("all", string.format("move:%d,%d,%d", player, pos.y, pos.x));
		end
		alexgames.set_status_err("")
		alexgames.save_state(session_id, wu.serialize_state(state))
	else
		alexgames.set_status_err(wu.err_code_to_str(rc))
	end
	update()
	update_status_msg_turn(state, ctrl_state)
	check_for_winner()
end

function send_state()
	alexgames.send_message("all", "state:"..wu.serialize_state(state))
end

function handle_msg_received(src, msg)
	print("handle_msg_received (from src:" .. src .. "): " .. msg);

	if local_multiplayer then
		return
	end

	if two_player.handle_msg_received(src, msg) then
		return
	end

	local m = msg:gmatch("(%S+):(.*)")
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

		if player == wu_ctrl.get_player(ctrl_state) then
			-- TODO make UI visible message for this case?
			print(string.format("Received message for move from wrong player"))
			return
		end
		wu.player_move(state, player, row, col)
		alexgames.set_status_err("")
		update()
		update_status_msg_turn(state, ctrl_state)
		check_for_winner()
	elseif header == "get_state" then
		send_state()
	elseif header == "state" then
		local new_state = wu.deserialize_state(payload)
		-- TODO check with user if they want to overwrite their state with
		-- this (possibly unsolicited!!) state from the other player
		state = new_state
		update()
		alexgames.set_status_err("")
		update_status_msg_turn(state, ctrl_state)
	elseif header == "new_game" then
		request_state = true
	else
		print("Unexpected message header: \""..header.."\"")
	end
end

function handle_btn_clicked(btn_id)
	print("handle_btn_clicked: "..btn_id)
	if btn_id == wu_ui.BTN_ID_UNDO then
		load_state_move_offset(-1)
	elseif btn_id == wu_ui.BTN_ID_REDO then
		load_state_move_offset(1)
	else
		error(string.format("Unhandled button: \"%s\"", btn_id))
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

	local display_name = wu.player_idx_to_colour_name(state.player_turn)
	if not local_multiplayer then
		display_name = string.format("%s (%s)", display_name, get_player_name(state.player_turn))
	end
	alexgames.set_status_msg(string.format("Waiting for %s to move", display_name))
end

function handle_popup_btn_clicked(popup_id, btn_idx)
	if two_player.handle_popup_btn_clicked(popup_id, btn_idx) then
		-- handled, no action here
	elseif popup_id == GAME_OVER_POPUP_ID then
		if btn_idx == 0 then
			new_game()
			alexgames.hide_popup()
		end
	else
		print(string.format("Unexpected popup_id \"%s\"", popup_id));
		alexgames.hide_popup()
	end
end

function two_player_init()
	local args = {
		supports_local_multiplayer = true,
		handle_multiplayer_type_choice = function (multiplayer_type)
			if multiplayer_type == two_player.MULTIPLAYER_TYPE_LOCAL then
				local_multiplayer = true
			elseif multiplayer_type == two_player.MULTIPLAYER_TYPE_NETWORK then
				local_multiplayer = false
			end
		end,
		title = "Choose piece colour",
		player_choices = PLAYER_CHOICE_BTNS,
		choice_id_to_player_id = function (btn_id)
			return PLAYER_CHOICE_BTNS_MAP[btn_id]
		end,
		player_name_to_id = player_name_to_id,
		player_id_to_nice_name = function (player_id)
			local player_colour = wu.player_idx_to_colour_name(player_id)
			return utils.make_first_char_uppercase(player_colour)
		end,
		get_msg = function ()
			local msg = "Black moves first."
			--local other_player = wu_ctrl.get_other_player(ctrl_state)
			if utils.table_len(player_name_to_id) == 0 then
				msg = msg .. "\nThe other player has not yet chosen."
			else
				--msg = msg .. string.format("The other player has chosen %s",
				--                           wu.player_idx_to_colour_name(other_player))
				for player_name, player_id in pairs(player_name_to_id) do
					local player_colour = wu.player_idx_to_colour_name(player_id)
					msg = msg .. string.format("\n%s is chosen by %s", utils.make_first_char_uppercase(player_colour), player_name)
				end
			end
			return msg
		end,
		handle_player_choice = function (player_name, player_id)
			local choice_str = wu.player_idx_to_colour_name(player_id)
			print(string.format("handle_player_choice{ player_name=\"%s\", choice=%q (%q) }", player_name, player_id, choice_str))
			if player_name == two_player.LOCAL_PLAYER then
				wu_ctrl.player_chosen(ctrl_state, player_id)
				update_status_msg_turn(state, ctrl_state)
			else
				wu_ctrl.other_player_chosen(ctrl_state, player_id)

			end
			print(string.format("we are %q, other player is %q",
			      wu_ctrl.get_player(ctrl_state), wu_ctrl.get_other_player(ctrl_state)))
		end,

		need_reselect = function ()
			local this_player  = wu_ctrl.get_player(ctrl_state)
			local other_player = wu_ctrl.get_other_player(ctrl_state)

			-- print(string.format("needs_reselect { this_player = %q, other_player = %q }", this_player, this_player == other_player))
			return this_player == nil or this_player == other_player
		end,

		get_local_player_choice = function ()
			return wu_ctrl.get_player(ctrl_state)
		end
	}
	two_player.init(args)
end

function handle_game_option_evt(option_id)
	if option_id == OPTION_ID_NEW_GAME then
		new_game()
	else
		error(string.format("Unhandled option_id %s", option_id))
	end
end


function get_state()
	return wu.serialize_state(state)
end

function load_state_helper(session_id_arg, serialized_state)
	session_id = session_id_arg
	state = wu.deserialize_state(serialized_state)
end


function load_state_move_offset(move_offset)
	local serialized_state = alexgames.get_saved_state_offset(session_id, move_offset)
	load_state_helper(session_id, serialized_state)
	update()
	send_state()
end


function lua_main()
	while true do
		print_board()
		::read_input::
		local user_input = get_user_input()
		local rc = handle_user_string_input(user_input)
		if rc ~= wu.SUCCESS then
			print('Error: '.. wu.err_code_to_str(rc))
			goto read_input
		end
	end
end


function start_game(session_id_arg, serialized_state)
	local last_sess_id = alexgames.get_last_session_id()

	if serialized_state ~= nil then
		print("Loading state from URL param")
		load_state_helper(session_id_arg, serialized_state)
	elseif last_sess_id ~= nil then
		print("Loading autosaved state")
		serialized_state = alexgames.get_saved_state_offset(last_sess_id, 0)
		load_state_helper(last_sess_id, serialized_state)
	else
		print("Starting new game, no URL param or autosaved state found")
		new_game()
	end
	two_player_init()
	alexgames.send_message("all", "get_state:")

	alexgames.add_game_option(OPTION_ID_NEW_GAME, { type = alexgames.OPTION_TYPE_BTN, label = "New Game"})
end
