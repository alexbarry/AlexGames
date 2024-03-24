local combinations = {}

local utils = require("libs/utils")

-- Loops through every combination of possible combinations
-- of elements in the input, where order does not matter
--
-- It is like looping through binary:
--     0 0 0 1
--     0 0 1 0
--     0 0 1 1
--     0 1 0 0
--     0 1 0 1
--     0 1 1 0
--     0 1 1 1
--     ... etc
function combinations.get_combos(ary)
	
	local chosen = {}
	for i=1,#ary do
		chosen[i] = false
	end


	local to_return_combos = {}
	-- loop through all combinations of cards, like counting in binary:
	-- 0 0 0 0
	-- 0 0 0 1
	-- 0 0 1 0
	-- 0 0 1 1
	-- 0 1 0 0
	-- ...
	-- io.write(string.format("starting loop... %d %d\n", #ary, #chosen))
	while true do
		--[[
		local chosen_copy = {}
		for idx,val in ipairs(chosen) do
			chosen_copy[idx] = val
		end
		table.insert(to_return_combos, chosen_copy)
		]]
		local combo = {}
		for idx,val in ipairs(chosen) do
			if val then
				table.insert(combo, ary[idx])
			end
		end
		table.insert(to_return_combos, combo)

		local i = 1
		while i <= #ary and chosen[i] do
			chosen[i] = false
			i = i + 1
		end
		if i > #ary then
			goto end_loop
		else
			chosen[i] = true
		end
	end
	::end_loop::
	return to_return_combos
end

local function sum(ary)
	local val = 0
	for _, elem in ipairs(ary) do
		val = val + elem
	end
	return val
end

-- Given an array of values e.g. {a, b, c}
-- Returns every distinct sum and the pieces that make it up, e.g.:
-- {
--     { val = a,     parts = {a}       },
--     { val = a+b,   parts = {a, b}    },
--     { val = a+b+c, parts = {a, b, c} },
--     { val = a+c,   parts = {a, c}    },
--     -- Note that any duplicate sums (say if a == b) would only be included once
-- }
function combinations.get_distinct_sums(ary)
	local sums_map = {}
	local combos = combinations.get_combos(ary)
	for _, vals in ipairs(combos) do
		-- skip any combinations with zero in them, so that the "selected indexes" (`parts`) will
		-- not contain unused values
		if utils.any_eq(vals, 0) then
			goto next_val_combo
		end
		local sum_val = sum(vals)
		sums_map[sum_val] = vals
		::next_val_combo::
	end

	local distinct_sums = {}
	for sum_val, parts in pairs(sums_map) do
		table.insert(distinct_sums, { val = sum_val, parts = parts })
	end

	return distinct_sums
end

return combinations
