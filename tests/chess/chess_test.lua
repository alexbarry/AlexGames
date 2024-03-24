#!/usr/bin/env lua

package.path = 'src/lua_scripts/?.lua'

local core = require("games/chess/chess_core")

local state = {
	player_turn = core.PLAYER_WHITE,
	board = {
		{ 8, 9, 10, 11,  0, 10, 9, 8 },
		{ 7, 7,  7,  7,  7,  0, 7, 7 },
		{ 0, 0,  0,  0,  0,  0, 0, 0 },
		{ 0, 0,  0,  0, 12,  0, 0, 5 },
		{ 0, 0,  0,  0,  0,  0, 0, 0 },
		{ 0, 0,  0,  0,  0,  0, 0, 0 },
		{ 1, 1,  1,  1,  0,  1, 1, 1 },
		{ 2, 3,  4,  0,  6,  4, 3, 2 },
	},
}

-- core.print_state(state)

--local white_in_check = core.in_check(state, core.PLAYER_WHITE)
--print(string.format("white_in_check: %s", white_in_check))

local black_in_check = core.in_check(state, core.PLAYER_BLACK)
print(string.format("black_in_check: %s", black_in_check))
