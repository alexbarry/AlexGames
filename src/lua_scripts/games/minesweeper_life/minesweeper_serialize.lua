local serialize = {}

local bit_pack = require("libs/serialize/bit_pack")
local core = require("games/minesweeper_life/minesweeper_life_core")

serialize.VERSION = 1
local serialize_lib = require("libs/serialize/serialize")

local function serialize_cell_for_client(cell)
	if not cell.revealed then
		if cell.flagged_by_player == nil then return 0
		else return 10 + cell.flagged_by_player end
	else
		if cell.has_mine then return 10
		else
			if cell.touching_mine_count > 0 then
				return cell.touching_mine_count
			else
				return 9
			end
		end
	end
end

local function client_deserialize_cell(bytes)
	local byte = table.remove(bytes, 1)
	byte = string.byte(byte)
	local cell = {
		revealed = false,
		has_mine = false,
		flagged_by_player = nil,
		touching_mine_count = nil,
	}
	if byte == 0 then
		-- pass
	elseif 11 <= byte and byte <= 14 then
		cell.flagged_by_player = byte - 10
	elseif byte == 10 then
		cell.revealed = true
		cell.has_mine = true
	elseif byte == 9 then
		cell.revealed = true
		cell.touching_mine_count = 0
	elseif 1 <= byte and byte <= 8 then
		cell.revealed = true
		cell.touching_mine_count = byte
	else
		error(string.format("unexpected serialized cell byte=%s", byte))
	end

	return cell
end

function serialize.serialize_client_game_state(state, player)
	local game_state = state.game
	local output = ""
	output = output .. serialize_lib.serialize_byte(#state.players)
	output = output .. serialize_lib.serialize_16bit(game_state.width)
	output = output .. serialize_lib.serialize_16bit(game_state.height)
	for i=1,#state.players do
		local player_state = state.players[i]
		output = output .. serialize_lib.serialize_s32(player_state.score)
	end
	for y=1,game_state.height do
		for x=1,game_state.width do
			local serialized_cell = serialize_cell_for_client(game_state.board[y][x])
			output = output .. serialize_lib.serialize_byte(serialized_cell)
		end
	end
	return output
end

function serialize.deserialize_client_game_state(state, bytes)
	bytes = serialize_lib.bytestr_to_byteary(bytes)
	local game_state = state.game
	local player_count      = serialize_lib.deserialize_byte(bytes)
	game_state.width        = serialize_lib.deserialize_16bit(bytes)
	game_state.height       = serialize_lib.deserialize_16bit(bytes)
	for i=1,player_count do
		if state.players[i] == nil then
			error(string.format("player idx %d not in map when len %d", i, #state.players))
		end
		state.players[i].score = serialize_lib.deserialize_s32(bytes)
	end
	game_state.board = {}
	for y=1,game_state.height do
		game_state.board[y] = {}
		for x=1,game_state.width do
			game_state.board[y][x] = client_deserialize_cell(bytes)
		end
	end
	return game_state
end

local function serialize_cell_concise(cell)
	local val = 0
	if cell.flagged_by_player ~= nil then val = val | 0x4 end
	if cell.revealed                 then val = val | 0x2 end
	if cell.has_mine                 then val = val | 0x1 end

	return val
end

local function deserialize_cell_concise(val)
	local cell = {}
	cell.flagged_by_player = (val & 0x4) > 0
	if cell.flagged_by_player then
		cell.flagged_by_player = 1
	else
		cell.flagged_by_player = nil
	end
	cell.revealed          = (val & 0x2) > 0
	cell.has_mine          = (val & 0x1) > 0
	return cell
end

local function serialize_cells_concise(cells)
	local cells_3bits = {} 
	for y=1,#cells do
		for x=1,#cells[1] do
			table.insert(cells_3bits, serialize_cell_concise(cells[y][x]))
		end
	end

	return bit_pack.pack(cells_3bits, 3)
end

local function deserialize_cells_concise(cells_bytes)
	local cells = {}
	for y=1,#cells_bytes do
		local row = {}
		for x=1,#cells_bytes[1] do
			table.insert(row, deserialize_cell_concise(cells_bytes[y][x]))
		end
		table.insert(cells, row)
	end
	return cells
end

local function unflatten(cells_flat, height, width)
	local cells = {}
	for y=1,height do
		local row = {}
		for x=1,width do
			table.insert(row, cells_flat[(y-1)*width + x] )
		end
		table.insert(cells, row)
	end
	return cells
end


function serialize.serialize_state(state)
	local output = ""
	output = output .. serialize_lib.serialize_byte(serialize.VERSION)
	output = output .. serialize_lib.serialize_byte(state.game.height)
	output = output .. serialize_lib.serialize_byte(state.game.width)
	output = output .. serialize_lib.serialize_bytes(serialize_cells_concise(state.game.board))
	return output
end

function serialize.deserialize_state(bytes)
	bytes = serialize_lib.bytestr_to_byteary(bytes)
	local state = {
		game = {},
	}
	local version = serialize_lib.deserialize_byte(bytes)
	if version ~= serialize.VERSION then
		error(string.format("Can only deserialize state version %d, found %d", serialize.VERSION, version))
	end
	state.game.height = serialize_lib.deserialize_byte(bytes)
	state.game.width  = serialize_lib.deserialize_byte(bytes)

	local cells_flat_bytes_packed = serialize_lib.deserialize_bytes(bytes)
	local cells_flat_serialized = bit_pack.unpack(cells_flat_bytes_packed, 3)
	local cells_bytes = unflatten(cells_flat_serialized, state.game.height, state.game.width)
	state.game.board = deserialize_cells_concise(cells_bytes)

	core.calc_state_vals(state)

	state.players = {
		core.new_player_state(),
	}

	return state
end

return serialize
