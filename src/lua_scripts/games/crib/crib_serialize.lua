local serialize = {}
local core = require("games/crib/crib_core")

local cards = require("libs/cards/cards")

local function serialize_byte(val)
	if val == nil then error("nil arg", 2) end
	return string.char(val)
end

local function deserialize_byte(bytes)
	return string.byte(table.remove(bytes, 1))
end

local function bool_to_int(bool)
	if bool then return 1
	else return 0 end
end

local function int_to_bool(val)
	if val == 0 then return false
	elseif val == 1 then return true
	else error(string.format("Unexpected value for bool: %s", val)) end
end

local function serialize_255bool_ary(ary)
	local chars = {}
	chars[#chars+1] = string.char(#ary)
	for i=1,#ary do
		chars[#chars+1] = string.char(bool_to_int(ary[i]))
	end
	return table.concat(chars, "")
end

local function deserialize_255bool_ary(bytes)
	local ary = {}
	local ary_len = string.byte(table.remove(bytes,1))
	if ary_len > #bytes then
		error(string.format("Read ary_len %d, only %d bytes left", ary_len, #bytes))
	end
	for i=1,ary_len do
		ary[i] = int_to_bool(string.byte(table.remove(bytes,1)))
	end
	return ary
end

function serialize.serialize_state(state)
	return serialize.serialize_client_state(state, nil)
end

-- If player is nil, then store all players' hands
-- Otherwise, only serialize the hand for `player`.
function serialize.serialize_client_state(state, player)
	if state == nil then return nil end
	local output = ""
	output = output .. serialize_byte(state.state)
	output = output .. serialize_byte(state.player_turn)
	output = output .. serialize_byte(state.player_crib)
	output = output .. serialize_byte(state.player_count)
	output = output .. serialize_byte(state.playing_sum)
	output = output .. serialize_byte(state.first_player_cant_move)
	output = output .. cards.serialize_card(state.cut_deck_card)
	output = output .. cards.serialize_card_array(state.playing_sequence)

	local show_all_players = (player == nil)

	for player_idx, hand in ipairs(state.hands) do
		if show_all_players or player == player_idx then
			output = output .. serialize_byte(player_idx)
			output = output .. serialize_byte(1)
			for _, card in ipairs(state.hands[player_idx]) do
				assert(card ~= cards.UNREVEALED_CARD and type(card) == 'table')
			end
			output = output .. cards.serialize_card_array(state.hands[player_idx])
		else
			output = output .. serialize_byte(player_idx)
			output = output .. serialize_byte(0)
			output = output .. serialize_byte(#hand)
		end
	end

	for player_idx,playing in ipairs(state.playing) do
		output = output .. cards.serialize_card_array(playing)
	end
	for player_idx,played in ipairs(state.played) do
		output = output .. cards.serialize_card_array(played)
	end

	for player_idx,_ in ipairs(state.tentative_discards) do
		output = output .. serialize_255bool_ary(state.tentative_discards[player_idx])
	end

	for player_idx=1,state.player_count do
		output = output .. serialize_byte(state.score[player_idx])
	end

	if show_all_players or state.state == core.states.ACKNOWLEDGE_CRIB then
		output = output .. cards.serialize_card_array(state.crib)
	else
		output = output .. cards.serialize_card_array({})
	end
	output = output .. serialize_255bool_ary(state.acknowledged_points)
	return output
end

local function bytestr_to_byteary(bytestr)
	local byteary = {}
	for i=1,#bytestr do
		byteary[i] = bytestr:sub(i,i)
	end
	return byteary
end

-- TODO remove this
function serialize.deserialize_client_state(bytes)
	return serialize.deserialize_state(bytes)
end

function serialize.deserialize_state(bytes, is_host)
	if bytes == nil then error("deserialize_state arg is nil", 2) end
	bytes = bytestr_to_byteary(bytes)
	local state = {}
	state.state        = deserialize_byte(bytes)
	state.player_turn  = deserialize_byte(bytes)
	state.player_crib  = deserialize_byte(bytes)
	state.player_count = deserialize_byte(bytes)
	state.playing_sum   = deserialize_byte(bytes)
	state.first_player_cant_move = deserialize_byte(bytes)
	state.cut_deck_card   = cards.deserialize_card(bytes)
	state.playing_sequence = cards.deserialize_card_array(bytes)

	state.playing = {}
	state.played  = {}
	state.hands = {}

	for _=1,state.player_count do
		local other_player_idx = deserialize_byte(bytes)
		local cards_visible = deserialize_byte(bytes)
		if is_host then
			if cards_visible ~= 1 then
				error(string.format("as host, deserialized state with cards_visible = %s", cards_visible))
			end
		end
		if cards_visible == 0 then
			local count = deserialize_byte(bytes)
			state.hands[other_player_idx] = {}
			for _=1,count do
				table.insert(state.hands[other_player_idx], cards.UNREVEALED_CARD)
			end
		elseif cards_visible == 1 then
			state.hands[other_player_idx] = cards.deserialize_card_array(bytes)
			for _, card in ipairs(state.hands[other_player_idx]) do
				if card == cards.UNREVEALED_CARD then
					error(string.format("Unexpected card value: %d", card))
				end
				if type(card) ~= 'table' then
					error(string.format("Unexpected card value: %s", type(card)))
				end
			end
		else
			-- TODO unhandled
			error(string.format("unhandled cards_visible val=%d", cards_visible))
		end
	end

	for other_player_idx=1,state.player_count do
		state.playing[other_player_idx] = cards.deserialize_card_array(bytes)
	end
	for other_player_idx=1,state.player_count do
		state.played[other_player_idx] = cards.deserialize_card_array(bytes)
	end

	state.tentative_discards = {}
	for player_idx=1,state.player_count do
		state.tentative_discards[player_idx] = deserialize_255bool_ary(bytes)
	end

	state.score = {}
	for player_idx=1,state.player_count do
		state.score[player_idx] = deserialize_byte(bytes)
	end

	state.crib = cards.deserialize_card_array(bytes)

	state.acknowledged_points = deserialize_255bool_ary(bytes)


	if #bytes ~= 0 then
		error(string.format("%d bytes remaining after deserializing", #bytes))
	end

	return state
end

return serialize
