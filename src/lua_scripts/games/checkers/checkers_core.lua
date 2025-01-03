core = {}

core.BOARD_HEIGHT = 8
core.BOARD_WIDTH  = 8

core.ROWS_OF_PIECES = 3

core.EMPTY   = 0
core.PLAYER1        = 1
core.PLAYER2        = 2
core.PLAYER1_KING   = 3
core.PLAYER2_KING   = 4

core.RC_SUCCESS       = 0
core.RC_NOT_YOUR_TURN = -1
-- Can not move to this position
core.RC_INVALID_MOVE  = -2
core.RC_OCCUPIED      = -3
core.RC_NOT_YOUR_PIECE = -4
core.RC_NO_PIECE_TO_SELECT = -5
core.RC_MUST_JUMP_SELECTED = -6
core.RC_MUST_JUMP = -7
-- core.RC_UNSELECTED = -6

function core.player_id_to_name(id)
	if id == nil then return nil
	elseif id == core.PLAYER1 then return "red"
	elseif id == core.PLAYER2 then return "black"
	else
		error(string.format("Unexpected player id %q", id))
	end
end

local dirs = {
	{ y = 1, x = 1},
	{ y =-1, x = 1},
	{ y =-1, x =-1},
	{ y = 1, x =-1},
}

function core.rc_to_string(rc)
	local rc_to_str_map = {
		[core.RC_SUCCESS]            = "Success",
		[core.RC_NOT_YOUR_TURN]      = "Not your turn",
		[core.RC_INVALID_MOVE]       = "Can not move to this position",
		[core.RC_OCCUPIED]           = "This position is occupied",
		[core.RC_NOT_YOUR_PIECE]     = "This piece is not controlled by you",
		[core.RC_NO_PIECE_TO_SELECT] = "Must select a piece to move",
		[core.RC_MUST_JUMP_SELECTED] = "Must jump with currently selected piece",
		[core.RC_MUST_JUMP]          = "You have at least one jump available, so you must jump",
	}
	return rc_to_str_map[rc]
end

local function new_2d_array(height, width, default_val)
	local ary = {}
	for y=1,height do
		ary[y] = {}
		for x=1,width do
			ary[y][x] = default_val
		end
	end
	return ary
end

function core.default_game_settings()
	return {
		must_jump_when_able = true,
	}
end

function core.new_state(game_settings)
	if game_settings == nil then
		game_settings = core.default_game_settings()
	end
	local board = new_2d_array(core.BOARD_HEIGHT, core.BOARD_WIDTH, 0)
	for y=1,core.ROWS_OF_PIECES do
		local x_start
		if y % 2 == 1 then
			x_start = 1
		else
			x_start = 2
		end
		for x=x_start,8,2 do
			board[y][x] = core.PLAYER1
		end
	end

	for y=core.BOARD_HEIGHT-core.ROWS_OF_PIECES+1,core.BOARD_HEIGHT do
		local x_start
		if y % 2 == 1 then
			x_start = 1
		else
			x_start = 2
		end
		for x=x_start,8,2 do
			board[y][x] = core.PLAYER2
		end
	end

	return {
		game_settings = game_settings,
		player_turn = core.PLAYER1,
		board = board,
		selected_y = nil,
		selected_x = nil,
		-- for the case where you are partway through a double jump
		must_jump_selected = false,
	}
end

function core.print_state(state)
	io.write("state = {\n")
	io.write(string.format("    player_turn = %s\n", state.player_turn))
	io.write(string.format("    selected_y = %s\n", state.selected_y))
	io.write(string.format("    selected_x = %s\n", state.selected_x))
	io.write(string.format("    must_jump_selected = %s\n", state.must_jump_selected))
	io.write(string.format("    board = {\n", state.selected_x))
	for _,row in ipairs(state.board) do
		io.write("        {")
		for _,cell in ipairs(row) do
			io.write(string.format("%d ", cell))
		end
		io.write("}\n")
	end
	io.write("    }\n")
	io.write("}\n")
end

local val_to_char_map = {
	[core.EMPTY]   = ' ',
	[core.PLAYER1] = 'x',
	[core.PLAYER1] = 'o',
}

function core.print_board(board)
	io.write("+")
	for x=1,#board do
		io.write(string.format("-+"))
	end
	io.write("\n")
	for y=1,#board do
		io.write("|")
		for x=1,#board do
			io.write(string.format("%s|", val_to_char_map[board[y][x]]))
		end
		io.write("\n")
		io.write("+")
		for x=1,#board do
			io.write(string.format("-+"))
		end
		io.write("\n")
	end
end

local function in_range(y,x)
	return (1 <= y and y <= core.BOARD_HEIGHT and
	        1 <= x and x <= core.BOARD_WIDTH)
end

local function is_player(state, y, x, player)
	local piece = state.board[y][x]
	if player == core.PLAYER1 then
		return piece == core.PLAYER1 or piece == core.PLAYER1_KING
	elseif player == core.PLAYER2 then
		return piece == core.PLAYER2 or piece == core.PLAYER2_KING
	else
		error(string.format("Unexpected player %s", player))
		return false
	end
end

function core.piece_to_player(piece)
	if piece == core.EMPTY then
		return core.EMPTY
	elseif piece == core.PLAYER1 or piece == core.PLAYER1_KING then
		return core.PLAYER1
	elseif piece == core.PLAYER2 or piece == core.PLAYER2_KING then
		return core.PLAYER2
	else
		error(string.format("Unexpected piece %s", piece))
		return nil
	end
end

function core.piece_is_king(piece)
	return piece == core.PLAYER1_KING or piece == core.PLAYER2_KING
end

local function other_player(player)
	if player == core.PLAYER1 then return core.PLAYER2
	elseif player == core.PLAYER2 then return core.PLAYER1
	else error(string.format("Unexpected player %s", player)) end
end

local function sign(val)
	if val > 0 then return 1
	elseif val == 0 then return 0
	else return -1 end
end

local function king(player)
	if player == core.PLAYER1 then return core.PLAYER1_KING
	elseif player == core.PLAYER2 then return core.PLAYER2_KING
	else error(string.format("Unexpected player %s", player)) end
end

-- TODO rename to "valid destination to highlight" or something...
-- this only determines if a destination should be highlighted when a piece is selected,
-- it doesn't check if the player can actually perform the move (e.g. in case they must jump)
function core.valid_move(state, src_y, src_x, dst_y, dst_x, jumped_pieces)
	local dy = dst_y - src_y
	local dx = dst_x - src_x

	if not in_range(dst_y, dst_x) then
		return false
	end
	if state.board[dst_y][dst_x] ~= 0 then
		return false
	end


	local piece = state.board[src_y][src_x]
	local player = core.piece_to_player(piece)

	--print(string.format("valid_move, player = %s, dy=%s, dx=%s", player, dy, dx))

	if (core.piece_is_king(piece) and math.abs(dy) == 1) or 
	   (player == core.PLAYER1 and dy ==  1) or
	   (player == core.PLAYER2 and dy == -1) then
		--print("hit dy == 1 case")
		return dx == 1 or dx == -1
	elseif (core.piece_is_king(piece) and math.abs(dy) == 2) or
	       (player == core.PLAYER1 and dy ==  2) or
	       (player == core.PLAYER2 and dy == -2) then
		--print("hit dy == 2 case")
		if math.abs(dx) ~= 2 then
			--print("dx ~= 2")
			return false
		end
		local jumped_y = src_y + sign(dy)
		local jumped_x = src_x + sign(dx)
		if is_player(state, jumped_y, jumped_x, other_player(player)) then
			--print("should be jumped")
			if jumped_pieces ~= nil then
				table.insert(jumped_pieces, {y= jumped_y, x= jumped_x })
			end
			return core.RC_SUCCESS
		else
			--print("jumped player is not other player")
			return false
		end
	else
		--print("hit other case")
		return false
	end

end

function core.get_valid_moves(state)
	--print("[ai] checkers get_valid_moves called")
	local move_dists = nil
	if jumps_available_for_player(state, state.player_turn) then
		move_dists = { 2 }
	else
		move_dists = { 1 }
	end

	local dirs = {
		{ dy = -1, dx = -1, },
		{ dy = -1, dx =  1, },
		{ dy =  1, dx = -1, },
		{ dy =  1, dx =  1, },
	}
	local moves = {}
	for y=1,core.BOARD_HEIGHT do
		for x=1,core.BOARD_WIDTH do
			if state.board[y][x] ~= state.player_turn then
				goto next_cell
			end

			local src = {
				y = y,
				x = x,
			}

			for _,move_dist in ipairs(move_dists) do
				for _, dir in ipairs(dirs) do
					local dst = {
						y = src.y + dir.dy * move_dist,
						x = src.x + dir.dx * move_dist,
					}
					if core.valid_move(state, src.y, src.x, dst.y, dst.x, {}) then
						table.insert(moves, { src = src, dst = dst, })
					end
					
				end
			end
			
			::next_cell::
		end
	end

	return moves
end

local function move_piece(state, y, x)
	local piece = state.board[state.selected_y][state.selected_x]
	state.board[state.selected_y][state.selected_x] = core.EMPTY
	state.board[y][x] = piece
end

local function can_jump(state, y, x)
	for _,dir in ipairs(dirs) do
		local y2 = y + 2*dir.y
		local x2 = x + 2*dir.x

		if not in_range(y2, x2) then
			--print(string.format("Checking y2=%s, x2=%s, out of range", y2, x2))
			goto next_dir
		end

		if state.board[y2][x2] ~= core.EMPTY then
			--print(string.format("Checking y2=%s, x2=%s, occupied", y2, x2))
			goto next_dir
		end

		local dir_valid_move = core.valid_move(state, y, x, y2, x2)
		--print(string.format("Checking y2=%s, x2=%s, valid_move=%q", y2, x2, dir_valid_move))
		if dir_valid_move then
			return true
		end
		::next_dir::
	end
	return false
end

function move_is_jump(state, y, x)
	local dy = state.selected_y - y
	local dx = state.selected_x - x

	return math.abs(dy) == 2 and math.abs(dx) == 2
end

function jumps_available_for_player(state, player)
	for y=1,core.BOARD_HEIGHT do
		for x=1,core.BOARD_WIDTH do
			if core.piece_to_player(state.board[y][x]) ~= player then
				goto next_cell
			end
			if can_jump(state, y, x) then
				return true
			end
			::next_cell::
		end
	end

	return false
end

-- Used for both selecting a piece, and choosing where to move it.
-- (Called twice for a single move)
function core.player_move(state, player, y, x)
	if player ~= state.player_turn then
		return core.RC_NOT_YOUR_TURN
	end

	if not in_range(y,x) then
		return core.RC_INVALID_MOVE
	end

	if state.selected_y == nil or state.selected_x == nil then
		if state.board[y][x] == core.EMPTY then
			return core.RC_NO_PIECE_TO_SELECT
		elseif not is_player(state, y, x, player) then
			return core.RC_NOT_YOUR_PIECE
		else
			state.selected_y = y
			state.selected_x = x
			return core.RC_SUCCESS
		end
	else
		if y == state.selected_y and x == state.selected_x then
			if state.must_jump_selected then
				return core.RC_MUST_JUMP_SELECTED
			end
			state.selected_y = nil
			state.selected_x = nil
			-- return core.RC_UNSELECTED
			return core.RC_SUCCESS
		end

		if state.game_settings.must_jump_when_able then
			if jumps_available_for_player(state, player) and not move_is_jump(state, y, x) then
				return core.RC_MUST_JUMP
			end
		end

		-- change selection if selected own pieces
		if is_player(state, y, x, player) then
			state.selected_y = y
			state.selected_x = x
			return core.RC_SUCCESS
		end

		if state.board[y][x] ~= core.EMPTY then
			return core.RC_OCCUPIED
		end


		if state.must_jump_selected then
			if math.abs(state.selected_y - y) ~= 2 and
			   math.abs(state.selected_x - x) ~= 2 then
				return core.RC_MUST_JUMP_SELECTED
			end
		end


		local jumped_pieces = {}
		if core.valid_move(state, state.selected_y, state.selected_x, y, x, jumped_pieces) then
			for _,piece in ipairs(jumped_pieces) do
				state.board[piece.y][piece.x] = core.EMPTY
			end
			move_piece(state, y, x)
		else
			return core.RC_INVALID_MOVE
		end

		if (player == core.PLAYER1 and y == core.BOARD_HEIGHT) or
		   (player == core.PLAYER2 and y == 1) then
			state.board[y][x] = king(player)
		end

		if #jumped_pieces > 0 and can_jump(state, y, x) then
			state.must_jump_selected = true
			-- updated selected indicators to point to this cell
			-- now that the piece moved here
			state.selected_y = y
			state.selected_x = x
		else
			state.must_jump_selected = false
			state.selected_y = nil
			state.selected_x = nil
			state.player_turn = (((state.player_turn-1) + 1 ) % 2) + 1
		end

		return core.RC_SUCCESS
	end
end

function core.get_square_colour(y, x)
	return (y%2 == 1) ~= (x%2 == 1)
end


--local state = core.new_state()
--core.print_board(state.board)

return core
