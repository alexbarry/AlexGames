local core = {}

local NUM_STARS = 5*5*50
local NUM_WALLS = 50
local MIN_WALL_Y = 0
local MAX_WALL_Y = 480
local WALL_Y_SIZE = 170

local WALL_X_SPACE = 250
local WALL_X_WIDTH =   5

local THRUST_ACCEL = 900.0
local MAX_SPEED    = 750
local ANGLE_ROT_PER_SECOND = 360.0

local WALL_TOUCHING_DIST = 15

local RACE_TRACK_SCALING = 480
local race_track = {
	{ outer = { y =  0, x =  0 }, inner = { y =  2, x =  2 }, }, -- a ( 1, 2)
	{ outer = { y =  0, x =  5 }, inner = { y =  2, x =  5 }, }, -- b ( 3, 4)
	{ outer = { y =  0, x =  6 }, inner = { y =  2, x =  6 }, }, -- c ( 5, 6)
	{ outer = { y =  1, x =  9 }, inner = { y =  3, x =  7 }, }, -- d ( 7, 8)
	{ outer = { y =  4, x =  9 }, inner = { y =  4, x =  6 }, }, -- e ( 9,10)
	{ outer = { y =  6, x =  7 }, inner = { y =  6, x =  5 }, }, -- f (11,12)
	{ outer = { y =  9, x =  9 }, inner = { y =  9, x =  7 }, }, -- g
	{ outer = { y = 12, x =  9 }, inner = { y = 10, x =  7 }, }, -- h
	{ outer = { y = 12, x =  3 }, inner = { y = 10, x =  4 }, }, -- i
	{ outer = { y =  9, x =  0 }, inner = { y =  9, x =  2 }, }, -- j
	{ outer = { y =  7, x =  0 }, inner = { y =  7, x =  2 }, }, -- k
	{ outer = { y =  4, x =  2 }, inner = { y =  4, x =  4 }, }, -- l
	{ outer = { y =  2, x =  0 }, inner = { y =  2, x =  2 }, }, -- m
}
local race_track_finish = {
	pt1 = { y=0, x=2 },
	pt2 = { y=2, x=2 },
}

local race_track_checkpoints = {
	{ pt1 = {y= 6, x=7}, pt2 = {y= 6, x=5} },
	{ pt1 = {y=12, x=6}, pt2 = {y=10, x=6} },
	{ pt1 = {y= 7, x=0}, pt2 = {y= 7, x=2} },
}

local start_race_pt =  { y = 1, x = 3 }
local start_race_pt =  { y = 1, x = 3 }

local races = {
	{
		track       = race_track,
		finish      = race_track_finish,
		checkpoints = race_track_checkpoints,
		start       = start_race_pt,
	},

	{
		start       = { y = 1, x = 6 },
		checkpoints = {
			{ pt1 = { y = 4, x = 13 }, pt2 = { y = 4, x = 10 }, },
			{ pt1 = { y = 7.5, x = 5 }, pt2 = { y = 6.5, x = 5 }, },
			{ pt1 = { y = 4, x = -1 }, pt2 = { y = 4, x = 2 }, },
		},
		finish      = { pt1 = { y = 0, x = 4}, pt2 = { y = 2, x = 4 } },
		track       = {
			{ outer = { y = 0, x = 0 }, inner = { y = 2, x = 2 }, },
			{ outer = { y = 0, x =12 }, inner = { y = 2, x =10 }, },
			{ outer = { y = 4, x =13 }, inner = { y = 4, x =10 }, },

			{ outer = { y = 8, x =12 }, inner = { y = 6, x =10 }, },

			{ outer = { y = 7.50, x = 6 }, inner = { y = 6.50, x = 6 } },
			{ outer = { y = 7.50, x = 4 }, inner = { y = 6.50, x = 4 } },

			{ outer = { y = 8, x = 0 }, inner = { y = 6, x = 2 }, },
			{ outer = { y = 4, x =-1 }, inner = { y = 4, x = 2 }, },
		},
	},
}

local function sign(val)
	if val >= 0 then return 1
	else return -1 end
end

local function clip(min_val, val, max_val)
	if val < min_val then return min_val
	elseif val > max_val then return max_val
	else return val end
end


local function new_player_state(state)
	local player_state = {
		y = 0,
		x = 0,
		angle_degrees = 0,
		vel_y = 0,
		vel_x = 0,

		thrust_on = false,
		brake_on  = false,

		lap_time_ms = 0,
		lap_times = {},

		met_checkpoints = {},
	}
	for checkpoint_idx, _ in ipairs(state.checkpoints) do
		player_state.met_checkpoints[checkpoint_idx] = false
	end
	return player_state
end

local function squared(x)
	return x*x
end

local function wall_length(wall_info)
	return math.sqrt( squared(wall_info.y_end - wall_info.y_start) + squared(wall_info.x_end - wall_info.x_start))
end

function core.new_game_state(track_key)
	local state = {
		zoom = 0.2,
		stars = {},
		walls = {},
		players = {},
		checkpoints = {},
		track       = nil,
	}


	for i=1,NUM_STARS do
		table.insert(state.stars, {
			y = math.random() * 5*480,
			x = math.random() * 5*480,
		})
	end

	local race                   = races[track_key]
	state.track = race
	local race_track_finish      = race.finish
	local race_track_checkpoints = race.checkpoints
	local start_race_pt          = race.start
	local race_track             = race.track

	state.finish_line = {
		y_start = race_track_finish.pt1.y * RACE_TRACK_SCALING,
		y_end   = race_track_finish.pt2.y * RACE_TRACK_SCALING,
		x_start = race_track_finish.pt1.x * RACE_TRACK_SCALING,
		x_end   = race_track_finish.pt2.x * RACE_TRACK_SCALING,
	}

	for _, checkpoint_info in ipairs(race_track_checkpoints) do
		table.insert(state.checkpoints, {
			y_start = checkpoint_info.pt1.y * RACE_TRACK_SCALING,
			y_end   = checkpoint_info.pt2.y * RACE_TRACK_SCALING,
			x_start = checkpoint_info.pt1.x * RACE_TRACK_SCALING,
			x_end   = checkpoint_info.pt2.x * RACE_TRACK_SCALING,
		})
	end
	print('checkpoints count: ' .. #state.checkpoints)


	state.players[1] = new_player_state(state)
	state.players[1].y = start_race_pt.y * RACE_TRACK_SCALING
	state.players[1].x = start_race_pt.x * RACE_TRACK_SCALING
	state.players[1].angle_degrees = 90

	--[[
	for i=1,NUM_WALLS do
		y_start = math.floor(math.random()*(MAX_WALL_Y-MIN_WALL_Y-WALL_Y_SIZE) + MIN_WALL_Y)
		table.insert(state.walls, {
			y_start = y_start,
			y_end   = y_start + WALL_Y_SIZE,

			x_start = i*WALL_X_SPACE,
			x_end   = i*WALL_X_SPACE + WALL_X_WIDTH,
		})
	end
	--]]

	for race_pt_idx, race_pt in ipairs(race_track) do
		local pts1 = race_pt
		local pts2
		if race_pt_idx == #race_track then	
			pts2 = race_track[1]
		else
			pts2 = race_track[race_pt_idx + 1]
		end

		table.insert(state.walls, {
			y_start = pts1.outer.y * RACE_TRACK_SCALING,
			x_start = pts1.outer.x * RACE_TRACK_SCALING,

			y_end   = pts2.outer.y * RACE_TRACK_SCALING,
			x_end   = pts2.outer.x * RACE_TRACK_SCALING,
		})
		state.walls[#state.walls].len = wall_length(state.walls[#state.walls])

		table.insert(state.walls, {
			y_start = pts1.inner.y * RACE_TRACK_SCALING,
			x_start = pts1.inner.x * RACE_TRACK_SCALING,

			y_end   = pts2.inner.y * RACE_TRACK_SCALING,
			x_end   = pts2.inner.x * RACE_TRACK_SCALING,
		})
		state.walls[#state.walls].len = wall_length(state.walls[#state.walls])

	end

	

	return state
end

local function is_touching_line(wall_info, player_state, touching_dist)
	if wall_info.len == nil then
		wall_info.len = wall_length(wall_info)
	end

	local len_squared = wall_info.len * wall_info.len
	local t = ((player_state.x - wall_info.x_start) * (wall_info.x_end - wall_info.x_start) + 
	           (player_state.y - wall_info.y_start) * (wall_info.y_end - wall_info.y_start)) / len_squared
	          
	t = clip(0, t, 1)
	local projection = {
		y = wall_info.y_start + t * (wall_info.y_end - wall_info.y_start),
		x = wall_info.x_start + t * (wall_info.x_end - wall_info.x_start),
	}

	local dy = projection.y - player_state.y
	local dx = projection.x - player_state.x

	local dist_to_wall_squared = squared(dy) + squared(dx)

	if false and wall_idx == 1 then
		print(string.format("Dist to wall %d is %f", wall_idx, math.sqrt(dist_to_wall_squared)))
		print(string.format("{y_start=%s, y_end=%s, x_start=%s, x_end=%s}, player {y=%s, x=%s}",
		      wall_info.y_start, wall_info.y_end,
		      wall_info.x_start, wall_info.x_end,
		      player_state.y, player_state.x))
	end

	
	if dist_to_wall_squared <= squared(touching_dist) then
		print(string.format("Dist to wall %s is %f", wall_idx, math.sqrt(dist_to_wall_squared)))
		print(string.format("{y_start=%s, y_end=%s, x_start=%s, x_end=%s}, player {y=%s, x=%s}",
		      wall_info.y_start, wall_info.y_end,
		      wall_info.x_start, wall_info.x_end,
		      player_state.y, player_state.x))
		return true
	end

end

local function is_touching_any_wall(state, player_state, touching_dist)
	for wall_idx, wall_info in ipairs(state.walls) do
		-- Oops, this is only for infinite length lines
		--[[
		local dist_to_wall = math.abs( (wall_info.x_end - wall_info.x_start)*(wall_info.y_start - player_state.y) -
		                       (wall_info.x_start - player_state.x)*(wall_info.y_end - wall_info.y_start)
		                     ) / wall_info.len
		--]]
		if is_touching_line(wall_info, player_state, touching_dist) then
			return true
		end

	end

	return false
end

function core.met_all_checkpoints(player_state)
	for _, met in pairs(player_state.met_checkpoints) do
		if not met then return false end
	end
	return true
end

function core.update_state(state, dt)
	local player_state = state.players[1]
	local angle_diff = 0
	if player_state.rot_left and player_state.rot_right then
	elseif player_state.rot_left then
		angle_diff = -ANGLE_ROT_PER_SECOND * dt
	elseif player_state.rot_right then
		angle_diff = ANGLE_ROT_PER_SECOND * dt
	end

	player_state.angle_degrees = player_state.angle_degrees + angle_diff

	if player_state.brake_on then
		player_state.vel_y = player_state.vel_y / 2
		if player_state.vel_y < 1 then
			player_state.vel_y = 0
		end

		player_state.vel_x = player_state.vel_x / 2
		if player_state.vel_x < 1 then
			player_state.vel_x = 0
		end
	elseif player_state.thrust_on then
		player_state.vel_y = player_state.vel_y + THRUST_ACCEL * dt * -math.cos(player_state.angle_degrees/180*math.pi)
		player_state.vel_x = player_state.vel_x + THRUST_ACCEL * dt * math.sin(player_state.angle_degrees/180*math.pi)
	end

	player_state.vel_y = clip(-MAX_SPEED, player_state.vel_y, MAX_SPEED)
	player_state.vel_x = clip(-MAX_SPEED, player_state.vel_x, MAX_SPEED)
	

	if player_state.vel_y ~= 0 then
		player_state.y = math.floor(player_state.y + player_state.vel_y * dt + 0.5)
	end
	if player_state.vel_x ~= 0 then
		player_state.x = math.floor(player_state.x + player_state.vel_x * dt + 0.5)
	end

	player_state.lap_time_ms = player_state.lap_time_ms + math.floor(1000*dt)

	if is_touching_any_wall(state, player_state, WALL_TOUCHING_DIST) then
		print("Touching wall!")
		player_state.vel_y = 0
		player_state.vel_x = 0
		player_state.y = state.track.start.y * RACE_TRACK_SCALING
		player_state.x = state.track.start.x * RACE_TRACK_SCALING
		player_state.angle_degrees = 90
		player_state.lap_time_ms = 0
		player_state.met_checkpoints = {}
		for checkpoint_idx, _ in ipairs(state.checkpoints) do
			player_state.met_checkpoints[checkpoint_idx] = false
		end
	else
		for checkpoint_idx, checkpoint_info in ipairs(state.checkpoints) do
			if is_touching_line(checkpoint_info, player_state, WALL_TOUCHING_DIST) then
				player_state.met_checkpoints[checkpoint_idx] = true
	
			end
		end
		if core.met_all_checkpoints(player_state) and
		   is_touching_line(state.finish_line, player_state, WALL_TOUCHING_DIST) then
			table.insert(player_state.lap_times, player_state.lap_time_ms)
			player_state.lap_time_ms = 0
			for checkpoint_idx, _ in ipairs(state.checkpoints) do
				player_state.met_checkpoints[checkpoint_idx] = false
			end
		end
	end

	local str = ''
	for _, met in pairs(player_state.met_checkpoints) do
		local val
		if met then val = '1' else val = '0' end
		str = str .. val .. ' '
	end
	--print('checkpoints: ' .. str .. string.format("%s", core.met_all_checkpoints(player_state)))

	-- print(string.format("update_state{y=%s, x=%s, angle=%s, vel_y=%s, vel_x=%s}",
	--                    state.y, state.x, state.angle_degrees, state.vel_y, state.vel_x))
end



return core
