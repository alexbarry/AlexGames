local storage_helpers = {}

local utils = require("libs/utils")

local alexgames = require("alexgames")

function storage_helpers.store_bool(key, val)
	if type(val) ~= 'boolean' then
		error(string.format("Expected arg val to be type boolean, was %s", type(val)),2)
	end

	data = { utils.boolean_to_number(val) }

	alexgames.store_data(key, data)
end

function storage_helpers.read_bool(key, default_val)
	local data = alexgames.read_stored_data(key)

	if data == nil then
		return default_val
	end

	if #data ~= 1 then
		error(string.format("Expected a single byte when reading stored value %s, received %d bytes", key, #data))
	end

	local val = string.byte(data:sub(1,1))
	print(string.format("val = %s", val))

	return utils.number_to_boolean(val)
end

return storage_helpers
