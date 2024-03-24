local serialize = {}

function serialize_byte(val)
	if val == nil then val = 128 end
	return string.char(val)
end

function deserialize_byte(bytes)
	local val = string.byte(table.remove(bytes,1))
	if val == 128 then val = nil end
	return val
end

function bool_to_byte(val)
	if val then return 1
	else return 0 end
end

function byte_to_bool(val)
	if val == 1 then return true
	elseif val == 0 then return false
	else error(string.format("Expected 1 or 0 for bool, recvd %s", val)) end
end

function serialize_bool(val)
	return serialize_byte(bool_to_byte(val))
end

function deserialize_bool(bytes)
	return byte_to_bool(deserialize_byte(bytes))
end

function serialize.serialize_state(state)
	local output = ""
	output = output .. serialize_bool(state.game_settings.must_jump_when_able)
	output = output .. serialize_byte(state.player_turn)
	output = output .. serialize_byte(state.selected_y)
	output = output .. serialize_byte(state.selected_x)
	output = output .. serialize_bool(state.must_jump_selected)
	local board_height = #state.board
	local board_width  = #state.board[1]
	output = output .. serialize_byte(board_height)
	output = output .. serialize_byte(board_width)
	for y=1,board_height do
		for x=1,board_width do
			output = output .. serialize_byte(state.board[y][x])
		end
	end

	return output
end

function serialize.deserialize_state(byte_str)
	local bytes = {}
	for i=1,#byte_str do
		bytes[i] = byte_str:sub(i,i)
	end

	if #bytes ~= 7 + 64 then
		error(string.format("Expected to recieve %d bytes, recvd %d", 7 + 64, #bytes))
	end

	local state = {}
	state.game_settings = {}

	state.game_settings.must_jump_when_able = deserialize_bool(bytes)
	state.player_turn         = deserialize_byte(bytes)
	state.selected_y          = deserialize_byte(bytes)
	state.selected_x          = deserialize_byte(bytes)
	state.must_jump_selected  = deserialize_bool(bytes)

	local board_height = deserialize_byte(bytes)
	local board_width = deserialize_byte(bytes)
	state.board = {}
	for y=1,board_height do
		state.board[y] = {}
		for x=1,board_width do
			state.board[y][x] = deserialize_byte(bytes)
		end
	end
	return state
end

return serialize
