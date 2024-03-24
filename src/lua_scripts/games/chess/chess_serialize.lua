local serialize = {}

local core = require("games/chess/chess_core")
local serialize_lib = require("libs/serialize/serialize")

function serialize.deserialize_state(byte_str)
	local bytes = serialize_lib.bytestr_to_byteary(byte_str)
	local state = {}
	state.player_turn = serialize_lib.deserialize_byte(bytes)
	state.board = {}
	state.selected = nil
	for y=1,core.BOARD_SIZE do
		state.board[y] = {}
		for x=1,core.BOARD_SIZE do
			state.board[y][x] = serialize_lib.deserialize_byte(bytes)
		end
	end

	if #bytes ~= 0 then
		error(string.format("%d bytes remaining after deserializing", #bytes))
	end

	return state
end

function serialize.serialize_state(state)
	local output = ""
	output = output .. serialize_lib.serialize_byte(state.player_turn)
	for y=1,core.BOARD_SIZE do
		for x=1,core.BOARD_SIZE do
			output = output .. serialize_lib.serialize_byte(state.board[y][x])
		end
	end

	return output
end

return serialize
