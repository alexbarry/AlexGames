local draw = {}

local alex_c_api = require("alex_c_api")

-- Helper library to draw shapes from the base APIs defined in alex_c_api
local draw_more = require("libs/draw/draw_shapes")

local g_board_width
local g_board_height

local BORDER_COLOUR = '#8888ff88'
local BORDER_THICKNESS = 3

function draw.init(board_width, board_height)
	g_board_width  = board_width
	g_board_height = board_height
end

local function in_range(min_val, val, max_val)
	return min_val <= val and val <= max_val
end


function draw.draw(state)
	-- This clears anything on the screen from previous `draw_board` calls.
	alex_c_api.draw_clear()


	-- Draw a border around the screen to show where the ball will bounce
	local padding = 3
	local outline_pt1 = { y = padding, x = padding }
	local outline_pt2 = { y = g_board_height - padding, x = g_board_width - padding }
	draw_more.draw_rect_outline(BORDER_COLOUR, BORDER_THICKNESS,
	                            outline_pt1.y, outline_pt1.x,
	                            outline_pt2.y, outline_pt2.x)
	-- draw_more.draw_rect_outline(...) is a helper function to do this (draw 4 lines in a rectangle):
	--[[
	alex_c_api.draw_line(BORDER_COLOUR, BORDER_THICKNESS,
	                     0, 0,
	                     0, g_board_width)
	alex_c_api.draw_line(BORDER_COLOUR, BORDER_THICKNESS,
	                     0,              g_board_width,
	                     g_board_height, g_board_width)
	alex_c_api.draw_line(BORDER_COLOUR, BORDER_THICKNESS,
	                     g_board_height, g_board_width,
	                     g_board_height, 0)
	alex_c_api.draw_line(BORDER_COLOUR, BORDER_THICKNESS,
	                     g_board_height, 0,
	                     0             , 0)
	--]]

	local msg = string.format("time: %s, frame: %5d", alex_c_api.get_time_of_day(), state.frame_idx)
	local text_color = '#000000'
	local text_size = 18

	local padding = 5

	local y_pos = text_size + padding
	local x_pos = padding

	-- Draw text on the screen
	alex_c_api.draw_text(msg, text_color,
	                     y_pos, x_pos,
	                     text_size,
	                     alex_c_api.TEXT_ALIGN_LEFT)

	alex_c_api.draw_text('Hello, world!', '#ff0000',
	                     y_pos + padding + text_size, x_pos,
	                     text_size,
	                     alex_c_api.TEXT_ALIGN_LEFT)

	local square_size  = 40
	local squares_per_row = math.ceil(g_board_width  / square_size)
	local squares_per_col = math.ceil(g_board_height / square_size)
	--[[
	local square_y_pos = math.floor(state.ball_pos_y/square_size)*square_size
	local square_x_pos = math.floor(state.ball_pos_x/square_size)*square_size

	local square_color
	if (square_y_pos + square_x_pos * squares_per_row) % squares_per_row == 0 then
		square_color = '#ffffff88'
	else
		square_color = '#00000088'
	end

	alex_c_api.draw_rect(square_color,
	                     square_y_pos, square_x_pos,
	                     square_y_pos + square_size, square_x_pos + square_size)
	--]]
	for square_y_idx=0,squares_per_col-1 do
		for square_x_idx=0,squares_per_row-1 do
			local square_y_pos1 = square_y_idx * square_size
			local square_x_pos1 = square_x_idx * square_size
			local square_y_pos2 = (square_y_idx+1) * square_size
			local square_x_pos2 = (square_x_idx+1) * square_size

			local ball_in_square = (in_range(0, (math.floor(state.ball_pos_y/square_size + 0.5) - square_y_idx), 1) and
			                        in_range(0, (math.floor(state.ball_pos_x/square_size + 0.5) - square_x_idx), 1))
			local square_is_white = ((square_y_idx + square_x_idx * (squares_per_row+1)) % 2 == 0)

			local square_color
			if square_is_white then
				if ball_in_square then square_color = '#ffffff'
				else square_color = '#ffffff33' end
			else
				if ball_in_square then square_color = '#000000'
				else square_color = '#00000033' end
			end
			
			alex_c_api.draw_rect(square_color,
			                     square_y_pos1, square_x_pos1,
			                     square_y_pos2, square_x_pos2)
		end
	end
	                     
	local circle_color  = '#aaaacc88'
	local circle_outline = '#0000ff'
	alex_c_api.draw_circle(circle_color, circle_outline,
	                       state.ball_pos_y, state.ball_pos_x, state.ball_radius)

	-- TODO I need to implement the ability to upload custom graphics
	-- For now this API uses an ID that is hardcoded in a hashmap mapping this to
	-- a graphic file.
	alex_c_api.draw_graphic('chess_rook_black',
	                        state.ball_pos_y, state.ball_pos_x,
	                        2*state.ball_radius, 2*state.ball_radius,
	                        { angle_degrees = state.frame_idx / 60 * 90, })

	-- Draw a red line in the direction of the desired user position
	-- if they are pressing keys, clicking, or touching the screen.
	if state.user_input_vec ~= nil then
		local angle = math.atan(state.user_input_vec.y, state.user_input_vec.x)
		alex_c_api.draw_line('#ff0000', 4,
		                     state.ball_pos_y, state.ball_pos_x,
		                     state.ball_pos_y + 2*state.ball_radius*math.sin(angle), state.ball_pos_x + 2*state.ball_radius*math.cos(angle))
	end

	-- Show text indicating user input to help debug, also
	-- explain to user how they can provide input to move the ball.
	if state.mouse_down then
		alex_c_api.draw_text(string.format('Mouse pos: {y=%3.0f, x=%3.0f}', state.user_input_pos_y, state.user_input_pos_x), text_color,
		                     g_board_height - padding, padding,
		                     text_size, alex_c_api.TEXT_ALIGN_LEFT)
	elseif state.active_touch ~= nil then
		alex_c_api.draw_text(string.format('Touch pos: {y=%3.0f, x=%3.0f}', state.user_input_pos_y, state.user_input_pos_x), text_color,
		                     g_board_height - padding, padding,
		                     text_size, alex_c_api.TEXT_ALIGN_LEFT)
	else
		-- Admittedly I don't have a multi line draw_text function yet
		alex_c_api.draw_text('Press arrow keys, WASD, or mouse/touch', text_color,
		                     g_board_height - 2*padding - text_size, padding,
		                     text_size, alex_c_api.TEXT_ALIGN_LEFT)
		alex_c_api.draw_text('to move ball', text_color,
		                     g_board_height - padding, padding,
		                     text_size, alex_c_api.TEXT_ALIGN_LEFT)
	end

	-- On the web version, this does nothing.
	-- On other implementations, this is needed to cause the previous draw APIs to take effect.
	alex_c_api.draw_refresh()
end

return draw
