#!/usr/bin/env lua5.3

package.path = 'src/lua_scripts/?.lua'

local cards = require("libs/cards/cards")
local core  = require("games/solitaire/solitaire_core")
local serialize = require("games/solitaire/solitaire_serialize")
local utils = require("libs/utils")

local function assert_eq(actual, expected)
	if actual ~= expected then
		error(string.format("actual=%s, expected=%s", actual, expected), 2)
	end
end

local function assert_card_eq(actual, expected)
	if not cards.cards_eq(actual, expected) then
		local actual_str   = cards.card_to_string(actual)
		local expected_str = cards.card_to_string(expected)
		error(string.format("actual=%s, expected=%s", actual_str, expected_str), 2)
	end
end


local player = 1
local state = core.new_game(1, core.DRAW_TYPE_THREE)


local function move_deck_card_to_pos(dst, expected_card)
	core.handle_mouse_down(player, state, { section_type = core.SECTION_DECK_DRAW, col = 1 })
	state.players[1].moved = true

	assert_eq(#state.players[player].holding, 1)

	if expected_card ~= nil then
		assert_card_eq(state.players[player].holding[1], expected_card)
	end

	local rc = core.handle_mouse_up(player, state, dst)
	assert_eq(rc, true)
end

state.deck_unrevealed = {
	{ suit = cards.HEARTS, val =  10, },
	{ suit = cards.HEARTS, val =  cards.JACK, },
	{ suit = cards.HEARTS, val =  cards.QUEEN, },

	{ suit = cards.CLUBS, val =  5, },
	{ suit = cards.CLUBS, val =  4, },
	{ suit = cards.CLUBS, val =  3, },

	{ suit = cards.CLUBS, val =  9, },
	{ suit = cards.CLUBS, val =  8, },
	{ suit = cards.CLUBS, val =  7, },
}
state.play_columns_staging[1] = { {suit = cards.DIAMONDS, val =  6 }, }
state.play_columns_staging[2] = { {suit = cards.DIAMONDS, val =  5 }, }
state.play_columns_staging[3] = { {suit = cards.DIAMONDS, val =  4 }, }

assert_eq(#state.deck_discard, 0)
assert_eq(#state.deck_draw, 0)

-- Click deck to draw 3
core.next_in_deck(state)

-- Ensure that three cards are drawn, the last 3 in the deck
assert_eq(#state.deck_discard, 0)
assert_eq(#state.deck_draw, 3)
assert_card_eq(state.deck_draw[1], { suit = cards.CLUBS, val = 7 })
assert_card_eq(state.deck_draw[2], { suit = cards.CLUBS, val = 8 })
assert_card_eq(state.deck_draw[3], { suit = cards.CLUBS, val = 9 })

-- Pick up the first one in the draw pile
core.handle_mouse_down(player, state, { section_type = core.SECTION_DECK_DRAW, col = 1 })

-- Ensure it's the last one in the deck
assert_eq(#state.players[player].holding, 1)
assert_card_eq(state.players[player].holding[1],{ suit = cards.CLUBS, val = 9 })

-- Ensure remaining two are left in the deck_draw
assert_eq(#state.deck_draw, 2)
assert_card_eq(state.deck_draw[1], { suit = cards.CLUBS, val = 7 })
assert_card_eq(state.deck_draw[2], { suit = cards.CLUBS, val = 8 })

-- Release, putting card back
local rc = core.handle_mouse_up(player, state, nil)
assert_eq(rc, false)

-- Ensure deck_draw is back to all 3, in the same order
assert_eq(#state.deck_draw, 3)
assert_card_eq(state.deck_draw[1], { suit = cards.CLUBS, val = 7 })
assert_card_eq(state.deck_draw[2], { suit = cards.CLUBS, val = 8 })
assert_card_eq(state.deck_draw[3], { suit = cards.CLUBS, val = 9 })

core.next_in_deck(state)
assert_eq(#state.deck_draw, 3)
assert_card_eq(state.deck_draw[1], { suit = cards.CLUBS, val = 3 })
assert_card_eq(state.deck_draw[2], { suit = cards.CLUBS, val = 4 })
assert_card_eq(state.deck_draw[3], { suit = cards.CLUBS, val = 5 })

local dst = { section_type = core.SECTION_PLAY_COLUMN_STAGING, col = 1, idx = 1 }
move_deck_card_to_pos(dst, {suit = cards.CLUBS, val = 5})

assert_eq(#state.deck_draw, 2)
assert_card_eq(state.deck_draw[1], { suit = cards.CLUBS, val = 3 })
assert_card_eq(state.deck_draw[2], { suit = cards.CLUBS, val = 4 })

move_deck_card_to_pos({ section_type = core.SECTION_PLAY_COLUMN_STAGING, col = 2, idx = 1 }, {suit = cards.CLUBS, val = 4})
move_deck_card_to_pos({ section_type = core.SECTION_PLAY_COLUMN_STAGING, col = 3, idx = 1 }, {suit = cards.CLUBS, val = 3})

-- The card that was on the top of the draw deck before should now be what appears when the draw deck is used up
assert_eq(#state.deck_draw, 1)
assert_card_eq(state.deck_draw[1], { suit = cards.CLUBS, val = 9 })
