-- Run this script by the standalone lua interpeter, from either repo root or src/lua_scripts
package.path = 'src/lua_scripts/?.lua;?.lua'

local core = require("games/crib/crib_core")
local cards = require("libs/cards/cards")

local print_test_passes = false

local test_passes = 0
local test_failures = 0
local error_on_failure = false

-- TODO extract all this boilerplate test stuff into a generic module that accepts
-- running a function or something
local function test_hand(msg, hand, extra_card, expected_points)
	local actual_points = core.check_points_sequence(hand, extra_card).points
	if expected_points ~= actual_points then
		test_failures = test_failures + 1
		local msg_to_print = string.format("Expected hand=%s, extra_card=%s to be worth " ..
		                                   "%d points, was worth %d. Msg=%s",
		                                   cards.card_array_to_string(hand),
		                                   cards.card_to_string(extra_card),
		                                   expected_points, actual_points, msg)
		if error_on_failure then
			error(msg_to_print)
		else
			print(msg_to_print)
		end
	else
		test_passes = test_passes + 1
		if print_test_passes then
			print(string.format("Hand=%s, extra_card=%s was correctly worth %d points. Msg=%s",
			cards.card_array_to_string(hand), cards.card_to_string(extra_card), actual_points, msg))
		end
	end
end

test_hand("nothing", {
		{ suit = cards.DIAMONDS, val = 2 },
		{ suit = cards.CLUBS,    val = 4 },
		{ suit = cards.DIAMONDS, val = 6 },
		{ suit = cards.DIAMONDS, val = 8 },
	},
	{ suit = cards.CLUBS, val = cards.KING},
	0
)

test_hand("4 of suit", {
		{ suit = cards.DIAMONDS, val = 2 },
		{ suit = cards.DIAMONDS, val = 4 },
		{ suit = cards.DIAMONDS, val = 6 },
		{ suit = cards.DIAMONDS, val = 8 },
	},
	{ suit = cards.CLUBS, val = cards.KING},
4)

test_hand("run of 4 + one 15", {
		{ suit = cards.DIAMONDS, val =  7 },
		{ suit = cards.CLUBS,    val =  8 },
		{ suit = cards.DIAMONDS, val =  9 },
		{ suit = cards.DIAMONDS, val = 10 },
	},
	{ suit = cards.CLUBS, val = 2},
	4 + 2
)

test_hand("two runs of 4 + pair + fifteen", {
		{ suit = cards.DIAMONDS, val =  7 },
		{ suit = cards.CLUBS,    val =  8 },
		{ suit = cards.DIAMONDS, val =  9 },
		{ suit = cards.DIAMONDS, val = 10 },
	},
	{ suit = cards.CLUBS, val = 10},
	2*4 + 2 + 2
)

test_hand("run of 5 + two fifteen (6+9, 8+7)", {
		{ suit = cards.DIAMONDS, val =  6 },
		{ suit = cards.CLUBS,    val =  7 },
		{ suit = cards.DIAMONDS, val =  8 },
		{ suit = cards.DIAMONDS, val =  9 },
	},
	{ suit = cards.CLUBS, val = 10},
	5 + 2*2
)

test_hand("run of 5 + two fifteen (6+9, 8+7) + flush", {
		{ suit = cards.DIAMONDS, val =  6 },
		{ suit = cards.DIAMONDS, val =  7 },
		{ suit = cards.DIAMONDS, val =  8 },
		{ suit = cards.DIAMONDS, val =  9 },
	},
	{ suit = cards.CLUBS, val = 10},
	5 + 2*2 + 4
)

-- TODO why is this one failing?
test_hand("three 10s + two 5s = 6 fifteens + 1 pair of two + 1 pair of three", {
		{ suit = cards.DIAMONDS, val =  10 },
		{ suit = cards.CLUBS,    val =  cards.KING },
		{ suit = cards.DIAMONDS, val =  5 },
		{ suit = cards.HEARTS,   val =  5 },
	},
	{ suit = cards.SPADES, val = 10},
	6*2 + 2 + 6
)

test_hand("pair of three", {
		{ suit = cards.DIAMONDS, val =  10 },
		{ suit = cards.CLUBS,    val =  10 },
		{ suit = cards.SPADES,   val =  10 },
		{ suit = cards.HEARTS,   val =  9 },
	},
	{ suit = cards.SPADES, val = 2},
	6
)

test_hand("pair of four", {
		{ suit = cards.DIAMONDS, val =  10 },
		{ suit = cards.CLUBS,    val =  10 },
		{ suit = cards.SPADES,   val =  10 },
		{ suit = cards.HEARTS,   val =  10 },
	},
	{ suit = cards.SPADES, val = 2},
	12
)

print(string.format("Tests passed: %d", test_passes))
print(string.format("Tests failed: %d", test_failures))

if test_failures > 0 or test_passes == 0 then
	return -1
end
