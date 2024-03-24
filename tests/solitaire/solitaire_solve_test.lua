#!/usr/bin/env lua5.3

local cards = require("src/lua_scripts/libs/cards/cards")
local core  = require("src/lua_scripts/games/solitaire/solitaire_core")
local serialize = require("src/lua_scripts/games/solitaire/solitaire_serialize")
local solve = require("src/lua_scripts/games/solitaire/solitaire_solve")
local utils = require("src/lua_scripts/libs/utils")


-- here is a winnable game, not too difficult
local games = {
	{
		state_serialized_hrstr = '18 16 2a 31 30 1b 00 24 07 22 02 23 29 11 05 19 21 0e 0d 0a 03 2c 09 25 0b 00 00 01 0c 01 2e 01 27 02 20 17 01 01 03 2d 04 2f 01 1a 04 08 28 32 15 01 1f 05 18 26 10 06 13 01 14 06 1d 1e 2b 0f 33 1c 01 12 00 00 00 00',
		is_solvable = true,
	},
	{
		state_serialized_hrstr = '18 01 1a 22 1c 04 07 03 25 23 05 27 14 0f 24 09 1d 30 28 0e 18 00 08 13 2d 00 00 01 2a 01 12 01 1e 02 17 06 01 1b 03 0b 15 0a 01 2e 04 31 0d 26 32 01 2f 05 11 29 16 1f 10 01 33 06 0c 02 2b 20 19 2c 01 21 00 00 00 00',
		is_solvable = true,
	},
	{
		state_serialized_hrstr = '18 16 01 0b 2f 00 28 02 2c 14 0c 22 27 26 12 31 33 05 1b 19 25 24 0e 17 06 00 00 01 09 01 30 01 03 02 23 29 01 1a 03 32 07 20 01 2a 04 2e 13 0a 0d 01 15 05 08 11 10 1f 1e 01 2b 06 1c 21 2d 1d 0f 04 01 18 00 00 00 00',
		is_solvable = true,
	},
	{
		state_serialized_hrstr = '18 2c 2d 0c 18 31 06 01 32 13 29 12 17 07 2e 24 16 2a 2b 14 1e 1b 08 21 0a 00 00 01 1d 01 15 01 26 02 0e 05 01 23 03 2f 0f 20 01 00 04 33 1f 1a 30 01 22 05 11 25 1c 19 02 01 03 06 0d 28 0b 09 27 04 01 10 00 00 00 00',
		is_solvable = true,
	},
	{
		state_serialized_hrstr = '18 01 20 32 10 29 02 13 2a 08 1c 14 0f 2e 2f 07 1e 0b 2b 26 1b 0e 33 16 17 00 00 01 1d 01 00 01 21 02 09 25 01 05 03 28 19 04 01 06 04 27 22 23 0d 01 11 05 24 30 03 0c 2c 01 1f 06 2d 15 0a 31 1a 18 01 12 00 00 00 00',
		is_solvable = true,
	},
	{
		state_serialized_hrstr = '18 21 18 2d 08 0f 1e 0e 15 09 1f 06 00 03 32 19 0c 26 2f 2b 02 10 30 05 1b 00 00 01 27 01 28 01 01 02 31 20 01 13 03 23 33 29 01 17 04 2c 24 2e 07 01 14 05 12 1d 1c 11 2a 01 04 06 0b 0d 25 16 22 1a 01 0a 00 00 00 00',
		is_solvable = true, -- TODO I haven't tried this one myself yet
	},
	--[[
	{
		state_serialized_hrstr = '18 14 01 1d 23 28 12 0e 21 0a 33 1e 1f 2b 27 07 03 13 08 2d 04 0c 0b 2c 18 00 00 01 2a 01 0f 01 06 02 02 2e 01 15 03 1b 0d 30 01 22 04 09 11 29 05 01 10 05 17 26 20 16 2f 01 19 06 00 1a 1c 24 32 31 01 25 00 00 00 00',
		is_solvable = false, -- it may be solvable, but I wasn't able to solve it manually
	},
	--[[
	]]
}

local player = 1
local num_players = 1

local function get_state(test)
	local serialized_board_state = utils.hr_binstr_to_binstr(test.state_serialized_hrstr)
	local board_state = serialize.deserialize_board_state(serialized_board_state)
	local state = core.new_state_from_board_state(num_players, board_state)
	return state
end

-- Test that putting an ace in each goal stack does not result in a
-- different hash
if true then
	local state = get_state(games[1])
	assert(solve.get_goal_stacks_hash(state) == '\x00\x00\x00\x00')
	for i=1,4 do
		local state_copy = core.copy_state(state)
		assert(#state_copy.goal_stacks[i] == 0)
		local move = {
			src = {section_type = core.SECTION_PLAY_COLUMN_STAGING, col = 2, idx=1 },
			dst = {section_type = core.SECTION_GOAL_STACKS, col = i },
		}
		local rc = core.handle_move(state_copy, player, move)
		assert(solve.get_goal_stacks_hash(state_copy) == '\x00\x00\x00\x01\x27')
		assert(#state_copy.goal_stacks[i] == 1)
		assert(rc == true)
	end
end

-- Test that cycling through the deck does not result in a unique hash
if true then
	local state = get_state(games[1])
	local hash = solve.state_to_hash(state)
	for i = 1,200 do
		local state_copy = core.copy_state(state)
		core.next_in_deck(state_copy)
		local hash2 = solve.state_to_hash(state_copy)
		assert(hash == hash2)
	end
end

for test_num, test in ipairs(games) do
	local start_time_s = os.clock()
	local state = get_state(test)
	local solve_state = solve.new_solve_state({
		update_period = nil, -- 1000,
		timeout_s = 10,
		id = string.format('Test id %d, is_solvable=%s', test_num, test.is_solvable),
	})
	--local solve_state = solve.new_solve_state({update_period = 1})
	local is_solvable = solve.is_solvable(state, solve_state)
	local end_time_s = os.clock()
	local time_taken_s = end_time_s - start_time_s
	assert(is_solvable == test.is_solvable)
	print(string.format("Test %d passed in %5.2f s, tried %7d unique states, " ..
	                    "%7d iterations",
	                    test_num, time_taken_s, solve_state.unique_states_counter,
	                    solve_state.counter))
end

-- core.print_state(state)
