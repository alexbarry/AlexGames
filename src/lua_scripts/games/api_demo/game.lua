-- This is the "main" file of the example game "api_demo".
-- It is intended to show some examples of how the APIs work, including:
--     * drawing graphics,
--     * drawing lines, rectangles,
--     * setting a timer to update the game state and redraw 60 (`FPS`) times per second
--     * receiving keyboard ("key") events,
--     * receiving mouse events (mouse button pressed ("down"), released ("up"), move),
--     * receiving touch events (finger(s) pressed), only available on mobile.

-- These are other Lua files defined in the rest of the game bundle.
-- If this line is failing then either you removed them or renamed them in the zip you uploaded,
-- or I forgot to include the right path in Lua `package.path`.
-- Note that in most of the other games I wrote, I instead referenced the global path (something like "games/whatever_game/game_core")
-- and didn't bother adding the game's local directory to `package.path`. 
-- For uploaded games, I made an exception and added it.
local core = require("game_core") -- game_core.lua
local draw = require("game_draw") -- game_draw.lua

-- This is the API that I defined, defined in `lua_api.c`.
local alexgames = require("alexgames")


print(
"Hello, world! You should see this message in the developer tools console " ..
"if you\'re using the web version.")

-- The dots are simply to concatentate strings (instead of "+" like in most
-- languages). They could be omitted here, I just wanted to break
-- this long string across multiple lines.
print(string.format("If you're new to Lua, this is a way to achieve printf " ..
                    "like behaviour: %d %s %q",
                    123, "test", nil))

-- TODO these should come from an API
local board_height = 480
local board_width  = 480


-- This is calling into the "game_core.lua" file to create
-- a new table with the game's initial state.
local state = core.new_state(board_height, board_width)

local FPS = 60
local MS_PER_FRAME = math.floor(1000/FPS)


-- This function is called initially, and then many times repeatedly if `alexgames.set_timer_update_ms(time_ms)`
-- is called, to update state.
-- TODO I think it would also be cleaner to move away from global symbols like this, and instead register the important methods
-- in something like `alexgames.init({update=update})`, and register the others (key, touch, mousemove) when I enable those events.
function update()
	local dt_ms = MS_PER_FRAME


	if state.mouse_down or state.active_touch ~= nil then
		core.set_user_input_pos(state, {y=state.user_input_pos_y, x=state.user_input_pos_x})
	end

	-- Lua doesn't have an increment operator. This is not ideal, but whenever you encounter
	-- minor annoyances like this, try to remember that the entire interpreter compiles to ~400 kB of WASM and
	-- is wonderfully nice to integrate with C.
	-- And rather than apply a patch that does have an increment operator, I'd like be consistent with standard
	-- Lua (for now, at least).
	state.frame_idx = state.frame_idx + 1

	core.update_ball_pos(state, dt_ms)

	draw.draw(state)
end

-- Lua table (like a dictionary/hashmap) to track if a key is down
-- or not.
-- This way, when a user presses "up", we can check if they're also
-- pressing "left", and then move them diagonally.
local keys_pressed = {}

-- Lua table (like a dictionary/hashmap) to track if keys are handled or not.
-- This step is somewhat optional, I'm doing this so that we can tell the browser
-- which keys we don't handle, so it can choose to handle them
-- (e.g. not call evt.preventDefault() for Ctrl L (jump to address bar),
-- but it should call evt.preventDefault() for the arrow keys/WASD, so that
-- the arrow keys don't scroll on the page (as they normally would).
-- Instead, arrow keys move the player around.
local keys_handled = {
	['ArrowLeft']  = true,
	['ArrowRight'] = true,
	['ArrowUp']    = true,
	['ArrowDown']  = true,

	['KeyW']  = true,
	['KeyA']  = true,
	['KeyS']  = true,
	['KeyD']  = true,
}

function handle_key_evt(evt_id, key_code)
	print(string.format("handle_key_evt(evt=%s, code=%s)", evt_id, key_code))

	if not keys_handled[key_code] then
		local msg = string.format("key %s not handled", key_code)
		alexgames.set_status_msg(msg)
		print(msg)
		return false
	end

	if evt_id == 'keydown' then
		keys_pressed[key_code] = true
	elseif evt_id == 'keyup' then
		keys_pressed[key_code] = false
	else
		error(string.format("unhandled evt_id=%s", evt_id))
	end

	local x_vec = 0
	local y_vec = 0

	if keys_pressed['ArrowLeft']  or keys_pressed['KeyA'] then x_vec = x_vec - 1 end
	if keys_pressed['ArrowRight'] or keys_pressed['KeyD'] then x_vec = x_vec + 1 end
	if keys_pressed['ArrowUp']    or keys_pressed['KeyW'] then y_vec = y_vec - 1 end
	if keys_pressed['ArrowDown']  or keys_pressed['KeyS'] then y_vec = y_vec + 1 end

	local vec = nil
	if x_vec ~= 0 or y_vec ~= 0 then
		vec = { y = y_vec, x = x_vec }
	end

	core.set_user_input_vec(state, vec)
	return true
end


function handle_mouse_evt(evt_id, pos_y, pos_x)
	print(string.format("handle_mouse_evt(evt_id=%d, pos_y=%d, pos_x=%d)", evt_id, pos_y, pos_x))
	if evt_id == alexgames.MOUSE_EVT_DOWN then
		state.mouse_down = true
		state.user_input_pos_y = pos_y
		state.user_input_pos_x = pos_x
		--core.set_user_input_pos(state, {y=pos_y, x=pos_x})
	elseif evt_id == alexgames.MOUSE_EVT_UP then
		state.mouse_down = false
		core.set_user_input_pos(state, nil)
	elseif evt_id == alexgames.MOUSE_EVT_LEAVE then
		-- not handled, but including it here as an example 
	end
end

function handle_mousemove(pos_y, pos_x)
	if state.mouse_down then
		state.user_input_pos_y = pos_y
		state.user_input_pos_x = pos_x
		--core.set_user_input_pos(state, {y=pos_y, x=pos_x})
	end
end

function handle_touch_evt(evt_id, touches)
	print(string.format("handle_touch_evt(evt_id=%s, touches[%d])", evt_id, #touches))
	for _, touch in ipairs(touches) do
		if evt_id == 'touchstart' and state.active_touch == nil then
			state.active_touch = touch.id
			state.user_input_pos_y = touch.y
			state.user_input_pos_x = touch.x
		elseif evt_id == 'touchmove' and touch.id == state.active_touch then
			state.user_input_pos_y = touch.y
			state.user_input_pos_x = touch.x
		elseif evt_id == 'touchend' or evt_id == 'touchcancel' and touch.id == state.active_touch then
			state.active_touch = nil
			core.set_user_input_pos(state, nil)
		end
	end
		
end

-- This function is called when the game is started.
-- It is better to put game init stuff here than at the top level,
-- so that the game code could be loaded only once, but multiple game states
-- could be rendered (e.g. history browser).
--
-- The session_id_arg and state_serialized should be set if the game
-- is being loaded from the history browser (for the player to play, or
-- to render a preview), or the state is loaded from the URL parameter.
-- session_id_arg is only used when storing state with the
-- `alexgames.save_state` API, it indicates whether the state of a previous
-- game should be updated, or if a new saved state session should be created.
function start_game(session_id_arg, state_serialized)
	draw.init(board_height, board_width)
	
	-- This causes update to be called every `MS_PER_FRAME` ms.
	alexgames.set_timer_update_ms(MS_PER_FRAME)
	
	-- This causes handle_key_evt to get key presses.
	alexgames.enable_evt("key")
	
	-- This causes handle_mouse_evt to get events on mouse up/down.
	alexgames.enable_evt("mouse_updown")
	
	-- This causes handle_mousemove to get events on mouse move.
	alexgames.enable_evt("mouse_move")
	
	-- This causes handle_touch_evt to get events on touchscreen inputs.
	alexgames.enable_evt("touch")
end
