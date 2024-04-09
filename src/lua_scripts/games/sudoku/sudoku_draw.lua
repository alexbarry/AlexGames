local draw = {}

local cell_size = nil
local x_offset = nil
local num_choice_y_offset = nil
local num_choice_x_offset = nil

local OUTLINE_COLOUR = '#88888888'
local TEXT_COLOUR = '#000000'
local TEXT_SIZE   = 24
local TEXT_PADDING_Y = 5

local ORIG_CELL_COLOUR   = '#cccccc44'
local SELECTED_BG_COLOUR = '#0088cc33'

local CELL_LINE_THICKNESS = 1
local BOX_LINE_THICKNESS = 4

local core       = require("games/sudoku/sudoku_core")
local draw_shapes = require("libs/draw/draw_shapes")
local alexgames = require("alexgames")

local board_height = nil
local board_width  = nil

function draw.init(width, height)
	cell_size = math.floor(math.min(width,height)*1.0/(core.GAME_SIZE + 2.5))
	x_offset = math.floor((width - cell_size*core.GAME_SIZE)/2)
	board_height = height
	board_width  = width

	num_choice_y_offset = board_height - cell_size
	num_choice_x_offset = math.floor((board_width - (core.GAME_SIZE + 1)*cell_size)/2)
	return {
		selected = nil,
	}
end

local function draw_num_choices()
	local choices = { 'x' }
	for num=1,core.GAME_SIZE do
		table.insert(choices, string.format("%d", num))
	end
	for choice_idx, choice_val in ipairs(choices) do
		alexgames.draw_text(choice_val, TEXT_COLOUR,
		                     math.floor(num_choice_y_offset + TEXT_SIZE/2),
		                     num_choice_x_offset + math.floor((choice_idx-0.5)*cell_size),
		                     TEXT_SIZE, 0)
	end
end

function draw.draw_state(state, ui_state)
	alexgames.draw_clear()
	for y, row in ipairs(state.board) do
		for x, cell in ipairs(row) do
			draw_shapes.draw_rect_outline(OUTLINE_COLOUR, CELL_LINE_THICKNESS,
			                              (y-1)*cell_size, x_offset + (x-1)*cell_size,
			                              y*cell_size,     x_offset +  x*cell_size)
			local cell_bg = nil
			if cell.is_init_val then
				cell_bg = ORIG_CELL_COLOUR
			elseif ui_state.selected ~= nil and
			       ui_state.selected.y == y and
    			   ui_state.selected.x == x then
				cell_bg = SELECTED_BG_COLOUR
			end
			if cell_bg ~= nil then
				alexgames.draw_rect(cell_bg,
				                     (y-1)*cell_size, x_offset + (x-1)*cell_size,
				                     y*cell_size,     x_offset +  x*cell_size)
			end
			if cell.val ~= 0 then
				alexgames.draw_text(string.format("%d", cell.val), TEXT_COLOUR,
				                     math.floor((y-0.5)*cell_size + TEXT_SIZE/2),
				                     math.floor((x-0.5)*cell_size) + x_offset, 
				                     TEXT_SIZE, 0)
			end
		end
	end

	for y=1,core.BOX_SIZE-1 do
		alexgames.draw_line(OUTLINE_COLOUR, BOX_LINE_THICKNESS,
		                     y*core.BOX_SIZE*cell_size, x_offset + 0,
		                     y*core.BOX_SIZE*cell_size, x_offset + core.GAME_SIZE*cell_size)
	end
	for x=1,core.BOX_SIZE-1 do
		alexgames.draw_line(OUTLINE_COLOUR, BOX_LINE_THICKNESS,
		                     0,                        x_offset + x*core.BOX_SIZE*cell_size,
		                     core.GAME_SIZE*cell_size, x_offset + x*core.BOX_SIZE*cell_size)
	end

	if ui_state.selected ~= nil then
		draw_num_choices()
	end
	alexgames.draw_refresh()
end

function draw.get_cell_coords(pos_y, pos_x)
	local coords = {
		y = math.floor(pos_y/cell_size) + 1,
		x = math.floor((pos_x - x_offset)/cell_size) + 1,
	}

	if 1 <= coords.y and coords.y <= core.GAME_SIZE and
	   1 <= coords.x and coords.x <= core.GAME_SIZE then
		return coords
	else
		return nil
	end
end

function draw.get_num_choice(ui_state, pos_y, pos_x)
	if ui_state.selected == nil then
		return nil
	end
	if pos_y >= num_choice_y_offset then
		if num_choice_x_offset <= pos_x and pos_x <= num_choice_x_offset + (core.GAME_SIZE+1) * cell_size then
			local idx = math.floor((pos_x - num_choice_x_offset)/cell_size)
			return idx
		end
	end
end

function draw.handle_user_sel(ui_state, cell)
	if ui_state.selected ~= nil and
	   ui_state.selected.y == cell.y and
	   ui_state.selected.x == cell.x then
		ui_state.selected = nil
	else
		ui_state.selected = cell
	end
end

return draw
