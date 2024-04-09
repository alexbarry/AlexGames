local alexgames = require("alexgames")

local lua_draw = {}

local cell_size_y = nil
local cell_size_x = nil

local present_colour = '#000000'
local absent_colour  = '#ffffff'

if alexgames.get_user_colour_pref() == "dark" then
	present_colour = '#888888'
	absent_colour  = '#000000'
end

function lua_draw.init(cell_size)
	cell_size_y = cell_size
	cell_size_x = cell_size
end

function lua_draw.update(board)
	alexgames.draw_clear()
	for y=1,#board do
		for x=1,#board[y] do
			local fill_colour
			if board[y][x] ~= 0 then
				fill_colour = present_colour
			else
				fill_colour = absent_colour
			end
			alexgames.draw_rect(fill_colour,
			                     (y-1)*cell_size_y, (x-1)*cell_size_x,
			                      y *  cell_size_y,  x *  cell_size_x)
		end
	end
	alexgames.draw_refresh()
end

function lua_draw.coords_to_cell_idx(coords_y, coords_x)
	return { y = 1 + math.floor(coords_y/cell_size_y),
	         x = 1 + math.floor(coords_x/cell_size_x) }
end

return lua_draw
