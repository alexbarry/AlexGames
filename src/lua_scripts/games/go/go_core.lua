local go = {}

-- todo rename to go.EMPTY?
local EMPTY   = 0
-- Player1 is black (since black goes first)
go.PLAYER1 = 1
-- Player2 is white (since white goes second)
go.PLAYER2 = 2

function go.player_idx_to_colour_name(idx)
	local map =  {
		[go.PLAYER1] = "black",
		[go.PLAYER2] = "white",
	}
	return map[idx]
end

local Point = {x = 0, y = 0}


function Point:str(self)
	return string.format("(%d,%d)",self.y, self.x)
end

function Point:create (o)
	o.parent = self
	return o
end

function Point:add(arg1, arg2)
	return Point:create{ y = (arg1.y + arg2.y), x = (arg1.x + arg2.x) }
end

local function in_range(game_state, y, x)
	return (1 <= x and x <= game_state.x_max and
	       1 <= y and y <= game_state.y_max)
end


local dirs = {
	Point:create{y = 0, x = 1},
	Point:create{y = 0, x =-1},
	Point:create{y = 1, x = 0},
	Point:create{y =-1, x = 0},
}

local function make_2d_array(y_len,x_len, val)
	local visited = {}
	for y=1,y_len do
		table.insert(visited, {})
		for x=1,x_len do
			table.insert(visited[y], val)
		end
	end
	return visited
end

local function copy_2d_array(ary)
	local to_return = {}
	for y=1, #ary do
		table.insert(to_return, {})
		for x=1, #ary[y] do
			table.insert(to_return[y], ary[y][x])
		end
	end
	return to_return
end

local function has_liberties(game_state, y, x)
	if game_state.board[y][x] == EMPTY then
		error(string.format("has_liberties called on empty point y=%d, x=%d", y, x))
	end

	local this_player = game_state.board[y][x]
	local visited = make_2d_array(game_state.y_max, game_state.x_max, false)
	local to_visit = { Point:create{y=y, x=x}}
	while #to_visit > 0 do
		local pt = table.remove(to_visit)
		if not in_range(game_state, pt.y, pt.x) then
			--continue
			goto next_iter
		elseif game_state.board[pt.y][pt.x] == EMPTY then
			return true
		elseif visited[pt.y][pt.x] then
			-- continue
			goto next_iter
		elseif  game_state.board[pt.y][pt.x] ~= this_player then
			--continue
			goto next_iter
		elseif game_state.board[pt.y][pt.x] == this_player then
			visited[pt.y][pt.x] = true
			for _, dir in ipairs(dirs) do
				local pt2 = Point:add(pt, dir)
				if in_range(game_state, pt2.y, pt2.x) then
					table.insert(to_visit, Point:add(pt, dir))
				end
			end
		end
		::next_iter::
	end
	return false
end

local function clear_piece_group(board, y, x)
	local this_player = board[y][x]
	local visited = make_2d_array(#board, #board[1], false)
	local to_visit = { Point:create{y=y, x=x}}
	while #to_visit > 0 do
		local pt = table.remove(to_visit)
		if not in_range(game_state, pt.y, pt.x) then
			--continue
		elseif board[pt.y][pt.x] == EMPTY then
			-- continue
		elseif visited[pt.y][pt.x] then
			-- continue
		elseif  board[pt.y][pt.x] ~= this_player then
			--continue
		elseif board[pt.y][pt.x] == this_player then
			board[pt.y][pt.x] = EMPTY
			visited[pt.y][pt.x] = true
			for _, dir in ipairs(dirs) do
				local pt2 = Point:add(pt, dir)
				if in_range(game_state, pt2.y, pt2.x) then
					table.insert(to_visit, pt2)
				end
			end
		end
	end
end

local val_to_char = {
	[0] = ' ',
	--[1] = 'x',
	--[2] = 'o',
	[1] = '\x1b[32mx\x1b[0m',
	[2] = '\x1b[33mo\x1b[0m',
}

function go.print_board(board)
	if #board[1] > 9 then
		io.write('  ')
		for x =1, #board[1] do
			local c = ' '
			if x >= 10 then c = string.format('%d', math.floor(x/10)) end
			io.write(string.format('%s ', c))
		end
		io.write('\n')
	end
	io.write('  ')
	for x =1, #board[1] do
		io.write(string.format('%d ', x%10))
	end
	io.write('\n +')
	for x =1, #board[1] do
		io.write('-+')
	end
	io.write('\n')
	for y = 1, #board do
		io.write(string.format('%s|', string.char(string.byte('A')+(y-1))))
		for x = 1, #board[y] do
			local c =  board[y][x]
			io.write( val_to_char[c] )
			io.write('|')
		end
		io.write('\n +')
		for x =1, #board[y] do
			io.write('-+')
		end
		io.write('\n')
	end
end

function go.player_num_to_char(num)
	return val_to_char[num]
end

function go.new_game(size)
	game_state = {
		player_turn = 1,
		y_max = size,
		x_max = size,
		board = make_2d_array(size, size, EMPTY),
		prev_board = nil,
		last_move_y = nil,
		last_move_x = nil,
	}
	return game_state
end

function if_nil_rt_zero(val)
	if val == nil then
		return 0
	else
		return val
	end
end

function go.serialize_state(state)
	if state == nil then return nil end
	local bytes = { }
	bytes[#bytes+1] = string.char(state.player_turn)
	bytes[#bytes+1] = string.char(state.y_max)
	bytes[#bytes+1] = string.char(state.x_max)
	bytes[#bytes+1] = string.char(if_nil_rt_zero(state.last_move_y))
	bytes[#bytes+1] = string.char(if_nil_rt_zero(state.last_move_x))
	for y=1,state.y_max do
		for x=1,state.x_max do
			bytes[#bytes+1] = string.char(state.board[y][x])
		end
	end

	if state.prev_board == nil then
		bytes[#bytes+1] = "x"
	else
		for y=1,state.y_max do
			for x=1,state.x_max do
				if state.prev_board ~= nil then
					bytes[#bytes+1] = string.char(state.prev_board[y][x])
				end
			end
		end
	end
	--print(string.format("Serialized state into %d bytes", #bytes))
	return table.concat(bytes, "")
end

function go.deserialize_state(data)
	local state = {}
	if #data < 3 then
		print(string.format("Bad serialized state received, less than 3 bytes: %d", #data))
		return nil
	end
	print(string.format("len data = %d, data[1] = %q, data[2] = %q, data[3] = %q", #data, data:sub(1,1), data:sub(2,2), data:sub(3,3)))
	state.player_turn = string.byte(data:sub(1,1))
	state.y_max       = string.byte(data:sub(2,2))
	state.x_max       = string.byte(data:sub(3,3))
	state.last_move_y = string.byte(data:sub(4,4))
	state.last_move_x = string.byte(data:sub(5,5))
	local prev_bytes = 5
	if #data ~= prev_bytes + state.y_max * state.x_max + 1 and
	   #data ~= prev_bytes + state.y_max * state.x_max * 2  then
		print(string.format("Bad serialized state, recvd %d bytes, y_max = %d, x_max = %d",
		                    #data, state.y_max, state.x_max))
		return nil
	end
	state.board = make_2d_array(state.y_max, state.x_max, EMPTY)
	local idx = prev_bytes + 1
	for y=1,state.y_max do
		for x=1,state.x_max do
			state.board[y][x] = string.byte(data:sub(idx,idx))
			idx = idx + 1
		end
	end

	if #data < prev_bytes + state.y_max * state.x_max * 2 then
		state.prev_board = nil
	else
		print(string.format("first byte is %q", data:sub(idx,idx)))
		state.prev_board = make_2d_array(state.y_max, state.x_max, EMPTY)
		for y=1,state.y_max do
			for x=1,state.x_max do
				state.prev_board[y][x] = string.byte(data:sub(idx,idx))
				idx = idx + 1
			end
		end
	end
	return state
end

go.SUCCESS        =  0
go.NOT_YOUR_TURN  = -1
go.OUT_OF_RANGE   = -2
go.OCCUPIED       = -3
go.SUICIDE        = -4
go.NOT_ALLOWED_KO = -5

local code_to_str = {
	[go.SUCCESS]        = "Success",
	[go.NOT_YOUR_TURN]  = "Not your turn",
	[go.OUT_OF_RANGE]   = "Position out of range",
	[go.OCCUPIED]       = "Position occupied",
	[go.SUICIDE]        = "Position would be suicidal",
	[go.NOT_ALLOWED_KO] = "Ko rule forbids game returning to this state after two turns",
}

function go.err_code_to_str(code)
	return code_to_str[code]
end


local function boards_eq(board1, board2)
	if board2 == nil and board1 ~= nil then
		return false
	end
	for y=1,#board1 do
		for x=1, #board1[1] do
			if board1[y][x] ~= board2[y][x] then
				return false
			end
		end
	end
	return true
end

local function next_turn(game_state)
	if game_state.player_turn == 1 then
		game_state.player_turn = 2
	elseif game_state.player_turn == 2 then
		game_state.player_turn = 1
	else
		error("invalid player turn")
	end
end

function go.player_move(game_state, player, y, x)
	if game_state == nil or player == nil or y == nil or x == nil then
		error(string.format("go.player_move called with nil args: %s %s %s %s", game_state, player, y, x))
	end
	print(string.format("Attempting to move player %d to y=%d, x=%d", player, y, x))
	local old_board = copy_2d_array(game_state.board)
	if player ~= game_state.player_turn then
		return go.NOT_YOUR_TURN
	end

	if not (1 <= x and x <= game_state.x_max) or
	   not (1 <= y and y <= game_state.y_max) then
		return go.OUT_OF_RANGE
	end

	if game_state.board[y][x] ~= EMPTY then
		return go.OCCUPIED
	end

	game_state.board[y][x] = player

	-- can't check for liberties here, because
	-- it's okay to move to a position where you have no liberties
	-- if you are taking a piece (which results in liberties)
	--if not has_liberties(game_state, y, x) then
	--	game_state.board[y][x] = EMPTY
	--	return go.SUICIDE
	--end

	pt = Point:create{y=y, x=x}
	for _, dir in ipairs(dirs) do
		local pt2 = Point:add(pt, dir)
		if not in_range(game_state, pt2.y, pt2.x) then
			goto next_dir
		end
		local dst = game_state.board[pt2.y][pt2.x]
		if dst == EMPTY or dst == player then
			goto next_dir
		end

		if not has_liberties(game_state, pt2.y, pt2.x) then
			clear_piece_group(game_state.board, pt2.y, pt2.x)
		end
		::next_dir::
	end

	-- is it just the previous state?
	if boards_eq(game_state.board, game_state.prev_board) then
		game_state.board = old_board
		return go.NOT_ALLOWED_KO
	end

	if not has_liberties(game_state, y, x) then
		game_state.board[y][x] = EMPTY
		return go.SUICIDE
	end
	
	next_turn(game_state)

	game_state.prev_board = old_board
	game_state.last_move_y = pt.y
	game_state.last_move_x = pt.x
	return go.SUCCESS
end

function go.player_pass(game_state, player)
	if player ~= game_state.player_turn then
		return go.NOT_YOUR_TURN
	end

	next_turn(game_state)
	return go.SUCCESS
end

return go
