game31s_draw = {}

local game31s_core = require("games/31s/31s_core")
local cards_draw = require("libs/cards/cards_draw")
local cards = require("libs/cards/cards")
local alex_c_api = require("alex_c_api")

local cards_per_hand = 3

game31s_draw.HAND_1       = 1
game31s_draw.HAND_2       = 2
game31s_draw.HAND_3       = 3
game31s_draw.DECK         = 4
game31s_draw.DISCARD      = 5
game31s_draw.STAGING_AREA = 6

local canvas_width = nil
local canvas_height = nil

--local card_width     =  70
--local card_height    = 125
local card_width     =  70
local card_height    = 110

local card_font_size =  32
local card_padding   =  20
local card_edge_padding = 3

local hand_width   = nil
local hand_y_start = nil
local hand_y_end   = nil
local hand_x_start = nil
local hand_x_end   = nil

-- For the current player-- this one can be clicked
local staging_area_y_start = nil
local staging_area_x_start = nil

local deck_discard_y = nil
local deck_discard_x_start = nil

function get_staging_area_pos(pos)
	if pos == 1 then
		return { y = staging_area_y_start,
		         x = staging_area_x_start,
		         angle = 0 }
	elseif pos == 2 then
		return { y = math.floor(canvas_height/2 - card_width/2),
		         x = math.floor(canvas_width/4 + card_height/2),
		         angle = 90 }
	elseif pos == 3 then
		return { y = math.floor(canvas_height/2 + card_height/2 - card_padding),
		         x = deck_discard_x_start - card_padding,
		         angle = 180 }
	elseif pos == 4 then
		return { y = math.floor(canvas_height/2 + card_width/2),
		         x = math.floor(canvas_width/2 + card_padding),
		         angle = 270 }
	end
end

function game31s_draw.init_ui(canvas_width_arg, canvas_height_arg)
	canvas_width  = canvas_width_arg
	canvas_height = canvas_height_arg

	hand_y_start = canvas_height - card_height - card_edge_padding
	hand_y_end   = hand_y_start + card_height
	hand_width = cards_per_hand*card_width + (cards_per_hand-1)*card_padding
	hand_x_start = math.floor((canvas_width - hand_width)/2)
	hand_x_end   = hand_x_start + hand_width
	deck_discard_y = math.floor((canvas_height - card_height)/2)
	deck_discard_x_start = math.floor((canvas_width  - 2*card_width + card_padding)/2)

	staging_area_y_start = math.floor(canvas_height/2 - card_height/2 + card_padding)
	staging_area_x_start = deck_discard_x_start - card_padding - card_width
end



local function draw_revealed_hand(state, player, position, highlight)
	print(string.format("Drawing player %s hand", player))
	local y_start
	local x_start
	local dy
	local dx
	local width
	local height
	local angle

	width = card_width
	height = card_height
	angle = 0
	dy = 0
	dx = (card_width + card_padding)
	if position == 1 then
		y_start = hand_y_start
		x_start = hand_x_start
	elseif position == 2 then
		y_start = math.floor((canvas_height - hand_width)/2)
		x_start = card_edge_padding + card_height
		dy      = card_width + card_padding
		dx      = 0
		width = card_width
		height = card_height
		angle = 90
	elseif position == 3 then
		y_start = card_edge_padding
		x_start = hand_x_start
	elseif position == 4 then
		y_start = canvas_height - math.floor((canvas_height - hand_width)/2)
		x_start = canvas_height - card_edge_padding - card_height
		dy      = -(card_width + card_padding)
		dx      = 0
		width   = card_width
		height  = card_height
		angle   = 270

	else
		error(string.format("Unhandled position %q", position))
		return
	end

	local hand = state.player_hands[player]
	if hand == nil then
		error("hand is nil")
		return
	end

	if #hand ~= cards_per_hand then
		error(string.format("unexpected hand len: %d", #hand))
		return
	end


	for i=1, cards_per_hand do
		cards_draw.draw_card(state.player_hands[player][i],
		                     y_start + (i-1)*dy, x_start + (i-1)*dx,
		                     width, height,
		                     card_font_size, highlight, angle)
	end
end

local function draw_hand_facedown(pos)
	local y_start, x_start
	local angle
	local dy, dx
	local width  = card_width
	local height = card_height
	if pos == 2 then
		y_start = math.floor((canvas_height - hand_width)/2)
		x_start = card_edge_padding + card_height
		dy = card_padding + card_width
		dx = 0
		angle = 90
	elseif pos == 3 then
		y_start = card_edge_padding + card_height
		x_start = hand_x_start + card_width
		dy = 0
		dx = card_padding + card_width
		angle = 180
	elseif pos == 4 then
		y_start = canvas_height - math.floor((canvas_height - hand_width)/2)
		x_start = canvas_height - card_edge_padding - card_height
		dy = -(card_width + card_padding)
		dx = 0
		angle = 270
	end

	for i=1, cards_per_hand do
		cards_draw.draw_facedown_card(y_start + (i-1)*dy, x_start + (i-1)*dx, width, height, false, angle)
	end
end

local function draw_deck_and_discard(state, highlight)

	cards_draw.draw_facedown_card(deck_discard_y, deck_discard_x_start, card_width, card_height, highlight)
	if state ~= nil and #state.discard_pile > 0 then
		cards_draw.draw_card(state.discard_pile[#state.discard_pile],
		                     deck_discard_y, deck_discard_x_start + card_width + card_padding,
		                     card_width, card_height, card_font_size, highlight)
	end
end

local function draw_staging_area(state, player, pos_idx, highlight)
	if state.staging_area ~= nil then
		local card = state.staging_area
		if state.player_turn ~= player and not state.drew_from_discard then
			card = cards.UNREVEALED_CARD
		end
		print("staging area pos " .. pos_idx)
		local pos = get_staging_area_pos(pos_idx)
		print(string.format("Drawing staging area idx=%d, pos{y=%d, x=%d}", pos_idx, pos.y, pos.x))
		cards_draw.draw_card(card,
		                     pos.y, pos.x,
		                     card_width, card_height, card_font_size, highlight, pos.angle)
	end
end

local function get_starting_pos_other_player(player_count)
	if player_count == 2 then
		return 3
	else
		return 2
	end
end

local function player_idx_to_board_pos(this_player, player_idx, player_count)
	if this_player == player_idx then
		return 1
	end

	if player_count == 2 then
		return 3
	end

	local pos_counter = 2
	local player_idx_to_pos_map = {}
	for i=1,player_count do
		if i == this_player then goto next_player end
		player_idx_to_pos_map[i] = pos_counter
		pos_counter = pos_counter + 1
		::next_player::
	end
	return player_idx_to_pos_map[player_idx]
end

function game31s_draw.draw(state, player)

	alex_c_api.draw_clear()

	local highlight_hand_and_staging = false
	local highlight_draw_and_discard = false

	if state ~= nil and #state.winners == 0 and player == state.player_turn then
		highlight_hand_and_staging = (state.staging_area ~= nil)
		highlight_draw_and_discard = (state.staging_area == nil)
	end

	draw_deck_and_discard(state, highlight_draw_and_discard)

	if state == nil then
		alex_c_api.draw_refresh()
		return
	end

	draw_revealed_hand(state, player,  1, highlight_hand_and_staging)

	if #state.winners > 0 then
		for other_player=1, state.player_count do
			if other_player == player then
				goto next_player
			end
			local pos = player_idx_to_board_pos(player, other_player, state.player_count)
			draw_revealed_hand(state, other_player,  pos, false)
			pos = pos + 1
			::next_player::
		end
	else
		local pos = get_starting_pos_other_player(state.player_count)
		for _=1,state.player_count-1 do
			draw_hand_facedown(pos)
			pos = pos + 1
		end
	end

	local staging_area_pos = player_idx_to_board_pos(player, state.player_turn, state.player_count)
	draw_staging_area(state, player, staging_area_pos, highlight_hand_and_staging)

	alex_c_api.draw_refresh()
end

function game31s_draw.coords_to_ui_elem(y, x)
	if hand_y_start <= y and y <= hand_y_end and
	   hand_x_start <= x and x <= hand_x_end then
		local card_idx = 1 + math.floor( (x - hand_x_start) * cards_per_hand / hand_width )
		local map = {
			[1] = game31s_draw.HAND_1,
			[2] = game31s_draw.HAND_2,
			[3] = game31s_draw.HAND_3,
		}
		return map[card_idx]
	elseif staging_area_y_start <= y and y <= staging_area_y_start + card_height and
	       staging_area_x_start <= x and x <= staging_area_x_start + card_width then
		return game31s_draw.STAGING_AREA
	elseif deck_discard_y       <= y and y <= deck_discard_y + card_height and
	       deck_discard_x_start <= x and x <= deck_discard_x_start + 2*card_width + card_padding then
		local fact = (x - deck_discard_x_start) / (2*card_width + card_padding)
		if fact < 0.5 then
			return game31s_draw.DECK
		else
			return game31s_draw.DISCARD
		end
	else
		return nil
	end
end

return game31s_draw
