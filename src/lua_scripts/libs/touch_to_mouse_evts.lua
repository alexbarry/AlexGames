local touch_to_mouse_evts = {}

local alexgames = require("alexgames")

function touch_to_mouse_evts.init(funcs)
	local state = {
		active_touch_id  = nil,
		handle_mouse_evt = funcs.handle_mouse_evt,
		handle_mousemove = funcs.handle_mousemove,
	}
	alexgames.enable_evt("touch")
	return state
end

function touch_to_mouse_evts.handle_touch_evt(state, evt_id, changed_touches)
	local params = {
		is_touch = true,
	}
	for _, touch in ipairs(changed_touches) do
		local y = math.floor(touch.y)
		local x = math.floor(touch.x)
		if state.active_touch == touch.id then
			if evt_id == 'touchmove' then
				state.handle_mousemove(y, x)
			elseif evt_id == 'touchend' then
				state.handle_mouse_evt(alexgames.MOUSE_EVT_UP, y, x, params)
				state.active_touch = nil
			elseif evt_id == 'touchcancel' then
				state.handle_mouse_evt(alexgames.MOUSE_EVT_DOWN, y, x, params)
				state.active_touch = nil
			end
		end

		if evt_id == 'touchstart' then
			if state.active_touch == nil then
				state.active_touch = touch.id
				state.handle_mouse_evt(alexgames.MOUSE_EVT_DOWN, y, x, params)
			end
		end
	end

end

return touch_to_mouse_evts
