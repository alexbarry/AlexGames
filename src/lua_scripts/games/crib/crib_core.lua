local core = {}
-- Notes from what I remember Sabrina telling me:
-- state.PICK_DISCARD
--     players are given enough cards that they can discard 0 to 2 and end up with 4 cards in their hand,
--     and total of 4 discarded cards that form the "crib" of one player.
-- state.PLAY
--     A card might be drawn from the deck at this point
--     Players then take turns playing one of the cards from their hand.
--     They are awarded points if the running total is 15, 31, there is a run (cards in order (or reverse order?)),
--     or four of a suit(?), and last card
--     At the end, the player whose crib it is gets awarded points for the cards in their crib.

local cards = require("libs/cards/cards")

-- TODO implement last card:
--    * still need to award a point for last card once all cards are played
--      (should add an acknowledgemepoint phase for that where all players must press "next"
--    * use this stage once 31 is reached normally
--    maybe just add a boolean like "wait_for_next_btn" which is set to true
--    only when a sum of 31 is reached, or when all players' hands are empty?
--    Need to figure out how to make this co-exist with the "can't move" button.
--    Maybe rename that one to "next"

-- TODO should implement winner, make sure points are awarded in the right order

-- TODO if a card is played resulting in a sum of 31 , clear the play thing?

-- TODO the last card played in PLAY state isn't visible to the other player(s), it
-- immediately jumps to showing your old hand. Should add a "next" button to let people acknowledge,
-- then transition to this state

-- TODO on a new hand, make sure its the player's turn who is to the left of the crib

-- TODO add an array of "last_points_reasons" in state, send to other players?
-- indicating player, points reason, and amount?
-- set it to true only for events like jack of suit on cut deck card, playing points, last card?
-- use this to show status messages, so players notice when points are added

core.states = {
	-- Players start with some number of cards and must discard to the "crib" until they have 4 left
	-- Can only exit this state once all players have discarded.
	PICK_DISCARD = 1,
	-- Players play a card, and are awarded points if they get 15/run/4 of the same suit/31
	PLAY         = 2,

	-- After the above "PLAY" state, players also get awarded points based on the 4 cards they played, plus
	-- a card from the deck that is shared by everyone.
	-- Reveal the cards to the player in this state, and proceed back to PICK_DISCARD once all players
	-- have acknowledged
	ACKNOWLEDGE_POINTS = 3,

	-- Similar to the above state, but only the player whose crib it is gets points
	ACKNOWLEDGE_CRIB = 4,
}

core.actions = {
	HAND = 1,
	DISCARD_CONFIRM = 2,
	CANT_MOVE_ACCEPT = 3,
	NEXT = 4,
}

core.point_types = {
	FIFTEEN    = 1,
	RUN        = 2,
	PAIR       = 3,
	THIRTY_ONE = 4,
	FLUSH      = 5,
	JACK_OF_SUIT = 6,
}

core.CARDS_PER_HAND = 4
core.MAX_PLAYING_SUM = 31

core.RC_SUCCESS                    = 0
core.RC_ERROR                      = -1
core.RC_WAIT_FOR_OTHERS_TO_DISCARD = -2
core.RC_NOT_YOUR_TURN              = -3
core.RC_INVALID_PARAM              = -4
core.RC_PLAY_HIGHER_THAN_31        = -5
core.RC_MUST_MOVE                  = -6

local rc_to_str_map = {
	[core.RC_SUCCESS]                    = "Success",
	[core.RC_ERROR]                      = "Error",
	[core.RC_WAIT_FOR_OTHERS_TO_DISCARD] = "Wait for other players to discard",
	[core.RC_NOT_YOUR_TURN]              = "Not your turn",
	-- I don't think the user should be able to hit this unless there's a UI error or state mismatch
	[core.RC_INVALID_PARAM]              = "Invalid parameters",
	[core.RC_PLAY_HIGHER_THAN_31]        = "Must play a card which results in a sum less than 31",
	[core.RC_MUST_MOVE]                  = "Can only skip turn if no cards can be played",
}

local JACK_OF_SUIT_CUT_DECK_POINTS  = 2
local JACK_OF_SUIT_HAND_CRIB_POINTS = 1
local LAST_CARD_POINTS              = 1

function core.rc_to_str(rc)
	return rc_to_str_map[rc]
end

function core.point_type_to_str(reason)
	local map = {
		[core.point_types.FIFTEEN]    = 'Fifteen',
		[core.point_types.RUN]        = 'Run',
		[core.point_types.PAIR]       = 'Pair',
		[core.point_types.THIRTY_ONE] = 'Thirty-one',
		[core.point_types.FLUSH]      = 'Flush',
		[core.point_types.JACK_OF_SUIT] = 'Jack of suit',
	}
	return map[reason]
end

local function deal_new_hand(state, do_shuffle)
	state.cut_deck_card = nil
	state.crib = {}
	state.playing_sequence = {}
	state.playing_sum = 0

	if do_shuffle then
		state.deck = cards.new_deck()
		cards.shuffle(state.deck)
	end

	-- each player gets at least 4 cards, 
	-- and then an extra 4 cards are distributed among the players evenly (if possible)
	-- The player must discard cards (into the crib) until they have 4 left.
	-- If the crib does not have 4 cards right now, add deck cards until it is 4
	local player_cards_to_discard = math.floor(core.CARDS_PER_HAND/state.player_count)
	local cards_per_hand = core.CARDS_PER_HAND + player_cards_to_discard
	local deck_cards_to_crib = core.CARDS_PER_HAND - player_cards_to_discard * state.player_count
	for player_idx=1,state.player_count do
		state.hands[player_idx] = {}
		state.tentative_discards[player_idx] = {}
		state.playing[player_idx] = {}
		state.played[player_idx] = {}
		for _=1,cards_per_hand do
			table.insert(state.hands[player_idx], table.remove(state.deck, 1))
			table.insert(state.tentative_discards[player_idx], false)
		end
	end
	for _=1,deck_cards_to_crib do
		table.insert(state.crib, table.remove(state.deck))
	end
end


-- deck is optional, if nil or not provided then will generate and shuffle a deck
function core.new_game(player_count, deck)
	if deck == nil then
		deck = cards.new_deck()
		cards.shuffle(deck)
	end
	local state = {
		state = core.states.PICK_DISCARD,
		player_count = player_count,
		deck = deck,
		score = {},
		hands = {},

		-- extra card that is drawn after the discard is done, but before players start playing/pegging
		cut_deck_card = nil, -- is this name good?

		-- these are cards that count towards the current total of 31
		playing = {},

		-- these are cards that at one point counted towards the
		-- total of 31, but the limit was reached and now
		-- they are put aside until everyone has played all the cards
		-- in their hands, so that later all the played cards can be looked
		-- at to determine points
		played = {},

		-- these are copies of cards that have been played in the `playing` array
		-- Used to calculate runs/flush/etc
		playing_sequence = {},

		-- these are cards that the user has selected to discard for the crib, but they haven't yet
		-- pressed the "confirm discard" button
		tentative_discards = {},

		crib = {},

		-- array of booleans for if the player has pressed "next" when seeing the points from their hand
		-- once all have played their cards.
		-- Once all players press "next", move on to the crib
		acknowledged_points = {},

		player_crib = 1,
		player_turn = 1,
		playing_sum  = 0,

		-- set this to the player index when a player can't move.
		--    * if another player can move, clear it.
		--    * if another player can not move, leave it set.
		--      If it is still set when we return to the player who 
		--      set it originally, and that player can not move, then
		--      end that round of play
		--      (put `playing` cards in `played`, reset `playing_sum`)
		first_player_cant_move = 0,
	}
	for player_idx=1,state.player_count do
		state.score[player_idx] = 0
	end

	deal_new_hand(state, false)

	return state
end


function core.print_state(state)
	if state == nil then
		io.write("state = nil\n")
		return
	end
	io.write("state = {\n")
	io.write(string.format("    state = %s\n", state.state))
	io.write(string.format("    player_turn = %s\n", state.player_turn))
	io.write(string.format("    player_crib = %s\n", state.player_crib))
	io.write(string.format("    playing_sum  = %s\n", state.playing_sum))
	if state.deck ~= nil then
		io.write(string.format("    deck len = %d\n", #state.deck))
	else
		io.write(string.format("    deck = nil\n"))
	end

	io.write(string.format("    first_player_cant_move = %d\n", state.first_player_cant_move ))

	io.write(string.format("    playing_sequence = %s\n", cards.card_array_to_string(state.playing_sequence)))

	io.write(string.format("    hands[%d] = {\n", #state.hands))
	for player_idx, hand in pairs(state.hands) do
		io.write(string.format("      [%d] = ", player_idx))
		io.write(cards.card_array_to_string(hand))
		io.write(",\n")
	end
	io.write(string.format("    },\n"))

	io.write(string.format("    playing[%d] = {\n", #state.playing))
	for player_idx, playing in pairs(state.playing) do
		io.write(string.format("       [%d] = ", player_idx))
		io.write(cards.card_array_to_string(playing))
		io.write(",\n")
	end
	io.write(string.format("    },\n"))

	io.write(string.format("    played[%d] = {\n", #state.played))
	for player_idx, played in pairs(state.played) do
		io.write(string.format("       [%d] = ", player_idx))
		io.write(cards.card_array_to_string(played))
		io.write(",\n")
	end
	io.write(string.format("    },\n"))


	io.write(string.format("    tentative_discards[%d] = {\n", #state.tentative_discards))
	for i=1,#state.tentative_discards do
		io.write("      ")
		-- io.write("{")
		io.write(string.format("[%d] = {", i))
		for j=1,#state.tentative_discards[i] do
			io.write(string.format("%s, ", state.tentative_discards[i][j]))
		end
		io.write("},\n")
	end
	io.write(string.format("    },\n"))

	io.write(string.format("    crib = "))
	if state.crib ~= nil then
		io.write(cards.card_array_to_string(state.crib))
	else
		io.write("nil")
	end
	io.write(string.format("\n"))

	io.write(string.format("    score[%d] = {\n", #state.score))
	for i=1,#state.score do
		io.write(string.format("      [%d] = %d,\n", i, state.score[i]))
	end
	io.write("    }\n")
	io.write("}\n")
end

local function handle_discard_confirm(state, player)
	if state.state ~= core.states.PICK_DISCARD then
		error(string.format("Unexpected handle_discard_confirm from state %s", state.state))
	end

	if #state.hands[player] == core.CARDS_PER_HAND then
		error(string.format("Unexpected handle_discard_confirm when player has 4 cards"))
	end

	for i=1,#state.tentative_discards[player] do
		local i2 = #state.tentative_discards[player] - i + 1
		if state.tentative_discards[player][i2] then
			state.crib[#state.crib+1] = table.remove(state.hands[player], i2)
		end
	end

	state.tentative_discards[player] = {}

	local discard_done = true
	for player_idx=1, #state.hands do
		if #state.hands[player_idx] ~= core.CARDS_PER_HAND then
			discard_done = false
			goto done_checking_players
		end
	end
	::done_checking_players::

	if discard_done then
		state.state = core.states.PLAY
		state.cut_deck_card = table.remove(state.deck)
		if state.cut_deck_card.val == cards.JACK then
			-- TODO notify player that they were awarded points due to this
			state.score[state.player_crib] = state.score[state.player_crib] + JACK_OF_SUIT_CUT_DECK_POINTS
		end
	end 

	return core.RC_SUCCESS
end

-- TODO put in a utility library or something
local function copy_ary(ary)
	local ary_copied = {}
	for i=1,#ary do
		ary_copied[i] = ary[i]
	end
	return ary_copied
end


local function get_card_value(card)
	if card.val <= 10 then return card.val
	else return 10 end
end

local function card_order(a,b)
	return a.val < b.val
end

-- runs can be out of order,
-- so the way to check is if the sorted 
-- list of cards is sequential
local function check_is_run_add_card(sequence, card, len)
	local new_sequence = {}
	-- get the last (len-1) cards from sequence
	local start_i = #sequence - (len-1) + 1
	if start_i < 1 then
		return false
	end
	if card == nil then
		error("card is nil")
	end

	for i=start_i,#sequence do
		new_sequence[#new_sequence+1] = sequence[i]
	end
	new_sequence[#new_sequence+1] = card

	--print("new_sequence = ", cards.card_array_to_string(new_sequence))
	--for i=1,#new_sequence-1 do
	--	print("card_order(...) = ", card_order(new_sequence[i], new_sequence[i+1]))
	--end
	table.sort(new_sequence, card_order)
	--print("new_sequence = ", cards.card_array_to_string(new_sequence))

	if #new_sequence < 3 then
		error(string.format("new_sequence len is %d?", #new_sequence))
	end

	local is_run = true
	local last_elem = new_sequence[1]
	for i=2,#new_sequence do
		if new_sequence[i].val ~= last_elem.val + 1 then
			is_run = false
			goto done_run_len_check
		end
		last_elem = new_sequence[i]
	end
	::done_run_len_check::
	return is_run
	
end

local function is_run_sequence_enabled(sequence, cards_enabled)
	local enabled_seq = {}
	for i=1,#cards_enabled do
		if cards_enabled[i] then
			table.insert(enabled_seq, sequence[i])
		end
	end

	if #enabled_seq < 3 then
		return false
	end

	table.sort(enabled_seq, card_order)

	for i=1,#enabled_seq-1 do
		if enabled_seq[i+1].val ~= enabled_seq[i].val + 1 then
			return false
		end
	end

	return true
end

local function cards_enabled_to_card_idx(cards_enabled)
	local card_idxes = {}
	for i=1,#cards_enabled do
		if cards_enabled[i] then
			table.insert(card_idxes, i)
		end
	end
	return card_idxes
end

local function run_is_subsequence(run, run_ary)
	for _, run2 in ipairs(run_ary) do
		local i=1
		for j=1,#run2 do
			if run2[j] < run[i] then
				-- pass
			elseif run2[j] == run[i] then
				if i == #run then
					return true
				end
				i = i + 1
			else
				goto next_run
			end
		end
		::next_run::
	end
end

-- Only handle sequences of 5 cards,
-- and only check for runs of length 5, 4, or 3
-- Return array of array of indicies of cards that are enabled to make up a run
-- A run of 4 {2,3,4,5} must only count as one run, but
-- Two runs of 3 must be counted if they don't make a run of 4, e.g. {2, 2, 3, 4} is two runs of 3
local function check_points_sequence_run(sequence)

	if #sequence ~= 5 then
		error(string.format("checked for run on sequences of len %d", #sequence))
	end

	local cards_enabled = {}
	for i=1,#sequence do
		cards_enabled[i] = true
	end

	if is_run_sequence_enabled(sequence, cards_enabled) then
		return {cards_enabled_to_card_idx(cards_enabled)}
	end

	local runs4 = {}
	for card_disabled_idx=1,#cards_enabled do
		cards_enabled[card_disabled_idx] = false
		if is_run_sequence_enabled(sequence, cards_enabled) then
			table.insert(runs4, cards_enabled_to_card_idx(cards_enabled))
		end
		cards_enabled[card_disabled_idx] = true
	end

	-- TODO need to check for runs of length 3 that are not
	-- contained within a run of 4
	local runs3 = {}
	for card_disabled_idx1=1, #cards_enabled do
		cards_enabled[card_disabled_idx1] = false
		for card_disabled_idx2=card_disabled_idx1+1, #cards_enabled do
			cards_enabled[card_disabled_idx2] = false
			if is_run_sequence_enabled(sequence, cards_enabled) then
				local run_seq = cards_enabled_to_card_idx(cards_enabled)
				if not run_is_subsequence(run_seq, runs4) then
					table.insert(runs3, run_seq)
				end
			end
			cards_enabled[card_disabled_idx2] = true
		end
		cards_enabled[card_disabled_idx1] = true
	end

	local runs = {}
	for i=1,#runs4 do
		runs[#runs+1] = runs4[i]
	end
	for i=1,#runs3 do
		runs[#runs+1] = runs3[i]
	end

	return runs
end

local function check_points_sequence_15(sequence)
	local fifteen_count = 0
	local combinations = {}
	
	local cards_enabled = {}
	for i=1,#sequence do
		cards_enabled[i] = false
	end


	-- loop through all combinations of cards, like counting in binary:
	-- 0 0 0 0
	-- 0 0 0 1
	-- 0 0 1 0
	-- 0 0 1 1
	-- 0 1 0 0
	-- ...
	-- io.write(string.format("starting loop... %d %d\n", #sequence, #cards_enabled))
	while true do
		local sum = 0
		local debug_str = ""
		for i=1,#sequence do
			-- debug_str = debug_str .. string.format("%d ", cards_enabled[i] and 1 or 0)
			if cards_enabled[i] then
				sum = sum + get_card_value(sequence[i])
			end
		end
		--debug_str = debug_str .. string.format("; sum=%d\n", sum)
		--io.write(debug_str)
		if sum == 15 then
			fifteen_count = fifteen_count + 1
			local cards_enabled_copy = {}
			for idx,val in ipairs(cards_enabled) do
				cards_enabled_copy[idx] = val
			end
			table.insert(combinations, cards_enabled_copy)
		end

		local j = 1
		while j <= #sequence and cards_enabled[j] do
			cards_enabled[j] = false
			j = j + 1
		end
		if j > #sequence then
			goto end_loop
		else
			cards_enabled[j] = true
		end
	end
	::end_loop::
	return {
		count = fifteen_count,
		combinations = combinations,
	}
end

local function pair_count_to_points(pair_count)
	local pair_points = 0
	if pair_count == 2 then
		pair_points = 2
	elseif pair_count == 3 then
		pair_points = 6
	elseif pair_count == 4 then
		pair_points = 12
	end
	return pair_points
end



local function check_points_seqeuence_pair(sequence)
	local card_pairs = {}
	for val=cards.MIN_VAL,cards.MAX_VAL do
		local possible_pair = {}
		for j=1,#sequence do
			if sequence[j].val == val then
				table.insert(possible_pair, j)
			end
		end
		if #possible_pair > 1 then
			table.insert(card_pairs, possible_pair)
		end
	end
	return card_pairs
end

local function check_points_sequence_flush(sequence, cut_deck_card)
	local card_flushes = {}
	for _, suit in ipairs(cards.suits) do
		local possible_flush = {}
		for i=1,#sequence do
			if sequence[i].suit == suit then
				table.insert(possible_flush, i)
			end
		end

		if #possible_flush >= 4 and suit == cut_deck_card.suit then
			table.insert(possible_flush, #sequence + 1)
		end

		if #possible_flush >= 4 then
			table.insert(card_flushes, possible_flush)
		end
	end
	return card_flushes
end

function core.check_points_sequence(sequence, cut_deck_card)
	local info = {
		points_reasons = {},
		points = 0,
	}

	local sequence2 = copy_ary(sequence)
	table.insert(sequence2, cut_deck_card)

	local info_15 = check_points_sequence_15(sequence2)

	for _,combination in ipairs(info_15.combinations) do
		local card_idxs = {}
		for j=1,#combination do
			if combination[j] then
				table.insert(card_idxs, j)
			end
		end
		info.points_reasons[#info.points_reasons+1] = {
			reason = core.point_types.FIFTEEN,
			points = 2,
			card_idxs = card_idxs,
		}
	end

	info.points = info.points + info_15.count * 2

	local runs = check_points_sequence_run(sequence2)
	for _,run in ipairs(runs) do
		info.points = info.points + #run
		info.points_reasons[#info.points_reasons+1] = {
			reason = core.point_types.RUN,
			points = #run,
			card_idxs = run,
		}
	end

	local card_pairs = check_points_seqeuence_pair(sequence2)
	for _,card_pair in ipairs(card_pairs) do
		local pair_points = pair_count_to_points(#card_pair) info.points = info.points + pair_points
		info.points_reasons[#info.points_reasons+1] = {
			reason = core.point_types.PAIR,
			points = pair_points,
			card_idxs = card_pair,
		}
	end

	local card_flushes = check_points_sequence_flush(sequence, cut_deck_card)
	for _, card_flush in ipairs(card_flushes) do
		local flush_points = #card_flush
		info.points = info.points + flush_points
		info.points_reasons[#info.points_reasons+1] = {
			reason = core.point_types.FLUSH,
			points = flush_points,
			card_idxs = card_flush,
		}
	end

	for card_idx, card in ipairs(sequence) do
		if card.val == cards.JACK and card.suit == cut_deck_card.suit then
			info.points_reasons[#info.points_reasons+1] = {
				reason = core.point_types.JACK_OF_SUIT,
				points = JACK_OF_SUIT_HAND_CRIB_POINTS,
				card_idxs = {card_idx},
			}
		end
	end

	return info
end

local function check_points_add_card(playing_sequence, card)
	local info = {
		points_reasons = {},
		points = 0,
	}
	if #playing_sequence == 0 then
		return info
	end

	-- check for runs
	local run_len = 0
	local diff = playing_sequence[#playing_sequence].val - card.val
	local last_card = playing_sequence[#playing_sequence]
	for possible_run_len=#playing_sequence+1,3,-1 do
		if check_is_run_add_card(playing_sequence, card, possible_run_len) then
			run_len = possible_run_len
			goto done_run_check
		end
	end
	::done_run_check::

	info.points = info.points + run_len
	info.points_reasons[#info.points_reasons] = { reason = core.point_types.RUN, points = run_len }

	-- check for pairs of two or more of cards with the same value
	local pair_count = 1
	for i=#playing_sequence,1,-1 do
		if playing_sequence[i].val == card.val then
			pair_count = pair_count + 1
		else
			goto done_pair_check
		end
	end
	::done_pair_check::

	local pair_points = pair_count_to_points(pair_count)

	if pair_points > 0 then
		info.points = info.points + pair_points
		info.points_reasons[#info.points_reasons] = { reason = core.point_types.PAIR, points = pair_points }
	end

	return info
end

local function cards_in_hand_remaining(state)
	for _,hand in ipairs(state.hands) do
		if #hand > 0 then
			return true
		end
	end
	return false
end



local function handle_play(state, player, idx, points_reasons)
	if state.player_turn ~= player then
		return core.RC_NOT_YOUR_TURN
	end

	if not (1 <= idx and idx <= #state.hands[player]) then
		error(string.format("Invalid move card %d of hand with only %d cards", idx, #state.hands[player]))
	end

	local tentative_card_played = state.hands[player][idx]

	local tentative_card_value = get_card_value(tentative_card_played)

	if state.playing_sum + tentative_card_value > core.MAX_PLAYING_SUM then
		return core.RC_PLAY_HIGHER_THAN_31
	end

	state.playing_sum = state.playing_sum + tentative_card_value
	state.first_player_cant_move = 0

	if state.playing_sum == 15 then
		state.score[player] = state.score[player] + 2
		points_reasons[#points_reasons+1] = { reason = core.point_types.FIFTEEN, points = 2}
	elseif state.playing_sum == 31 then
		state.score[player] = state.score[player] + 2
		points_reasons[#points_reasons+1] = { reason = core.point_types.THIRTY_ONE, points = 2}
	end

	local card = table.remove(state.hands[player], idx)
	
	local points_info = check_points_add_card(state.playing_sequence, card)
	for _,points_info_elem in ipairs(points_info.points_reasons) do
		points_reasons[#points_reasons+1] = points_info_elem
	end
	state.score[player] = state.score[player] + points_info.points

	-- TODO what oher cases result in points?
	--    * a run of 3 or more?
	--    * pairs?
	--    * getting 30?
	--    * last card
	--    * multiple cards of the same suit?

	-- TODO do something if score is 31?

	table.insert(state.playing[player],  card)
	table.insert(state.playing_sequence, card)


	if not cards_in_hand_remaining(state) then

		-- move all cards from playing to played
		for i=1,state.player_count do
			while #state.playing[i] > 0 do
				table.insert(state.played[i], table.remove(state.playing[i], 1))
				
			end

		end

		state.state = core.states.ACKNOWLEDGE_POINTS
	else
		state.player_turn = ((state.player_turn) % state.player_count) + 1
	end

	-- check if player just played their last card and award a point?
	-- No, it's last card of the run, I think
	--if #state.hands[player] == 0 then
	--	state.score[player] = state.score[player] + 1
	--end

	return core.RC_SUCCESS
end

function core.cant_move(state)
	local player = state.player_turn
	for _,card in ipairs(state.hands[player]) do
		if state.playing_sum + get_card_value(card) <= core.MAX_PLAYING_SUM then
			return false
		end
	end
	return true
end

local function handle_cant_move_accept(state, player)
	if player ~= state.player_turn then
		return core.RC_NOT_YOUR_TURN
	end

	if not core.cant_move(state) then
		return core.RC_MUST_MOVE
	end

	state.player_turn = ((state.player_turn) % state.player_count) + 1
	if state.first_player_cant_move == state.player_turn then
		local last_player_played = (state.first_player_cant_move-2) % state.player_count + 1
		-- one point for last card
		-- TODO make sure this happens when no player has any cards remaining, too
		-- TODO do not do this if each player pressed "can't move" after 31 was reached.
		-- Maybe transition to "next" for that case
		state.score[last_player_played] = state.score[last_player_played] + LAST_CARD_POINTS
		state.first_player_cant_move = 0
		state.playing_sum = 0
		for player_idx=1,state.player_count do
			while #state.playing[player_idx] > 0 do
				table.insert(state.played[player_idx], table.remove(state.playing[player_idx], 1))
			end
		end
		-- TODO if "can't move" goes around the whole table and no one can move,
		-- then must set playing_sum to zero and put the "playing" cards to the "played" tables.
		-- Also record points that people get during this whole thing
		-- Also last card gets a point, I think
	else
		if state.first_player_cant_move == 0 then
			state.first_player_cant_move = player
		end
	end


	return core.RC_SUCCESS
end

function core.has_acknowledged_points(state, player)
	return state.acknowledged_points[player]
end

local function handle_acknowledged_points(state, player)
	local rc = core.RC_SUCCESS
	state.acknowledged_points[player] = true

	local all_acknowledged = true
	for i=1,state.player_count do
		if not state.acknowledged_points[i] then
			all_acknowledged = false
			goto done
		end
	end
	::done::

	if all_acknowledged then
		state.state = core.states.ACKNOWLEDGE_CRIB

		-- reset acknowledged_points array
		for i=1,state.player_count do
			state.acknowledged_points[i] = false
		end

		-- add points
		for i=1,state.player_count do
			local points_info = core.check_points_sequence(state.played[i], state.cut_deck_card)

			state.score[i] = state.score[i] + points_info.points
		end
	end

	return rc
end

local function handle_acknowledged_crib(state, player)
	local rc = core.RC_SUCCESS
	state.acknowledged_points[player] = true

	local all_acknowledged = true
	for i=1,state.player_count do
		if not state.acknowledged_points[i] then
			all_acknowledged = false
			goto done
		end
	end
	::done::

	if all_acknowledged then
		for i=1,state.player_count do
			state.acknowledged_points[i] = false
		end

		local points_info = core.check_points_sequence(state.crib, state.cut_deck_card)

		state.score[state.player_crib] = state.score[state.player_crib] + points_info.points


		state.state = core.states.PICK_DISCARD
		state.player_crib = ((state.player_crib) % state.player_count) + 1
		deal_new_hand(state, true)
	end

	return rc

end

function core.handle_move(state, player, action)
	if state.state == core.states.PICK_DISCARD then
		if #state.hands[player] == core.CARDS_PER_HAND then
			return core.RC_WAIT_FOR_OTHERS_TO_DISCARD
		end
		if action.action == core.actions.HAND then
			state.tentative_discards[player][action.idx] = not(state.tentative_discards[player][action.idx])
			return core.RC_SUCCESS
		elseif action.action == core.actions.DISCARD_CONFIRM then
			return handle_discard_confirm(state, player)
		end
	elseif state.state == core.states.PLAY then
		if action.action == core.actions.HAND then
			-- TODO get this to the user somehow
			local points_reasons = {}
			local rc = handle_play(state, player, action.idx, points_reasons)
			return rc
		elseif action.action == core.actions.CANT_MOVE_ACCEPT then
			return handle_cant_move_accept(state, player)
		end
	elseif state.state == core.states.ACKNOWLEDGE_POINTS then
		if action.action == core.actions.NEXT then
			return handle_acknowledged_points(state, player)
		end
	elseif state.state == core.states.ACKNOWLEDGE_CRIB then
		if action.action == core.actions.NEXT then
			return handle_acknowledged_crib(state, player)
		end
	end
	error(string.format("Unhandled action %s from state %s", action.action, state.state))
	return core.RC_ERROR
end

-- get number of cards needed to select for discard before we can continue
function core.get_tentative_remaining_cards(state, player)
	local tentative_discard_count = 0
	for i=1,#state.tentative_discards[player] do
		if state.tentative_discards[player][i] then
			tentative_discard_count = tentative_discard_count + 1
		end
	end

	local tentative_remaining_cards = #state.hands[player] - tentative_discard_count
	return tentative_remaining_cards 
end

-- Check what cards should be highlighted in the discard state
function core.get_highlight_ary(state, player)

	local highlight_ary = {}
	if state.state == core.states.PICK_DISCARD then
		local tentative_remaining_cards = core.get_tentative_remaining_cards(state, player)
	
		for i=1,#state.hands[player] do
			local highlight = nil
			if tentative_remaining_cards == core.CARDS_PER_HAND then
				highlight = false
			elseif tentative_remaining_cards > core.CARDS_PER_HAND then
				highlight = not state.tentative_discards[player][i]
			else
				highlight = state.tentative_discards[player][i]
			end
			highlight_ary[i] = highlight
		end
	elseif state.state == core.states.PLAY then
		for i=1,#state.hands[player] do
			local card = state.hands[player][i]
			local can_play = nil
			if state.player_turn ~= player then
				can_play = false
			else
				can_play = (get_card_value(card) + state.playing_sum) <= core.MAX_PLAYING_SUM
			end
			highlight_ary[i] = can_play
		end
	elseif state.state == core.states.ACKNOWLEDGE_POINTS or
	       state.state == core.states.ACKNOWLEDGE_CRIB then
		-- no highlights
	else
		error(string.format("Unhandled state %s", state.state))
	end
	return highlight_ary
end

function core.get_discard_status_str(state, player)
	if state.state ~= core.states.PICK_DISCARD then
		error("Not waiting for discard but called get_discard_status_str")
		return "Not waiting for discard..."
	end
	
	if #state.hands[player] == core.CARDS_PER_HAND then
		return "Waiting for other players to discard"
	end

	local tentative_remaining_cards = core.get_tentative_remaining_cards(state, player)

	local diff = tentative_remaining_cards - core.CARDS_PER_HAND

	if diff > 0 then
		return string.format("Please select %d more cards for discard", diff)
	elseif diff < 0 then
		return string.format("Please select %d fewer cards for discard", -diff)
	else
		return "Press \"discard\" button to discard selected cards"
	end
end

tests = {
	{ actual = check_is_run_add_card({{val=9}, {val=11}}, {val=10}, 3), expected = true },
	{ actual = check_is_run_add_card({{val=9}, {val=12}}, {val=10}, 3), expected = false },
	{ actual = check_is_run_add_card({{val=2}, {val=5}}, {val=4}, 3), expected = false },
	{ actual = check_is_run_add_card({{val=3}, {val=5}, {val=4}}, {val=2}, 3), expected = false },
	{ actual = check_is_run_add_card({{val=2}, {val=5}, {val=4}}, {val=3}, 3), expected = true },
	{ actual = check_is_run_add_card({{val=2}, {val=5}, {val=4}}, {val=3}, 4), expected = true },

	{ actual = check_points_sequence_15({{val=10}, {val=4}, {val= 1}}).count, expected = 1},
	{ actual = check_points_sequence_15({{val= 9}, {val=4}, {val= 1}}).count, expected = 0},
	{ actual = check_points_sequence_15({{val= 9}, {val=4}, {val= 2}}).count, expected = 1},
	{ actual = check_points_sequence_15({{val=10}, {val=5}, {val= 3}}).count, expected = 1},
	{ actual = check_points_sequence_15({{val=10}, {val=5}, {val= 5}}).count, expected = 2},
	{ actual = check_points_sequence_15({{val=10}, {val=5}, {val=10}}).count, expected = 2},
	{ actual = check_points_sequence_15({{val= 5}, {val=6}, {val= 4}}).count, expected = 1},
	{ actual = check_points_sequence_15({{val= 5}, {val=5}, {val= 5}}).count, expected = 1},
	{ actual = check_points_sequence_15({{val= 5}, {val=5}, {val= 5}, {val=5}}).count, expected = 4},

	-- { actual = check_points_sequence_15({{val= 13}, {val=7}, {val= 5}, {val=7}, {val=9}, {val=6}}).count, expected = 2},
	{ actual = check_points_sequence_15({{val= 8}, {val=5}, {val= 9}, {val=11}, {val=6}, {val=2}}).count, expected = 3},
}

for test_idx, test in ipairs(tests) do
	if test.actual ~= test.expected then
		error(string.format("Test %d failed, expected %s, received %s", test_idx, test.expected, test.actual))
	end
end

local run_tests = {
	{ actual = check_points_sequence_run({{val=2}, {val=3}, {val=4}, {val=6}, {val=11}}), runs = 1, run_len = 3},
	{ actual = check_points_sequence_run({{val=3}, {val=4}, {val=2}, {val=6}, {val=11}}), runs = 1, run_len = 3},
	{ actual = check_points_sequence_run({{val=4}, {val=2}, {val=6}, {val=3}, {val=11}}), runs = 1, run_len = 3},
	{ actual = check_points_sequence_run({{val=2}, {val=3}, {val=5}, {val=6}, {val=11}}), runs = 0, run_len = nil},
	{ actual = check_points_sequence_run({{val=2}, {val=3}, {val=4}, {val=5}, {val=11}}), runs = 1, run_len = 4},
	{ actual = check_points_sequence_run({{val=5}, {val=2}, {val=3}, {val=4}, {val=11}}), runs = 1, run_len = 4},
	{ actual = check_points_sequence_run({{val=5}, {val=3}, {val=4}, {val=4}, {val=11}}), runs = 2, run_len = 3},
	{ actual = check_points_sequence_run({{val=5}, {val=3}, {val=4}, {val=4}, {val=2}}), runs = 2, run_len = 4},
	{ actual = check_points_sequence_run({{val=5}, {val=3}, {val=4}, {val=6}, {val=2}}), runs = 1, run_len = 5},

	{ actual = check_points_sequence_run({{val=2}, {val=3}, {val=4}, {val=3}, {val=4}}), runs = 4, run_len = 3},
	{ actual = check_points_sequence_run({{val=2}, {val=3}, {val=4}, {val=3}, {val=4}}), runs = 4, run_len = 3},
	{ actual = check_points_sequence_run({{val=4}, {val=2}, {val=4}, {val=2}, {val=3}}), runs = 4, run_len = 3},

	{ actual = check_points_sequence_run({{val=2}, {val=3}, {val=5}, {val=6}, {val=7}}), runs = 1, run_len = 3},
	{ actual = check_points_sequence_run({{val=2}, {val=3}, {val=5}, {val=6}, {val=8}}), runs = 0, run_len = nil},
	{ actual = check_points_sequence_run({{val=11}, {val=12}, {val=13}, {val=1}, {val=2}}), runs = 1, run_len = 3},
	{ actual = check_points_sequence_run({{val=11}, {val=12}, {val=13}, {val=10}, {val=2}}), runs = 1, run_len = 4},
	{ actual = check_points_sequence_run({{val=11}, {val=12}, {val=13}, {val=10}, {val=9}}), runs = 1, run_len = 5},

}

for test_idx, test in ipairs(run_tests) do
	if #test.actual ~= test.runs then
		error(string.format("Run test %d failed, expected %d runs, actual %d", test_idx, test.runs, #test.actual ))
	end
	for i=1,#test.actual do
		if #test.actual[i] ~= test.run_len then
			error(string.format("Run test %d failed, run %d had len %d, expected %d",
			      test_idx, i, #test.actual[i], test.run_len))
		end
	end
end

local pair_tests = {
	{ actual = check_points_seqeuence_pair({{val= 5}, {val=13}, {val=13}, {val= 4}}), pair_lens = {2}    },
	{ actual = check_points_seqeuence_pair({{val=13}, {val=13}, {val=13}, {val= 4}}), pair_lens = {3}    },
	{ actual = check_points_seqeuence_pair({{val=13}, {val= 4}, {val=13}, {val= 5}}), pair_lens = {2}    },
	{ actual = check_points_seqeuence_pair({{val=13}, {val= 4}, {val=13}, {val= 4}}), pair_lens = {2, 2} },
	{ actual = check_points_seqeuence_pair({{val=13}, {val=13}, {val=13}, {val=13}}), pair_lens = {4}    },
	{ actual = check_points_seqeuence_pair({{val= 2}, {val= 2}, {val= 3}, {val= 4}}), pair_lens = {2}    },
	{ actual = check_points_seqeuence_pair({{val= 2}, {val= 2}, {val= 3}, {val= 3}}), pair_lens = {2, 2} },
}

for test_idx, test in ipairs(pair_tests) do
	if #test.actual ~= #test.pair_lens then
		error(string.format("Pair test %d failed, expected %d pairs, actual %d", test_idx, #test.pair_lens, #test.actual ))
	end
	for i=1,#test.actual do
		if #test.actual[i] ~= test.pair_lens[i] then
			error(string.format("Pair test %d failed, pair %d had len %d, expected %d",
			      test_idx, i, #test.actual[i], test.pair_lens[i]))
		end
	end
end

local A = cards.DIAMONDS
local B = cards.SPADES

local flush_tests = {
	{ actual = check_points_sequence_flush({{suit=A}, {suit=A}, {suit=A}, {suit=B}}, {suit=A}), expected={} },
	{ actual = check_points_sequence_flush({{suit=A}, {suit=A}, {suit=A}, {suit=A}}, {suit=B}), expected={4} },
	{ actual = check_points_sequence_flush({{suit=A}, {suit=A}, {suit=A}, {suit=A}}, {suit=A}), expected={5} },
	{ actual = check_points_sequence_flush({{suit=B}, {suit=A}, {suit=A}, {suit=A}}, {suit=A}), expected={} },
}

for test_idx, test in ipairs(flush_tests) do
	if #test.actual ~= #test.expected then
		error(string.format("Flush Test %d failed, expected %d flushes, actual %d", test_idx, #test.expected, #test.actual))
	end

	for i=1,#test.expected do
		if #test.actual[i] ~= test.expected[i] then
			error(string.format("Flush test %d failed, elem %d has len %d, expected %d",
			      test_idx, i, #test.actual[i], test.expected[i]))
		end
	end
end

return core
