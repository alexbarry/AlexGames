
cards = {}

cards.DIAMONDS = "diamonds"
cards.HEARTS   = "hearts"
cards.SPADES   = "spades"
cards.CLUBS    = "clubs"

cards.ACE   = 1
cards.JACK  = 11
cards.QUEEN = 12
cards.KING  = 13

cards.MIN_VAL = cards.ACE
cards.MAX_VAL = cards.KING

cards.NUM_SUITS = 4
cards.NUM_VALS  = 13

cards.suits = {
	cards.DIAMONDS,
	cards.HEARTS,
	cards.SPADES,
	cards.CLUBS,
}

cards.suit_to_idx = {
	[cards.DIAMONDS] = 0,
	[cards.HEARTS]   = 1,
	[cards.SPADES]   = 2,
	[cards.CLUBS]    = 3,
}

cards.idx_to_suit = {
}

for suit, suit_idx in pairs(cards.suit_to_idx) do
	cards.idx_to_suit[suit_idx] = suit
end

cards.UNREVEALED_CARD = 53

cards.vals = {
	cards.ACE,
	2,
	3,
	4,
	5,
	6,
	7,
	8,
	9,
	10,
	cards.JACK,
	cards.QUEEN,
	cards.KING,
}

function cards.card_to_int(card)
	if card == nil then error("card_to_int arg is nil", 2) end
	if card == cards.UNREVEALED_CARD then
		return card
	end
	return cards.suit_to_idx[card.suit] * cards.NUM_VALS + (card.val-1)
end

function cards.int_to_card(card_int)
	if card_int == cards.UNREVEALED_CARD then
		return card_int
	end
	if not(0 <= card_int and card_int < cards.NUM_SUITS * cards.NUM_VALS) then
		return nil
	end
	local card = {}
	card.suit = cards.idx_to_suit[math.floor(card_int / cards.NUM_VALS)]
	card.val  = (card_int % cards.NUM_VALS) + 1
	return card
end

function cards.copy_card(card)
	if card == nil then
		return nil
	end
	local card_int = cards.card_to_int(card)
	return cards.int_to_card(card_int)
end

function cards.copy_card_ary(card_ary_orig)
	local card_ary_copy = {}
	for _, card in ipairs(card_ary_orig) do
		table.insert(card_ary_copy, cards.copy_card(card))
	end
	return card_ary_copy
end

function cards.copy_card_ary_ary(card_ary_ary_orig)
	local ary_copy = {}
	for _, card_ary in ipairs(card_ary_ary_orig) do
		table.insert(ary_copy, cards.copy_card_ary(card_ary))
	end
	return ary_copy
end


function cards.val_to_string(val)
	if val == nil then
		return "nil"
	end
	local to_letter = {
		[cards.ACE]   = "A",
		[cards.JACK]  = "J",
		[cards.QUEEN] = "Q",
		[cards.KING]  = "K",
	}

	if 2 <= val and val <= 10 then
		return string.format("%d", val)
	else
		return to_letter[val]
	end
end

function cards.card_to_string(card)
	if card == nil then return 'nil' end
	local val_str = cards.val_to_str(card.val)
	local suit_str = cards.suit
	return string.format('[%s %s]', suit_str, val_str)
end

function cards.card_ary_to_string(card_ary)
	local s = '{'
	for i, card in ipairs(card_ary) do
		if i == 1 then s = s .. ' '
		else s = s .. ', ' end
		s = s .. cards.card_to_string(card)
	end
	s = s .. '}'
	return s
end

local function swap(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
end

local function shuffle(array)
    local counter = #array
    while counter > 1 do
        local index = math.random(counter)
        swap(array, index, counter)
        counter = counter - 1
    end
end

local function new_card(suit,val)
	return { suit = suit, val = val }
end

function cards.new_deck()
	local deck = {}
	for _, suit in ipairs(cards.suits) do
		for _, val in ipairs(cards.vals) do
			local card = new_card(suit, val)
			deck[#deck+1] = card
		end
	end
	return deck
end

function cards.shuffle(deck)
	return shuffle(deck)
end

function cards.card_to_string(card)
	if card == nil then return "nil"
	elseif card == cards.UNREVEALED_CARD then return "[unrevealed]" end
	return string.format("[%s %s]", card.suit, cards.val_to_string(card.val))
end

function cards.card_array_to_string(card_array)
	local str = "{"
	for i=1,#card_array do
		str = str .. cards.card_to_string(card_array[i]) .. ", "
	end
	str = str .. "}"
	return str
end

function cards.serialize_card(card)
	local byte = nil
	if card == nil then
		byte = 255
	else
		byte = cards.card_to_int(card)
	end
	local chars = {string.char(byte)}
	return table.concat(chars, "")
end

function cards.deserialize_card(bytes)
	local card_int = string.byte(table.remove(bytes,1))
	if card_int == 255 then
		return nil
	else
		return cards.int_to_card(card_int)
	end
end

function cards.serialize_card_array(card_array)
	if card_array == nil then
		error("arg is nil", 2)
		return
	end
	local bytes = {}
	bytes[#bytes+1] = string.char(#card_array)
	for i=1,#card_array do
		bytes[#bytes+1] = string.char(cards.card_to_int(card_array[i]))
	end
	local msg = table.concat(bytes, "")
	return msg
end

-- Also removes the elements from the table `bytes`
function cards.deserialize_card_array(bytes)
	local card_array = {}
	--local num_cards = string.byte(bytes:sub(1,1))
	local num_cards = string.byte(table.remove(bytes, 1))
	if #bytes < num_cards then
		error(string.format("expected %d bytes, only had %d", num_cards, #bytes))
		return
	end
	for i=1,num_cards do
		--card_array[#card_array+1] = cards.int_to_card(string.byte(bytes:sub(i,i)))
		local card_int = string.byte(table.remove(bytes,1))
		card_array[#card_array+1] = cards.int_to_card(card_int)
	end 
	return card_array
end

function cards.suit_is_red(suit)
	return suit == cards.DIAMONDS or suit == cards.HEARTS
end

function cards.cards_eq(card1, card2)
	return (card1.suit == card2.suit and
	        card1.val  == card2.val)
end


--[[
for i=0,51 do
	local card = cards.int_to_card(i)
	local i2 = cards.card_to_int(card)
	if i ~= i2 then
		error(string.format("%q ~= %q", i, i2))
	end
	--print(string.format("i=%d, card=%s, i2=%d", i, cards.card_to_string(card), i2))
end
]]

return cards
