#!/usr/bin/env lua

package.path = 'src/lua_scripts/?.lua'

local core = require("games/chess/chess_core")

local BLACK_L_CASTLING = (1 << 0)
local BLACK_R_CASTLING = (1 << 1)
local WHITE_L_CASTLING = (1 << 2)
local WHITE_R_CASTLING = (1 << 3)

local ALL_CASTLING = (1 << 4) - 1

local function new_castling_possible_state(param)
	local state = core.new_game()

	if (param & BLACK_L_CASTLING) ~= 0 then
		state.board[1][2] = 0 state.board[1][3] = 0
		state.board[1][4] = 0
	end

	if (param & BLACK_R_CASTLING) ~= 0 then
		state.board[1][6] = 0
		state.board[1][7] = 0
	end

	if (param & WHITE_L_CASTLING) ~= 0 then
		state.board[8][2] = 0
		state.board[8][3] = 0
		state.board[8][4] = 0
	end

	if (param & WHITE_R_CASTLING) ~= 0 then
		state.board[8][6] = 0
		state.board[8][7] = 0
	end

	return state
end

local BLACK_KING = 12
local BLACK_ROOK =  8
local WHITE_KING =  6
local WHITE_ROOK =  2

local function apply_castling_type(state, param)
	if param == BLACK_L_CASTLING then
		state.board[1][5] = 0
		state.board[1][3] = BLACK_KING
		state.board[1][4] = BLACK_ROOK
		state.board[1][1] = 0
		state.kings_moved[core.PLAYER_BLACK] = true
		state.rooks_moved[11] = true
		state.player_turn = core.PLAYER_WHITE
	elseif param == BLACK_R_CASTLING then
		state.board[1][5] = 0
		state.board[1][7] = BLACK_KING
		state.board[1][6] = BLACK_ROOK
		state.board[1][8] = 0
		state.kings_moved[core.PLAYER_BLACK] = true
		state.rooks_moved[18] = true
		state.player_turn = core.PLAYER_WHITE
	elseif param == WHITE_L_CASTLING then
		state.board[8][5] = 0
		state.board[8][3] = WHITE_KING
		state.board[8][4] = WHITE_ROOK
		state.board[8][1] = 0
		state.kings_moved[core.PLAYER_WHITE] = true
		state.rooks_moved[81] = true
		state.player_turn = core.PLAYER_BLACK
	elseif param == WHITE_R_CASTLING then
		state.board[8][5] = 0
		state.board[8][7] = WHITE_KING
		state.board[8][6] = WHITE_ROOK
		state.board[8][8] = 0
		state.kings_moved[core.PLAYER_WHITE] = true
		state.rooks_moved[88] = true
		state.player_turn = core.PLAYER_BLACK
	else
		error("Unhandled param")
	end
end

local castling_types = {
	BLACK_L_CASTLING,
	BLACK_R_CASTLING,
	WHITE_L_CASTLING,
	WHITE_R_CASTLING,
}

local get_player_from_castling_type = {
	[BLACK_L_CASTLING] = core.PLAYER_BLACK,
	[BLACK_R_CASTLING] = core.PLAYER_BLACK,
	[WHITE_L_CASTLING] = core.PLAYER_WHITE,
	[WHITE_R_CASTLING] = core.PLAYER_WHITE,
}

local get_move_from_castling_type = {
	[BLACK_L_CASTLING] = { src = { y = 1, x = 5 }, dst = { y = 1, x = 3 } },
	[BLACK_R_CASTLING] = { src = { y = 1, x = 5 }, dst = { y = 1, x = 7 } },
	[WHITE_L_CASTLING] = { src = { y = 8, x = 5 }, dst = { y = 8, x = 3 } },
	[WHITE_R_CASTLING] = { src = { y = 8, x = 5 }, dst = { y = 8, x = 7 } },
}

for i=0,ALL_CASTLING do
	local state
	local orig_state = new_castling_possible_state(i)

	
	for _, castling_type in ipairs(castling_types) do
		local castling_possible = ( (i & castling_type) ~= 0 )
		local player_turn = get_player_from_castling_type[castling_type]
		local player_move = get_move_from_castling_type[castling_type]

		state = core.copy_state(orig_state)
		state.player_turn = player_turn
		local src = player_move.src
		local dst = player_move.dst
		local rc

		rc = core.player_touch(state, player_turn, src)
		assert(state.selected.y == src.y)
		assert(state.selected.x == src.x)
		if rc ~= core.SUCCESS then
			error(string.format("first touch returned %d", rc))
		end

		rc = core.player_touch(state, player_turn, dst)
		if rc ~= core.SUCCESS then
			error(string.format("second touch returned %d", rc))
		end
		--assert(state.player_turn == core.PLAYER_WHITE)
		--assert(state.selected == nil)

		local expected_state
		if castling_possible then
			expected_state = new_castling_possible_state(i)
			apply_castling_type(expected_state, castling_type)
		else
			expected_state = core.copy_state(orig_state)
			expected_state.player_turn = player_turn
		end

		if not core.states_eq(state, expected_state) then
			print(string.format("For case where castling_possible=%s", castling_possible))
			print("Expected state:")
			core.print_state(expected_state)
			print("#######################")
			print("")
			print("Actual state:")
			core.print_state(state)
			print("#######################")
			print("")

			error("Expected and actual states do not match")
		else
			print(string.format("Test 0x%x passed for castling type %d!", i, castling_type))
		end

	end
end

print("All castling tests passed!")
