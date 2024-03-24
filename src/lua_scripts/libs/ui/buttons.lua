local buttons = {}

local alex_c_api = require("alex_c_api")
local draw_shapes = require("libs/draw/draw_shapes")

buttons.BTN_SHAPE_RECT     = "rect" -- sending nil instead of this works too
buttons.BTN_SHAPE_TRIANGLE = "triangle"

function buttons.new_state()
	local state = {
		buttons = {},
		btn_id_map = {},
	}
	return state
end

function buttons.new_button(state, btn_params)
	if state == nil then error("state is nil", 2) end
	if btn_params.id == nil then
		error("btn_params.id is nil", 2)
	end
	if btn_params.text == nil then
		error("btn_params.text is nil", 2)
	end
	local enabled = true
	if btn_params.enabled ~= nil then
		enabled = btn_params.enabled
	end
	local btn_info = {
		id             = btn_params.id,
		text           = btn_params.text,
		bg_colour      = btn_params.bg_colour,
		fg_colour      = btn_params.fg_colour,
		outline_colour = btn_params.outline_colour,
		outline_width  = btn_params.outline_width,
		btn_shape      = btn_params.btn_shape,
		shape_param    = btn_params.shape_param,
		text_size      = btn_params.text_size,
		padding        = btn_params.padding,
		y_start        = btn_params.y_start,
		x_start        = btn_params.x_start,
		--y_end     = btn_params.y_start + btn_params.y_size,
		--x_end     = btn_params.x_start + btn_params.x_size,
		y_end          = btn_params.y_end,
		x_end          = btn_params.x_end,
		enabled        = enabled,
		visible        = true,
		callback       = btn_params.callback,
	}
	table.insert(state.buttons, btn_info)
	state.btn_id_map[btn_params.id] = btn_info
end

function buttons.on_user_click(state, y_pos, x_pos)
	for _, btn_info in ipairs(state.buttons) do
		if btn_info.enabled and btn_info.visible and
		   btn_info.y_start <= y_pos and y_pos <= btn_info.y_end and
		   btn_info.x_start <= x_pos and x_pos <= btn_info.x_end then
			--print(string.format("Pressed button \"%s\"", btn_info.text))
			if btn_info.callback then
				btn_info.callback(btn_info.id)
			end
			return btn_info.id
		end
	end
end

function buttons.set_enabled(state, btn_id, is_enabled)
	state.btn_id_map[btn_id].enabled = is_enabled
end

function buttons.set_visible(state, btn_id, is_visible)
	state.btn_id_map[btn_id].visible = is_visible
end

function buttons.set_text(state, btn_id, text)
	state.btn_id_map[btn_id].text = text
end

function buttons.draw(state)
	for _, btn_info in ipairs(state.buttons) do
		if not btn_info.visible then
			goto next_button
		end
		local btn_width = btn_info.x_end - btn_info.x_start
		local text_align = 0

		local outline_colour = btn_info.outline_colour
		local bg_colour      = btn_info.bg_colour
		local fg_colour      = btn_info.fg_colour

		if not btn_info.enabled then
			outline_colour = '#cccccc88'
			bg_colour      = '#eeeeee88'
			fg_colour      = '#aaaaaa88'
		end

		if btn_info.btn_shape == buttons.BTN_SHAPE_TRIANGLE then
			draw_shapes.draw_triangle_lr(outline_colour, btn_info.outline_width, bg_colour,
			                             btn_info.shape_param,
			                             btn_info.y_start, btn_info.x_start,
			                             btn_info.y_end,   btn_info.x_end)
			if btn_info.shape_param then
				text_align = 1
			else
				text_align = -1
			end
		else
			alex_c_api.draw_rect(bg_colour,
			                     btn_info.y_start, btn_info.x_start,
			                     btn_info.y_end,   btn_info.x_end)
			draw_shapes.draw_rect_outline(outline_colour, btn_info.outline_width,
			                              btn_info.y_start, btn_info.x_start,
			                              btn_info.y_end,   btn_info.x_end)
		end

		local text_y_start = math.floor((btn_info.y_start + btn_info.y_end + btn_info.text_size)/2)
		alex_c_api.draw_text(btn_info.text, fg_colour,
		                     text_y_start, math.floor(btn_info.x_start + btn_width/2),
		                     btn_info.text_size, text_align)
		::next_button::
	end
end

return buttons
