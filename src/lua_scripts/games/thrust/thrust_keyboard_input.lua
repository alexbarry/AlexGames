local input = {}

local need_to_rotate_enabled = true

function input.new_input_state() 
	return {
		rot_left  = false,
		rot_right = false,

		thrust_left  = false,
		thrust_right = false,
		thrust_up    = false,
		thrust_down  = false,
	}
end

function input.handle_key_evt(input_state, player_state, evt_id, code)
	--print(string.format("handle_key_evt, code=%s, evt=%s", code, evt_id))
	if need_to_rotate_enabled then
		if code == "ArrowLeft" then
			player_state.rot_left = (evt_id == "keydown")
		elseif code == "ArrowRight" then
			player_state.rot_right = (evt_id == "keydown")
		elseif code == "ArrowUp" then
			player_state.thrust_on = (evt_id == "keydown")
		elseif code == "ArrowDown" then
			player_state.brake_on = (evt_id == "keydown")
		else
			return false
		end
		return true
	else
		if code == "ArrowLeft" then
			input_state.thrust_left = (evt_id == "keydown")
		elseif code == "ArrowRight" then
			input_state.thrust_right = (evt_id == "keydown")
		elseif code == "ArrowUp" then
			input_state.thrust_up = (evt_id == "keydown")
		elseif code == "ArrowDown" then
			input_state.thrust_down = (evt_id == "keydown")
		else
			return false
		end

		local thrust_vec_y = 0
		local thrust_vec_x = 0

		if input_state.thrust_left and input_state.thrust_right then
			-- pass
		elseif input_state.thrust_left then
			thrust_vec_x =  1
		elseif input_state.thrust_right then
			thrust_vec_x = -1
		end

		if input_state.thrust_up and input_state.thrust_down then
			-- pass
		elseif input_state.thrust_up then
			thrust_vec_y = 1
		elseif input_state.thrust_down then
			thrust_vec_y = -1
		end

		if thrust_vec_y ~= 0 or thrust_vec_x ~= 0 then
			player_state.angle_degrees = math.atan(thrust_vec_y, thrust_vec_x) * 180 / math.pi - 90
			player_state.thrust_on = true
		else
			player_state.thrust_on = false
		end
		return true
	end
end

return input
