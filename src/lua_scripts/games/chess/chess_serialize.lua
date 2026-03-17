local serialize = {}

local core = require("games/chess/chess_core")
local utils = require("libs/utils")
local serialize_lib = require("libs/serialize/serialize")

serialize.VERSION_1 = 1
serialize.VERSION_2 = 2
serialize.VERSION_3 = 3

serialize.CURRENT_VERSION = serialize.VERSION_3

function serialize.deserialize_state(byte_str)
	local bytes = serialize_lib.bytestr_to_byteary(byte_str)
	local version
	if #bytes == 65 then
		version = serialize.VERSION_1
	else
		version = serialize_lib.deserialize_byte(bytes)
	end

	local state = {}
	state.rooks_moved = {}
	state.kings_moved = {}
	state.pawn_moved_two_squares = 0

	if version == serialize.VERSION_1 then
		state.rooks_moved[core.POS_ROOK1_BLACK] = false
		state.rooks_moved[core.POS_ROOK2_BLACK] = false
		state.rooks_moved[core.POS_ROOK1_WHITE] = false
		state.rooks_moved[core.POS_ROOK2_WHITE] = false
		state.kings_moved[core.PLAYER_WHITE]    = false
		state.kings_moved[core.PLAYER_BLACK]    = false

	elseif version == serialize.VERSION_2 or version == serialize.VERSION_3 then
		local pieces_moved_bitfield = serialize_lib.deserialize_byte(bytes)
		state.rooks_moved[core.POS_ROOK1_BLACK] = utils.number_to_boolean(pieces_moved_bitfield & (1 << 0))
		state.rooks_moved[core.POS_ROOK2_BLACK] = utils.number_to_boolean(pieces_moved_bitfield & (1 << 1))
		state.rooks_moved[core.POS_ROOK1_WHITE] = utils.number_to_boolean(pieces_moved_bitfield & (1 << 2))
		state.rooks_moved[core.POS_ROOK2_WHITE] = utils.number_to_boolean(pieces_moved_bitfield & (1 << 3))
		state.kings_moved[core.PLAYER_WHITE]    = utils.number_to_boolean(pieces_moved_bitfield & (1 << 4))
		state.kings_moved[core.PLAYER_BLACK]    = utils.number_to_boolean(pieces_moved_bitfield & (1 << 5))

		if version == serialize.VERSION_3 then
			state.pawn_moved_two_squares = serialize_lib.deserialize_byte(bytes)
		end
	else
		error(string.format("Unhandled serialized chess state, version %d", version))
	end

	state.player_turn = serialize_lib.deserialize_byte(bytes)
	state.board = {}
	state.selected = nil
	for y=1,core.BOARD_SIZE do
		state.board[y] = {}
		for x=1,core.BOARD_SIZE do
			state.board[y][x] = serialize_lib.deserialize_byte(bytes)
		end
	end
	state.game_status = core.get_game_status(state)

	if #bytes ~= 0 then
		error(string.format("%d bytes remaining after deserializing", #bytes))
	end

	return state
end

function serialize.serialize_state(state)
	local output = ""
	output = output .. serialize_lib.serialize_byte(serialize.CURRENT_VERSION)

	local pieces_moved_bitfield = 0
	pieces_moved_bitfield = pieces_moved_bitfield | utils.boolean_to_number(state.rooks_moved[core.POS_ROOK1_BLACK]) * (1 << 0)
	pieces_moved_bitfield = pieces_moved_bitfield | utils.boolean_to_number(state.rooks_moved[core.POS_ROOK2_BLACK]) * (1 << 1)
	pieces_moved_bitfield = pieces_moved_bitfield | utils.boolean_to_number(state.rooks_moved[core.POS_ROOK1_WHITE]) * (1 << 2)
	pieces_moved_bitfield = pieces_moved_bitfield | utils.boolean_to_number(state.rooks_moved[core.POS_ROOK2_WHITE]) * (1 << 3)
	pieces_moved_bitfield = pieces_moved_bitfield | utils.boolean_to_number(state.kings_moved[core.PLAYER_WHITE]) * (1 << 4)
	pieces_moved_bitfield = pieces_moved_bitfield | utils.boolean_to_number(state.kings_moved[core.PLAYER_BLACK]) * (1 << 5)

	output = output .. serialize_lib.serialize_byte(pieces_moved_bitfield)

	output = output .. serialize_lib.serialize_byte(state.pawn_moved_two_squares)

	output = output .. serialize_lib.serialize_byte(state.player_turn)
	for y=1,core.BOARD_SIZE do
		for x=1,core.BOARD_SIZE do
			output = output .. serialize_lib.serialize_byte(state.board[y][x])
		end
	end

	return output
end

return serialize
