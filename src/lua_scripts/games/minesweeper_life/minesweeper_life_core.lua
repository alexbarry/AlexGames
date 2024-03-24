
local core = {}

core.INIT_ZOOM_FACT = 0.5

local CELL_COUNT_BORDER_PADDING = 6

local dirs = {
	{y = 0, x = 1},
	{y = 1, x = 1},
	{y = 1, x = 0},
	{y = 1, x =-1},
	{y = 0, x =-1},
	{y =-1, x =-1},
	{y =-1, x = 0},
	{y =-1, x = 1},
}

core.DEFAULT_MINE_PORTION = 0.1


local MIN_MAX_ZOOM_FACT = 3

core.MOVE_FLAG_CELL    = 1
core.MOVE_CLICK_CELL   = 2

core.RC_SUCCESS      =  0
core.RC_OUT_OF_RANGE = -1
core.RC_INVALID_MOVE = -2
core.RC_CAN_NOT_AUTO_REVEAL = -3

local FLAG_MINE_SUCCESS_SCORE =   10
local FLAG_MINE_FAIL_SCORE    =  -30
local REVEAL_MINE_SCORE       = -100
local REVEAL_CELL_SCORE       =    1


-- TODO this should be in the draw file only
-- apparently I wrote this game before I was used to properly separating the UI and the game logic
core.cell_size = 35

local function in_range(state, y, x)
	return 1 <= y and y <= state.game.height and
	       1 <= x and x <= state.game.width
end

-- TODO rename this to "update"
function core.get_touching_mine_count(state)

	for y=1,state.game.height do
		for x=1,state.game.width do
			local count = 0
			for _,dir in ipairs(dirs) do
				local y2 = y + dir.y
				local x2 = x + dir.x
				if not in_range(state, y2, x2) then
					goto next_dir
				end

				if state.game.board[y2][x2].has_mine then
					count = count + 1
				end
				::next_dir::
			end
			state.game.board[y][x].touching_mine_count = count
		end
	end
	
end

function core.new_player_state()
	local player_state = {
		offset_y = 0,
		offset_x = 0,
		zoom_fact = core.INIT_ZOOM_FACT,
		score    = 0,
	}
	return player_state
end

function core.copy_player_ui_states(state)
	local ui_states = {}
	for _, player in ipairs(state.players) do
		table.insert(ui_states, {
			offset_y = player.offset_y,
			offset_x = player.offset_x,
			zoom_fact = player.zoom_fact,
		})
	end
	return ui_states
end

function core.apply_player_ui_states(state, ui_states)
	for player_idx, player in ipairs(state.players) do
		player.offset_y  = ui_states[player_idx].offset_y
		player.offset_x  = ui_states[player_idx].offset_x
		player.zoom_fact = ui_states[player_idx].zoom_fact
	end
end

local function copy_cell(cell)
	local new_cell = {
		has_mine            = cell.has_mine,
		revealed            = cell.revealed,
		flagged_by_player   = cell.flagged_by_player,
		touching_mine_count = cell.touching_mine_count,
	}
	return new_cell
end

function core.new_state(player_count, game_height, game_width, cell_size, mine_portion)
	local state = {
		game = {
			width = game_width,
			height = game_height,
			board = {},
			cells_unrevealed = nil,
			mines_unrevealed = nil,
		},
		players = {},
		cell_size = cell_size,
	}

	for y=1,game_height do
		state.game.board[y] = {}
		for x=1,game_width do
			state.game.board[y][x] = {}
			state.game.board[y][x].has_mine = (math.random() <= mine_portion)
			state.game.board[y][x].revealed = false
			state.game.board[y][x].flagged_by_player = nil
			state.game.board[y][x].touching_mine_count = nil
		end
	end

	for i=1,player_count do
		state.players[i] = core.new_player_state()
	end

	core.calc_state_vals(state)

	return state
end

function core.calc_state_vals(state)
	core.get_touching_mine_count(state)
	core.calc_cells_unrevealed(state)
	core.calc_mines_unrevealed(state)
end

function core.calc_cells_unrevealed(state)
	local cells_unrevealed = 0
	for y=1,state.game.height do
		for x=1,state.game.width do
			local cell = state.game.board[y][x]
			if not cell.revealed and not cell.flagged_by_player then
				cells_unrevealed = cells_unrevealed + 1
			end
		end
	end
	state.game.cells_unrevealed = cells_unrevealed
end

function core.calc_mines_unrevealed(state)
	local mines_unrevealed = 0
	for y=1,state.game.height do
		for x=1,state.game.width do
			local cell = state.game.board[y][x]
			if cell.has_mine and not cell.revealed and not cell.flagged_by_player then
				mines_unrevealed = mines_unrevealed + 1
			end
		end
	end
	state.game.mines_unrevealed = mines_unrevealed
end


function core.is_game_over(state)
	return state.game.cells_unrevealed == 0
end
	

local function clip_min_max(val, min_val, max_val)
	if val < min_val then return min_val
	elseif val > max_val then return max_val
	else return val end
end

function core.get_zoom_fact(state, player)
	return state.players[player].zoom_fact
end
function core.set_zoom_fact(state, player, zoom_fact)
	state.players[player].zoom_fact = clip_min_max(zoom_fact, 1/MIN_MAX_ZOOM_FACT, MIN_MAX_ZOOM_FACT)
end

function add_pts(arg1, arg2)
	return { y = (arg1.y + arg2.y), x = (arg1.x + arg2.x) }
end

-- TODO there must be a minesweeper version of this already,
-- but I copied it from my "life" game
function count_neighbours(state, pos)
	local count = 0
	for _, dir in ipairs(dirs) do
		local pt2 = add_pts(pos, dir)
		if not in_range(state, pt2.y, pt2.x) then
			goto next_dir
		end

		if state.game.board[pt2.y][pt2.x].has_mine then
			count = count + 1
		end

		::next_dir::
	end

	return count
end

local function copy_board(board)
	local new_board = {}
	for _, row in ipairs(board) do
		local new_row = {}
		for _, cell in ipairs(row) do
			table.insert(new_row, copy_cell(cell))
		end
		table.insert(new_board, new_row)
	end
	return new_board
end

function core.life_increment(state)
	local new_board = copy_board(state.game.board)
	for y=1,#state.game.board do
		for x=1,#state.game.board[y] do
			local mine = state.game.board[y][x].has_mine
			local neighbour_count = count_neighbours(state, {y=y, x=x})
			if mine and 2 <= neighbour_count and neighbour_count <= 3 then
				new_board[y][x].has_mine = true
			elseif not mine and neighbour_count == 3 then
				new_board[y][x].has_mine = true
			else
				new_board[y][x].has_mine = false
			end
		end
	end
	state.game.board = new_board
end

-- normally this "autoreveal" happens when the user first reveals
-- an "empty" cell (meaning it has no neighbouring mines).
-- But in "life" mines move around, and I've found it cumbersome
-- to require the user to click the empty cells even though they
-- are guaranteed to be safe (i.e. no flagging/mines nearby are needed)
function core.autoreveal_empty_cells(state, player)
	for y=1,state.game.height do
		for x=1,state.game.width do
			if state.game.board[y][x].revealed then
				if count_neighbours(state, {y=y, x=x}) == 0 then
					core.reveal_neighbours(state, player, y, x)
				end
			end
		end
	end
end

-- Before adding "life", minesweeper wouldn't let you flag cells that
-- don't contain a mine (since in multiplayer, that could become a mess.
-- in single player though, it would be reasonable)
-- 
-- But in "life", the mines move around, and flags no longer contain mines sometimes.
-- So remove the flags
function core.remove_flags_if_no_longer_valid(state)
	for y=1,state.game.height do
		for x=1,state.game.width do
			local cell = state.game.board[y][x]
			if not cell.has_mine and cell.flagged_by_player ~= nil then
				cell.flagged_by_player = nil
				cell.revealed = true
			end
		end
	end
end

function core.handle_move(state, player, move, y, x)

	local prev_cell_state = state.game.board[y][x]

	-- kind of a hack, I should modify the life_increment function to 
	-- take in a board, rather than do this
	local state2 = {
		game = {
			height = state.game.height,
			width  = state.game.width,
			board  = copy_board(state.game.board),
		},
	}
	core.life_increment(state2)

	print(string.format("On copy of state, incremented life state and found cell %d %d is revealed=%s, has_mine=%s prev_has_mine=%s (move=%s)", y, x, state2.game.board[y][x].revealed, state2.game.board[y][x].has_mine, prev_cell_state.has_mine, move))

	local rc
	-- if flagging, only support flagging cells that previously were not mines,
	-- and have become one since the life update.
	-- if revealing, only support unrevealed cells
	if (move == core.MOVE_FLAG_CELL and not prev_cell_state.has_mine and state2.game.board[y][x].has_mine) or
	   (move == core.MOVE_CLICK_CELL and not prev_cell_state.revealed) then
		-- TODO maybe only do this every 10 moves or so
		core.life_increment(state)

		-- I'm not sure if this takes too much of the fun out of it.
		--core.autoreveal_empty_cells(state, player)
		core.get_touching_mine_count(state)
		core.remove_flags_if_no_longer_valid(state)

		-- Update "mine count" and etc, and check if game is now won
		core.calc_state_vals(state)
		if state.game.cells_unrevealed == 0 then
		end

		if move == core.MOVE_FLAG_CELL then
			rc = core.flag_cell(state, player, y, x)
		elseif move == core.MOVE_CLICK_CELL then
			rc = core.clicked_cell(state, player, y, x)
		else
			error(string.format("unhandled move type %s", move))
		end

	end


	return rc
end

local function in_ary(ary, y, x)
	if ary[y] == nil then
		return false
	else
		return ary[y][x] ~= nil
	end
end


-- I think what I need here is the width of the view-- how 
-- many mines fit in the view window
local function get_max_y_offset(state)
	return (state.game.height - CELL_COUNT_BORDER_PADDING) * core.cell_size 
end

local function get_max_x_offset(state)
	return (state.game.width  - CELL_COUNT_BORDER_PADDING) * core.cell_size
end

function core.adjust_offset(state, player, offset_y, offset_x)
	state.players[player].offset_y = clip_min_max(offset_y,
	                                             -core.cell_size*CELL_COUNT_BORDER_PADDING,
	                                             get_max_y_offset(state))
	state.players[player].offset_x = clip_min_max(offset_x,
	                                             -core.cell_size*CELL_COUNT_BORDER_PADDING,
	                                             get_max_x_offset(state))
end

function core.reveal_cell(state, player, y, x)
	if player == nil then
		error("player param is nil")
	end
	if not in_range(state, y, x) then
		return core.RC_OUT_OF_RANGE
	end

	if state.game.board[y][x].revealed then
		return core.RC_SUCCESS
	end

	local to_visit = {
		{ y = y, x = x }
	}
	local visited = {}

	while #to_visit > 0 do
		local pos = table.remove(to_visit)

		if not in_range(state, pos.y, pos.x) or
		   in_ary(visited, pos.y, pos.x) then
			goto next_cell
		end


		if not state.game.board[pos.y][pos.x].revealed then
			state.game.cells_unrevealed = state.game.cells_unrevealed - 1
		end
		state.game.board[pos.y][pos.x].revealed = true
		local score_change = 0
		if state.game.board[pos.y][pos.x].has_mine then
			score_change = REVEAL_MINE_SCORE
			state.game.mines_unrevealed = state.game.mines_unrevealed - 1
		else
			score_change = REVEAL_CELL_SCORE
		end
		state.players[player].score = state.players[player].score + score_change

		if visited[pos.y] == nil then
			visited[pos.y] = {}
		end
		visited[pos.y][pos.x] = true

		if state.game.board[pos.y][pos.x].touching_mine_count > 0 or
		   state.game.board[pos.y][pos.x].has_mine then
			goto next_cell
		end

		for _, dir in ipairs(dirs) do
			local y2 = pos.y + dir.y
			local x2 = pos.x + dir.x
			if in_range(state, y2, x2) and
			   not in_ary(visited, y2, x2) and
			   not state.game.board[y2][x2].has_mine then
				table.insert(to_visit, {y=y2, x=x2})
			end
		end
		::next_cell::
	end

	return core.RC_SUCCESS
end

function core.flag_cell(state, player, y, x)
	if not in_range(state, y, x) then
		return core.RC_OUT_OF_RANGE
	end

	--if state.game.board[y][x].revealed then
	--	return core.RC_INVALID_MOVE
	--end

	-- in single player, remove your own flag, if desired
	if #state.players == 1 and state.game.board[y][x].flagged_by_player == player then
		state.game.board[y][x].flagged_by_player = nil
		state.players[player].score = state.players[player].score - FLAG_MINE_SUCCESS_SCORE
		state.game.cells_unrevealed = state.game.cells_unrevealed + 1
		state.game.mines_unrevealed = state.game.mines_unrevealed + 1
	-- can only flag unflagged cells
	elseif state.game.board[y][x].flagged_by_player == nil then
		if state.players == 1 then
			state.game.board[y][x].flagged_by_player = player
		else
			local score_change
			if state.game.board[y][x].has_mine == true then
				state.game.board[y][x].flagged_by_player = player
				score_change = FLAG_MINE_SUCCESS_SCORE
				state.game.mines_unrevealed = state.game.mines_unrevealed - 1
			else
				state.game.board[y][x].revealed = true
				score_change = FLAG_MINE_FAIL_SCORE
				-- TODO need to communicate this state to the user, so animations can be shown
			end
			state.game.cells_unrevealed = state.game.cells_unrevealed - 1
			state.players[player].score = state.players[player].score + score_change
		end
		-- Now that Conway's game of life is introduced,
		-- it is possible to flag cells that were previously revealed, but will
		-- contain a mine on the next life update.
		-- TODO: it would be better to simply make the UI code render revealed and flagged
		-- cells as flagged instead of revealed, but I don't want to
		-- make that change just yet in case it turns out to be more complicated
		state.game.board[y][x].revealed = false
	end

	return core.RC_SUCCESS
end

function core.reveal_neighbours(state, player, y, x)
	if not in_range(state, y, x) then
		return core.RC_OUT_OF_RANGE
	end
	if not state.game.board[y][x].revealed then
		return
	end

	local flags_or_revealed_mines_nearby = 0

	for _, dir in ipairs(dirs) do
		local y2 = y + dir.y
		local x2 = x + dir.x

		if in_range(state, y2, x2) then
			local cell = state.game.board[y2][x2]
			if cell.revealed and cell.has_mine or
			   cell.flagged_by_player ~= nil then
				flags_or_revealed_mines_nearby = flags_or_revealed_mines_nearby + 1
			end
		end
	end

	if flags_or_revealed_mines_nearby >= state.game.board[y][x].touching_mine_count then
		local activity = false
		for _, dir in ipairs(dirs) do
			local y2 = y + dir.y
			local x2 = x + dir.x

			if in_range(state, y2, x2) then
				local cell = state.game.board[y2][x2]
				print(string.format("cell{y=%d,x=%d}: revealed %s, has_mine %s, flagged_by_player %s", y2, x2, cell.revealed, cell.has_mine, cell.flagged_by_player))
				if not cell.revealed and
				   not cell.has_mine and
				   cell.flagged_by_player == nil then
					core.reveal_cell(state, player, y2, x2)
					activity = true
				end
			end
		end
		if activity then
			return core.RC_SUCCESS
		else
			-- TODO remove
			print(string.format("Can not auto reveal due to no activity"))
		end
	end

	return core.RC_CAN_NOT_AUTO_REVEAL
	
end

function core.clicked_cell(state, player, y, x)
	if not in_range(state, y, x) then
		return core.RC_OUT_OF_RANGE
	end

	if state.game.board[y][x].revealed then
		return core.reveal_neighbours(state, player, y, x)
	elseif state.game.board[y][x].flagged_by_player == nil then
		return core.reveal_cell(state, player, y, x)
	end


end


return core
