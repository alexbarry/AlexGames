local wu = {}

wu.EMPTY   = 0
-- Player1 is black (since black goes first)
wu.PLAYER1 = 1
-- Player2 is white (since white goes second)
wu.PLAYER2 = 2

wu.PIECES_IN_ROW_TO_WIN = 5

function wu.player_idx_to_colour_name(idx)
	local map =  {
		[wu.PLAYER1] = "black",
		[wu.PLAYER2] = "white",
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

function Point:mult(arg, factor)
	return Point:create{ y = (arg.y * factor), x = (arg.x * factor) }
end

local function in_range(game_state, y, x)
	return (1 <= x and x <= game_state.x_max and
	       1 <= y and y <= game_state.y_max)
end


-- In only one direction, you must check these and the negative of them at once
-- (if a user places a piece "a" in "xxaxx" then they still win, because they have 2 on the right
-- and 2 on the left)
local dirs = {
	{y = 0, x = 1}, -- -->
	{y = 1, x = 0}, -- ^
	{y = 1, x = 1}, -- \v
	{y =-1, x = 1}, -- /^
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

local val_to_char = {
	[wu.EMPTY]   = ' ',
	[wu.PLAYER1] = '1',
	[wu.PLAYER2] = '2'
}

function wu.print_board(board)
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

function wu.player_num_to_char(num)
	return val_to_char[num]
end

function wu.new_game(size)
	game_state = {
		player_turn = 1,
		y_max = size,
		x_max = size,
		board = make_2d_array(size, size, wu.EMPTY),
		last_move_y = nil,
		last_move_x = nil,
		winner = nil,
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

function wu.serialize_state(state)
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

	--print(string.format("Serialized state into %d bytes", #bytes))
	return table.concat(bytes, "")
end

function wu.deserialize_state(data)
	local state = {}
	local header_bytes = 5
	if #data < header_bytes then
		print(string.format("Bad serialized state received, less than 3 bytes: %d", #data))
		return nil
	end
	state.player_turn = string.byte(data:sub(1,1))
	state.y_max       = string.byte(data:sub(2,2))
	state.x_max       = string.byte(data:sub(3,3))
	state.last_move_y = string.byte(data:sub(4,4))
	state.last_move_x = string.byte(data:sub(5,5))
	local expected_len = header_bytes + state.y_max * state.x_max 
	if #data ~= expected_len then
		print(string.format("Bad serialized state, recvd %d bytes, expected %d bytes; y_max = %d, x_max = %d",
		                    #data, expected_len, state.y_max, state.x_max))
		return nil
	end
	state.board = make_2d_array(state.y_max, state.x_max, wu.EMPTY)
	local idx = header_bytes + 1
	for y=1,state.y_max do
		for x=1,state.x_max do
			state.board[y][x] = string.byte(data:sub(idx,idx))
			idx = idx + 1
		end
	end

	return state
end

wu.SUCCESS        =  0
wu.NOT_YOUR_TURN  = -1
wu.OUT_OF_RANGE   = -2
wu.OCCUPIED       = -3
wu.GAME_OVER      = -4

local code_to_str = {
	[wu.SUCCESS]        = "Success",
	[wu.NOT_YOUR_TURN]  = "Not your turn",
	[wu.OUT_OF_RANGE]   = "Position out of range",
	[wu.OCCUPIED]       = "Position occupied",
	[wu.GAME_OVER]      = "Game over",
}

function wu.err_code_to_str(code)
	return code_to_str[code]
end


function wu.player_move(game_state, player, y, x)
	print(string.format("Attempting to move player %s to y=%d, x=%d", player, y, x))

	if game_state.winner ~= nil then
		return wu.GAME_OVER
	end
	if player ~= game_state.player_turn then
		return wu.NOT_YOUR_TURN
	end

	if not (1 <= x and x <= game_state.x_max) or
	   not (1 <= y and y <= game_state.y_max) then
		return wu.OUT_OF_RANGE
	end

	if game_state.board[y][x] ~= wu.EMPTY then
		return wu.OCCUPIED
	end


	game_state.board[y][x] = player

	pt = Point:create{y=y, x=x}
	for _, dir in ipairs(dirs) do
		local in_a_row = 1
		for is_neg=0, 1 do
			for i=1,wu.PIECES_IN_ROW_TO_WIN-1 do
				local offset = Point:mult(dir,i)
				if is_neg == 1 then
					offset = Point:mult(offset, -1)
				end
				local pt2 = Point:add(pt, offset)
				if not in_range(game_state, pt2.y, pt2.x) then
					goto neg_dir
				end
				local dst = game_state.board[pt2.y][pt2.x]
				if dst ~= player then
					goto neg_dir
				end
				in_a_row = in_a_row + 1
			end
			::neg_dir::
		end

		if in_a_row >= wu.PIECES_IN_ROW_TO_WIN then
			game_state.winner = player
			print(string.format("Found winner at y=%d,x=%d", pt.y, pt.x))
			goto end_dir_loop
		end
	end
	::end_dir_loop::

	if game_state.player_turn == 1 then
		game_state.player_turn = 2
	elseif game_state.player_turn == 2 then
		game_state.player_turn = 1
	else
		error("invalid player turn")
	end
	game_state.last_move_y = pt.y
	game_state.last_move_x = pt.x
	return wu.SUCCESS
end


return wu
