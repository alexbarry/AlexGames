local draw_keyboard = {}

local alexgames = require("alexgames")

local KEYS = {
	"qwertyuiop",
	"asdfghjkl",
	"zxcvbnm",
}

local padding = 5

draw_keyboard.SPECIAL_KEY_ENTER = "Enter"
draw_keyboard.SPECIAL_KEY_BKSP  = "Backspace"

local SPECIAL_KEYS = {
	{ idx = draw_keyboard.SPECIAL_KEY_ENTER, text = "Enter" },
	{ idx = draw_keyboard.SPECIAL_KEY_BKSP,  text = "<" },
}

local function get_key_params(kb_params)
	local key_params = {
		y_start    = kb_params.y_start,
		x_start    = kb_params.x_start,
		y_end      = kb_params.y_end,
		x_end      = kb_params.x_end,
		padding    = padding,
		key_height = math.floor((kb_params.y_end - kb_params.y_start) / #KEYS) - padding,
		key_width  = math.floor((kb_params.x_end - kb_params.x_start) / #KEYS[1]) - padding,
		offsets    = { 0, 0.5, 1.5 },
	}
	key_params.text_size = math.floor(0.7*math.min(key_params.key_height, key_params.key_width))
	return key_params
end

local function get_key_pos(params, row_idx, col_idx, special_idx)

	if special_idx == draw_keyboard.SPECIAL_KEY_ENTER then
		local pos = {
			y_start = params.y_start + 2 * (params.key_height + params.padding),
			x_start = params.x_start + padding/2,
		}
		pos.y_end = pos.y_start + params.key_height
		pos.x_end = pos.x_start + 1.5 * params.key_width
		local text_padding = 1
		--pos.text_size = math.min(math.floor(((pos.x_end - pos.x_start) - 2*text_padding)/5),
		--                         math.floor( (pos.y_end - pos.y_start) - 2*text_padding))
		pos.text_size = 16
		pos.text_y = pos.y_start + params.key_height/2 + pos.text_size/2
		pos.text_x = pos.x_start + (pos.x_end - pos.x_start)/2
		return pos
	elseif special_idx == draw_keyboard.SPECIAL_KEY_BKSP then
		local pos = {
			y_start = params.y_start + 2 * (params.key_height + params.padding),
			x_start = params.x_end - 1.5 * params.key_width - 3/2*padding
		}
		pos.y_end = pos.y_start + params.key_height
		pos.x_end = pos.x_start + 1.5 * params.key_width
		pos.text_size = params.text_size
		pos.text_y = pos.y_start + params.key_height/2 + pos.text_size/2
		pos.text_x = pos.x_start + (pos.x_end - pos.x_start)/2
		return pos
	end

	local pos = {
		y_start = params.y_start + (row_idx-1) * (params.key_height + params.padding),
		x_start = params.x_start + (col_idx-1 + params.offsets[row_idx]) * (params.key_width  + params.padding),
	}
	pos.y_end = pos.y_start + params.key_height
	pos.x_end = pos.x_start + params.key_width

	pos.text_y = pos.y_start + (params.key_height/2) + params.text_size/2
	pos.text_x = pos.x_start + params.key_width/2
	return pos
end

function draw_keyboard.get_key_pressed(kb_params, y_pos, x_pos)
	local key_params = get_key_params(kb_params)
	-- TODO this isn't very efficient, but it's
	-- easier to implement in case I change this later.
	-- And there shouldn't be so many touches that
	-- looping through ~26 keys is significant
	for row_idx, row in ipairs(KEYS) do
		for col_idx=1,#row do
			local key = row:sub(col_idx,col_idx)
			local pos = get_key_pos(key_params, row_idx, col_idx)
			--print(string.format("%2d %2d %s", row_idx, col_idx, key))
			if pos.y_start <= y_pos and y_pos <= pos.y_end and
			   pos.x_start <= x_pos and x_pos <= pos.x_end then
				return key
			end
		end
	end

	for _, info in ipairs(SPECIAL_KEYS) do
		local pos = get_key_pos(key_params, nil, nil, info.idx)
		if pos.y_start <= y_pos and y_pos <= pos.y_end and
		   pos.x_start <= x_pos and x_pos <= pos.x_end then
			return info.idx
		end
	end
	return nil
end

function draw_keyboard.draw_keyboard(kb_params)
	local key_params = get_key_params(kb_params)


	for row_idx, row in ipairs(KEYS) do
		for col_idx=1,#row do
			local char = row:sub(col_idx,col_idx)
			local pos = get_key_pos(key_params, row_idx, col_idx)
			local bg_colour = kb_params.key_bg_colours[char]
			local fg_colour = kb_params.key_fg_colours[char]
			if bg_colour == nil then bg_colour = kb_params.key_bg_colour_default end
			if fg_colour == nil then fg_colour = kb_params.key_fg_colour_default end
			
			alexgames.draw_rect(bg_colour,
			                     pos.y_start, pos.x_start,
			                     pos.y_end,   pos.x_end)
			alexgames.draw_text(string.upper(char), fg_colour,
			                     pos.text_y, pos.text_x,
			                     key_params.text_size,
			                     alexgames.TEXT_ALIGN_CENTRE)
		end
	end


	for _, key_info in ipairs(SPECIAL_KEYS) do
		local pos = get_key_pos(key_params, nil, nil, key_info.idx)
			alexgames.draw_rect(kb_params.key_bg_colour_default,
			                     pos.y_start, pos.x_start,
			                     pos.y_end,   pos.x_end)
			alexgames.draw_text(key_info.text, '#888888',
			                     pos.text_y, pos.text_x,
			                     pos.text_size,
			                     alexgames.TEXT_ALIGN_CENTRE)

	end
end

return draw_keyboard
