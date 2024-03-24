#!/usr/bin/env lua
-- Unlike most other Lua scripts in this repo, this script is meant to be run
-- on a PC with any Lua program, it doesn't rely on any alexgames APIs.
-- It reads the dictionary file as an sqlite3 database.
-- Note that this means you need to run `src/dictionary/build_word_list_w_freq.py`
-- before you can run this script.
--
-- This script only prints to stdout. It outputs Lua code that defines
-- some `crossword_letter` puzzles, based on a hardcoded list of words/letters.
--
-- To find useful sets of letters, run `gen_crossword_letters2.py`.


--local core = require("src/lua_scripts/games/crossword_letters/crossword_letters_core")
package.path = 'src/lua_scripts/?.lua'
local core = require("games/crossword_letters/crossword_letters_core")
local shuffle = require("libs/shuffle")



local function get_words(query)
	local rows = {}
	--print(string.format('Executing query %q', query))
	local handle = io.popen(string.format("sqlite3 out/word_dict.db %q", query))
	while true do
		local result = handle:read("*l")
		if not result then break end
		--print(string.format("read result: %q", result))
		table.insert(rows, result)
	end
	handle:close()
	return rows
end

core.set_get_words_func(get_words)

local params = {
	min_word_len  = 3,
	min_word_freq = 1e-6,
	crossword_height = 12,
	crossword_width  = 12,
}

local letter_sets = {
--[[
	{ "f", "a", "c", "e", "d", "t"},
	{ "s", "c", "i", "e", "c", "n"},
	{ "d", "e", "i", "s", "r", "e"},
	{ "d", "o", "v", "e", "e", "t"},
	{ "m", "a", "r", "v", "e", "l"},
	{ "r", "s", "t", "e", "n", "e"},
	{ "e", "s", "t", "l", "n", "a"},
--]]


--[[
	"plates",
	"easter",
	"raised",
	"paints",
	"traces",
	"master",
	"median",
	"hearts",
	"ladies",
	"scrape",
	"faster",
	"gamers",
	"stable",
	"browse",
	"sought",
--]]

--[[
	"soothe",
	"hustle",
	"hunted",
	"yogurt",
	"outcry",
	"fronts",
	"rights",
	"forget",
	"births",
	"snitch",
	"outing",
	"bylaws",
	"covent",
	"hernia",
	"beware",
	"amount",
	"warren",
	"renown",
	"relish",
	"shiver",
	"freaky",
	"retake",
	"budget",
	"submit",
	"sphere",
	"beaver",
	"thorns",
	"reaper",
	"barker",
	"banish",
	"tubing",
--]]

-- TODO uncomment this one, I found these words on 2023-11-27
-- they make up a lot of 5 letter words (20, I think).
-- but the lua generate puzzle program was taking forever.
-- I suspect that it would be a lot better if I just limit the
-- number of words used when there are so many 5 letter words. They might not
-- all fit.
-- Perhaps the Lua algorithm should simply return the best puzzle it can within a few minutes or
-- so many iterations, though.
--[[
	"pastel",
	"alerts",
	"earths",
	"lasted",
	"merits",
	"master",
	"metals",
	"metals",
	"traced",
	"easter",
	"insert",
	"stable",
	"arches",
	"stared",
	"pacers",
	"faster",
	"waters",
	"steals",
	"shared",
--]]

	"others",
	"morale",
	"father",
	"herald",
	"metric",
	"backer",
	"voters",
	--"halted",
	"chapel",
	"farmed",
	"skates",
	"purest",
	"flared",
	--"delays",
	"finder",
	"loaned",
	"braids",
	"course",
	"chalet",
	"scaled",
	"curate",
	"scored",
	"hordes",
	"corset",
	"angled",
	"fiesta",
	"malice",
	"tigers",
	"banker",
	"banter",
	"brides",
	"saturn",
	"unites",
	"slider",
	"ponies",
	"hassle",
	"washer",
	"graves",
	"ratios",
	"reigns",
	"daring",
	"grants",
	"spores",
	"hermit",
	"almost",
	"modest",
	"floats",
	"harmed",
	"biased",
	"greasy",

-- Added on 2023-12-23
	--"slogan",
	"makers",
	"permit",
	"blamed",
	"parcel",
	"dancer",
	"finder",
	"linear",
	"course",
	"dental",
	"rained",
	--"meters",
	"bailed",
	"wander",
	"soften",
	"lesion",
	"alpine",
}

local function string_to_char_list(str)
	local char_list = {}
	for i=1,#str do
		local c = str:sub(i,i)
		table.insert(char_list, c)
	end
	return char_list
end

local header = [[
local puzzles = {}

local core = require("games/crossword_letters/crossword_letters_core")

puzzles.puzzles = {
]]

print(header)

for _, letter_set in ipairs(letter_sets) do
	letter_set = string_to_char_list(letter_set)
	shuffle.shuffle(letter_set)
	local crossword = core.generate_crossword_from_letters(letter_set, params)

	local crossword_str = core.crossword_to_string(crossword)
	crossword_str = "--" .. crossword_str:gsub("\n", "\n--")
	print(crossword_str)
	local output = core.crossword_words_to_lua_code(letter_set, crossword)
	print(output)
end


local footer = [[
}

return puzzles
]]

print(footer)
