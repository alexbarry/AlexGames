

local cards_draw = require("libs/cards/cards_draw")

local canvas_width  = 480
local canvas_height = 480

local card_width  =  40
local card_height =  70
local font_size   =  24
local padding     =   5

if false then
	card_width  =  70
	card_height = 120
	font_size   =  48
	padding     =   5
end

cards_draw.draw_facedown_card(padding, padding, card_width, card_height)

local deck2 = cards.new_deck()
cards.shuffle(deck2)


local dx = card_width + padding
local dy = card_height + padding

local y = padding
local x = padding + dx

for i, card in ipairs(deck2) do


	print("Drawing card " .. cards.card_to_string(card))
	cards_draw.draw_card(card, y, x, card_width, card_height, font_size)

	x = x + dx

	if x + card_width + padding >= canvas_width then
		x = padding
		y = y + dy
	end
end
