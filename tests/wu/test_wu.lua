wu = require('../src/lua_scripts/games/wu/wu_core')

local function to_string(arg)
	if arg == nil then return 'nil'
	else return string.format("%q", arg) end
end

local function simulate_game(game)
	state = wu.new_game(15)
	for idx, move in pairs(game) do
		local rc = wu.player_move(state, move[1], move[2], move[3])
		if rc ~= wu.SUCCESS then
			wu.print_board(state.board)
			error(string.format("at idx %d, rc is %q: %q", idx, rc, wu.err_code_to_str(rc)))
		end
	end

	wu.print_board(state.board)
	print(string.format("Winner is: %s", to_string(state.winner)))
	if state.winner ~= game[#game][1] then
		error("expected winner to be last move, but it isn't")
	end
end


games = {

{
	-- Alex is player 1, Sabrina is 2
	{1,7,9},
	{2,11,9},
	{1,8,9},
	{2,10,10},
	{1,8,8},
	{2,8,7},
	{1,7,8},
	{2,7,10},
	{1,9,10},
	{2,6,7},
	{1,9,8},
	{2,6,8},
	{1,9,9},
	{2,9,7},
	{1,6,9},
	{2,10,9},
	{1,5,9},
},

{
	-- Alex is player 1, Sabrina is 2
	{1,6,6},
	{2,6,10},
	{1,7,7},
	{2,7,9},
	{1,6,9},
	{2,8,8},
	{1,9,7},
	{2,8,10},
	{1,8,9},
	{2,6,8},
	{1,5,7},
	{2,8,7},
	{1,8,6},
	{2,7,10},
	{1,9,10},
	{2,7,8},
	{1,7,5},
	{2,4,8},
	{1,7,6},
	{2,5,8},
	-- Sabrina won here, but we didn't see a win popup.
--	{1,7,4},
--	{2,7,3},
--	{1,8,4},
--	{2,9,8},
},


{
	-- now Sabrina is 1, Alex is 2
	{1,6,8},
	{2,7,8},
	{1,5,8},
	{2,7,9},
	{1,5,9},
	{2,6,9},
	{1,4,10},
	{2,7,7},
	{1,5,10},
	{2,7,10},
	{1,3,11},
	{2,7,6},
},

{
	-- Sabrina is 1, Alex is 2
	{1,5,10},
	{2,11,5},
	{1,5,9},
	{2,10,6},
	{1,9,7},
	{2,11,6},
	{1,11,7},
	{2,10,5},
	{1,10,7},
	{2,12,7},
	{1,9,4},
	{2,12,5},
	{1,9,5},
	{2,9,6},
	{1,12,6},
	{2,13,6},
	{1,11,4},
	{2,13,8},
	{1,14,9},
	{2,13,5},
	{1,13,7},
	{2,14,5},
},

{
	{1,6,2},
	{2,1,9},
	{1,5,3},
	{2,2,9},
	{1,4,4},
	{2,3,9},
	{1,3,5},
	{2,4,9},
	{1,2,6},
},

{
	{1,8,9},
	{2,8,10},
	{1,9,9},
	{2,9,10},
	{1,5,6},
	{2,10,9},
	{1,4,7},
	{2,10,10},
	{1,6,5},
	{2,11,9},
	{1,7,4},
	{2,12,9},
	{1,3,8},
},


}

for _, game in pairs(games) do
	simulate_game(game)
end
