local draw = {}

local alexgames = require("alexgames")

local cards      = require("libs/cards/cards")
local cards_draw = require("libs/cards/cards_draw")
local draw_celebration_anim = require("libs/draw/draw_celebration_anim")

local core       = require("games/solitaire/solitaire_core")

local BACKGROUND_COLOUR = '#008800'
local CARD_SPACE_COLOUR = '#007000'
local BACKGROUND_COLOUR_DARK  = '#002200'
local CARD_SPACE_COLOUR_DARK  = '#001100'

local TEXT_SIZE   = 14
local TEXT_COLOUR_LIGHT = '#0000cc'
local TEXT_COLOUR_DARK  = '#8888aa'
local PADDING = 3

-- 
draw.show_move_count_and_elapsed_time = nil

local function get_bg_colour()
	if alexgames.get_user_colour_pref() == "dark" then
		return BACKGROUND_COLOUR_DARK
	else
		return BACKGROUND_COLOUR
	end
end

local function get_card_space_colour()
	if alexgames.get_user_colour_pref() == "dark" then
		return CARD_SPACE_COLOUR_DARK
	else
		return CARD_SPACE_COLOUR
	end

end

local function get_text_colour()
	if alexgames.get_user_colour_pref() == "dark" then
		return TEXT_COLOUR_DARK
	else
		return TEXT_COLOUR_LIGHT
	end
end

--local PLAYER_HOLDING_OFFSET_Y = -7
--local PLAYER_HOLDING_OFFSET_X = 7
--local PLAYER_HOLDING_OFFSET_Y = 0
--local PLAYER_HOLDING_OFFSET_X = 0
local PLAYER_HOLDING_OFFSET_Y = -5
local PLAYER_HOLDING_OFFSET_X = 5
local HELD_CARD_IS_HIGHLIGHTED = true

local is_touch_controlled = false

draw.BTN_ID_AUTO_COMPLETE = "autocomplete"
draw.BTN_ID_NEW_GAME = "new_game"
draw.BTN_ID_UNDO     = "undo"

--local card_height = 105
--local card_width  = 60
local card_ratio = 75/40
local card_padding_ratio = 10/75

local card_height = 75
local card_width  = 40
local card_font_size  = 32
local card_padding = 10
local card_stack_offset = 5
local card_revealed_offset = 20
 -- for draw 3, how much space to leave between the three cards drawn from the deck
local draw_pile_offset = 23

local board_width  = nil
local board_height = nil

local ANIM_MOVE_MS = 150
local anim_start_time_ms = nil
local anim_end_time_ms   = nil
local card_anim_src_y = nil
local card_anim_src_x = nil
local card_anim_dst_y = nil
local card_anim_dst_x = nil
local card_anim = nil
local card_anim_pos_y = nil
local card_anim_pos_x = nil
local move_list = {}
local last_animation_update_time = nil
local anim_finished_callback = nil

local anim_state = draw_celebration_anim.new_state({
})
-- TODO this probably should be included in the anim state?
-- Perhaps as an option, for games that don't otherwise require a timer
local g_victory_anim_timer = nil


function draw.set_is_touch_controlled(arg)
	is_touch_controlled = arg
end

function draw.init(board_width_arg, board_height_arg)

	board_width  = board_width_arg
	board_height = board_height_arg

	local card_width_max  = math.floor(board_width/(core.NUM_PLAY_COLUMNS * (1+card_padding_ratio)))
	local card_height_max = math.floor(card_width_max * card_ratio)

	card_width  = card_width_max
	card_height = card_height_max
	card_padding = math.floor(card_width_max * card_padding_ratio)


	alexgames.create_btn(draw.BTN_ID_UNDO,          "Undo",          1)
	alexgames.create_btn(draw.BTN_ID_NEW_GAME,      "New Game",      1)
	alexgames.create_btn(draw.BTN_ID_AUTO_COMPLETE, "Auto-Complete", 1)
end


function draw.get_pos(state, game_section, col, idx)
	if game_section == core.SECTION_PLAY_COLUMN_UNREVEALED then
		return {
			y = card_height + 2*card_padding + (idx-1) * card_stack_offset,
			x = card_padding + (col-1) * (card_padding + card_width),
		}
	elseif game_section == core.SECTION_PLAY_COLUMN_STAGING then
		local stack = #state.play_columns_unrevealed[col]
		if idx == nil then
			idx = #state.play_columns_staging
		end
		return {
			y = card_height + 2*card_padding + stack*card_stack_offset + (idx-1)*card_revealed_offset,
			x = card_padding + (col-1) * (card_padding + card_width),
		}
	elseif game_section == core.SECTION_DECK_UNREVEALED then
		return {
			y = card_padding,
			x = card_padding + (core.NUM_PLAY_COLUMNS-1) * (card_padding + card_width),
		}
	elseif game_section == core.SECTION_DECK_DRAW or
	       game_section == core.SECTION_DECK_DISCARD then
		if game_section == core.SECTION_DECK_DISCARD then
			if col ~= nil then
				error("col is nil for get_pos(DISCARD)")
			end
			col = 1
		end
		if col == nil then
			error(string.format("get_pos col is nil"), 3)
		end
		-- This is the extra space that we have to divide between the draw 3 cards (if present)
		local draw_width = card_width + card_padding
		local draw_idx = 1
		if state.draw_type == core.DRAW_TYPE_THREE then
			draw_idx = 3 - col + 1
		end
		return {
			y = card_padding,
			x = math.floor(card_padding + (core.NUM_PLAY_COLUMNS-2) * (card_padding + card_width) - (draw_idx-1)*draw_pile_offset)
		}
	elseif game_section == core.SECTION_GOAL_STACKS then
		return {
			y = card_padding,
			x = card_padding + (col-1) * (card_padding + card_width),
		}
	else
		error(string.format("get_pos: unhandled section %s", game_section))
	end
	
end

local function in_section(state, pos_y, pos_x, game_section, col, idx)
	local pos = draw.get_pos(state, game_section, col, idx)
	return pos.y <= pos_y and pos_y <= pos.y + card_height and
	       pos.x <= pos_x and pos_x <= pos.x + card_width
end

local function get_offset(player_state)
	if not is_touch_controlled then
		return {
			dy = player_state.y_card_offset,
			dx = player_state.x_card_offset,
		}
	else
		return {
			dy = math.floor(card_height/2),
			dx = math.floor(card_width/2),
		}
	end
end


function draw.draw_state(session_id, state)
	alexgames.draw_clear()

	alexgames.draw_rect(get_bg_colour(), 0, 0, board_height, board_width)

	for i=1,core.NUM_GOAL_STACKS do
		local pos = draw.get_pos(state, core.SECTION_GOAL_STACKS, i)
		alexgames.draw_rect(get_card_space_colour(),
		                     pos.y, pos.x,
		                     pos.y + card_height,
		                     pos.x + card_width)
	end

	if state == nil then
		local pos = draw.get_pos(state, core.SECTION_DECK_UNREVEALED)
		cards_draw.draw_card(cards.UNREVEALED_CARD,
		                     pos.y, pos.x,
		                     card_width,
		                     card_height,
		                     card_font_size,
				             false,
				             0)
		local text_size = 24
		alexgames.draw_text("Press \"New Game\" button",
		                     "#000000",
		                     board_height/2 - text_size,
		                     board_width/2,
		                     text_size,
		                     alexgames.TEXT_ALIGN_CENTRE)
		return
	end


	for i=1,#state.play_columns_unrevealed do
		for j=1,#state.play_columns_unrevealed[i] do
			local pos = draw.get_pos(state, core.SECTION_PLAY_COLUMN_UNREVEALED, i, j)
			cards_draw.draw_card(cards.UNREVEALED_CARD,
					             pos.y, pos.x,
			                     card_width,
			                     card_height,
			                     card_font_size,
					             false,
					             0)
		end

		for j=1,#state.play_columns_staging[i] do
			local card = state.play_columns_staging[i][j]
			local pos = draw.get_pos(state, core.SECTION_PLAY_COLUMN_STAGING, i, j)
				cards_draw.draw_card(card,
					             pos.y, pos.x,
			                     card_width,
			                     card_height,
			                     card_font_size,
					             false,
					             0)		
		end
	end

	-- TODO if deck is empty, draw some sort of an icon in its place
	local pos = draw.get_pos(state, core.SECTION_DECK_UNREVEALED)
	if #state.deck_unrevealed > 0 then
		cards_draw.draw_card(cards.UNREVEALED_CARD,
		                     pos.y, pos.x,
		                     card_width,
		                     card_height,
		                     card_font_size,
				             false,
				             0)
	else
		-- TODO draw some sort of an icon, like a green circle,
		-- to indicate that this can be clicked?
		alexgames.draw_rect(get_card_space_colour(),
		                     pos.y, pos.x,
		                     pos.y + card_height,
		                     pos.x + card_width)
	end


	if #state.deck_draw > 0 then
		-- Card at top of stack should be drawn on top
		for i=1,#state.deck_draw do
			local pos = draw.get_pos(state, core.SECTION_DECK_DRAW, i)
			local deck_revealed_top = state.deck_draw[i]
			cards_draw.draw_card(deck_revealed_top,
			                     pos.y, pos.x,
			                     card_width,
			                     card_height,
			                     card_font_size,
					             false,
					             0)
		end
	-- Maybe only draw this card if the player is holding one?
	-- what is really bad is if the player isn't holding a card, and there's a bug
	-- in the core logic that prevents one of the discard cards from being moved to
	-- the draw pile. There's this card shown (by the below code) that can't be picked up.
	elseif #state.deck_discard > 0 and state.draw_type == core.DRAW_TYPE_ONE then
	-- For draw three, if there are no cards here, don't draw any from the deck_discard pile.
	-- Rely on the core game code to put a discard card here when the user has actually
	-- placed (stopped holding)
		local pos = draw.get_pos(state, core.SECTION_DECK_DRAW, 1)
		local card = state.deck_discard[#state.deck_discard]
		if card == nil then error("card is nil in case 1234234") end
		cards_draw.draw_card(card,
		                     pos.y, pos.x,
		                     card_width,
		                     card_height,
		                     card_font_size,
				             false,
				             0)
	end

	for i=1,#state.goal_stacks do
		local card = nil
		if #state.goal_stacks[i] > 0 then
			card = state.goal_stacks[i][#state.goal_stacks[i]]
		end
		local pos = draw.get_pos(state, core.SECTION_GOAL_STACKS, i)
		if card ~= nil then
			cards_draw.draw_card(card,
			                     pos.y, pos.x,
			                     card_width,
			                     card_height,
			                     card_font_size,
			                     false,
			                     0)
		end
	end

	for player=1,state.player_count do
		local player_state = state.players[player]
		if player_state.holding ~= nil then
			local y = player_state.y
			local x = player_state.x

			if player_state.y_card_offset ~= nil and
			   player_state.x_card_offset ~= nil then
				local offset = get_offset(player_state)
				y = y - offset.dy
				x = x - offset.dx
			end

			y = y + PLAYER_HOLDING_OFFSET_Y
			x = x + PLAYER_HOLDING_OFFSET_X

			for stack_idx, card in ipairs(player_state.holding) do
				cards_draw.draw_card(card,
				                     y + (stack_idx-1)*card_revealed_offset,
				                     x,
				                     card_width, card_height, card_font_size,
				                     HELD_CARD_IS_HIGHLIGHTED, 0)
			end
		end
	end

	if card_anim ~= nil then
		cards_draw.draw_card(card_anim,
		                     math.floor(card_anim_pos_y), math.floor(card_anim_pos_x),
		                     card_width, card_height, card_font_size,
		                     false, 0)
	end

	if draw.show_move_count_and_elapsed_time and state.move_count ~= nil then
		local moves_str = string.format('Moves: %d', state.move_count)
		alexgames.draw_text(moves_str, get_text_colour(),
		                     board_height - PADDING,
		                     PADDING,
		                     TEXT_SIZE, alexgames.TEXT_ALIGN_LEFT)
	end
	if draw.show_move_count_and_elapsed_time and state.time_elapsed ~= nil then
		local mins_elapsed = math.floor(state.time_elapsed / 60)
		local secs_elapsed = state.time_elapsed % 60
		local time_str = string.format('%d:%02d', mins_elapsed, secs_elapsed)
		alexgames.draw_text(time_str, get_text_colour(),
		                     board_height - PADDING,
		                     board_width - PADDING,
		                     TEXT_SIZE, alexgames.TEXT_ALIGN_RIGHT)
	end

	draw_celebration_anim.draw(anim_state)
	alexgames.draw_refresh()


	-- TODO uncomment once testing is done on this
	--alexgames.set_btn_enabled(draw.BTN_ID_AUTO_COMPLETE, core.autocomplete_available(state))
	alexgames.set_btn_enabled(draw.BTN_ID_UNDO, alexgames.has_saved_state_offset(session_id, -1))
end


function draw.pos_to_action(state, player, pos_y, pos_x, evt_id)
	if state == nil then
		return nil
	end
	if #move_list > 0 then
		return nil
	end
	local info = {
		section_type = nil,
		col = nil,
		idx = nil,

		-- only used for setting player pos
		y = pos_y,
		x = pos_x,
	}

	if evt_id == 'touchend' and 
	   state.players[player].y_card_offset ~= nil and 
	   state.players[player].x_card_offset ~= nil then
		local offset = get_offset(state.players[player])
		offset.dy = offset.dy - math.floor(card_height/2)
		offset.dx = offset.dx - math.floor(card_width/2)

		pos_y = pos_y - offset.dy
		pos_x = pos_x - offset.dx

		print(string.format("offsetting mouse pos with dy=%d, dx=%d, is_touch=%s", offset.dy, offset.dx, is_touch_controlled))
	end 

	if in_section(state, pos_y, pos_x, core.SECTION_DECK_UNREVEALED) then
		info.section_type = core.SECTION_DECK_UNREVEALED
		return info
	else
		for draw_idx=1,state.draw_type do
			if in_section(state, pos_y, pos_x, core.SECTION_DECK_DRAW, draw_idx) then
				info.section_type = core.SECTION_DECK_DRAW
				info.col          = draw_idx
				return info
			end
		end
		for col=1,core.NUM_PLAY_COLUMNS do
			for idx=#state.play_columns_staging[col],1,-1 do
				if in_section(state, pos_y, pos_x, core.SECTION_PLAY_COLUMN_STAGING, col, idx) then
					info.section_type = core.SECTION_PLAY_COLUMN_STAGING
					info.col = col
					info.idx = idx
					return info
				end
			end
			-- This is the "empty column" case, where you can place kings
			if #state.play_columns_staging[col] == 0 and 
			   #state.play_columns_unrevealed[col] == 0 then 
				if in_section(state, pos_y, pos_x, core.SECTION_PLAY_COLUMN_STAGING, col, 1) then
					info.section_type = core.SECTION_PLAY_COLUMN_STAGING
					info.col = col
					return info
				end
			end
		end

		for col=1,core.NUM_PLAY_COLUMNS do

			for idx=1,#state.play_columns_unrevealed[col] do
				if in_section(state, pos_y, pos_x, core.SECTION_PLAY_COLUMN_UNREVEALED, col, idx) then
					info.section_type = core.SECTION_PLAY_COLUMN_UNREVEALED
					info.col = col
					info.idx = idx
					return info
				end
			end
		end

		for col=1,cards.NUM_SUITS do
			if in_section(state, pos_y, pos_x, core.SECTION_GOAL_STACKS, col) then
				info.section_type = core.SECTION_GOAL_STACKS
				info.col = col
				return info
			end
		end
	end
	return nil
end

local function start_anim(state, item)
	--print("start_anim")
	--if #move_list > 0 then
	--	return
	--end
	if item.item.move == core.ACTION_MOVE then
		card_anim = core.remove_card_from_move(state, item.item.src)
		local src_pos = draw.get_pos(state, item.item.src.section_type, item.item.src.col)
		card_anim_src_y = src_pos.y
		card_anim_src_x = src_pos.x
		local dst_pos = draw.get_pos(state, item.item.dst.section_type, item.item.dst.col)
		card_anim_dst_y = dst_pos.y
		card_anim_dst_x = dst_pos.x
		anim_start_time_ms = alexgames.get_time_ms()
		anim_end_time_ms   = item.time

		card_anim_pos_y = card_anim_src_y
		card_anim_pos_x = card_anim_src_x
		core.inc_move_count(state)
	elseif item.item.move == core.ACTION_DECK_NEXT then
		core.next_in_deck(state)
		anim_start_time_ms = alexgames.get_time_ms()
		anim_end_time_ms   = item.time
	else
		error(string.format("unexpected item.item.move=%s", item.item.move))
	end
	
end

function draw.stop_move_animations()
	anim_start_time_ms = nil
	anim_end_time_ms   = nil
	card_anim_src_y = nil
	card_anim_src_x = nil
	card_anim_dst_y = nil
	card_anim_dst_x = nil
	card_anim = nil
	card_anim_pos_y = nil
	card_anim_pos_x = nil
	move_list = {}
	last_animation_update_time = nil
	if anim_finished_callback ~= nil then
		anim_finished_callback()
	end
	anim_finished_callback = nil
end

function draw.animate_moves(state, move_list_arg, on_anim_finished)
	if #move_list > 0 then
		return
	end

	local current_time_ms = alexgames.get_time_ms()
	for i, item in ipairs(move_list_arg) do
		local anim_item = {
			item = item,
			time = current_time_ms + i * ANIM_MOVE_MS,
		}
		table.insert(move_list, anim_item)
	end
	if #move_list > 0 then
		start_anim(state, move_list[1])
	end
	anim_finished_callback = on_anim_finished
end

-- While working on this I had added two "animations":
-- * the autocomplete moves, that's what `draw.animate_moves` does
-- * the fireworks "victory animation" / "draw_celebration_anim".
function draw.update_animations(state, dt_ms)
	--print("update_animations", dt_ms, "move list len", #move_list)

	draw.animate_moves(state, move_list, on_anim_finished)
	draw_celebration_anim.update(anim_state, dt_ms/1000.0)

	if #move_list == 0 then
		return
	end

	-- TODO REMOVE?
	if dt_ms == 0 then
		return
	end 
	local current_time_ms = alexgames.get_time_ms()
	--local time_diff = last_animation_update_time - current_time_ms
	if current_time_ms < move_list[1].time then
		if move_list[1].item.move == core.ACTION_MOVE then
			local time_portion = (current_time_ms - anim_start_time_ms) / (anim_end_time_ms - anim_start_time_ms)
			if time_portion >= 1 then
				time_portion = 1
			end
	
			card_anim_pos_y = card_anim_src_y + time_portion * (card_anim_dst_y - card_anim_src_y)
			card_anim_pos_x = card_anim_src_x + time_portion * (card_anim_dst_x - card_anim_src_x)
		end
	else
		if move_list[1].item.move == core.ACTION_MOVE then
			local ary = core.get_card_ary(state, move_list[1].item.dst.section_type, move_list[1].item.dst.col)
			table.insert(ary, card_anim)
			card_anim = nil
		end
		table.remove(move_list, 1)
		if #move_list > 0 then
			start_anim(state, move_list[1])
		else
			if anim_finished_callback ~= nil then
				anim_finished_callback()
			end
		end
	end
end

function draw.victory_animation(fps)
	print("setting timer")
	if g_victory_anim_timer ~= nil then
		error(string.format("victory_animation: anim_timer is not nil"))
	end
	g_victory_anim_timer = alexgames.set_timer_update_ms(1000/fps)
	draw_celebration_anim.fireworks_display(anim_state, {
		on_finish = function ()
			if g_victory_anim_timer == nil then
				alexgames.set_status_err("warning: g_victory_anim_timer is nil on anim complete")
			else
				alexgames.delete_timer(g_victory_anim_timer)
				g_victory_anim_timer = nil
			end
			--print("animation finished! Resuming timer")
			--alexgames.set_timer_update_ms(0)
			--alexgames.set_timer_update_ms(1000/60)
		end,
	})
end
	

return draw
