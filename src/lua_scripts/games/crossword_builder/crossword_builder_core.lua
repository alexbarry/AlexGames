local core = {}

local words_lib = require("libs/words")
local shuffle   = require("libs/shuffle")

local letter_tiles = require("libs/letter_tiles")

local LANGUAGE = "en"

core.LETTER_EMPTY = letter_tiles.LETTER_EMPTY

core.RC_SUCCESS = 0
core.RC_LETTERS_NOT_IN_A_LINE   = -1
core.RC_LETTERS_NOT_CONTINUOUS  = -2
core.RC_WORD_NOT_IN_DICTIONARY  = -3

local RC_TO_STR_MAP = {
	[core.RC_LETTERS_NOT_IN_A_LINE]  = "Letters not in a horizontal or vertical line",
	[core.RC_LETTERS_NOT_CONTINUOUS] = "Letters not continuous",
	[core.RC_WORD_NOT_IN_DICTIONARY] = "Word not in dictionary",
}


local LETTERS_PER_PLAYER = 8

local LETTER_AMOUNTS = {
	{ letter = "E", count = 14, points = 1 },
	{ letter = "A", count = 10, points = 1 },
	{ letter = "I", count =  8, points = 1 },
	{ letter = "O", count =  7, points = 1 },
	{ letter = "N", count =  8, points = 1 },
	{ letter = "R", count =  8, points = 1 },
	{ letter = "T", count =  6, points = 1 },
	{ letter = "L", count =  5, points = 1 },
	{ letter = "S", count =  4, points = 1 },
	{ letter = "U", count =  4, points = 1 },

	{ letter = "D", count =  4, points = 2 },
	{ letter = "G", count =  3, points = 2 },

	{ letter = "B", count =  2, points = 2 },
	{ letter = "C", count =  2, points = 2 },
	{ letter = "M", count =  2, points = 3 },
	{ letter = "P", count =  2, points = 3 },

	{ letter = "F", count =  2, points = 5 },
	{ letter = "H", count =  2, points = 5 },
	{ letter = "V", count =  2, points = 5 },
	{ letter = "W", count =  2, points = 5 },
	{ letter = "Y", count =  2, points = 5 },

	{ letter = "K", count =  1, points = 6 },

	{ letter = "J", count =  1, points = 8 },
	{ letter = "X", count =  1, points = 9 },

	{ letter = "Q", count =  1, points = 10 },
	{ letter = "Z", count =  1, points = 10 },
}

local LETTERS_TO_POINTS = {}

for _, info in ipairs(LETTER_AMOUNTS) do
	LETTERS_TO_POINTS[info.letter] = info.points
end

function core.get_letter_points(letter)
	return LETTERS_TO_POINTS[letter]
end

function core.rc_to_str(rc)
	local s = RC_TO_STR_MAP[rc]

	if s == nil then
		error(string.format("Could not convert rc %s to string", rc))
	end

	return s
end

function core.submit_info_to_msg(submit_info)
	if submit_info.rc == core.RC_WORD_NOT_IN_DICTIONARY then
		return string.format("Word '%s' (pos y=%d,x=%d) not in dictionary", submit_info.word, submit_info.pos.y, submit_info.pos.x)
	else
		return core.rc_to_str(submit_info.rc)
	end
end

function core.new_state(player_count)
	words_lib.init(LANGUAGE)
	local state = {
		letters = {},
		players = {},
		grid_size_y = 12,
		grid_size_x = 12,

		grid = {},
	}

	for _, info in ipairs(LETTER_AMOUNTS) do
		for _=1,info.count do
			table.insert(state.letters, info.letter)
		end
	end

	shuffle.shuffle(state.letters)

	for _=1,player_count do
		local player_letters = {}
		for _=1,LETTERS_PER_PLAYER do
			local letter = table.remove(state.letters)
			table.insert(player_letters, letter)
		end
		table.insert(state.players, {
			letters = player_letters
		})
	end

	for y=1,state.grid_size_y do
		local row = {}
		for x = 1,state.grid_size_y do
			table.insert(row, core.LETTER_EMPTY)
		end
		table.insert(state.grid, row)
	end

	return state
end

local function sign(x)
	if x == 0 then return 0
	elseif x < 0 then return -1
	else return 1 end
end

local function letters_in_a_line(placed_letters)
	local dy = nil
	local dx = nil

	local prev_tile_info = nil
	for _, tile_info in ipairs(placed_letters) do
		if prev_tile_info ~= nil then
			local dy2 = prev_tile_info.y - tile_info.y
			local dx2 = prev_tile_info.x - tile_info.x

			if dy ~= nil then
				print(string.format("{y=%d, x=%d}, dy=%s, dx=%s, dy2=%s, dx2=%s", tile_info.y, tile_info.x, dy, dx, dy2, dx2))
				if dy == 0 and dy2 ~= 0 then return false end
				if dx == 0 and dx2 ~= 0 then return false end
	
				if dy == 0 and dx ~= 0 then
					--if sign(dx) ~= sign(dx2) then return false end
				elseif dx == 0 and dy ~= 0 then
					--if sign(dy) ~= sign(dy2) then return false end
				else
					return false
				end
			else
				dy = dy2
				dx = dx2
			end


		end
		prev_tile_info = tile_info
	end
	return true
end

local function get_letters_bounds(state, placed_letters)
	if #placed_letters == 0 then error("get_letters_bounds called with no placed_letters", 2) end
	local letters_start = nil
	local letters_end   = nil

	for _, letter_info in ipairs(placed_letters) do
		if letters_start == nil or
			(letter_info.y <= letters_start.y and
			 letter_info.x <= letters_start.x) then
			letters_start = letter_info
		end

		if letters_end == nil or
			(letter_info.y >= letters_end.y and
			 letter_info.x >= letters_end.x) then
			letters_end = letter_info
		end
	end

	-- TODO check if there are already letters before or after start/end?

	if letters_start == nil or letters_end == nil then
		error("could not find start or end of letters?")
	end
	return { start_pos = letters_start, end_pos = letters_end }
end

local function get_placed_letters_map(state, placed_letters)
	local placed_letters_map = {}
	for y=1,state.grid_size_y do
		placed_letters_map[y] = {}
	end
	for _, placed_letter_info in ipairs(placed_letters) do
		if placed_letters_map[placed_letter_info.y][placed_letter_info.x] ~= nil then
			error(string.format("already found letter at pos %d %d", placed_letter_info.y, placed_letter_info.x))
		end
		placed_letters_map[placed_letter_info.y][placed_letter_info.x] = placed_letter_info.letter
	end
	return placed_letters_map
end

local function get_letter(state, placed_letters, pt)
	local placed_letters_map = get_placed_letters_map(state, placed_letters)
	if placed_letters_map[pt.y][pt.x] then
		return placed_letters_map[pt.y][pt.x]
	else
		return state.grid[pt.y][pt.x]
	end
end


local function get_points_between_letters(state, bounds)
	local dy = sign(bounds.end_pos.y - bounds.start_pos.y)
	local dx = sign(bounds.end_pos.x - bounds.start_pos.x)
	print(string.format('get_points_between_letters, dy=%d, dx=%d', dy, dx))

	local pts = {}
	if dy ~= 0 then
		local x = bounds.start_pos.x
		for y=bounds.start_pos.y,bounds.end_pos.y,dy do
			table.insert(pts, { y = y, x = x })
		end
	elseif dx ~= 0 then
		local y = bounds.start_pos.y
		for x=bounds.start_pos.x,bounds.end_pos.x,dx do
			table.insert(pts, { y = y, x = x })
		end
	else
		table.insert(pts, { y = bounds.start_pos.y, x = bounds.start_pos.x })
	end
	return pts
end

local function letters_continuous(state, placed_letters)
	local bounds = get_letters_bounds(state, placed_letters)

	local placed_letters_map = get_placed_letters_map(state, placed_letters)

	for _, pos in ipairs(get_points_between_letters(state, bounds)) do
		if placed_letters_map[pos.y][pos.x] == nil and
		   state.grid[pos.y][pos.x] == core.LETTER_EMPTY then
			return false
		end
	end

	return true
end

local function get_word_formed(state, placed_letters)
	-- TODO need to get letters before and after if present
	local word = ""

	local bounds = get_letters_bounds(state, placed_letters)
	local placed_letters_map = get_placed_letters_map(state, placed_letters)
	for _, pt in ipairs(get_points_between_letters(state, bounds)) do
		local letter = nil
		if placed_letters_map[pt.y][pt.x] then
			letter = placed_letters_map[pt.y][pt.x]
		elseif state.grid[pt.y][pt.x] then
			letter = state.grid[pt.y][pt.x]
		else
			error(string.format("no letter at pos %d %d", pt.y, pt.x))
		end

		print(string.format("getting letter from pt %d %d: %s", pt.y, pt.x, letter))
		word = word .. letter
	end

	return word
end

local function in_range(state, y, x)
	return (1 <= y and y <= state.grid_size_y and
	        1 <= x and x <= state.grid_size_x)
end

local function find_end_pt(state, placed_letters, start_pt, dy, dx)
	print(string.format("find_end_pt called with pt %d %d, dy=%d, dx=%d", start_pt.y, start_pt.x, dy, dx))
	if dy == 0 and dx == 0 then return { y = start_pt.y, x = start_pt.x } end
	local y = start_pt.y
	local x = start_pt.x

	while true do
		if not in_range(state, y - dy, x - dx) then
			break
		end
		local letter = get_letter(state, placed_letters, { y = y - dy, x = x - dx })
		print(string.format("checking pt %d %d, %s", y, x, letter))
		if letter == core.LETTER_EMPTY then
			break
		end
		y = y - dy
		x = x - dx
	end

	print(string.format("find_end_pt returning with %d %d", y, x))
	return { y = y, x = x }
end

local function get_parallel_word_info(state, placed_letters, dy, dx)
	print(string.format("get_parallel_word_info"))
	local bounds = get_letters_bounds(state, placed_letters)
	local placed_letters_map = get_placed_letters_map(state, placed_letters)

	if dy ~= 0 and dx ~= 0 then
		error(string.format("expected horizontal or vertical line, received diagonal"))
	elseif dy == 0 and dx == 0 then
		-- for the case of a single letter (resulting in dy = 0 and dx = 0), just
		-- arbitrarily pick one to be 1, and the other to be 0.
		-- then this function (get_parallel_word_info) and the perpendicular one
		-- will work, even for this special case.
		error("expected non zero dy or dx.")
	end

	local start_pt = find_end_pt(state, placed_letters, bounds.start_pos, dy, dx)
	local end_pt   = find_end_pt(state, placed_letters, bounds.start_pos, -dy, -dx)

	local word = ""
	
	print(string.format("parallel word start %d %d, end %d %d", start_pt.y, start_pt.x, end_pt.y, end_pt.x))
	for offset=0,math.max(end_pt.y - start_pt.y, end_pt.x - start_pt.x) do
		local pt = {
			y = start_pt.y + offset*dy,
			x = start_pt.x + offset*dx
		}
		print(string.format("parallel word checking %d %d", pt.y, pt.x))

		local letter
		if placed_letters_map[pt.y][pt.x] then
			letter = placed_letters_map[pt.y][pt.x]
		elseif state.grid[pt.y][pt.x] then
			letter = state.grid[pt.y][pt.x]
		else
			error(string.format("could not find letter at %d %d", pt.y, pt.x))
		end

		word = word .. letter
	end

	return {
		start_pt = start_pt,
		end_pt   = end_pt,
		word     = word,
	}
end

local function between_pts(start_pt, end_pt)
	local dy = sign(end_pt.y - start_pt.y)
	local dx = sign(end_pt.x - start_pt.x)

	local pts = {}
	local y = start_pt.y
	local x = start_pt.x
	while y <= end_pt.y and x <= end_pt.x do
		table.insert(pts, { y = y, x = x })
		y = y + dy
		x = x + dx
	end

	return pts
end

local function find_perpendicular_word(state, placed_letters, pt, dy_arg, dx_arg)
	-- swap dy and dx: we're looking for perpendicular words
	local dy = dx_arg
	local dx = dy_arg

	local start_pt = find_end_pt(state, placed_letters, pt,  dy,  dx)
	local end_pt   = find_end_pt(state, placed_letters, pt, -dy, -dx)

	if start_pt.y == end_pt.y and
	   start_pt.x == end_pt.x then
		return nil
	else
		local word = ""
		for _, pt in ipairs(between_pts(start_pt, end_pt)) do
			local letter = get_letter(state, placed_letters, pt)
			word = word .. letter
		end
		return {
			start_pt = start_pt,
			end_pt   = end_pt,
			word     = word,
		}
	end
end

local function get_all_new_words_formed(state, placed_letters)
	local word_infos = {}
	local bounds = get_letters_bounds(state, placed_letters)

	local dy = sign(bounds.end_pos.y - bounds.start_pos.y)
	local dx = sign(bounds.end_pos.x - bounds.start_pos.x)

	local skip_parallel = false
	local skip_parallel = false
	if #placed_letters == 1 then
		assert(dy == 0)
		assert(dx == 0)

		-- Arbitrarily choosing horizontal as the "parallel" direction with one letter
		dx = 1

		-- Since I chose horizontal as "parallel", check if we need to actually
		-- look for "perpendicular" letters ( y-1 and y+1)
		local pt1 = { y = bounds.start_pos.y, x = bounds.start_pos.x - 1 }
		local pt2 = { y = bounds.start_pos.y, x = bounds.start_pos.x + 1 }

		local l1 = get_letter(state, placed_letters, pt1)
		local l2 = get_letter(state, placed_letters, pt2)
		print(string.format("l1=%s, l2=%s", l1, l2))
		if get_letter(state, placed_letters, pt1) == core.LETTER_EMPTY and
		   get_letter(state, placed_letters, pt2) == core.LETTER_EMPTY then
			skip_parallel = true
		end
	end
		
	if not skip_parallel then
		local parallel_word_info = get_parallel_word_info(state, placed_letters, dy, dx)
		print(string.format("Found parallel word: %s", parallel_word_info.word))
		table.insert(word_infos, parallel_word_info)
	end

	for _, pt in ipairs(get_points_between_letters(state, bounds)) do
		local perp_info = find_perpendicular_word(state, placed_letters, pt, dy, dx)
		if perp_info then
			print(string.format("Found perpendicular word: %s", perp_info.word))
			table.insert(word_infos, perp_info)
		end
	end

	return word_infos

end

local function get_idx_of_letter(letter_list, letter_val)
	for idx, val in ipairs(letter_list) do
		if letter_val == val then
			return idx
		end
	end
end

local function commit_placed_letters(state, player_idx, placed_letters)
	for _, placed_letter_info in ipairs(placed_letters) do
		state.grid[placed_letter_info.y][placed_letter_info.x] = placed_letter_info.letter
	end

	for _, placed_letter_info in ipairs(placed_letters) do
		local player_letters = state.players[player_idx].letters
		table.remove(player_letters, get_idx_of_letter(player_letters, placed_letter_info.letter))
	end
end

local function deal_more_tiles(state, player_idx)
	local player = state.players[player_idx]
	while #player.letters < LETTERS_PER_PLAYER do
		print("dealing player a new tile")
		local letter = table.remove(state.letters)
		table.insert(player.letters, letter)
	end
end
	

function core.submit(state, player_idx, placed_letters)
	print(string.format("core.submit... placed_letters len: %d", #placed_letters))

	print("checking if letters are in a line...")
	if not letters_in_a_line(placed_letters) then
		print("letters not in a line!")
		return { rc = core.RC_LETTERS_NOT_IN_A_LINE }
	end

	print("checking if letters are continuous...")
	if not letters_continuous(state, placed_letters) then
		print("letters not continuous!")
		return { rc = core.RC_LETTERS_NOT_CONTINUOUS }
	end

	local word_infos = get_all_new_words_formed(state, placed_letters)
	print(string.format("found %d words", #word_infos))
	for i, info in ipairs(word_infos) do
		print(string.format("%2d: %3d %3d %s", i, info.start_pt.y, info.start_pt.x, info.word))

		if not words_lib.is_valid_word(LANGUAGE, info.word) then
			return { rc = core.RC_WORD_NOT_IN_DICTIONARY, word = info.word, pos=info.start_pt }
		end
		
	end

	commit_placed_letters(state, player_idx, placed_letters)

	deal_more_tiles(state, player_idx)

	print(string.format("player tile count %d", #state.players[player_idx].letters))

	return { rc = core.RC_SUCCESS, word_infos = word_infos }
end

-- words_lib.get_words_made_from_letters

return core
