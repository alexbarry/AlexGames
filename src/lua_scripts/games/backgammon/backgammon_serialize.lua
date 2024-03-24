local serialize = {}

local core = require("games/backgammon/backgammon_core")
local serialize_lib = require("libs/serialize/serialize")

serialize.CURRENT_VERSION = 2

-- when encoding dice
local USED_DICE_BIT_OFFSET   = 3
assert(6 < 2^USED_DICE_BIT_OFFSET)

-- when encoding cells
local CELL_PLAYER_BIT_OFFSET = 5
assert(24 < 2^CELL_PLAYER_BIT_OFFSET)

local function bit_idx_to_mask(bit_idx)
	return (1<<bit_idx) - 1
end

function serialize.serialize_state(state)
	local output = ""
	output = output .. serialize_lib.serialize_byte(serialize.CURRENT_VERSION)
	output = output .. serialize_lib.serialize_byte(state.game_state)
	output = output .. serialize_lib.serialize_byte(state.player_turn)
	output = output .. serialize_lib.serialize_byte(math.floor(math.log(state.double_val)/math.log(2)))
	output = output .. serialize_lib.serialize_byte(#state.player_init_rolls)
	for i=1,#state.player_init_rolls do
		output = output .. serialize_lib.serialize_byte(state.player_init_rolls[i])
	end
	output = output .. serialize_lib.serialize_byte(#state.dice_vals)
	for i=1,#state.dice_vals do
		local used_dice_int = 0
		if state.used_dice[i] then
			used_dice_int = 1
		end
		local dice_val_encoded = state.dice_vals[i] | (used_dice_int << USED_DICE_BIT_OFFSET)
		output = output .. serialize_lib.serialize_byte(dice_val_encoded)
	end
	for _,player_idx in ipairs(core.PLAYERS) do
		output = output .. serialize_lib.serialize_byte(#state.pieces_in_middle[player_idx])
		output = output .. serialize_lib.serialize_byte(#state.finished_pieces[player_idx])
	end

	for board_idx=core.BOARD_IDX_START,core.BOARD_IDX_END do
		local coords = core.board_idx_to_coords(board_idx)
		local cell = state.board[coords.y][coords.x]
		local cell_enc = 0

		if #cell > 0 then
			local player_in_cell = cell[1]
			cell_enc = (#cell) | (player_in_cell << CELL_PLAYER_BIT_OFFSET)
		end
		output = output .. serialize_lib.serialize_byte(cell_enc)
	end

	return output
end

function serialize.deserialize_state(byte_str)
	local bytes = serialize_lib.bytestr_to_byteary(byte_str)
	local state = {
		dice_vals = {},
		used_dice = {},

		pieces_in_middle = {},
		finished_pieces = {},
		board = {},
	}
	for _, player_idx in ipairs(core.PLAYERS) do
		state.pieces_in_middle[player_idx] = {}
		state.finished_pieces[player_idx]  = {}
	end
	for y=1,core.BACKGAMMON_ROWS do
		table.insert(state.board, {})
		for x=1,core.BACKGAMMON_COLS do
			table.insert(state.board[y], {})
		end
	end

	local version = serialize_lib.deserialize_byte(bytes)
	if version ~= serialize.CURRENT_VERSION then
		error(string.format("Received serialized state encoded with version %d, can only handle %d", version, serialize.CURRENT_VERSION))
	end


	state.game_state = serialize_lib.deserialize_byte(bytes)
	state.player_turn = serialize_lib.deserialize_byte(bytes)
	state.double_val = 2^serialize_lib.deserialize_byte(bytes)

	local player_init_rolls_count = serialize_lib.deserialize_byte(bytes)
	state.player_init_rolls = {}
	for _=1,player_init_rolls_count do
		table.insert(state.player_init_rolls, serialize_lib.deserialize_byte(bytes))
	end

	local dice_count = serialize_lib.deserialize_byte(bytes)
	for _=1,dice_count do
		local dice_enc_val = serialize_lib.deserialize_byte(bytes)
		table.insert(state.dice_vals, dice_enc_val & bit_idx_to_mask(USED_DICE_BIT_OFFSET))
		table.insert(state.used_dice, (dice_enc_val >> USED_DICE_BIT_OFFSET) ~= 0)
	end

	for _,player_idx in ipairs(core.PLAYERS) do
		local middle_count = serialize_lib.deserialize_byte(bytes)
		local finished_count = serialize_lib.deserialize_byte(bytes)
		for _=1,middle_count do
			table.insert(state.pieces_in_middle[player_idx], player_idx)
		end
		for _=1,finished_count do
			table.insert(state.finished_pieces[player_idx], player_idx)
		end
	end

	for board_idx=core.BOARD_IDX_START,core.BOARD_IDX_END do
		local coords = core.board_idx_to_coords(board_idx)
		local cell_enc = serialize_lib.deserialize_byte(bytes)
		if cell_enc > 0 then
			local player_in_cell = cell_enc >> CELL_PLAYER_BIT_OFFSET
			local cell_piece_count = cell_enc & bit_idx_to_mask(CELL_PLAYER_BIT_OFFSET)
			for _=1,cell_piece_count do
				table.insert(state.board[coords.y][coords.x], player_in_cell)
			end
		end
	end

	if #bytes ~= 0 then
		error(string.format("After deserializing state, %d bytes remain, expected 0", #bytes))
	end

	return state
end

return serialize
