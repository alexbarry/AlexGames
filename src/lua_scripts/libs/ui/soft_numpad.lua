local soft_numpad = {}

local buttons = require("libs/ui/buttons")

function soft_numpad.btn_id(num)
	return string.format("numpad_%d", num)
end

local BUTTON_ID_CLEAR = "numpad_clear"
local BUTTON_ID_BKSP  = "numpad_bksp"

local BUTTON_ID_TO_NUM = {
}
for i=0,9 do
	BUTTON_ID_TO_NUM[soft_numpad.btn_id(i)] = i
end

local function button_pressed(state, btn_id)
	if btn_id == BUTTON_ID_CLEAR then
		state.input_presses = {}
	elseif btn_id == BUTTON_ID_BKSP then
		table.remove(state.input_presses)
	elseif BUTTON_ID_TO_NUM[btn_id] then
		local num = BUTTON_ID_TO_NUM[btn_id]
		table.insert(state.input_presses, num)
	else
		return
	end

	local output_str = ''
	for i, val in ipairs(state.input_presses) do
		if i ~= 1 then output_str = output_str .. ', ' end
		output_str = output_str .. val
	end
	print("input_presses is now: " .. output_str)
end

function soft_numpad.init(numpad_params)
	local state = {
		buttons       = nil,
		input_presses = {},
	}
	state.buttons = buttons.new_state()

	-- [clr] [bksp]
	--    7 8 9
	--    4 5 6
	--    1 2 3
	--      0  

	local num_buttons_y = 5
	local num_buttons_x = 3

	local padding = 5
	if numpad_params.padding ~= nil then
		padding = numpad_params.padding
	end

	local numpad_width = numpad_params.x_end - numpad_params.x_start

	local button_size_y = math.floor((numpad_params.y_end - numpad_params.y_start)/num_buttons_y)
	local button_size_x = math.floor(numpad_width/num_buttons_x)
	local meta_button_size_x = math.floor(numpad_width/2)

	local meta_buttons = {
		{
			id   = BUTTON_ID_CLEAR,
			text = "clear",
		},

		{
			id   = BUTTON_ID_BKSP,
			text = "bksp",
		},
	}
	for meta_btn_idx, btn_info in ipairs(meta_buttons) do
		local x_start = numpad_params.x_start + (meta_btn_idx-1) * meta_button_size_x + padding
		buttons.new_button(state.buttons, {
			id   = btn_info.id,
			text = btn_info.text,
			bg_colour = numpad_params.btn_bg_colour,
			fg_colour = numpad_params.btn_fg_colour,
			text_size = button_size_y - 4*padding,
			outline_colour = numpad_params.btn_outline_colour,
			outline_width  = numpad_params.btn_outline_width,
			padding   = padding,
			y_start = numpad_params.y_start + padding,
			x_start = x_start,
			y_end   = numpad_params.y_start + button_size_y - padding,
			x_end   = x_start + meta_button_size_x - padding,
			callback = function (btn_id) button_pressed(state, btn_id) end,
		})
	end


	local nums = {
		[7] = { y = 1, x = 1 },
		[8] = { y = 1, x = 2 },
		[9] = { y = 1, x = 3 },

		[4] = { y = 2, x = 1 },
		[5] = { y = 2, x = 2 },
		[6] = { y = 2, x = 3 },

		[1] = { y = 3, x = 1 },
		[2] = { y = 3, x = 2 },
		[3] = { y = 3, x = 3 },

		[0] = { y = 4, x = 2 },
	}

	for num, pos in pairs(nums) do
		local y_start = numpad_params.y_start + (pos.y-1+1)*button_size_y + padding
		local x_start = numpad_params.x_start + (pos.x-1)*button_size_x + padding
		local btn_params = {
			id        = soft_numpad.btn_id(num),
			text      = string.format("%d", num),
			bg_colour = numpad_params.btn_bg_colour,
			fg_colour = numpad_params.btn_fg_colour,
			text_size = math.floor(button_size_y/2),
			padding   = padding,
			y_start   = y_start,
			x_start   = x_start,
			y_end     = y_start + button_size_y - padding,
			x_end     = x_start + button_size_x - padding,
			callback  = function (btn_id) button_pressed(state, btn_id) end,
		}
		buttons.new_button(state.buttons, btn_params)
	end

	return state
end

function soft_numpad.draw(state)
	buttons.draw(state.buttons)
end

function soft_numpad.on_user_click(state, y_pos, x_pos)
	buttons.on_user_click(state.buttons, y_pos, x_pos)
end

function soft_numpad.get_val(state)
	local val_str = ''
	for _, num in ipairs(state.input_presses) do
		val_str = val_str .. num
	end
	return val_str
end

function soft_numpad.set_val(state, val)
	local val_str
	if val ~= 0 then
		val_str = tostring(val)
	else
		val_str = ''
	end
	state.input_presses = {}
	for i=1,#val_str do
		table.insert(state.input_presses, val_str:sub(i,i))
	end
end

return soft_numpad
