local draw = {}

local ui   = require("games/blue/blue_ui")
local core = require("games/blue/blue_core")
local draw_shapes = require("libs/draw/draw_shapes")
local alex_c_api = require("alex_c_api")

local BTN_SELECT_BACKGROUND = '#55555588'

--local PIECE_OUTLINE_COLOUR = '#666666'
local PIECE_OUTLINE_COLOUR = '#8888aa'
--local PIECE_OUTLINE_COLOUR = '#ffffff' 


local HIGHLIGHT_COLOUR_BG      = '#ffff0066'
local HIGHLIGHT_COLOUR_BG_LIGHT = '#ffff0033'
local HIGHLIGHT_COLOUR_OUTLINE = '#ffff00'
local HIGHLIGHT_COLOUR_OUTLINE_TRANSPARENT = '#ffff0066'

local SELECTED_COLOUR_BG       = '#ffffff66'
local SELECTED_COLOUR_OUTLINE  = '#88cccc'

local PENALTY_TEXT_ICON_COLOUR_BG = '#66cc66'
local PENALTY_TEXT_ICON_COLOUR_OUTLINE = '#008800'

local COLOUR_MAP = {
	--[core.PIECES["white"]]  = { filled = "#ccffff", empty = "#ccffff33" },
	[core.PIECES["white"]]  = { filled = "#aacccc", empty = "#aacccc33" },
	[core.PIECES["black"]]  = { filled = "#000000", empty = "#00000033" },
	[core.PIECES["red"  ]]  = { filled = "#ff0000", empty = "#ff000033" },
	--[core.PIECES["yellow"]] = { filled = "#ffff00", empty = "#ffff0033" },
	-- making yellow a little darker to distinguish it from the highlight
	[core.PIECES["yellow"]] = { filled = "#ddc249", empty = "#ddc24966" },
	[core.PIECES["blue"]]   = { filled = "#0000ff", empty = "#0000ff33" },
}

local SQUARE_SIZE = 40
local CARD_SIZE = core.PIECE_COLOUR_COUNT * SQUARE_SIZE

local SMALL_SQUARE_SIZE = 15

local text_size = 18

local board_width  = 480
local board_height = 480
local padding = 5

local big_padding   = 5
local small_padding = 1


local big_pile_space_radius = math.floor(board_width/5)/2 
local pile_select_y_start = 0
local pile_select_x_start = 0

local small_pile_space_radius = math.floor(board_width/5*0.3)/2
local view_players_select_piles_y_start = board_height/2 - 5 * small_pile_space_radius
local view_players_select_piles_x_start = board_width/2 - 5 * small_pile_space_radius
local view_players_select_piles_y_end   = view_players_select_piles_y_start + 4 * small_pile_space_radius
local view_players_select_piles_x_end   = view_players_select_piles_x_start + 10 * small_pile_space_radius

local piece_select_pile_radius = 2*big_pile_space_radius

local piece_select_pile_pos = {
	y = big_padding + piece_select_pile_radius,
	x = math.floor(board_width/2),
}
local piece_select_pile_params = {
	text_size = 18,
	padding           = big_padding,
	pile_radius       = piece_select_pile_radius,
	piece_size_factor = 1/5,
	pile_space_radius = piece_select_pile_radius,
}

-- Only used when drawing _only_ the discard pile
-- (not when drawing all the piles, or when drawing the small pile button)
local discard_pile_params = {
	text_size = 24,
	-- Note that y_start/x_start are the centre of the pile
	y_start = padding + piece_select_pile_radius,
	x_start = board_width/2,

	padding           = big_padding,
	pile_radius       = piece_select_pile_radius,
	piece_size_factor = 1/5,
	pile_space_radius = piece_select_pile_radius,

}

local pile_select_pile_params = {
		padding = big_padding,
		pile_space_radius = big_pile_space_radius,
		pile_radius       = big_pile_space_radius - padding,
		y_start = pile_select_y_start,
		x_start = pile_select_x_start,
		piece_size_factor = 1/5,
}

local back_btn_y_start = view_players_select_piles_y_end + padding
local back_btn_x_start = padding
local back_btn_y_end   = back_btn_y_start + 40
local back_btn_x_end   = back_btn_x_start + 80

local function draw_game_card(state, params, player_idx)
	local card_size = core.PIECE_COLOUR_COUNT * params.square_size
	for y=1,core.PIECE_COLOUR_COUNT do
		for x=1,core.PIECE_COLOUR_COUNT do
			local square_colour_type = core.get_card_piece_type(y,x)
			local colour = COLOUR_MAP[square_colour_type]
			local y_pos = params.y_pos + (y-1)*params.square_size
			local x_pos = params.x_pos + (x-1)*params.square_size

			alex_c_api.draw_rect(colour.empty,
			                     y_pos, x_pos,
			                     y_pos + params.square_size, x_pos + params.square_size)

			if state.game_state.player_states[player_idx].card[y][x] ~= core.PIECE_EMPTY then
				alex_c_api.draw_circle(colour.filled, '#000000',
				                       math.floor(y_pos + params.square_size/2),
				                       math.floor(x_pos + params.square_size/2),
				                       math.floor(params.square_size*0.8/2))
			end
		end
	end
	draw_shapes.draw_rect_outline('#000000', 3,
	                              params.y_pos, params.x_pos,
	                              params.y_pos + card_size, params.x_pos + card_size)
end

local function get_game_staging_row_info(params, row_idx)
	return {
		y_start = params.y_pos + (row_idx-1)*params.square_size,
		y_end   = params.y_pos + (row_idx)*params.square_size,

		x_start = params.x_pos + (core.PIECE_COLOUR_COUNT-row_idx)*params.square_size,
		x_end   = params.x_pos + core.PIECE_COLOUR_COUNT*params.square_size,
	}
end

local function draw_game_staging_area(state, params, player_idx)
	for y=1,core.PIECE_COLOUR_COUNT do
		for x=1,y do
			-- x2 is x "flipped". x is position from the left,
			-- and x2 is position from the right.
			local x2 = (core.PIECE_COLOUR_COUNT - x + 1)
			local y_pos = params.y_pos + (y-1)*params.square_size
			local x_pos = params.x_pos + (x2-1)*params.square_size
			draw_shapes.draw_rect_outline('#000000', 1,
			                              y_pos, x_pos,
			                              y_pos + params.square_size, x_pos + params.square_size)
			local staging_row = state.game_state.player_states[player_idx].staging[y]
			-- y-x is:
			--         1
			--       1 2
			--     1 2 3
			--   1 2 3 4
			-- 1 2 3 4 5
			if staging_row.count > y - x then
				local square_colour_type = core.get_card_piece_type(y,x)
				local colour = COLOUR_MAP[staging_row.colour]
				alex_c_api.draw_circle(colour.filled, colour.outline,
				                       math.floor(y_pos + params.square_size/2),
				                       math.floor(x_pos + params.square_size/2),
				                       math.floor(params.square_size/2 - small_padding))
			end
		end
		local row_info = get_game_staging_row_info(params, y)
		if params.highlight_rows[y] then
			alex_c_api.draw_rect(HIGHLIGHT_COLOUR_BG,
			                     row_info.y_start, row_info.x_start,
			                     row_info.y_end,   row_info.x_end)
			local padding = 3
			draw_shapes.draw_rect_outline(HIGHLIGHT_COLOUR_OUTLINE_TRANSPARENT, 3,
			                     row_info.y_start + padding, row_info.x_start + padding,
			                     row_info.y_end   - padding, row_info.x_end   - padding)
		end
	end
end

local function get_player_params(pos)
	local main_player_text_size = 36
	local other_player_text_size = 18
	if pos == 1 then
		return {
			y_pos = board_height - CARD_SIZE - padding,
			x_pos = math.floor(board_width/2),
			square_size = SQUARE_SIZE,
			text_size = main_player_text_size,
		}
	elseif pos == 2 then
		return {
			y_pos = math.floor(board_height - 2*5*SMALL_SQUARE_SIZE)/2,
			x_pos = 5*SMALL_SQUARE_SIZE + padding,
			square_size = SMALL_SQUARE_SIZE,
			text_size = other_player_text_size,
		}
	elseif pos == 3 then
		return {
			y_pos = math.floor(board_height - 2*5*SMALL_SQUARE_SIZE)/2,
			x_pos = board_width - 5*SMALL_SQUARE_SIZE - padding,
			square_size = SMALL_SQUARE_SIZE,
			text_size = other_player_text_size,
		}
	elseif pos == 4 then
		return {
			y_pos = padding,
			x_pos = math.floor((board_width)/2),
			square_size = SMALL_SQUARE_SIZE,
			text_size = other_player_text_size,
		}
	else
		error(string.format("unhandled player pos %s", pos))
	end
	
end

local function draw_back_btn()
	draw_shapes.draw_rect_outline('#000000', 1,
	                              back_btn_y_start, back_btn_x_start,
	                              back_btn_y_end,   back_btn_x_end)
	alex_c_api.draw_rect(BTN_SELECT_BACKGROUND,
	                     back_btn_y_start, back_btn_x_start,
	                     back_btn_y_end,   back_btn_x_end)
	alex_c_api.draw_text("Back", '#000000',
	                     back_btn_y_start + (back_btn_y_end - back_btn_y_start)/2 + text_size/2,
	                     back_btn_x_start + (back_btn_x_end - back_btn_x_start)/2,
	                     text_size,
	                     0)
end

local function within_back_btn(y_pos, x_pos)
	return (back_btn_y_start <= y_pos and y_pos <= back_btn_y_end and
	        back_btn_x_start <= x_pos and x_pos <= back_btn_x_end)
end

local function get_main_player_card_params()
	local params = get_player_params(1)
	params.x_pos = params.x_pos - core.PIECE_COLOUR_COUNT * params.square_size
	return params
end

local function draw_player_state(state, params, player_idx)
	local card_params = {
		y_pos = params.y_pos,
		x_pos = params.x_pos,
		square_size = params.square_size,
	}
	draw_game_card(state, card_params, player_idx)
	local card_params = {
		highlight_rows = {},
		y_pos = params.y_pos,
		x_pos = params.x_pos - core.PIECE_COLOUR_COUNT * params.square_size,
		square_size = params.square_size,
	}

	for i=1,core.PIECE_COLOUR_COUNT do
		--if state.selected_pile ~= nil and
		if 
		   state.selected_piece_colour ~= nil then
			card_params.highlight_rows[i] = core.can_place_piece(state.game_state, player_idx, state.selected_pile, state.selected_piece_colour, i)
		else
			card_params.highlight_rows[i] = false
		end
	end
	draw_game_staging_area(state, card_params, player_idx)

	local score = state.game_state.player_states[player_idx].score
	alex_c_api.draw_text(string.format("%3d", score), '#000000',
	                     params.y_pos + params.text_size + params.square_size,
	                     params.x_pos - 3*params.square_size,
	                     params.text_size,
	                     -1)


end


local function pile_idx_to_pt(idx)
	local MAP = {
		[1] = { y=1, x=1},
		[2] = { y=1, x=2},
		[3] = { y=1, x=3},
		[4] = { y=1, x=4},
		[5] = { y=1, x=5},

		[6] = { y=2, x=1},
		[7] = { y=2, x=5},
		[8] = { y=2, x=2},
		[9] = { y=2, x=4},
	}
	if MAP[idx] == nil then
		error(string.format("pile idx %d not handled", idx))
	end

	return MAP[idx]
end

local function pile_coords_to_pos(y_start, x_start, y, x, pile_space_radius)
	local y_pos = y_start + pile_space_radius + (y-1) * 2*pile_space_radius
	local x_pos = x_start + pile_space_radius + (x-1) * 2*pile_space_radius
	return { y = y_pos, x = x_pos }
end

local function pile_idx_to_pos(idx, y_start, x_start, pile_space_radius)
	local pt = pile_idx_to_pt(idx)
	return pile_coords_to_pos(y_start, x_start, pt.y, pt.x, pile_space_radius)
end

local function piece_idx_to_pos(pile_pos, pile_params, piece_idx)
	local piece_radius = math.floor(pile_params.pile_radius*2*pile_params.piece_size_factor) - pile_params.padding - 2
	local dy = 1 + 2*(math.floor((piece_idx-1)/2) - 1)
	local dx = 1 + 2*(((piece_idx-1)%2)  - 1)
	local info = {
		radius = piece_radius,
		y = math.floor(pile_pos.y + dy * (piece_radius + pile_params.padding)),
		x = math.floor(pile_pos.x + dx * (piece_radius + pile_params.padding)),
	}
	return info
end

local function draw_pile(state, params, pile, pos, selected_colour)
	alex_c_api.draw_circle(BTN_SELECT_BACKGROUND, '#000000',
	                       pos.y, pos.x, params.pile_radius)
	if params.highlight_colour ~= nil then
		alex_c_api.draw_circle(params.highlight_colour_bg, params.highlight_colour,
		                       pos.y, pos.x, params.pile_radius + 2)
	end
	alex_c_api.draw_circle(BTN_SELECT_BACKGROUND, '#000000',
	                       pos.y, pos.x, params.pile_radius)
	for piece_idx, piece_colour_type in ipairs(pile) do
		local colour = COLOUR_MAP[piece_colour_type].filled
		local piece_pos = piece_idx_to_pos(pos, params, piece_idx)
		local highlight_colour_bg = nil
		local highlight_colour   = nil
		if state.ui_state == ui.UI_STATE_SELECT_PIECES and selected_colour == nil then
			highlight_colour_bg = HIGHLIGHT_COLOUR_BG
			highlight_colour    = HIGHLIGHT_COLOUR_OUTLINE
		elseif state.ui_state == ui.UI_STATE_SELECT_PIECES and selected_colour == piece_colour_type then
			highlight_colour_bg = SELECTED_COLOUR_BG
			highlight_colour    = SELECTED_COLOUR_OUTLINE
		end
		if highlight_colour ~= nil then
			alex_c_api.draw_circle(highlight_colour, highlight_colour,
			                       piece_pos.y, piece_pos.x,
			                       math.floor(piece_pos.radius/2))
		end
		alex_c_api.draw_circle(colour, '#000000',
		                       piece_pos.y, piece_pos.x, piece_pos.radius)
		if highlight_colour ~= nil then
			alex_c_api.draw_circle(highlight_colour_bg, highlight_colour,
			                       piece_pos.y, piece_pos.x,
			                       math.floor(piece_pos.radius/2))
		end

	end
end

local function get_discard_pile_info(params)
	local info = {
		y_start = params.y_start - params.pile_space_radius + padding,
		x_start = params.x_start - params.pile_space_radius + padding,
	}
	info.y_end = info.y_start + 2*params.pile_space_radius - 2*padding
	info.x_end = info.x_start + 2*params.pile_space_radius - 2*padding

	info.pile_space_radius  = params.pile_space_radius 
	info.pile_radius        = params.pile_radius 
	info.piece_size_factor  = params.piece_size_factor 
	info.padding            = params.padding

	return info
end

local function get_discard_piece_info(params, distinct_colours, x_idx, piece_idx)
	local discard_centre = {
		y = params.y_start + params.pile_space_radius - params.padding,
		x = params.x_start + params.pile_space_radius - params.padding,
	}
	local piece_info = piece_idx_to_pos(discard_centre, params, 1)
	discard_centre.y = discard_centre.y - piece_info.radius

	local piece_group_offset = {}
	if x_idx == 1 then
		piece_group_offset.y = 0
		piece_group_offset.x = 0
	else
		if x_idx == 2 or x_idx == 3 then
			piece_group_offset.y = -2*piece_info.radius
		elseif x_idx == 4 or x_idx == 5 then
			piece_group_offset.y = 2*piece_info.radius
		end

		if x_idx == 2 or x_idx == 4 then
			piece_group_offset.x = -2*piece_info.radius
		elseif x_idx == 3 or x_idx == 5 then
			piece_group_offset.x = 2*piece_info.radius
		end
	end

	local piece_offset_y = math.floor(piece_info.radius*2/3)

	return {
		y = discard_centre.y + piece_group_offset.y + piece_idx*piece_offset_y,
		x = discard_centre.x + piece_group_offset.x,
		radius = piece_info.radius,
	}
end

local function default_discard_pile_highlight_params()
	return {
		highlight_bg         = false,
		highlight_selectable = false,
		highlighted_colour   = nil,
	}
end

local function draw_discard_pile(state, params, highlight_params)
		local pile_info = get_discard_pile_info(params)
		if highlight_params.highlight_bg then
			alex_c_api.draw_rect(HIGHLIGHT_COLOUR_BG,
			                    pile_info.y_start, pile_info.x_start,
			                    pile_info.y_end,   pile_info.x_end)
			draw_shapes.draw_rect_outline('#000000', 1,
			                    pile_info.y_start, pile_info.x_start,
			                    pile_info.y_end,   pile_info.x_end)
			draw_shapes.draw_rect_outline(HIGHLIGHT_COLOUR_OUTLINE_TRANSPARENT, 3,
			                    pile_info.y_start, pile_info.x_start,
			                    pile_info.y_end,   pile_info.x_end)
		end
		local discarded_colours = {}
		for _, discarded_colour_type in ipairs(state.game_state.discard_pile) do
			if discarded_colours[discarded_colour_type] == nil then
				discarded_colours[discarded_colour_type] = 0
			end
			discarded_colours[discarded_colour_type] = discarded_colours[discarded_colour_type] + 1
		end
		local distinct_colours = 0
		for _, num_colours in pairs(discarded_colours) do
			distinct_colours = distinct_colours + 1
		end

		local radius = 0
		local x_idx = 1
		for colour_type, count in pairs(discarded_colours) do
			local colour = COLOUR_MAP[colour_type]
			for piece_idx=1,count do
				local discard_piece_info = get_discard_piece_info(pile_info, distinct_colours, colour_type, piece_idx)
				radius = discard_piece_info.radius
				-- I want a slight grey outline so that you can count the number of
				-- black pieces when they're stacked in the middle
				alex_c_api.draw_circle(PIECE_OUTLINE_COLOUR, PIECE_OUTLINE_COLOUR,
				                       discard_piece_info.y,
				                       discard_piece_info.x,
				                       discard_piece_info.radius)

				alex_c_api.draw_circle(colour.filled, PIECE_OUTLINE_COLOUR,
				                       discard_piece_info.y,
				                       discard_piece_info.x,
				                       discard_piece_info.radius - 1)
				local highlight_colour_bg
				local highlight_colour_outline
				if colour_type == highlight_params.highlighted_colour then
					highlight_colour_bg      = SELECTED_COLOUR_BG
					highlight_colour_outline = SELECTED_COLOUR_OUTLINE
				elseif highlight_params.highlight_selectable then
					highlight_colour_bg      = HIGHLIGHT_COLOUR_BG
					highlight_colour_outline = HIGHLIGHT_COLOUR_OUTLINE
				end
				if highlight_colour_bg ~= nil then
					alex_c_api.draw_circle(highlight_colour_bg, highlight_colour_outline,
					                       discard_piece_info.y,
					                       discard_piece_info.x,
					                       math.floor(discard_piece_info.radius/2))
				end
			end
			x_idx = x_idx + 1
		end
		if state.game_state.discard_penalty then
			local text_size = params.text_size
			local penalty_text_pos = {
				y = pile_info.y_end + text_size + radius,
				x = pile_info.x_start + math.floor((pile_info.x_end - pile_info.x_start)/2),
			}
			alex_c_api.draw_circle(PENALTY_TEXT_ICON_COLOUR_BG, PENALTY_TEXT_ICON_COLOUR_OUTLINE,
			                       penalty_text_pos.y - text_size/2,
			                       penalty_text_pos.x,
			                       text_size)
			local highlight_colour_bg      = nil
			local highlight_colour_outline = nil
			if highlight_params.highlighted_colour ~= nil then
				highlight_colour_bg      = SELECTED_COLOUR_BG
				highlight_colour_outline = SELECTED_COLOUR_OUTLINE
			end
			if highlight_colour_bg ~= nil then
				alex_c_api.draw_circle(highlight_colour_bg, highlight_colour_outline,
				                       penalty_text_pos.y - text_size/2,
				                       penalty_text_pos.x,
				                       math.floor(text_size/2))
			end

			alex_c_api.draw_text("-1", "#000000", penalty_text_pos.y, penalty_text_pos.x, text_size, 0)
		end
end

local function get_pile_params(is_big)
	local pile_space_radius
	local pile_radius
	local y_start
	local x_start
	local piece_size_factor
	local padding
	local text_size

	if is_big then
		padding = big_padding
		pile_space_radius = big_pile_space_radius
		pile_radius       = pile_space_radius - padding
		y_start = pile_select_y_start
		x_start = pile_select_x_start
		piece_size_factor = 1/5
		text_size = 18
	else
		padding = small_padding
		pile_space_radius = small_pile_space_radius 
		pile_radius       = pile_space_radius - small_padding
		y_start = view_players_select_piles_y_start
		x_start = view_players_select_piles_x_start

		piece_size_factor = 1/3
		text_size = 8
	end
	local params = {
		y_start           = y_start,
		x_start           = x_start,
		padding           = padding,
		pile_radius       = pile_radius,
		pile_space_radius = pile_space_radius,
		piece_size_factor = piece_size_factor,
		text_size         = text_size,
	}
	return params
end

local function get_discard_pile_params(is_big)
	local params = get_pile_params(is_big)
	local pos = pile_coords_to_pos(params.y_start, params.x_start, 2, 3, params.pile_space_radius)
	params.y_start = pos.y
	params.x_start = pos.x
	return params
end

-- Draws the 5-9 circles with pieces in them,
-- and the discarded pieces (with -1) if present.
--
-- Called both when:
-- * is_big=false (drawing this small),  as a button in thre centre of the screen, and
-- * is_big=true  (drawing this larger), to select individual piles
local function draw_piles(state, is_big)
	local params = get_pile_params(is_big)
	if not is_big then
		alex_c_api.draw_rect(BTN_SELECT_BACKGROUND, params.y_start, params.x_start,
		                     view_players_select_piles_y_end, view_players_select_piles_x_end)
		draw_shapes.draw_rect_outline('#000000', 1,
		                              params.y_start, params.x_start,
		                              view_players_select_piles_y_end, view_players_select_piles_x_end)
		alex_c_api.draw_rect(HIGHLIGHT_COLOUR_BG, params.y_start, params.x_start,
		                     view_players_select_piles_y_end, view_players_select_piles_x_end)
		draw_shapes.draw_rect_outline(HIGHLIGHT_COLOUR_OUTLINE, 3,
		                              params.y_start, params.x_start,
		                              view_players_select_piles_y_end, view_players_select_piles_x_end)
	end
	local tmp_info = get_discard_piece_info(params, 1, 1, 1)
	params.piece_radius = params
	for i, pile in pairs(state.game_state.piles) do
		local pos = pile_idx_to_pos(i, params.y_start, params.x_start, params.pile_space_radius)
			
		if state.ui_state == ui.UI_STATE_SELECT_PILE then
			params.highlight_colour    = HIGHLIGHT_COLOUR_OUTLINE
			params.highlight_colour_bg = HIGHLIGHT_COLOUR_BG
		end
		draw_pile(state, params, pile, pos)
	end

	if #state.game_state.discard_pile > 0 then
		local params = get_discard_pile_params(is_big)
		local highlight_params = default_discard_pile_highlight_params()
		if state.ui_state == ui.UI_STATE_SELECT_PILE then
			highlight_params.highlight_bg = true
		end
		draw_discard_pile(state, params, highlight_params)
	end
end

local function draw_player_states(state)
	alex_c_api.draw_clear()

	for player_idx, _ in ipairs(state.game_state.player_states) do
		local player_pos = player_idx -- TODO
		local params = get_player_params(player_pos)
		draw_player_state(state, params, player_idx)
	end
	draw_piles(state, false)
end

local function get_discard_piece_count(game_state, colour_type)
	local count = 0
	for _, discard_piece_colour in ipairs(game_state.discard_pile) do
		if colour_type == discard_piece_colour then
			count = count + 1
		end
	end
	return count
end

local function within_circle_bounding_box(circle_info, pos_y, pos_x)
	return (circle_info.y - circle_info.radius <= pos_y and pos_y <= circle_info.y + circle_info.radius and
	        circle_info.x - circle_info.radius <= pos_x and pos_x <= circle_info.x + circle_info.radius)
end

local function get_player_row_selected(y_pos, x_pos)
	for row_idx=1,core.PIECE_COLOUR_COUNT do
		local params = get_main_player_card_params()
		local row_info = get_game_staging_row_info(params, row_idx)
		if row_info.y_start <= y_pos and y_pos <= row_info.y_end and
		   row_info.x_start <= x_pos and x_pos <= row_info.x_end then
			return row_idx
		end
	end
end

function draw.pos_to_action(state, y_pos, x_pos)
	if state.ui_state == ui.UI_STATE_VIEW_OTHER_PLAYERS then
		y_start = view_players_select_piles_y_start
		x_start = view_players_select_piles_x_start
		y_end   = view_players_select_piles_y_end
		x_end   = view_players_select_piles_x_end

		if y_start <= y_pos and y_pos <= y_end and
		   x_start <= x_pos and x_pos <= x_end then
			return {
				action         = ui.ACTION_CHANGE_UI_STATE,
				action_arg_idx = ui.UI_STATE_SELECT_PILE,
			}
		end
	elseif state.ui_state == ui.UI_STATE_SELECT_PILE then
		if within_back_btn(y_pos, x_pos) then
			return {
				action         = ui.ACTION_CHANGE_UI_STATE,
				action_arg_idx = ui.UI_STATE_VIEW_OTHER_PLAYERS,
			}
		end
		for i, pile in pairs(state.game_state.piles) do
			local pos = pile_idx_to_pos(i, pile_select_y_start, pile_select_x_start, big_pile_space_radius)
			if pos.y - big_pile_space_radius <= y_pos and y_pos <= pos.y + big_pile_space_radius and
			   pos.x - big_pile_space_radius <= x_pos and x_pos <= pos.x + big_pile_space_radius then
				return {
					action         = ui.ACTION_SELECT_PILE,
					action_arg_idx = i,
				}
			end
		end

		if #state.game_state.discard_pile > 0 then
			local tmp_params = get_discard_pile_params(get_pile_params(true))
			local discard_pile_info = get_discard_pile_info(tmp_params)
			if discard_pile_info.y_start <= y_pos and y_pos <= discard_pile_info.y_end and
			   discard_pile_info.x_start <= x_pos and x_pos <= discard_pile_info.x_end then
				return {
						action         = ui.ACTION_SELECT_DISCARD_PILE,
						action_arg_idx = nil,
				}
			end
		end
	elseif state.ui_state == ui.UI_STATE_SELECT_PIECES then
		if within_back_btn(y_pos, x_pos) then
			return {
				action         = ui.ACTION_CHANGE_UI_STATE,
				action_arg_idx = ui.UI_STATE_SELECT_PILE,
			}
		end

		for piece_idx, piece_colour_type in ipairs(state.game_state.piles[state.selected_pile]) do
			local piece_pos = piece_idx_to_pos(piece_select_pile_pos, piece_select_pile_params, piece_idx)
			if piece_pos.y - piece_pos.radius <= y_pos and y_pos <= piece_pos.y + piece_pos.radius and
			   piece_pos.x - piece_pos.radius <= x_pos and x_pos <= piece_pos.x + piece_pos.radius then
				return {
					action = ui.ACTION_SELECT_PIECE,
					action_arg_idx = piece_colour_type,
				}
			end
		end

		local selected_row_idx = get_player_row_selected(y_pos, x_pos)
		if selected_row_idx ~= nil then
			return {
				action         = ui.ACTION_PLACE_PIECE,
				action_arg_idx = selected_row_idx,
			}
		end
	elseif state.ui_state == ui.UI_STATE_SELECT_DISCARDED_PIECES then
		if within_back_btn(y_pos, x_pos) then
			return {
				action         = ui.ACTION_CHANGE_UI_STATE,
				action_arg_idx = ui.UI_STATE_SELECT_PILE,
			}
		end

		local idx = 1
		for _, colour_type in pairs(core.PIECES) do
			for same_piece_idx=1,get_discard_piece_count(state.game_state, colour_type) do
	
				local pile_info = get_discard_pile_info(discard_pile_params)
				local discard_piece_info = get_discard_piece_info(pile_info, core.PIECE_COLOUR_COUNT, colour_type, same_piece_idx)
				if within_circle_bounding_box(discard_piece_info, y_pos, x_pos) then
					return {
						action         = ui.ACTION_SELECT_DISCARD_PIECE_COLOUR,
						action_arg_idx = colour_type,
					}
				end
			end
			idx = idx + 1
		end

		local selected_row_idx = get_player_row_selected(y_pos, x_pos)
		if selected_row_idx ~= nil then
			return {
				action         = ui.ACTION_PLACE_PIECE,
				action_arg_idx = selected_row_idx,
			}
		end

	end

	return nil
end

function draw.draw_state(state, player)
	-- alex_c_api.draw_rect('#ffffff', 0, 0, 480, 480)
	alex_c_api.draw_clear()
	if state.ui_state == ui.UI_STATE_VIEW_OTHER_PLAYERS then
		draw_player_states(state)
	elseif state.ui_state == ui.UI_STATE_SELECT_PILE then
		draw_piles(state, true)
		local params = get_player_params(1)
		draw_player_state(state, params, player)
		draw_back_btn()
	elseif state.ui_state == ui.UI_STATE_SELECT_PIECES then
		local pile = state.game_state.piles[state.selected_pile]
		draw_pile(state, piece_select_pile_params, pile, piece_select_pile_pos, state.selected_piece_colour)

		local params = get_player_params(1)
		draw_player_state(state, params, player)

		draw_back_btn()
	elseif state.ui_state == ui.UI_STATE_SELECT_DISCARDED_PIECES then
		local params = get_player_params(1)
		draw_player_state(state, params, player)

		local highlight_params = default_discard_pile_highlight_params()
		highlight_params.highlight_selectable = (state.selected_piece_colour == nil)
		highlight_params.highlighted_colour = state.selected_piece_colour
		draw_discard_pile(state, discard_pile_params, highlight_params)

		draw_back_btn()
	else
		error(string.format("Unhandled ui state %s", state.ui_state))
	end
	alex_c_api.draw_refresh()
end

return draw
