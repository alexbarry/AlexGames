local core = {}

local BALL_RADIUS = 20

local MAX_DIM_VEL = 200

local USER_INPUT_SPEED = 300

function core.new_state(board_width, board_height)
	local state = {
		frame_idx = 0,

		board_height = board_height,
		board_width  = board_width,

		ball_radius = BALL_RADIUS,
		ball_pos_y = BALL_RADIUS,
		ball_pos_x = BALL_RADIUS,
		ball_vel_y = 200,
		ball_vel_x = 80,

		user_input_vec = nil,

		mouse_down = false,
		active_touch = nil,
		user_input_pos_y = nil,
		user_input_pos_x = nil,
	}
	return state
end

local function clip(min_val, val, max_val)
	if val < min_val then return min_val
	elseif val > max_val then return max_val
	else return val end
end

function core.update_ball_pos(state, dt_ms)
	if state.user_input_vec ~= nil then
		print(string.format("Adjusting ball pos from user input {y=%f, x=%f}", state.user_input_vec.y, state.user_input_vec.x))
		state.ball_vel_x = state.ball_vel_x + state.user_input_vec.x * USER_INPUT_SPEED / 1000 * dt_ms
		state.ball_vel_y = state.ball_vel_y + state.user_input_vec.y * USER_INPUT_SPEED / 1000 * dt_ms
	end

	state.ball_vel_x = clip(-MAX_DIM_VEL, state.ball_vel_x, MAX_DIM_VEL)
	state.ball_vel_y = clip(-MAX_DIM_VEL, state.ball_vel_y, MAX_DIM_VEL)

	state.ball_pos_y = state.ball_pos_y + state.ball_vel_y * dt_ms/1000
	state.ball_pos_x = state.ball_pos_x + state.ball_vel_x * dt_ms/1000

	if state.ball_pos_y < state.ball_radius or state.ball_pos_y + state.ball_radius >= state.board_height then
		state.ball_vel_y = -state.ball_vel_y
	end

	if state.ball_pos_x < state.ball_radius or state.ball_pos_x + state.ball_radius >= state.board_width then
		state.ball_vel_x = -state.ball_vel_x
	end
end

local function get_vec_towards_pt(state, pt)
	if pt == nil then return nil end
	local dy = pt.y - state.ball_pos_y
	local dx = pt.x - state.ball_pos_x

	if dy == 0 and dx == 0 then return nil end

	local mag = math.sqrt(dy*dy + dx*dx)

	dy = dy / mag
	dx = dx / mag

	return { y = dy, x = dx }
end

function core.set_user_input_vec(state, vec)
	state.user_input_vec = vec
end

function core.set_user_input_pos(state, pos)
	local vec = get_vec_towards_pt(state, pos)
	core.set_user_input_vec(state, vec)
end

return core
