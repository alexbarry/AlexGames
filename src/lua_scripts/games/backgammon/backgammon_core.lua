-- Game:   Backgammon
-- author: Alex Barry (github.com/alexbarry)
local core = {}

local utils = require("libs/utils")
local dice = require("libs/dice/dice")
local combinations = require("libs/combinations")


--[[
-- Board:
--
--    1 1 1
--    2 1 0 9 8 7    6 5 4 3 2 1
--    b - - - w - || b - - - - b
--    b - - - w - || b - - - - b  <-- (black start)
--    b - - - w - || b - - - - -
--    b - - - - - || b - - - - -
--    b - - - - - || b - - - - -
--                ||
--    w - - - - - || w - - - - -
--    w - - - - - || w - - - - -
--    w - - - b - || w - - - - -
--    w - - - b - || w - - - - w  <-- (white start)
--    w - - - b - || w - - - - w
--    1 1 1 1 1 1    1 2 2 2 2 2
--    3 4 5 6 7 8    9 0 1 2 3 4
--
--]]

core.BACKGAMMON_ROWS =  2
core.BACKGAMMON_COLS = 12


core.NUM_DICE = 2 -- 2 dice
core.DICE_MAX = 6 -- 6 sided dice

core.PLAYER_BLACK = 1
core.PLAYER_WHITE = 2
core.NUM_PLAYERS  = 2

-- top right of the board, where BLACK starts
core.BOARD_IDX_START = 1

-- bottom right of the board, where WHITE starts
core.BOARD_IDX_END   = core.BACKGAMMON_COLS*2

core.SUCCESS            = 0
core.NOT_YOUR_TURN      = 1
core.PIECE_CAN_NOT_MOVE = 2
core.INVALID_DST        = 3
core.NO_PIECE_IN_SRC    = 4
core.NOT_YOUR_PIECE     = 5
core.MUST_MOVE_MIDDLE   = 6
core.INVALID_MOVE       = 7

local ERR_MSGS = {
	[core.SUCCESS]            = "Success",
	[core.NOT_YOUR_TURN]      = "Not your turn",
	[core.PIECE_CAN_NOT_MOVE] = "This piece can not move",
	[core.INVALID_DST]        = "Invalid destination",
	[core.NO_PIECE_IN_SRC]    = "No piece to select",
	[core.NOT_YOUR_PIECE]     = "Not your piece",
	[core.MUST_MOVE_MIDDLE]   = "Must move piece in middle",
	[core.INVALID_MOVE]       = "Invalid move",
}

local STATE_WAITING_FOR_INIT_ROLLS    = 1
local STATE_WAITING_FOR_INIT_ACK      = 2
local STATE_WAITING_FOR_ROLL_NO_DBL   = 3
local STATE_WAITING_FOR_ROLL_AFTER_DBL= 4
local STATE_WAITING_FOR_MOVE_COMPLETE = 5

core.PLAYERS = {
	core.PLAYER_BLACK,
	core.PLAYER_WHITE,
}

function core.get_err_msg(rc)
	return ERR_MSGS[rc]
end

function core.get_player_name(player)
	if     player == core.PLAYER_BLACK then return "Black"
	elseif player == core.PLAYER_WHITE then return "White"
	else error(string.format("unexpected player id=%s", player)) end
end

function core.all_init_roll_complete(state)
	for player, init_roll in ipairs(state.player_init_rolls) do
		if init_roll == 0 then
			return false
		end
	end

	return true
end

local function get_next_init_roll_player(state)
	for player, init_roll in ipairs(state.player_init_rolls) do
		if init_roll == 0 then
			return player
		end
	end
end

local function dice_sum(dice)
	local sum_val = 0
	for _, die in ipairs(dice) do
		sum_val = sum_val + die
	end
	return sum_val
end

local function get_init_first_player(state)
	local max_dice = nil
	local max_dice_val = 0
	local max_player = nil
	for player, init_dice in ipairs(state.player_init_rolls) do
		if init_dice > max_dice_val then
			max_dice_val = init_dice
			max_dice = init_dice
			max_player = player
		end
	end

	return { player = max_player, dice = max_dice, dice_val = max_dice_val }
end

function get_init_prev_status_msg(state)
	local last_player = nil
	for player, init_dice in ipairs(state.player_init_rolls) do
		if init_dice == 0 then
			break
		end
		last_player = player
	end

	if last_player ~= nil then
		local last_player_name = core.get_player_name(last_player)
		local last_roll = state.player_init_rolls[last_player]
		return string.format("%s rolled %d. ", last_player_name, last_roll)
	end

	return ""
end

function core.get_status_msg(state)
	--print(string.format("get_status_msg(state=%s)", state.game_state))
	if state.game_state == STATE_WAITING_FOR_INIT_ROLLS then 
		local player = get_next_init_roll_player(state)
		local player_name = core.get_player_name(player)

		local prev_status_msg = get_init_prev_status_msg(state)
		return string.format("%s%s, please roll to see who goes first", prev_status_msg, player_name)
	end
	if state.game_state == STATE_WAITING_FOR_INIT_ACK then
		if state.player_init_rolls[1] == state.player_init_rolls[2] then
			return string.format("Both players rolled a %s, press 'Ack' to start over.", state.player_init_rolls[1])
		else
			local first_player = get_init_first_player(state).player
			local first_player_name = core.get_player_name(first_player)
			local prev_status_msg = get_init_prev_status_msg(state)
			return string.format("%s%s goes first, press 'Acknowledge' to continue", prev_status_msg, first_player_name)
		end
	end
	local action
	if state.player_selected == nil then
		action = "select a piece"
	else
		action = "select a destination"
	end
	return string.format("%s, please %s", core.get_player_name(state.player_turn), action)
end

function core.show_roll_button(state, player)
	if state.player_turn ~= player then
		return false
	end
	return (state.game_state == STATE_WAITING_FOR_INIT_ROLLS or
	        state.game_state == STATE_WAITING_FOR_ROLL_NO_DBL or
	        state.game_state == STATE_WAITING_FOR_ROLL_AFTER_DBL)
end

function core.show_ack_button(state)
	return state.game_state == STATE_WAITING_FOR_INIT_ACK
end

local function set_used_dice(state, dice_vals)
	state.used_dice = {}
	for i=1,#state.dice_vals do
		state.used_dice[i] = false
	end
end


function core.ack_init(state, player)
	if state.game_state == STATE_WAITING_FOR_INIT_ACK then
		if state.player_init_rolls[1] == state.player_init_rolls[2] then
			state.game_state = STATE_WAITING_FOR_INIT_ROLLS
			state.dice_vals = {}
			state.player_init_rolls = { 0, 0 }
		else
			local first_player_info = get_init_first_player(state)
			state.dice_vals = { state.player_init_rolls[1], state.player_init_rolls[2] }
			set_used_dice(state, state.dice_vals)
			state.game_state = STATE_WAITING_FOR_MOVE_COMPLETE
			state.move_timer = 0
		end
	else
		error(string.format("ack_init called from state %s", state.game_state))
	end

	return core.SUCCESS
end

local function make_pieces(val, piece_count)
	local ary = {}
	for i=1,piece_count do
		table.insert(ary, val)
	end
	return ary
end

function core.board_idx_to_coords(idx)
	if idx < 1 then return core.get_bearing_off_coords() end
	if idx > core.BACKGAMMON_COLS*2 then return core.get_bearing_off_coords() end

	idx = idx - 1
	local y = math.floor(idx/core.BACKGAMMON_COLS)+1
	local x = idx % core.BACKGAMMON_COLS + 1
	if y == 1 then
		x = core.BACKGAMMON_COLS - x + 1
	end
	return { y = y, x = x }
end

function core.is_last_piece(state, player, coords, piece_idx)
	local cell = core.get_cell(state, player, coords)
	if core.coords_are_middle(coords) then
		return piece_idx == #cell
	else
		return #cell == piece_idx
	end
end

function core.coords_to_board_idx(player, coords)
	if core.coords_are_middle(coords) then
		if player == core.PLAYER_BLACK then
			-- TODO maybe reverse these?
			return core.BOARD_IDX_START - 1
		elseif player == core.PLAYER_WHITE then
			return core.BOARD_IDX_END + 1
		else
			error(string.format("coords_to_board_idx: invalid player %s", player), 2)
		end
	elseif core.coords_are_bearing_off(coords) then
		if player == core.PLAYER_BLACK then
			return core.BOARD_IDX_START-1
		elseif player == core.PLAYER_WHITE then
			return core.BOARD_IDX_END+1
		else
			error(string.format("coords_to_board_idx: invalid player %s", player), 2)
		end
	end

	if coords == nil or
	   coords.x == nil or coords.y == nil or
	   not(1 <= coords.y and coords.y <= 2) or
	   not(1 <= coords.x and coords.x <= core.BACKGAMMON_COLS) then
		error(string.format("invalid coords {y=%s, x=%s}", coords.y, coords.x), 2)
	end
	local idx = (coords.y-1) * core.BACKGAMMON_COLS
	if coords.y == 1 then
		idx = idx + (core.BACKGAMMON_COLS - coords.x) + 1
	else
		idx = idx + coords.x
	end
	return idx
end


function pt_eq(coord1, coord2)
	return coord1.x == coord2.x and coord1.y == coord2.y
end

function core.piece_is_selected(state, coords)
	return state.player_selected ~= nil and pt_eq(state.player_selected, coords)
end

--[[
function test(idx, coord)
	local coords_result = core.board_idx_to_coords(idx)
	print(string.format("%d --> coords{y=%2d, x=%2d}", idx, coords_result.y, coords_result.x))
	local idx_result = core.coords_to_board_idx(player, coord)
	print(string.format("coords{y=%2d, x=%2d} --> %d", coord.y, coord.x, idx_result))
	assert(pt_eq(coord, coords_result))
	assert(idx == idx_result)
end
test(1, { y=1, x=12})
test(2, { y=1, x=11})
test(3, { y=1, x=10})
test(4, { y=1, x= 9})
test(5, { y=1, x= 8})
test(6, { y=1, x= 7})
test(7, { y=1, x= 6})
test(8, { y=1, x= 5})
test(9, { y=1, x= 4})
test(10, { y=1, x= 3})
test(11, { y=1, x= 2})
test(12, { y=1, x= 1})
test(13, { y=2, x= 1})
test(14, { y=2, x= 2})
test(15, { y=2, x= 3})
test(16, { y=2, x= 4})
test(17, { y=2, x= 5})
test(18, { y=2, x= 6})
test(19, { y=2, x= 7})
test(20, { y=2, x= 8})
test(21, { y=2, x= 9})
test(22, { y=2, x= 10})
test(23, { y=2, x= 11})
test(24, { y=2, x= 12})
--]]

--[
--  starting positions are:
--  1  2  3  4  5  6    7  8  9  10 11 12
--  B5 -- -- -- 3W -- | 5W -- -- -- -- 2B
--  W5 -- -- -- 3B -- | 5B -- -- -- -- 2W
--  white moves clockwise
--  black moves counter clockwise,
--]
function core.new_game()
	local state = {
		player_init_rolls = {},
		player_turn = core.PLAYER_BLACK,
		game_state = STATE_WAITING_FOR_INIT_ROLLS,

		-- there are typically two dice, unless when rolled they
		-- have the same value, in which case there are 4 dice.
		-- i.e. each value represents a move that can be made.
		-- the UI may choose to render this differently
		dice_vals = nil,
		-- array of booleans corresponding to if values in `dice_vals` have been used
		used_dice = nil,
		player_selected = nil,

		double_val = 1,

		move_timer = nil,

		-- set to true when the player must press a "can't move" button to acknowledge that
		-- they can't move. Only needed when there are dice moves remaining, but they can't be
		-- used to make a legitimate move.
		player_cant_move = false,
		pieces_in_middle = {},
		finished_pieces = {},
		board = {},
	}

	for _, player in ipairs(core.PLAYERS) do
		state.player_init_rolls[player] = 0
		state.pieces_in_middle[player] = {}
		state.finished_pieces[player] = {}
	end

	for y=1,core.BACKGAMMON_ROWS do
		state.board[y] = {}
		for x=1,core.BACKGAMMON_COLS do
			state.board[y][x] = {}
		end
	end

	state.board[1][ 1] = make_pieces(core.PLAYER_BLACK, 5)
	state.board[1][ 5] = make_pieces(core.PLAYER_WHITE, 3)
	state.board[1][ 7] = make_pieces(core.PLAYER_BLACK, 5)
	state.board[1][12] = make_pieces(core.PLAYER_BLACK, 2)

	state.board[2][ 1] = make_pieces(core.PLAYER_WHITE, 5)
	state.board[2][ 5] = make_pieces(core.PLAYER_BLACK, 3)
	state.board[2][ 7] = make_pieces(core.PLAYER_WHITE, 5)
	state.board[2][12] = make_pieces(core.PLAYER_WHITE, 2)

	return state
end

function core.get_player_dir(player)
	if player == 1 then return 1
	elseif player == 2 then return -1
	else error(string.format("unexpected player %s", player), 2) end
end

function core.print_state(state)
	print("state = {")
	print(string.format("    player_turn = %s", state.player_turn))
	print(string.format("    player_cant_move = %s", state.player_cant_move))
	print(string.format("    dice_vals = %s", utils.ary_to_str(state.dice_vals)))
	print(string.format("    used_dice = %s", utils.ary_to_str(state.used_dice)))
	print(string.format("    player_selected = %s", state.player_selected))
	print(string.format("    finished_pieces = %s", utils.ary_to_str(state.finished_pieces)))
	for i=1,2*core.BACKGAMMON_COLS do
		local coords = core.board_idx_to_coords(i)
		print(string.format("    board[%2d][%2d] (board idx: %2d) = %s",
		                    coords.y, coords.x, i,
		                    utils.ary_to_str(state.board[coords.y][coords.x])))
	end
	for player=1,core.NUM_PLAYERS do
		print(string.format("    pieces_in_middle[%d] = %s", player, utils.ary_to_str(state.pieces_in_middle[player])))
	end
	print("}")
end

local function set_dice(state, dice_vals)
	state.dice_vals = dice_vals
	set_used_dice(state, state.dice_vals)
end

local function roll_dice(state, player, num_dice)
	assert(num_dice ~= nil)
	state.dice_vals = dice.roll_multiple_dice(num_dice, core.DICE_MAX)
	if num_dice == 2 and
	   state.dice_vals[1] == state.dice_vals[2] then
		for i=1,2 do
			table.insert(state.dice_vals, state.dice_vals[1])
		end
	end
	set_dice(state, state.dice_vals)
end

function core.player_selecting_dst(state, player)
	return state.player_selected ~= nil
end

-- indicates if a destination is free to move to (e.g. is not occupied by
-- more than one enemy piece)
local function can_move_to_pos(state, y_idx, x_idx)
	local dst = {y=y_idx, x=x_idx}
	if core.coords_are_bearing_off(dst) then
		return true
	end
	local dst_cell = core.get_cell(state, player, dst)
	return (#dst_cell == 0 or #dst_cell == 1 or
	       dst_cell[1] == state.player_turn)
end

-- if a (pseudo) position is outside a board in the player's
-- forward direction, meaning that moving a place to this
-- position will remove it from the board (i.e. bearing off)
local function in_bearing_off_region(player, pos_idx)
	return (player == core.PLAYER_BLACK and pos_idx > core.BOARD_IDX_END or
	        player == core.PLAYER_WHITE and pos_idx < core.BOARD_IDX_START)
end

-- given a move choice, see if it is a valid move based on the dice sums.
-- TODO this generates all the sums and checks each one against the dst.
-- it would be more efficient to generates sums, find dsts that can be highlighted,
-- then only try to highlight those.
function core.valid_dst(state, player, src, dst)
	if src == nil then return false end
	src = core.coords_to_board_idx(player, src)

	local possib_dst_idx = core.coords_to_board_idx(player, dst)

	local avail_dice_vals = core.get_avail_dice(state.used_dice, state.dice_vals)
	local sums_info = combinations.get_distinct_sums(avail_dice_vals)
	-- Need to sort this for the case of bearing off, where
	-- instead of moving to a specific destination, you just
	-- need to move to a spot greater than 24 or less than 1.
	-- In that case, we must start with the smaller sums first,
	-- to avoid wasting more than necessary dice moving to a spot
	-- further than max+1 or min-1
	table.sort(sums_info, function (left, right)
		return left.val < right.val
	end)

	for _, sum_info in ipairs(sums_info) do
		if sum_info.val == 0 then
			goto next_sum
		end
		local dice_move_pos = src + core.get_player_dir(state.player_turn) * sum_info.val
		if dice_move_pos == possib_dst_idx or
		   core.coords_are_bearing_off(dst) and in_bearing_off_region(player, dice_move_pos) then 
			local dst_coords = core.board_idx_to_coords(possib_dst_idx)
			local is_valid = can_move_to_pos(state, dst_coords.y, dst_coords.x)
			if is_valid then
				local indexes_used = utils.get_val_indexes(avail_dice_vals, sum_info.parts)
				--print("avail_dice_vals = %s", utils.ary_to_str(avail_dice_vals))
				--print(string.format("Used dice %s", utils.ary_to_str(indexes_used)))
				return { is_valid = true, used_dice = indexes_used }
			end
		end
		::next_sum::
	end

	return { is_valid = false, used_dice = {} }
end

function valid_board_idx(board_idx)
	return 1 <= board_idx and board_idx <= core.BACKGAMMON_COLS*2
end

function core.get_avail_dice(used_dice, dice_vals)
	if used_dice == nil or dice_vals == nil then
		error(string.format("get_avail_dice: nil args used_dice=%s, dice_vals=%s", used_dice, dice_vals), 2)
	end

	if #used_dice ~= #dice_vals then
		error(string.format("get_avail_dice: used_dice len: %d, dice_vals len: %d", #used_dice, #dice_vals))
	end

	local dice_avail = {}
	for i, dice_val in ipairs(dice_vals) do
		if used_dice[i] then
			dice_val = 0
		end
		table.insert(dice_avail, dice_val)
	end
	return dice_avail
end

function core.player_can_move(state, player)
	for y=1,core.BACKGAMMON_ROWS do
		for x=1,core.BACKGAMMON_COLS do
			if core.piece_can_move(state, player, {y=y, x=x}) then
				return true
			end
		end
	end
	return false
end

-- returns true if a piece is able to move.
-- This is meant for when the player is selecting a piece to move,
-- whether or not it should be highlighted in the UI, and if it can be
-- selected by the player
function core.piece_can_move(state, player, coords)
	if player == nil then
		return false
	end

	if state.game_state ~= STATE_WAITING_FOR_MOVE_COMPLETE then
		return false
	end

	if not core.all_init_roll_complete(state, player) then
		return false
	end
	--print(string.format("piece_can_move(player=%d, coords=%s)", player, core.coords_to_str(coords)))
	local cell = core.get_cell(state, player, coords)
	if #cell == 0 or cell[1] ~= state.player_turn then
		return false
	end

	if #state.pieces_in_middle[player] > 0 and
	   not core.coords_are_middle(coords) then
		return false
	end

	local src = core.coords_to_board_idx(player, coords)

	local avail_dice = core.get_avail_dice(state.used_dice, state.dice_vals)
	--print(string.format("piece_can_move: avail_dice = %s", utils.ary_to_str(avail_dice)))
	local sums_info = combinations.get_distinct_sums(avail_dice)


	local can_bear_off = core.piece_can_bear_off(state, player, coords)

	for _, sum_info in ipairs(sums_info) do
		if sum_info.val == 0 then
			goto next_sum
		end
		local possib_dst_idx = src + core.get_player_dir(state.player_turn) * sum_info.val

		if can_bear_off and in_bearing_off_region(player, possib_dst_idx) then
			return true
		end

		if not valid_board_idx(possib_dst_idx) then
			goto next_sum
		end
		local dst_coords = core.board_idx_to_coords(possib_dst_idx)
		if can_move_to_pos(state, dst_coords.y, dst_coords.x) then
			return true
		end
		::next_sum::
	end

	return false
end

-- returns true if any dice have not been used yet
function core.any_dice_avail(state)
	return utils.any_eq(state.used_dice, false)
end

local function next_turn(state)
	--print("Moving to next player's turn")
	state.player_turn = (state.player_turn % core.NUM_PLAYERS) + 1
	state.game_state = STATE_WAITING_FOR_ROLL_NO_DBL
	state.move_timer = nil
	state.dice_vals = {}
	set_used_dice(state, state.dice_vals)

	if not core.player_can_move(state, state.player_turn) then
		state.player_cant_move = true
	end

end

local function mark_dice_used(state, dice_used_in_move)
	for _, dice_idx in ipairs(dice_used_in_move) do
		if state.used_dice[dice_idx] then
			error(string.format("tried to use dice %s but they were already used, previous use state = %s",
			      utils.ary_to_str(dice_used_in_move),
			      utils.ary_to_str(orig_dice_used)))
		end
		state.used_dice[dice_idx] = true
	end
end

-- TODO make sure that middle can't be used as a destination
local function move_player(state, player, dst_coords, dice_used_in_move)
	print(string.format("move_player %d, selected=%s, dst=%s, dice_used_in_move=%s",
	      player, core.coords_to_str(state.player_selected), core.coords_to_str(dst_coords),
	      utils.ary_to_str(dice_used_in_move)))
	local src = core.get_cell(state, player, state.player_selected)
	local dst = core.get_cell(state, player, dst_coords)

	print(string.format("move_player src_cell=%s, dst_cell=%s", utils.ary_to_str(src), utils.ary_to_str(dst)))

	-- If dst is opponent, handle "hit": place piece in middle
	if #dst > 0 and dst[1] ~= player then
		if #dst ~= 1 then
			error("move_player called with dst containing more than one opponent piece")
		end
		local piece = table.remove(dst)
		table.insert(state.pieces_in_middle[piece], piece)
	end

	local piece = table.remove(src)
	assert(piece == player)
	table.insert(dst, piece)

	local orig_dice_used = utils.ary_copy(state.used_dice)
	mark_dice_used(state, dice_used_in_move)
	state.player_selected = nil

	if not core.any_dice_avail(state) then
		print("no dice remaining, next player's turn")
		next_turn(state)
	elseif not core.player_can_move(state, player) then
		print("dice remain but player can not move anywhere")
		state.player_cant_move = true
	end
	-- if dice are available, but no moves can be made, then player needs to press a "can't move" button to progress
end

function core.player_cant_move_ack(state, player)
	if player ~= state.player_turn then
		return core.NOT_YOUR_TURN
	end

	if not state.player_cant_move then
		error("player_cant_move_ack called when state.player_cant_move is false")
	end

	state.player_cant_move = false
	next_turn(state)
	return core.SUCCESS
end

function core.coords_are_middle(coords)
	if coords == nil then error("arg is nil", 2) end
	return coords.y == -1 and coords.x == -1
end

function core.get_middle_coords()
	return { y = -1, x = -1 }
end

function core.coords_are_bearing_off(coords)
	if coords == nil then
		error("arg is nil", 2)
	end
	return coords.y == -2 and coords.x == -2
end

function core.get_bearing_off_coords()
	return { y = -2, x = -2 }
end

function core.get_cell(state, player, coords)
	if coords == nil then error("arg is nil", 2) end
	if core.coords_are_middle(coords) then
		return state.pieces_in_middle[player]
	elseif core.coords_are_bearing_off(coords) then
		return state.finished_pieces[player]
	else
		if state.board[coords.y] == nil or state.board[coords.y][coords.x] == nil then
			error(string.format("core.get_cell: unexpected coords %s", core.coords_to_str(coords)), 2)
		end
		local cell = state.board[coords.y][coords.x]
		return cell
	end
end

function core.coords_to_str(coords)
	if coords == nil then return "nil"
	else return string.format("{y=%s, x=%s}", coords.y, coords.x) end
end

function core.player_at_pos(state, coords)
	return state.board[coords.y][coords.x][1]
end

function core.get_valid_dsts(state, player, src)
	local valid_dsts = {}
	for y=1,core.BACKGAMMON_ROWS do
		for x=1,core.BACKGAMMON_COLS do
			local dst = { y = y, x = x }
			if core.valid_dst(state, player, src, dst).is_valid then
				table.insert(valid_dsts, dst)
			end
		end
	end

	return valid_dsts
end

function core.player_touch(state, player, coords)
	print(string.format("player %s touched %s", player, core.coords_to_str(coords)))
	if state.player_turn ~= player then
		return core.NOT_YOUR_TURN
	end

	-- if player selects something that isn't a piece, clear their selection
	if coords == nil then
		state.player_selected = nil
		return core.SUCCESS
	end

	if state.player_selected == nil then
		-- player is choosing a piece to select
		local cell = core.get_cell(state, player, coords)
		if #cell == 0 then
			return core.NO_PIECE_IN_SRC
		elseif cell[1] ~= player then
			return core.NOT_YOUR_PIECE
		end

		if #state.pieces_in_middle[player] > 0 and 
		   not core.coords_are_middle(coords) then
			return core.MUST_MOVE_MIDDLE
		end

		-- TODO need to make this function return false when player has pieces in middle 
		-- TODO need to handle middle highlighted as selected
		local can_move = core.piece_can_move(state, player, coords)
		if not can_move then
			return core.PIECE_CAN_NOT_MOVE
		else
			state.player_selected = coords
			return core.SUCCESS
		end
	else

		-- if the player presses the piece that they just selected,
		-- and if there is only one move available, then move there.
		-- If more than one move is available, then do nothing?
		-- (not sure if that's the most intuitive, but unselecting
		-- might be worse, since it looks similar to moving)
		if pt_eq(coords, state.player_selected) then
			local valid_dsts = core.get_valid_dsts(state, player, state.player_selected)
			--print(string.format("found %s valid dsts", #valid_dsts))
			if #valid_dsts == 1 then
				coords = valid_dsts[1]
				print(string.format("Player double tapped piece with only one destination, " ..
				                    "attempting to move to {y=%s,x=%s}", coords.y, coords.x))
			end
		end

		--print(string.format("Player selected dst index %s", possib_dst_idx))

		-- TODO should this "valid_dst" function check for middle?
		-- player is choosing a destination for their selected piece
		local valid_dst_info = core.valid_dst(state, player, state.player_selected, coords)
		if not valid_dst_info.is_valid then

			-- if the player presses a different piece that they control,
			-- then select that instead
			if not core.coords_are_bearing_off(coords) and
			   not core.coords_are_middle(coords) and
			   player == core.player_at_pos(state, coords) then
				state.player_selected = coords
				return core.SUCCESS
			end
			return core.INVALID_DST
		else
			move_player(state, player, coords, valid_dst_info.used_dice)
			return core.SUCCESS
		end
	end
end

-- Checks if a position is in the last 6 positions
-- leading up to the end of the board.
-- If all a player's pieces are in this region, they may start
-- bearing off.
local function is_final_region(player, coords)
	if player == core.PLAYER_BLACK then
		return coords.y == 2 and coords.x > 6
	elseif player == core.PLAYER_WHITE then
		return coords.y == 1 and coords.x > 6
	else
		error(string.format("unexpected player %s", player))
	end
end

local function players_pieces_all_in_final_region(state, player)
	for board_idx=core.BOARD_IDX_START,core.BOARD_IDX_END do
		local coords = core.board_idx_to_coords(board_idx)
		if not is_final_region(player, coords) and core.player_at_pos(state, coords) == player then
			return false
		end
	end

	return true
end

function core.player_can_bear_off(state, player)
	if state.game_state ~= STATE_WAITING_FOR_MOVE_COMPLETE then
		return false
	end

	if not core.all_init_roll_complete(state) then
		return false
	end
	if player ~= state.player_turn then
		return false
	end

	if not players_pieces_all_in_final_region(state, player) then
		return false
	end

	return true
end

function core.piece_can_bear_off(state, player, selection)
	if state.game_state ~= STATE_WAITING_FOR_MOVE_COMPLETE then
		return false
	end

	if not core.all_init_roll_complete(state) then
		return false
	end
	if not core.player_can_bear_off(state, player) then
		return false
	end

	if selection == nil then
		return false
	end

	local dst = core.get_bearing_off_coords()
	return core.valid_dst(state, player, selection, dst).is_valid
end

function core.increment_move_timer(state)
	if state.move_timer == nil then
		return
	end
	state.move_timer = state.move_timer + 1
end

function core.can_player_double_request(state, player)
	if state.game_state ~= STATE_WAITING_FOR_ROLL_NO_DBL then
		return false
	end

	if player ~= state.player_turn then
		return false
	end

	return true
end

function core.double_request(state, player)
	if not core.can_player_double_request(state, player) then
		return core.INVALID_MOVE
	end

	state.game_state = STATE_WAITING_FOR_ROLL_AFTER_DBL
	return core.SUCCESS
end

function core.double_response(state, player, accepted)
	if not accepted then
		-- TODO need to forfeit
	else
		state.double_val = state.double_val * 2
		state.game_state = STATE_WAITING_FOR_ROLL_AFTER_DBL
	end

end

function core.can_roll_rc(state, player)
	if state.game_state ~= STATE_WAITING_FOR_INIT_ROLLS and
	   state.game_state ~= STATE_WAITING_FOR_ROLL_NO_DBL and
	   state.game_state ~= STATE_WAITING_FOR_ROLL_AFTER_DBL then
		return core.INVALID_MOVE
	end

	if player ~= state.player_turn then
		return core.NOT_YOUR_TURN
	end

	return core.SUCCESS
end

-- dice_vals param should be nil for local multiplayer, but
-- should be the dice value when the dice is rolled by the other
-- player in network multiplayer
function core.roll(state, player, dice_vals)
	local can_roll_rc = core.can_roll_rc(state, player)
	if can_roll_rc ~= core.SUCCESS then
		return can_roll_rc
	end

	if state.game_state ~= STATE_WAITING_FOR_INIT_ROLLS then
		if dice_vals == nil then
			roll_dice(state, player, core.NUM_DICE)
		else
			set_dice(state, dice_vals)
		end
		state.game_state = STATE_WAITING_FOR_MOVE_COMPLETE
		state.move_timer = 0
	else

		if dice_vals == nil then
			roll_dice(state, player, --[[ num_dice = --]] 1)
		else
			set_dice(state, dice_vals)
		end
	
		if not core.all_init_roll_complete(state) then
			if player ~= get_next_init_roll_player(state) then
				error("game error: get_next_init_roll_player not current player")
			end
	
			state.player_init_rolls[player] = state.dice_vals[1]
	
			state.player_turn = get_next_init_roll_player(state)
			if state.player_turn == nil then
				state.game_state = STATE_WAITING_FOR_INIT_ACK
				local first_player_info = get_init_first_player(state)
				state.player_turn = first_player_info.player
			end
		end

	end

	return core.SUCCESS
end

return core
