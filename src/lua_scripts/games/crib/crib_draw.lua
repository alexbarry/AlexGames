local core = require("games/crib/crib_core")
local cards_draw = require("libs/cards/cards_draw")
local alexgames = require("alexgames")
local draw_more = require("libs/draw/draw_more")

local draw = {}

draw.ACTION_TYPE_GAME = 'game'
draw.ACTION_TYPE_UI   = 'ui'

draw.ACTION_UI_SHOW_POINTS_POPUP = "show_points"
draw.ACTION_UI_HIDE_POINTS_POPUP = "hide_points"

local TEXT_COLOUR = '#000000'
local TEXT_SIZE = 24
local text_height = 20

local CARD_POINTS_POPUP_BACKGROUND_COLOUR = '#aaaaaaf0'
local CARD_POINTS_POPUP_OUTLINE_COLOUR = '#000000'
local popup_padding = 40

draw.BTN_ID_DISCARD = "discard"
draw.BTN_ID_PASS = "pass"
draw.BTN_ID_NEXT = "next"

local width = nil
local height = nil
local card_height = 105
local card_width  = 60
local card_font_size  = 28
local card_padding = 15
local card_discard_offset = 40
-- when drawing a pile of cards, this is the y and x offset
-- that should be drawn to subsequent cards on the pile so
-- they appear to form a stack.
local card_pile_offset = 3

local more_info_btn_width  = 50
local more_info_btn_height = 50

local player_hand_y_centre = nil
local player_hand_x_centre = nil


local small_card_width = 35
local small_card_height = 50
local small_card_font_size = 12
local small_card_padding = 3

local hand_width = nil

function draw.init(height_arg, width_arg)
	height = height_arg
	width  = width_arg

	player_hand_y_centre = math.floor(height - card_height/2 - card_padding)
	player_hand_x_centre = math.floor(width/2)

	hand_width = core.CARDS_PER_HAND * card_width + (core.CARDS_PER_HAND - 1) * card_padding

	alexgames.create_btn(draw.BTN_ID_DISCARD, "Discard", 1)
	alexgames.create_btn(draw.BTN_ID_PASS,    "Can't move", 1)
	alexgames.create_btn(draw.BTN_ID_NEXT,    "Next", 1)
	alexgames.set_btn_enabled(draw.BTN_ID_DISCARD, false)
	alexgames.set_btn_enabled(draw.BTN_ID_PASS,    false)
	alexgames.set_btn_enabled(draw.BTN_ID_NEXT,    false)

	local ui_state = {
		points_popup_shown   = false,
		points_popup_player  = nil,
	}
	return ui_state
end

local function get_offset_ary(state, player)
	if state.state ~= core.states.PICK_DISCARD then
		return nil
	end
	local offset_ary = {}
	for i=1,#state.hands[player] do
		local offset = nil
		if state.tentative_discards[player][i] then
			offset = -card_discard_offset
		else
			offset = 0
		end
		offset_ary[i] = offset
	end
	return offset_ary
end

local function get_hand_pos(state, this_player, player)
	local pos = {}
	local adjusted_player_pos = ((player - this_player) % state.player_count)
	if adjusted_player_pos == 0 then
		pos.y = player_hand_y_centre
		pos.x = player_hand_x_centre
	elseif adjusted_player_pos == 1 then
		pos.y = math.floor(card_height/2 + card_padding)
		pos.x = math.floor(width/2)
	else
		error(string.format("Unhandled this_player=%s, player=%s, adjusted=%s", this_player, player, adjusted_player_pos))
	end

	return pos
end

local function get_more_info_btn_pos(this_player, player)
	if this_player == player then
		return {
			y = math.floor(height - card_height - 2*card_padding - more_info_btn_height),
			x = math.floor(width/2 + hand_width/2 - more_info_btn_width),
		}
	else
		return {
			y = math.floor(card_height + 2*card_padding),
			x = math.floor(width/2 - hand_width/2),
		}
	end
end

local function get_hand_score_pos(this_player, player)
	if this_player == player then
		return {
			y = math.floor(height - card_height - 2*card_padding),
			x = math.floor(width/2),
		}
	else
		return {
			y = math.floor(card_height + 2*card_padding + text_height),
			x = math.floor(width/2),
		}
	end
end

local function get_played_pos(state, this_player, player)
	local pos = {}
	--local adjusted_player_pos = ((player - this_player) % state.player_count)
	local adjusted_player_pos = nil
	if (this_player == player) then
		adjusted_player_pos = 0
	else
		adjusted_player_pos = 1
	end

	local offset_frac_y = 0.6
	local offset_card_widths_x = 2.0
		
	if adjusted_player_pos == 0 then
		pos.y = math.floor(offset_frac_y*height - card_height/2)
		pos.x = math.floor(width/2 - card_width/2 + offset_card_widths_x*card_width)
	elseif adjusted_player_pos == 1 then
		pos.y = math.floor((1-offset_frac_y)*height - card_height/2)
		pos.x = math.floor(width/2 - card_width/2 - offset_card_widths_x*card_width)
	else
		error(string.format("Unhandled this_player=%s, player=%s, adjusted=%s", this_player, player, adjusted_player_pos))
	end
	return pos
end

local function get_other_player(state, player)
	if player == 1 then return 2
	else return 1 end
end

local function player_pos_to_idx(state, player, pos)
	if pos == 1 then return player
	else return get_other_player(state, player) end
end

local function draw_points_popup(state, points_info, player)
		alexgames.draw_rect(CARD_POINTS_POPUP_BACKGROUND_COLOUR,
		                     popup_padding, popup_padding,
		                     width - popup_padding, height - popup_padding)

		alexgames.draw_text(string.format("Player %d points: %d", player, points_info.points), TEXT_COLOUR,
		                     popup_padding + 2*card_padding,
		                     popup_padding + card_padding,
		                     TEXT_SIZE, 1, 0)

		for i,points_reason in ipairs(points_info.points_reasons) do
			--local text_height = 16*2
			local text_height = small_card_height + small_card_padding
			local text_pos_y = popup_padding + 4*card_padding + (i-1)*text_height
			local reason_str = core.point_type_to_str(points_reason.reason)
			alexgames.draw_text(string.format("+%2d %s", points_reason.points, reason_str), TEXT_COLOUR,
			                     text_pos_y, popup_padding + 3*card_padding, 16, 1, 0)
			for j,card_idx in ipairs(points_reason.card_idxs) do
				local card_pos_x = width - popup_padding - j*(small_card_width + small_card_padding)
				local card = nil
				local hand = nil
				if state.state == core.states.ACKNOWLEDGE_POINTS then
					hand = state.played[player]
				elseif state.state == core.states.ACKNOWLEDGE_CRIB then
					hand = state.crib
				end

				if card_idx <= #hand then
					card = hand[card_idx]
				elseif card_idx == #state.played[player] + 1 then
					card = state.cut_deck_card
				else
					error(string.format("Unexpected card_idx %s, #hand = %s", card_idx, #hand))
				end
				cards_draw.draw_card(card,
				                math.floor(text_pos_y - small_card_height/2),
				                card_pos_x,
								small_card_width,
								small_card_height,
				                small_card_font_size,
				                false,
				                0)
			end
		end

		local btn_pos_y = height - popup_padding - more_info_btn_height - card_padding
		local btn_pos_x = popup_padding + card_padding
		alexgames.draw_rect('#dddddd',
		                        btn_pos_y, btn_pos_x,
		                        (width - popup_padding - card_padding), --  - btn_pos_x,
		                        (height - popup_padding - card_padding)) --  - btn_pos_y)
		alexgames.draw_text("Close", TEXT_COLOUR,
		                     math.floor(btn_pos_y + more_info_btn_height/2),
		                     math.floor(width/2),
		                     TEXT_SIZE, 0, 0)
end

local function get_hand_to_draw(state, this_player, player)
	if state.state == core.states.ACKNOWLEDGE_POINTS then
		return state.played[player]
	elseif state.state == core.states.ACKNOWLEDGE_CRIB then
		if player == state.player_crib then
			return state.crib
		else
			return {}
		end
	else
		if this_player == player then
			return state.hands[player]
		else
			local len = #state.hands[player]
			local hand = {}
			for i=1,len do
				table.insert(hand, cards.UNREVEALED_CARD)
			end
			return hand
		end
	end
end

local function get_crib_label_pos(player_crib, player)
	if player == player_crib then
		return {
			y = math.floor(height - card_height - 4*card_padding),
			x = math.floor(width - 2*card_padding),
			align = -1,
		}
	else
		return {
			y = math.floor(card_height + 5*card_padding),
			x = math.floor(2*card_padding),
			align = 1,
		}
	end
end

local function get_score(state, player)
	--if state == nil then return "" end
	--if player == nil then return "" end
	return string.format("%d", state.score[player])
end

function draw.draw(state, ui_state, player)
	alexgames.draw_clear()


	if state == nil then
		return
	end

	local offset_ary = nil 
	local highlight_ary = core.get_highlight_ary(state, player)

	if state.state == core.states.PICK_DISCARD then
		offset_ary = get_offset_ary(state, player)
	elseif state.state == core.states.PLAY then
	end

	if state.state == core.states.PLAY then
		alexgames.draw_text(tostring(state.playing_sum), TEXT_COLOUR,
			math.floor(height/2),
			math.floor(width/2 + card_padding),
			TEXT_SIZE,
			1, 0)
	end

	if state.cut_deck_card ~= nil then
		cards_draw.draw_card(state.cut_deck_card,
			math.floor(height/2 - card_height/2),
			math.floor(width/2 - card_width),
			card_width,
			card_height,
			card_font_size,
			false, 0)
	end

	alexgames.draw_text(get_score(state, player), TEXT_COLOUR,
		math.floor(height - card_height - 2*card_padding),
		math.floor(width - 2*card_padding),
		TEXT_SIZE,
		-1,
		0)

	local crib_label_pos = get_crib_label_pos(state.player_crib, player)
	alexgames.draw_text("crib", TEXT_COLOUR,
		crib_label_pos.y,
		crib_label_pos.x,
		TEXT_SIZE,
		crib_label_pos.aign,
		0)

	local my_hand = get_hand_pos(state, player, player)
	cards_draw.draw_card_array(get_hand_to_draw(state, player, player),
		my_hand.y,
		my_hand.x,
		card_width,
		card_height,
		card_font_size,
		highlight_ary,
		card_padding,
		offset_ary)

	if #state.playing[player] > 0 then
		local pos = get_played_pos(state, player, player)
		--local card = state.playing[player][#state.playing[player]]
		-- .draw_card(card, y, x, width, height, font_size, highlight, angle)
		for card_idx, card in ipairs(state.playing[player]) do
		cards_draw.draw_card(
			card,
			pos.y + card_idx*card_pile_offset,
			pos.x + card_idx*card_pile_offset,
			card_width,
			card_height,
			card_font_size,
			false,
			0)
		end
	end

	-- TODO loop through all other players and draw their cards
	-- TODO should draw offset array for other players too
	local other_player = get_other_player(state, player)
	alexgames.draw_text(get_score(state, other_player), TEXT_COLOUR,
		math.floor(card_height + 3*card_padding), -- TODO the other one is 2*padding. Ensure vertical centre?
		math.floor(2*card_padding),
		TEXT_SIZE,
		1,
		0)
	local hand_pos = get_hand_pos(state, player, other_player)

	cards_draw.draw_card_array(get_hand_to_draw(state, player, other_player),
		hand_pos.y,
		hand_pos.x,
		card_width,
		card_height,
		card_font_size,
		nil,
		card_padding,
		get_offset_ary(state, other_player))

	if #state.playing[other_player] > 0 then
		local pos = get_played_pos(state, player, other_player)
		local card = state.playing[other_player][#state.playing[other_player]]
		-- .draw_card(card, y, x, width, height, font_size, highlight, angle)
		for card_idx,card in ipairs(state.playing[other_player]) do
		cards_draw.draw_card(
			card,
			pos.y + card_idx*card_pile_offset,
			pos.x + card_idx*card_pile_offset,
			card_width,
			card_height,
			card_font_size,
			false,
			0)
		end
	end


	for player_idx=1,state.player_count do

		local hand = nil
		if state.state == core.states.ACKNOWLEDGE_POINTS then
			hand = state.played[player_idx]
		elseif state.state == core.states.ACKNOWLEDGE_CRIB and
		       state.player_crib == player_idx then
			hand = state.crib
		else
			goto next_player
		end

		local btn_pos = get_more_info_btn_pos(player, player)
		draw_more.draw_graphic_ul("more_info_btn", 
		                        btn_pos.y, btn_pos.x, 
		                        more_info_btn_width, more_info_btn_height)

		local points_info = core.check_points_sequence(hand, state.cut_deck_card)

		local hand_score_pos = get_hand_score_pos(player, player_idx)

		alexgames.draw_text(string.format("+%d", points_info.points),
			TEXT_COLOUR,
			hand_score_pos.y, hand_score_pos.x,
			TEXT_SIZE, 0, 0)

		if ui_state.points_popup_shown and player_idx == ui_state.points_popup_player then
			draw_points_popup(state, points_info, player_idx)
		end

		::next_player::
	end

	alexgames.draw_refresh()

	local visible_btn_discard = (state.state == core.states.PICK_DISCARD)
	local visible_btn_pass    = (state.state == core.states.PLAY)
	local visible_btn_next    = (state.state == core.states.ACKNOWLEDGE_POINTS or
	                             state.state == core.states.ACKNOWLEDGE_CRIB)
	alexgames.set_btn_visible(draw.BTN_ID_DISCARD, visible_btn_discard)
	alexgames.set_btn_visible(draw.BTN_ID_PASS,    visible_btn_pass)
	alexgames.set_btn_visible(draw.BTN_ID_NEXT,    visible_btn_next)

	local enable_discard_btn = (state.state == core.states.PICK_DISCARD and 
	                            #state.hands[player] > core.CARDS_PER_HAND and
	                            core.get_tentative_remaining_cards(state, player) == core.CARDS_PER_HAND)
	local enable_pass_btn = (state.state == core.states.PLAY and 
	                            state.player_turn == player and
	                            core.cant_move(state))
	local enable_btn_next = ((state.state == core.states.ACKNOWLEDGE_POINTS or
	                          state.state == core.states.ACKNOWLEDGE_CRIB) and
	                         not core.has_acknowledged_points(state, player))
	alexgames.set_btn_enabled(draw.BTN_ID_DISCARD, enable_discard_btn)
	alexgames.set_btn_enabled(draw.BTN_ID_PASS, enable_pass_btn)
	alexgames.set_btn_enabled(draw.BTN_ID_NEXT, enable_btn_next)
end

function draw.coords_to_action(state, ui_state, player, coord_y, coord_x)
	local action = {
		action_type = nil, 
		action = nil,
		idx = nil
	}

	-- If clicked anywhere while the popup is shown, hide it
	if ui_state.points_popup_shown then
		action.action_type = draw.ACTION_TYPE_UI
		action.action      = draw.ACTION_UI_HIDE_POINTS_POPUP
		return action
	end

	for other_player=1,state.player_count do
		local btn_pos = get_more_info_btn_pos(player, other_player)
		if btn_pos.y <= coord_y and coord_y <= btn_pos.y + more_info_btn_height and
		   btn_pos.x <= coord_x and coord_x <= btn_pos.x + more_info_btn_width then
			action.action_type = draw.ACTION_TYPE_UI
			action.action      = draw.ACTION_UI_SHOW_POINTS_POPUP
			action.idx = other_player
			return action
		end
	end
	

	local offset_ary = get_offset_ary(state, player)

	local hand_idx = cards_draw.card_array_coords_to_idx(
		#state.hands[player],
		player_hand_y_centre,
		player_hand_x_centre,
		card_width,
		card_height,
		card_padding,
		offset_ary,
		coord_y,
		coord_x)
	if hand_idx ~= nil then
		action.action_type = draw.ACTION_TYPE_GAME
		action.action = core.actions.HAND
		action.idx = hand_idx
	end

	return action
end

function draw.handle_ui_action(ui_state, ui_action)
	if ui_action.action == draw.ACTION_UI_SHOW_POINTS_POPUP then
		ui_state.points_popup_shown  = true
		ui_state.points_popup_player = ui_action.idx
	elseif ui_action.action == draw.ACTION_UI_HIDE_POINTS_POPUP then
		ui_state.points_popup_shown  = false
		ui_state.points_popup_player = nil
	end
end

return draw
