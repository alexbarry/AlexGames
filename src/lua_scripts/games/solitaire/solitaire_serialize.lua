local serialize = {}

local cards = require("libs/cards/cards")
local serialize_lib = require("libs/serialize/serialize")

local core  = require("games/solitaire/solitaire_core")

serialize.VERSION = 2

function serialize.serialize_board_state(state)
	local output = ""
	output = output .. serialize_lib.serialize_byte(state.draw_type)
	output = output .. cards.serialize_card_array(state.deck_unrevealed)
	output = output .. cards.serialize_card_array(state.deck_draw)
	output = output .. cards.serialize_card_array(state.deck_discard)
	for i=1,core.NUM_PLAY_COLUMNS do
		output = output .. cards.serialize_card_array(state.play_columns_unrevealed[i])
		output = output .. cards.serialize_card_array(state.play_columns_staging[i])
	end
	for i=1,core.NUM_GOAL_STACKS do
		output = output .. cards.serialize_card_array(state.goal_stacks[i])
	end

	if state.move_count ~= nil then
		output = output .. serialize_lib.serialize_16bit(state.move_count)
	else
		output = output .. serialize_lib.serialize_16bit(0)
	end

	if state.time_elapsed ~= nil then
		output = output .. serialize_lib.serialize_16bit(state.time_elapsed)
	else
		output = output .. serialize_lib.serialize_16bit(0)
	end
	return output
end

function serialize.serialize_state(state)
	if state == nil then
		error("arg is nil", 2)
	end

	local output = ""
	output = output .. serialize_lib.serialize_byte(serialize.VERSION)
	output = output .. serialize_lib.serialize_byte(state.player_count)
	output = output .. serialize.serialize_board_state(state)

	-- TODO I don't like the player state being serialized
	for _, player_state in ipairs(state.players) do
		output = output .. serialize_lib.serialize_16bit(player_state.y)
		output = output .. serialize_lib.serialize_16bit(player_state.x)
		output = output .. cards.serialize_card_array(player_state.holding)
		output = output .. serialize_lib.serialize_16bit(player_state.holding_src)
		output = output .. serialize_lib.serialize_16bit(player_state.holding_src_col)
	end
	output = output .. serialize_lib.serialize_u64(state.seed_x)
	output = output .. serialize_lib.serialize_u64(state.seed_y)
	return output
end


local function deserialize_board_state_internal(version, bytes, state)
	state.draw_type       = serialize_lib.deserialize_byte(bytes)
	state.deck_unrevealed = cards.deserialize_card_array(bytes)
	state.deck_draw       = cards.deserialize_card_array(bytes)
	state.deck_discard    = cards.deserialize_card_array(bytes) state.play_columns_unrevealed = {}
	state.play_columns_staging    = {}
	for i=1,core.NUM_PLAY_COLUMNS do
		state.play_columns_unrevealed[i] = cards.deserialize_card_array(bytes)
		state.play_columns_staging[i]    = cards.deserialize_card_array(bytes)
	end
	state.goal_stacks = {}
	for i=1,core.NUM_GOAL_STACKS do
		state.goal_stacks[i] = cards.deserialize_card_array(bytes)
	end

	print(string.format('Deserializing board state version %d', version))
	if version == 1 then
		-- do nothing
	elseif version == serialize.VERSION then
		state.move_count   = serialize_lib.deserialize_16bit(bytes)
		state.time_elapsed = serialize_lib.deserialize_16bit(bytes)
	else
		error(string.format("Unhandled solitaire serialized state version " ..
		                    "%d, expected <= %d",
		                    version,
		                    serialize.VERSION))
	end
end

function serialize.deserialize_board_state(bytes)
	local state = {}
	bytes = serialize_lib.bytestr_to_byteary(bytes)
	deserialize_board_state_internal(version, bytes, state)

	if #bytes ~= 0 then
		error(string.format("%d bytes remaining after deserializing", #bytes))
	end

	return state
end

function serialize.deserialize_state(bytes)
	bytes = serialize_lib.bytestr_to_byteary(bytes)
	local state = {}
	local first_byte = serialize_lib.deserialize_byte(bytes)
	local version
	-- in the first version, I didn't have a byte for version.
	-- But I did have a player count that was always 1
	if first_byte == 1 then
		state.player_count = 1
		version = 1
	else
		version = first_byte
		if version ~= serialize.VERSION then
			error(string.format("Received solitaire serialized state for " ..
			                    "version %d, but can only handle <= %d",
			                    version, serialize.VERSION))
		end
		state.player_count    = serialize_lib.deserialize_byte(bytes)
	end

	deserialize_board_state_internal(version, bytes, state)

	state.players = {}
	for i=1, state.player_count do
		state.players[i] = {}
		state.players[i].y               = serialize_lib.deserialize_16bit(bytes)
		state.players[i].x               = serialize_lib.deserialize_16bit(bytes)
		state.players[i].holding         = cards.deserialize_card_array(bytes)
		state.players[i].holding_src     = serialize_lib.deserialize_16bit(bytes)
		state.players[i].holding_src_col = serialize_lib.deserialize_16bit(bytes)
	end
	state.seed_x = serialize_lib.deserialize_u64(bytes)
	state.seed_y = serialize_lib.deserialize_u64(bytes)

	if #bytes ~= 0 then
		error(string.format("%d bytes remaining after deserializing", #bytes))
	end

	return state
end

return serialize
