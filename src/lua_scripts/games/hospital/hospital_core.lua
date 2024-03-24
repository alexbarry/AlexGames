local core = {}

local PLAYER_MOVE_SPEED = 3.0/1000

core.ITEM_ID_PLAYER         =  1
core.ITEM_ID_PATIENT_IN_BED =  2
core.ITEM_ID_PATIENT_IN_BED_FLIPPED = 3
core.ITEM_ID_BED            =  4
core.ITEM_ID_BED_FLIPPED    =  5
core.ITEM_ID_BED_SEGMENT_2  =  6
core.ITEM_ID_IV_BAG         =  7
core.ITEM_ID_DEFIB          =  8
core.ITEM_ID_VENTILATOR     =  9
core.ITEM_ID_XRAY_SHEET     = 10
core.ITEM_ID_XRAY_SOURCE    = 11

core.NEEDS_LOW_FLUIDS   = 1
core.NEEDS_LOW_OXYGEN   = 2
core.NEEDS_NO_HEARTBEAT = 3
core.NEEDS_BROKEN_BONE  = 4


core.ACTION_DIR_PAD_POS_CHANGE  = 1
core.ACTION_USE_BTN_DOWN        = 2
core.ACTION_USE_BTN_RELEASE     = 3
core.ACTION_DROP_BTN_DOWN       = 4
core.ACTION_DROP_BTN_RELEASE    = 5

core.USING_ACTION_REVEAL_NEEDS = 1
core.USING_ACTION_LOW_FLUIDS   = 2
core.USING_ACTION_DEFIB        = 3
core.USING_ACTION_VENTILATOR   = 4
core.USING_ACTION_PICK_UP_PATIENT = 5
core.USING_ACTION_PUT_PATIENT_IN_BED = 6

core.EVT_PATIENT_NEED_EXPIRED = 1
core.EVT_PATIENT_CURED        = 2

core.USE_PROGRESS_MAX = 100

local TIME_TO_REVEAL_NEEDS    = 1.0
local TIME_TO_PICK_UP_PATIENT = 0.7

local NEED_LIST = {
	core.NEEDS_LOW_FLUIDS,
	core.NEEDS_NO_HEARTBEAT,
	core.NEEDS_LOW_OXYGEN,
	core.NEEDS_BROKEN_BONE,
}

local NEEDS_TO_USE_TIME_MAP = {
	[core.NEEDS_LOW_FLUIDS]   = 2.5,
	[core.NEEDS_NO_HEARTBEAT] = 1.5,
	[core.NEEDS_LOW_OXYGEN]   = 2.5,
}

local NEED_TO_BED_FIX_TIME_MS = {
	[core.NEEDS_BROKEN_BONE] = 20*1000,
}


local NEEDS_TO_ITEMS_MAP = {
		[core.NEEDS_LOW_FLUIDS]    = { core.ITEM_ID_IV_BAG     },
		[core.NEEDS_NO_HEARTBEAT]  = { core.ITEM_ID_DEFIB      },
		[core.NEEDS_LOW_OXYGEN]    = { core.ITEM_ID_VENTILATOR },
		[core.NEEDS_BROKEN_BONE]   = { },
}

local ITEMS_DROPPED_ON_USE_MAP = {
	[core.ITEM_ID_IV_BAG] = true,
	[core.ITEM_ID_VENTILATOR] = true,
}

-- These seem good for one player...
-- rough ideas, should be sum of:
--    * time to reveal max-ish number of patients that could reasonably need to have
--      their needs revealed at any given time, plus
--    * time to walk halfway across the map, plus
--    * time to fix patient with equipment 
local NEED_TYPE_TO_TIME_LEFT = {
	[core.NEEDS_LOW_FLUIDS]   = 60,
	[core.NEEDS_NO_HEARTBEAT] = 25,
	[core.NEEDS_LOW_OXYGEN]   = 40,
	[core.NEEDS_BROKEN_BONE]  = 90,
}


local DIRS = {
	{ y =  1, x =  0 },
	{ y =  1, x = -1 },
	{ y =  0, x = -1 },
	{ y = -1, x = -1 },
	{ y = -1, x =  0 },
	{ y = -1, x =  1 },
	{ y =  0, x =  1 },
	{ y =  1, x =  1 },
}

local PICK_UP_ITEMS = {
	[core.ITEM_ID_IV_BAG]     = true,
	[core.ITEM_ID_DEFIB]      = true,
	[core.ITEM_ID_VENTILATOR] = true,
}


local function get_player_starting_pos(i)
	--[[
	local map = {
		[1] = { y = 2.5, x = 2.5 },
		[2] = { y = 7.5, x = 7.5 },
		[3] = { y = 7.5, x = 2.5 },
		[4] = { y = 2.5, x = 7.5 },
	}
	]]

	local map = {
		[1] = { y = 2.5, x = 5.0 },
		[2] = { y = 7.5, x = 5.0 },
		[3] = { y = 5.0, x = 2.5 },
		[4] = { y = 5.0, x = 7.5 },
	}
	return map[i]
end

local function new_item(id)
	return {
		id = id,
	}
end

local function new_bed(id, fixes_needs)
	local item = new_item(id)
	if not core.is_bed(item) then
		error(string.format("Item id %s is not bed", id), 2)
	end
	item.fixes_needs = fixes_needs
	return item
end

local needs_type_debug = 0


function core.is_patient(item_info)
	if item_info == nil then
		error("arg is nil", 2)
	end
	return item_info.id == core.ITEM_ID_PATIENT_IN_BED or
	       item_info.id == core.ITEM_ID_PATIENT_IN_BED_FLIPPED
end

function core.is_player(item_info)
	return item_info.id == core.ITEM_ID_PLAYER
end

function core.is_bed(item_info)
	return item_info.id == core.ITEM_ID_BED or
	       item_info.id == core.ITEM_ID_BED_FLIPPED
end

local function new_patient(y, x)
	needs_type_debug = needs_type_debug + 1
	return {
		id = core.ITEM_ID_PATIENT_IN_BED,
		y = y,
		x = x,

		requires_help  = false,
		needs_revealed = false,
		needs_type     = needs_type_debug,

		time_left      = nil,
		orig_time_left = nil,

		held_by        = nil,
	}
end

local function set_patient_need(patient, need_type)
	patient.requires_help  = true
	patient.needs_revealed = false
	patient.needs_type     = need_type
	patient.time_left      = NEED_TYPE_TO_TIME_LEFT[need_type]
	patient.orig_time_left = NEED_TYPE_TO_TIME_LEFT[need_type]
end

local function load_level1(state)
	-- TODO put xray room in top left or top right,
	-- so that it's easier to see
	local level_map = {
		--0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0},   -- 0
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0},   -- 1
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1},   -- 2
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1},   -- 3
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},   -- 4
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},   -- 5
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1},   -- 6
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1},   -- 7
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0},   -- 8
		{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0},   -- 9
		--{ 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},   -- 0
		--{ 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},   -- 1
		--{ 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},   -- 2
		--{ 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},   -- 3
		--{ 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},   -- 4
		--{ 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},   -- 5
	}

	for row_idx, row in ipairs(level_map) do
		local y = row_idx-1
		state.cells[y] = {}
		for col_idx, cell in ipairs(row) do
			local x = col_idx-1
			if level_map[row_idx][col_idx] == 1 then
				state.cells[y][x] = {}
			end
		end
	end

	local level_items = {
		{ y = 2, x = 1, item = new_bed(core.ITEM_ID_BED_FLIPPED) },
		{ y = 1, x = 1, item = new_item(core.ITEM_ID_BED_SEGMENT_2) },
		{ y = 2, x = 4, item = new_bed(core.ITEM_ID_BED_FLIPPED) },
		{ y = 1, x = 4, item = new_item(core.ITEM_ID_BED_SEGMENT_2) },
		{ y = 2, x = 7, item = new_bed(core.ITEM_ID_BED_FLIPPED) },
		{ y = 1, x = 7, item = new_item(core.ITEM_ID_BED_SEGMENT_2) },

		{ y = 2, x = 1, item = new_item(core.ITEM_ID_PATIENT_IN_BED) },
		{ y = 2, x = 4, item = new_item(core.ITEM_ID_PATIENT_IN_BED) },
		{ y = 2, x = 7, item = new_item(core.ITEM_ID_PATIENT_IN_BED) },

		{ y = 7, x = 1, item = new_bed(core.ITEM_ID_BED) },
		{ y = 6, x = 1, item = new_item(core.ITEM_ID_BED_SEGMENT_2) },
		{ y = 7, x = 4, item = new_bed(core.ITEM_ID_BED) },
		{ y = 6, x = 4, item = new_item(core.ITEM_ID_BED_SEGMENT_2) },
		{ y = 7, x = 7, item = new_bed(core.ITEM_ID_BED) },
		{ y = 6, x = 7, item = new_item(core.ITEM_ID_BED_SEGMENT_2) },

		{ y = 7, x = 1, item = new_item(core.ITEM_ID_PATIENT_IN_BED_FLIPPED) },
		{ y = 7, x = 4, item = new_item(core.ITEM_ID_PATIENT_IN_BED_FLIPPED) },
		{ y = 7, x = 7, item = new_item(core.ITEM_ID_PATIENT_IN_BED_FLIPPED) },

		{ y = 1, x = 2, item = new_item(core.ITEM_ID_IV_BAG) },
		{ y = 7, x = 5, item = new_item(core.ITEM_ID_IV_BAG) },
		{ y = 1, x = 6, item = new_item(core.ITEM_ID_IV_BAG) },

		{ y = 7, x = 8, item = new_item(core.ITEM_ID_DEFIB) },
		{ y = 7, x = 2, item = new_item(core.ITEM_ID_VENTILATOR) },


		{ y = 3, x = 14, item = new_item(core.ITEM_ID_XRAY_SOURCE) },
		{ y = 4, x = 14, item = new_item(core.ITEM_ID_BED_SEGMENT_2) },
		{ y = 5, x = 14, item = new_bed(core.ITEM_ID_BED_FLIPPED, {core.NEEDS_BROKEN_BONE}) },
		{ y = 6, x = 14, item = new_item(core.ITEM_ID_XRAY_SHEET) },
	}

	for _, item_info in ipairs(level_items) do
		if core.is_patient(item_info.item) then
			local patient_info = new_patient(item_info.y, item_info.x)
			table.insert(state.patients, patient_info)
			table.insert(state.cells[item_info.y][item_info.x], patient_info)
		else
			table.insert(state.cells[item_info.y][item_info.x], item_info.item)
		end
	end

	set_patient_need(state.patients[1], core.NEEDS_BROKEN_BONE)
	set_patient_need(state.patients[2], core.NEEDS_LOW_FLUIDS)
end

local function add_player(state, player_idx, pos_y, pos_x)
	local player_item = new_item(core.ITEM_ID_PLAYER)
	player_item.player_idx = player_idx
	table.insert(state.cells[math.floor(pos_y)][math.floor(pos_x)], player_item)
	state.players[player_idx] = {
		y = pos_y,
		x = pos_x,
		vel_y = 0,
		vel_x = 0,
		use_btn_down  = false,
		drop_btn_down = false,
		holding = nil,
		is_using = false,
		use_progress = 0,
		use_time     = nil,
	}
end

function core.init(game_params)
	local state = {
		y_size  = game_params.y_size,
		x_size  = game_params.x_size,
		cells   = {},
		patients = {},
		players = {},

		-- 15 seconds was a bit too hard for just one player
		new_sickness_period = 18*1000,
		time_to_new_sickness  = nil,
		new_sickness_count    = 2,
	}
	state.time_to_new_sickness = state.new_sickness_period

	-- print("loading level 1...")
	load_level1(state)


	for i=1,game_params.num_players do
		local pos = get_player_starting_pos(i)
		add_player(state, i, pos.y, pos.x)
	end


	return state
end

function core.handle_player_dirpad_update(state, player, vec_y, vec_x)

	if vec_y ~= 0 or vec_x ~= 0 then
		-- TODO could probably simplify this with a trig identity?
		local mag = math.sqrt(vec_y*vec_y + vec_x*vec_x)
		local angle = math.atan(vec_y, vec_x)
		angle = angle - math.pi/4
		
		vec_y = mag * math.sin(angle)
		vec_x = mag * math.cos(angle)
	end

	state.players[player].vel_y = vec_y * PLAYER_MOVE_SPEED
	state.players[player].vel_x = vec_x * PLAYER_MOVE_SPEED
end

function core.handle_player_use_btn(state, player, btn_down)
	local player_state = state.players[player]
	player_state.use_btn_down = btn_down
	if btn_down then
		return core.use_start(state, player)
	else
		return core.use_stop(state, player)
	end
end

function core.handle_player_drop_btn(state, player, btn_down)
	local player_state = state.players[player]
	player_state.drop_btn_down = btn_down
	if btn_down then
		if player_state.holding ~= nil and
		   not core.is_patient(player_state.holding) then
			core.drop_item(state, player)
		end
	end
end

local function clip_min_max(min_val, max_val, val)
	if val < min_val then return min_val
	elseif val > max_val then return max_val
	else return val end
end

local function is_collision(state, player_idx, tentative_y, tentative_x)
	local tentative_y_idx = math.floor(tentative_y)
	local tentative_x_idx = math.floor(tentative_x)

	-- If we'are already in this cell-- let the player walk through it to escape.
	-- Otherwise they would be completely trapped
	if tentative_y_idx == math.floor(state.players[player_idx].y) and
	   tentative_x_idx == math.floor(state.players[player_idx].x) then
		return false
	end

	if state.cells[tentative_y_idx] == nil or
	   state.cells[tentative_y_idx][tentative_x_idx] == nil then
		return true
	elseif #state.cells[tentative_y_idx][tentative_x_idx] == 0 then
		return false
	elseif #state.cells[tentative_y_idx][tentative_x_idx] == 1 then
		local item_info = state.cells[tentative_y_idx][tentative_x_idx][1]
		return not (item_info.id == core.ITEM_ID_PLAYER and item_info.player_idx == player_idx)
	else
		-- more than one item in dst, so must be collision
		return true
	end
		
end

local function move_player(state, player_idx, pos_y, pos_x)
	local player_state = state.players[player_idx]
	local old_y_idx = math.floor(player_state.y)
	local old_x_idx = math.floor(player_state.x)
	local new_y_idx = math.floor(pos_y)
	local new_x_idx = math.floor(pos_x)
	player_state.y = pos_y
	player_state.x = pos_x

	if old_y_idx ~= new_y_idx or
	   old_x_idx ~= new_x_idx then
		local old_cell = state.cells[old_y_idx][old_x_idx]
		local player_tbl_idx = nil
		for idx, item_info in ipairs(old_cell) do
			if item_info.id == core.ITEM_ID_PLAYER and item_info.player_idx == player_idx then
				player_tbl_idx = idx
				goto found_elem
			end
		end
		::found_elem::

		local item_info = table.remove(old_cell, player_tbl_idx)
		table.insert(state.cells[new_y_idx][new_x_idx], item_info)
	end
end

local function player_can_move(player_state)
	return not player_state.is_using
end

function core.update_state(state, dt)
	local events = {}
	for player_idx, player_state in ipairs(state.players) do

		if player_can_move(player_state) then
			local tentative_y = player_state.y + player_state.vel_y * dt
			local tentative_x = player_state.x + player_state.vel_x * dt

			-- Try to move to the new position.
			-- If it is blocked, try moving in just the y direction, or just the x direction
			if not is_collision(state, player_idx, tentative_y, tentative_x) then
				move_player(state, player_idx, tentative_y, tentative_x)
				player_state.y = tentative_y
				player_state.x = tentative_x
			elseif not is_collision(state, player_idx, tentative_y, player_state.x) then
				move_player(state, player_idx, tentative_y, player_state.x)
				player_state.y = tentative_y
			elseif not is_collision(state, player_idx, player_state.y, tentative_x) then
				move_player(state, player_idx, player_state.y, tentative_x)
				player_state.x = tentative_x
			end
		end

		if player_state.is_using then
			player_state.use_progress = player_state.use_progress + (dt/1000.0/player_state.use_time)*core.USE_PROGRESS_MAX
			if player_state.use_progress >=	core.USE_PROGRESS_MAX then
				player_state.use_progress = core.USE_PROGRESS_MAX
				core.on_use_complete_func(state, player_idx, events)
			end
		end
	end

	for _, patient in ipairs(state.patients) do
		if patient.requires_help then
			if patient.fix_time ~= nil then
				patient.fix_time = patient.fix_time - dt
				if patient.fix_time <= 0 then
					table.insert(events, {
						event = core.EVT_PATIENT_CURED,
						patient = patient,
					})
					patient.requires_help  = false
					patient.needs_revealed = false
					patient.needs_type     = nil
					patient.time_left      = nil
					patient.orig_time_left = nil
					patient.fix_time       = nil
					patient.orig_fix_time  = nil
					goto next_patient
				end
				
			end
			patient.time_left = patient.time_left - dt / 1000.0
			if patient.time_left <= 0 then
				patient.time_left = 0
				table.insert(events, {
					event = core.EVT_PATIENT_NEED_EXPIRED,
					patient = patient,
				})
				patient.requires_help  = false
				patient.needs_revealed = false
				patient.needs_type     = nil
				patient.time_left      = nil
				patient.orig_time_left = nil
				patient.fix_time       = nil
				patient.orig_fix_time  = nil
			end
		end
		::next_patient::
	end

	state.time_to_new_sickness = state.time_to_new_sickness - dt
	if state.time_to_new_sickness <= 0 then
		state.time_to_new_sickness = state.new_sickness_period
		local healthy_patients = {}
		for _, patient in ipairs(state.patients) do
			if not patient.requires_help then
				table.insert(healthy_patients, patient)
			end
		end
		for _=1,state.new_sickness_count do
			if #healthy_patients > 0 then
				local idx = math.random(#healthy_patients)
				set_patient_need(healthy_patients[idx], NEED_LIST[math.random(#NEED_LIST)])
				table.remove(healthy_patients, idx)
			end
		end
	end

	return events
end

function core.get_item_needs_type(item_id)
	local map = {
		[core.ITEM_ID_IV_BAG]        = core.NEEDS_LOW_FLUIDS,
		[core.ITEM_ID_DEFIB]         = core.NEEDS_NO_HEARTBEAT,
		[core.ITEM_ID_VENTILATOR]    = core.NEEDS_LOW_OXYGEN,

	}
	return map[item_id]
end

local function in_range_coords(state, y, x)
	return state.cells[y] ~= nil and state.cells[y][x] ~= nil
end

local function item_id_can_be_picked_up(item_id)
	return PICK_UP_ITEMS[item_id] == true
end


local function ary_contains(ary, elem)
	for _, val in ipairs(ary) do
		if val == elem then return true end
	end
	return false
end

local function patient_can_be_interacted(player_state, patient_info)
	if patient_info.requires_help then
		if not patient_info.needs_revealed then
			return true
		else
			if player_state.holding ~= nil and
			       ary_contains(NEEDS_TO_ITEMS_MAP[patient_info.needs_type], player_state.holding.id) then
				return true
			elseif patient_info.needs_type == core.NEEDS_BROKEN_BONE and
			       -- don't let the player pick up a patient if they are already holding one...
			       -- unless the patients should be swapped? That might be an option in the future
			       (player_state.holding == nil or not core.is_patient(player_state.holding)) then
				return true
			end
		end
	end
	if player_state.holding == nil then
		-- can always pick up patients to move them around
		return true
	end

	return false
end

local function item_id_can_be_interacted(player_state, item_info)
	if item_id_can_be_picked_up(item_info.id) then
		return true
	end

	if core.is_patient(item_info) then
		return patient_can_be_interacted(player_state, item_info)
	end

	if core.is_bed(item_info) and
	   player_state.holding ~= nil and
	   core.is_patient(player_state.holding) then
		return true
	end

	return false
end

local function get_interact_in_cell_idx(state, player_idx, y, x)
	for idx, item in ipairs(state.cells[y][x]) do
		if item_id_can_be_interacted(state.players[player_idx], item) then
			return idx
		end
	end
	return nil
end

local function calc_dist(player_state, y, x)
	local dy = player_state.y - y
	local dx = player_state.x - x
	return math.sqrt( dy*dy + dx*dx )
end

function core.get_closest_item_cell(state, player_idx)
	local player_state = state.players[player_idx]
	local y, x = math.floor(player_state.y), math.floor(player_state.x)

	if in_range_coords(state, y, x) then
		local item_idx = get_interact_in_cell_idx(state, player_idx, y, x)

		if item_idx ~= nil then
			return { y = y, x = x }
		end
	end

	local min_dist = nil
	local closest_cell = nil
	for _, dir in ipairs(DIRS) do
		local y2 = y + dir.y
		local x2 = x + dir.x
		if not in_range_coords(state, y2, x2) then
			goto next_dir
		end
		local item_idx = get_interact_in_cell_idx(state, player_idx, y2, x2)

		if item_idx ~= nil then
			local dist = calc_dist(player_state, y2, x2)
			if min_dist == nil or dist < min_dist then
				min_dist = dist
				closest_cell = { y = y2, x = x2 }
			end
		end
		::next_dir::
	end

	return closest_cell
end

function core.get_patient_pos(patient_info)
	if patient_info.held_by == nil then
		return { y = patient_info.y, x = patient_info.x }
	else
		return { y = patient_info.held_by.y,
		         x = patient_info.held_by.x }
	end
end

function core.get_cells_to_highlight(state)
	local cells_to_highlight = {}

	local items_to_highlight = {}

	for _, patient_info in ipairs(state.patients) do
		if patient_info.requires_help and patient_info.held_by == nil then
			if not patient_info.needs_revealed or 
			   patient_info.needs_type == core.NEEDS_BROKEN_BONE then
				
				local pt = core.get_patient_pos(patient_info)
				if pt.y == nil or pt.x == nil then
					error(string.format("received nil coords, %s", patient_info.held_by) )
				end
				table.insert(cells_to_highlight, pt)
			else
				for _, item in ipairs(NEEDS_TO_ITEMS_MAP[patient_info.needs_type]) do
					items_to_highlight[item] = true
				end
			end
		end
	end

	for y, row in pairs(state.cells) do
		for x, cell in pairs(row) do
			for _, item in ipairs(cell) do
				if items_to_highlight[item.id] then
					table.insert(cells_to_highlight, { y = y, x = x })
					goto next_cell
				end
			end
			::next_cell::
		end
	end

	return cells_to_highlight
end

local function get_item_idx_can_be_picked_up(state, cell)
	for cell_item_idx, item_info in ipairs(state.cells[cell.y][cell.x]) do
		if item_id_can_be_picked_up(item_info.id) then
			return cell_item_idx
		end
	end
	return nil
end

function core.pick_up_item(state, player_idx)
	local cell = core.get_closest_item_cell(state, player_idx)
	if cell == nil then
		return false
	else
		local cell_pick_up_item_idx = get_item_idx_can_be_picked_up(state, cell)
		state.players[player_idx].holding = table.remove(state.cells[cell.y][cell.x], cell_pick_up_item_idx)
		
	end
end

function core.drop_item(state, player_idx, drop_pt)
	local player_state = state.players[player_idx]
	if drop_pt == nil then
		drop_pt = {
			y = math.floor(player_state.y),
			x = math.floor(player_state.x),
		}
	end
	local cell = state.cells[drop_pt.y][drop_pt.x]
	table.insert(cell, player_state.holding)
	player_state.holding = nil
end

local function id_is_patient(info_id)
	return info_id == core.ITEM_ID_PATIENT_IN_BED or
	       info_id == core.ITEM_ID_PATIENT_IN_BED_FLIPPED
end

local function get_patient_in_cell(state, cell)
	for _, info in ipairs(state.cells[cell.y][cell.x]) do
		if id_is_patient(info.id) then
			return info
		end
	end
	return nil
end

local function needs_type_to_using_action(needs_type)
	local map = {
		[core.NEEDS_LOW_FLUIDS]   = core.USING_ACTION_LOW_FLUIDS,
		[core.NEEDS_LOW_OXYGEN]   = core.USING_ACTION_DEFIB,
		[core.NEEDS_NO_HEARTBEAT] = core.USING_ACTION_VENTILATOR,
	}
	return map[needs_type]
end

function empty_bed_in_cell(state, cell_pos)
	local cell = state.cells[cell_pos.y][cell_pos.x]
	local bed_present = false
	local patient_present = false
	for _, item_info in ipairs(cell) do
		if core.is_bed(item_info) then
			bed_present = true
		elseif core.is_patient(item_info) then
			patient_present = true
		end
	end
	return bed_present and not patient_present
end

function core.use_start(state, player_idx)
	local player_state = state.players[player_idx]
	local nearest_item_cell = core.get_closest_item_cell(state, player_idx)

	if player_state.holding == nil and
		nearest_item_cell ~= nil and
		get_item_idx_can_be_picked_up(state, nearest_item_cell) then
		return core.pick_up_item(state, player_idx)
	end

	local patient_info = nil
	
	if nearest_item_cell ~= nil then
		patient_info = get_patient_in_cell(state, nearest_item_cell)
	end

	
	local can_help = false
	local use_time = nil

	-- if the player is holding a patient and near a bed
	if player_state.holding ~= nil and
	   core.is_patient(player_state.holding) and
	   nearest_item_cell ~= nil and
	   empty_bed_in_cell(state, nearest_item_cell) then
		can_help = true
		player_state.using_action = core.USING_ACTION_PUT_PATIENT_IN_BED
		player_state.patient_drop_pos = { y = nearest_item_cell.y, x = nearest_item_cell.x }
		use_time = TIME_TO_PICK_UP_PATIENT
	-- if the player is near a patient who requires aid
	elseif patient_info ~= nil and patient_info.requires_help then
		if not patient_info.needs_revealed then
			can_help = true
			player_state.helping_patient = patient_info
			player_state.using_action    = core.USING_ACTION_REVEAL_NEEDS
			use_time = TIME_TO_REVEAL_NEEDS
		else
			if patient_info.needs_type ~= core.NEEDS_BROKEN_BONE and
			   player_state.holding ~= nil and
			   ary_contains(NEEDS_TO_ITEMS_MAP[patient_info.needs_type], player_state.holding.id) then
				can_help = true
				player_state.helping_patient = patient_info
				player_state.using_action    = needs_type_to_using_action(patient_info.needs_type)
				use_time = NEEDS_TO_USE_TIME_MAP[patient_info.needs_type]
			end
		end
	end

	if not can_help and patient_info ~= nil and
	   (player_state.holding == nil or not core.is_patient(player_state.holding)) then
		-- can move any patient, whether they need help or not
		can_help = true
		player_state.helping_patient = patient_info
		player_state.using_action    = core.USING_ACTION_PICK_UP_PATIENT
		use_time = TIME_TO_PICK_UP_PATIENT
	end



	if can_help then
		player_state.is_using     = true
		player_state.use_progress = 0
		player_state.use_time     = use_time
		return true
	else
		return false
	end
end

function core.use_stop(state, player_idx)
	local player_state = state.players[player_idx]
	player_state.is_using     = false
	player_state.use_progress = 0
	player_state.helping_patient = nil
	player_state.using_action    = nil
end

local function get_patient_item_pos(patient_info)
	return {
		y = patient_info.y - 1,
		x = patient_info.x + 1,
	}
end

local function get_patient_cell_idx(state, patient_info)
	local cell = state.cells[patient_info.y][patient_info.x]
	for idx, item_in_cell in ipairs(cell) do
		if item_in_cell == patient_info then
			return idx
		end
	end
	return nil
end

local function bed_fixes_needs(bed, needs_type)
	if bed.fixes_needs == nil then
		return false
	end
	for _, bed_fixes in ipairs(bed.fixes_needs) do
		if bed_fixes == needs_type then
			return true
		end
	end
	return false
end

local function patient_put_in_bed(state, patient_info)
	local cell = state.cells[patient_info.y][patient_info.x]
	local bed = nil
	for _, item_info in ipairs(cell) do
		if core.is_bed(item_info) then
			bed = item_info
			break
		end
	end

	patient_info.in_bed = bed
	if bed_fixes_needs(bed, patient_info.needs_type) then
		local fix_time = NEED_TO_BED_FIX_TIME_MS[patient_info.needs_type]
		patient_info.orig_fix_time = fix_time
		patient_info.fix_time      = fix_time
	end
end

function core.on_use_complete_func(state, player_idx, events)
	local player_state = state.players[player_idx]
	local patient_info = player_state.helping_patient
	local using_action = player_state.using_action
	core.use_stop(state, player_idx)

	if using_action == core.USING_ACTION_PUT_PATIENT_IN_BED then
		local patient = player_state.holding
		core.drop_item(state, player_idx, player_state.patient_drop_pos)
		patient.y = player_state.patient_drop_pos.y
		patient.x = player_state.patient_drop_pos.x
		patient.held_by = nil
		player_state.patient_drop_pos = nil
		patient_put_in_bed(state, patient)
	elseif using_action == core.USING_ACTION_PICK_UP_PATIENT then
		if player_state.holding ~= nil then
			core.drop_item(state, player_idx)
		end
		local patient_cell_idx = get_patient_cell_idx(state, patient_info)
		table.remove(state.cells[patient_info.y][patient_info.x], patient_cell_idx)
		player_state.holding = patient_info
		patient_info.held_by = player_state
		patient_info.y = nil
		patient_info.x = nil
		patient_info.fix_time = nil
	elseif patient_info.requires_help then
		if not patient_info.needs_revealed then
			if using_action == core.USING_ACTION_REVEAL_NEEDS then
				patient_info.needs_revealed = true
			end
		else
			if needs_type_to_using_action(patient_info.needs_type) == using_action then
				patient_info.requires_help  = false
				patient_info.needs_revealed = false
				if ITEMS_DROPPED_ON_USE_MAP[player_state.holding.id] then
					core.drop_item(state, player_idx, get_patient_item_pos(patient_info))
				end

				table.insert(events, {
					event = core.EVT_PATIENT_CURED,
					patient = patient_info,
				})

			end
		end
	end
end

return core
