local bit_pack = {}

local function bit_mask(pos)
	return (1<<pos) - 1
end

local function to_bin_str(val, places)
	if val == nil then return 'nil' end
	local bin_str = ''
	if places == nil then
		places = 8
	end
	for i=places-1,0,-1 do
		if ( val & (1<<i) ) > 0 then
			bin_str = bin_str .. '1'
		elseif places ~= nil or #bin_str > 0 then
			bin_str = bin_str .. '0'
		end
	end

	if #bin_str == 0 then
		return '0'
	else
		return bin_str
	end
end

function bit_pack.pack(vals_list, bit_count)
	local packed_bytes = {}
	local bit_buff = 0
	local bits_written = 0
	for _, val in ipairs(vals_list) do
		bit_buff = (bit_buff << bit_count) | (val & bit_mask(bit_count))
		bits_written = bits_written + bit_count

		if bits_written >= 8 then
			local byte_to_write = bit_buff >> (bits_written - 8)
			bits_written = bits_written - 8
			bit_buff = bit_buff & bit_mask(bits_written)
			table.insert(packed_bytes, byte_to_write)
		end
	end

	if bits_written > 0 then
		table.insert(packed_bytes, bit_buff << (8 - bits_written))
	else
		bits_written = 8
	end

	table.insert(packed_bytes, bits_written)

	return packed_bytes
end

function bit_pack.unpack(packed_bytes, bit_count)
	local vals = {}
	local bits_in_last_byte = packed_bytes[ #packed_bytes ]
	local bits_in_buff = 0
	local bit_buff = 0

	for idx, byte in ipairs(packed_bytes) do
		local bits_to_read
		local offset
		if idx == #packed_bytes - 1 then
			bits_to_read = bits_in_last_byte
			offset = 8 - bits_in_last_byte
		elseif idx < #packed_bytes - 1 then
			bits_to_read = 8
			offset = 0
		elseif idx == #packed_bytes then
			goto next_idx
		else
			error(string.format("Unhandled idx %d, len %d", idx, #packed_bytes))
		end

		bits_to_read = bits_to_read + bits_in_buff
		bit_buff = (bit_buff << 8) | byte
		while bits_to_read >= bit_count do
			local val = bit_buff >> (bits_to_read - bit_count + offset)
			bits_to_read = bits_to_read - bit_count
			bit_buff = bit_buff & (bit_mask(bits_to_read) << offset)
			table.insert(vals, val)
		end

		bits_in_buff = bits_to_read
		::next_idx::
	end

	return vals
end

local function lists_eq(list1, list2)
	if #list1 ~= list2 then return false end
	for i, val1 in ipairs(list1) do
		if list1[i] ~= list2[i] then
			return false
		end
	end

	return true
end


--[[
local packed = bit_pack.pack({ 0, 1, 2, 3, 4, 5, 6, 7 }, 3)
local expected_output = { tonumber("000".."001" .. "01", 2), 
                          tonumber("0" .. "011".."100" .. "1", 2), 
                          tonumber("01" .. "110" .. "111", 2),
                          8 }
print(string.format('eq: %s',  lists_eq(expected_output, packed)))

print('')
for i=7,0,-1 do
	io.write(i)
end
io.write('\n')
print('---------')
for i, val in ipairs(packed) do
	print(val)
	assert(val < 256)
	print(to_bin_str(val, 8), to_bin_str(expected_output[i], 8), val == expected_output[i])
end

print('---expected:')
for _, val in ipairs(expected_output) do
	print(to_bin_str(val, 8))
end

-- 000 001 01
-- 0 011 110 1
-- 01 110 001
-- 00 000000
--]]

return bit_pack
