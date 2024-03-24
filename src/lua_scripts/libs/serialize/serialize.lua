local serialize = {}

function serialize.bytestr_to_byteary(bytestr)
	if bytestr == nil then
		error("arg is nil", 2)
	end
	local byteary = {}
	for i=1,#bytestr do
		byteary[i] = bytestr:sub(i,i)
	end
	return byteary
end

function serialize.serialize_byte(val)
	if val == nil then
		val = 255
	end
	-- return string.char(val)
	local output
	local state, err = pcall(function() output = string.char(val) end )
	if not state then
		error(string.format("bad argument to serialize_byte: %s", val), 2)
	end
	return output
end

function serialize.deserialize_byte(bytes)
	if bytes == nil then
		error("arg is nil", 2)
	elseif #bytes == 0 then
		error("arg is length 0", 2)
	end
	if type(bytes) ~= "table" then
		error(string.format("arg is %s, expected table", type(bytes)), 2)
	end
	local val = string.byte(table.remove(bytes, 1))
	if val == 255 then return nil end
	return val
end




function serialize.serialize_16bit(val)
	local output = ""
	local orig_val = val
	if val == nil then
		val = 0x7fff
	else
		val = math.floor(val)
	end
	val = val + 0x7fff
	if not(0 <= val and val <= 0xffff) then
		error(string.format("Need 16 bit val, recvd %s", orig_val))
		return nil
	end
	output = output .. string.char(math.floor((val/256))&0xff)
	output = output .. string.char(math.floor(val%256))
	return output
end

function serialize.deserialize_16bit(bytes)
	if #bytes < 2 then
		error(string.format("Expected at least 2 bytes, recvd %d", #bytes))
	end
	local msb = string.byte(table.remove(bytes,1))
	local lsb = string.byte(table.remove(bytes,1))
	local val = ((msb << 8) | lsb) - 0x7fff
	--print(string.format("deserialize_16bit %02x %02x returning %s", msb, lsb, val))
	if val == 0x7fff then
		return nil
	else
		return val
	end
end

function serialize.serialize_s32(val)
	if val == nil then
		error("nil arg", 2)
	end
	local bytes = {}
	local byte_count = 4
	local orig_val = val
	val = val + 0x7fffffff
	if not(0 <= val and val <= 0xffffffff) then
		error(string.format("val %s is out of range for s32", orig_val))
	end

	for i=1,byte_count do
		bytes[byte_count-i+1] = string.char(val & 0xFF)
		val = val >> 8
	end
	return table.concat(bytes, "")
end

local s32_nil = 0x7ffffffe
function serialize.serialize_s32_nilable(val)
	if val == nil then
		val = s32_nil
	end
	return serialize.serialize_s32(val)
end

function serialize.deserialize_s32_nilable(bytes)
	local val = serialize.deserialize_s32(bytes)
	if val == s32_nil then
		return nil
	else
		return val
	end
end

function serialize.deserialize_s32(bytes)
	local val = 0
	local byte_count = 4
	if #bytes < byte_count then
		error(string.format("Expected at least %d bytes, recvd %d", byte_count, #bytes))
		return
	end
	for i=1,byte_count do
		local bit_pos = 8 * (byte_count-i)
		val = val | (string.byte(table.remove(bytes,1))<<bit_pos)
	end
	val = val - 0x7fffffff
	return val
end

function serialize.serialize_u64(val)
	if val == nil then
		error("nil arg", 2)
	end
	local bytes = {}
	local byte_count = 8
	local orig_val = val

	for i=1,byte_count do
		bytes[byte_count-i+1] = string.char(val & 0xFF)
		val = val >> 8
	end
	return table.concat(bytes, "")
end

function serialize.deserialize_u64(bytes)
	local val = 0
	local byte_count = 8
	if #bytes < byte_count then
		error(string.format("Expected at least %d bytes, recvd %d", byte_count, #bytes))
		return
	end
	for i=1,byte_count do
		local bit_pos = 8 * (byte_count-i)
		val = val | (string.byte(table.remove(bytes,1))<<bit_pos)
	end
	return val
end

function serialize.serialize_bool(val)
	if val then return string.char(1)
	else return string.char(0) end
end

function serialize.deserialize_bool(bytes)
	if bytes == nil then
		error(string.format("arg is nil"), 2)
	elseif #bytes == 0 then
		error(string.format("arg is empty"), 2)
	end
	local byte = string.byte(table.remove(bytes,1))
	if byte == 0 then return false
	elseif byte == 1 then return true
	else error(string.format("invalid byte for bool %s", byte), 2) end
end

function serialize.serialize_string(s)
	if s == nil then
		return serialize.serialize_16bit(0x7fff)
	end
	return serialize.serialize_16bit(#s) .. s
end

function serialize.deserialize_string(bytes)
	--print("deserialize_string called with byte count = " .. #bytes)
	local str_len = serialize.deserialize_16bit(bytes)
	-- TODO which is expected?
	if str_len == 0x7fff or str_len == nil then
		return nil
	end
	--print(string.format("str_len = %s", str_len))
	if #bytes < str_len then
		error(string.format("serialize_lib.deserialize_string only has %d bytes remaining, expected %d", #bytes, str_len), 2)
	end
	local chars = {}
	for i=1,str_len do
		table.insert(chars, table.remove(bytes, 1))
	end
	--print("deserialize_string finished with byte count = " .. #bytes)
	local s = table.concat(chars, "")
	--print(string.format("returning str = \"%s\"", s))
	return s
end

function serialize.serialize_bytes(bytes)
	local chars = {}
	for i, val in ipairs(bytes) do
		if val < 0 or val > 255 then
			error(string.format("serialize_bytes: Found val %d at idx %d, must be between 0 and 255", val, i), 2)
		end
		table.insert(chars, string.char(val))
	end
	return table.concat(chars, "")
end

function serialize.deserialize_bytes(bytes_chars)
	print(string.format("arg is %s",bytes_chars))
	if bytes_chars == nil then error("nil arg", 2) end
	local vals = {}
	for i=1,#bytes_chars do
		table.insert(vals, string.byte(bytes_chars[1]))
		table.remove(bytes_chars, 1)
	end
	return vals
end

return serialize
