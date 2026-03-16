-- Game:   Chess
-- Author: Alex Barry (github.com/alexbarry)

local core = {}

core.BOARD_SIZE = 8

core.PLAYER_WHITE = 1
core.PLAYER_BLACK = 2
core.PIECE_COUNT  = 2

core.PIECE_PAWN   = 1
core.PIECE_ROOK   = 2
core.PIECE_KNIGHT = 3
core.PIECE_BISHOP = 4
core.PIECE_QUEEN  = 5
core.PIECE_KING   = 6
core.PIECE_TYPE_COUNT = core.PIECE_KING

core.EMPTY_PIECE_ID = 0

core.GAME_STATUS_NORMAL    = 1
core.GAME_STATUS_CHECK     = 2
core.GAME_STATUS_CHECKMATE = 3

core.SUCCESS        = 0
core.NOT_YOUR_PIECE = 1
core.NOT_YOUR_TURN  = 2
core.RC_CANT_MOVE_INTO_CHECK = 3
core.RC_MUST_RESOLVE_CHECK   = 4
core.RC_GAME_OVER            = 5
--core.INVALID_MOVE   = 2

core.POS_ROOK1_BLACK = 11
core.POS_ROOK2_BLACK = 18
core.POS_ROOK1_WHITE = 81
core.POS_ROOK2_WHITE = 88

local ERROR_CODE_MAP = {
	[core.SUCCESS]        = "Success",
	[core.NOT_YOUR_PIECE] = "Not your piece",
	[core.NOT_YOUR_TURN]  = "Not your turn",
	[core.RC_CANT_MOVE_INTO_CHECK]  = "Can not move into check",
	[core.RC_MUST_RESOLVE_CHECK]    = "Must move out of check",
	[core.RC_GAME_OVER]             = "Game over!",
}

function core.get_err_msg(rc)
	return ERROR_CODE_MAP[rc]
end

function core.get_piece_id(player, piece_type)
	return ((player - 1) * core.PIECE_TYPE_COUNT + (piece_type - 1)) + 1
end



function core.get_player(piece_id)
	if piece_id == nil then error(string.format("core.get_player called with nil arg"), 2) end

	if piece_id == core.EMPTY_PIECE_ID then return nil end
	return math.floor((piece_id-1)/core.PIECE_TYPE_COUNT) + 1
end

local function get_other_player(player)
	if     player == core.PLAYER_BLACK then return core.PLAYER_WHITE
	elseif player == core.PLAYER_WHITE then return core.PLAYER_BLACK
	else
		error(string.format("unexpected player %s", player))
	end
end

local function coords_eq(a, b)
	return a.y == b.y and a.x == b.x
end


function core.get_piece_type(piece_id)
	return ((piece_id-1) % core.PIECE_TYPE_COUNT) + 1
end

local function get_player_pawn_row(player)
	if player == core.PLAYER_WHITE then return 7
	elseif player == core.PLAYER_BLACK then return 2 end
end

function core.new_game()
	local state = {
		player_turn = core.PLAYER_WHITE,
		board = {},
		selected = nil,
		game_status = core.GAME_STATUS_NORMAL,

		-- TODO could combine these into "castling_possible" for left and right
		-- for each player. Clear both left and right if king moves.
		rooks_moved = {},
		kings_moved = {},
	}

	state.rooks_moved[core.POS_ROOK1_BLACK] = false
	state.rooks_moved[core.POS_ROOK2_BLACK] = false
	state.rooks_moved[core.POS_ROOK1_WHITE] = false
	state.rooks_moved[core.POS_ROOK2_WHITE] = false
	state.kings_moved[core.PLAYER_WHITE] = false
	state.kings_moved[core.PLAYER_BLACK] = false

	for y=1,core.BOARD_SIZE do
		state.board[y] = {}
		for x=1,core.BOARD_SIZE do
			state.board[y][x] = core.EMPTY_PIECE_ID
		end
	end

	for x=1,core.BOARD_SIZE do
		state.board[7][x] = core.get_piece_id(core.PLAYER_WHITE, core.PIECE_PAWN)
	end
	state.board[8][1] = core.get_piece_id(core.PLAYER_WHITE, core.PIECE_ROOK)
	state.board[8][2] = core.get_piece_id(core.PLAYER_WHITE, core.PIECE_KNIGHT)
	state.board[8][3] = core.get_piece_id(core.PLAYER_WHITE, core.PIECE_BISHOP)
	state.board[8][4] = core.get_piece_id(core.PLAYER_WHITE, core.PIECE_QUEEN)
	state.board[8][5] = core.get_piece_id(core.PLAYER_WHITE, core.PIECE_KING)
	state.board[8][6] = core.get_piece_id(core.PLAYER_WHITE, core.PIECE_BISHOP)
	state.board[8][7] = core.get_piece_id(core.PLAYER_WHITE, core.PIECE_KNIGHT)
	state.board[8][8] = core.get_piece_id(core.PLAYER_WHITE, core.PIECE_ROOK)

	for x=1,core.BOARD_SIZE do
		state.board[2][x] = core.get_piece_id(core.PLAYER_BLACK, core.PIECE_PAWN)
	end
	state.board[1][1] = core.get_piece_id(core.PLAYER_BLACK, core.PIECE_ROOK)
	state.board[1][2] = core.get_piece_id(core.PLAYER_BLACK, core.PIECE_KNIGHT)
	state.board[1][3] = core.get_piece_id(core.PLAYER_BLACK, core.PIECE_BISHOP)
	state.board[1][4] = core.get_piece_id(core.PLAYER_BLACK, core.PIECE_QUEEN)
	state.board[1][5] = core.get_piece_id(core.PLAYER_BLACK, core.PIECE_KING)
	state.board[1][6] = core.get_piece_id(core.PLAYER_BLACK, core.PIECE_BISHOP)
	state.board[1][7] = core.get_piece_id(core.PLAYER_BLACK, core.PIECE_KNIGHT)
	state.board[1][8] = core.get_piece_id(core.PLAYER_BLACK, core.PIECE_ROOK)

	return state
end

local function copy_coords(pos)
	if pos == nil then return nil end
	return { y = pos.y, x = pos.x }
end

function core.copy_state(state)
	local new_state = {
		player_turn = state.player_turn,
		board       = {},
		selected    = copy_coords(state.selected),
		game_status = nil,
		kings_moved = {},
		rooks_moved = {},
	}

	for key, val in pairs(state.kings_moved) do
		new_state.kings_moved[key] = val
	end

	for key, val in pairs(state.rooks_moved) do
		new_state.rooks_moved[key] = val
	end

	for y=1,core.BOARD_SIZE do
		new_state.board[y] = {}
		for x=1,core.BOARD_SIZE do
			new_state.board[y][x] = state.board[y][x]
		end
	end

	return new_state
end

local function pts_eq(pt1, pt2)
	if pt1 == nil and pt2 == nil then
		return true
	elseif pt1 == nil or pt2 == nil then
		return false
	else
		return pt1.y == pt2.y and pt1.x == pt2.x
	end
end

local function boards_eq(board1, board2)
	for y=1,core.BOARD_SIZE do
		for x=1,core.BOARD_SIZE do
			if board1[y][x] ~= board2[y][x] then
				return false
			end
		end
	end
	return true
end

local function empty_in_between_pts_x(state, pt1, pt2)
	if pt1.y ~= pt2.y then
		error(string.format("empty_in_between_pts_x called with pts having different y values: pt1.y = %s, pt2.y = %s", pt1.y, pt2.y))
	end

	local y = pt1.y
	local x1 = math.min(pt1.x, pt2.x)
	local x2 = math.max(pt1.x, pt2.x)

	for x=(x1+1),(x2-1) do
		if state.board[y][x] ~= core.EMPTY_PIECE_ID then
			return false
		end
	end

	return true
end

local function can_castle(state, player, rook_pt)
	local rook_pos_id = get_rooks_moved_pos_id(rook_pt)
	local king_pt = get_king_pos(player)

	if rook_pos_id == nil then
		return false
	end

	local rook_piece = state.board[rook_pt.y][rook_pt.x] 
	local king_piece = state.board[king_pt.y][king_pt.x] 

	if core.get_player(rook_piece) ~= player or core.get_player(king_piece) ~= player then
		return false
	end

	if state.kings_moved[player] or state.rooks_moved[rook_pos_id] then
		return false
	end


	if  (core.get_piece_type(rook_piece) ~= core.PIECE_ROOK or
	     core.get_piece_type(king_piece) ~= core.PIECE_KING) then
		-- This should never be possible, unless the state is saved from the older
		-- version that didn't track `rooks_moved` and just defaults it to false.
		-- Otherwise, if the rook/king didn't move, then the piece should be what
		-- we expect.
		return false
	end

	if player ~= state.player_turn then
		return false
	end

	return empty_in_between_pts_x(state, king_pt, rook_pt)
	
end

function core.states_eq(state1, state2)
	return (
		state1.player_turn == state2.player_turn and
		--pts_eq(state1.selected, state2.selected) and
		boards_eq(state1.board, state2.board) and
		--state1.game_status == state2.game_status and
		state1.kings_moved[core.PLAYER_WHITE] == state2.kings_moved[core.PLAYER_WHITE] and
		state1.kings_moved[core.PLAYER_BLACK] == state2.kings_moved[core.PLAYER_BLACK] and
		state1.rooks_moved[core.POS_ROOK1_WHITE] == state2.rooks_moved[core.POS_ROOK1_WHITE] and
		state1.rooks_moved[core.POS_ROOK2_WHITE] == state2.rooks_moved[core.POS_ROOK2_WHITE] and
		state1.rooks_moved[core.POS_ROOK1_BLACK] == state2.rooks_moved[core.POS_ROOK1_BLACK] and
		state1.rooks_moved[core.POS_ROOK2_BLACK] == state2.rooks_moved[core.POS_ROOK2_BLACK]
	)
end

function core.get_player_name(player)
	if     player == core.PLAYER_BLACK then return "Black"
	elseif player == core.PLAYER_WHITE then return "White" end
end

function core.get_status_msg(state)
	local player_name = core.get_player_name(state.player_turn)
	local game_status_str = ""
	if state.game_status == nil then
		state.game_status = core.get_game_status(state)
	end
	if state.game_status == core.GAME_STATUS_NORMAL then
		-- do nothing
	elseif state.game_status == core.GAME_STATUS_CHECK then
		game_status_str = string.format("%s is in check!", player_name)
	elseif state.game_status == core.GAME_STATUS_CHECKMATE then
		return string.format("%s is in checkmate! Game over, %s wins.", player_name, core.get_player_name(get_other_player(state.player_turn)))
	else
		error(string.format("Unhandled game_status %s", state.game_status))
	end
	if #game_status_str > 0 then
		game_status_str = game_status_str .. ' '
	end

	local action
	if state.selected == nil then
		action = "select a piece to move"
	else
		action = "select a destination"
	end
	return string.format("%s%s, %s", game_status_str, player_name, action)
end

local function get_player_letter(player)
	if player == core.PLAYER_BLACK then return 'B'
	elseif player == core.PLAYER_WHITE then return 'W'
	else
		error(string.format("Unhandled player %s", player))
	end
end

local function get_piece_letter(piece_type)
	if     piece_type == core.PIECE_KING     then return "K"
	elseif piece_type == core.PIECE_QUEEN    then return "Q"
	elseif piece_type == core.PIECE_BISHOP   then return "B"
	elseif piece_type == core.PIECE_KNIGHT   then return "N"
	elseif piece_type == core.PIECE_ROOK     then return "R"
	elseif piece_type == core.PIECE_PAWN     then return "P"
	else
		error(string.format("Unhandled piece type %s", piece_type))
	end
end

local function piece_id_to_hr_str(piece_id)
	local player     = core.get_player(piece_id)
	local piece_type = core.get_piece_type(piece_id)
	return get_player_letter(player) .. get_piece_letter(piece_type)
end

local function pt_to_string(pt)
	if pt == nil then return "nil"
	else
		return string.format("{ y=%d, x=%d }", pt.y, pt.x)
	end
end

function core.print_state(state)
	--          1  2  3  4  5  6  7  8
	row_sep = '+--+--+--+--+--+--+--+--+'
	io.write(row_sep .. '\n')
	for y=1,core.BOARD_SIZE do
		io.write('|')
		for x=1,core.BOARD_SIZE do
			local piece_id   = state.board[y][x]
			if piece_id == core.EMPTY_PIECE_ID then
				io.write('  ')
			else
				io.write(piece_id_to_hr_str(piece_id))
			end
			io.write('|')
		end
		io.write('\n' .. row_sep .. '\n')
	end
	io.write(string.format("- player_turn: %s\n", core.get_player_name(state.player_turn)))
	io.write(string.format("- player_selected: %s\n", pt_to_string(state.selected)))
	io.write(string.format("- game_status: %s\n", state.game_status))
	io.write("- pieces moved (for castling):\n")
	io.write(string.format("    black king:  %s\n", state.kings_moved[core.PLAYER_BLACK]))
	io.write(string.format("    black rook1: %s\n", state.rooks_moved[core.POS_ROOK1_BLACK]))
	io.write(string.format("    black rook2: %s\n", state.rooks_moved[core.POS_ROOK2_BLACK]))
	io.write(string.format("    white king:  %s\n", state.kings_moved[core.PLAYER_WHITE]))
	io.write(string.format("    white rook1: %s\n", state.rooks_moved[core.POS_ROOK1_WHITE]))
	io.write(string.format("    white rook2: %s\n", state.rooks_moved[core.POS_ROOK2_WHITE]))
	io.write("--------------------------------------\n")
end

local function get_piece_move_cells(piece_type, dy, dx)
	if piece_type == core.PIECE_KNIGHT then
		return ((math.abs(dy) == 2 and math.abs(dx) == 1) or
		        (math.abs(dy) == 1 and math.abs(dx) == 2))
	elseif piece_type == core.PIECE_KING then
		return math.abs(dx) <= 1 and math.abs(dy) <= 1 and
		       (math.abs(dy) > 0 or math.abs(dx) > 0)
	end
end

local function get_piece_move_vecs(piece_type)
	if piece_type == core.PIECE_ROOK then
		return { { y=1, x=0 }, {y=-1, x=0}, {y=0, x=1}, {y=0, x=-1} }
	elseif piece_type == core.PIECE_BISHOP then
		return { { y=1, x=1 }, {y=-1, x=1}, {y=1, x=-1}, {y=-1, x=-1} }
	elseif piece_type == core.PIECE_QUEEN then
		return { { y=1, x=0 }, {y=-1, x=0}, {y=0, x=1},  {y= 0, x=-1},
		         { y=1, x=1 }, {y=-1, x=1}, {y=1, x=-1}, {y=-1, x=-1} }
	else
		return {}
	end
end


local function out_of_range(pos)
	return not (1 <= pos.x and pos.x <= core.BOARD_SIZE and
	            1 <= pos.y and pos.y <= core.BOARD_SIZE)
end

local function get_player_move_dir(player)
	if player == core.PLAYER_WHITE then return -1
	elseif player == core.PLAYER_BLACK then return 1 end
end

local function get_player_rel_delta_pos(player, src, dst)
	local dy = dst.y - src.y
	local dx = dst.x - src.x

	dy = get_player_move_dir(player) * dy

	return { dy = dy, dx = dx }
end

local function move_is_castle(player, src, dst)
	--print(string.format("move_is_castle(src=(%d,%d), dst=(%d,%d)", src.y, src.x, dst.y, dst.x))
	if not pts_eq(src, get_king_pos(player)) then
		--print(string.format("move_is_castle returning false because ne to king pos %d %d", get_king_pos(player).y, get_king_pos(player).x))
		return false
	end
	return src.y == dst.y and math.abs(src.x - dst.x) == 2
end

local function get_castle_rook_pt_from_king_dst(player, king_dst)
	local king_src = get_king_pos(player)
	--print(string.format("get_castle_rook_pt_from_king_dst(king_dst=(%d,%d), king_src=(%d,%d))", king_dst.y, king_dst.x, king_src.y, king_dst.x))
	if not move_is_castle(player, king_src, king_dst) then
		error(string.format("get_castle_rook_pt_from_king_dst called when move is not castle"))
	end
	local y = king_dst.y
	local x
	if king_dst.x < 5 then
		x = 1
	else
		x = 8
	end

	return { y = y, x = x }
end

-- Checks if a move can be made by that kind of piece, and that
-- no pieces are in the way.
-- Does not check if the move results in check or checkmate. (i.e.
-- this can return true for moves that would put your own king in check)
-- Also doesn't check for castling or en passant
local function is_valid_move_pos(state, src, dst)
	-- print(string.format("is_valid_move_pos(src=(%d,%d), dst=(%d,%d))", src.y, src.x, dst.y, dst.x))
	local src_piece_id = state.board[src.y][src.x]
	local dst_piece_id = state.board[dst.y][dst.x]

	local src_player = core.get_player(src_piece_id)
	local src_piece_type = core.get_piece_type(src_piece_id)

	local dst_player = core.get_player(dst_piece_id)

	local delta_pos = get_player_rel_delta_pos(src_player, src, dst)
	local dy = delta_pos.dy
	local dx = delta_pos.dx

	if src_piece_type == core.PIECE_PAWN then
		if dx == 0 then
			if dy == 1 and dst_piece_id == core.EMPTY_PIECE_ID then
				return true
			elseif dy == 2 and src.y == get_player_pawn_row(src_player) then
				return (state.board[src.y+1*get_player_move_dir(src_player)][src.x] == core.EMPTY_PIECE_ID and
				        state.board[src.y+2*get_player_move_dir(src_player)][src.x] == core.EMPTY_PIECE_ID)
			end
		elseif math.abs(dx) == 1 and dy == 1 then
			return core.get_player(dst_piece_id) == get_other_player(src_player)
		else
			return false
		end
	elseif src_piece_type == core.PIECE_KING and move_is_castle(src_player, src, dst) then
		--print(string.format("is_valid_move_pos... calling get_castle_rook_pt_from_king_dst(dst=(%d,%d)", dst.y, dst.x))
		local rook_pt = get_castle_rook_pt_from_king_dst(src_player, dst)
		--print("is_valid_move_pos... done calling get_castle_rook_pt_from_king_dst")
		return can_castle(state, src_player, rook_pt)
	elseif get_piece_move_cells(src_piece_type, dy, dx) then
		return dst_piece_id == core.EMPTY_PIECE_ID or dst_player ~= src_player
	else
		for _, move_vec in ipairs(get_piece_move_vecs(src_piece_type)) do
			for i=1,core.BOARD_SIZE do
				local dst2 = { y = src.y + move_vec.y*i,
				               x = src.x + move_vec.x*i}
				if out_of_range(dst2) then
					goto next_move_vec
				end
				local dst2_piece_id = state.board[dst2.y][dst2.x]
				if core.get_player(dst2_piece_id) == src_player then
					goto next_move_vec
				elseif core.get_player(dst2_piece_id) == get_other_player(src_player) then
					if coords_eq(dst, dst2) then
						return true
					end
					goto next_move_vec
				else
					if coords_eq(dst, dst2) then
						return true
					end
				end
			end
			::next_move_vec::
		end
	end
end

function core.get_possib_dsts(state, src)
	local piece_id = state.board[src.y][src.x]
	if piece_id == core.EMPTY_PIECE_ID then return {} end
	local piece_type = core.get_piece_type(piece_id)
	local player = core.get_player(piece_id)

	local possib_dsts = {}

	for y=1,core.BOARD_SIZE do
		for x=1,core.BOARD_SIZE do
			local dst_piece_id = state.board[y][x]

			if is_valid_move_pos(state, src, {y=y, x=x}) then
				table.insert(possib_dsts, {y=y, x=x})
			end

			::next_dst::
		end
	end

	if piece_type == core.PIECE_KING then
		for _, rook_pos in ipairs(get_rook_pts(player)) do
			if can_castle(state, state.player_turn, rook_pos) then
				table.insert(possib_dsts, get_king_castle_dst(state.player_turn, rook_pos))
			end
		end
	end

	return possib_dsts
end

function core.in_check(state, player)
	for y=1,core.BOARD_SIZE do
		for x=1,core.BOARD_SIZE do
			local src = { y = y, x = x }
			local src_piece_id = state.board[y][x]
			-- Only check other player's pieces
			if src_piece_id == core.EMPTY_PIECE_ID or
			   core.get_player(src_piece_id) == player then
				goto next_square
			end

			local dsts = core.get_possib_dsts(state, src)
			for _, dst in ipairs(dsts) do
				local dst_piece_id = state.board[dst.y][dst.x]
				-- See if any of them could capture the king on their next move
				if core.get_piece_type(dst_piece_id) == core.PIECE_KING and
				   core.get_player(dst_piece_id) == player then
					return true
				end
				
			end

			::next_square::
		end
	end
	return false
end

function get_rooks_moved_pos_id(pt)
	if pt.y == 1 and pt.x == 1 then
		return core.POS_ROOK1_BLACK
	elseif pt.y == 1 and pt.x == 8 then
		return core.POS_ROOK2_BLACK
	elseif pt.y == 8 and pt.x == 1 then
		return core.POS_ROOK1_WHITE
	elseif pt.y == 8 and pt.x == 8 then
		return core.POS_ROOK2_WHITE
	end
end

function get_king_pos(player)
	if player == core.PLAYER_BLACK then
		return { y = 1, x = 5 }
	elseif player == core.PLAYER_WHITE then
		return { y = 8, x = 5 }
	else
		error(string.format("Unhandled player %s passed to get_king_pos", player))
	end
end

function get_king_castle_dst(player, rook_pos)
	local king_pos = get_king_pos(player)

	local x = king_pos.x
	if rook_pos.x < king_pos.x then
		x = x - 2
	else
		x = x + 2
	end

	return { y = king_pos.y, x = x }
end

function get_rook_pos(player, rook_id)
	local y, x

	if rook_id == 1 then
		x = 1
	elseif rook_id == 2 then
		x = 8
	else
		error(string.format("Invalid rook_id %s, expected 1 or 2", rook_id))
	end

	if player == core.PLAYER_BLACK then
		y = 1
	elseif player == core.PLAYER_WHITE then
		y = 8
	else
		error(string.format("Unhandled player %s", player))
	end

	return { y = y, x = x }
end

local function get_rook_pt_from_castle_dst(player, dst)
	local king_pos = get_king_pos(player)
	local rook_id
	if dst.x < king_pos.x then
		rook_id = 1
	else
		rook_id = 2
	end

	return get_rook_pos(player, rook_id)
end

local function get_rook_dst_from_castling(player, rook_pt)
	local king_pos = get_king_pos(player)
	local x
	if rook_pt.x < king_pos.x then
		x = king_pos.x - 1
	else
		x = king_pos.x + 1
	end

	return { y = king_pos.y, x = x }
end

function get_rook_pts(player)
	local pts = {}
	for i=1,2 do
		table.insert(pts, get_rook_pos(player, i))
	end
	return pts
end

local function move_piece(state, src, dst)
	--print(string.format("Moving piece %d %d to %d %d", src.y, src.x, dst.y, dst.x))
	local piece_id = state.board[src.y][src.x]
	local piece_type = core.get_piece_type(piece_id)
	local this_player = core.get_player(piece_id)
	if piece_id == core.EMPTY_PIECE_ID then
		return core.SUCCESS
	end

	local state_copy = core.copy_state(state)
	state_copy.board[src.y][src.x] = core.EMPTY_PIECE_ID
	state_copy.board[dst.y][dst.x] = piece_id
	state_copy.selected = nil
	state_copy.player_turn = get_other_player(state.player_turn)
	if core.in_check(state_copy, this_player) then
		return core.RC_CANT_MOVE_INTO_CHECK
	end

	local rooks_moved_pos_id = get_rooks_moved_pos_id(src)
	if rooks_moved_pos_id ~= nil then
		state.rooks_moved[rooks_moved_pos_id] = true
	end

	if piece_type == core.PIECE_KING then
		state.kings_moved[this_player] = true
	end

	state.board[src.y][src.x] = core.EMPTY_PIECE_ID
	state.board[dst.y][dst.x] = piece_id
	state.selected = nil
	state.player_turn = get_other_player(state.player_turn)
	state.game_status = core.get_game_status(state)

	if piece_type == core.PIECE_KING and move_is_castle(this_player, src, dst) then
		--print("Applying castling move...")
		local rook_pos = get_rook_pt_from_castle_dst(this_player, dst)
		local new_rook_pos = get_rook_dst_from_castling(this_player, dst)
		local this_player_rook = state.board[rook_pos.y][rook_pos.x]
		assert(core.get_player(this_player_rook) == this_player)
		assert(core.get_piece_type(this_player_rook) == core.PIECE_ROOK)
		assert(state.board[new_rook_pos.y][new_rook_pos.x] == core.EMPTY_PIECE_ID)
		state.board[rook_pos.y][rook_pos.x] = core.EMPTY_PIECE_ID
		state.board[new_rook_pos.y][new_rook_pos.x] = this_player_rook
		state.rooks_moved[get_rooks_moved_pos_id(rook_pos)] = true
	end

	if state.game_status == core.GAME_STATUS_CHECKMATE then
		return core.RC_GAME_OVER
	end
	return core.SUCCESS
end

local function get_player_pieces(state, player)
	local pieces_pos = {}
	for y=1,core.BOARD_SIZE do
		for x=1,core.BOARD_SIZE do
			local piece_id = state.board[y][x]
			if piece_id ~= core.EMPTY_PIECE_ID and
			   core.get_player(piece_id) == player then
				table.insert(pieces_pos, {y=y, x=x})
			end
		end
	end
	return pieces_pos
end

function core.get_game_status(state)
	local in_check = core.in_check(state, state.player_turn)

	if not in_check then
		return core.GAME_STATUS_NORMAL
	else
		for _, src_pos in ipairs(get_player_pieces(state, state.player_turn)) do
			for _, dst_pos in ipairs(core.get_possib_dsts(state, src_pos)) do
				local state_copy = core.copy_state(state)
				local rc = move_piece(state_copy, src_pos, dst_pos)
				if rc == core.SUCCESS then
					return core.GAME_STATUS_CHECK
				end
			end
		end
		return core.GAME_STATUS_CHECKMATE
	end
end

function core.player_touch(state, player, coords)
	if player ~= state.player_turn then
		return core.NOT_YOUR_TURN
	end

	if state.selected == nil then
		if coords == nil then return core.SUCCESS end
		local dst_piece_id = state.board[coords.y][coords.x]
		if core.get_player(dst_piece_id) ~= player then
			return core.NOT_YOUR_PIECE
		else
			state.selected = coords
			return core.SUCCESS
		end
	else
		--print(string.format("player_touch(coords=(%d,%d)); selected=%s", coords.y, coords.x, pt_to_string(state.selected)))
		if coords == nil or coords_eq(coords, state.selected) then
			state.selected = nil
			return core.SUCCESS
		else
			if not is_valid_move_pos(state, state.selected, coords) then
				local dst_piece_id = state.board[coords.y][coords.x]
				-- If the player clicks on one of their own pieces, select that one instead
				if core.get_player(dst_piece_id) == player then
					print("player selected a different piece")
					state.selected = coords
				-- If the player clicks on an empty piece or enemy piece that can't be captured,
				-- unselect
				else
					print("player selected an empty or other player piece")
					state.selected = nil
				end
				return core.SUCCESS
			else
				--print(string.format("calling move_piece(src=%s, dst=%s)", pt_to_string(state.selected), pt_to_string(coords)))
				local rc = move_piece(state, state.selected, coords)
				if rc == core.RC_CANT_MOVE_INTO_CHECK then
					if core.in_check(state, state.player_turn) then
						return core.RC_MUST_RESOLVE_CHECK
					end
				end
				return rc
			end
		end
	end
end

return core
