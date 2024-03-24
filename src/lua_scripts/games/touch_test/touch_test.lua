
local alex_c_api = require("alex_c_api")

local touch_count = 0
local touches = {}

local colours = {
	'#ff0000',
	'#0000ff',
	'#00ff00',
	'#00ffff',
	'#ffff00',
	'#ff00ff',
	'#000000',
}

local board_height = 480
local board_width  = 480

local touch_line_width = 2
local circle_radius = 20

local text_size = 12
local padding = 5

local last_touch_str = nil

function draw_board()
	alex_c_api.draw_clear()

	if touch_count == 0 then
		local text_size = 18
		local line1 = 'Touch (and optionally drag) the screen'
		local line2 = 'to see info about touches'
		alex_c_api.draw_text(line1,
		                     text_colour,
		                     board_height/2 - text_size - padding/2, board_width/2,
		                     text_size, 0)
		alex_c_api.draw_text(line2,
		                     text_colour,
		                     board_height/2 + text_size + padding/2, board_width/2,
		                     text_size, 0)
	end
	local touch_idx = 1
	for i, touch in pairs(touches) do

		local text = string.format('%2d: id=%d [%3d] ', touch_idx, i, #touch)
		for _, pos in ipairs(touch) do
			text = text .. string.format('{y=%d,x=%d}, ', pos.y, pos.x)
		end
		alex_c_api.draw_text(text, '#000000', touch_idx*(text_size+padding), padding, text_size, 1)
		last_touch_str = text

		local colour = colours[ (i-1) % #colours + 1]
		print('draw: ', touch[1].y, touch[1].x)
		alex_c_api.draw_circle(colour, colour, touch[1].y, touch[1].x, circle_radius)
		for i=2,#touch do
			local pt1 = touch[i-1]
			local pt2 = touch[i]
			alex_c_api.draw_line(colour, touch_line_width, pt1.y, pt1.x, pt2.y, pt2.x)
		end
		touch_idx = touch_idx + 1
	end

	if last_touch_str ~= nil then
		alex_c_api.draw_text('last: ' .. last_touch_str, '#000000', board_height - text_size - padding, padding, text_size, 1)
	end
end

function handle_touch_evt(evt_id, changed_touches)
	for _, touch in ipairs(changed_touches) do
		if evt_id == 'touchstart' then
			touch_count = touch_count + 1
			touches[touch.id] = {}
		end
		if evt_id == 'touchstart' or
		   evt_id == 'touchmove' then
			print(evt_id, touch.y, touch.x)
			table.insert(touches[touch.id], { y = math.floor(touch.y), x = math.floor(touch.x) })
		end

		if evt_id == 'touchend' or
		   evt_id == 'touchcancel' then
			touch_count = touch_count - 1
			touches[touch.id] = nil
		end
	end
	draw_board()
end

alex_c_api.enable_evt('touch')
