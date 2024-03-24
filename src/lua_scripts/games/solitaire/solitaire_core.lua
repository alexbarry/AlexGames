local core = {}

local cards = require("libs/cards/cards")

core.NUM_PLAY_COLUMNS = 7
core.NUM_GOAL_STACKS = cards.NUM_SUITS


core.ACTION_MOVE = 1
core.ACTION_DECK_NEXT = 2

core.SECTION_PLAY_COLUMN_UNREVEALED = 1
core.SECTION_PLAY_COLUMN_STAGING    = 2
core.SECTION_DECK_UNREVEALED        = 3
core.SECTION_DECK_DRAW              = 4
core.SECTION_DECK_DISCARD           = 5
core.SECTION_GOAL_STACKS            = 6
core.SECTION_LAST                   = core.SECTION_GOAL_STACKS

core.DRAW_TYPE_ONE   = 1
core.DRAW_TYPE_THREE = 3

-- height and width of a square that the user is allowed to move
-- their touch/mouse inside before their gesture is interpreted as
-- moving, rather than just a single click.
local MAX_MOVE_FOR_CLICK = 2

function core.new_state_from_board_state(num_players, board_state)
	local state = board_state
	state.player_count = num_players
	state.players = {}

	for i=1,num_players do
		state.players[i] = {
			y = 0,
			x = 0,

			y_card_offset = 0,
			x_card_offset = 0,
			holding = {},
			holding_src = nil,
			holding_src_col = nil,

			moved = false,
		}
	end
	return state
end

function core.new_board_state(draw_type, params)
	local deck_unrevealed = cards.new_deck()

	local seed_x, seed_y
	if params.seed_x and params.seed_y then
		seed_x, seed_y = math.randomseed(params.seed_x, params.seed_y)
	else
		seed_x, seed_y = math.randomseed()
	end
	cards.shuffle(deck_unrevealed)

	local board_state = {
		draw_type       = draw_type,
		deck_unrevealed = deck_unrevealed,
		deck_discard    = {},

		-- Cards taken from the deck, shown to the user.
		-- In draw one, this is only ever zero or one card.
		-- In draw three, this can be zero to three cards.
		-- The card at the end of the list is the one that is on "top"
		-- and the user can try to move. 
		deck_draw       = {},

		play_columns_unrevealed = {},
		play_columns_staging = {},
		goal_stacks = {},
		players = {},

		seed_x = seed_x,
		seed_y = seed_y,
	}

	for i=1,core.NUM_GOAL_STACKS do
		board_state.goal_stacks[i] = {}
	end

	for i=1,core.NUM_PLAY_COLUMNS do
		board_state.play_columns_unrevealed[i] = {}
		board_state.play_columns_staging[i]    = {}
		for j=2,i do
			local card = table.remove(board_state.deck_unrevealed)
			table.insert(board_state.play_columns_unrevealed[i], card)
		end
		local card = table.remove(board_state.deck_unrevealed)
		table.insert(board_state.play_columns_staging[i], card)
	end

	board_state.move_count   = 0
	board_state.time_elapsed = 0
	
	return board_state
end

function core.game_won(state)
	if state == nil then return false end

	if #state.goal_stacks ~= core.NUM_GOAL_STACKS then
		error(string.format("Expected num goal stacks (%d) to be equal to %d", #state.goal_stacks, core.NUM_GOAL_STACKS))
	end

	for _, goal_stack in ipairs(state.goal_stacks) do
		if #goal_stack ~= cards.NUM_VALS then
			return false
		end
	end

	return true
end

function core.new_game(num_players, draw_type, params)
	local board_state = core.new_board_state(draw_type, params)
	return core.new_state_from_board_state(num_players, board_state)
end

function core.print_state(state)
	print('{')
	for i=1,#state.goal_stacks do
		print(string.format('goal_stack[%d] = %s,', i, cards.card_ary_to_string(state.goal_stacks[i])))
	end
	print(string.format('deck_unrevealed = %s,', cards.card_ary_to_string(state.deck_unrevealed)))
	print(string.format('deck_draw   = %s,', cards.card_ary_to_string(state.deck_draw)))
	print(string.format('deck_discard = %s,', cards.card_ary_to_string(state.deck_discard)))
	for i=1,core.NUM_PLAY_COLUMNS do
		print(string.format('play_unrevealed[%d] = %s,', i, cards.card_ary_to_string(state.play_columns_unrevealed[i])))
		print(string.format('play_revealed[%d]   = %s,', i, cards.card_ary_to_string(state.play_columns_staging[i])))
	end
	print('}')
end

function core.copy_state(state_orig)
	local state_copy = {}
	state_copy.draw_type               = state_orig.draw_type
	state_copy.player_count            = state_orig.player_count
	state_copy.move_count              = state_orig.move_count
	state_copy.time_elapsed            = state_orig.time_elapsed
	state_copy.deck_unrevealed         = cards.copy_card_ary(state_orig.deck_unrevealed)
	state_copy.deck_draw               = cards.copy_card_ary(state_orig.deck_draw)
	state_copy.deck_discard            = cards.copy_card_ary(state_orig.deck_discard)
	state_copy.play_columns_unrevealed = cards.copy_card_ary_ary(state_orig.play_columns_unrevealed)
	state_copy.play_columns_staging    = cards.copy_card_ary_ary(state_orig.play_columns_staging)
	state_copy.goal_stacks             = cards.copy_card_ary_ary(state_orig.goal_stacks)
	state_copy.players                 = {}
	for i, player_state in ipairs(state_orig.players) do
		state_copy.players[i] = {}
		state_copy.players[i].y               = player_state.y
		state_copy.players[i].x               = player_state.x
		state_copy.players[i].holding         = cards.copy_card_ary(player_state.holding)
		state_copy.players[i].holding_src     = player_state.holding_src
		state_copy.players[i].holding_src_col = player_state.holding_src_col
		state_copy.players[i].moved           = moved
	end
	return state_copy
end

function core.get_held_cards(state, player)
	return state.players[player].holding
end

-- pos_info = {
-- 		section_type = core.SECTION_PLAY_*,
-- 		col = int, 
-- }
function core.can_place_card(state, held_cards, pos_info)
	if pos_info == nil then
		return false
	end

	local held_card_top = nil
	if #held_cards == 0 then
		return false
	else
		held_card_top = held_cards[1]
	end

	if pos_info.section_type == core.SECTION_PLAY_COLUMN_STAGING then
		if #state.play_columns_staging[pos_info.col] > 0 then
			local dst_card_top = state.play_columns_staging[pos_info.col][#state.play_columns_staging[pos_info.col]]
			return (cards.suit_is_red(dst_card_top.suit) ~= cards.suit_is_red(held_card_top.suit) and 
			       held_card_top.val == dst_card_top.val - 1)
		else
			return held_card_top.val == cards.KING
		end
	elseif pos_info.section_type == core.SECTION_GOAL_STACKS then
		if #held_cards > 1 then
			return false
		end
		if #state.goal_stacks[pos_info.col] == 0 then
			return held_card_top.val == cards.ACE
		else
			local dst_card_top = state.goal_stacks[pos_info.col][#state.goal_stacks[pos_info.col]]
			return (held_card_top.suit == dst_card_top.suit and held_card_top.val == dst_card_top.val + 1)
		end
	else
		print("can_place_card: unhandled section_type", pos_info.section_type)
		return false
	end
end

function core.handle_mousemove(state, player, pos_y, pos_x)
	local player = state.players[player]
	player.y = pos_y
	player.x = pos_x

	if player.y_start ~= nil and math.abs(player.y_start - pos_y) > MAX_MOVE_FOR_CLICK or
	   player.x_start ~= nil and math.abs(player.x_start - pos_x) > MAX_MOVE_FOR_CLICK then
		player.moved = true
	end
end

function core.get_card_ary(state, section_type, col)
	-- TODO: change all references to this enum
	if section_type == core.SECTION_DECK_DRAW then
		return state.deck_draw
	elseif section_type == core.SECTION_PLAY_COLUMN_STAGING then
		return state.play_columns_staging[col]
	elseif section_type == core.SECTION_GOAL_STACKS then
		return state.goal_stacks[col]
	else
		error(string.format("get_card_ary section_type %s unexpected", section_type))
	end
end

function core.next_in_deck(state)
	-- This can be confusing: for most lists of cards, we always draw from the end.
	-- For the case where the user clicks the deck, remove from end of deck_unrevealed, and insert at end of deck_draw
	-- When moving cards from deck_draw to deck_discard, remove from beginning of deck_draw, but insert at end of deck_discard.
	-- If the player runs out of deck_discard cards, draw from end of deck_discard.
		if #state.deck_unrevealed > 0 then
			while #state.deck_draw > 0 do
				table.insert(state.deck_discard, table.remove(state.deck_draw, 1))
			end
			for _=1,state.draw_type do
				if #state.deck_unrevealed == 0 then
					goto draw_from_deck -- continue
				end
				local card = table.remove(state.deck_unrevealed)
				table.insert(state.deck_draw, card)
				::draw_from_deck::
			end
		else
			while #state.deck_draw > 0 do
				table.insert(state.deck_discard, table.remove(state.deck_draw, 1))
				--table.insert(state.deck_discard, table.remove(state.deck_draw))
			end

			while #state.deck_discard > 0 do
				table.insert(state.deck_unrevealed, table.remove(state.deck_discard))
			end
		end
	core.inc_move_count(state)
end

function core.handle_mouse_down(player, state, pos_info)
	local rc = false
	if pos_info ~= nil then
		state.players[player].y = pos_info.y
		state.players[player].x = pos_info.x
		state.players[player].y_start = pos_info.y
		state.players[player].x_start = pos_info.x
	end

	state.players[player].moved = false

	if pos_info == nil then
		-- pass
	elseif pos_info.section_type == core.SECTION_DECK_UNREVEALED then
		core.next_in_deck(state)
		rc = true
	elseif #state.players[player].holding == 0 then
		if pos_info.section_type == core.SECTION_PLAY_COLUMN_UNREVEALED then
			if #state.play_columns_staging[pos_info.col] == 0 and
			   #state.play_columns_unrevealed[pos_info.col] > 0 then
				local card = table.remove(state.play_columns_unrevealed[pos_info.col])
				table.insert(state.play_columns_staging[pos_info.col], card)
			end
		elseif pos_info.section_type == core.SECTION_DECK_DRAW then
			if #state.deck_draw > 0 then
				local card = table.remove(state.deck_draw)
				state.players[player].holding = {card}
				state.players[player].holding_src = pos_info.section_type
				print(string.format("player picked up cards %s", cards.card_ary_to_string(state.players[player].holding)))
			end
		elseif pos_info.section_type == core.SECTION_PLAY_COLUMN_STAGING then
			local stack = core.get_card_ary(state, pos_info.section_type, pos_info.col)
			if #stack > 0 then
				state.players[player].holding = {}
				while #stack >= pos_info.idx do
					table.insert(state.players[player].holding, table.remove(stack, pos_info.idx))
				end
				state.players[player].holding_src = pos_info.section_type
				state.players[player].holding_src_col = pos_info.col
			end
		elseif pos_info.section_type == core.SECTION_GOAL_STACKS then
			local stack = core.get_card_ary(state, pos_info.section_type, pos_info.col)
			if #stack > 0 then
				state.players[player].holding = {table.remove(stack)}
				state.players[player].holding_src = pos_info.section_type
				state.players[player].holding_src_col = pos_info.col
			end
		end
	end

	if pos_info ~= nil and pos_info.card_src_y ~= nil and pos_info.card_src_x ~= nil then 
		state.players[player].y_card_offset = pos_info.y - pos_info.card_src_y
		state.players[player].x_card_offset = pos_info.x - pos_info.card_src_x
	end
	return rc
end

local function restore_card(state, player)
	local player_state = state.players[player]
	local stack = core.get_card_ary(state, player_state.holding_src, player_state.holding_src_col)
	while #player_state.holding > 0 do
		local card = table.remove(player_state.holding, 1)
		table.insert(stack, card)
	end
end

function core.move_held_cards_to_dst(state, player, pos_info)
	local stack = core.get_card_ary(state, pos_info.section_type, pos_info.col)
	local player_state = state.players[player]
	while #player_state.holding > 0 do
		local card = table.remove(player_state.holding, 1)
		table.insert(stack, card)
	end
end

function core.inc_move_count(state)
	if state.move_count ~= nil then
		state.move_count = state.move_count + 1
	end
end 

function core.update_time_elapsed(state, dt_ms)
	if state == nil then return end
	if state.time_elapsed == nil then
		return
	end

	if core.game_won(state) then
		return
	end

	if state.last_time_elapsed_update == nil then
		state.last_time_elapsed_update = 0
	end
	state.last_time_elapsed_update = state.last_time_elapsed_update + dt_ms
	if state.last_time_elapsed_update >= 1000 then
		state.last_time_elapsed_update = state.last_time_elapsed_update - 1000
		state.time_elapsed = state.time_elapsed + 1
	end
end

function core.handle_mouse_up(player, state, pos_info)
	local rc = false
	local player_state = state.players[player]
	if #player_state.holding == 0 then
		--print("player not holding anything")
		goto done
	end

	if not player_state.moved then
		--print("player not moved")
		if pos_info == nil then
			print("hitting this case")
			restore_card(state, player)
			goto done
		end

		-- TODO clean this up... need to put the card back before we attempt an auto move.
		local stack = core.get_card_ary(state, player_state.holding_src, player_state.holding_src_col)
		while #player_state.holding > 0 do
			local card = table.remove(player_state.holding, 1)
			table.insert(stack, card)
		end
		player_state.holding = {}
		player_state.holding_src = nil

		if pos_info.section_type == core.SECTION_PLAY_COLUMN_UNREVEALED then
			pos_info.section_type = core.SECTION_PLAY_COLUMN_STAGING
		end

		-- print("trying to auto move card")
		rc = core.auto_move_card(player, state, pos_info)
		goto done
	end

	if core.can_place_card(state, core.get_held_cards(state, player), pos_info) then
		--print("can place card...")
		core.move_held_cards_to_dst(state, player, pos_info)
		if #state.deck_draw == 0 and #state.deck_discard > 0 then
			local card = table.remove(state.deck_discard)
			table.insert(state.deck_draw, card)
		end
		rc = true
	else
		--print("can not place card, restoring...")
		restore_card(state, player)
	end
	player_state.holding = {}
	player_state.holding_src = nil


	::done::

	if rc then
		core.inc_move_count(state)
	end
	state.players[player].y_card_offset = 0
	state.players[player].x_card_offset = 0
	return rc

end

function core.copy_pos_info(pos_info)
	local new_pos_info = {
		section_type = pos_info.section_type,
		col          = pos_info.col,
		idx          = pos_info.idx,
		cards        = pos_info.cards,
	}
	return new_pos_info
end

function core.copy_move(move)
	local new_move = {
		src = core.copy_pos_info(move.src),
		dst = core.copy_pos_info(move.dst),
	}
	return new_move
end

function core.handle_move(state, player, move)
	assert(#state.players[player].holding == 0)
	core.handle_mouse_down(player, state, move.src)
	assert(#state.players[player].holding >= 1)

	if move.src.cards ~= nil then
		assert(cards.cards_eq(state.players[player].holding[1], move.src.cards[1]))
	end
	state.players[player].moved = true -- TODO CLEAN UP
	local rc = core.handle_mouse_up(player, state, move.dst)
	assert(#state.players[player].holding == 0)

	-- Click to reveal any cards that can now be revealed in the play columns
	if move.src.section_type == core.SECTION_PLAY_COLUMN_STAGING and
	   #state.play_columns_staging[move.src.col] == 0 and
	   #state.play_columns_unrevealed[move.src.col] > 0 then
		local new_src = { section_type = core.SECTION_PLAY_COLUMN_UNREVEALED, col = move.src.col }
		core.handle_mouse_down(player, state, new_src )
		core.handle_mouse_up(player, state, new_src )
		assert(#state.players[player].holding == 0)
	end

	return rc
end

local function get_card_from_pos_info(state, pos_info)
	local ary = core.get_card_ary(state, pos_info.section_type, pos_info.col)
	if #ary == 0 then
		return nil
	end

	return ary[#ary]
end

local function find_auto_move_card_spot(state, pos_info)
	local card = get_card_from_pos_info(state, pos_info)

	if card == nil then
		return
	end

	for i, stack in ipairs(state.goal_stacks) do
		if card.val == cards.ACE then
			if #stack == 0 then
				return i
			end
		elseif #stack > 0 and stack[#stack].suit == card.suit then
			if stack[#stack].val == card.val - 1 then
				return i
			else
				return nil
			end
		end
	end
	return nil
end

function core.auto_move_card(player, state, pos_info)
	local rc = false
	local idx = find_auto_move_card_spot(state, pos_info)
	if idx ~= nil then
		local card = table.remove(core.get_card_ary(state, pos_info.section_type, pos_info.col))
		table.insert(state.goal_stacks[idx], card)
		rc = true
	end

	-- If card moved was the last draw card, put one from the discard pile on the draw pile.
	if pos_info.section_type == core.SECTION_DECK_DRAW and #state.deck_draw == 0 and #state.deck_discard > 0 then
		local card = table.remove(state.deck_discard)
		table.insert(state.deck_draw, card)
	end
	return rc
end

function core.autocomplete_available(state)
	return core.play_cols_unrevealed_empty(state)
end

function core.play_cols_unrevealed_empty(state)
	for i=1,core.NUM_PLAY_COLUMNS do
		if #state.play_columns_unrevealed[i] > 0 then
			return false
		end
	end
	return true
end

function core.get_autocomplete_move_list(state_orig)
	-- TODO there is a bug here where it doesn't check the last card
	-- if the deck only has one card in it? Something like that
	-- I tried the autocomplete feature and it got all the way to the end,
	-- but there was a single king left in the deck that it couldn't find

	-- TODO uncomment below
	if false then
	-- if not core.autocomplete_available(state_orig) then
		print("autocomplete not available")
		return
	end

	local move_list = {}

	local state_copy = core.copy_state(state_orig)

	local changed = true
	while changed do
		::play_columns_loop::
		changed = false
		for i,_ in ipairs(state_copy.play_columns_staging) do
			local src_pos_info = {
				section_type = core.SECTION_PLAY_COLUMN_STAGING,
				col = i,
			}
			local idx = find_auto_move_card_spot(state_copy, src_pos_info)
			if idx ~= nil then
				local dst_pos_info = {
					section_type = core.SECTION_GOAL_STACKS,
					col = idx,
				}
				table.insert(move_list, { move = core.ACTION_MOVE, src = src_pos_info, dst = dst_pos_info })
				local card = table.remove(core.get_card_ary(state_copy, src_pos_info.section_type, src_pos_info.col))
				table.insert(state_copy.goal_stacks[idx], card)
				changed = true
			end
		end
		if changed then
			goto play_columns_loop
		end

		
		--local deck_size_start = #state_copy.deck_unrevealed + #state_copy.deck_draw + #state_copy.deck_discard
		--local deck_pos_start  = #state_copy.deck_discard
		--local deck_pos_end    = nil
		--if deck_size_start > 0 then
		--	deck_pos_end = (deck_pos_start - 1) % deck_size_start
		--else
		--	deck_pos_end = 0
		--end
		local deck_pos_counter = 0
		local deck_pos_counter_end = math.ceil((#state_copy.deck_unrevealed + #state_copy.deck_draw + #state_copy.deck_discard)/state_copy.draw_type)

		while true do
			::next_deck::
			local src_pos_info = {
				section_type = core.SECTION_DECK_DRAW,
				col          = 1,
			}
			local idx = find_auto_move_card_spot(state_copy, src_pos_info)

			if idx == nil then
				deck_pos_counter = deck_pos_counter + 1
				-- TODO loop forever here to test error handling on OOM
				if deck_pos_counter <= deck_pos_counter_end then
					table.insert(move_list, { move = core.ACTION_DECK_NEXT })
					core.next_in_deck(state_copy)
					goto next_deck
				end
			else
				local dst_pos_info = {
					section_type = core.SECTION_GOAL_STACKS,
					col = idx,
				}
				table.insert(move_list, { move = core.ACTION_MOVE, src = src_pos_info, dst = dst_pos_info })
				local card = table.remove(core.get_card_ary(state_copy, src_pos_info.section_type, src_pos_info.col))
				table.insert(state_copy.goal_stacks[idx], card)
				changed = true
				goto play_columns_loop
			end
			break
		end
	end
	return move_list
end

function core.autocomplete(state, handle_move_list)
	local move_list = core.get_autocomplete_move_list(state)
	if #move_list > 0 then
		print("autocomplete moves", #move_list)
		handle_move_list(move_list)
	else
		print("can't autocomplete, no moves found")
	end
end

function core.remove_card_from_move(state, pos_info)
	local ary = core.get_card_ary(state, pos_info.section_type, pos_info.col)
	return table.remove(ary, #ary)
end

return core
