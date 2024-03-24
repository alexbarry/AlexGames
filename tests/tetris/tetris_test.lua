#!/usr/bin/env lua5.3

package.path = 'src/lua_scripts/?.lua'

local core  = require("games/tetris/tetris_core")

local function assert_eq(actual, expected)
	if actual ~= expected then
		error(string.format("actual=%s, expected=%s", actual, expected), 2)
	end
end

local function split_str(str, sep)
	local strs = {}
	for token in string.gmatch(str, sep) do
		table.insert(strs, token)
	end
	return strs
end

local function assert_grid_eq(state, expected_grid_str)
	local expected_grid_lines = split_str(expected_grid_str, '[^%s]+')
	if expected_grid_lines[#expected_grid_lines] == '\n' then
		table.remove(expected_grid_lines)
	end
	local grid = core.get_grid(state)
	for y=core.ROW_COUNT,1,-1 do
		local expected_row_idx = #expected_grid_lines - (core.ROW_COUNT - y)
		if expected_row_idx < 1 then
			break
		end
		local expected_line_str = expected_grid_lines[expected_row_idx]
		for x=1,core.COL_COUNT do
			local expected_cell = ( expected_line_str:sub(x,x) ~= '.' )
			if expected_cell ~= (grid[y][x] ~= 0) then
				print(string.format('Cell y=%d, x=%d did not match', y, x))
				print('Actual: ')
				core.print_state(state)
				print('\nExpected: ')
				print(expected_grid_str)
				error(string.format('Cell y=%d, x=%d did not match', y, x))
			end
		end
	end
end

local blocks = {
	core.PIECE_SQUARE,
	core.PIECE_L,
	core.PIECE_T,
	core.PIECE_T,
	core.PIECE_L2,
	core.PIECE_LINE,
}

print('##########################')
print('##### Beginning tetris test')
print('##########################')

local state = core.new_state(blocks)

-- square
assert_eq(state.current_piece, core.PIECE_SQUARE)
core.move_x(state, 2)
core.move_bottom(state)
assert_grid_eq(state, 
'..........\n' ..
'........##\n' ..
'........##\n' ..
''
)

-- L
assert_eq(state.current_piece, core.PIECE_L)
core.move_x(state, -3)
core.rotate_piece(state, 1)
core.move_bottom(state)
assert_grid_eq(state, 
'..........\n' ..
'...#....##\n' ..
'.###....##\n' ..
''
)

-- T
assert_eq(state.current_piece, core.PIECE_T)
core.move_x(state, -1)
core.rotate_piece(state, 1)
core.move_bottom(state)
assert_grid_eq(state, 
'..........\n' ..
'...#.o..##\n' ..
'.###ooo.##\n' ..
''
)

-- T
assert_eq(state.current_piece, core.PIECE_T)
core.move_x(state, 1)
core.rotate_piece(state, -1)
core.rotate_piece(state, -1)
core.move_bottom(state)
assert_grid_eq(state, 
'.......o..\n' ..
'...#.#oo##\n' ..
'.######o##\n' ..
''
)

-- L
assert_eq(state.current_piece, core.PIECE_L2)
for _=1,3 do
core.move_down(state)
end
core.rotate_piece(state, 1)
core.rotate_piece(state, 1)
core.move_x(state, 1)
--core.rotate_piece(state, -1)
core.move_bottom(state)
assert_grid_eq(state, 
'........oo\n' ..
'........o.\n' ..
'.......#o.\n' ..
'...#.#####\n' ..
'.#########\n' ..
''
)


--assert_eq(state.current_piece, core.PIECE_L2)
core.print_state(state)

