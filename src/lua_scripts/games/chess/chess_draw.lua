-- Game:   Chess
-- Author: Alex Barry (github.com/alexbarry)

local draw = {}

local alex_c_api   = require("alex_c_api")
local draw_more    = require("libs/draw/draw_more")
local draw_shapes  = require("libs/draw/draw_shapes")
local draw_colours = require("libs/draw/draw_colours")

local core = require("games/chess/chess_core")


local board_height = nil
local board_width  = nil
local show_labels  = nil

local OUTLINE_WIDTH = 4
local cell_size    = nil
local piece_padding = 0
local border_padding = 20

local LABEL_COLOUR = '#000000'
local LABEL_FONT_SIZE = 12
-- the number of pixels taken up by the parts of a letter that are drawn below the line, like the "tail" of the letter "g"
local text_y_buffer = 4

--local CELL_COLOUR_WHITE = '#ffffff'
--local CELL_COLOUR_WHITE = '#dc802f'
--local CELL_COLOUR_BLACK = '#000000'
local CELL_COLOUR_WHITE = '#ffce9e'
local CELL_COLOUR_BLACK = '#d18b47'
local PIECE_SEL_HIGHLIGHT_OUTLINE = draw_colours.ALT_HIGHLIGHT_OUTLINE
local PIECE_SEL_HIGHLIGHT_COLOUR = draw_colours.ALT_HIGHLIGHT_FILL

local PIECE_SEL_HIGHLIGHT_OUTLINE_REMOTE = draw_colours.ALT_HIGHLIGHT_OUTLINE_REMOTE
local PIECE_SEL_HIGHLIGHT_COLOUR_REMOTE = draw_colours.ALT_HIGHLIGHT_FILL_REMOTE

local function get_cell_colour_white()
	if alex_c_api.get_user_colour_pref() == "very_dark" then
		return '#352215cc'
	elseif alex_c_api.get_user_colour_pref() == "dark" then
		return '#453225'
	else
		return CELL_COLOUR_WHITE
	end
end

local function get_cell_colour_black()
	if alex_c_api.get_user_colour_pref() == "very_dark" then
		return '#201000cc'
	elseif alex_c_api.get_user_colour_pref() == "dark" then
		return '#302005'
	else
		return CELL_COLOUR_BLACK
	end
end
local DST_HIGHLIGHT_OUTLINE        = draw_colours.HIGHLIGHT_OUTLINE
local DST_HIGHLIGHT_COLOUR         = draw_colours.HIGHLIGHT_FILL
local DST_HIGHLIGHT_OUTLINE_REMOTE = draw_colours.HIGHLIGHT_OUTLINE_REMOTE
local DST_HIGHLIGHT_COLOUR_REMOTE  = draw_colours.HIGHLIGHT_FILL_REMOTE

function draw.init(height, width, show_labels_arg)
	board_height = height
	board_width  = width

	show_labels = show_labels_arg
	if not show_labels then
		border_padding = 0
	end

	cell_size = math.floor((math.min(board_height, board_width) - 2*border_padding) / core.BOARD_SIZE)
end

local function is_cell_white(y, x)
	return (y*(core.BOARD_SIZE+1) + x) % 2 ~= 0
end

local function get_piece_graphic_id(player, piece_type, params)
	if params == nil then params = {} end

	if player == core.PLAYER_BLACK then
		if params.is_dark then
			if     piece_type == core.PIECE_ROOK   then return 'chess_rook_black_dark'
			elseif piece_type == core.PIECE_KNIGHT then return 'chess_knight_black_dark'
			elseif piece_type == core.PIECE_BISHOP then return 'chess_bishop_black_dark'
			elseif piece_type == core.PIECE_QUEEN  then return 'chess_queen_black_dark'
			elseif piece_type == core.PIECE_KING   then return 'chess_king_black_dark'
			elseif piece_type == core.PIECE_PAWN   then return 'chess_pawn_black_dark'
			else
				error(string.format("Unexpected piece_type: %s", piece_type))
			end
		else
			if     piece_type == core.PIECE_ROOK   then return 'chess_rook_black'
			elseif piece_type == core.PIECE_KNIGHT then return 'chess_knight_black'
			elseif piece_type == core.PIECE_BISHOP then return 'chess_bishop_black'
			elseif piece_type == core.PIECE_QUEEN  then return 'chess_queen_black'
			elseif piece_type == core.PIECE_KING   then return 'chess_king_black'
			elseif piece_type == core.PIECE_PAWN   then return 'chess_pawn_black'
			else
				error(string.format("Unexpected piece_type: %s", piece_type))
			end
		end
	elseif player == core.PLAYER_WHITE then
		if     piece_type == core.PIECE_ROOK   then return 'chess_rook_white'
		elseif piece_type == core.PIECE_KNIGHT then return 'chess_knight_white'
		elseif piece_type == core.PIECE_BISHOP then return 'chess_bishop_white'
		elseif piece_type == core.PIECE_QUEEN  then return 'chess_queen_white'
		elseif piece_type == core.PIECE_KING   then return 'chess_king_white'
		elseif piece_type == core.PIECE_PAWN   then return 'chess_pawn_white'
		else
			error(string.format("Unexpected piece_type: %s", piece_type))
		end
	else
		error(string.format("Unexpected player: %s", player))
	end
end

function draw.draw_coords_to_cell(y, x)
	y = y - border_padding
	x = x - border_padding
	local y_idx = math.floor(y/cell_size)+1
	local x_idx = math.floor(x/cell_size)+1

	if 1 <= x_idx and x_idx <= core.BOARD_SIZE and
	   1 <= y_idx and y_idx <= core.BOARD_SIZE then
		return { y=y_idx, x=x_idx }
	else
		return nil
	end
end

function draw_rect_at_pos(colour, outline_colour, y, x)
	cell_start_y = border_padding + (y-1)*cell_size
	cell_start_x = border_padding + (x-1)*cell_size

	cell_end_y   = border_padding + (y  )*cell_size
	cell_end_x   = border_padding + (x  )*cell_size
	alex_c_api.draw_rect(colour,
	                     cell_start_y, cell_start_x,
	                     cell_end_y  , cell_end_x)
	if outline_colour then
		draw_shapes.draw_rect_outline(outline_colour, OUTLINE_WIDTH,
		                     cell_start_y, cell_start_x,
		                     cell_end_y  , cell_end_x)
	end
end

local function get_col_label(col)
	return string.char(string.byte('a') + col-1)
end

local function get_row_label(row)
	return string.format('%d', row)
end

local function get_piece_brightness(player)
	if alex_c_api.get_user_colour_pref() == "very_dark" then
		return 35
	elseif alex_c_api.get_user_colour_pref() == "dark" then
		return 50
	else
		return 100
	end
end

local function draw_piece_graphic(player, piece_type, pos_y, pos_x, size_y, size_x)
	local img_id = get_piece_graphic_id(player, piece_type)
	local brightness = get_piece_brightness(player)
	local invert = false
	
	local brightness = get_piece_brightness(player)
	local user_colour_pref = alex_c_api.get_user_colour_pref()
	if user_colour_pref == "very_dark" or user_colour_pref == "dark" then
		if player == core.PLAYER_BLACK then
			img_id = get_piece_graphic_id(core.PLAYER_BLACK, piece_type, {is_dark = true})
			--img_id = get_piece_graphic_id(core.PLAYER_WHITE, piece_type)
			-- invert = true -- originally I just inverted the white piece, but safari doesn't support that
			brightness = 50
		end
	end
	draw_more.draw_graphic_ul(img_id, 
	                          pos_y, pos_x,
	                          size_y, size_x,
	                          { invert = invert, brightness_percent = brightness } )
end


function draw.draw_state(state, params)
	alex_c_api.draw_clear()
	alex_c_api.draw_rect('#000000', 0, 0, board_height, board_width)
	-- Draw checkerboard
	for y=1,core.BOARD_SIZE do
		for x=1,core.BOARD_SIZE do
			local cell_colour
			if is_cell_white(y,x) then
				cell_colour = get_cell_colour_white()
			else
				cell_colour = get_cell_colour_black()
			end
			draw_rect_at_pos(cell_colour, nil, y, x)
		end
	end

	-- Add labels to rows and columns
	if show_labels then
		for _, y_pos in ipairs({border_padding-text_y_buffer, border_padding + core.BOARD_SIZE*cell_size+LABEL_FONT_SIZE}) do
			for x=1,core.BOARD_SIZE do
				local label = get_col_label(x)
				alex_c_api.draw_text(label, LABEL_COLOUR,
				                     y_pos,  border_padding + math.floor(cell_size*(x-0.5)),
				                     LABEL_FONT_SIZE, 0)
			end
		end
	
		for _, x_pos_info in ipairs({{pos = border_padding, align=-1}, {pos = board_width-border_padding, align=1}}) do
			for y=1,core.BOARD_SIZE do
				local label = get_row_label(y)
				alex_c_api.draw_text(label, LABEL_COLOUR,
				                     border_padding + math.floor(cell_size*(y-0.5)), x_pos_info.pos,
				                     LABEL_FONT_SIZE, x_pos_info.align)
			end
		end
	end

	local highlight_colour = PIECE_SEL_HIGHLIGHT_COLOUR
	local highlight_outline = PIECE_SEL_HIGHLIGHT_OUTLINE
	local dst_highlight = DST_HIGHLIGHT_COLOUR
	local dst_outline = DST_HIGHLIGHT_OUTLINE

	if not params.local_multiplayer and params.player ~= state.player_turn then
		highlight_colour = PIECE_SEL_HIGHLIGHT_COLOUR_REMOTE
		highlight_outline = PIECE_SEL_HIGHLIGHT_OUTLINE_REMOTE
		dst_highlight = DST_HIGHLIGHT_COLOUR_REMOTE
		dst_outline = DST_HIGHLIGHT_OUTLINE_REMOTE
	end

	-- If a cell is selected, highlight it
	if state.selected ~= nil then
		draw_rect_at_pos(highlight_colour, highlight_outline, state.selected.y, state.selected.x)
	
		-- Also highlight the possible moves that could be made by the selected piece
		local possib_dsts = core.get_possib_dsts(state, state.selected)
		for _, possib_dst in ipairs(possib_dsts) do
			draw_rect_at_pos(dst_highlight, dst_outline, possib_dst.y, possib_dst.x)
		end
	end

	-- Finally, draw the pieces (on top of the highlights)
	for y=1,core.BOARD_SIZE do
		for x=1,core.BOARD_SIZE do
		local piece_id = state.board[y][x]
		local player = core.get_player(piece_id)
			if piece_id ~= core.EMPTY_PIECE_ID then
				local piece_type  = core.get_piece_type(piece_id)

				local piece_pos_y = border_padding + (y-1)*cell_size + piece_padding
				local piece_pos_x = border_padding + (x-1)*cell_size + piece_padding
				local piece_size_y = cell_size - 2*piece_padding
				local piece_size_x = cell_size - 2*piece_padding

				draw_piece_graphic(player, piece_type,
				                   piece_pos_y, piece_pos_x,
				                   piece_size_y, piece_size_x)
			end
		end
	end

	alex_c_api.draw_refresh()
end

return draw
