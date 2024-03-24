local cards_set = {}

local cards = require("libs/cards/cards")

function cards_set.card_list_to_set(card_list)
	local card_set = {
		suits = {},
		list = card_list,
	}
	for _, suit in ipairs(cards.suits) do
		card_set.suits[suit] = {}
	end

	for _, card in ipairs(card_list) do
		card_set.suits[card.suit][card.val] = true
	end

	return card_set
end
