go = require("src/lua_scripts/games/go/go")

-- A game that Sabrina and I played on 2021-05-11
-- my understanding is that I (1) control 46 territory and she (2) controls 35.
-- It seems non trivial to determine this though.
-- Maybe in our game it is fairly simple, we only have a few
-- groups of points in each other's territory, and all of those ones
-- have limited liberties that could probably be rulled out programatically.
board = {
	{1, 1, 1, 1, 1, 1, 0, 1, 0},
	{2, 1, 2, 1, 2, 1, 2, 1, 0},
	{2, 2, 2, 2, 2, 1, 1, 1, 0},
	{2, 1, 0, 2, 2, 2, 1, 0, 1},
	{1, 1, 1, 2, 1, 1, 1, 1, 1},
	{2, 1, 0, 2, 1, 0, 1, 0, 1},
	{2, 2, 2, 2, 1, 0, 1, 0, 0},
	{0, 2, 0, 2, 2, 1, 1, 0, 2},
	{2, 0, 2, 2, 1, 1, 1, 1, 1},
}

go.print_board(board)
