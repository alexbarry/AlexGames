local serialize = {}

local serialize_lib = require("libs/serialize/serialize")

local function serialize_player_state(player_state)
	local output = ""
	output = output .. serialize_lib.serialize_string(player_state.name)
	output = output .. serialize_lib.serialize_s32(player_state.chips)
	output = output .. serialize_lib.serialize_s32(player_state.bet)
	output = output .. serialize_lib.serialize_bool(player_state.folded)
	output = output .. serialize_lib.serialize_string(player_state.last_action)
	output = output .. serialize_lib.serialize_s32_nilable(player_state.last_bet)

	return output
end

local function deserialize_player_state(bytes)
	local player_state = {}
	player_state.name        = serialize_lib.deserialize_string(bytes)
	player_state.chips       = serialize_lib.deserialize_s32(bytes)
	player_state.bet         = serialize_lib.deserialize_s32(bytes)
	player_state.folded      = serialize_lib.deserialize_bool(bytes)
	player_state.last_action = serialize_lib.deserialize_string(bytes)
	player_state.last_bet    = serialize_lib.deserialize_s32_nilable(bytes)

	return player_state
end

local function serialize_pots(pots)
	local output = ""
	output = output .. serialize_lib.serialize_byte(#pots)
	for _, pot in ipairs(pots) do
		output = output .. serialize_lib.serialize_s32(pot)
	end
	return output
end

local function deserialize_pots(bytes)
	local pots = {}
	local pot_count = serialize_lib.deserialize_byte(bytes)
	for i=1,pot_count do
		pots[i] = serialize_lib.deserialize_s32(bytes)
	end
	return pots
end

function serialize.deserialize_state(bytes_str)
	local bytes = serialize_lib.bytestr_to_byteary(bytes_str)
	print("deserializing " .. #bytes .. " bytes")
	local state = {}
	state.pots = deserialize_pots(bytes)
	local player_count = serialize_lib.deserialize_byte(bytes)
	state.players = {}
	for i=1,player_count do
		state.players[i] = deserialize_player_state(bytes)
	end
	state.min_bet             = serialize_lib.deserialize_s32(bytes)
	state.player_turn         = serialize_lib.deserialize_byte(bytes)

	if #bytes ~= 0 then
		error(string.format("%d bytes leftover after deserializing", #bytes))
	end


	return state
end

function serialize.serialize_state(state)
	local output = ""
	output = output .. serialize_pots(state.pots)
	output = output .. serialize_lib.serialize_byte(#state.players)
	for _, player_state in ipairs(state.players) do
		output = output .. serialize_player_state(player_state)
	end
	output = output .. serialize_lib.serialize_s32(state.min_bet)
	output = output .. serialize_lib.serialize_byte(state.player_turn)

	return output
end

return serialize
