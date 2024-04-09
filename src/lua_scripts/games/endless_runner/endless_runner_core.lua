local core = {}

-- TODO remove, only for debugging
local alexgames = require("alexgames")

local Y_MIN =  0
local Y_MAX = 10

core.PLAYER_SIZE_Y = 0.5
core.PLAYER_SIZE_X = 0.75

core.WALL_SIZE_X = 1

core.JUMP_TYPE_KEY   = 1
core.JUMP_TYPE_TOUCH = 2

local DIST_BETWEEN_WALLS = 4
local GRAVITY = 15
--local JUMP_SPEED_INC_KEY = 8
--local JUMP_SPEED_INC_TOUCH = 6.5

local Y_VEL_ON_JUMP = 5

local Y_POS_INIT = 5
--local WALL_GAP_SIZE = 3.5 -- this doesn't seem hard enough, even on mobile
--local WALL_GAP_SIZE = 3.25 -- this seems a bit harder, but not much
--local WALL_GAP_SIZE = 3 -- this seems about right
--local WALL_GAP_SIZE = 2.75
--local WALL_GAP_SIZE = 2.5
local WALL_GAP_SIZE = 2.0

local FIRST_WALL_X = 8


local WALL_GAP_POS_MIN = 2
local WALL_GAP_POS_MAX = 8

local WALL_INIT_SEGMENTS = 5

local PLAYER_X_VEL = DIST_BETWEEN_WALLS

-- Once a wall is this far away behind the player,
-- remove it
local REMOVE_WALLS_BEHIND_DIST = 5

local function clip(val, min_val, max_val)
	if val <= min_val then
		return min_val
	end

	if val >= max_val then
		return max_val
	end

	return val
end

local function random_range(min_val, max_val)
	return min_val + math.random() * (max_val - min_val)
end

local function generate_new_wall_segs(prev_gap_y_pos, x_pos)
	local new_gap_pos = prev_gap_y_pos + math.random(-3,3)
	--local new_gap_pos = prev_gap_y_pos + math.random(-1,1) * 3
	new_gap_pos = clip(new_gap_pos, WALL_GAP_POS_MIN, WALL_GAP_POS_MAX)
	-- TODO consider decreasing gap size gradually from say 4 to 3 or so
	-- from wall 0 to 100.
	-- TODO change x_pos to index
	--local wall_gap_size = random_range(2,4)
	local wall_gap_size = 2.75
	local wall1_y = new_gap_pos - wall_gap_size/2
	local wall2_y = new_gap_pos + wall_gap_size/2
	local wall1 = {
		x       = x_pos,
		y_outer = Y_MIN,
		y_inner = wall1_y
	}
	local wall2 = {
		x       = x_pos,
		y_outer = Y_MAX,
		y_inner = wall2_y
	}

	return {
		wall1 = wall1,
		wall2 = wall2,
		gap_pos = new_gap_pos
	}
end

local function get_last_gap_pos(state)
	assert(#state.walls >= 2)
	local wall1 = state.walls[#state.walls-1]
	local wall2 = state.walls[#state.walls-0]

	return (wall1.y_inner + wall2.y_inner)/2
end

function core.update_state(state, dt_ms)
	if state.game_over then
		return
	end

	local dt = dt_ms / 1000

	local prev_player_x = state.player_x

	state.player_x = state.player_x + PLAYER_X_VEL * dt
	state.player_y_vel = state.player_y_vel - GRAVITY * dt
	state.player_y = state.player_y + state.player_y_vel * dt

	if state.player_y - core.PLAYER_SIZE_Y/2 < Y_MIN then
		state.game_over = true
	end
	if state.player_y + core.PLAYER_SIZE_Y/2 >= Y_MAX then
		state.game_over = true
	end

	for _, wall in ipairs(state.walls) do
		if prev_player_x - core.PLAYER_SIZE_X/2 <= wall.x + core.WALL_SIZE_X/2 and
		   wall.x - core.WALL_SIZE_X/2 <= state.player_x + core.PLAYER_SIZE_X/2 then
			-- TODO this is a bit ugly
			if wall.y_outer == Y_MAX and state.player_y + core.PLAYER_SIZE_Y/2 > wall.y_inner or
			   wall.y_outer == Y_MIN and state.player_y - core.PLAYER_SIZE_Y/2 < wall.y_inner then
				local debug_str = string.format("wall { y_outer: %s, y_inner: %s, x: %s },  player = { y: %s, x: %s }",
				                    wall.y_outer, wall.y_inner, wall.x, state.player_y, state.player_x)
				-- TODO remove
				alexgames.set_status_msg("Wall collision! Debug info: " .. debug_str)
				state.game_over = true
				break
			end
		
		end
	end

	while #state.walls > 0 and state.walls[1].x < state.player_x - REMOVE_WALLS_BEHIND_DIST do
		table.remove(state.walls, 1)
	end

	local prev_gap_pos = get_last_gap_pos(state)
	local prev_x_pos = state.walls[#state.walls].x
	while #state.walls < 2*WALL_INIT_SEGMENTS do
		local x_pos = prev_x_pos + DIST_BETWEEN_WALLS
		local wall_info = generate_new_wall_segs(prev_gap_pos, x_pos)
		table.insert(state.walls, wall_info.wall1)
		table.insert(state.walls, wall_info.wall2)
		prev_gap_pos = wall_info.gap_pos
		prev_x_pos   = x_pos
	end

	--print(string.format("walls count: %d; first x: %5d, last x: %5d", #state.walls, state.walls[1].x, state.walls[#state.walls].x))
end

function core.jump(state, jump_type)
	if state.game_over then
		return
	end


	--[[
	local jump_inc = nil

	if jump_type == core.JUMP_TYPE_KEY then
		jump_inc = JUMP_SPEED_INC_KEY
	elseif jump_type == core.JUMP_TYPE_TOUCH then
		jump_inc = JUMP_SPEED_INC_TOUCH
	end

	state.player_y_vel = state.player_y_vel + jump_inc
	--]]
	state.player_y_vel = Y_VEL_ON_JUMP
end

function core.score(state)
	local score = math.ceil( (state.player_x - FIRST_WALL_X) / DIST_BETWEEN_WALLS )
	if score < 0 then
		return 0
	else
		return score
	end
end

function core.new_state()
	local state = {
		player_y = Y_POS_INIT,
		player_x = 0,
		player_y_vel = 0,

		walls = {},

		game_over = false,
	}

	local prev_gap_pos = Y_POS_INIT
	for i=1,WALL_INIT_SEGMENTS do
		if #state.walls >= 2 then
			assert(get_last_gap_pos(state) == prev_gap_pos)
		end
		local x_pos = FIRST_WALL_X + (i-1)*DIST_BETWEEN_WALLS
		local wall_info = generate_new_wall_segs(prev_gap_pos, x_pos)
		table.insert(state.walls, wall_info.wall1)
		table.insert(state.walls, wall_info.wall2)
		prev_gap_pos = wall_info.gap_pos
	end
	return state
end

return core
