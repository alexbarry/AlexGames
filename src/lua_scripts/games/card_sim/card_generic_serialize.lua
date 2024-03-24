local cards = require("libs/cards/cards")

local serialize = {}

-- TODO put it a library 
local function serialize_16bit(val)
	local output = ""
	local orig_val = val
	if val == nil then
		val = 0x7fff
	else
		val = math.floor(val)
	end
	val = val + 0x7fff
	if not(0 <= val and val <= 0xffff) then
		error(string.format("Need 16 bit val, recvd %s", orig_val))
		return nil
	end
	output = output .. string.char(math.floor((val/256))&0xff)
	output = output .. string.char(math.floor(val%256))
	return output
end
-- TODO put in a library
local function deserialize_16bit(bytes)
	if #bytes < 2 then
		error(string.format("Expected at least 2 bytes, recvd %d", #bytes))
	end
	local msb = string.byte(table.remove(bytes,1))
	local lsb = string.byte(table.remove(bytes,1))
	local val = ((msb << 8) | lsb) - 0x7fff
	--print(string.format("deserialize_16bit %02x %02x returning %s", msb, lsb, val))
	if val == 0x7fff then
		return nil
	else
		return val
	end
end

local function bytestr_to_byteary(byte_str)
	local byte_ary = {}
	for i=1,#byte_str do
		byte_ary[i] = byte_str:sub(i,i)
	end
	return byte_ary
end



function serialize.serialize_state_for_client(state, player)
	local output = ""

	
	output = output .. serialize_16bit(state.card_height)
	output = output .. serialize_16bit(state.card_width)
	output = output .. serialize_16bit(#state.player_states)
	for _, player_state in ipairs(state.player_states) do
		output = output .. serialize_16bit(player_state.y)
		output = output .. serialize_16bit(player_state.x)
		-- this could be a single byte
		output = output .. serialize_16bit(player_state.card_idx)
		output = output .. serialize_16bit(player_state.card_orig_y)
		output = output .. serialize_16bit(player_state.card_orig_x)
	end

	output = output .. serialize_16bit(#state.cards)
	for _, card_info in ipairs(state.cards) do
		local card_int = nil
		if card_info.revealed_all or card_info.revealed_to_player == player then
			card_int = cards.card_to_int(card_info.card)
		else
			card_int = cards.UNREVEALED_CARD
		end
		output = output .. serialize_16bit(card_int)
		output = output .. serialize_16bit(card_info.y)
		output = output .. serialize_16bit(card_info.x)
	end
	return output
end

function serialize.deserialize_client_state(bytes)
	local state = {}
	bytes = bytestr_to_byteary(bytes)

	state.card_height = deserialize_16bit(bytes)
	state.card_width = deserialize_16bit(bytes)

	local player_count = deserialize_16bit(bytes)
	state.player_states = {}
	for i=1,player_count do
		state.player_states[i] = {}
		state.player_states[i].y           = deserialize_16bit(bytes)
		state.player_states[i].x           = deserialize_16bit(bytes)
		state.player_states[i].card_idx    = deserialize_16bit(bytes)
		state.player_states[i].card_orig_y = deserialize_16bit(bytes)
		state.player_states[i].card_orig_x = deserialize_16bit(bytes)
	end

	local card_count = deserialize_16bit(bytes)
	state.cards = {}
	for i=1,card_count do
		state.cards[i] = {}
		local card_int = deserialize_16bit(bytes)
		state.cards[i].card = cards.int_to_card(card_int)
		state.cards[i].y = deserialize_16bit(bytes)
		state.cards[i].x = deserialize_16bit(bytes)
		state.cards[i].recvd = true
	end

	return state
end

return serialize
