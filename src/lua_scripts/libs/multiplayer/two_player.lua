--[[
-- This is a simple helper class for games that require exactly two players,
-- optionally supporting local multiplayer, or network multiplayer
-- where it is desirable to allow a player to quit, rejoin later, and even
-- select a different player (perhaps even the player that is already joined).
-- This seems good for strategy games, where there is no hidden information.
-- Though I'm now adding the ability to indicate which player selected their
-- player number first, so that for games with random information (e.g. dice
-- roll), one player can be responsible for rolling the dice.
--
-- e.g. if you are playing go/wu/checkers/chess against someone, but they
-- want to switch devices, or you want to switch devices, they could leave,
-- join on a different device, and then select black or white.
--
-- Things to add in the future:
--     * a spectate option
--]]

local two_player = {}

local alexgames = require("alexgames")
local show_buttons_popup = require("libs/ui/show_buttons_popup")

-- This message is sent by a player who chooses if they want to be e.g. black or white.
local MSG_HEADER_AM_PLAYER = 'am_player'
local MSG_HEADER_PLAYER_JOINED = 'two_player_player_joined'


two_player.THIS_PLAYER = "You"
two_player.MULTIPLAYER_TYPE_LOCAL   = "local"
two_player.MULTIPLAYER_TYPE_NETWORK = "network"

two_player.PLAYER_CHOICE_POPUP_ID = "two_player_choice_popup"
two_player.MULTIPLAYER_TYPE_POPUP_ID = "two_player_multiplayer_type_popup"

local multiplayer_types_btns = {
	"Local multiplayer (two players on this device)",
	"Network multiplayer (players on different devices)",
}
local multiplayer_type_btn_local   = 0
local multiplayer_type_btn_network = 1

-- "src" argument passed to args.handle_player_choice(src, player_choice) indicating that
-- it is the local player (player using this device to play on), rather than a player
-- over the network
two_player.LOCAL_PLAYER = "_two_player_local_player"

--[[
	args = {
		-- if true, will show a separate popup asking if the user wants to play local
		   multiplayer or play against someone on the network.
		-- if false, will jump straight to waiting for network players
		supports_local_multiplayer = true|false,

		-- multiplayer_type is either:
		--     two_player.MULTIPLAYER_TYPE_LOCAL
		--     two_player.MULTIPLAYER_TYPE_NETWORK
		handle_multiplayer_type_choice = function (multiplayer_type)
		end,
		title   = "Choose piece colour",
		player_choices = { "Black", "White" }
		player_name_to_id,  -- Reference to map of player name/ID to player ID

		-- function returning nice name (e.g. "White" or "Black")
		player_id_to_nice_name = function (player_id)
		end,

		get_msg = function ()
		              local msg = "Black moves first.\n"
		              if state.other_player == nil then
		                  msg = msg .. "The other player has not yet chosen."
		              else
		                  -- "state" here is not visible by this library, it can be whatever
		                  -- the game wants
		                  msg = msg .. "The other player has chosen player_idx_to_colour_name(state.other_player)"
		              end
		              return msg
		end,

		-- src is either:
		--    * two_player.LOCAL_PLAYER if the player choice is from the local player (the one playing on this device), or
		--    * the other player's IP/name if it's from a network player
		-- player_choice: is an integer representing the (1 based) index of args.player_choices
		handle_player_choice = function (src, player_choice)
			-- e.g. update state.other_player or state.this_player,
		end,

		-- returns nil if the local player has not chosen yet,
		-- otherwise sends the index of their choice.
		-- This is used when a new player joins, to tell them the local player's choice.
		get_local_player_choice = function ()
		end,
	 }
--]]

-- TODO maybe create a class for this instead
local g_args  = nil
local g_state = {
	-- TODO currently this tracks the player who selects their piece choice (white/black)
	-- first. But I think it might be better to choose the "host" based on who joined
	-- first. But currently I don't think there is any message sent to this library
	-- when a player joins without selecting a piece? I'm not sure.
	players_join_order = {},
	multiplayer_type_selected = nil,
}

local function need_player_reselect(remote_player)
	local local_player  = g_args.get_local_player_choice()
	--local remote_player = g_args.get_remote_player_choice()

	
	return local_player == nil or local_player == remote_player
end

local function show_player_choice_popup()
	show_buttons_popup.show_popup(two_player.PLAYER_CHOICE_POPUP_ID,
	                              g_args.title,
	                              g_args.get_msg(),
	                              g_args.player_choices)
end

local function show_multiplayer_type_popup()
	show_buttons_popup.show_popup(two_player.MULTIPLAYER_TYPE_POPUP_ID,
	                              "Multiplayer type",
	                              "",
	                              --"Choose to have two players on this device, or to play against someone over the network",
	                              --"Choose either:\n" ..
	                              --"* local multiplayer (two players using the same device), or\n" ..
	                              --"* network multiplayer (one player on this device, another on a separate device)",
	                              multiplayer_types_btns)
	                      
end

function two_player.init(args)
	if args.title == nil then
		error("args.title is nil", 2)
	end
	if args.player_choices == nil then
		error("args.player_choices is nil", 2)
	end
	if args.handle_multiplayer_type_choice == nil then
		error("args.handle_multiplayer_type_choice is nil", 2)
	end
	if args.player_choices == nil then
		error("args.player_choices is nil", 2)
	end
	if args.player_name_to_id == nil then
		error("args.player_name_to_id is nil", 2)
	end
	if args.player_id_to_nice_name == nil then
		error("args.player_id_to_nice_name is nil", 2)
	end
	if args.get_msg == nil then
		error("args.get_msg is nil", 2)
	end

	g_args  = args
	if g_args.supports_local_multiplayer then
		show_multiplayer_type_popup()
	else
		show_player_choice_popup()
	end
	alexgames.send_message("all", string.format("%s:", MSG_HEADER_PLAYER_JOINED))
end

local function broadcast_this_player_choice(player_choice)
	alexgames.send_message("all", string.format("%s:%d", MSG_HEADER_AM_PLAYER, player_choice))
end

local function add_player(state, src)
	for _, player_name in ipairs(state.players_join_order) do
		if player_name == src then
			return
		end
	end

	table.insert(state.players_join_order, src)
end

local function remove_player(state, src)
	local player_idx = nil
	for idx, val in ipairs(state.players_join_order) do
		if val == src then
			player_idx = idx
			break
		end
	end

	if player_idx ~= nil then
		table.remove(state.players_join_order, player_idx)
	else
		-- This can happen if:
		-- remote player joins
		-- current player joins
		-- remote player leaves -- current player gets the notification that the
		--  remote player left, but there's no entry in this table to remove.
		print(string.format("Could not find player %s in players_join_order", src))
	end
end

function two_player.am_first_player()
	local players_join_order = g_state.players_join_order 
	return #players_join_order > 0 and players_join_order[1] == two_player.THIS_PLAYER
end

function two_player.get_player_count()
	return #g_state.players_join_order
end

-- returns true if the message was handled, false otherwise
function two_player.handle_msg_received(src, msg)
	if g_state.multiplayer_type_selected == two_player.MULTIPLAYER_TYPE_LOCAL then
		return true
	end

	-- print("handle_msg_received (from src:" .. src .. "): " .. msg);
	local m = msg:gmatch("([^:]+):(.*)")
	local header, payload
	header, payload = m()

	if header == MSG_HEADER_AM_PLAYER then
		if g_args == nil then
			error("two_player.init not called yet, but received msg")
		end
		local other_player = tonumber(payload)
		g_args.player_name_to_id[src] = other_player
		add_player(g_state, src)
		--g_args.handle_player_choice(src, other_player)
		if need_player_reselect(other_player) then
			if g_state.multiplayer_type_selected == two_player.MULTIPLAYER_TYPE_NETWORK then
				show_player_choice_popup()
			end
		else
			alexgames.hide_popup()
		end
		-- Make sure that `hide_popup` isn't called after calling this, since
		-- the client may show their own popup that this library shouldn't hide.
		g_args.handle_player_choice(src, other_player)
		alexgames.set_status_msg(string.format("Player %s chose to be %s", src, g_args.player_id_to_nice_name(other_player)))
		return true
	elseif header == MSG_HEADER_PLAYER_JOINED then
		-- When new players join, if the local player has already chosen, then tell them.
		-- This way their popup will show the existing choice.
		local this_player_choice = g_args.get_local_player_choice()
		if this_player_choice ~= nil then
			broadcast_this_player_choice(this_player_choice)
		end
		alexgames.set_status_msg(string.format("Player %s joined", src))
		return true
	elseif header == "player_left" and src == "ctrl" then
		print("player left")
		local player_name = payload
		local player_id = g_args.player_name_to_id[player_name]
		alexgames.set_status_msg(string.format("Player %s (%s) left", player_name, g_args.player_id_to_nice_name(player_id)))
		g_args.player_name_to_id[player_name] = nil
		remove_player(g_state, player_name)
		-- TODO I don't see how this was ever true,
		-- and why show a popup when another player leaves?
		-- You can just make your move, and maybe they'll rejoin
		--[[
		if need_player_reselect() then
			if g_state.multiplayer_type_selected == two_player.MULTIPLAYER_TYPE_NETWORK then
				print("showing popup")
				show_player_choice_popup()
			end
		end
		--]]
		-- this is a system level message that is handled by more than just us, do not return false,
		-- allow the client to handle this too if necessary
		return false
	else
		--print(string.format("two_player: unhandled msg from src=\"%s\", header=\"%s\"", src, header))
		return false
	end
end

function two_player.handle_popup_btn_clicked(popup_id, btn_idx)
	if popup_id == two_player.PLAYER_CHOICE_POPUP_ID then
		local player_idx = g_args.choice_id_to_player_id(btn_idx)
		if player_idx == nil then
			error(string.format("btn_idx=%s, player_idx=%s", btn_idx, player_idx))
		end
		g_args.player_name_to_id[two_player.THIS_PLAYER] = player_idx
		add_player(g_state, two_player.THIS_PLAYER)
		broadcast_this_player_choice(player_idx)
		alexgames.hide_popup()
		g_args.handle_player_choice(two_player.LOCAL_PLAYER, player_idx)
		return true
	elseif popup_id == two_player.MULTIPLAYER_TYPE_POPUP_ID then
		if btn_idx == multiplayer_type_btn_local then
			alexgames.hide_popup()
			g_state.multiplayer_type_selected = two_player.MULTIPLAYER_TYPE_LOCAL
			g_args.handle_multiplayer_type_choice(two_player.MULTIPLAYER_TYPE_LOCAL)
		elseif btn_idx == multiplayer_type_btn_network then
			alexgames.hide_popup()
			g_state.multiplayer_type_selected = two_player.MULTIPLAYER_TYPE_NETWORK
			g_args.handle_multiplayer_type_choice(two_player.MULTIPLAYER_TYPE_NETWORK)
			show_player_choice_popup()
		else
			error(string.format("Unhandled multiplayer type btn=%q", btn_idx))
		end
		return true
	else
		return false
	end
end


return two_player
