-- Game:   Chess
-- Author: Alex Barry (github.com/alexbarry)
--[[
TODO:
* implement logic for check and checkmate
* prevent player from moving into check
* implement serializing state so state can be saved or network games can be played
* implement castling
* implement pawn en-passant capturing?? (I didn't even know about this rule)
* implement history (undo/redo)
--]]
local alexgames = require("alexgames")

local core = require("games/chess/chess_core")
local draw = require("games/chess/chess_draw")
local serialize = require("games/chess/chess_serialize")

local utils = require("libs/utils")
local two_player = require("libs/multiplayer/two_player")

local g_session_id = alexgames.get_new_session_id()
local g_state = core.new_game()
--local player = core.PLAYER_WHITE
local player = nil
local local_multiplayer = nil
local player_name_to_id = {}
local g_other_player = nil
local session_id = alexgames.get_new_session_id()

local SELECT_PLAYER_POPUP_ID = "select_player"
local PLAYER_CHOICE_BTNS = {
	"White",
	"Black",
}
local BTN_MAP = {
    [0] = core.PLAYER_WHITE,
    [1] = core.PLAYER_BLACK,
}


local BTN_ID_UNDO = "btn_undo"
local BTN_ID_REDO = "btn_redo"

local POPUP_ID_NEW_GAME          = "game_over"
local POPUP_ITEM_ID_NEW_GAME_BTN = 1

local OPTION_ID_NEW_GAME = "new_game"

function get_player()
	if local_multiplayer then
		return g_state.player_turn
	else
		return player
	end
end

function get_other_player(player)
	if player == core.PLAYER_WHITE then
		return core.PLAYER_BLACK
	elseif player == core.PLAYER_BLACK then
		return core.PLAYER_WHITE
	else
		error(string.format("unexpected player: %s", player), 2)
	end
end

local function get_draw_state_params()
	return {
		local_multiplayer = local_multiplayer,
		player            = player,
	}
end

draw.init(480,480, false)
local function draw_board_internal()
	--core.print_state(g_state)
	draw.draw_state(g_state, get_draw_state_params())
	alexgames.set_btn_enabled(BTN_ID_UNDO, alexgames.has_saved_state_offset(g_session_id, -1))
	alexgames.set_btn_enabled(BTN_ID_REDO, alexgames.has_saved_state_offset(g_session_id,  1))
end

function update()
	draw_board_internal()
end

function handle_rc(rc, is_other_player)
	if rc == core.SUCCESS then
		-- TODO need to come up with a way to only save real moves
		save_state()
		alexgames.set_status_msg(core.get_status_msg(g_state))
		local state_serialized = serialize.serialize_state(g_state)
		print(string.format("State is now: %s", utils.binstr_to_hr_str(state_serialized)))
	elseif rc == core.RC_GAME_OVER then
		local msg = core.get_status_msg(g_state)
		alexgames.set_status_msg(msg)
		alexgames.show_popup(POPUP_ID_NEW_GAME, { title = "Game Over", items = {
			{ item_type = alexgames.POPUP_ITEM_TYPE_MSG, msg = msg },
			{ id = POPUP_ITEM_ID_NEW_GAME_BTN, item_type = alexgames.POPUP_ITEM_TYPE_BTN, text = "New Game" },
		} })
	else
		local msg = core.get_err_msg(rc)
		if is_other_player then
			msg = "Other player invalid move: " .. msg
		end
		alexgames.set_status_err(msg)
	end
end

function handle_user_clicked(pos_y, pos_x)
	local coords = draw.draw_coords_to_cell(pos_y, pos_x)
	local rc = core.player_touch(g_state, get_player(), coords)
	if not local_multiplayer and rc == core.SUCCESS then
		alexgames.send_message("all", string.format("move:%d,%d,%d", get_player(), coords.y, coords.x))
	end
	handle_rc(rc)
	--core.print_state(g_state)
	draw_board_internal()
end

function handle_popup_btn_clicked(popup_id, btn_id, popup_state)
	 if two_player.handle_popup_btn_clicked(popup_id, btn_id) then
        -- handled
	elseif popup_id == POPUP_ID_NEW_GAME then
		if btn_id == POPUP_ITEM_ID_NEW_GAME_BTN then
			start_game()
			alexgames.hide_popup()
		else	
			error(string.format("Unhandled btn_id=\"%s\"", btn_id))
		end
	else
		error(string.format("Unhandled popup_id=\"%s\"", popup_id))
	end
end

local function broadcast_state(dst)
	alexgames.send_message(dst, "state:" .. serialize.serialize_state(g_state))
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
		local coords = { y = y, x = x }
        local rc = core.player_touch(g_state, player_idx, coords)
        handle_rc(rc, --[[is_other_player=]] true)

        if rc ~= core.SUCCESS then
            alexgames.set_status_err("Other player made an invalid move")
        else
            alexgames.set_status_msg("Your move")
            draw_board_internal()
            save_state()
        end

    elseif header == "get_state" then
		broadcast_state(src)
    elseif header == "state" then
        local recvd_state = serialize.deserialize_state(payload)
        print("Recieved state:")
        --core.print_state(recvd_state)
        g_state = recvd_state
        draw_board_internal()
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
				player = g_state.player_turn
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
            local msg = "White moves first."
            if utils.table_len(player_name_to_id) == 0 then
                msg = msg .. "\nThe other player has not yet chosen."
            else
                --msg = msg .. string.format("The other player has chosen %s",
                --                           core.player_id_to_name(other_player))
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

local function load_state(session_id_arg, state_serialized)
	g_session_id = session_id_arg
	g_state = serialize.deserialize_state(state_serialized)
end

local function load_state_offset(session_id_arg, move_offset)
	local state_serialized = alexgames.adjust_saved_state_offset(session_id_arg, move_offset)
	if state_serialized == nil then
		error(string.format("state_serialized is nil"))
	end
	load_state(session_id_arg, state_serialized)
	broadcast_state("all")
end

function save_state()
	local serialized_state = serialize.serialize_state(g_state)
	alexgames.save_state(g_session_id, serialized_state)
end

function handle_btn_clicked(btn_id)
	if btn_id == BTN_ID_UNDO then
		load_state_offset(g_session_id, -1)
		draw_board_internal()
	elseif btn_id == BTN_ID_REDO then
		load_state_offset(g_session_id, 1)
		draw_board_internal()
	else
		error(string.format("Unhandled btn_id %s", btn_id)) 
	end
end

function handle_game_option_evt(option_id)
	if option_id == OPTION_ID_NEW_GAME then
		g_session_id = alexgames.get_new_session_id()
		g_state = core.new_game()
		save_state()
		draw_board_internal()
	end
end

function get_state()
	return serialize.serialize_state(g_state)
end

function start_game(session_id_arg, state_serialized)
	local state_loaded = false
	if state_serialized ~= nil then
		load_state(session_id_arg, state_serialized)
		state_loaded = true
	else
		local saved_session_id = alexgames.get_last_session_id()
		if saved_session_id ~= nil and alexgames.has_saved_state_offset(saved_session_id, 0) then
			alexgames.set_status_msg(string.format("Loading saved state session %d", saved_session_id))
			load_state_offset(saved_session_id, 0)
			state_loaded = true
		end
	end

	two_player_init()

	alexgames.send_message("all", "get_state:")

	alexgames.add_game_option(OPTION_ID_NEW_GAME, { type = alexgames.OPTION_TYPE_BTN, label = "New Game" })

	alexgames.create_btn(BTN_ID_UNDO, "Undo", 1)
	alexgames.create_btn(BTN_ID_REDO, "Redo", 1)
	--[[
	g_session_id = alexgames.get_new_session_id()
	g_state = core.new_game()
	player = core.PLAYER_WHITE
	local_multiplayer = true
	update()
	--]]
end
