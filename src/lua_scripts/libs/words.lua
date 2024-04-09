local words_lib = {}

local alex_dict  = require("alexgames.dict")

words_lib.FUN_WORD_FREQ = 3e-6

local ALPHABET = {}
for i=0,25 do
	table.insert(ALPHABET, string.char(string.byte('a') + i))
end


local function get_sql_word_pattern(len)
	local sql_word_pattern = ''
	for _=1,len do
		sql_word_pattern = sql_word_pattern .. '_'
	end
	return sql_word_pattern
end

function words_lib.is_ready()
	return alex_dict.is_ready()
end

function words_lib.get_random_word(language, freq, len)
	-- TODO avoid SQL injection on all of these queries
	--[[
	local rows = alex_dict.get_words(string.format("SELECT word FROM words WHERE freq > %e AND word LIKE '%s' ORDER BY RANDOM() LIMIT 1",
	                                         freq, get_sql_word_pattern(len)), language)
	local word = rows[1][1]
	--]]

	local word = alex_dict.get_random_word({min_length = len, max_length = len, min_freq = freq})
	return word
end

function words_lib.get_possib_word_count(language, freq, len)
	--local rows = alex_dict.get_words(string.format("SELECT COUNT(1) FROM words WHERE freq > %e AND word LIKE '%s'",
	--                                        freq, get_sql_word_pattern(len)), language)
	--return tonumber(rows[1][1])

	-- TODO
	return -1
end

function words_lib.is_valid_word(language, word)
	word = string.lower(word)
	--[[
	local rows = alex_dict.get_words(string.format("SELECT COUNT(1) FROM words WHERE word = '%s'", word), language)
	local count_str = rows[1][1]
	local count = tonumber(count_str)
	return count > 0
	--]]

	return alex_dict.is_valid_word(word)
end

function words_lib.get_words_made_from_letters(language, letters_arg, min_length, min_freq)
	print("get_words_made_from_letters")
	local letters = {}
	for _, letter_arg in ipairs(letters_arg) do
		table.insert(letters, string.lower(letter_arg))
	end
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
	for _, letter in pairs(ALPHABET) do
		local count = 1
		if letters_count[letter] ~= nil then
			count = letters_count[letter] + 1
		end
		print("letter: %s, count: %d", letter, count-1)
		query = query .. " AND word NOT LIKE '%"
		for _=1,count do
			query = query .. letter .. "%"
		end
		query = query .. "' \n"
	end
	query = query .. "ORDER BY LENGTH(word) DESC, freq DESC \n"
	query = query .. "LIMIT 20 \n"

	print(query)
	local rows = alex_dict.get_words(query, language)
	local words = {}
	print(string.format("found %d words fromt these letters", #words))
	for row_idx, row in ipairs(rows) do
		table.insert(words, row[1])
		print(string.format("%3d: %s", row_idx, row[1]))
	end
	return words
end

function words_lib.get_word_freq(language, word)
	local query = string.format("SELECT freq from words WHERE word = %q", word)
	local rows = alex_dict.get_words(query, language)
	if #rows == 0 then return nil end
	return tonumber(rows[1][1])
end

function words_lib.init(language)
	return alex_dict.init(language)
end



return words_lib
