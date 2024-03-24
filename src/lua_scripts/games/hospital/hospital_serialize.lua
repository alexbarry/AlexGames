local serialize = {}

local core = require("games/hospital/hospital_core")
local utils = require("libs/utils")
local serialize_lib = require("libs/serialize/serialize")

local function get_patient_info_idx(state, item_info)
	for idx, patient_info in ipairs(state.patients) do
		if patient_info == item_info then
			return idx
		end
	end
	return nil
end

local function deserialize_patient_info(state, bytes)
	local info = {}
	info.id             = serialize_lib.deserialize_byte(bytes)
	info.y              = serialize_lib.deserialize_byte(bytes)
	info.x              = serialize_lib.deserialize_byte(bytes)
	info.requires_help  = serialize_lib.deserialize_bool(bytes)
	info.needs_revealed = serialize_lib.deserialize_bool(bytes)
	info.needs_type     = serialize_lib.deserialize_byte(bytes)
	local time_left_s32 = serialize_lib.deserialize_s32(bytes)
	if time_left_s32 == 0x7fffffff then
		info.time_left = nil
	else
		info.time_left      = time_left_s32
	end
	local orig_time_left_s32 = serialize_lib.deserialize_s32(bytes)
	if orig_time_left_s32 ~= 0x7fffffff then
		info.orig_time_left = orig_time_left_s32
	else
		info.orig_time_left = nil
	end
	local held_by_player_idx = serialize_lib.deserialize_byte(bytes)
	if held_by_player_idx == nil then
		info.held_by = nil
	else
		info.held_by = state.players[held_by_player_idx]
	end

	return info
end

local function get_player_idx(state, player_state)
	if player_state == nil then
		return nil
	end
	for idx, player in ipairs(state.players) do
		if player == player_state then
			return idx
		end
	end
	error("could not find player in states")
end

local function serialize_patient_info(state, patient_info)
	local output = ""
	output = output .. serialize_lib.serialize_byte(patient_info.id)
	output = output .. serialize_lib.serialize_byte(patient_info.y)
	output = output .. serialize_lib.serialize_byte(patient_info.x)
	output = output .. serialize_lib.serialize_bool(patient_info.requires_help)
	output = output .. serialize_lib.serialize_bool(patient_info.needs_revealed)
	output = output .. serialize_lib.serialize_byte(patient_info.needs_type)
	if patient_info.time_left ~= nil then
		output = output .. serialize_lib.serialize_s32( math.floor(patient_info.time_left))
	else
		output = output .. serialize_lib.serialize_s32( 0x7fffffff )
	end
	if patient_info.orig_time_left ~= nil then
		output = output .. serialize_lib.serialize_s32( patient_info.orig_time_left)
	else
		output = output .. serialize_lib.serialize_s32( 0x7fffffff )
	end

	output = output .. serialize_lib.serialize_byte(get_player_idx(state, patient_info.held_by))
		
	return output
end

local function deserialize_player_info(bytes)
	local info = {}
	info.id            = core.ITEM_ID_PLAYER
	info.y             = serialize_lib.deserialize_s32(bytes)*1.0/1000
	info.x             = serialize_lib.deserialize_s32(bytes)*1.0/1000
	info.vel_y         = serialize_lib.deserialize_s32(bytes)*1.0/1000/1000
	info.vel_x         = serialize_lib.deserialize_s32(bytes)*1.0/1000/1000
	info.use_btn_down  = serialize_lib.deserialize_bool(bytes)
	info.drop_btn_down = serialize_lib.deserialize_bool(bytes)
	local holding_id   = serialize_lib.deserialize_byte(bytes)
	if holding_id == nil then
		info.holding = nil
	else
		info.holding = { id = holding_id }
	end
	info.is_using      = serialize_lib.deserialize_bool(bytes)
	info.use_progress  = serialize_lib.deserialize_byte(bytes)
	local use_time_byte = serialize_lib.deserialize_byte(bytes)
	if use_time_byte == 0xff then
		info.use_time = nil
	else
		info.use_time      = use_time_byte
	end
	return info
end

local function serialize_player_info(player_info)
	local output = ""
	output = output .. serialize_lib.serialize_s32( math.floor(player_info.y*1000))
	output = output .. serialize_lib.serialize_s32( math.floor(player_info.x*1000))
	output = output .. serialize_lib.serialize_s32( math.floor(player_info.vel_y*1000*1000))
	output = output .. serialize_lib.serialize_s32( math.floor(player_info.vel_x*1000*1000))
	output = output .. serialize_lib.serialize_bool(player_info.use_btn_down)
	output = output .. serialize_lib.serialize_bool(player_info.drop_btn_down)
	local holding_id = nil
	if player_info.holding ~= nil then
		holding_id = player_info.holding.id
	end
	output = output .. serialize_lib.serialize_byte(holding_id)
	output = output .. serialize_lib.serialize_bool(player_info.is_using)
	output = output .. serialize_lib.serialize_byte(math.floor(player_info.use_progress))
	if player_info.use_time ~= nil then
		output = output .. serialize_lib.serialize_byte(math.floor(player_info.use_time))
	else
		output = output .. serialize_lib.serialize_byte(0xff)
	end
	return output
end

local function serialize_cell(state, cell)
	local output = ""
	output = output .. serialize_lib.serialize_byte(#cell)
	local debug_type = nil
	for _, item_info in ipairs(cell) do
		output = output .. serialize_lib.serialize_byte(item_info.id)
		if core.is_patient(item_info) then
			local patient_idx = get_patient_info_idx(state, item_info)
			output = output .. serialize_lib.serialize_byte(patient_idx)
			debug_type = "patient"
		elseif core.is_player(item_info) then
			local player_idx = item_info.player_idx
			output = output .. serialize_lib.serialize_byte(player_idx)
			debug_type = "player"
		else
			debug_type = "none"
		end
	end
	local s = ""
	for _, item_info in ipairs(cell) do
		s = s .. string.format("%d, ", item_info.id)
	end
	--print(string.format("serialized cell into %d bytes, had %d items (%s) (%s) (%s)", #output, #cell, debug_type, s, utils.binstr_to_hr_str(output)))
	return output
end

local function deserialize_cell(state, bytes)
	local start_byte_count = #bytes
	local cell = {}
	local item_count = serialize_lib.deserialize_byte(bytes)
	local debug_type = "nil"
	for i=1,item_count do
		local item_id = serialize_lib.deserialize_byte(bytes)
		local item_info = {
			id = item_id,
		}
		if core.is_patient(item_info) then
			local patient_idx = serialize_lib.deserialize_byte(bytes)
			if not(1 <= patient_idx and patient_idx <= #state.patients) then
				error(string.format("expected patient idx, received %s, have " ..
				      " only %d patient states", patient_idx, #state.patients))
			end
			debug_type = "patient"
			item_info = state.patients[patient_idx]
		elseif core.is_player(item_info) then
			local player_idx = serialize_lib.deserialize_byte(bytes)
			if not(1 <= player_idx and player_idx <= #state.players) then
				error(string.format("expected player idx, received %s, have " ..
				      " only %d player states", player_idx, #state.players))
			end
			debug_type = "player"
			item_info = state.players[player_idx]
			item_info.id = item_id
			item_info.player_idx = player_idx
		else
			debug_type = "none"
		end
		table.insert(cell, item_info)
	end
	--print(string.format("deserialized cell from %d bytes, contained %d items (%s)", start_byte_count - #bytes, item_count, debug_type))
	return cell
end

function serialize.serialize_state(state)
	local output = ""
	output = output .. serialize_lib.serialize_byte(state.y_size)
	output = output .. serialize_lib.serialize_byte(state.x_size)

	output = output .. serialize_lib.serialize_s32(state.new_sickness_period)
	output = output .. serialize_lib.serialize_s32_nilable(state.time_to_new_sickness)
	output = output .. serialize_lib.serialize_byte(state.new_sickness_count)

	output = output .. serialize_lib.serialize_byte(#state.players)
	for _, player in ipairs(state.players) do
		output = output .. serialize_player_info(player)
	end
	output = output .. serialize_lib.serialize_byte(#state.patients)
	for _, patient in ipairs(state.patients) do
		output = output .. serialize_patient_info(state, patient)
	end
	local cells_serialized = ""
	local non_empty_cell_count = 0
	for y, row in pairs(state.cells) do
		for x, cell in pairs(row) do
			if state.cells[y][x] ~= nil then
				cells_serialized = cells_serialized .. serialize_lib.serialize_byte(y)
				cells_serialized = cells_serialized .. serialize_lib.serialize_byte(x)
				cells_serialized = cells_serialized .. serialize_cell(state, state.cells[y][x])
				non_empty_cell_count = non_empty_cell_count + 1
			end
		end
	end
	output = output .. serialize_lib.serialize_16bit(non_empty_cell_count)
	output = output .. cells_serialized
	--print(string.format("serialized %d non empty cells into %d bytes", non_empty_cell_count, #cells_serialized))
	--print(string.format("serialized into %d bytes", #output))
	return output
end

function serialize.deserialize_state(byte_str)
	local bytes = serialize_lib.bytestr_to_byteary(byte_str)
	--print(string.format("deserializing %d bytes", #bytes))
	local state = {}
	state.y_size = serialize_lib.deserialize_byte(bytes)
	state.x_size = serialize_lib.deserialize_byte(bytes)

	state.new_sickness_period  = serialize_lib.deserialize_s32(bytes)
	state.time_to_new_sickness = serialize_lib.deserialize_s32_nilable(bytes)
	state.new_sickness_count   = serialize_lib.deserialize_byte(bytes)

	local player_count = serialize_lib.deserialize_byte(bytes)
	state.players  = {}
	for i=1,player_count do
		state.players[i] = deserialize_player_info(bytes)
	end

	local patient_count = serialize_lib.deserialize_byte(bytes)
	state.patients = {}
	for i=1,patient_count do
		--print("deserializing patient " .. i)
		state.patients[i] = deserialize_patient_info(state, bytes)
	end

	state.cells = {}

	local non_empty_cell_count = serialize_lib.deserialize_16bit(bytes)
	--print("deserializing " .. non_empty_cell_count .. " cells from " .. #bytes .. " remaining bytes" )
	for i=1,non_empty_cell_count do
		--print("i=" .. i ..", remaining bytes: " .. utils.binary_to_hr_str(bytes))
		local y = serialize_lib.deserialize_byte(bytes)
		local x = serialize_lib.deserialize_byte(bytes)
		if state.cells[y] == nil then
			state.cells[y] = {}
		end
		state.cells[y][x] = deserialize_cell(state, bytes)
	end

	if #bytes > 0 then
		error(string.format("received %d leftover bytes when deserializing", #bytes))
	end
	
	return state
end

return serialize
