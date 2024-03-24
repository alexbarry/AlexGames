local touchpad = {}

function touchpad.new_state(touchpad_pos, touchpad_radius)
	return {
		pos    = touchpad_pos,
		radius = touchpad_radius,
		active_touch = nil,

		player_vec = { y = 0, x = 0 },
	}
end

local function touch_in_dirpad(state, touch)
	local dy = (touch.y - state.pos.y)
	local dx = (touch.x - state.pos.x)

	return (math.abs(dy) <= state.radius and
	        math.abs(dx) <= state.radius)
end

function touchpad.handle_touch_evts(state, evt_id, touches)
	local touch_changed = false
	for _, touch in ipairs(touches) do
		if evt_id == 'touchstart' and state.active_touch == nil and touch_in_dirpad(state, touch) then
			state.active_touch = touch.id
			touch_changed = true
		elseif (evt_id == 'touchend' or evt_id == 'touchcancel') and state.active_touch == touch.id then
			state.active_touch = nil
			state.player_vec = { y = 0, x = 0 }
			touch_changed = true
		end

		if state.active_touch == touch.id then
			local dy = (touch.y - state.pos.y)
			local dx = (touch.x - state.pos.x)
			local mag   = math.sqrt(dy*dy + dx*dx) / state.radius
			mag = math.min(mag, 1)
			local angle = math.atan(dy,dx)
			state.player_vec = {
				y = mag*math.sin(angle),
				x = mag*math.cos(angle),
			}
			touch_changed = true
		end
	end

	if touch_changed then
		return state.player_vec
	else
		return nil
	end
end

return touchpad
