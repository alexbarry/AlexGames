local core = {}

local shuffle = require("libs/shuffle")

core.RC_SUCCESS      = 0
core.RC_INVALID_MOVE = 1

function core.new_state(num_colours, num_extra_vials, num_segments, params)
	local seed_x, seed_y
	if params and params.seed_x and params.seed_y then
		seed_x, seed_y = math.randomseed(params.seed_x, params.seed_y)
	else
		seed_x, seed_y = math.randomseed()
	end

	local vials_and_segments_flat = {}
	for color_idx=1,num_colours do
		for seg=1,num_segments do
			table.insert(vials_and_segments_flat, color_idx)
		end
	end

	shuffle.shuffle(vials_and_segments_flat)

	local state = {
		num_segments = num_segments,
		vials = {},
		seed_x = seed_x,
		seed_y = seed_y,
	}
	local num_vials = num_colours + num_extra_vials
	local i = 1
	for _=1,num_vials do
		local vial = {}
		for _=1,num_segments do
			local val = 0
			if i <= #vials_and_segments_flat then
				val = vials_and_segments_flat[i]
				i = i + 1
				table.insert(vial, val)
			end
		end
		table.insert(state.vials, vial)
	end

	return state
end

function core.game_won(state)
	for _, vial in ipairs(state.vials) do
		if #vial == 0 then
			goto next_vial
		end

		if #vial ~= state.num_segments then
			return false
		end

		for _, seg in ipairs(vial) do
			if seg ~= vial[1] then
				return false
			end
		end

		::next_vial::
	end

	return true
end

local function get_same_segs_count(state, idx)
	local vial = state.vials[idx]

	if #vial == 0 then return 0 end

	local colour = vial[#vial]
	local seg_idx = 1
	while vial[#vial-seg_idx+1] == colour do
		if seg_idx == #vial then
			return #vial
		end
		seg_idx = seg_idx + 1
	end

	return seg_idx - 1
end

function core.move(state, src, dst)
	local src_vial = state.vials[src]
	local dst_vial = state.vials[dst]

	if #src_vial == 0 then
		return core.RC_INVALID_MOVE
	end


	if state.num_segments - #dst_vial < get_same_segs_count(state, src) then
		return core.RC_INVALID_MOVE
	end

	if #dst_vial > 0 and dst_vial[#dst_vial] ~= src_vial[#src_vial] then
		return core.RC_INVALID_MOVE
	end

	if src == dst then
		return core.RC_INVALID_MOVE
	end

	local colour = src_vial[#src_vial]
	while src_vial[#src_vial] == colour do
		local val = table.remove(src_vial, #src_vial)
		table.insert(dst_vial, val)
	end
end

return core
