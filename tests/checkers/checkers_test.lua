
package.path = 'src/lua_scripts/?.lua'
local core = require("games/checkers/checkers_core")

function test_get_moves_while_selected()
	local state = {
	    player_turn = 1,
	    selected_y = 6,
	    selected_x = 8,
	    must_jump_selected = true,
	    board = {
	        {1,0,1,0,0,0,0,0 },
	        {0,0,0,0,0,0,0,0 },
	        {0,0,1,0,1,0,0,0 },
	        {0,0,0,0,0,0,0,0 },
	        {0,0,0,0,0,0,2,0 },
	        {0,0,0,0,0,0,0,3 },
	        {0,0,1,0,0,0,0,0 },
	        {0,3,0,0,0,0,0,0 },
	    },
	}
	
	
	local moves = core.get_valid_moves(state)
	assert(#moves == 1)
	local move = moves[1]
	assert(move.src.y == 6)
	assert(move.src.x == 8)
	assert(move.dst.y == 4)
	assert(move.dst.x == 6)

	print("Test test_get_moves_while_selected passed!")
end


local tests = {
	test_get_moves_while_selected,
}

for test_idx, test in ipairs(tests) do
	test()
end
