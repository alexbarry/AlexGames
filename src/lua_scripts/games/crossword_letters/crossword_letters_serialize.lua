local serialize = {}

local serialize_lib = require("libs/serialize/serialize")

local core    = require("games/crossword_letters/crossword_letters_core")

function serialize.serialize_state(state)
	if state == nil then return nil end
	local output = ""
	output = output .. serialize_lib.serialize_byte(#state.letters)
	for _, letter in ipairs(state.letters) do
		output = output .. serialize_lib.serialize_byte(string.byte(letter))
	end
	output = output .. serialize_lib.serialize_byte(#state.finished_crossword.grid)
	output = output .. serialize_lib.serialize_byte(#state.finished_crossword.grid[1])
	output = output .. serialize_lib.serialize_byte(state.finished_crossword.word_count)
	for word, word_info in pairs(state.finished_crossword.words) do
		output = output .. serialize_lib.serialize_byte(word_info.pos.y)
		output = output .. serialize_lib.serialize_byte(word_info.pos.x)
		output = output .. serialize_lib.serialize_byte(word_info.orientation)
		output = output .. serialize_lib.serialize_string(word)
	end

	output = output .. serialize_lib.serialize_string(state.hint_word)

	local found_word_count = 0
	for word, _ in pairs(state.found_words) do
		found_word_count = found_word_count + 1
	end

	output = output .. serialize_lib.serialize_16bit(found_word_count)
	for word, _ in pairs(state.found_words) do
		output = output .. serialize_lib.serialize_string(word)
	end

	output = output .. serialize_lib.serialize_16bit(#state.hint_letters)
	for _, pos in ipairs(state.hint_letters) do
		output = output .. serialize_lib.serialize_byte(pos.y)
		output = output .. serialize_lib.serialize_byte(pos.x)
	end

	output = output .. serialize_lib.serialize_16bit(state.puzzle_id)

	return output
end

function serialize.deserialize_state(bytes)
	if bytes == nil then return nil end
	bytes = serialize_lib.bytestr_to_byteary(bytes)

	if #bytes == 0 then return nil end

	local state = {}

	state.letters = {}
	local letter_count = serialize_lib.deserialize_byte(bytes)
	for _=1,letter_count do
		table.insert(state.letters, string.char(serialize_lib.deserialize_byte(bytes)))
	end

	local grid_y_size = serialize_lib.deserialize_byte(bytes)
	local grid_x_size = serialize_lib.deserialize_byte(bytes)
	local word_count  = serialize_lib.deserialize_byte(bytes)

	state.finished_crossword = core.generate_empty_crossword(grid_y_size, grid_x_size)
	for _=1,word_count do
		local word_info = {
			pos = {}
		}
		word_info.pos.y           = serialize_lib.deserialize_byte(bytes)
		word_info.pos.x           = serialize_lib.deserialize_byte(bytes)
		word_info.orientation     = serialize_lib.deserialize_byte(bytes)
		word_info.word            = serialize_lib.deserialize_string(bytes)

		core.add_word_to_crossword_modify(state.finished_crossword, word_info.pos, word_info.orientation, word_info.word)
	end

	state.hint_word = serialize_lib.deserialize_string(bytes)

	local found_word_count = serialize_lib.deserialize_16bit(bytes)
	state.found_words = {}
	for _=1,found_word_count do
		local found_word = serialize_lib.deserialize_string(bytes)
		state.found_words[found_word] = true
	end

	state.hint_letters = {}
	local hint_count = serialize_lib.deserialize_16bit(bytes)
	for _=1,hint_count do
		local hint = {
			y = serialize_lib.deserialize_byte(bytes),
			x = serialize_lib.deserialize_byte(bytes),
		}
		table.insert(state.hint_letters, hint)
	end

	-- TODO BEFORE PUBLISHING this should be a required field
	if #bytes > 0 then
		state.puzzle_id = serialize_lib.deserialize_16bit(bytes)
	end

	if #bytes ~= 0 then
		error(string.format("Found %d bytes remaining after deserialize, expected 0", #bytes))
	end
	
	return state
end

return serialize
