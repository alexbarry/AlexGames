local utils = {}

function utils.ary_to_str(ary)
	if ary == nil then return "nil" end
	local s = "["
	local first = true
	-- Somehow I didn't realize that ipairs will stop after encountering a nil value,
	-- and pairs will just skip over it.
	--for _, val in ipairs(ary) do
	for i=1,#ary do
		local val = ary[i]
		if not first then
			s = s .. ", "
		end
		first = false
		s = s .. string.format("%s", val)
	end
	s = s .. "]"
	return s
end

function utils.binstr_to_hr_str(binstr)
	if binstr == nil then
		error("arg is nil", 2)
	end
	local s = ""
	for i=1,#binstr do
		local byte = string.byte(binstr:sub(i,i))
		s = s .. string.format("%02x ", byte)
	end
	return s
end

function utils.hr_binstr_to_byte_ary(hr_binstr)
	local byte_ary = {}
	while #hr_binstr > 0 do
		local byte_val_str = hr_binstr:sub(1,3)
		local byte_val = tonumber(byte_val_str, 16)
		table.insert(byte_ary, byte_val)
		if #hr_binstr >= 4 then
			hr_binstr = hr_binstr:sub(4, #hr_binstr)
		else
			break
		end
	end
	return byte_ary
end

function utils.hr_binstr_to_binstr(hr_binstr)
	local byte_ary = utils.hr_binstr_to_byte_ary(hr_binstr)
	local binstr = ''
	for _, val in ipairs(byte_ary) do
		binstr = binstr .. string.char(val)
	end
	return binstr
end

function utils.binary_to_hr_str(binary)
	local s = ""
	for i=1,#binary do
		local byte = string.byte(binary[i])
		s = s .. string.format("%02x ", byte)
	end
	return s
end

-- If iter_dir is positive, returns something like an inclusive python range(start,end,iter)
-- If iter_dir is negative, returns range(end, start, iter)
-- The idea being that this can be used and the order can be reserved simply by making iter_dir 1 or -1
function utils.iter_range(start_idx, end_idx, iter_dir)
	local tbl = {}
	if iter_dir < 0 then
		if start_idx < end_idx then
			local tmp = end_idx
			end_idx = start_idx
			start_idx = tmp
		end
	end
	for i=start_idx, end_idx, iter_dir do
		table.insert(tbl, i)
	end
	return tbl
end

--
-- Given:
--     val_ary       = { 10, 20, 30, 40 }
--     vals_selected = { 40, 20}
-- Will return the indexes in val_ary of vals_selected, e.g.:
--     return { 4, 2 }
function utils.get_val_indexes(val_ary, vals_selected)
	if val_ary == nil or vals_selected == nil then
		error(string.format("get_val_indexes nil args: val_ary = %s, vals_selected = %s", val_ary, vals_selected), 2)
	end
	local val_idxes = {}

	local vals_used = {}
	for i=1,#val_ary do
		vals_used[i] = false
	end

	for _, val_selected in ipairs(vals_selected) do
		for i, val in ipairs(val_ary) do
			if val == val_selected and not vals_used[i] then
				table.insert(val_idxes, i)
				vals_used[i] = true
				goto next_val_selected
			end
		end
		error(string.format("Could not find unused val %s in ary %s", val_selected, utils.ary_to_str(val_ary)), 2)
		::next_val_selected::
	end

	return val_idxes
end

function utils.any_eq(vals, val_arg)
	for _, val in ipairs(vals) do
		if val == val_arg then return true end
	end
	return false
end

function utils.ary_copy(ary)
	local new_ary = {}
	for _, val in ipairs(ary) do
		table.insert(new_ary, val)
	end
	return new_ary
end

function utils.ary_of(val, len)
	local new_ary = {}
	for i=1,len do
		table.insert(new_ary, val)
	end
	return new_ary
end

function utils.reverse_map(map)
	local reversed_map = {}
	for key, value in pairs(map) do
		if reversed_map[value] ~= nil then
			error(string.format("utils.reverse_map: found duplicate values \"%s\" in map", value))
		end
		reversed_map[value] = key
	end
	return reversed_map
end

function utils.table_len(tbl)
	if tbl == nil then
		error("utils.table_len arg is nil", 2)
	end
	local count = 0
	for _, _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function utils.make_first_char_uppercase(str)
	if str == nil then return nil end
	return (str:gsub("^%l", string.upper))
end

function utils.gmatch_to_list(pattern, str)
	local vals = {}
	for token in str:gmatch(pattern) do
		table.insert(vals, token)
	end

	return vals
end

function utils.slice_list(list, start_idx, end_idx)
	return {table.unpack(list, start_idx, end_idx)}
end

function utils.number_to_boolean(num)
	if type(num) ~= 'number' then
		error(string.format("Argument is type %s, expected number", num, type(num)), 2)
	end

	return num ~= 0
end

function utils.boolean_to_number(val)
	if type(val) ~= 'boolean' then
		error(string.format('Argument %s is type %s, expected boolean', type(val)), 2)
	end

	if val == nil then
		error(string.format('Argument is nil'), 2)
	end

	if val then return 1
	else return 0 end
end

return utils
