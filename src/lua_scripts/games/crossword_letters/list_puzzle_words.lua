#!/usr/bin/env lua
package.path = 'src/lua_scripts/?.lua'

local puzzles = require("games/crossword_letters/crossword_letters_puzzles")

local words_list = {}
local words_count = {}

for _, puzzle in ipairs(puzzles.puzzles) do
	for _, word_pos_info in ipairs(puzzle.word_positions) do
		local word = word_pos_info.word
		if not words_count[word] then
			table.insert(words_list, word)
			words_count[word] = 1
		else
			words_count[word] = words_count[word] + 1
		end
	end
end

--[[
for word, count in pairs(words_count) do
	if count > 1 then
		print(string.format("Found word %-8s %d times", word, count))
	end
end
--]]


local bad_words_list = {
}

local bad_words_set = {}

for _, word in ipairs(bad_words_list) do
	bad_words_set[word] = true
end

for _, word in ipairs(words_list) do
	if bad_words_set[word] then
		goto next_word
	end
	print(string.format("%-6s", word))
	::next_word::
end
