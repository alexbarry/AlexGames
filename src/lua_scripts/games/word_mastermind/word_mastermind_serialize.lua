local serialize = {}

local serialize_lib = require("libs/serialize/serialize")

local core = require("games/word_mastermind/word_mastermind_core")

serialize.version = 1

function serialize.serialize_state(state)
	if state == nil then return nil end
	local output = ""

	output = output .. serialize_lib.serialize_byte(serialize.version)

	output = output .. serialize_lib.serialize_byte(state.max_guesses)
	output = output .. serialize_lib.serialize_string(state.word)
	output = output .. serialize_lib.serialize_16bit(#state.guesses)
	for _, guess in ipairs(state.guesses) do
		output = output .. serialize_lib.serialize_string(guess.word)
	end

	return output
end

function serialize.deserialize_state(bytes)
	if bytes == nil then return nil end
	bytes = serialize_lib.bytestr_to_byteary(bytes)

	local version = serialize_lib.deserialize_byte(bytes)

	if version ~= serialize.version then
		error(string.format("can't deserialize state: received version %d, this implementation version is %d", version, serialize.version))
	end

	local partial_state = {}
	partial_state.max_guesses = serialize_lib.deserialize_byte(bytes)
	partial_state.word        = serialize_lib.deserialize_string(bytes)
	partial_state.guesses     = {}
	local guess_count         = serialize_lib.deserialize_16bit(bytes)
	for i=1,guess_count do
		table.insert(partial_state.guesses, serialize_lib.deserialize_string(bytes))
	end

	local state = core.new_game(#partial_state.word, partial_state.max_guesses, partial_state.word)
	for guess_idx, guess in ipairs(partial_state.guesses) do
		core.force_guess(state, guess)
	end

	return state
end

function serialize.serialize_session_id(bytes)
	return serialize_lib.serialize_s32(bytes)
end

function serialize.deserialize_session_id(bytestr)
	if bytestr == nil then
		return nil
	end
	bytes = serialize_lib.bytestr_to_byteary(bytestr)
	return serialize_lib.deserialize_s32(bytes)
end

return serialize
