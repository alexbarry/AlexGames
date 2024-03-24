
local core = {}

local MINE_PORTION = 0.20

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


local MIN_MAX_ZOOM_FACT = 3

core.MOVE_FLAG_CELL    = 1
core.MOVE_CLICK_CELL   = 2

core.RC_SUCCESS      =  0
core.RC_OUT_OF_RANGE = -1
core.RC_INVALID_MOVE = -2

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
		zoom_fact = 1.0,
		score    = 0,
	}
	return player_state
end


function core.new_state(player_count, game_height, game_width, cell_size)
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
			state.game.board[y][x].has_mine = (math.random() <= MINE_PORTION)
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

function core.handle_move(state, player, move, y, x)
	if move == core.MOVE_FLAG_CELL then
		return core.flag_cell(state, player, y, x)
	elseif move == core.MOVE_CLICK_CELL then
		return core.clicked_cell(state, player, y, x)
	else
		error(string.format("unhandled move type %s", move))
	end
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

	if state.game.board[y][x].revealed then
		return core.RC_INVALID_MOVE
	end

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
		for _, dir in ipairs(dirs) do
			local y2 = y + dir.y
			local x2 = x + dir.x

			if in_range(state, y2, x2) then
				local cell = state.game.board[y2][x2]
				if not( cell.revealed and cell.has_mine or
				   cell.flagged_by_player ~= nil) then
					core.reveal_cell(state, player, y2, x2)
				end
			end
		end
	end
	
	return core.RC_SUCCESS
end

function core.clicked_cell(state, player, y, x)
	if not in_range(state, y, x) then
		return core.RC_OUT_OF_RANGE
	end

	if state.game.board[y][x].revealed then
		core.reveal_neighbours(state, player, y, x)
	elseif state.game.board[y][x].flagged_by_player == nil then
		core.reveal_cell(state, player, y, x)
	end


	return core.RC_SUCCESS
end


return core
