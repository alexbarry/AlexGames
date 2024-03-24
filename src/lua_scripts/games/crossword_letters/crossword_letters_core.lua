-- Author: Alex Barry (github.com/alexbarry)
local core = {}


local LANGUAGE = "en"

core.VERTICAL   = 1
core.HORIZONTAL = 2

core.EMPTY = " "

core.RC_SUCCESS              =  0
core.RC_NOT_IN_DICTIONARY    = -1
core.RC_NOT_IN_CROSSWORD     = -2
core.RC_WORD_ALREADY_FOUND   = -3
core.RC_LETTER_NOT_AVAILABLE = -4


local ORIENTATIONS = {
	core.VERTICAL,
	core.HORIZONTAL,
}

local ERR_MSGS = {
	[core.RC_NOT_IN_DICTIONARY]  = "Not in dictionary",
	[core.RC_NOT_IN_CROSSWORD]   = "Not in crossword",
	[core.RC_WORD_ALREADY_FOUND] = "Word already found",
	[core.RC_LETTER_NOT_AVAILABLE] = "Letter not available",
}

local ALPHABET = {}
for i=0,25 do
	table.insert(ALPHABET, string.char(string.byte('a') + i))
end

function core.rc_to_msg(rc)
	return ERR_MSGS[rc]
end

local g_get_words_func = nil

function core.set_get_words_func(get_words_func)
	g_get_words_func = get_words_func
end

local function sqlite_query(query)
	return g_get_words_func(query)
end


local function get_words_made_from_letters(letters, min_length, min_freq)
	local letters_count = {}
	for _, letter in ipairs(letters) do
		if letters_count[letter] == nil then
			letters_count[letter] = 0
		end
		letters_count[letter] = letters_count[letter] + 1
	end
	local query = "SELECT word FROM words WHERE\n"
	query = query .. string.format(" LENGTH(word) <= %d \n", #letters)
	query = query .. string.format(" AND LENGTH(word) >= %d \n", min_length)
	query = query .. string.format(" AND freq >= %e \n", min_freq)
	query = query .. string.format(" AND NOT words.is_vulgar_or_weird \n")
	local first = true
	for _, letter in pairs(ALPHABET) do
		local count = 1
		if letters_count[letter] ~= nil then
			count = letters_count[letter] + 1
		end
		query = query .. " AND word NOT LIKE '%"
		for _=1,count do
			query = query .. letter .. "%"
		end
		query = query .. "'\n"
	end
	query = query .. "ORDER BY LENGTH(word) DESC, freq DESC \n"
	query = query .. "LIMIT 20 \n"

	--print(query)
	return sqlite_query(query)
end

local function copy_list_except_idx(list, except_idx)
	local new_list = {}
	for idx, val in ipairs(list) do
		if idx ~= except_idx then
			table.insert(new_list, val)
		end
	end
	return new_list
end

function core.generate_empty_crossword(height, width)
	local rows = {}
	for y=1,height do
		local row = {}
		for x=1,width do
			table.insert(row, core.EMPTY)
		end
		table.insert(rows, row)
	end
	local crossword = {
		grid  = rows,

		word_count = 0,
		-- elements in words should be: {
		--     word = "crane",
		--     pos = { y = 1, x = 1},
		--     orientation = core.VERTICAL,
		-- }
		words = {},
	}
	return crossword
end

local function get_word_positions(word, start_pos, orientation)
	if word == nil then error("word is nil", 2) end
	if start_pos == nil then error("start_pos is nil", 2) end
	if type(word) ~= "string" then error("word is not str", 2) end
	local positions = {}
	for i=1,#word do
		local letter = word:sub(i,i)
		local letter_pos = { y = start_pos.y, x = start_pos.x , letter = letter, idx = i }
		if orientation == core.HORIZONTAL then
			letter_pos.x = letter_pos.x + (i-1)
		elseif orientation == core.VERTICAL then
			letter_pos.y = letter_pos.y + (i-1)
		else
			error(string.format("Unexpected orientation %s", orientation), 2)
		end

		table.insert(positions, letter_pos)
	end

	return positions
end

-- Only meant to be called by serialize functions.
-- Not meant to be called outside this file for any other purpose.
function core.add_word_to_crossword_modify(crossword, pos, orientation, word)
	for _, p in ipairs(get_word_positions(word, pos, orientation)) do
		crossword.grid[p.y][p.x] = p.letter
	end

	crossword.word_count = crossword.word_count + 1
	crossword.words[word] = {
		word        = word,
		pos         = pos,
		orientation = orientation,
	}
end

local function get_letters_revealed_for_word(state, word)
	local crossword = core.get_filled_crossword_grid(state)
	local word_info = state.finished_crossword.words[word]
	local letters_revealed = 0
	for _, pos in ipairs(get_word_positions(word, word_info.pos, word_info.orientation)) do
		if crossword[pos.y][pos.x] ~= "?" then
			letters_revealed = letters_revealed + 1
		end
	end

	return letters_revealed
end

local function copy_crossword(crossword)
	local new_crossword = core.generate_empty_crossword(#crossword.grid, #crossword.grid[1])
	
	for _, word in pairs(crossword.words) do
		core.add_word_to_crossword_modify(new_crossword, word.pos, word.orientation, word.word)
	end

	return new_crossword
end

local function add_word_to_crossword(crossword, pos, orientation, word)
	local crossword = copy_crossword(crossword)
	core.add_word_to_crossword_modify(crossword, pos, orientation, word)
	return crossword
end


local function pos_in_range(crossword, pos)
	return ((1 <= pos.y and pos.y <= #crossword.grid) and
	        (1 <= pos.x and pos.x <= #crossword.grid[1]))
end

local function other_orientation(orientation)
	if orientation == core.VERTICAL then return core.HORIZONTAL
	elseif orientation == core.HORIZONTAL then return core.VERTICAL
	else error(string.format("unexpected orientation %s", orientation), 2) end
end

local function get_adjacent_positions(pos, orientation)
	local adjacent_positions = {}

	if orientation == core.HORIZONTAL then
		table.insert(adjacent_positions, { y = pos.y    , x = pos.x + 1 })
		table.insert(adjacent_positions, { y = pos.y    , x = pos.x - 1 })
	elseif orientation == core.VERTICAL then
		table.insert(adjacent_positions, { y = pos.y + 1, x = pos.x     })
		table.insert(adjacent_positions, { y = pos.y - 1, x = pos.x     })
	end
	return adjacent_positions
end

function core.crossword_to_string(crossword)
	if crossword == nil then
		return "crossword is nil"
	end

	local output = ""
	output = output .. ("+")
	for x=1,#crossword.grid[1] do
		output = output .. ("-")
	end
	output = output .. ("+\n")
	for y=1,#crossword.grid do
		output = output .. ("|")
		for x=1,#crossword.grid[1] do
			local c = crossword.grid[y][x]
			--if c == nil then
			--	c = ' '
			--end
			output = output .. (c)
		end
		output = output .. ("|\n")
	end
	output = output .. ("+")
	for x=1,#crossword.grid[1] do
		output = output .. ("-")
	end
	output = output .. ("+\n")

	return output
end

function core.print_crossword(crossword)
	print(core.crossword_to_string(crossword))
end

local function get_all_possible_positions(crossword)
	local positions = {}
	for y=1,#crossword.grid do
		for x=1,#crossword.grid[1] do
			for _, orientation in ipairs(ORIENTATIONS) do
				table.insert(positions, {y=y, x=x, orientation=orientation})
			end
		end
	end
	return positions
end

local function get_edge_positions(word, pos, orientation)
	local positions = {}
	if orientation == core.VERTICAL then
		table.insert(positions, { y = pos.y - 1    , x = pos.x })
		table.insert(positions, { y = pos.y + #word, x = pos.x })
	elseif orientation == core.HORIZONTAL then
		table.insert(positions, { y = pos.y, x = pos.x - 1     })
		table.insert(positions, { y = pos.y, x = pos.x + #word })
	else
		error(string.format("unexpected orientation %s", orientation), 2)
	end

	return positions
end

-- Checks if the word fits in the crossword at the specified pos and oritentation.
local function word_fits_in_crossword(crossword, word, pos, orientation, empty_ok)

	local edge_positions = get_edge_positions(word, pos, orientation)
	for _, edge_pos in ipairs(edge_positions) do
		if not pos_in_range(crossword, edge_pos) then
			goto next_edge_pos
		end

		if crossword.grid[edge_pos.y][edge_pos.x] ~= core.EMPTY then
			return false
		end
		::next_edge_pos::
	end

	local found_letter = false
	local positions = get_word_positions(word, pos, orientation)


	for _, pos in ipairs(positions) do
		if not pos_in_range(crossword, pos) then
			return false
		end

		-- ensure destination cell is the same as what we're
		-- placing over it, or that it's empty
		if crossword.grid[pos.y][pos.x] ~= pos.letter and
		   crossword.grid[pos.y][pos.x] ~= core.EMPTY then
			return false
		end

		if crossword.grid[pos.y][pos.x] == pos.letter then
			found_letter = true
		else
			-- If this cell isn't already occupied, then make sure that
			-- it's not adjacent to any existing letters
			for _, adjacent_pos in ipairs(get_adjacent_positions(pos, other_orientation(orientation))) do
				if pos_in_range(crossword, adjacent_pos) and
				   crossword.grid[adjacent_pos.y][adjacent_pos.x] ~= core.EMPTY then
					return false
				end
			end
		end
		
	end


	if empty_ok then
		return true
	else
		return found_letter
	end
end

local function get_possible_positions(crossword, word, empty_ok)
	local positions = {}
	for y=1,#crossword.grid do
		for x=1,#crossword.grid[1] do
			for _, orientation in ipairs(ORIENTATIONS) do
				local pos = { y = y, x = x }
				if word_fits_in_crossword(crossword, word, pos, orientation, empty_ok) then
					table.insert(positions, { pos = pos, orientation = orientation })
				end
			end
		end
	end
	return positions
end

local function generate_crossword_from_words(words, crossword)

	-- instead of finding the best, find first
	local FIND_FIRST = true

	--core.print_crossword(crossword)
	local max_score             = nil
	local best_crossword        = nil
	local best_next_word        = nil
	local best_next_pos         = nil
	local best_next_orientation = nil
	--print(string.format("generate_crossword from %d words...", #words))
	for word_idx, word in ipairs(words) do
		local empty_ok = (crossword.word_count == 0)
		if type(word) ~= "string" then error("word is not string") end
		local positions = get_possible_positions(crossword, word, empty_ok)
		--print(string.format("trying word: %-12s, positions %d", word, #positions))
		for _, pos in ipairs(positions) do
			local crossword2 = add_word_to_crossword(crossword, pos.pos, pos.orientation, word)

			local words2 = copy_list_except_idx(words, word_idx)

			local finished_crossword
			if #words2 == 0 then
				finished_crossword = crossword2
				--core.print_crossword(crossword2)
				--print("-------")
			else
				--print(string.format("Selected word \"%s\", generating crossword with %d other words", word, #words2))
				finished_crossword = generate_crossword_from_words(words2, crossword2)
			end
			--print(string.format("Successfully generated crossword"))

			if finished_crossword ~= nil and (max_score == nil or #finished_crossword.word_count >= max_score) then
				max_score             = finished_crossword.word_count
				best_crossword        = finished_crossword
				best_next_word        = word
				best_next_pos         = pos
				best_next_orientation = orientation
			end

			if FIND_FIRST and finished_crossword ~= nil then
				return finished_crossword
			end
		end
	end

	return best_crossword
end


function core.generate_crossword(words, height, width)
	return generate_crossword_from_words(words, core.generate_empty_crossword(height, width))
end

local function take_first_x_vals(vals, x)
	local new_vals = {}
	for i=1,#vals do
		if i > x then return new_vals end
		table.insert(new_vals, vals[i])
	end 
	return new_vals
end

function core.generate_crossword_from_letters(letters, params)
	--print("called generate_crossword_from_letters")

	local words = get_words_made_from_letters(letters, params.min_word_len, params.min_word_freq)
	--print(string.format("found %d words that can be made from letters", #words))

	for _, word in ipairs(words) do
		--print(word)
	end

	if #words <= 4 then
		local letters_str = "{"
		local first = true
		for _, letter in ipairs(letters) do
			if not first then letters_str = letters_str .. ", " end
			first = false
			letters_str = letters_str .. letter
		end
		letters_str = letters_str .. "}"
		error(string.format("Could not find at least 4 words made from letters: %s", letters_str))
	end

	local crossword = nil
	--for i=4,#words do
	if true then
		i = #words
		local words2 = take_first_x_vals(words, 18)
		
		--print(string.format("Generating crossword with first %d words...", #words2))
		crossword = core.generate_crossword(words2, params.crossword_height, params.crossword_width)
		--print(i)
		--core.print_crossword(crossword)
	end

	return crossword
	
end

local function orientation_to_lua_str(orientation)
	if orientation == core.HORIZONTAL then
		return 'core.HORIZONTAL'
	elseif orientation == core.VERTICAL then
		return 'core.VERTICAL'
	else
		error(string.format("Unhandled orientation %s", orientation), 2)
	end
end

local function str_list_to_hr_str(str_list)
	local output = "{"
	local first = true
	for _, str in ipairs(str_list) do
		if not first then
			output = output .. ", "
		end
		first = false
		output = output .. string.format("%q", str)
	end
	output = output .. "}"

	return output
end

-- Rather than run the computationally expensive act of crossword generation
-- on the user's browser/PC before they can play anything, this function is
-- used to convert the generated crossword into a string of Lua code
-- that can be hardcoded in with the game, to "preload" some pre-generated
-- puzzles.
function core.crossword_words_to_lua_code(letters, crossword)
	local output = "{\n"
	output = output .. string.format("\tletters = %s,\n", str_list_to_hr_str(letters))
	output = output .. "\tword_positions = {\n"
	for _, word in pairs(crossword.words) do
		output = output .. string.format("\t\t{ word = %-20s, pos = { y = %2d, x = %2d }, orientation = %-17s},\n",
		                                 string.format("%q", word.word),
		                                 word.pos.y, word.pos.x,
		                                 orientation_to_lua_str(word.orientation))
	end
	output = output .. "\t},\n"
	output = output .. "},\n"
	return output
end

--function core.new_game(letters, params)
--end

function core.new_game_from_crossword(puzzle_id, crossword, letters)
	local state = {
		puzzle_id          = puzzle_id,
		letters            = letters,
		finished_crossword = crossword,

		finished           = false,
		
		-- key is found word
		found_words        = {},

		-- each hint is simply { y = y, x = x}
		hint_letters       = {},
		hint_word          = nil,
	}
	return state
end

local function crossword_from_word_list(word_positions, params)
	local crossword = core.generate_empty_crossword(params.crossword_height, params.crossword_width)
	for _, word in pairs(word_positions) do
		core.add_word_to_crossword_modify(crossword, word.pos, word.orientation, word.word)
	end
	return crossword
end


function core.new_game_from_pregen_puzzle(puzzle_id, puzzle, params)
	local crossword = crossword_from_word_list(puzzle.word_positions, params)
	return core.new_game_from_crossword(puzzle_id, crossword, puzzle.letters, params)
end

function core.get_filled_crossword_grid(state, show_all)
	local filled_crossword_grid = core.generate_empty_crossword(#state.finished_crossword.grid, #state.finished_crossword.grid[1]).grid
	for y=1,#filled_crossword_grid do
		for x=1,#filled_crossword_grid[y] do
			--print(string.format("crossword[%d][%d] = %q (%s, %s)", y, x, state.finished_crossword.grid[y][x], state.finished_crossword.grid[y][x] == core.EMPTY, core.EMPTY))
			filled_crossword_grid[y][x] = ""
			if state.finished_crossword.grid[y][x] ~= core.EMPTY then
				filled_crossword_grid[y][x] = "?"
			end
		end
	end
	--print(string.format("generated grid of height %d, width %d", #filled_crossword_grid, #filled_crossword_grid[1]))
	if show_all then
		for _, word_info in pairs(state.finished_crossword.words) do
			-- TODO note that this actually solves the crossword in state.
			-- this is bad. It should only show the words.
			-- But I am lazy and taking a shortcut since this is just for testing for now.
			--print(string.format("word is: %s", word_info.word))
			state.found_words[word_info.word] = true
		end
	end
	for word, _ in pairs(state.found_words) do
		local word_info = state.finished_crossword.words[word]
		local cell_positions = get_word_positions(word_info.word, word_info.pos, word_info.orientation)
		for _, pos in ipairs(cell_positions) do
			--print(string.format("populating pos %d %d with letter %s", pos.y, pos.x, pos.letter))
			filled_crossword_grid[pos.y][pos.x] = pos.letter
		end
	end

	for _, hint in ipairs(state.hint_letters) do
		-- they should be the same anyway... but it feels weird
		-- to overwrite a cell with a hint, if the rest of the word
		-- was already guessed correctly.
		if filled_crossword_grid[hint.y][hint.x] == "?" then
			filled_crossword_grid[hint.y][hint.x] = state.finished_crossword.grid[hint.y][hint.x]
		end
	end
	return filled_crossword_grid
end

local function is_game_finished(state)
	for word, _ in pairs(state.finished_crossword.words) do
		if not state.found_words[word] then
			return false
		end
	end
	return true
end

function core.word_input(state, word)
	word = string.lower(word)
	if state.finished_crossword.words[word] == nil then
		return core.RC_NOT_IN_CROSSWORD
	end
	if state.found_words[word] then
		return core.RC_WORD_ALREADY_FOUND
	end

	print("User found word %q", word)
	state.found_words[word] = true
	if is_game_finished(state) then
		state.finished = true
	end
	return core.RC_SUCCESS
end

function find_word_with_fewest_letters_revealed(state)
	local min_letters_revealed = nil
	local min_letters_word     = nil
	for word, word_info in pairs(state.finished_crossword.words) do
		if state.found_words[word] ~= nil then
			goto next_word
		end
		local letters_revealed = get_letters_revealed_for_word(state, word)
		if letters_revealed ~= #word and
		   (min_letters_revealed == nil or
		   letters_revealed <= min_letters_revealed or
		   #min_letters_word < #word) then
			min_letters_revealed = letters_revealed
			min_letters_word     = word
		end

		::next_word::
	end

	return min_letters_word
end

function core.hint(state)
	-- see if the word previously chosen for hints has now been fully revealed
	if state.hint_word ~= nil then
		local revealed = get_letters_revealed_for_word(state, state.hint_word)
		print(string.format("existing hint word %q has %s letters revealed, len %s", state.hint_word, revealed, #state.hint_word))
	end
	if state.hint_word ~= nil and
	   get_letters_revealed_for_word(state, state.hint_word) == #state.hint_word then
		print(string.format("existing hint word %q has all %d letters revealed, finding new hint word", state.hint_word, #state.hint_word))
		state.hint_word = nil
	end

	-- if we don't have a chosen hint word, choose one
	if state.hint_word == nil then
		state.hint_word = find_word_with_fewest_letters_revealed(state)

		if state.hint_word == nil then
			print("Can't provide hint, all letters have been revealed!")
			return
		end
	end

	local crossword = core.get_filled_crossword_grid(state)
	print(string.format("Looking for word %q", state.hint_word))
	local word_info = state.finished_crossword.words[state.hint_word]

	for _, pos in ipairs(get_word_positions(state.hint_word, word_info.pos, word_info.orientation)) do
		if crossword[pos.y][pos.x] == "?" then
			table.insert(state.hint_letters, { y = pos.y, x = pos.x })
			return
		end
	end

end

return core
