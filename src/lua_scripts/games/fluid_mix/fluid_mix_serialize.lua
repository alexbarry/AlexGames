local serialize = {}

local serialize_lib = require("libs/serialize/serialize")

serialize.VERSION = 2

function serialize.serialize(state)
	local output = ""
	output = output .. serialize_lib.serialize_byte(serialize.VERSION)
	output = output .. serialize_lib.serialize_byte(state.num_segments)
	output = output .. serialize_lib.serialize_byte(#state.vials)
	for _, vial in ipairs(state.vials) do
		output = output .. serialize_lib.serialize_byte(#vial)
		for _, seg_val in ipairs(vial) do
			output = output .. serialize_lib.serialize_byte(seg_val)
		end
	end
	output = output .. serialize_lib.serialize_u64(state.seed_x)
	output = output .. serialize_lib.serialize_u64(state.seed_y)

	return output
end

function serialize.deserialize(bytes)
	local state = {}
	bytes = serialize_lib.bytestr_to_byteary(bytes)
	local version
	-- version 1, I didn't have a version number for this one,
	-- and had 14 vials with... 4 segments each and 3 empty ones
	-- TODO remove this, there is probably some combination of parameters
	-- where versions > 1 can have the same number of bytes
	if #bytes == 2 + 14 + (14-3)*4 + 4*2 then
		version = 1
	else
		version = serialize_lib.deserialize_byte(bytes)
		if version ~= serialize.VERSION then
			error(string.format("Unhandled fluid_mix serialized state version %d", version))
		end
	end
	state.num_segments = serialize_lib.deserialize_byte(bytes)
	state.vials = {}
	local vial_count   = serialize_lib.deserialize_byte(bytes)
	for _=1,vial_count do
		local segs_in_vial = serialize_lib.deserialize_byte(bytes)
		local vial = {}
		for _=1,segs_in_vial do
			table.insert(vial, serialize_lib.deserialize_byte(bytes))
		end
		table.insert(state.vials, vial)
	end

	if version == 1 then
		-- This is what I did before, but it's wrong-- on wxWidgets at least,
		-- the seed can be greater than 32 bits
		state.seed_x = serialize_lib.deserialize_s32(bytes)
		state.seed_y = serialize_lib.deserialize_s32(bytes)
	elseif version == serialize.VERSION then
		state.seed_x = serialize_lib.deserialize_u64(bytes)
		state.seed_y = serialize_lib.deserialize_u64(bytes)
	end

	assert(#bytes == 0)

	return state
end

return serialize
