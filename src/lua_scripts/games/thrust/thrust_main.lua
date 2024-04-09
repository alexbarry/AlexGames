--[[

TODO:
* add a button to do a speed boost, or to increase the "max allowed speed"
* implement touch support with a joystick like the hospital game
* maybe implement mouse support?

* bug with checkpoints: I've missed a few sometimes. Need to draw them as lines on the screen,
  higlight the next one, and make it change colour once passed through

--]]
local core = require("games/thrust/thrust_core")
local draw = require("games/thrust/thrust_draw")
local key_input = require("games/thrust/thrust_keyboard_input")

local alexgames = require("alexgames")


--local FPS = 60
local FPS = 50
local TIME_PER_FRAME_MS = math.floor(1000/FPS)

local g_state = {
	ui       = draw.init(),
	game     = core.new_game_state(1),
	keyboard = key_input.new_input_state(),
}


function update(dt_ms)
	--core.update_state(g_state.game, TIME_PER_FRAME_MS/1000.0)
	core.update_state(g_state.game, dt_ms/1000.0)
	draw.draw_state(g_state.game, g_state.ui)
end

function handle_mousemove(y_pos, x_pos)
	--g_state.angle_degrees = math.floor(math.atan(480/2 - y_pos, 480/2 - x_pos)*180/3.14159 - 90)
	--print("handle_mousemove:", y_pos, x_pos, g_state.angle_degrees)
	--draw.draw_state(g_state.ui, g_state)
end


function handle_key_evt(evt_id, code)
	local player_state = g_state.game.players[1]
	local handled = key_input.handle_key_evt(g_state.keyboard, player_state, evt_id, code)
	if handled then
		draw.draw_state(g_state.game, g_state.ui)
	end
	return handled
end

function handle_touch_evt(evt_id, touches)
	local player_state = g_state.game.players[1]

	local actions = draw.handle_touch_evts(g_state.ui, evt_id, touches)

	for _, action in ipairs(actions) do
		if action.action == draw.ACTION_PLAYER_VEC_CHANGED then
			local vec = action.player_vec
			player_state.angle_degrees = math.atan(-vec.y, -vec.x) * 180 / math.pi - 90
			player_state.thrust_on = (vec.y ~= 0 and vec.x ~= 0)
		end
	end
end

-- In this game, it doesn't really make sense to save the state.
-- Well, ideally I'd implement some way to share your best times... maybe in
-- a future update.
function get_state()
	return nil
end

function start_game()
	alexgames.enable_evt("mouse_move")
	alexgames.enable_evt("key")
	alexgames.enable_evt("touch")
	alexgames.set_timer_update_ms(TIME_PER_FRAME_MS)
end
