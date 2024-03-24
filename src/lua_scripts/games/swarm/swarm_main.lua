--[[
--
-- TODO better AoE damage:
--   hard to do much AoE damage when the attacks are consumed as soon as they hit the edge of a mob of enemies, especially the hammer.
--   should mark them as "remove in 300 ms" or something, so they get some time to do more damage.
--   maybe also only let them do a certain amount of damage
--
-- TODO:
--   * add touch dirpad, refactor into common library for use with other games like thrust and hospital/bound
--
--]]
local core = require("games/swarm/swarm_core")
local draw = require("games/swarm/swarm_draw")
local keyboard_input = require("games/swarm/swarm_keyboard_input")
local alex_c_api = require("alex_c_api")

local FPS = 60
--local FPS = 2
local MS_PER_FRAME = math.floor(1000/FPS)
local player_idx = 1

local is_paused = false

local height = 480
local width  = 480

local g_state = {
	ui = draw.init(height, width),
	game = core.new_state(1),
	key_state = keyboard_input.new_key_state(),
}

function draw_board()
	draw.draw_state(g_state.game, g_state.ui, player_idx)
	if not is_paused then
		core.update_state(g_state.game, MS_PER_FRAME)
	end
end

function handle_key_evt(evt, code)
	local handled = false
	if code == "KeyP" and evt == "keydown" then
		is_paused = not is_paused
		local pause_str
		if is_paused then
			pause_str = "paused"
		else
			pause_str = "unpaused"
		end
		alex_c_api.set_status_msg(string.format("Game %s. (Press \"P\" to toggle)", pause_str))
		handled = true
	end
	local info = keyboard_input.get_move_vec_from_key_evt(g_state.key_state, evt, code)
	handled = handled or info.handled
	core.set_player_move_vec(g_state.game, player_idx, info.vec)
	return handled
end

function handle_touch_evt(evt, touches)
	local actions = draw.handle_touch_evts(g_state.ui, evt, touches)
	for _, action in ipairs(actions) do
		if action.action_type == draw.ACTION_PLAYER_VEC_CHANGE then
			core.set_player_move_vec(g_state.game, player_idx, action.new_player_vec)
		end
	end
end

alex_c_api.set_timer_update_ms(MS_PER_FRAME)
alex_c_api.enable_evt("key")
alex_c_api.enable_evt("touch")
