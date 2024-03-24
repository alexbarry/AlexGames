local keyboard_input = {}

local INV_SQRT2 = 1/math.sqrt(2)

function keyboard_input.new_key_state()
	local state = {
		keys_pressed = {},
	}
	return state
end

local function abs(x)
	if x >= 0 then return x
	else return -x end
end

local function sign(x)
	if x >= 0 then return 1
	else return -1 end
end

function keyboard_input.get_move_vec_from_key_evt(state, evt, code)
	if state.keys_pressed[code] == nil then
		state.keys_pressed[code] = false
	end

	state.keys_pressed[code] = (evt == "keydown")

	local keys_handled = {
		["ArrowLeft"]  = true,
		["ArrowRight"] = true,
		["ArrowUp"]    = true,
		["ArrowDown"]  = true,

		["ArrowH"]  = true,
		["ArrowJ"]  = true,
		["ArrowK"]  = true,
		["ArrowL"]  = true,
	}

	local left  = state.keys_pressed["ArrowLeft"]  or state.keys_pressed["KeyH"]
	local right = state.keys_pressed["ArrowRight"] or state.keys_pressed["KeyL"]
	local down  = state.keys_pressed["ArrowDown"]  or state.keys_pressed["KeyJ"]
	local up    = state.keys_pressed["ArrowUp"]    or state.keys_pressed["KeyK"]

	local move_vec_y = 0
	local move_vec_x = 0

	if left and right then
		-- pass
	elseif left then
		move_vec_x = -1
	elseif right then
		move_vec_x = 1
	end

	if up and down then
		-- pass
	elseif up then
		move_vec_y = -1
	elseif down then
		move_vec_y = 1
	end

	if abs(move_vec_y) > 0 and abs(move_vec_x) > 0 then
		move_vec_y = sign(move_vec_y)*INV_SQRT2
		move_vec_x = sign(move_vec_x)*INV_SQRT2
	end

	return {
		handled = keys_handled[code],
		vec = {
			y = move_vec_y,
			x = move_vec_x,
		},
	}
		
end

return keyboard_input
