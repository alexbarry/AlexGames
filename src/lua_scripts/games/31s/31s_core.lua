local game31s = {}

local cards = require("libs/cards/cards")

-- each player holds 3 cards in their hand at a time
local cards_per_hand = 3

-- e.g. having three cards of same val (e.g. all 8s, or all 2s) results in a score of 30
-- I think some variations claim it is 30.5?
local score_of_all_same_val = 30

local get_hand_score = nil

game31s.SRC_DECK    = 1
game31s.SRC_DISCARD = 2

game31s.SUCCESS                 =  0
game31s.NOT_YOUR_TURN           = -1 
game31s.STAGING_AREA_FULL       = -2
game31s.STAGING_AREA_EMPTY      = -3
game31s.SOMEONE_ALREADY_KNOCKED = -4
game31s.GAME_OVER               = -5

game31s.MSG_PLAYER  = "player"
game31s.MSG_DRAW    = "draw"
game31s.MSG_DISCARD = "discard"
game31s.MSG_KNOCK   = "knock"

function game31s.err_code_to_str(rc)
	local map = {
		[game31s.SUCCESS]            = "Sucess",
		[game31s.NOT_YOUR_TURN]      = "Not your turn",
		[game31s.STAGING_AREA_FULL]  = "Staging area full",
		[game31s.STAGING_AREA_EMPTY] = "Staging area empty",
		[game31s.SOMEONE_ALREADY_KNOCKED] = "Someone has already knocked",
		[game31s.GAME_OVER]          = "Game over",
	}
	return map[rc]
end

-- Shouldn't need to call this externally, unless you manually edit the cards
-- outside of these APIs
function game31s.check_for_31_in_hand(state)
	for player=1,state.player_count do
		local score = get_hand_score(state.player_hands[player])
		if score >= 31 then
			state.winners[#state.winners+1] = player
		end
	end
end

function game31s.new_game(player_count)
	local deck = cards.new_deck()
	cards.shuffle(deck)

	local player_hands = {}

	for i=1, player_count do
		player_hands[i] = {}
		for _=1, cards_per_hand do
			player_hands[i][#player_hands[i]+1] = table.remove(deck)
		end

	end


	local discard_pile = {}

	table.insert(discard_pile, table.remove(deck))

	local state = {
		player_count = player_count,
		deck = deck,
		discard_pile = discard_pile,
		player_hands = player_hands,
		player_turn = 1,

		-- this is where a card drawn from the deck is stored until the player
		-- chooses to either discard it, or swap it with one of the cards in their hand
		staging_area = nil,

		-- if the player picks up the discarded card and puts it back,
		-- that shouldn't count as a turn.
		drew_from_discard = false,

		-- when a player "knocks", this is set to player_count
		-- then it is decremented on each turn and the game is over once it reaches zero
		turns_to_gameover = nil,

		winners = {},
	}
	game31s.check_for_31_in_hand(state)
	return state
end

function game31s.print_state(state)
	if state == nil then
		io.write("state = nil\n")
		return
	end

	io.write("state {\n")
	io.write(string.format("    player_count = %d\n", state.player_count))
	if state.deck ~= nil then
		io.write(string.format("    deck.size    = %d\n", #state.deck))
	else
		io.write(string.format("    deck is nil\n"))
	end
	io.write(string.format("    player_hands = {\n"))
	for player,_ in pairs(state.player_hands) do
		io.write(string.format("     [%d] = {", player))
		for card_idx=1, #state.player_hands[player] do
			io.write(cards.card_to_string(state.player_hands[player][card_idx]))
			io.write(", ")
		end
		io.write("    }\n")
	end
	io.write("    }\n")
	io.write(string.format("    player_turn = %d\n", state.player_turn))
	io.write(string.format("    staging_area = %s\n", cards.card_to_string(state.staging_area)))

	io.write(string.format("    winners = {"))
	for _,winner in ipairs(state.winners) do
		io.write(string.format("%d, ", winner))
	end
	io.write(string.format("}\n"))

	io.write("}\n")
end

function table_slice(array, start_idx, end_idx)
	local dst_array = {}
	for i=start_idx,end_idx do
		if not(1 <= i and i <= #array) then
			goto next
		end
		table.insert(dst_array, array[i])
		::next::
	end
	return dst_array
end


function bool_to_byte(b)
	if b then return 1
	else return 0 end
end

function byte_to_bool(val)
	return (val ~= 0)
end

local function bytestr_to_nice_str(s)
	if s == nil then return "nil" end
	local nice_strs = {}
	for i=1,#s do
		table.insert(nice_strs, string.format("%02x", string.byte(s:sub(i,i))))
	end
	return table.concat(nice_strs, " ")
end

local function bytearray_to_nice_str(array)
	local nice_strs = {}
	for i=1, #array do
		table.insert(nice_strs, string.format("%02x", string.byte(array[i])))
	end
	return table.concat(nice_strs, " ")
end

local function serialize_byte_array(array)
	local output = {}
	output[#output+1] = string.char(#array)
	for i=1,#array do
		output[#output+1] = string.char(array[i])
	end
	return table.concat(output, "")
end

local function deserialize_byte_array(bytes)
	local array = {}
	local len = string.byte(table.remove(bytes, 1))
	for i=1,len do
		array[i] = string.byte(table.remove(bytes, 1))
	end
	return array
end
	
--
-- To prevent cheating, only the host will know all the cards.
-- The clients will only be sent what they need to know:
--    * their hand
--    * if another player draws a card into their staging area
--    * if another player discards from their hand or the staging area card
--    * a change in the discard pile
--    * if someone knocks?
--    * turns to game over?

function game31s.serialize_state_for_client(state, player_idx)
	local output = ""
	if state == nil then return output end
	output = output .. string.char(state.player_count)
	output = output .. string.char(state.player_turn)
	output = output .. bool_to_byte(state.drew_from_discard)
	output = output .. cards.serialize_card_array(state.player_hands[player_idx])
	output = output .. cards.serialize_card_array(table_slice(state.discard_pile, #state.discard_pile-1, #state.discard_pile))
	local staging_area_array = {}
	if state.staging_area ~= nil then
		if state.player_turn ~= player_idx and not state.drew_from_discard then
			table.insert(staging_area_array, cards.UNREVEALED_CARD)
		else
			table.insert(staging_area_array, state.staging_area)
		end
	end
	local staging_area_bytes = cards.serialize_card_array(staging_area_array)
	output = output .. staging_area_bytes

	output = output .. serialize_byte_array(state.winners)

	-- If the game is over, reveal all the hands
	if #state.winners > 0 then
		for player_hand_idx=1, state.player_count do
			if player_hand_idx == player_idx then
				goto next_player
			end
			output = output .. string.char(player_hand_idx)
			output = output .. cards.serialize_card_array(state.player_hands[player_hand_idx])
			::next_player::
		end
	end
	return output
end


function game31s.deserialize_client_state(player, bytes_str)
	local bytes = {}
	for i=1,#bytes_str do
		bytes[i] = bytes_str:sub(i,i)
	end
	local state = {}
	state.player_count = string.byte(table.remove(bytes, 1))
	state.player_turn = string.byte(table.remove(bytes, 1))
	state.drew_from_discard = byte_to_bool(table.remove(bytes,1))
	state.player_hands = {}
	state.player_hands[player]  = cards.deserialize_card_array(bytes)
	state.discard_pile = cards.deserialize_card_array(bytes)
	local staging_area_array = cards.deserialize_card_array(bytes)
	if #staging_area_array == 0 then
		state.staging_area = nil
	elseif #staging_area_array == 1 then
		state.staging_area = staging_area_array[1]
	else
		error(string.format("Unexpected staging_area len received %d", #staging_area_array))
	end

	state.winners = deserialize_byte_array(bytes)

	-- if #state.winners > 0 then
	while #bytes > 0 do
		local player_hand_idx = string.byte(table.remove(bytes,1))
		state.player_hands[player_hand_idx] = cards.deserialize_card_array(bytes)
	end

	return state
end

function game31s.draw_from_deck(state, player)
	if state.player_turn ~= player then
		return game31s.NOT_YOUR_TURN
	end

	if state.staging_area ~= nil then
		return game31s.STAGING_AREA_FULL
	end

	if #state.winners > 0 then
		return game31s.GAME_OVER
	end

	-- shouldn't happen, discard pile should be shuffled when the last card is drawn
	if #state.deck == 0 then
		error("Deck is empty")
	end

	state.staging_area = table.remove(state.deck)

	if #state.deck == 0 then
		print("Shuffling discard pile to refill deck")
		--local discard_pile_top = table.remove(state.discard_pile)
		state.deck = state.discard_pile
		state.discard_pile = {}
		cards.shuffle(state.deck)
	end

	return game31s.SUCCESS
end

function game31s.draw_from_discard(state, player)
	if state.player_turn ~= player then
		return game31s.NOT_YOUR_TURN
	end

	if state.staging_area ~= nil then
		return game31s.STAGING_AREA_FULL
	end

	if #state.winners > 0 then
		return game31s.GAME_OVER
	end

	-- shouldn't happen
	if #state.discard_pile == 0 then
		error("Discard pile is empty")
	end

	state.drew_from_discard = true
	state.staging_area = table.remove(state.discard_pile)

	return game31s.SUCCESS
end

local function get_card_val(card_val)
	local map = {
		[cards.ACE]   = 11,
		[2]           =  2,
		[3]           =  3,
		[4]           =  4,
		[5]           =  5,
		[6]           =  6,
		[7]           =  7,
		[8]           =  8,
		[9]           =  9,
		[10]          = 10,
		[cards.JACK]  = 10,
		[cards.QUEEN] = 10,
		[cards.KING]  = 10,
	}
	return map[card_val]
end

local function check_all_same_val(hand)
	local val = hand[1].val
	for _, card in ipairs(hand) do
		if val ~= card.val then
			return false
		end
	end
	return true
end

function get_hand_score(hand)
	local sums_per_suit = {}
	for _,suit in ipairs(cards.suits) do
		sums_per_suit[suit] = 0
	end
	for i=1,#hand do
		local card = hand[i]
		sums_per_suit[card.suit] = sums_per_suit[card.suit] + get_card_val(card.val)
	end

	local score = 0
	for _,val in pairs(sums_per_suit) do
		if val > score then
			score = val
		end
	end

	if check_all_same_val(hand) and score < score_of_all_same_val then
		score = score_of_all_same_val
	end

	return score
end

local function get_scores(state)
	local scores = {}
	for player=1, state.player_count do
		scores[player] = get_hand_score(state.player_hands[player])
	end
	return scores
end

local function get_max_score(scores)
	local max_score = nil
	for _, score in ipairs(scores) do
		if max_score == nil or score > max_score then
			max_score = score
		end
	end
	return max_score
end

local function ary_to_str(ary, fmt)
	local str = "{"
	for _, val in ipairs(ary) do
		str = str .. string.format(fmt, val) .. ", "
	end
	return str .. "}"
end

local function get_winner(state)
	local scores = get_scores(state)
	print("Scores are: " .. ary_to_str(scores, "%d"))
	local max_score = get_max_score(scores)

	state.winners = {}
	for player=1,state.player_count do
		if scores[player] == max_score then
			state.winners[#state.winners+1] = player
		end
	end
end

local function next_player(state)
	state.player_turn = ((state.player_turn-1 + 1) % state.player_count) + 1
	if state.turns_to_gameover == 0 then
		print("Turns to game over is zero, getting winners...")
		get_winner(state)
		print("Winners are: " .. ary_to_str(state.winners, "%d"))
	elseif state.turns_to_gameover ~= nil then
		state.turns_to_gameover = state.turns_to_gameover - 1
	end

end

function game31s.player_swap_card(state, player, hand_idx)
	if state.player_turn ~= player then
		return game31s.NOT_YOUR_TURN
	end

	if state.staging_area == nil then
		return game31s.STAGING_AREA_EMPTY
	end

	if #state.winners > 0 then
		return game31s.GAME_OVER
	end


	local discard_card = state.player_hands[player][hand_idx] 
	state.player_hands[player][hand_idx]  = state.staging_area
	state.staging_area = nil
	state.drew_from_discard = false
	table.insert(state.discard_pile, discard_card)

	-- TODO
	if get_hand_score(state.player_hands[player]) == 31 then
		state.winners = {player}
	end

	next_player(state)

	return game31s.SUCCESS
end

function game31s.player_discard_staged(state, player)
	if state.player_turn ~= player then
		return game31s.NOT_YOUR_TURN
	end

	if state.staging_area == nil then
		return game31s.STAGING_AREA_EMPTY
	end

	if #state.winners > 0 then
		return game31s.GAME_OVER
	end

	table.insert(state.discard_pile, state.staging_area)
	state.staging_area = nil
	if not state.drew_from_discard then
		next_player(state)
	end
	state.drew_from_discard = false

	return game31s.SUCCESS
end

function game31s.player_knock(state, player)
	if state.player_turn ~= player then
		return game31s.NOT_YOUR_TURN
	end

	if state.turns_to_gameover ~= nil then
		return game31s.SOMEONE_ALREADY_KNOCKED
	end

	if #state.winners > 0 then
		return game31s.GAME_OVER
	end

	state.turns_to_gameover = state.player_count - 1
	next_player(state)

	return game31s.SUCCESS
end

return game31s
