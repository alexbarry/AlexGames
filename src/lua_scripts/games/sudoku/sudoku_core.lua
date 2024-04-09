local core = {}

local alexgames = require("alexgames")
local shuffle = require("libs/shuffle")

core.GAME_SIZE = 9
core.BOX_SIZE = math.floor(math.sqrt(core.GAME_SIZE))

if core.BOX_SIZE*core.BOX_SIZE ~= core.GAME_SIZE then
	error("Invalid box size: is not sqrt of game size")
end

local GROUP_TYPE_ROW = 1
local GROUP_TYPE_COL = 2
local GROUP_TYPE_BOX = 3

local GROUP_TYPES = {
	GROUP_TYPE_ROW,
	GROUP_TYPE_COL,
	GROUP_TYPE_BOX,
}

local function print_board(board)
	for y=1,core.GAME_SIZE do
		if y%3 == 1 then
			print('+---+---+---+')
		end
		local s = '|'
		for x=1,core.GAME_SIZE do
			if board[y][x].val ~= 0 then
				s = s .. string.format("%s", board[y][x].val)
			else
				s = s .. " "
			end
			if x%3 == 0 then
				s = s .. '|'
			end
		end
		print(s)
	end
end


local function pt_eq(pt1, pt2)
	return pt1.y == pt2.y and pt1.x == pt2.x
end


-- Return y,x coords where idx is value in each cell
--     x=1, 2, 3
--   y=1[1][2][3],
--     2[4][5][6],
--     3[7][8][9] ]
local function get_box_pt(idx)
	return { y = math.floor((idx-1)/core.BOX_SIZE)+1,
	         x = math.floor((idx-1)%core.BOX_SIZE)+1 }
end

assert(pt_eq(get_box_pt(1), {y=1,x=1}))
assert(pt_eq(get_box_pt(2), {y=1,x=2}))
assert(pt_eq(get_box_pt(3), {y=1,x=3}))
assert(pt_eq(get_box_pt(4), {y=2,x=1}))
assert(pt_eq(get_box_pt(5), {y=2,x=2}))
assert(pt_eq(get_box_pt(6), {y=2,x=3}))
assert(pt_eq(get_box_pt(7), {y=3,x=1}))
assert(pt_eq(get_box_pt(8), {y=3,x=2}))
assert(pt_eq(get_box_pt(9), {y=3,x=3}))

-- Returns first cell in each box, e.g.
-- y,x coords of each cell below, where box_idx is value in cell
--    x=1, 2, 3,  4, 5, 6,  7, 8, 9
--  y=1[1][ ][ ]|[2][ ][ ]|[3][ ][ ]
--    2[ ][ ][ ]|[ ][ ][ ]|[ ][ ][ ]
--    3[ ][ ][ ]|[ ][ ][ ]|[ ][ ][ ]
--     ---------+---------+---------
--    4[4][ ][ ]|[5][ ][ ]|[6][ ][ ]
--    5[ ][ ][ ]|[ ][ ][ ]|[ ][ ][ ]
--    6[ ][ ][ ]|[ ][ ][ ]|[ ][ ][ ]
--     ---------+---------+---------
--    7[7][ ][ ]|[8][ ][ ]|[9][ ][ ]
--    8[ ][ ][ ]|[ ][ ][ ]|[ ][ ][ ]
--    9[ ][ ][ ]|[ ][ ][ ]|[ ][ ][ ]
--
local function get_box_start_pt(box_idx)
	local pt = get_box_pt(box_idx)
	pt.y = (pt.y-1) * core.BOX_SIZE + 1
	pt.x = (pt.x-1) * core.BOX_SIZE + 1
	return pt
end

assert(pt_eq(get_box_start_pt(1), {y=1, x=1}))
assert(pt_eq(get_box_start_pt(2), {y=1, x=4}))
assert(pt_eq(get_box_start_pt(3), {y=1, x=7}))
assert(pt_eq(get_box_start_pt(4), {y=4, x=1}))
assert(pt_eq(get_box_start_pt(5), {y=4, x=4}))
assert(pt_eq(get_box_start_pt(6), {y=4, x=7}))
assert(pt_eq(get_box_start_pt(7), {y=7, x=1}))
assert(pt_eq(get_box_start_pt(8), {y=7, x=4}))
assert(pt_eq(get_box_start_pt(9), {y=7, x=7}))

local function pt_ary_eq(pt_ary1, pt_ary2)
	if #pt_ary1 ~= #pt_ary2 then
		return false
	end

	for i, _ in ipairs(pt_ary1) do
		if not pt_eq(pt_ary1[i], pt_ary2[i]) then
			return false
		end
	end
	return true
end

local function pt_add(pt1, pt2)
	return { y = pt1.y + pt2.y,
	         x = pt1.x + pt2.x }
end

assert(pt_eq(get_box_start_pt(1), {y=1,x=1}))
assert(pt_eq(get_box_start_pt(2), {y=1,x=4}))
assert(pt_eq(get_box_start_pt(3), {y=1,x=7}))
assert(pt_eq(get_box_start_pt(4), {y=4,x=1}))
assert(pt_eq(get_box_start_pt(5), {y=4,x=4}))
assert(pt_eq(get_box_start_pt(6), {y=4,x=7}))
assert(pt_eq(get_box_start_pt(7), {y=7,x=1}))
assert(pt_eq(get_box_start_pt(8), {y=7,x=4}))
assert(pt_eq(get_box_start_pt(9), {y=7,x=7}))

local function cells_in_group(group_type, idx)
	local cells = {}
	if group_type == GROUP_TYPE_ROW then
		local y = idx
		for x=1,core.GAME_SIZE do
			table.insert(cells, { y = y, x = x })
		end
	elseif group_type == GROUP_TYPE_COL then
		local x = idx
		for y=1,core.GAME_SIZE do
			table.insert(cells, { y = y, x = x })
		end
	elseif group_type == GROUP_TYPE_BOX then
		local box_idx = idx
		for cell_idx=1,core.GAME_SIZE do
			local pt = pt_add(get_box_start_pt(box_idx), get_box_pt(cell_idx))
			pt = pt_add(pt, { y = -1, x = -1 })
			table.insert(cells, pt)
		end
	else
		error(string.format("unexpected group_type: %s", group_type))
	end
	return cells
end


assert(pt_ary_eq(cells_in_group(GROUP_TYPE_BOX, 1), {
	{ y = 1, x = 1},
	{ y = 1, x = 2},
	{ y = 1, x = 3},
	{ y = 2, x = 1},
	{ y = 2, x = 2},
	{ y = 2, x = 3},
	{ y = 3, x = 1},
	{ y = 3, x = 2},
	{ y = 3, x = 3},
}))

local function get_pt_group_idx(group_type, y, x)
	if group_type == GROUP_TYPE_ROW then
		return y
	elseif group_type == GROUP_TYPE_COL then
		return x
	elseif group_type == GROUP_TYPE_BOX then
		local box_idx = math.floor( (y-1)/core.BOX_SIZE)*core.BOX_SIZE + math.floor( (x-1)/core.BOX_SIZE) + 1
		return box_idx
	else
		error(string.format("unexpected group_type: %s", group_type))
	end
end


local function is_board_valid(state)
	for _, group_type in ipairs(GROUP_TYPES) do
		for group_idx=1,core.GAME_SIZE do
			local nums_seen = {}
			for _, pt in ipairs(cells_in_group(group_type, group_idx)) do
				local val = state.board[pt.y][pt.x].val
				if val ~= 0 then
					if nums_seen[val] then
						return false
					end
					nums_seen[val] = true
				end
			end
		end
	end
	return true
end

local debug = false

local function get_possible_values(board, y, x)
	local vals = {}
	for i=1,core.GAME_SIZE do
		vals[i] = true
	end

	if debug then print_board(board) end
	if debug then print(string.format('--- checking y=%d,x=%d', y, x)) end
	for _, group_type in ipairs(GROUP_TYPES) do
		local group_idx = get_pt_group_idx(group_type, y, x)
		for _, pt in ipairs(cells_in_group(group_type, group_idx)) do
			local val = board[pt.y][pt.x].val
			if val ~= 0 then
				if debug then print(string.format("found val %d in group_type=%d, group_idx=%d", val, group_type, group_idx)) end
				vals[val] = false
			end
		end
	end

	local val_list = {}
	for val, is_valid in ipairs(vals) do
		if is_valid then
			table.insert(val_list, val)
		end
	end
	return val_list
end

local function get_cell_with_min_possib_vals(board)
	local cell = nil
	local min_possib_vals = nil
	for y=1,core.GAME_SIZE do
		for x=1,core.GAME_SIZE do
			if board[y][x].val ~= 0 then
				goto next_cell
			end
			local possib_vals = get_possible_values(board, y, x)
			if min_possib_vals == nil or #possib_vals < min_possib_vals then
				min_possib_vals = #possib_vals
				cell = { y = y, x = x }
			end
			if min_possib_vals == 0 then
				return cell
			end
			::next_cell::
		end
	end
	return cell
end

local function copy_board(board)
	local new_board = {}
	for y, row in ipairs(board) do
		new_board[y] = {}
		for x, cell in ipairs(row) do
			new_board[y][x] = {}
			new_board[y][x].val = cell.val
		end
	end
	return new_board
end

local function is_board_complete(board)
	for y=1,core.GAME_SIZE do
		for x=1,core.GAME_SIZE do
			if board[y][x].val == 0 then
				return false
			end
		end
	end
	return true
end

local function get_num_possib_solutions(board, max_count)
	--print_board(board)
	board = copy_board(board)
	local solution_count = 0
	local cell, possib_vals
	while true do
		if is_board_complete(board) then
			return 1
		end

		cell = get_cell_with_min_possib_vals(board)
		if cell == nil then
			error("get_cell_with_min_possib_vals is nil?")
			return 0
		end

		possib_vals = get_possible_values(board, cell.y, cell.x)
		--print(string.format("found cell{y=%d,x=%d} has %d possib_vals", cell.y, cell.x, #possib_vals))
		if #possib_vals == 0 then
			if is_board_complete(board) then
				return 1
			else
				return 0
			end
		elseif #possib_vals == 1 then
			--print(string.format("filling in easy val %d to {y=%d,x=%d}", possib_vals[1], cell.y, cell.x))
			board[cell.y][cell.x].val = possib_vals[1]
		else
			break
		end
	end
	for _, possib_val in ipairs(possib_vals) do
		local board2 = copy_board(board)
		--print(string.format("guessing val=%d at {y=%d,x=%d}", possib_val, cell.y, cell.x))
		board2[cell.y][cell.x].val = possib_val
		if solution_count >= max_count then
			return solution_count
		end
		solution_count = solution_count + get_num_possib_solutions(board2, max_count)
	end
	return solution_count
end

local function solve_board(board)
	board = copy_board(board)
	while not is_board_complete(board) do
		local cell = get_cell_with_min_possib_vals(board)
		local possib_vals = get_possible_values(board, cell.y, cell.x)
		--print(string.format("found cell {y=%d,x=%d} has %d possib vals", cell.y, cell.x, #possib_vals))
		if #possib_vals == 0 then
			return board
		end

		if #possib_vals == 1 then
			--print(string.format("filling in val %d to {y=%d,x=%d}", possib_vals[1], cell.y, cell.x))
			board[cell.y][cell.x].val = possib_vals[1]
		else
			shuffle.shuffle(possib_vals)
			for _, possib_val in ipairs(possib_vals) do
				--print("making guess val=%d, y=%d,x=%d", possib_val, cell.y, cell.x)
				local board2 = copy_board(board)
				board2[cell.y][cell.x].val = possib_val
				board2 = solve_board(board2)
				if is_board_complete(board2) then
					return board2
				end
			end
			-- if we hit this, the board wasn't solvable
			return board
		end
	end
	return board
end

local function get_random_filled_in_cell(board)
	local cells = {}
	for y=1,core.GAME_SIZE do
		for x=1,core.GAME_SIZE do
			if board[y][x].val ~= 0 then
				table.insert(cells, { y=y, x=x} )
			end
		end
	end
	return cells[math.random(#cells)]
end

function core.new_game()
	local state = {
		board = {},
	}

	for y=1,core.GAME_SIZE do
		state.board[y] = {}
		for x=1,core.GAME_SIZE do
			state.board[y][x] = {}
			state.board[y][x].val = 0
		end
	end

	local start_time_ms = alexgames.get_time_ms()
	state.board = solve_board(state.board)
	local i = 0
	while i < 400 do
		i = i + 1
		local orig_board = copy_board(state.board)
		local cell = get_random_filled_in_cell(state.board)
		state.board[cell.y][cell.x].val = 0
		if get_num_possib_solutions(state.board, 2) > 1 then
			state.board = orig_board
			break
		elseif get_num_possib_solutions(state.board, 2) == 1 then
			-- pass
		else
			error("more than 1 solution?")
		end
	end
	for y=1,core.GAME_SIZE do
		for x=1,core.GAME_SIZE do
			state.board[y][x].is_init_val = (state.board[y][x].val ~= 0)
		end
	end
	::done_generating_game::
	local end_time_ms = alexgames.get_time_ms()


	alexgames.set_status_msg(string.format("Generated a game in %.3f seconds", (end_time_ms - start_time_ms)/1000))
	--local soln_count = get_num_possib_solutions(state.board, 5)
	--print("found " .. soln_count .. " possible solutions (max 5)")
	
	debug = true
	return state
end

function core.user_enter(state, y, x, num_choice)
	if state.board[y][x].is_init_val then
		return -- TODO error code?
	end

	state.board[y][x].val = num_choice
end

return core
