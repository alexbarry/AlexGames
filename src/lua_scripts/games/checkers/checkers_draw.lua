local draw = {}
local core = require("games/checkers/checkers_core")
local alex_c_api = require("alex_c_api")
local draw_more = require("libs/draw/draw_more")

local height = nil
local width  = nil
local square_size = nil
local piece_radius = nil
local square_padding = 1
local square_size_w_padding = nil
local offset_y = nil
local offset_x = nil


local SQUARE_BORDERS = '#aaaa55'
local SQUARE_BLACK   = '#000000'
local SQUARE_RED     = '#882222'
local SQUARE_BLACK_HIGHLIGHTED   = '#555555'
local SQUARE_RED_HIGHLIGHTED     = '#aa4444'

local PIECE_BLACK  = '#444444'
local PIECE_RED    = '#aa2222'
-- local PIECE_OUTLINE = '#333333'
local PIECE_RED_OUTLINE   = '#770000'
local PIECE_BLACK_OUTLINE = '#777777'

if alex_c_api.get_user_colour_pref() == "dark" then
	SQUARE_BORDERS = '#666600'
	SQUARE_BLACK   = '#000000'
	SQUARE_RED     = '#220000'
	SQUARE_BLACK_HIGHLIGHTED   = '#555555'
	SQUARE_RED_HIGHLIGHTED     = '#aa4444'
	
	PIECE_BLACK  = '#333333'
	PIECE_RED    = '#660000'
	PIECE_RED_OUTLINE   = '#770000'
	PIECE_BLACK_OUTLINE = '#777777'
end

function draw.init(height_arg, width_arg)
	height = height_arg
	width  = width_arg
	local board_square_count = math.min(core.BOARD_HEIGHT, core.BOARD_WIDTH)
	square_size = math.floor((math.min(height,width) - (board_square_count+1)*square_padding)*1.0 / board_square_count)
	square_size_w_padding = square_size + square_padding
	piece_radius = math.floor(square_size*0.8/2)

	offset_y = math.floor((height - (core.BOARD_HEIGHT+1)*square_padding - core.BOARD_HEIGHT*square_size)/2)
	offset_x = math.floor((width  - (core.BOARD_WIDTH +1)*square_padding - core.BOARD_WIDTH *square_size)/2)
end

local function get_colour_of_square(state, y, x)
	local is_red = core.get_square_colour(y,x)
	if state.selected_y == y and state.selected_x == x then
		if is_red then
			return SQUARE_RED_HIGHLIGHTED
		else
			return SQUARE_BLACK_HIGHLIGHTED
		end
	end
	if is_red then
		return SQUARE_RED
	else
		return SQUARE_BLACK
	end
end

function draw.draw_board(state)
	--alex_c_api.draw_rect('#000000', 0, 0, height, width)
	alex_c_api.draw_clear()
	-- Why do I need to add another 2 pixels here?? Otherwise the gold edge is cutoff
	alex_c_api.draw_rect(SQUARE_BORDERS, offset_y, offset_x,
	                     math.ceil(core.BOARD_HEIGHT*square_size + (core.BOARD_HEIGHT+2)*square_padding) + 2,
	                     math.ceil(core.BOARD_WIDTH*square_size  + (core.BOARD_WIDTH +2)*square_padding) + 2)
	for y=1,core.BOARD_HEIGHT do
		for x=1,core.BOARD_WIDTH do
			local colour = get_colour_of_square(state, y, x)
			alex_c_api.draw_rect(colour,
			                     offset_y + square_padding + (y-1)*square_size_w_padding,
			                     offset_x + square_padding + (x-1)*square_size_w_padding,
			                     offset_y + (y  )*square_size_w_padding,
                                 offset_x + (x  )*square_size_w_padding)

			local piece = state.board[y][x]
			local piece_colour = nil
			local piece_outline_colour = nil
			if core.piece_to_player(piece) == core.PLAYER1 then
				piece_colour = PIECE_RED
				piece_outline_colour = PIECE_RED_OUTLINE
			elseif core.piece_to_player(piece) == core.PLAYER2 then
				piece_colour = PIECE_BLACK
				piece_outline_colour = PIECE_BLACK_OUTLINE
			end

			if piece_colour ~= nil then
				local coord_y = offset_y + math.floor((y-1+0.5)*square_size_w_padding)
				local coord_x = offset_x + math.floor((x-1+0.5)*square_size_w_padding)
				alex_c_api.draw_circle(piece_colour, piece_outline_colour,
				                       coord_y,
				                       coord_x,
				                       piece_radius)
				if core.piece_is_king(piece) then
					draw_more.draw_graphic_ul("piece_king_icon",
					                       coord_y - piece_radius,
					                       coord_x - piece_radius,
					                       2*piece_radius,
					                       2*piece_radius)
				end
			end
		end
	end
	alex_c_api.draw_refresh()
end

function draw.coords_to_piece_idx(coord_y, coord_x)
	local idx_y = math.floor((coord_y - offset_y - square_padding) / square_size_w_padding) + 1
	local idx_x = math.floor((coord_x - offset_x - square_padding) / square_size_w_padding) + 1
	return { y = idx_y, x = idx_x }
end

return draw
