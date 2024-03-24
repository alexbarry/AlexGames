#!/usr/bin/env lua

local cards = require("src/lua_scripts/libs/cards/cards")
local core = require("src/lua_scripts/games/crib/crib_core")

local deck = {
	{ suit = "hearts",   val = 6},
	{ suit = "diamonds", val = 2}, -- to crib
	{ suit = "hearts",   val = cards.QUEEN},
	{ suit = "diamonds", val = 7}, 
	{ suit = "spades",   val = 9},
	{ suit = "clubs",    val = 4}, -- to crib

	{ suit = "clubs",    val = cards.KING},
	{ suit = "spades",   val = 3},
	{ suit = "diamonds", val = 9}, -- to crib
	{ suit = "hearts",   val = 2},
	{ suit = "diamonds", val = 5},
	{ suit = "hearts",   val = 4}, -- to crib

	{ suit = "spades",   val = cards.KING},
}


local deck_cpy = {}
for _, card in ipairs(deck) do
	table.insert(deck_cpy, card)
end

local state = core.new_game(2, deck)

local function assert_eq(val1, val2, msg)
	if val1 ~= val2 then
		core.print_state(state)
		error(string.format("Expected %s == %s, msg: %s", val1, val2, msg))
	end
end

local function assert_success(rc)
	if rc ~= core.RC_SUCCESS then
		core.print_state(state)
		error(string.format("Expected rc_success, received %s (%s)", rc, core.rc_to_str(rc)))
	end
end

assert_eq(state.state, core.states.PICK_DISCARD)

assert_success( core.handle_move(state, 1, { action = core.actions.HAND, idx = 2} ) )
assert_success( core.handle_move(state, 1, { action = core.actions.HAND, idx = 6} ) )

assert_success( core.handle_move(state, 2, { action = core.actions.HAND, idx = 3} ) )
assert_success( core.handle_move(state, 2, { action = core.actions.HAND, idx = 6} ) )
assert_success( core.handle_move(state, 1, { action = core.actions.DISCARD_CONFIRM }) )
assert_success( core.handle_move(state, 2, { action = core.actions.DISCARD_CONFIRM }) )

assert_eq(state.state, core.states.PLAY)
assert_eq(state.cut_deck_card.suit, "spades")
assert_eq(state.cut_deck_card.val,  cards.KING)

assert_success( core.handle_move(state, 1, { action = core.actions.HAND, idx = 2} ) )
assert_eq(state.playing_sum, 10, "playing_sum check")
assert_eq(state.score[1], 0)
assert_eq(state.score[2], 0)

-- test "not your turn"
assert_eq( core.handle_move(state, 1, { action = core.actions.HAND, idx = 2} ), core.RC_NOT_YOUR_TURN )

assert_success( core.handle_move(state, 2, { action = core.actions.HAND, idx = 4} ) )
assert_eq(state.playing_sum, 15, "playing_sum check")
assert_eq(state.score[1], 0)
assert_eq(state.score[2], 2)

assert_success( core.handle_move(state, 1, { action = core.actions.HAND, idx = 3} ) )
assert_eq(state.playing_sum, 24, "playing_sum check")
assert_eq(state.score[1], 0)
assert_eq(state.score[2], 2)

assert_eq( core.handle_move(state, 2, { action = core.actions.HAND, idx = 1} ), core.RC_PLAY_HIGHER_THAN_31 )

assert_success( core.handle_move(state, 2, { action = core.actions.HAND, idx = 2} ) )
assert_eq(state.playing_sum, 27, "playing_sum check")
assert_eq(state.score[1], 0)
assert_eq(state.score[2], 2)

assert_success( core.handle_move(state, 1, { action = core.actions.CANT_MOVE_ACCEPT } ) )

assert_eq( core.handle_move(state, 2, { action = core.actions.CANT_MOVE_ACCEPT } ), core.RC_MUST_MOVE)

assert_success( core.handle_move(state, 2, { action = core.actions.HAND , idx = 2 } ) )
assert_eq(state.playing_sum, 29, "playing_sum check")
assert_eq(state.score[1], 0)
assert_eq(state.score[2], 2)

assert_success( core.handle_move(state, 1, { action = core.actions.CANT_MOVE_ACCEPT } ) )
assert_success( core.handle_move(state, 2, { action = core.actions.CANT_MOVE_ACCEPT } ) )

assert_eq(state.playing_sum, 0, "playing_sum check")
assert_eq(state.score[1], 0)
assert_eq(state.score[2], 3)

assert_success( core.handle_move(state, 1, { action = core.actions.HAND , idx = 2 } ) )
assert_eq(state.playing_sum, 7, "playing_sum check")
assert_eq(state.score[1], 0)
assert_eq(state.score[2], 3)

assert_success( core.handle_move(state, 2, { action = core.actions.HAND , idx = 1 } ) )
assert_eq(#state.hands[2], 0, "player 2 should have empty hand")
assert_eq(state.playing_sum, 17, "playing_sum check")
assert_eq(state.score[1], 0)
assert_eq(state.score[2], 3)

assert_eq(state.state, core.states.PLAY)

assert_success( core.handle_move(state, 1, { action = core.actions.HAND , idx = 1 } ) )
assert_eq(#state.hands[1], 0, "player 2 should have empty hand")
assert_eq(state.score[1], 0)
assert_eq(state.score[2], 3)

-- TODO there should be a "NEXT" button press in here from the other player, or from all players?
--[[
assert_success( core.handle_move(state, 1, { action = core.actions.NEXT } ))
assert_success( core.handle_move(state, 2, { action = core.actions.NEXT } ))
]]

assert_eq(state.state, core.states.ACKNOWLEDGE_POINTS)

local points_info1 = core.check_points_sequence(state.played[1], state.cut_deck_card)
local points_info2 = core.check_points_sequence(state.played[2], state.cut_deck_card)

assert_eq(points_info1.points, 2)
assert_eq(points_info2.points, 10)

assert_success( core.handle_move(state, 1, { action = core.actions.NEXT } ))
assert_success( core.handle_move(state, 2, { action = core.actions.NEXT } ))

assert_eq(state.state, core.states.ACKNOWLEDGE_CRIB)
assert_eq(state.score[1], 2)
assert_eq(state.score[2], 13)

local points_info_crib = core.check_points_sequence(state.crib, state.cut_deck_card)
assert_eq(points_info_crib.points, 6)

assert_success( core.handle_move(state, 1, { action = core.actions.NEXT } ))
assert_success( core.handle_move(state, 2, { action = core.actions.NEXT } ))

assert_eq(state.state, core.states.PICK_DISCARD)

print("Test finished successfully!")
