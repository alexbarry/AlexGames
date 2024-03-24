local solve = {}

local cards     = require("libs/cards/cards")
local cards_set = require("libs/cards/cards_set")
local utils     = require("libs/utils")
local core      = require("games/solitaire/solitaire_core")
local solitaire_serialize = require("games/solitaire/solitaire_serialize")

--[[
--  TODO: need to try traversing these trees in real time to see what 
--        they manage to do in so much wasted time.
--        Implement logic to favour moves that I would in real life.
--        Also keep an eye out for bad moves that should never be allowed,
--        or should be heavily deprioritized.
--        To do figure out the most effective ways to fix all this:
--            * make nodes reference each other, and
--            * make a nicely readable state to ASCII function, likely using the ascii symbols
--              for heart/diamond/clubs/spades
--            * at each state, print a list of all possible moves, and all the moves that each one led to.
--              This should help estimate how much time is being wasted.
--            * Allow easily traversing the graph with keyboard shortcuts.
--]]


local MOVE_POS_DECK  = 1
local MOVE_POS_GOAL  = 3


--[[
-- These priorities seem to get pretty good results
local PRI_MOVE_TO_GOAL_STACK        = 1
local PRI_MOVE_KING_TO_EMPTY_COL    = 2
local PRI_MOVE_LAST_CARDS_IN_STAGING = 3
local PRI_NORMAL                    = 3
local PRI_MOVE_FROM_DECK            = nil
local PRI_MOVE_AROUND_STAGING       = nil
local PRI_MOVE_FROM_GOAL_STACK      = 6
local NUM_PRIORITIES = 6
--]]

local PRI_MOVE_TO_GOAL_STACK        = 1
local PRI_MOVE_KING_TO_EMPTY_COL    = 2
local PRI_MOVE_LAST_CARDS_IN_STAGING = 3 -- TODO increasing this above normal doesn't seem to help
local PRI_NORMAL                    = 3
local PRI_MOVE_FROM_DECK            = nil
local PRI_MOVE_AROUND_STAGING       = nil
local PRI_MOVE_FROM_GOAL_STACK      = 6
local NUM_PRIORITIES = 6

local SECTION_DECK_POS_INDEPENDENT = core.SECTION_LAST + 1

local player = 1 -- TODO

-- converts suit to an index from 1 to 4.
-- Used to choose which goal stack to put cards in,
-- to avoid a bunch of duplicate positions
local suit_idx_map = {}

for i, suit in ipairs(cards.suits) do
	suit_idx_map[suit] = i
end

-- TODO: print each move, so I can figure out what is going on.
-- keep track of prev move


--[[
-- Here is my plan for a solitaire solving algorithm:
--   make a "state to hash" api that returns a string that represents a unique
--   game state-- but returning the same hash for trivial variations of the same state,
--   such as:
--      * cycling through the deck, and
--      * moving a king (or its stack) from one empty column to another
--   I think I can simply:
--      * always hash the deck as if it were not opened, and
--      * have a separate set of columns for kings on an empty column?
--
--
-- Then I'd guess that it would be as simple as:
--    * loop through all possible moves, recurse...?
--
-- Since I'm taking shortcuts, I couldn't consider "reveal next card in deck" as a move.
-- So I'd have to loop through every possible move for every possible card in the deck.
-- That's not too hard either.
--
-- Then that's it? Return true once it's possible to reach a state where all the unrevealed
-- cards are revealed?
--]]

local function section_type_to_string(section_type)
	local type_to_str = {
		[core.SECTION_PLAY_COLUMN_UNREVEALED] = 'PLAY_COL_U',
		[core.SECTION_PLAY_COLUMN_STAGING]    = 'PLAY_COL',
		[core.SECTION_GOAL_STACKS]            = 'GOAL',
		[SECTION_DECK_POS_INDEPENDENT]        = 'DECK_PI',
	}
	return type_to_str[section_type]
end

local function format_int(val, chars)
	if val == nil then
		--return string.format("%-*s", chars, val)
		return string.format("%-" .. chars .. "s", val)
	else
		return string.format("%" .. chars .. "d", val)
	end
end

local function pos_to_str(pos)
	local s = string.format("{%-8s, %s, %s;",
	      section_type_to_string(pos.section_type), format_int(pos.col, 3), format_int(pos.idx, 3))
	if pos.card ~= nil then
		s = s .. string.format(" (%-12s)", cards.card_to_string(pos.card))
	end
	s = s .. "}"
	return s
end

local function print_move(prev_state_id, move, next_state_id, is_duplicate_state, info)
	local dup_string = ""
	if is_duplicate_state then
		dup_string = "(visited)"
	end
	print(string.format("from state id=%3d, src%s -> dst%s to state id %3d%s; %s",
	      prev_state_id,
	      pos_to_str(move.src),
	      pos_to_str(move.dst),
	      next_state_id, dup_string, info))
end
		

local function get_deck_pos_independent(state)
	local deck = {}
	for _, card in ipairs(state.deck_revealed) do
		table.insert(deck, card)
	end
	--for _, card in ipairs(state.deck_unrevealed) do
	for i=#state.deck_unrevealed,1,-1 do
		local card = state.deck_unrevealed[i]
		table.insert(deck, card)
	end

	return deck
end


-- Returns the serialized card array for each goal stack
-- in the order of cards.suits
-- 
-- The purpose is so that a whole new game isn't simulated
-- if the player chose to put the hearts in goal stack 1 or 2
function solve.get_goal_stacks_hash(state)
	local hash = ''
	for _, suit in ipairs(cards.suits) do
		local stack = {}
		for i=1,#state.goal_stacks do
			if #state.goal_stacks[i] > 0 and state.goal_stacks[i][1].suit == suit then
				stack = state.goal_stacks[i]
			end
		end
		hash = hash .. cards.serialize_card_array(stack)
	end
	return hash
end

function solve.state_to_hash(state)

	local hash = ''

	hash = hash .. cards.serialize_card_array(get_deck_pos_independent(state))
	hash = hash .. solve.get_goal_stacks_hash(state)

	local empty_stacks = {}

	local group_empty_stacks = true

	for i=1,core.NUM_PLAY_COLUMNS do
		local unrevealed = state.play_columns_unrevealed[i]
		local staging    = state.play_columns_staging[i]
		if group_empty_stacks and #unrevealed == 0 then
			table.insert(empty_stacks, staging)
			staging = {}
		end
		hash = hash .. cards.serialize_card_array(unrevealed)
		hash = hash .. cards.serialize_card_array(staging)
	end

	if group_empty_stacks then
	for _, suit in ipairs(cards.suits) do
		local suit_stack = {}
		for _, stack in ipairs(empty_stacks) do
			if #stack > 0 and stack[1].suit == suit then
				suit_stack = stack
			end
		end
		hash = hash .. cards.serialize_card_array(suit_stack)
	end
	end

	return hash
end

local function get_card_stack_positions_quick_order(num)
	if num == 0 then return { }
	elseif num == 1 then return { 1 }
	else
		local list = { 1, num }
		for i=2,num-1 do
			table.insert(list, i)
		end
		return list
	end
end

function solve.get_possib_src_cards(state)
	local src_cards = {}
	for i=1,core.NUM_PLAY_COLUMNS do
		local play_col = state.play_columns_staging[i]
		-- for j=#play_col,1,-1 do
		for _, j in ipairs(get_card_stack_positions_quick_order(#play_col)) do
			local card_stack = {}
			for k=j,#play_col do
				table.insert(card_stack, play_col[k])
			end
			table.insert(src_cards, {
				section_type = core.SECTION_PLAY_COLUMN_STAGING,
				col = i,
				idx = j,
				cards = card_stack,
				--card = play_col[j], -- TODO replace with card stack
			})
		end
	end

	for i=1,core.NUM_GOAL_STACKS do
		local stack = state.goal_stacks[i]
		if #stack > 0 then
			table.insert(src_cards, {
				section_type = core.SECTION_GOAL_STACKS,
				col = i,
				idx = #stack,
				cards = {stack[#stack]},
			})
		end
	end

	local deck = get_deck_pos_independent(state)
	for i=1,#deck do
		table.insert(src_cards, {
			section_type = SECTION_DECK_POS_INDEPENDENT,
			col = i,
			cards = {deck[i]},
		})
	end

	-- return cards_set.card_list_to_set(src_cards)
	return src_cards
end

function solve.get_possib_dsts(state)
	local dsts = {}

	for i=1,core.NUM_GOAL_STACKS do
		table.insert(dsts, {
			section_type = core.SECTION_GOAL_STACKS,
			col = i
		})
	end

	for i=1,core.NUM_PLAY_COLUMNS do
		table.insert(dsts, {
			section_type = core.SECTION_PLAY_COLUMN_STAGING,
			col = i,
		})
	end

	return dsts
end

function is_useful_move(state, src_info, dst_info)
	--assert(#src_info.cards > 0)
	--print(cards.card_array_to_string(src_info.cards))
	if src_info.section_type == core.SECTION_GOAL_STACKS and
	   dst_info.section_type == core.SECTION_GOAL_STACKS then
		return false
	elseif dst_info.section_type == core.SECTION_GOAL_STACKS and
	       suit_idx_map[src_info.cards[1].suit] ~= dst_info.col then
		return false
	-- moving kings around empty columns is not useful
	elseif src_info.section_type == core.SECTION_PLAY_COLUMN_STAGING and
	       dst_info.section_type == core.SECTION_PLAY_COLUMN_STAGING and
	       src_info.cards[1].val == cards.KING and
	       #state.play_columns_unrevealed[src_info.col] == 0 then
		return false
	end
	if dst_info.section_type ~= core.SECTION_GOAL_STACKS then
		--print("WARNING: SKIPPING DST NON GOAL STACKS MOVE FOR TESTING")
		--return false
	end

	return true
end

function new_move_priority_queue(priorities)
	local moves = {}
	for i=1,priorities do
		table.insert(moves, {})
	end
	return moves
end

function add_move(moves, priority, move_info)
	table.insert(moves[priority], move_info)
end


function has_moves(moves)
	for _, priority_list in ipairs(moves) do
		if #priority_list > 0 then return true end
	end
	return false
end

function moves_count(moves)
	local count = 0
	for _, queue in ipairs(moves) do
		count = count + #queue
	end
	return count
end

function get_move_count_str(moves)
	s = '{'
	for i, queue in ipairs(moves) do
		if i ~= 1 then s = s .. ', ' end
		s = s .. string.format('%d', #queue)
	end
	return s .. '}'
end

function get_move_priority(state, move)
	if move.src.section_type == core.SECTION_GOAL_STACKS then
		return PRI_MOVE_FROM_GOAL_STACK
	elseif move.dst.section_type == core.SECTION_GOAL_STACKS then
		return PRI_MOVE_TO_GOAL_STACK

	elseif move.src.section_type == core.SECTION_PLAY_COLUMN_STAGING and
		-- interestingly, changing this from #col == 1 to #col == #cards_held
		-- results in the first few tests going from 250 ms to ~10 ms,
		-- but test 4 goes up from 420 ms to 3480 s.
	       #state.play_columns_staging[move.src.col] == #move.src.cards then
	       -- #state.play_columns_staging[move.src.col] == 1 then
		return PRI_MOVE_LAST_CARDS_IN_STAGING
	elseif PRI_MOVE_KING_TO_EMPTY_COL ~= nil and
	       move.src.cards[1].val == cards.KING and
	       move.src.section_type == core.SECTION_PLAY_COLUMN_STAGING and
	       move.dst.section_type == core.SECTION_PLAY_COLUMN_STAGING and
	       #state.play_columns_staging[move.dst.col] == 0 then
		return PRI_MOVE_KING_TO_EMPTY_COL
	elseif PRI_MOVE_FROM_DECK ~= nil and
	       move.src.section_type == SECTION_DECK_POS_INDEPENDENT then
		return PRI_MOVE_FROM_DECK
	elseif PRI_MOVE_AROUND_STAGING ~= nil and 
	       move.src.section_type == core.SECTION_PLAY_COLUMN_STAGING and
	       move.dst.section_type == core.SECTION_PLAY_COLUMN_STAGING then
		return PRI_MOVE_AROUND_STAGING
	else
		return PRI_NORMAL
	end
end

function pop_move(moves)
	for _, queue in ipairs(moves) do
		if #queue > 0 then
			return table.remove(queue)
		end
	end
	error("popped on empty queue", 2)
end

function merge_moves(moves, new_moves)
	for priority, queue in ipairs(new_moves) do
		for _, move_info in ipairs(queue) do
			table.insert(moves[priority], move_info)
		end
	end
end


function solve.get_possib_moves(state, prev_state_id, state)
	local moves = new_move_priority_queue(NUM_PRIORITIES)
	-- print("deck: ", #state.deck_unrevealed, #state.deck_revealed, #get_deck_pos_independent(state))
	local srcs = solve.get_possib_src_cards(state)
	local dsts = solve.get_possib_dsts(state)
	--print(string.format("found %d possib srcs, %d possib dsts", #srcs, #dsts))
	for _, src_info in ipairs(srcs) do
		for _, dst_info in ipairs(dsts) do
			local useful_move = false
			if core.can_place_card(state, src_info.cards, dst_info) and
               is_useful_move(state, src_info, dst_info) then
				--table.insert(moves, {src = src_info, dst = dst_info})
				local move = {src = src_info, dst = dst_info}
				local priority = get_move_priority(state, move)
				local move_info = { 
					prev_state_id = prev_state_id,
					state = state, -- TODO remove this copy
					move = move,
				}
				add_move(moves, priority, move_info)
				useful_move = true
			end
			--[[
			print(string.format("checking if src=%s card=%-13s can be moved to dst=%s: %s, %s",
                  section_type_to_string(src_info.section_type),
			      cards.card_to_string(src_info.card),
                  section_type_to_string(dst_info.section_type),
                  core.can_place_card(state, src_info.card, dst_info),
                  core.can_place_card(state, src_info.card, dst_info)  and is_useful_move(state, src_info, dst_info)))
			]]
		end
	end
	return moves
end

local function make_move(state, move)
	move = core.copy_move(move)
	--core.print_state(state)
	--print(string.format("attempting to move from %s to %s", pos_to_str(move.src), pos_to_str(move.dst)))
	if move.src.section_type == SECTION_DECK_POS_INDEPENDENT then
		while #state.deck_revealed ~= move.src.col do
			core.handle_mouse_down(player, state, {section_type = core.SECTION_DECK_UNREVEALED })
		end
		--print(cards.card_to_string(state.deck_revealed[#state.deck_revealed]), cards.card_to_string(move.src.card))
		assert(cards.cards_eq(state.deck_revealed[#state.deck_revealed], move.src.cards[1]))
		move.src = {section_type = core.SECTION_DECK_REVEALED}
	end

	core.handle_move(state, player, move)

	for i=1,core.NUM_PLAY_COLUMNS do
		if #state.play_columns_staging[i] == 0 then
			assert(#state.play_columns_unrevealed[i] == 0)
		end
	end
end

local function get_cards_in_goals(state)
	local count = 0
	for _, goal_stack in ipairs(state.goal_stacks) do
		count = count + #goal_stack
	end
	return count
end

local function get_hidden_cards(state)
	local count = 0
	for _, hidden_stack in ipairs(state.play_columns_unrevealed) do
		count = count + #hidden_stack
	end
	return count
end


function solve.new_solve_state(params)
	local new_solve_state = {
		params = params,
		max_goal_cards = 0,
		min_hidden_cards = nil,
		best_cards_state = nil,
	}
	return new_solve_state
end

function solve.is_solvable(state, solve_state)
	if solve_state == nil then
		solve_state = solve.new_solve_state()
	end
	solve_state.start_time = os.time()
	local seen_states = {}
	local moves_to_try = new_move_priority_queue(NUM_PRIORITIES)

	-- TODO I need to think about this.
	-- * Keep track of the current state.
	-- * for every possible move from the current state, try
	--   making each move and see what happens to the state.
	-- * Then recurse. But stop if you already encountered this state before.
	--   Return true if all play_columns_unrevealed are empty

	-- So:
	-- * store current state in a node,
	-- * for each possible move, copy state, apply move, check hash.
	-- * if hash is already in map, skip-- duplicate result.
	-- * if hash is not in map, then create a new node and repeat

	local new_moves = solve.get_possib_moves(state, 0, state)
	--print("new_moves init: ", has_moves(new_moves))
	merge_moves(moves_to_try, new_moves)

	solve_state.counter = 0
	solve_state.unique_states_counter = 0
	while has_moves(moves_to_try) do
		--print(string.format("count=%d, unique_states=%d, moves_to_try=%d", counter, unique_states_counter, moves_count(moves_to_try)))
		solve_state.counter = solve_state.counter + 1
		--local move_to_try = table.remove(moves_to_try)
		local move_to_try = pop_move(moves_to_try)
		--local move_to_try = table.remove(moves_to_try, 1)
		local state2 = core.copy_state(move_to_try.state)

		make_move(state2, move_to_try.move)

		if core.play_cols_unrevealed_empty(state2) then
			return true
		end


		local state2_hash = solve.state_to_hash(state2)


		local is_duplicate_state
		if seen_states[state2_hash] == nil then
			solve_state.unique_states_counter = solve_state.unique_states_counter + 1
			seen_states[state2_hash] = solve_state.unique_states_counter
			is_duplicate_state = false
		else
			is_duplicate_state = true
		end

		local goal_cards = get_cards_in_goals(state2)
		local hidden_cards = get_hidden_cards(state2)
		--if goal_cards >= max_goal_cards then
		if solve_state.min_hidden_cards == nil or hidden_cards <= solve_state.min_hidden_cards then
			solve_state.max_goal_cards = goal_cards 
			solve_state.min_hidden_cards = hidden_cards
			solve_state.best_cards_state = core.copy_state(state2)
		end

		assert(#state.players[player].holding == 0)
		local next_state_id = seen_states[state2_hash]
		--print(string.format("%3d: %s", next_state_id, utils.binstr_to_hr_str(state2_hash)))
		--print(string.format("%3d state ser: %s", next_state_id, utils.binstr_to_hr_str(solitaire_serialize.serialize_state(state2))))


		if true or not is_duplicate_state then
			--print_move(move_to_try.prev_state_id, move_to_try.move, next_state_id, is_duplicate_state, get_cards_in_goals(state2))
		end

		if solve_state.params.update_period ~= nil and 
		   solve_state.counter % solve_state.params.update_period == 0 then
			if solve_state.params.id ~= nil then
				print(solve_state.params.id)
			end
			print(string.format("counter %d, min_hidden_cards = %d, max_goal_cards = %d", solve_state.counter, solve_state.min_hidden_cards, solve_state.max_goal_cards))
			print(string.format("count=%d, unique_states=%d, moves_to_try=%s", solve_state.counter, solve_state.unique_states_counter, get_move_count_str(moves_to_try)))
			core.print_state(solve_state.best_cards_state)
			print(string.format("board_state_ser: %s", utils.binstr_to_hr_str(solitaire_serialize.serialize_board_state(state2))))
			collectgarbage("collect")
		end

		local time_s = os.time()
		if solve_state.params.timeout_s ~= nil and
		   time_s - solve_state.start_time >= solve_state.params.timeout_s then
			error("solvable check timed out")
		end

		if is_duplicate_state then
			goto next_move
		end

		local new_moves = solve.get_possib_moves(state, seen_states[state2_hash], state2)
		merge_moves(moves_to_try, new_moves)


		::next_move::
	end

	return false
end


return solve
