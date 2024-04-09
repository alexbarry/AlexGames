-- Author: Alex Barry (github.com/alexbarry)
--
--[[

Should support both:
* "local" multiplayer (where a single user is using this app to track all players' bets/pots), or
* network multiplayer (where all players are using this app on their phones/computers and entering their own bets)


Expected sequence for network multiplayer:
* new player starts app, acts as host
* sends message to all, asking for state if anyone is host
* if receives a message from someone claiming to be a host, change to client, and load received state

TODO:
* need to show raising as relative to min bet
	* when raising, need to set "min bet" in keypad UI
* show dashed line above person who last raised

--]]
local alexgames  = require("alexgames")
local ui = require("games/poker_chips/poker_chips_ui")
local core = require("games/poker_chips/poker_chips_core")
local serialize = require("games/poker_chips/poker_chips_serialize")

local wait_for_players = require("libs/multiplayer/wait_for_players")
--local two_player = require("libs/multiplayer/two_player")


local player = 1

local players = {
	[1] = "You",
}


local SHOW_TEST_DATA = true


local state = {
	game = nil,
	ui   = nil,
}
state.game = core.new_state()

function get_player()
	-- TODO handle network multiplayer
	return state.game.player_turn
end

if SHOW_TEST_DATA then
	core.add_player(state.game, "Alex",    135)
	core.add_player(state.game, "Conor",   205)
	core.add_player(state.game, "Justin",   55)
	core.add_player(state.game, "Nick",    175)
	core.add_player(state.game, "Marc",    100)
	core.add_player(state.game, "Liam",    335)
	core.add_player(state.game, "Pranav",  220)
	core.add_player(state.game, "Shubham",  95)
end

core.print_state(state.game)

state.ui = ui.init()
ui.update(state.ui, state.game, get_player())

function draw_board() 
	ui.draw(state.ui)
end

local function update_state()
	for _, player in pairs(players) do
		if player == "You" then goto next_player end
		local serialized_state = serialize.serialize_state(state.game)
		print(string.format("Broadcasting state to player \"%s\", bytes %d", player, #serialized_state))
		alexgames.send_message(player, "state:" .. serialized_state)
		::next_player::
	end

end

function handle_user_string_input(str_input, is_cancelled)
	print(string.format("handle_user_string_input(str_input=\"%s\", is_cancelled=%q)", str_input, is_cancelled))
	alexgames.set_status_msg(string.format("handle_user_string_input(str_input=\"%s\", is_cancelled=%q)", str_input, is_cancelled))
end

function handle_user_clicked(y_pos, x_pos)
	local actions = ui.handle_user_clicked(state.ui, y_pos, x_pos)
	for _, action in ipairs(actions) do
		alexgames.set_status_msg(string.format("Received action %s", core.action_to_string(action)))
		local rc = core.handle_action(state.game, action)
		if rc ~= core.RC_SUCCESS then
			if rc == core.RC_BET_TOO_SMALL then
				alexgames.set_status_err(string.format("Your bet (%d) is lower than the minimum bet (%d)", action.param, state.game.min_bet))
			else
				alexgames.set_status_err(core.rc_to_string(rc))
			end
		else
			update_state()
			if action.on_success_callback ~= nil then
				action.on_success_callback()
			end
		end
	end
	ui.update(state.ui, state.game, get_player())
	ui.draw(state.ui)
end


function handle_popup_btn_clicked(popup_id, btn_idx)
	if wait_for_players.handle_popup_btn_clicked(popup_id, btn_idx) then
		-- handled
	else
		error(string.format("Unhandled popup_id=%s, btn_idx=%s", popup_id, btn_idx))
	end
end


function handle_msg_received(src, msg)
	if wait_for_players.handle_msg_received(src, msg) then
		return
	end

	local m = msg:gmatch("([^:]+):(.*)")
	local header, payload
	header, payload = m()

	if header == "state" then
		print(string.format("Received state from \"%s\", bytes %d", src, #payload))
		local received_state = serialize.deserialize_state(payload)
		state.game = received_state
		ui.update(state.ui, state.game, get_player())
		draw_board()
	else
		error(string.format("Unhandled message: %s", header))
	end

end

function start_host_game()
	-- TODO
end

function start_client_game()
	-- TODO
end

function start_game()
	wait_for_players.init(players, player, start_host_game, start_client_game)
end
