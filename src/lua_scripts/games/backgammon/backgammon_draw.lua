-- Game:   Backgammon
-- author: Alex Barry (github.com/alexbarry)
local draw = {}
local alex_c_api = require("alex_c_api")
local draw_more    = require("libs/draw/draw_more")
local draw_shapes  = require("libs/draw/draw_shapes")
local draw_colours = require("libs/draw/draw_colours")
local utils = require("libs/utils")
local buttons = require("libs/ui/buttons")
local show_buttons_popup = require("libs/ui/show_buttons_popup")

local core = require("games/backgammon/backgammon_core")
local dice_draw = require("libs/dice/dice_draw")

local BACKGAMMON_COLS = 12
local BOARD_COLOUR = '#ec9a34'

local BOARD_TRI_WHITE = 'backgammon_triangle_white'
local BOARD_TRI_BLACK = 'backgammon_triangle_black'
local BOARD_TRI_HIGHLIGHT = 'backgammon_triangle_highlight'

local brightness_percent = nil
local dice_invert = nil


local HIGHLIGHT_OUTLINE_WIDTH = 3
local HIGHLIGHT_COLOUR   = '#ffff0066'
local HIGHLIGHT_OUTLINE = '#ffff00'
local DICE_BG_COLOUR = '#ffffff'
local DICE_USED_COLOUR = '#555555ee'

local LINE_COLOUR = '#444444'
local TEXT_COLOUR = '#ccccff'
local TEXT_SIZE   = 18
local TEXT_PADDING = 5
local MIDDLE_LINE_SIZE = '20'

local BTN_COLOUR_BG     = '#888888'
local BTN_COLOUR_FG     = '#000000'
local BTN_OUTLINE_WIDTH = 4

local board_height = 480
local board_width  = 480


local DICE_Y_SIZE = 50
local DICE_X_SIZE = 50
local DICE_PADDING = 10

local SIDE_BUTTONS_WIDTH = math.floor(((board_width - MIDDLE_LINE_SIZE)/2 - DICE_PADDING)/2)

local BEARING_OFF_BUTTON_WIDTH = SIDE_BUTTONS_WIDTH
local BEARING_OFF_BUTTON_HEIGHT = DICE_Y_SIZE

local DOUBLE_BTN_WIDTH  = SIDE_BUTTONS_WIDTH
local DOUBLE_BTN_HEIGHT = DICE_Y_SIZE

local middle_padding_target = 50

local DICE_Y_POS_START = math.floor((board_height - DICE_Y_SIZE)/2)
--local DICE_X_POS_START = board_width - 2*DICE_PADDING - 2*DICE_X_SIZE - BEARING_OFF_BUTTON_WIDTH - 2*DICE_PADDING
--local DICE_X_POS_START = math.floor(((board_width - middle_padding_target)/4 - DICE_X_SIZE))
local DICE_X_POS_START = 2*DICE_PADDING

local DICE_GROUP_Y_POS_START = DICE_Y_POS_START
local DICE_GROUP_X_POS_START = DICE_PADDING
local DICE_GROUP_Y_POS_END   = DICE_Y_POS_START + DICE_Y_SIZE
local DICE_GROUP_X_POS_END   = DICE_X_POS_START + 2 * DICE_X_SIZE + DICE_PADDING
local DICE2_OFFSET = 10

local TIMER_Y_POS = math.floor(board_height/2 - TEXT_SIZE/2 - TEXT_PADDING/2)
local TIMER_X_POS = math.floor(board_width/2 - MIDDLE_LINE_SIZE - TEXT_PADDING)
local TIMER_TEXT_ALIGN = alex_c_api.TEXT_ALIGN_RIGHT

local DBL_TEXT_Y_POS = math.floor(board_height/2 + TEXT_SIZE/2 + TEXT_PADDING/2)
local DBL_TEXT_X_POS = math.floor(board_width/2 - MIDDLE_LINE_SIZE - TEXT_PADDING)

local DBL_BTN_Y_POS = math.floor(board_height/2)
local DBL_BTN_X_POS = math.floor(board_width/2 + MIDDLE_LINE_SIZE/2 + DICE_PADDING + DOUBLE_BTN_WIDTH/2)
local DBL_BTN_Y_START = math.floor(DBL_BTN_Y_POS - DOUBLE_BTN_HEIGHT/2)
local DBL_BTN_Y_END   = math.floor(DBL_BTN_Y_POS + DOUBLE_BTN_HEIGHT/2)
local DBL_BTN_X_START = math.floor(DBL_BTN_X_POS - DOUBLE_BTN_WIDTH/2)
local DBL_BTN_X_END   = math.floor(DBL_BTN_X_POS + DOUBLE_BTN_WIDTH/2)

local BEARING_OFF_BUTTON_X_POS = board_width - DICE_PADDING - BEARING_OFF_BUTTON_WIDTH/2 
local BEARING_OFF_BUTTON_Y_POS = board_height/2
local BEARING_OFF_BUTTON_Y_START = math.floor(BEARING_OFF_BUTTON_Y_POS - BEARING_OFF_BUTTON_HEIGHT/2)
local BEARING_OFF_BUTTON_Y_END   = math.floor(BEARING_OFF_BUTTON_Y_POS + BEARING_OFF_BUTTON_HEIGHT/2)
local BEARING_OFF_BUTTON_X_START = BEARING_OFF_BUTTON_X_POS - BEARING_OFF_BUTTON_WIDTH/2 
local BEARING_OFF_BUTTON_X_END   = BEARING_OFF_BUTTON_X_POS + BEARING_OFF_BUTTON_WIDTH/2 

local board_triangle_width_incl_padding = math.floor((board_width - middle_padding_target)/BACKGAMMON_COLS)
local middle_padding = board_width - board_triangle_width_incl_padding * BACKGAMMON_COLS
local padding = 0
local board_triangle_width = board_triangle_width_incl_padding  - padding
local board_triangle_height = math.floor(board_height / 2.0 * 0.85)

local piece_radius = math.floor(board_triangle_width/2.0*0.9)
local MAX_PIECES_TO_DRAW_PER_DST = math.floor(board_triangle_height/(2*piece_radius))
local PIECE_TEXT_SIZE = math.floor(piece_radius)
local PIECE_TEXT_COLOUR = TEXT_COLOUR

local MIDDLE_OFFSET_Y = math.floor(piece_radius*1.5)
local MIDDLE_STACK_OFFSET_Y = math.floor(piece_radius*2/3)


local draw_state = nil

draw.BTN_ID_CANT_MOVE = "btn_cant_move"
draw.BTN_ID_UNDO = "btn_undo"
draw.BTN_ID_REDO = "btn_redo"
draw.BTN_ID_DOUBLE_REQUEST = "btn_double_request"
draw.BTN_ID_UNSELECT = "btn_unselect"
draw.BTN_ID_ROLL = "btn_roll"
draw.BTN_ID_ACK  = "btn_ack"

draw.POPUP_ID_DOUBLE_REQUEST = "popup_double_request"

local double_request_btns = {
	"Accept",
	"Decline",
}
draw.DOUBLE_REQUEST_BTN_ACCEPT  = 0
draw.DOUBLE_REQUEST_BTN_DECLINE = 1

local TEXT_DICE_LOADING = "Waiting..."

local PLAYER_IDX_TO_COLOUR_MAP = {
	-- [core.PLAYER_WHITE] = '#cc3333',
	-- [core.PLAYER_BLACK] = '#3333cc',
	[core.PLAYER_WHITE] = '#ffffff',
	[core.PLAYER_BLACK] = '#222222',
}

if alex_c_api.get_user_colour_pref() == "dark" then
	BOARD_COLOUR = '#4f2d0f'
	brightness_percent = 60
	DICE_BG_COLOUR = '#666666'
	TEXT_COLOUR = '#6666ff'
	if alex_c_api.is_feature_supported("draw_graphic_invert") then
		dice_invert = true
		DICE_BG_COLOUR = '#000000'
	end

	PLAYER_IDX_TO_COLOUR_MAP = {
		[core.PLAYER_WHITE] = '#aaaaaa',
		[core.PLAYER_BLACK] = '#222222',
	}
end

local function get_piece_text_colour(player_idx)
	if player_idx == core.PLAYER_WHITE then
		return '#000000'
	elseif player_idx == core.PLAYER_BLACK then
		return '#ffffff'
	else
		error(string.format("Unhandled player idx %s", player_idx), 2)
	end
end

local function should_highlight_dst(state, player, y_idx, x_idx)
	return (core.player_selecting_dst(state, player) and
	        core.valid_dst(state, player, state.player_selected, {y=y_idx, x=x_idx}).is_valid)
end

local function is_last_piece(state, player, coords, piece_idx)
	if piece_idx == MAX_PIECES_TO_DRAW_PER_DST then
		return true
	else
		return core.is_last_piece(state, player, coords, piece_idx)
	end
end

local function should_highlight_piece(state, coords, piece_idx)
	return (state.player_selected == nil and
	        core.piece_can_move(state, state.player_turn, coords) and
	        is_last_piece(state, state.player_turn, coords, piece_idx))
end

function draw.init(state, params)
	alex_c_api.create_btn(draw.BTN_ID_UNDO, "Undo", 1)
	alex_c_api.create_btn(draw.BTN_ID_REDO, "Redo", 1)
	alex_c_api.create_btn(draw.BTN_ID_CANT_MOVE, "Can't move", 2)
	alex_c_api.set_btn_enabled(draw.BTN_ID_CANT_MOVE, false)
	alex_c_api.set_btn_enabled(draw.BTN_ID_UNDO, false)
	alex_c_api.set_btn_enabled(draw.BTN_ID_REDO, false)

	draw_state = {}
	draw_state.buttons_state = buttons.new_state()

	local buttons_info_left = {
		{ id = draw.BTN_ID_ROLL, label = "Roll" },
		{ id = draw.BTN_ID_ACK,  label = "Ack"  },
	}

	for _, info in ipairs(buttons_info_left) do
		buttons.new_button(draw_state.buttons_state, {
			id             = info.id,
			text           = info.label,
			bg_colour      = BTN_COLOUR_BG,
			fg_colour      = BTN_COLOUR_FG,
			outline_colour = BTN_COLOUR_FG,
			outline_width  = BTN_OUTLINE_WIDTH,
			text_size      = TEXT_SIZE,
			padding        = 5,
			y_start        = DICE_GROUP_Y_POS_START,
			x_start        = DICE_GROUP_X_POS_START,
			y_end          = DICE_GROUP_Y_POS_END,
			x_end          = DICE_GROUP_X_POS_END,
			callback       = params.handle_btn_clicked,
		})
		buttons.set_visible(draw_state.buttons_state, info.id, false)
	end


	local buttons_info = {
		--{ id = draw.BTN_ID_ROLL,           label = "Roll"       },
		{ id = draw.BTN_ID_DOUBLE_REQUEST, label = "Double"     },
		{ id = draw.BTN_ID_UNSELECT,       label = "Unselect"   },
		{ id = draw.BTN_ID_CANT_MOVE,      label = "Can't move" },
	}

	for _, info in ipairs(buttons_info) do
		--print(string.format("added btn %s", info.id))
		buttons.new_button(draw_state.buttons_state, {
			id             = info.id,
			text           = info.label,
			bg_colour      = BTN_COLOUR_BG,
			fg_colour      = BTN_COLOUR_FG,
			outline_colour = BTN_COLOUR_FG,
			outline_width  = BTN_OUTLINE_WIDTH,
			text_size      = TEXT_SIZE,
			padding        = 5,
			y_start        = DBL_BTN_Y_START,
			x_start        = DBL_BTN_X_START,
			y_end          = DBL_BTN_Y_END,
			x_end          = DBL_BTN_X_END,
			callback       = params.handle_btn_clicked,
		})
		buttons.set_enabled(draw_state.buttons_state, info.id, false)
		buttons.set_visible(draw_state.buttons_state, info.id, false)
	end
	buttons.set_visible(draw_state.buttons_state, draw.BTN_ID_DOUBLE_REQUEST, true)
	buttons.set_enabled(draw_state.buttons_state, draw.BTN_ID_DOUBLE_REQUEST, true)

end

local function format_time(total_seconds)
	local minutes = math.floor(total_seconds/60)
	local seconds = math.floor(total_seconds) % 60
	return string.format('%2d:%02d', minutes, seconds)
end

local function get_double_text(state)
	return string.format("x%d", state.double_val)
end

local HIGHLIGHT_TYPE_NORMAL = 1
local HIGHLIGHT_TYPE_ALT    = 2

local function get_piece_highlight_type(state, player, coords, piece_idx)
	if should_highlight_piece(state, coords, piece_idx) then
		return HIGHLIGHT_TYPE_NORMAL
	elseif core.piece_is_selected(state, coords) and 
	       is_last_piece(state, state.player_turn, coords, piece_idx) then
		return HIGHLIGHT_TYPE_ALT
	else
		return nil
	end
end

local function draw_piece_highlight(state, highlight_type, player, piece_pos_y, piece_pos_x, piece_radius)
	local piece_highlight_fill    = nil
	local piece_highlight_outline = nil
	if highlight_type == HIGHLIGHT_TYPE_NORMAL then
		if player == state.player_turn then
			piece_highlight_fill    = draw_colours.HIGHLIGHT_FILL
			piece_highlight_outline = draw_colours.HIGHLIGHT_OUTLINE
		else
			piece_highlight_fill    = draw_colours.HIGHLIGHT_FILL_REMOTE
			piece_highlight_outline = draw_colours.HIGHLIGHT_OUTLINE_REMOTE
		end
	elseif highlight_type == HIGHLIGHT_TYPE_ALT then
		if player == state.player_turn then
			piece_highlight_fill    = draw_colours.ALT_HIGHLIGHT_FILL
			piece_highlight_outline = draw_colours.ALT_HIGHLIGHT_OUTLINE
		else
			piece_highlight_fill    = draw_colours.ALT_HIGHLIGHT_FILL_REMOTE
			piece_highlight_outline = draw_colours.ALT_HIGHLIGHT_OUTLINE_REMOTE
		end
	end

	if piece_highlight_fill ~= nil then
		alex_c_api.draw_circle(piece_highlight_fill, piece_highlight_outline,
		                       piece_pos_y, piece_pos_x, piece_radius + HIGHLIGHT_OUTLINE_WIDTH, HIGHLIGHT_OUTLINE_WIDTH)
	end
end

local function draw_triangle(state, player, y_pos, x_tri_pos,
				             board_triangle_width,
				             board_triangle_height, flip_y)

				local y1 = y_pos
				local y2 = y_pos
				local y3
				if flip_y then
					y3 = y_pos - board_triangle_height
				else
					y3 = y_pos + board_triangle_height
				end

				local x1 = x_tri_pos
				local x2 = x_tri_pos + board_triangle_width
				local x3 = x_tri_pos + board_triangle_width/2

				local fill_colour    = draw_colours.HIGHLIGHT_FILL
				local outline_colour = draw_colours.HIGHLIGHT_OUTLINE

				if player ~= state.player_turn then
					fill_colour    = draw_colours.HIGHLIGHT_FILL_REMOTE
					outline_colour = draw_colours.HIGHLIGHT_OUTLINE_REMOTE
				end

				alex_c_api.draw_triangle(fill_colour,
				                         y1, x1,
				                         y2, x2,
				                         y3, x3)
				draw_shapes.draw_triangle_outline(outline_colour, HIGHLIGHT_OUTLINE_WIDTH,
				                         y1, x1,
				                         y2, x2,
				                         y3, x3)
end


function draw.draw_state(state, session_id, player)
	alex_c_api.draw_clear()
	alex_c_api.draw_rect(BOARD_COLOUR, 0, 0, board_height, board_width)
	for y_idx=1,2 do
		local y_idx_draw = y_idx-1
		for x_idx=1,BACKGAMMON_COLS do
			local coords = {y = y_idx, x = x_idx }
			local x_idx_draw = x_idx-1
			local img_id
			if (x_idx + y_idx * (BACKGAMMON_COLS+1)) % 2 == 0 then
				img_id = BOARD_TRI_WHITE
			else
				img_id = BOARD_TRI_BLACK
			end
			local y_tri_pos = 0
			local y_pos = 0
			local x_pos = x_idx_draw * board_triangle_width_incl_padding + math.floor(padding/2)
			local x_tri_pos = x_pos
			local angle = 0
			local flip_y = false
			if y_idx == 2 then
				y_pos = board_height
				y_tri_pos = board_height - board_triangle_height
				--x_pos = x_pos + board_triangle_width
				-- angle = 180

				flip_y = true
				-- TODO why is this needed?? flip_y shouldn't affect the x pos, right?
				--x_tri_pos = x_pos - board_triangle_width
			end
			if x_idx > BACKGAMMON_COLS/2 then
				x_pos = x_pos + middle_padding
				x_tri_pos = x_tri_pos + middle_padding
			end

			draw_more.draw_graphic_ul(img_id, y_tri_pos, x_tri_pos,
			                        board_triangle_width, board_triangle_height,
			                        { angle_degrees = angle, flip_y = flip_y,
			                          brightness_percent = brightness_percent })
			if should_highlight_dst(state, player, y_idx, x_idx) then
				--[[
				draw_more.draw_graphic_ul(BOARD_TRI_HIGHLIGHT, y_pos, x_tri_pos,
				                        board_triangle_width, board_triangle_height,
				                        { angle_degrees = angle, flip_y = flip_y,
				                          brightness_percent = brightness_percent })
				--]]
				draw_triangle(state, player, y_pos, x_tri_pos,
				              board_triangle_width,
				              board_triangle_height, flip_y)
			end
			local piece_count = #state.board[y_idx][x_idx]
			for piece_idx, player_idx in ipairs(state.board[y_idx][x_idx]) do
				if piece_idx > MAX_PIECES_TO_DRAW_PER_DST then
					break
				end
				local player_colour = PLAYER_IDX_TO_COLOUR_MAP[player_idx]
				local sign_map = {
					[1] = 1,
					[2] = -1,
				}
				local piece_pos_x = x_pos + math.floor(board_triangle_width/2)
				local piece_pos_y = y_pos + sign_map[y_idx]*(piece_idx-1) * 2*piece_radius + piece_radius
				if y_idx == 2 then
					piece_pos_y = piece_pos_y - 2*piece_radius
				end
				alex_c_api.draw_circle(player_colour, LINE_COLOUR,
				                       piece_pos_y, piece_pos_x, piece_radius)
				if piece_idx == 1 then
					local extra_pieces = math.max(0, piece_count - MAX_PIECES_TO_DRAW_PER_DST)
					if extra_pieces > 0 then
						local extra_pieces_txt = string.format("+%d", extra_pieces)
						alex_c_api.draw_text(extra_pieces_txt, get_piece_text_colour(player_idx),
						                     piece_pos_y + PIECE_TEXT_SIZE/2, piece_pos_x,
						                     PIECE_TEXT_SIZE, alex_c_api.TEXT_ALIGN_CENTRE)
					end
				end

				local highlight_type = get_piece_highlight_type(state, player, coords, piece_idx)
				draw_piece_highlight(state, highlight_type, player, piece_pos_y, piece_pos_x, piece_radius)
			end
		end
	end

	alex_c_api.draw_line(LINE_COLOUR, MIDDLE_LINE_SIZE, 
	                     0,            board_width/2,
	                     board_height, board_width/2)

	for player_idx, pieces_in_middle in pairs(state.pieces_in_middle) do
		local pos_y_offset_sign = 1
		if player_idx == core.PLAYER_BLACK then
			pos_y_offset_sign = -1
		end
		local piece_pos_x = math.floor(board_width/2)
		local piece_pos_base_y = math.floor(board_height/2) + pos_y_offset_sign * MIDDLE_OFFSET_Y
		local player_colour = PLAYER_IDX_TO_COLOUR_MAP[player_idx]

		for i=1,#pieces_in_middle do
			local piece_pos_y = piece_pos_base_y + (i-1)*pos_y_offset_sign*MIDDLE_STACK_OFFSET_Y
			alex_c_api.draw_circle(player_colour, LINE_COLOUR,
			                       piece_pos_y, piece_pos_x,
			                       piece_radius)
			local highlight_type = get_piece_highlight_type(state, player, core.get_middle_coords(), i)
			draw_piece_highlight(state, highlight_type, player, piece_pos_y, piece_pos_x, piece_radius)
			--[[
			if should_highlight_piece(state, core.get_middle_coords(), i) then
				alex_c_api.draw_circle(HIGHLIGHT_COLOUR, HIGHLIGHT_OUTLINE,
				                       piece_pos_y, piece_pos_x, piece_radius)
			end
			--]]
		end
	end

	local dice_y_pos_start = DICE_Y_POS_START
	local dice_x_pos_start = DICE_X_POS_START

	if core.show_roll_button(state, player) or
	   core.show_ack_button(state, player) then
		dice_y_pos_start = dice_y_pos_start - DOUBLE_BTN_HEIGHT - DICE_PADDING
	end

	if state.dice_loading then
		alex_c_api.draw_text(TEXT_DICE_LOADING, TEXT_COLOUR,
		                     dice_y_pos_start + TEXT_SIZE/2 + DICE_Y_SIZE/2, dice_x_pos_start,
		                     TEXT_SIZE, alex_c_api.TEXT_ALIGN_LEFT)
		                     
	end

	if state.dice_vals ~= nil then
		if #state.dice_vals == 0 then
			-- do nothing
		elseif #state.dice_vals == 2 or #state.dice_vals == 1 then
			dice_draw.draw_dice(state.dice_vals,
			                    dice_y_pos_start, dice_x_pos_start,
			                    DICE_Y_SIZE, DICE_X_SIZE,
			                    {padding = DICE_PADDING, background_colour = DICE_BG_COLOUR,
			                     used_dice = state.used_dice, dice_used_overlay_colour = DICE_USED_COLOUR,
			                     brightness_percent = brightness_percent, invert = dice_invert })
		elseif #state.dice_vals == 4 then
			local dice2 = utils.ary_of(state.dice_vals[1], 2)
			local used_dice2_back  = { state.used_dice[1], state.used_dice[3] }
			local used_dice2_front = { state.used_dice[2], state.used_dice[4] }
			dice_draw.draw_dice(dice2,
			                    dice_y_pos_start - DICE2_OFFSET, dice_x_pos_start - DICE2_OFFSET,
			                    DICE_Y_SIZE, DICE_X_SIZE,
			                    {padding = DICE_PADDING, background_colour = DICE_BG_COLOUR,
			                     used_dice = used_dice2_back, dice_used_overlay_colour = DICE_USED_COLOUR,
			                     brightness_percent = brightness_percent, invert = dice_invert  })
			dice_draw.draw_dice(dice2,
			                    dice_y_pos_start, dice_x_pos_start,
			                    DICE_Y_SIZE, DICE_X_SIZE,
			                    {padding = DICE_PADDING, background_colour = DICE_BG_COLOUR,
			                     used_dice = used_dice2_front, dice_used_overlay_colour = DICE_USED_COLOUR,
			                     brightness_percent = brightness_percent, invert = dice_invert  })
		else
			error(string.format("Unexpected dice count %s", #state.dice_vals))
		end
	end

	if core.piece_can_bear_off(state, player, state.player_selected) then
		alex_c_api.draw_graphic("arrow",
		                        BEARING_OFF_BUTTON_Y_POS, BEARING_OFF_BUTTON_X_POS,
		                        BEARING_OFF_BUTTON_WIDTH, BEARING_OFF_BUTTON_HEIGHT)
	end


	if state.move_timer ~= nil then
		alex_c_api.draw_text(format_time(state.move_timer), TEXT_COLOUR,
		                     TIMER_Y_POS, TIMER_X_POS, TEXT_SIZE,
		                     TIMER_TEXT_ALIGN)
	end

	if state.double_val > 1 then
		alex_c_api.draw_text(get_double_text(state), TEXT_COLOUR,
		                     DBL_TEXT_Y_POS, DBL_TEXT_X_POS, TEXT_SIZE,
		                     TIMER_TEXT_ALIGN)
	end

	alex_c_api.set_btn_enabled(draw.BTN_ID_CANT_MOVE, state.player_cant_move)
	alex_c_api.set_btn_enabled(draw.BTN_ID_UNDO, alex_c_api.has_saved_state_offset(session_id, -1))
	alex_c_api.set_btn_enabled(draw.BTN_ID_REDO, alex_c_api.has_saved_state_offset(session_id,  1))


	local can_player_double = core.can_player_double_request(state, player)
	--buttons.set_visible(draw_state.buttons_state, draw.BTN_ID_DOUBLE_REQUEST, can_player_double)
	buttons.set_visible(draw_state.buttons_state, draw.BTN_ID_DOUBLE_REQUEST, can_player_double)
	--buttons.set_visible(draw_state.buttons_state, draw.BTN_ID_ROLL,           not state.player_rolled)

	buttons.set_visible(draw_state.buttons_state, draw.BTN_ID_ROLL, core.show_roll_button(state, player))
	buttons.set_visible(draw_state.buttons_state, draw.BTN_ID_ACK,  core.show_ack_button(state, player))

	local show_unselect_btn = (state.player_selected ~= nil and player == state.player_turn)
	buttons.set_visible(draw_state.buttons_state, draw.BTN_ID_UNSELECT, show_unselect_btn)
	buttons.set_enabled(draw_state.buttons_state, draw.BTN_ID_UNSELECT, true)

	buttons.draw(draw_state.buttons_state)

	alex_c_api.draw_refresh()
end

function draw.double_request(state)
	local requester_player_name = core.get_player_name(state.player_turn)
	local msg = string.format("Player %s has requested to increase double cube from " ..
	                          "%s to %s, do you accept?\n" ..
	                          "If you decline, you will forfeit this game.",
	                          requester_player_name, state.double_val, 2*state.double_val)
	show_buttons_popup.show_popup(draw.POPUP_ID_DOUBLE_REQUEST,
	                              "Double Request", msg,
	                              double_request_btns)
end

-- TODO need to handle selecting the middle too, at least when there are
-- pieces in it
function draw.screen_coords_to_board_coords(pos_y, pos_x, player_can_bear_off)
	local middle_l = math.floor((board_width - middle_padding)/2)
	local middle_r = math.floor((board_width + middle_padding)/2)

	--print(string.format("{%s, %s}; [%s %s] [%s %s]", pos_y, pos_x, BEARING_OFF_BUTTON_Y_START, BEARING_OFF_BUTTON_Y_END,
	--                                                 BEARING_OFF_BUTTON_X_START, BEARING_OFF_BUTTON_X_END))
	if player_can_bear_off and
	   BEARING_OFF_BUTTON_Y_START <= pos_y and pos_y <= BEARING_OFF_BUTTON_Y_END and
	   BEARING_OFF_BUTTON_X_START <= pos_x and pos_x <= BEARING_OFF_BUTTON_X_END then
		return core.get_bearing_off_coords()
	end


	if middle_l <= pos_x and pos_x <= middle_r then
		return core.get_middle_coords()
	end
	local y_idx
	if 0 <= pos_y and pos_y < board_triangle_height then
		y_idx = 1
	elseif board_height - board_triangle_height <= pos_y and pos_y <= board_height then
		y_idx = 2
	end

	local x_idx
	if 0 <= pos_x and pos_x <= (board_width - middle_padding)/2 then
		x_idx = math.floor(pos_x/board_triangle_width_incl_padding) + 1
	elseif (board_width + middle_padding)/2 <= pos_x and pos_x <= board_width then
		x_idx = math.floor((pos_x - middle_padding)/board_triangle_width_incl_padding) + 1
	else
		x_idx = nil
	end

	if y_idx ~= nil and x_idx ~= nil then
		return { y = y_idx, x = x_idx }
	end

	return nil
end

-- returned true if the user clicked a button
function draw.handle_user_clicked(pos_y, pos_x)
	local btn_id_clicked = buttons.on_user_click(draw_state.buttons_state, pos_y, pos_x)
	if btn_id_clicked ~= nil then
		return true
	else
		return false
	end
end

return draw
