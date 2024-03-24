local core = {}

local utils = require("libs/utils")

--local ENEMY_MOVE_SPEED  = 60
local ENEMY_MOVE_SPEED  = 120
local PLAYER_MOVE_SPEED = 150

local ENEMY_SPAWN_DIST_FROM_PLAYER = 400
local ENEMY_DIST_TO_PLAYER = 10

local MAX_BROCCOLI_OFFSET = 400
local BROC_DMG = 200
local BROCCOLI_MOVE_SPEED = 35

local HAMMER_RADIUS = 150
local HAMMER_ROT_SPEED = 1.0/2*(2*math.pi)

local HAMMER_SIZE = 20 

core.ATTACK_TYPE_BROCCOLI = 1
core.ATTACK_TYPE_FROG     = 2
core.ATTACK_TYPE_HAMMER   = 3

core.ENTITY_TYPE_PLAYER   = 1
core.ENTITY_TYPE_ENEMY    = 2


core.ATTACK_INFO = {
	[core.ATTACK_TYPE_BROCCOLI] = {
		size_y = 80,
		size_x = 80,
	},
	[core.ATTACK_TYPE_HAMMER] = {
		size_y = HAMMER_SIZE,
		size_x = HAMMER_SIZE,
	},
}

local function get_enemy_spawn_time(state)
end

local function squared(x)
	return x*x
end

local function abs(x)
	if x >= 0 then return x
	else return -x end
end

local ENTITY_MAP_STEP = 20

local function entity_map_round(val)
	return math.floor(val/ENTITY_MAP_STEP)*ENTITY_MAP_STEP
end

local function get_entity_map_pos(pos)
	if pos.y == nil or pos.x == nil then
		error(string.format("invalid pos{y=%s,x=%s}", pos.y, pos.x), 2)
	end
	return {
		y = entity_map_round(pos.y),
		x = entity_map_round(pos.x),
	}
end

local function get_entity_map_cell_or_create(entity_map, y, x)
	if entity_map[y] == nil then
		entity_map[y] = {}
	end

	if entity_map[y][x] == nil then
		entity_map[y][x] = {}
	end

	return entity_map[y][x]
end

local function add_to_entity_map(entity_map, item_type, item_state)
	local entity_map_pos = get_entity_map_pos(item_state)
	local new_cell = get_entity_map_cell_or_create(entity_map, entity_map_pos.y, entity_map_pos.x)

	table.insert(new_cell, {
		item_type = item_type,
		state = item_state,
	})
	--print(string.format("Added entity type=%s, state=%s to entity map at y=%d, x=%d",
	--	item_type, item_state, entity_map_pos.y, entity_map_pos.x))
		
end

local function print_entity_map(entity_map)
	for y, row in pairs(entity_map) do
		for x, entities in pairs(row) do
			if #entities > 0 then
				print(string.format("entity_map[y=%3d][x=%3d] has %d entities",
				      y, x, #entities))
			end
		end
	end
end

local function get_entity_map_cell(entity_map, y, x)
	if entity_map[y] == nil or
	   entity_map[y][x] == nil then
		error(string.format("y=%d,x=%d not found in entity_map", y, x), 2)
	end

	return entity_map[y][x]
end

local function update_attack_states(state, player_state, dt_ms)
	for _, attack_state in pairs(player_state.attack_states) do
		if attack_state.enabled then
			attack_state.update(state, player_state, attack_state, dt_ms)
		end
	end
end

local function area_contains_enemy(state, start_y, start_x, end_y, end_x)
	local found_enemies = {}
	for y=entity_map_round(start_y),entity_map_round(end_y),ENTITY_MAP_STEP do
		for x=entity_map_round(start_x),entity_map_round(end_x),ENTITY_MAP_STEP do
			for val_idx, val in ipairs(get_entity_map_cell_or_create(state.entity_map, y, x)) do
				if val.item_type == core.ENTITY_TYPE_ENEMY then
					table.insert(found_enemies, val.state)
				end
			end
		end
	end

	return { found = #found_enemies > 0, enemies = found_enemies }
end

local function remove_entity(state, entity)
	local pos = get_entity_map_pos(entity)
	local cell = get_entity_map_cell(state.entity_map, pos.y, pos.x)
	local entity_idx
	for idx, val in ipairs(cell) do
		if val.state == entity then
			entity_idx = idx
		end
	end

	if entity_idx == nil then
		error(string.format("Could not find entity %s in entity_map", entity))
	end

	table.remove(cell, entity_idx)
end

local function remove_enemy(state, enemy)
	remove_entity(state, enemy)
	local enemy_idx
	for val_idx, val in ipairs(state.enemies) do
		if val == enemy then
			enemy_idx = val_idx
		end
	end

	if enemy_idx == nil then
		error(string.format("Could not find enemy %s in state.enemies", enemy))
	end
	table.remove(state.enemies, enemy_idx)
	print(string.format("Removed enemy %s", enemy))
end

local function damage_enemy(state, enemy, dmg)
	enemy.health = enemy.health - dmg
	if enemy.health <= 0 then
		remove_enemy(state, enemy)
	end
end

function update_broccoli_state(state, player_state, attack_state, dt_ms)
	local spawn_dirs = {
		{ y_vel = 0, x_vel =  1 },
		{ y_vel = 0, x_vel = -1 },
		{ y_vel = 1, x_vel =  0 },
		{ y_vel =-1, x_vel =  0 },
	}
	attack_state.time_to_next_spawn_ms = attack_state.time_to_next_spawn_ms - dt_ms
	if attack_state.time_to_next_spawn_ms < 0 then
		attack_state.time_to_next_spawn_ms = attack_state.spawn_period_ms

		for i=1,attack_state.entities_per_spawn do
			print("spawning broccoli")
			local y_vel = spawn_dirs[attack_state.next_spawn_dir].y_vel * BROCCOLI_MOVE_SPEED * dt_ms/1000
			local x_vel = spawn_dirs[attack_state.next_spawn_dir].x_vel * BROCCOLI_MOVE_SPEED * dt_ms/1000
	
			attack_state.next_spawn_dir = (attack_state.next_spawn_dir % #spawn_dirs) + 1
			table.insert(attack_state.particles, {
				y_offset = 0,
				x_offset = 0,
				
				y_vel = y_vel,
				x_vel = x_vel,
			})
		end
	end

	local broc_idxes_to_remove = {}

	for particle_idx, particle in ipairs(attack_state.particles) do
		particle.y_offset = particle.y_offset + particle.y_vel * dt_ms
		particle.x_offset = particle.x_offset + particle.x_vel * dt_ms

	if abs(particle.y_offset) > MAX_BROCCOLI_OFFSET or
	   abs(particle.x_offset) > MAX_BROCCOLI_OFFSET then
		table.insert(broc_idxes_to_remove, particle_idx)
		end
	end

	local positions = core.get_broccoli_particle_positions(state, player_state, attack_state)
	local BROC_SIZE_Y = 80
	local BROC_SIZE_X = 80
	--print_entity_map(state.entity_map)
	for pos_idx, pos in ipairs(positions) do
		local info = area_contains_enemy(state,
		                                 pos.y - BROC_SIZE_Y/2, pos.x - BROC_SIZE_X/2,
		                                 pos.y + BROC_SIZE_Y/2, pos.x + BROC_SIZE_X/2)
		--[[
		print(string.format("area y in {%s, %s}, x in {%s, %s} contained enemies: %s",
			pos.y - BROC_SIZE_Y/2, pos.y + BROC_SIZE_Y/2,
			pos.x - BROC_SIZE_Y/2, pos.x + BROC_SIZE_Y/2,
			info.found))
		--]]
		if info.found then
			print("broccoli hit enemy!")
			for _, enemy in ipairs(info.enemies) do
				damage_enemy(state, enemy, BROC_DMG)
			end
			if attack_state.consumed_on_dmg then
				table.insert(broc_idxes_to_remove, pos_idx)
			end
		end
	end
	-- TODO handle removing more than one at a time
	if #broc_idxes_to_remove > 0 then
		table.remove(attack_state.particles, broc_idxes_to_remove[1])
	end
		
end

-- TODO make private
function core.get_broccoli_particle_positions(state, player_state, attack_state)
	local positions = {}
	for _, particle in ipairs(attack_state.particles) do
		table.insert(positions, {
			y = player_state.y + particle.y_offset,
			x = player_state.x + particle.x_offset,
		})
	end

	return positions
end

local function get_missing_hammer_idx(attack_state)
	for i=1,attack_state.max_particles do
		if attack_state.particles[i] == nil then
			return i 
		end
	end
	return nil
end

local function update_hammer_state(state, player_state, attack_state, dt_ms)
	print("update_hammer_state")
	attack_state.time_to_next_spawn_ms = attack_state.time_to_next_spawn_ms - dt_ms
	if attack_state.time_to_next_spawn_ms < 0 then
		while utils.table_len(attack_state.particles) < attack_state.max_particles do
				attack_state.time_to_next_spawn_ms = attack_state.spawn_period_ms
				local i = get_missing_hammer_idx(attack_state)
				attack_state.particles[i] = {
					hammer_radius = HAMMER_RADIUS + i*HAMMER_SIZE,
					angle = 0,
					idx   = i,
				}
		end
	end

	for _, particle in pairs(attack_state.particles) do
		particle.angle = particle.angle + HAMMER_ROT_SPEED*dt_ms/1000
	end

	local hammers_to_remove = {}

	local positions = core.get_hammer_particle_positions(state, player_state, attack_state)
	for hammer_idx, hammer in ipairs(positions) do
		local info = area_contains_enemy(state,
		                                 hammer.y - HAMMER_SIZE/2, hammer.x - HAMMER_SIZE/2,
		                                 hammer.y + HAMMER_SIZE/2, hammer.x + HAMMER_SIZE/2)
		if info.found then
			print(string.format("Hammer hit %d enemies", #info.enemies))
			for _, enemy in ipairs(info.enemies) do
				damage_enemy(state, enemy, 200)
			end
			if attack_state.hammers_consumable then
				table.insert(hammers_to_remove, hammer_idx)
			end
		end
	end

	for _, idx in ipairs(hammers_to_remove) do
		attack_state.particles[idx] = nil
	end

end

function core.get_hammer_particle_positions(state, player_state, attack_state)
	local positions = {}
	for _, particle in pairs(attack_state.particles) do
		table.insert(positions, {
			y = player_state.y + particle.hammer_radius * math.cos(particle.angle),
			x = player_state.x + particle.hammer_radius * math.sin(particle.angle),
		})
	end

	return positions
end



local function update_entity_map(entity_map, old_pos, item_state)
	--print_entity_map(entity_map)
	local old_entity_map_pos = get_entity_map_pos(old_pos)
	local new_entity_map_pos = get_entity_map_pos(item_state)
	--[[
	print(string.format("Moving entity from {y=%d,x=%d} to {y=%d,x=%d}",
		old_entity_map_pos.y,
		old_entity_map_pos.x,
		new_entity_map_pos.y,
		new_entity_map_pos.x))
	--]]

	if old_entity_map_pos.y == new_entity_map_pos.y and
	   old_entity_map_pos.x == new_entity_map_pos.x then
		return
	end

	local old_map_cell = get_entity_map_cell(entity_map, old_entity_map_pos.y, old_entity_map_pos.x)
	local old_map_idx
	local old_val
	for idx, val in ipairs(old_map_cell) do
		if val.state == item_state then
			old_map_idx = idx
			old_val = val
		end
	end

	if old_map_idx == nil then
		print(string.format("old_map_cell has len %d", #old_map_cell))
		for idx, val in ipairs(old_map_cell) do
			print(string.format("old_map_cell[%d] = %s", idx, val.state))
		end
		error(string.format("Could not find item %s in old entity_map cell", item_state))
	end

	local new_map_cell = get_entity_map_cell_or_create(entity_map, new_entity_map_pos.y, new_entity_map_pos.x)
	table.remove(old_map_cell, idx)
	table.insert(new_map_cell, old_val)
end

function core.new_state(num_players)
	local state = {
		entity_map = {},
		players = {},
		enemies = {},
		--enemies_to_spawn_per_period = 50,
		enemies_to_spawn_per_period = 1,
		enemy_spawn_time_ms         = 400,
		--enemy_spawn_time_ms         = 400,
		time_to_next_enemy_spawn_ms = 0,
	}

	for i=1,num_players do

		table.insert(state.players, {
			y = 0,
			x = 0,

			move_vec = {
				y = 0,
				x = 0,
			},

			level = 1,
			attack_states = {
				[core.ATTACK_TYPE_BROCCOLI] = {
					enabled = true,
					update = update_broccoli_state,
					get_positions = core.get_broccoli_particle_positions,
					consumed_on_dmg = false,
					level = 1,
					time_to_next_spawn_ms = 500,
					--entities_per_spawn = 1,
					entities_per_spawn = 4,
					spawn_period_ms = 1000,
					next_spawn_dir = 1,
					particles = {},
				},

				[core.ATTACK_TYPE_HAMMER] = {
					enabled = true,
					update = update_hammer_state,
					get_positions = core.get_hammer_particle_positions,
					max_particles = 3,
					level = 1,
					time_to_next_spawn_ms = 500,
					spawn_period_ms = 1000,
					next_spawn_dir = 1,
					hammers_consumable = false,
					particles = {},
				},

			},
		})
		add_to_entity_map(state.entity_map, core.ENTITY_TYPE_PLAYER, state.players[i])
	end

	return state
end

local function get_random_dist_from_player(player_state, dist_from_player)
	local angle = math.random()*2*math.pi
	local pos = {
		y = player_state.y + dist_from_player*math.cos(angle),
		x = player_state.x + dist_from_player*math.sin(angle),
	}
	return pos
end

local function spawn_enemy(state, pos)
	local enemy_state = {
		y      = pos.y,
		x      = pos.x,
		health = 10,
		move_speed = ENEMY_MOVE_SPEED,
	}
	table.insert(state.enemies, enemy_state)
	add_to_entity_map(state.entity_map, core.ENTITY_TYPE_ENEMY, enemy_state)
end

local function collides_with_new_pos(state, entity, tentative_pos)
	local old_entity_pos = get_entity_map_pos(entity)
	local new_entity_pos = get_entity_map_pos(tentative_pos)

	if old_entity_pos.y == new_entity_pos.y and
	   old_entity_pos.x == new_entity_pos.x then
		return false
	else
		return #get_entity_map_cell_or_create(state.entity_map, new_entity_pos.y, new_entity_pos.x) > 0
	end

	
end

local function move_enemies_toward_player(state, dt_ms)
	local player_state = state.players[1]
	for _, enemy in ipairs(state.enemies) do
		local dy = player_state.y - enemy.y
		local dx = player_state.x - enemy.x

		local angle = math.atan(dy, dx)
		local dist_squared = dy*dy + dx*dx

		local old_pos = {
			y = enemy.y,
			x = enemy.x,
		}

		if dist_squared > squared(ENEMY_DIST_TO_PLAYER) then
			local tentative_pos = {
				y = enemy.y + enemy.move_speed * math.sin(angle) * dt_ms/1000.0,
				x = enemy.x + enemy.move_speed * math.cos(angle) * dt_ms/1000.0,
			}

			local map_pos = get_entity_map_pos(tentative_pos)
			local map_cell = get_entity_map_cell_or_create(state.entity_map, map_pos.y, map_pos.x)
			if not collides_with_new_pos(state, enemy, tentative_pos) then
				enemy.y = tentative_pos.y
				enemy.x = tentative_pos.x
			else
				-- otherwise, collision. Do not move
			end
			--print(string.format("enemy is at pos y=%s, x=%s", enemy.y, enemy.x))
		end

		update_entity_map(state.entity_map, old_pos, enemy)
	end
end

function core.update_state(state, dt_ms)
	if state.time_to_next_enemy_spawn_ms < 0 then
		for i=1,state.enemies_to_spawn_per_period do
			local new_enemy_pos = get_random_dist_from_player(state.players[1], ENEMY_SPAWN_DIST_FROM_PLAYER)
			spawn_enemy(state, new_enemy_pos)
		end
		state.time_to_next_enemy_spawn_ms = state.enemy_spawn_time_ms
	end

	state.time_to_next_enemy_spawn_ms = state.time_to_next_enemy_spawn_ms - dt_ms

	for _, player_state in ipairs(state.players) do
		if player_state.move_vec.y ~= 0 or
		   player_state.move_vec.x ~= 0 then
			local dy = PLAYER_MOVE_SPEED * player_state.move_vec.y * dt_ms/1000.0
			local dx = PLAYER_MOVE_SPEED * player_state.move_vec.x * dt_ms/1000.0

			player_state.y = player_state.y + dy
			player_state.x = player_state.x + dx
		end
		update_attack_states(state, player_state, dt_ms)
	end

	move_enemies_toward_player(state, dt_ms)
end

function core.set_player_move_vec(state, player_idx, move_vec)
	state.players[player_idx].move_vec.y = move_vec.y
	state.players[player_idx].move_vec.x = move_vec.x
end

return core
