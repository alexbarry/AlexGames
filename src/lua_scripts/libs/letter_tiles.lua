local letter_tiles = {}

-- TODO:
--   * tear out a bunch of the way moving tiles works (maybe save it in a branch first)
--      * need to distinguish between "floating in row" and "floating in grid"
--   * change it so that when you pick up a tile from the row or grid, it sets the row or grid's value to 0
--   * held tile has metadata of where it came from
--
-- Then things should be a lot cleaner. It should only take an hour or so.
-- Then:
--   * implement "submit" button:
--       * check if placed tiles are in a line, with no gaps
--       * check if placed tiles form a valid word... that's it!
--   * maybe implement a "reset" button
--   * show a "tap to reveal next player's tiles" for local multiplayer
--   * serialize and save state in state browser, only when words are successfully placed.

local alexgames = require("alexgames")

local draw_shapes = require("libs/draw/draw_shapes")

letter_tiles.GROUP_TYPE_ROW  = 1
letter_tiles.GROUP_TYPE_GRID = 2

letter_tiles.LETTER_EMPTY = 0

function letter_tiles.draw_piece(letter, y, x, params, more_params)
	if letter == letter_tiles.LETTER_EMPTY then return end

	local y_start = y - params.size/2
	local x_start = x - params.size/2
	local y_end   = y + params.size/2
	local x_end   = x + params.size/2
	alexgames.draw_rect(params.background_colour,
	                     y_start, x_start,
	                     y_end,   x_end)

	draw_shapes.draw_rect_outline(params.outline_colour, params.line_width,
	                              y_start, x_start,
	                              y_end,   x_end)

	alexgames.draw_text(letter, params.text_colour,
	                     y + params.main_text_size/2, x,
	                     params.main_text_size,
	                     alexgames.TEXT_ALIGN_CENTRE)

	if params.show_score then
		local score_txt = string.format("%2d", params.get_letter_points(letter))
		alexgames.draw_text(score_txt, params.text_colour,
		                     y + params.size/2 - params.padding_small, x + params.size/2 - params.padding_small,
		                     params.score_text_size,
		                     alexgames.TEXT_ALIGN_RIGHT)
	end

	if more_params and more_params.is_tentative then
		draw_shapes.draw_rect_outline(params.highlight_colour, params.highlight_width,
	                                  y_start, x_start,
	                                  y_end,   x_end)
	end
end

local function get_tile_row_piece_pos(letter_row, i)
	local params = letter_row.params.tile_params
	y = letter_row.pos.y
	x = letter_row.pos.x + math.floor((i-0.5 - #letter_row.letters/2)*(params.size + letter_row.padding))

	return {
		-- centre position (used by draw_tile API)
		y = y,
		x = x,

		-- bound positions (used to check if touch/click is for this particular tile) 
		y_start = y - params.size/2,
		y_end   = y + params.size/2,

		x_start = x - params.size/2,
		x_end   = x + params.size/2,
	}
end

local function snap_pos_eq(snap_pos1, snap_pos2)
	if snap_pos1.group_type ~= snap_pos2.group_type then
		return false
	end

	if snap_pos1.group_type == letter_tiles.GROUP_TYPE_ROW then
		return (snap_pos1.row_idx == snap_pos2.row_idx and
		        snap_pos1.tile_idx == snap_pos2.tile_idx)
	elseif snap_pos1.group_type == letter_tiles.GROUP_TYPE_GRID then
		return (snap_pos1.grid_idx == snap_pos2.grid_idx and
		        snap_pos1.y_idx    == snap_pos2.y_idx and
		        snap_pos1.x_idx    == snap_pos2.x_idx)
	else
		error(string.format("unhandled group type %s", snap_pos1.group_type), 2)
	end

end



local function get_placed_tile_idx(tiles_state, src)
	if tiles_state == nil or tiles_state.placed_tiles == nil then error("placed tiles is nil", 2) end
	for idx, placed_tile_info in ipairs(tiles_state.placed_tiles) do
		if snap_pos_eq(placed_tile_info.pos, src) then
			return idx
		end
	end
end


local function get_letter_at_pos(tiles_state, pos)
	if pos == nil then return nil end
	local placed_tile_idx = get_placed_tile_idx(tiles_state, pos)
	if placed_tile_idx ~= nil then
		return tiles_state.placed_tiles[placed_tile_idx].letter
	elseif pos.group_type == letter_tiles.GROUP_TYPE_ROW then
		return tiles_state.letter_rows[pos.row_idx].letters[pos.tile_idx]
	elseif pos.group_type == letter_tiles.GROUP_TYPE_GRID then
		return tiles_state.grids[pos.grid_idx].tiles[pos.y_idx][pos.x_idx]
	else
		error(string.format("Unrecognized group_type %s", pos.group_type), 2)
	end
end

local function draw_offset(tiles_state, pos)
	if tiles_state.held_letter == nil or
	   (tiles_state.cursor_offset_y == 0 and
	    tiles_state.cursor_offset_y == 0) then
		return
	end

	alexgames.draw_line(tiles_state.offset_line_colour, 
	                     tiles_state.offset_line_width, 
	                     pos.y - tiles_state.cursor_offset_y,
	                     pos.x - tiles_state.cursor_offset_x,
	                     pos.y,
	                     pos.x)
	alexgames.draw_circle(tiles_state.offset_line_colour_fill, tiles_state.offset_line_colour,
	                       pos.y - tiles_state.cursor_offset_y,
	                       pos.x - tiles_state.cursor_offset_x,
	                       20)
end

function letter_tiles.draw_letter_rows(tiles_state)

	for row_idx, letter_row in ipairs(tiles_state.letter_rows) do
		local params = letter_row.params.tile_params
		for tile_idx, letter in ipairs(letter_row.letters) do
			if letter == letter_tiles.LETTER_EMPTY then
				goto next_letter
			end

			local pos = get_tile_row_piece_pos(letter_row, tile_idx)
			letter_tiles.draw_piece(letter, pos.y, pos.x, params)
			::next_letter::
		end

		if tiles_state.held_letter_snap_pos ~= nil and
		   tiles_state.held_letter_snap_pos.group_type == letter_tiles.GROUP_TYPE_ROW and
		   tiles_state.held_letter_snap_pos.row_idx == row_idx then
			local letter = tiles_state.held_letter
			local pos = tiles_state.held_letter_pos
			print(string.format("drawing held row letter %s at %s %s", letter, pos.y, pos.x))
			letter_tiles.draw_piece(letter, pos.y, pos.x, params)
		end
	end

	if tiles_state.held_letter ~= nil and
	   tiles_state.held_letter_snap_pos.group_type == letter_tiles.GROUP_TYPE_ROW then
		local letter_row = tiles_state.letter_rows[tiles_state.held_letter_snap_pos.row_idx]
		local letter = letter_row.letters[tiles_state.held_letter_snap_pos.tile_idx]
		local params = letter_row.params.tile_params
		local pos = tiles_state.held_letter_pos
		letter_tiles.draw_piece(letter, pos.y, pos.x, params)
		draw_offset(tiles_state, pos)
	end

end

function letter_tiles.get_filled_grid(tiles_state, grid_idx)
	local grid_info = tiles_state.grids[grid_idx]
	local filled_tiles = {}
	for y_idx, row in ipairs(grid_info.tiles) do
		local filled_row = {}
		for x_idx, letter in ipairs(row) do
			local cell = {
				is_tentative = false,
				letter       = letter_tiles.LETTER_EMPTY,
			}
			cell.letter = letter
			table.insert(filled_row, cell)
		end
		table.insert(filled_tiles, filled_row)
	end

	for _, placed_tile in ipairs(tiles_state.placed_tiles) do
		filled_tiles[placed_tile.pos.y_idx][placed_tile.pos.x_idx].letter = placed_tile.letter
		filled_tiles[placed_tile.pos.y_idx][placed_tile.pos.x_idx].is_tentative = true
	end

	return filled_tiles
end

function letter_tiles.draw_grids(tiles_state)
	for grid_idx, grid_info in ipairs(tiles_state.grids) do
		local params = grid_info.tile_params
		local padding = params.padding
		local y_size = letter_tiles.get_grid_y_size(#grid_info.tiles, params)
		local x_size = letter_tiles.get_grid_x_size(#grid_info.tiles[1], params)

		local grid_y_start = letter_tiles.get_grid_cell_pos(grid_info, 1, 1).y_start - padding
		local grid_x_start = letter_tiles.get_grid_cell_pos(grid_info, 1, 1).x_start - padding
		alexgames.draw_rect(grid_info.bg_colour,
		                     grid_y_start,          grid_x_start,
		                     grid_y_start + y_size, grid_x_start + x_size)
		for y_idx=1,#grid_info.tiles+1 do
			--local cell_spacing = params.size + params.padding
			--local y_pos = grid_info.y_pos + (y_idx-1) * cell_spacing
			local y_pos 
			if y_idx < #grid_info.tiles+1 then
				y_pos = letter_tiles.get_grid_cell_pos(grid_info, y_idx, 1).y_start - padding/2
			else
				y_pos = letter_tiles.get_grid_cell_pos(grid_info, #grid_info.tiles, 1).y_end
			end
			alexgames.draw_line(grid_info.line_colour,
			                     1,
				                 y_pos, grid_info.x_pos - padding,
				                 y_pos, grid_info.x_pos + x_size - padding)
		end
		for x_idx=1,#grid_info.tiles[1]+1 do
			--local cell_spacing = params.size + params.padding
			--local x_pos = grid_info.x_pos + (x_idx-1) * cell_spacing
			--local x_pos = letter_tiles.get_grid_cell_pos(grid_info, 1, x_idx).x_start - padding
			local x_pos 
			if x_idx < #grid_info.tiles[1]+1 then
				x_pos = letter_tiles.get_grid_cell_pos(grid_info, 1, x_idx).x_start - padding/2
			else
				x_pos = letter_tiles.get_grid_cell_pos(grid_info, 1, #grid_info.tiles).x_end
			end
			alexgames.draw_line(grid_info.line_colour,
			                     1,
				                 grid_info.y_pos - padding, x_pos,
				                 grid_info.y_pos + y_size - padding,  x_pos)
		end

		for y_idx, row in ipairs(letter_tiles.get_filled_grid(tiles_state, grid_idx)) do
			for x_idx, cell in ipairs(row) do
				if cell.letter ~= letter_tiles.LETTER_EMPTY then
					local pos = letter_tiles.get_grid_cell_pos(grid_info, y_idx, x_idx)
					letter_tiles.draw_piece(cell.letter, pos.y, pos.x, params, cell )
				end
			end
		end

		if tiles_state.held_letter ~= nil and
		   tiles_state.held_letter_snap_pos.group_type == letter_tiles.GROUP_TYPE_GRID and
		   tiles_state.held_letter_snap_pos.grid_idx   == grid_idx then
			local pos_idx = tiles_state.held_letter_snap_pos
			local pos = letter_tiles.get_grid_cell_pos(grid_info, pos_idx.y_idx, pos_idx.x_idx)
			letter_tiles.draw_piece(tiles_state.held_letter, pos.y, pos.x, params)
			draw_offset(tiles_state, pos)
		end
	end
end

function letter_tiles.draw(tiles_state)
	letter_tiles.draw_grids(tiles_state)
	letter_tiles.draw_letter_rows(tiles_state)
end

function letter_tiles.get_grid_y_size(y_count, tile_params)
	return y_count * (tile_params.size + tile_params.padding) -- + tile_params.padding
end

function letter_tiles.get_grid_x_size(x_count, tile_params)
	return x_count * (tile_params.size + tile_params.padding) -- + tile_params.padding
end

local function grid_pos_to_indexes(grid_info, pos)
	local params = grid_info.tile_params
	local y_idx = 1 + math.floor((pos.y - grid_info.y_pos)/(params.size + params.padding))
	local x_idx = 1 + math.floor((pos.x - grid_info.x_pos)/(params.size + params.padding))

	return { y = y_idx, x = x_idx }
end

function letter_tiles.get_grid_cell_pos(grid_info, y_idx, x_idx)
	local params = grid_info.tile_params
	local y_start = grid_info.y_pos + 0*params.padding + (y_idx-1)*(params.size + params.padding)
	local x_start = grid_info.x_pos + 0*params.padding + (x_idx-1)*(params.size + params.padding)

	return {
		y_start = y_start,
		x_start = x_start,

		y_end   = y_start + params.size,
		x_end   = x_start + params.size,

		--y = math.floor(y_start + params.padding/2 + params.size/2),
		--x = math.floor(x_start + params.padding/2 + params.size/2),
		y = math.floor(y_start + params.size/2),
		x = math.floor(x_start + params.size/2),
	}
end

function letter_tiles.new_state(params)
	local tiles_state = {
		letter_rows = {},
		grids       = {},

		-- Tiles that have been placed on the board, but not yet committed.
		placed_tiles = {},

		held_letter     = nil,
		held_letter_pos = nil,
		held_letter_origin = nil,

		cursor_offset_y = 0,
		cursor_offset_x = 0,

		touch_cursor_offset_y = params.touch_cursor_offset_y,
		touch_cursor_offset_x = params.touch_cursor_offset_x,
		offset_line_colour    = '#ff0000',
		offset_line_colour_fill = '#ff000088',
		offset_line_width     = 1,
	}

	return tiles_state
end

function letter_tiles.add_letter_row(tiles_state, letters, pos, params)
	local idx = #tiles_state.letter_rows + 1
	table.insert(tiles_state.letter_rows, {
		padding = 5,
		letters = nil,
		pos     = pos,
		params  = {
			tile_params = params,
		},
	})
	letter_tiles.set_row(tiles_state, idx, letters)
end


function letter_tiles.add_grid(tiles_state, params)
	if params.tile_params == nil then error("params.tile_params is nil", 2) end
	local grid_state = {
		tiles  = {},

		bg_colour   = params.bg_colour,
		line_colour = params.line_colour,
		tile_params = params.tile_params,
		y_pos = params.y_pos,
		x_pos = params.x_pos,

		-- TODO replace y_pos/x_pos above with y_start/x_start?
		y_start = params.y_pos,
		x_start = params.x_pos,
		y_end   = params.y_pos + letter_tiles.get_grid_y_size(params.y_count, params.tile_params),
		x_end   = params.x_pos + letter_tiles.get_grid_x_size(params.y_count, params.tile_params),
	}

	for y=1,params.y_count do
		local row = {}
		for x=1,params.x_count do
			table.insert(row, letter_tiles.LETTER_EMPTY)
		end
		table.insert(grid_state.tiles, row)
	end

	table.insert(tiles_state.grids, grid_state)
end

function letter_tiles.set_grid(tiles_state, grid_idx, grid_arg)
	local grid_info = tiles_state.grids[grid_idx]
	for y=1,#grid_info.tiles do
		for x=1,#grid_info.tiles[1] do
			grid_info.tiles[y][x] = grid_arg[y][x]
		end
	end
end

function letter_tiles.set_row(tiles_state, row_idx, letters)
	local output = "{"
	for _, letter in ipairs(letters) do
		if letter_idx ~= 1 then
			output = output .. ", "
		end
		output = output .. letter
	end
	output = output .. "}"
	print(string.format("letters in row are now: %s", output))

	local letters_copy = {}
	for _, letter in ipairs(letters) do
		table.insert(letters_copy, letter)
	end
		
	tiles_state.letter_rows[row_idx].letters = letters_copy
end

local function within_bounds(pos, bounds)
	return (bounds.y_start <= pos.y and pos.y <= bounds.y_end and
	        bounds.x_start <= pos.x and pos.x <= bounds.x_end)
end

local function get_tile_at_pos(tiles_state, pos, only_row_idx)
	for row_idx, row in ipairs(tiles_state.letter_rows) do
		if only_row_idx ~= nil and row_idx ~= only_row_idx then
			goto next_row_idx
		end
		for tile_idx, letter in ipairs(row.letters) do
			local tile_pos = get_tile_row_piece_pos(row, tile_idx)
			if within_bounds(pos, tile_pos) then
				return { group_type = letter_tiles.GROUP_TYPE_ROW, row_idx = row_idx, tile_idx = tile_idx, letter = letter }
			end
		end
		::next_row_idx::
	end

	for grid_idx, grid_info in ipairs(tiles_state.grids) do
		if within_bounds(pos, grid_info) then
			local indexes = grid_pos_to_indexes(grid_info, pos)
			--local letter = grid_info.tiles[indexes.y][indexes.x]
			--print(string.format("Found tile in grid! %d %d", indexes.y, indexes.x))
			return {
			    group_type = letter_tiles.GROUP_TYPE_GRID,
				grid_idx  = grid_idx,
				y_idx     = indexes.y,
				x_idx     = indexes.x,
				letter    = letter,
			} 
		end
	end

	return nil
end

local function clear_tile(tiles_state, src)
	local placed_tile_idx = get_placed_tile_idx(tiles_state, src)
	if placed_tile_idx ~= nil then
		print(string.format("removing placed tile %d", placed_tile_idx))
		table.remove(tiles_state.placed_tiles, placed_tile_idx)
	elseif src.group_type == letter_tiles.GROUP_TYPE_ROW then
		tiles_state.letter_rows[src.row_idx].letters[src.tile_idx] = letter_tiles.LETTER_EMPTY
	elseif src.group_type == letter_tiles.GROUP_TYPE_GRID then
		tiles_state.grids[src.grid_idx].tiles[src.y_idx][src.x_idx] = letter_tiles.LETTER_EMPTY
	else
		error(string.format("unknown group type %d", src.group_type))
	end
end

function letter_tiles.place_tile(tiles_state, letter, tile_drop_pos)
	if letter == nil then error("letter is nil") end
	if tile_drop_pos.group_type == letter_tiles.GROUP_TYPE_ROW then 
		local row = tiles_state.letter_rows[tile_drop_pos.row_idx]
		row.letters[tile_drop_pos.tile_idx] = letter
		print(string.format("Placed held tile in row %d, tile idx %d", tile_drop_pos.row_idx, tile_drop_pos.tile_idx))
	elseif tile_drop_pos.group_type == letter_tiles.GROUP_TYPE_GRID then 
		table.insert(tiles_state.placed_tiles, {
			letter = letter,
			pos    = tile_drop_pos,
		})
		print(string.format("Placed held tile in grid %d placed tiles, %d %d", tile_drop_pos.grid_idx, tile_drop_pos.y_idx, tile_drop_pos.x_idx))
	end

	tiles_state.held_letter          = nil
	tiles_state.held_letter_origin   = nil
	tiles_state.held_letter_pos      = nil
	tiles_state.held_letter_snap_pos = nil
end

local function snap_pos_to_str(pos_selected)
	if pos_selected.group_type == letter_tiles.GROUP_TYPE_ROW then
		return string.format("{row %d, tile %d}", pos_selected.row_idx, pos_selected.tile_idx)
	elseif pos_selected.group_type == letter_tiles.GROUP_TYPE_GRID then
		return string.format("{grid %d, y:%d, x:%d}", pos_selected.grid_idx, pos_selected.y_idx, pos_selected.x_idx)
	else
		error(string.format("unhandled group type %s", pos_selected.group_type), 2)
	end
end

local function update_offset(tiles_state, params)
	-- TODO make the real handle_mouse_evt pass params too
	if params and params.is_touch then
		tiles_state.cursor_offset_y = tiles_state.touch_cursor_offset_y
		tiles_state.cursor_offset_x = tiles_state.touch_cursor_offset_x
	else
		tiles_state.cursor_offset_y = 0
		tiles_state.cursor_offset_x = 0
	end
end

local function add_offset(tiles_state, pos)
	return {
		y = pos.y + tiles_state.cursor_offset_y,
	    x = pos.x + tiles_state.cursor_offset_x,
	}
end

function letter_tiles.handle_mouse_evt(tiles_state, evt_id, pos_y, pos_x, params)
	update_offset(tiles_state, params)
	local pos = { y = pos_y, x = pos_x }
	--pos = add_offset(tiles_state, pos)
	if evt_id == alexgames.MOUSE_EVT_DOWN then
		local pos_selected = get_tile_at_pos(tiles_state, pos)
		local letter = get_letter_at_pos(tiles_state, pos_selected)
		if pos_selected ~= nil and letter ~= nil and letter ~= letter_tiles.LETTER_EMPTY then
			pos_selected.letter = letter
			print(string.format("User clicked on %s", snap_pos_to_str(pos_selected)))
			local letter = get_letter_at_pos(tiles_state, pos_selected)
			local offset_pos = add_offset(tiles_state, pos)
			local offset_pos_selected = get_tile_at_pos(tiles_state, offset_pos)
			if offset_pos_selected == nil then
				offset_pos_selected = pos_selected
			end
			offset_pos_selected.letter = letter -- TODO clean this up, shouldn't need to do this? Or at least make it harder to forget to do
			tiles_state.held_letter_origin = pos_selected
			tiles_state.held_letter_snap_pos = offset_pos_selected
			tiles_state.held_letter_pos = offset_pos
			tiles_state.held_letter = letter

			clear_tile(tiles_state, pos_selected)
		end
	elseif evt_id == alexgames.MOUSE_EVT_UP then
		pos = add_offset(tiles_state, pos)
		local tile_drop_pos = get_tile_at_pos(tiles_state, pos)
		if tiles_state.held_letter ~= nil and tiles_state.held_letter ~= letter_tiles.LETTER_EMPTY then

			local dst = tile_drop_pos
			-- check if destination is valid and empty.
			-- if it's not, then put the tile back at its origin.
			if dst == nil or get_letter_at_pos(tiles_state, dst) ~= letter_tiles.LETTER_EMPTY then
				dst = tiles_state.held_letter_origin
			end

			letter_tiles.place_tile(tiles_state, tiles_state.held_letter, dst)
			tiles_state.held_letter_origin = nil
		end
	end
end

local function copy_list(list)
	local new_list = {}
	for _, elem in ipairs(list) do
		table.insert(new_list, elem)
	end
	return new_list
end

local function letter_list_to_str(list)
	local str = "{"
	for i, letter in ipairs(list) do
		if i == 1 then str = str .. ", " end
		str = str .. letter
	end
	return str .. "}"
end

local function get_offset_list(length)
	local offset_list = {}
	for i=1,length do
		table.insert(offset_list, i)
		table.insert(offset_list, -i)
	end
	return offset_list
end

local function find_closest_empty_space_in_row(tiles_state, pos)
	local row = tiles_state.letter_rows[pos.row_idx]
	--for tile_idx, tile_val in ipairs(row.letters) do
	for _, offset in ipairs(get_offset_list(#row.letters)) do
		print(string.format("trying offset %s", offset))
		local tile_idx = pos.tile_idx + offset
		local tile_val = row.letters[tile_idx]
		if tile_val == nil then
			print("tile is nil, next offset...")
			goto next_offset
		end
		print(string.format("tile is %s", tile_val))
		if tile_val == letter_tiles.LETTER_EMPTY then
			return { group_type = letter_tiles.GROUP_TYPE_ROW, row_idx = pos.row_idx, tile_idx = tile_idx }
		end

		::next_offset::
	end

	-- TODO remove this
	error("could not find empty space")
end

local function rearrange_tiles(tiles_state, src_tile_pos, dst_tile_pos)
	if dst_tile_pos.group_type ~= letter_tiles.GROUP_TYPE_ROW then
		error(string.format("rearrange_tiles only supports dst group type ROW, received %s", dst_tile_pos.group_type), 2)
	end

	print(string.format("rearrange_tiles( src %s, dst %s)",
	                    snap_pos_to_str(src_tile_pos),
	                    snap_pos_to_str(dst_tile_pos)))
	if src_tile_pos.group_type ~= letter_tiles.GROUP_TYPE_ROW or src_tile_pos.row_idx ~= dst_tile_pos.row_idx then
		src_tile_pos = find_closest_empty_space_in_row(tiles_state, dst_tile_pos)
		if src_tile_pos == nil then
			error(string.format("Could not find empty space in row %s", dst_tile_pos.row_idx))
		end
	end

	if src_tile_pos.tile_idx == dst_tile_pos.tile_idx then
		return
	end

	local letters = tiles_state.letter_rows[src_tile_pos.row_idx].letters
	--local new_letters = copy_list(letters)
	local new_letters = {}

	local move_src_idx = src_tile_pos.tile_idx
	local move_dst_idx = dst_tile_pos.tile_idx

	local src_idx = 1
	local dst_idx = 1
	while dst_idx <= #letters do
		if dst_idx == move_dst_idx then
			local letter = letters[move_src_idx]
			table.insert(new_letters, letter)
			goto next_dst_idx
		end

		if src_idx == move_src_idx then
			src_idx = src_idx + 1
		end

		
		table.insert(new_letters, letters[src_idx])
		src_idx = src_idx + 1
		::next_dst_idx::
		dst_idx = dst_idx + 1
	end

	assert(#new_letters == #letters)
	
	tiles_state.letter_rows[src_tile_pos.row_idx].letters = new_letters

end

function letter_tiles.handle_mousemove(tiles_state, pos_y, pos_x)
	local pos = { y = pos_y, x = pos_x }
	pos = add_offset(tiles_state, pos)
	if tiles_state.held_letter ~= nil then
		tiles_state.held_letter_pos = pos
		-- see what tile player is hovering their held tile over
		local dst_tile_pos = get_tile_at_pos(tiles_state, pos, tiles_state.held_letter_pos.row_idx)

		if dst_tile_pos then 
			if dst_tile_pos.group_type == letter_tiles.GROUP_TYPE_ROW and
			   get_letter_at_pos(tiles_state, dst_tile_pos) ~= letter_tiles.LETTER_EMPTY then 
				rearrange_tiles(tiles_state, tiles_state.held_letter_snap_pos, dst_tile_pos)
			end
			local letter = tiles_state.held_letter_snap_pos.letter
			tiles_state.held_letter_snap_pos = dst_tile_pos
			tiles_state.held_letter_snap_pos.letter = letter
		end
	end
end


function letter_tiles.get_placed_tiles(tiles_state)
	local placed_tiles_out = {}
	for _, placed_tile in ipairs(tiles_state.placed_tiles) do
		local pt = {
			letter = placed_tile.letter,
			y = placed_tile.pos.y_idx,
			x = placed_tile.pos.x_idx,
		}
		table.insert(placed_tiles_out, pt)
	end
	return placed_tiles_out
end

function letter_tiles.clear_placed_tiles(tiles_state)
	tiles_state.placed_tiles = {}
end

return letter_tiles
