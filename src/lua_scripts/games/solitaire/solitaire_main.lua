
local alexgames = require("alexgames")

local core = require("games/solitaire/solitaire_core")
local draw = require("games/solitaire/solitaire_draw")
local serialize = require("games/solitaire/solitaire_serialize")
local utils = require("libs/utils")
local storage_helpers = require("libs/serialize/storage_helpers")

-- Here is a winnable game state, for testing:
-- from the beginning
-- http://localhost:1234/?game=solitaire&state=AQEYKy0fJRwWDxUiAzEOIB0wCAkRBBkjGBoTAAAAARABDQEkAgsuAQIDKSEBASwELwAeFwEGBQUqKDMbAQwGByYSFCcyAQoAAAAAgPyBuwD%2f%2fv%2f+AAAAAGVH8nMAAAAAAANT1A%3d%3d
-- almost won:
--  http://localhost:1234/?game=solitaire&id=tczscg&state=AQEAAAAAAhkyAAIMJQACMwsAAAABJgAAAAALGhscHR4fICEiIyQMDQ4PEBESExQVFhcYCycoKSorLC0uLzAxCwABAgMEBQYHCAkKgK2B1AD%2f%2foAEAAAAAGVH8nMAAAAAAANT1A%3d%3d 
-- 01 01 00 00 00 00 01 19 00 00 00 00 00 00 00 00 00 00 00 00 0d 1a 1b 1c 1d 1e 1f 20 21 22 23 24 25 26 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 0d 27 28 29 2a 2b 2c 2d 2e 2f 30 31 32 33 0d 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 80 c9 80 4f 00 ff fe 80 01 00 00 00 00 65 47 f2 73 00 00 00 00 00 03 53 d4 

-- autocomplete testing
-- http://localhost:1234/?game=solitaire&id=tczscg&state=AQECKy0BHwEDAAsZMhcwCC4GLAQqAgAGDCUKIxUhAAczCyQJIhQgAAEpAAUmGDEWLwACBR4AAQcEGhscHQcNDg8QERITAicoAgABgPSB1QD%2f%2foADAAAAAGVH8nMAAAAAAANT1A%3d%3d


-- TODO:
--     * (WIP) auto complete button for when all hidden cards are revealed
--     * (DONE) tap on a card and have it move to goal stacks if possible
--     * (not started) (and maybe an option to move it to play columns... some games have this,
--        it's nifty but I find I hit it accidentally and feel like I "cheated")
--     * (DONE) undo button
--     * (DONE, but not working on Sabrina's iPhone??) maybe fix the "pick up cards" offset, so that when
--       you press a card its centre isn't
--       drawn where your finger is
--     * timer, move count, score/points
--     * fix bug where auto complete doesn't keep going if deck is closed (all cards are face down)
--     * (DONE) disable user input while animation is playing (including pressing animation button a second time!)
--     * make animations only "try" to move, not forcefully move the cards
--     * use card_offset for dropping cards. Right now, if you drag from the bottom right, if that little piece isn't
--       over the destination (even though the centre of the card is), it won't get dropped
--
--  Eventually:
--     * show if game is winnable or not (should be an option) after every move?
--     * have option to only generate winnable games (maybe hardcode a couple hundred at first)
--     * the ability to export state to a base 64 string, so you can copy it from your
--       phone to computer and vice versa? (Is there any way to leverage the server for this?)
--     * high scores / records (fewest moves, fastest time, most points?)
--
--     TODO for draw three:
--      * need to preserve popup state, save in persistent state: user should not have to switch from default (draw one) to draw three every time
--      * allow undo many times, use history browse API?
--      * don't save state again on new button presses, only on changes. And not when a card is revealed 
--      * constantly seeing "invalid session id", need to fix
--      * need to disable set_timer_update_ms outside of animations? The game is using a ton of CPU usage when idle...




local session_id = nil
local state = nil 
local g_shown_victory_animation = false
local g_anim_timer_handle = nil

local FPS = 60

-- TODO remove these in favour of the autosaved / history browser state
local DATA_ID_STATE      = "game_state"
local DATA_ID_PREV_STATE = "prev_game_state"

local DATA_ID_SHOW_TIME_AND_MOVE_COUNT = "show_time_and_move_count"

local GAME_OPTION_SHOW_TIME_AND_MOVE_COUNT = "opt_show_time_and_move_count"

draw.show_move_count_and_elapsed_time = storage_helpers.read_bool(DATA_ID_SHOW_TIME_AND_MOVE_COUNT, true)

local POPUP_ID_NEW_GAME = "new_game"
local POPUP_ITEM_ID_BTN_START_GAME = 1
local POPUP_ITEM_ID_BTN_CANCEL     = 2
local POPUP_ITEM_ID_DRAW_TYPE      = 3

-- This is to test what it looks like if the cards are stacked in the highest combination
-- right now it's cut off a bit, but might just barely work
-- if the number of the card is drawn on the corner of the card
--[[
state.play_columns_staging[7][1] = { suit = "spades", val = 13 }
state.deck_unrevealed = {
	{ suit = "diamonds", val = 12 },
	{ suit = "spades",   val = 11 },
	{ suit = "diamonds", val = 10 },
	{ suit = "spades",   val =  9 },
	{ suit = "diamonds", val =  8 },
	{ suit = "spades",   val =  7 },
	{ suit = "diamonds", val =  6 },
	{ suit = "spades",   val =  5 },
	{ suit = "diamonds", val =  4 },
	{ suit = "spades",   val =  3 },
	{ suit = "diamonds", val =  2 },
	{ suit = "spades",   val =  1 },
}
]]

local player = 1
local player_count = 1
local touches = {}
local active_touch = nil

local function draw_board_internal()

	if core.game_won(state) and not g_shown_victory_animation then
		print("Player won, showing victory animation")
		draw.victory_animation(FPS)
		g_shown_victory_animation = true
	end
	draw.draw_state(session_id, state)
end

-- TODO should never call the update_animations from anywhere but here,
-- and should call draw_board_internal in this file only, never `update` directly
function update(dt_ms)
	if dt_ms == nil then
		dt_ms = 0
	end
	--print(string.format("update(dt_ms=%s)", dt_ms))
	core.update_time_elapsed(state, dt_ms)
	draw.update_animations(state, dt_ms)
	draw_board_internal()
end

function handle_user_clicked(pos_y, pos_x)
end

function handle_mousemove(pos_y, pos_x)
	if state == nil then return end
	draw.set_is_touch_controlled(false)
	core.handle_mousemove(state, player, pos_y, pos_x)
	draw_board_internal()
end

local function save_state()
	local prev_state_serialized = alexgames.read_stored_data(DATA_ID_STATE)
	if prev_state_serialized ~= nil then
		alexgames.store_data(DATA_ID_PREV_STATE, prev_state_serialized)
	end
	local state_serialized = serialize.serialize_state(state)
	alexgames.store_data(DATA_ID_STATE, state_serialized)
	-- TODO this is now kind of redundant, consider how to remove the old way of saving state
	alexgames.save_state(session_id, state_serialized)
end

local function load_prev_state()
--[[
	local prev_state_serialized = alexgames.read_stored_data(DATA_ID_PREV_STATE)
--]]
	print(string.format("loading prev state for session %s", session_id))
	-- If the player presses undo, we want all the previous state
	-- except we want the time elapsed to stay the same.
	local time_elapsed = state.time_elapsed
	local prev_state_serialized = alexgames.adjust_saved_state_offset(session_id, -1)
	if prev_state_serialized ~= nil then
		draw.stop_move_animations()
		state = serialize.deserialize_state(prev_state_serialized)
		state.time_elapsed = time_elapsed
		update()
		alexgames.set_status_msg("Loaded previous state")
	else
		alexgames.set_status_err("Can not load previous state, not found")
	end
end

local function add_offset(info)
	if info ~= nil then
		local card_pos = draw.get_pos(state, info.section_type, info.col, info.idx)
		if card_pos ~= nil then
			info.card_src_y = card_pos.y
			info.card_src_x = card_pos.x
		end
	end
end

local function mouse_evt_id_to_touch_evt(evt_id)
	if evt_id == 2 then
		return 'touchstart'
	elseif evt_id == 1 then
		return 'touchend'
	elseif evt_id == 3 then
		return 'touchcancel'
	else
		error("unexpected evt_id ", evt_id)
	end
end

local function new_game()
	alexgames.show_popup(POPUP_ID_NEW_GAME, {
	                          title = "New Game",
	                          items  = {
	                              {
	                                  id        = POPUP_ITEM_ID_DRAW_TYPE,
	                                  item_type = alexgames.POPUP_ITEM_TYPE_DROPDOWN,
	                                  label     = "Draw",
	                                  options   = { "One", "Three" },
	                              },
	                              {
	                                  id        = POPUP_ITEM_ID_BTN_START_GAME,
	                                  item_type = alexgames.POPUP_ITEM_TYPE_BTN,
	                                  text      = "Start game",
	                              },
	                              {
	                                  id        = POPUP_ITEM_ID_BTN_CANCEL,
	                                  item_type = alexgames.POPUP_ITEM_TYPE_BTN,
	                                  text      = "Cancel",
	                              },
	                          },
	                      })
end


local function handle_nil_state_click()
	new_game()
end

function handle_mouse_evt(evt_id, pos_y, pos_x)
	if state == nil then 
		if evt_id == alexgames.MOUSE_EVT_DOWN or evt_id == alexgames.MOUSE_EVT_UP then
			handle_nil_state_click()
		end
		return
	end
	local info = draw.pos_to_action(state, player, pos_y, pos_x, mouse_evt_id_to_touch_evt(evt_id))
	add_offset(info)
	if evt_id == 2 then
		local rc = core.handle_mouse_down(player, state, info)
		if rc then
			save_state()
		end
	elseif evt_id == 1 then
		local rc = core.handle_mouse_up(player, state, info)
		if rc then
			save_state()
		end
	elseif evt_id == 3 then
		-- TODO ideally this should cancel rather than release normally
		core.handle_mouse_up(player, state, info)
	end

	draw_board_internal()
end

function handle_touch_evt(evt_id, changed_touches)
	if state == nil then return handle_nil_state_click() end
	draw.set_is_touch_controlled(true)
	local rc = false
	for _, touch in ipairs(changed_touches) do
		local y = math.floor(touch.y)
		local x = math.floor(touch.x)
		if active_touch == touch.id then
			if evt_id == 'touchmove' then
				core.handle_mousemove(state, player, y, x)
			elseif evt_id == 'touchend' then
				local info = draw.pos_to_action(state, player, y, x, evt_id)
				rc = core.handle_mouse_up(player, state, info)
				active_touch = nil
			elseif evt_id == 'touchcancel' then
				rc = core.handle_mouse_up(player, state, nil)
				active_touch = nil
			end
		end

		if evt_id == 'touchstart' then
			if active_touch == nil then
				active_touch = touch.id
				local info = draw.pos_to_action(state, player, y, x, evt_id)
				add_offset(info)
				core.handle_mouse_down(player, state, info)
			end
		end
	end
	draw_board_internal()
	if rc then
		save_state()
	end
end

local function on_anim_finished()
	save_state()
	if g_anim_timer_handle == nil then
		print("on_anim_finished: g_anim_timer_handle is nil")
	else
		alexgames.delete_timer(g_anim_timer_handle)
		g_anim_timer_handle = nil
	end
end

local function handle_move_list_animation(move_list)

	if g_anim_timer_handle ~= nil then
		alexgames.set_status_err("warning: g_anim_timer_handle was not nil on auto complete btn pressed")
		alexgames.delete_timer(g_anim_timer_handle)
		g_anim_timer_handle = nil
	end
	g_anim_timer_handle = alexgames.set_timer_update_ms(1000/FPS)

	draw.animate_moves(state, move_list, on_anim_finished)
end

local function start_new_game(draw_type)
	g_shown_victory_animation = false
	session_id = alexgames.get_new_session_id()
	local params = {}
	state = core.new_game(player_count, draw_type, params)
	print(string.format("Starting new game (session=%d) (seed %016x %016x) with state: %s",
	      session_id, state.seed_x, state.seed_y,
	      utils.binstr_to_hr_str(serialize.serialize_board_state(state))))
	alexgames.set_status_msg(string.format("Generated new grame with seed %x %x", state.seed_x, state.seed_y))
	draw.stop_move_animations()
	save_state()
	draw_board_internal()
end

-- TODO do this in C API instead
local function key_val_list_to_map(list)
	local map = {}
	for _, item in ipairs(list) do
		print(string.format("key=%s, vale=%s", item.id, item.selected))
		map[item.id] = item.selected
	end
	return map
end

function handle_popup_btn_clicked(popup_id, btn_id, popup_state)
	if popup_id == POPUP_ID_NEW_GAME then
		if btn_id == POPUP_ITEM_ID_BTN_START_GAME then
			local popup_state_map = key_val_list_to_map(popup_state)
			local draw_type_dropdown_selected = popup_state_map[POPUP_ITEM_ID_DRAW_TYPE]
			local draw_type = nil
			if draw_type_dropdown_selected == 0 then
				draw_type = core.DRAW_TYPE_ONE
			elseif draw_type_dropdown_selected == 1 then
				draw_type = core.DRAW_TYPE_THREE
			else
				error(string.format("Unhandled new game popup dropdown sel %s", draw_type_dropdown_selected))
			end
			start_new_game(draw_type)
			alexgames.hide_popup()
		elseif btn_id == POPUP_ITEM_ID_BTN_CANCEL then
			alexgames.hide_popup()
		else
			error(string.format("Unhandled new game popup btn id %s", btn_id))
		end
	else
		error(string.format("Unhandled popup \"%s\"", popup_id))
	end
end

function handle_btn_clicked(btn_id)
	if btn_id == draw.BTN_ID_AUTO_COMPLETE then
		core.autocomplete(state, handle_move_list_animation)
	elseif btn_id == draw.BTN_ID_NEW_GAME then
		--alexgames.set_status_msg("Starting new game")
		new_game()
	elseif btn_id == draw.BTN_ID_UNDO then
		load_prev_state()
	else
		error(string.format("Unhandled btn_id \"%s\"", btn_id))
	end
end


function load_hr_binstr_state(version, hr_binstr_state)
	local state_board_serialized = utils.hr_binstr_to_binstr(hr_binstr_state)
	local board_state = serialize.deserialize_board_state(version, state_board_serialized)
	state = core.new_state_from_board_state(player_count, board_state)
	update()
end

function load_saved_state(session_id_arg, state_serialized)
	alexgames.set_status_msg(string.format("Loading saved state: %d bytes", #state_serialized)) -- TODO show date of last played?
	local hr_state_serialized = utils.binstr_to_hr_str(state_serialized)
	print("Serialized state: " .. hr_state_serialized)
	session_id = session_id_arg
	state = serialize.deserialize_state(state_serialized)
	g_shown_victory_animation = false
end

function get_state()
	if state == nil then return nil end
	return serialize.serialize_state(state)
end

function get_init_state()
	-- TODO I didn't look into this, but it's possible that the Lua random number seed
	-- stuff is not guaranteed to be consistent across versions of Lua.
	-- So this isn't super robust. I think that's fine for now.
	-- If you generate a state link via `get_state` and send it to a friend, and they're in
	-- a different version of Lua, then they might not be able to get the initial state
	-- themselves.
	--
	-- Partway through implementing this, I realized that all the states are saved in the
	-- history browser anyway, so I should just add a new API to load the oldest state.
	-- But that has two problems:
	--     1. if you share a link, it won't contain the original state. (Though I could add it,
	--        I suppose, doubling the size of the state)
	--     2. I will probably start pruning old saved states at some point, since I think
	--        the browser limits you to ~5 MB. (When I do that, I should add the option to mark
	--        some saved states as "more important".
	if state and state.seed_x and state.seed_y then
		local params = {
			seed_x = state.seed_x,
			seed_y = state.seed_y,
		}
		local init_state = core.new_game(player_count, state.draw_type, params)
		print(string.format("Generated initial state from seeds %016x %016x:", state.seed_x, state.seed_y))
		core.print_state(init_state)
		return serialize.serialize_state(init_state)
	else
		return ""
	end
end

function handle_game_option_evt(option_id, value)
	print(string.format("handle_game_option(option_id=%s, value=%s)", option_id, value))
	if option_id == GAME_OPTION_SHOW_TIME_AND_MOVE_COUNT then
		draw.show_move_count_and_elapsed_time = value
		storage_helpers.store_bool(DATA_ID_SHOW_TIME_AND_MOVE_COUNT, value)
		draw_board_internal()
	end
end

draw.init(480, 480)

function start_game(session_id_arg, state_serialized) 
	print(string.format("start_game(session_id=%d, state_serialized=%s)", session_id_arg, state_serialized))

	alexgames.enable_evt('mouse_move')
	alexgames.enable_evt('mouse_updown')
	alexgames.enable_evt('touch')
	
	if state_serialized ~= nil then
		print(string.format("start_game: loading from state param"))
		session_id = session_id_arg
		load_saved_state(session_id_arg, state_serialized)
		print(string.format("start_game: done loading from state param"))
	else
		-- this shouldn't be happening anymore, right?
		--print(string.format("start_game: no state param provided, checking if saved game stored in persistent storage"))
		--local state_serialized = alexgames.read_stored_data(DATA_ID_STATE)
		local last_session_id = alexgames.get_last_session_id()
		if last_session_id ~= nil then
			state_serialized = alexgames.adjust_saved_state_offset(last_session_id, 0)
		end

		-- this shouldn't usually be possible, but I think it happens if I manage to increment the session ID
		-- without storing a valid state.
		if state_serialized ~= nil then
			load_saved_state(last_session_id, state_serialized)
		else
			alexgames.set_status_msg("No saved state found, starting new game")
			new_game()
		end
	end

	alexgames.add_game_option(GAME_OPTION_SHOW_TIME_AND_MOVE_COUNT, {
		type  = alexgames.OPTION_TYPE_TOGGLE,
		label = "Show elapsed time and move count",
		value = draw.show_move_count_and_elapsed_time,
	} )
	
	-- Set a timer for every second, to update the "time elapsed" in the corner
	alexgames.set_timer_update_ms(1000)
end
