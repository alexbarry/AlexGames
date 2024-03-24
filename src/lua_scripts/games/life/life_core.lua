local life = {}

local dirs = {
	{ y =  0, x =  1},
	{ y =  0, x = -1},
	{ y =  1, x =  0},
	{ y = -1, x =  0},


	{ y =  1, x = -1},
	{ y =  1, x =  1},
	{ y = -1, x = -1},
	{ y = -1, x =  1},
}

function add_pts(arg1, arg2)
	return { y = (arg1.y + arg2.y), x = (arg1.x + arg2.x) }
end


function life.new_board(y_size, x_size)
	local board = {}
	for y=1,y_size do
		board[#board+1] = {}
		for x=1,x_size do
			board[y][#board[y]+1] = 0
		end
	end
	return board
end

function life.new_state(y_size, x_size)
	local state = {
		boards = {
			life.new_board(y_size, x_size),
			life.new_board(y_size, x_size),
		},
		board_idx = 1,
	}
	return state
end

function life.get_active_board(state)
	return state.boards[state.board_idx]
end

function in_range(board, pt)
	return (1 <= pt.x and pt.x <= #board[1] and
	        1 <= pt.y and pt.y <= #board)
end

function count_neighbours(board, pos)
	local count = 0
	for _, dir in ipairs(dirs) do
		local pt2 = add_pts(pos, dir)
		if not in_range(board, pt2) then
			goto next_dir
		end

		if board[pt2.y][pt2.x] ~= 0 then
			count = count + 1
		end

		::next_dir::
	end

	return count
end

function life.update_board(in_board, out_board)
	for y=1,#in_board do
		for x=1,#in_board[y] do
			local neighbour_count = count_neighbours(in_board, {y=y, x=x})
			--if neighbour_count > 0 then
			--	print(string.format("{y=%2d, x=%2d} found neighbour count %d", y,x,neighbour_count))
			--end
			if in_board[y][x] ~= 0 and 2 <= neighbour_count and neighbour_count <= 3 then
				out_board[y][x] = 1
			elseif in_board[y][x] == 0 and neighbour_count == 3 then
				out_board[y][x] = 1
			else
				out_board[y][x] = 0
			end
		end
	end
end

function life.update_state(state)
	local src_board_idx = state.board_idx
	local dst_board_idx
	if src_board_idx == 1 then
		dst_board_idx = 2
	else
		dst_board_idx = 1
	end

	life.update_board(state.boards[src_board_idx], state.boards[dst_board_idx])

	state.board_idx = dst_board_idx
end

function life.toggle_cell_board(board, y, x)
	if not in_range(board, {y=y, x=x}) then
		return
	end
	
	local val = board[y][x]
	if val == 0 then
		val = 1
	else
		val = 0
	end

	board[y][x] = val
end

function life.toggle_cell_state(state, cell_pos_pt)
	local board = life.get_active_board(state)
	life.toggle_cell_board(board, cell_pos_pt.y, cell_pos_pt.x)
end

function life.clear_board(state)
	local board = life.get_active_board(state)
	for y=1,#board do
		for x=1,#board[y] do
			board[y][x] = 0
		end
	end
end

function bool_to_int(b)
	if b then return 1
	else return 0 end
end

function life.random_board(state)
	local board = life.get_active_board(state)
	for y=1,#board do
		for x=1,#board[y] do
			board[y][x] = bool_to_int(math.random(0,10) <= 3)
		end
	end
end

return life
