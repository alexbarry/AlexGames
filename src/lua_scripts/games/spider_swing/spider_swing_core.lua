local core = {}

local PLAYER_MASS = 1

local function generate_spots(spots, x_pos)
	for i=1,10 do
		table.insert(spots, {
			y = 40 + math.random()*400,
			x = x_pos + math.random()*480,
		})
	end
end

function core.reset_player_state(state, player_idx)
	local player = state.players[player_idx]
	player.y  = 250
	player.x  = 0
	player.dy = 0
	player.dx = 0
	core.player_attach_swing(state, 1, 1)
end

local function squared(x)
	return x*x
end

local function get_speed(player)
	if player.swinging_on == nil then
		return math.sqrt(squared(player.dx) + squared(player.dy))
	else
		return math.abs(player.angleV * player.swing_len)
	end
end

function core.get_energy(state, player_idx)
	local player = state.players[player_idx]

	local player_height = (state.max_y - player.y)
	return PLAYER_MASS * (0.5*squared(get_speed(player)) + state.gravity_y *  player_height)
end

function core.new_state()
	local state = {
		players     = {
			{
				y  =  250,
				x  =    0,
				--dy = -250,
				--dx =  150,
				dy =    0,
				dx =    0,
				swinging_on = nil,
				swing_len   = nil,
			},
		},
		swing_spots = {
		--	{ y = 225, x = 250, },
	
			{ y = 150, x = 0, },

		--[[
			{ y = 25, x = 250, },
			{ y = 25, x = 500, },
			{ y = 25, x = 750, },
			{ y = 150, x = 1000, },
		--]]

		--[[
			{ y = 480 - 25, x = 1150, },
			{ y = 480 - 25, x = 1150 + 1*75, },
			{ y = 480 - 25, x = 1150 + 2*75, },
			{ y = 480 - 25, x = 1150 + 3*75, },
			{ y = 480 - 25, x = 1150 + 4*75, },
			{ y = 480 - 25, x = 1150 + 5*75, },
		--]]
		},

		gravity_y = 312,
		gravity_x =   0,

		max_y     =  480,
		game_over = false,

		finish_line_x = 5125,
	}

	for i=0,10 do
		generate_spots(state.swing_spots, 0 + 480*i)
	end
	core.player_attach_swing(state, 1, 1)
	return state
end

local function update_position(state, entity, dt_ms)
	entity.dy = entity.dy + state.gravity_y * dt_ms/1000
	entity.dx = entity.dx + state.gravity_x * dt_ms/1000
	entity.y = entity.y + entity.dy * dt_ms/1000
	entity.x = entity.x + entity.dx * dt_ms/1000
end

local function update_swinging_position(state, player, dt_ms)
	local node = state.swing_spots[player.swinging_on]
	local swing_dy = player.y - node.y
	local swing_dx = player.x - node.x
	player.swing_angle = math.atan(swing_dy,swing_dx)
	player.swing_len = math.sqrt(swing_dy*swing_dy + swing_dx*swing_dx)

	local gravity_force_perp_to_swing = state.gravity_y * math.sin(player.angle)
	local angleA = -gravity_force_perp_to_swing / player.swing_len
	player.angleV = player.angleV + angleA * dt_ms/1000
	player.angle = player.angle + player.angleV * dt_ms/1000

	player.x = node.x + player.swing_len * math.sin(player.angle)
	player.y = node.y + player.swing_len * math.cos(player.angle)

	--[[

	local x2 = swing_dx
	local y2 = swing_dy 

	local accel = -state.gravity_y * (x2/swing_len) * (swing_len - y2)/swing_len
	player.x = player.x + (player.dx + (accel/2 * dt_ms/1000)) * dt_ms/1000
	player.y = node.y + math.sqrt(swing_len*swing_len - x2*x2) - swing_len

	player.dx = player.dx + accel * dt_ms/1000
	--]]

	--[[
	player.swing_angle = math.atan(swing_dy,swing_dx)

	local swinging_gravity_y = state.gravity_y * math.sin(player.swing_angle + math.pi/2)
	local swinging_gravity_x = state.gravity_y * math.cos(player.swing_angle + math.pi/2)

	player.dy = player.dy + swinging_gravity_y * dt_ms/1000
	player.dx = player.dx + swinging_gravity_x * dt_ms/1000
	
	player.y = player.y + player.dy * dt_ms/1000
	player.x = player.x + player.dx * dt_ms/1000
	--]]

	

	
end

function core.update_state(state, dt_ms)
	if state.game_over then return end
	for _, player in ipairs(state.players) do
		if player.swinging_on == nil then
			update_position(state, player, dt_ms)
		else
			update_swinging_position(state, player, dt_ms)
		end

		if player.y > state.max_y then
			state.game_over = true
		end
	end
end

function core.get_closest_swing_spot(state, pos)
	local min_dist = nil
	local closest_node = nil

	-- TODO store these nodes in groups of screen size or something,
	-- to avoid looking through all of them
	for node_idx, node in ipairs(state.swing_spots) do
		local dy = pos.y - node.y
		local dx = pos.x - node.x
		local dist = math.sqrt(dy*dy + dx*dx)
		if min_dist == nil or dist < min_dist then
			closest_node = node_idx
			min_dist     = dist
		end
	end

	return closest_node
end

function core.player_attach_swing(state, player_idx, node_idx)
	local player = state.players[player_idx]
	local node = state.swing_spots[node_idx]

	player.swinging_on = node_idx
	local dy = node.y - player.y
	local dx = node.x - player.x

	player.swing_len = math.sqrt(dy*dy + dx*dx)
	--player.swing_angle = math.atan(dy, dx) + math.pi
	
	player.angle = math.atan(-dy, dx) - math.pi/2
	local angle2 = math.atan(dy, -dx) + math.pi
	player.angleV = (player.dx * math.sin(angle2) + player.dy * math.cos(angle2)) / player.swing_len
	player.dy = 0 -- TODO
	player.dx = 0 -- TODO
end
function core.player_release_swing(state, player_idx)
	local player = state.players[player_idx]
	if player.swinging_on == nil then return end
	local node = state.swing_spots[player.swinging_on]
	player.swinging_on = nil
	local angle2 = math.atan(player.y - node.y, -player.x + node.x)
	player.dy = math.cos(angle2) * player.swing_len * player.angleV
	player.dx = math.sin(angle2) * player.swing_len * player.angleV
	player.angleV = 0
end

function core.player_won(state, player_idx)
	return state.players[player_idx].x >= state.finish_line_x
end


return core
