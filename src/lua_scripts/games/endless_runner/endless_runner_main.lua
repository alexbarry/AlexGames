local core = require("games/endless_runner/endless_runner_core")
local draw = require("games/endless_runner/endless_runner_draw")

local alexgames = require("alexgames")

local FPS = 60

local g_state = nil

function draw_board(dt_ms)
	if dt_ms and dt_ms > 0 then
		core.update_state(g_state, dt_ms)
	end
	draw.draw_board(g_state)
end

local jump_keys = {
	["Space"]   = true,
	["Enter"]   = true,
	["ArrowUp"] = true,
	["KeyK"]    = true,
	["KeyW"]    = true
}

local function new_game()
	g_state = core.new_state()
end

function handle_key_evt(key_evt, key_id)
	print(string.format("evt=%s, id=%s", key_evt, key_id))
	if jump_keys[key_id] then
		if key_evt == "keydown" then
			core.jump(g_state, core.JUMP_TYPE_KEY)
		end
		return true
	end
	return false
end

function handle_mouse_evt(evt_id, pos_y, pos_x)
	if evt_id == alexgames.MOUSE_EVT_DOWN then
		core.jump(g_state, core.JUMP_TYPE_KEY)
		if draw.in_new_game_btn(state, pos_y, pos_x) then
			new_game()
		end
	end

end

function handle_touch_evt(evt_id, touches)
	for _, touch in ipairs(touches) do
		if evt_id == "touchstart" then
			core.jump(g_state, core.JUMP_TYPE_TOUCH)
			if draw.in_new_game_btn(state, touch.y, touch.x) then
				new_game()
			end
		end
	end

end

function start_game(session_id_arg, serialized_state_arg)
	new_game()

	alexgames.set_timer_update_ms(1000/FPS)
	alexgames.enable_evt("key")
	alexgames.enable_evt("mouse_updown")
	alexgames.enable_evt("touch")
end
