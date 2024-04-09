local draw_more = {}

local alexgames = require("alexgames")

-- Same as alexgames.draw_graphic, but the position is
-- from the top left instead of the centre.
--
-- Originally alexgames.draw_graphic(...) worked this way, but I changed it
-- when adding support for rotation of angles besides 0, 90, 180, 270.
-- So this API is provided to help convert the older games.
function draw_more.draw_graphic_ul(img_id,
                                   y, x, width, height, params)
	local y_rot_offset = height/2
	local x_rot_offset = width/2
	if params ~= nil and params.angle_degrees ~= nil and params.angle_degrees ~= 0 then
		y_rot_offset = height/2*math.cos(params.angle_degrees/180*math.pi) + width/2*math.sin(params.angle_degrees/180*math.pi)
		x_rot_offset = width/2*math.cos(params.angle_degrees/180*math.pi) - height/2*math.sin(params.angle_degrees/180*math.pi)
	end
	return alexgames.draw_graphic(img_id,
	                               math.floor(y + y_rot_offset),
	                               math.floor(x + x_rot_offset),
	                               width,
	                               height,
	                               params)
end

-- Converts between the old draw_graphic_ul (draws with y,x in upper left of graphic) points
-- to true y and x position after rotating.
-- Only works for multiples of 90 degrees. Kind of a hack.
--
-- The reason for this is that draw_graphic_ul handles rotation about the top left,
-- and draw_rect has no concept of rotation. So if you want to draw a rectangle over
-- a graphic, this function handles the conversion.
function draw_more.get_rotated_pts_ul(y, x, width, height, angle_degrees)
	if angle_degrees == nil then
		angle_degrees = 0
	end
	local y2
	local x2
	if angle_degrees == 0 then
		y2 = y
		x2 = x
	elseif angle_degrees == 90 then
		y2 = y
		x2 = x - height
	elseif angle_degrees == 180 then
		y2 = y - height
		x2 = x - width
	elseif angle_degrees == 270 then
		y2 = y - width
		x2 = x
	else
		error(string.format("get_rotated_pts_ul only supports angles multiple of 90, received %s", angle_degrees))
	end
	
	local width2
	local height2
	if angle_degrees == 90 or angle_degrees == 270 then
		width2  = height
		height2 = width
	elseif angle_degrees == 0 or angle_degrees == 180 then
		width2  = width
		height2 = height
	else
		error(string.format("get_rotated_pts_ul only supports angles multiple of 90, received %s", angle_degrees))
	end

	return {
		y = y2,
		x = x2,
		height = height2,
		width  = width2,
	}
	
end


function draw_more.draw_dashed_line(colour, thickness, duty_cycle, step, y1, x1, y2, x2)
	-- NOTE: this is likely terribly inefficient compared to one of the native HTML "draw dashed line"
	--       methods. It calls the "draw line" function separately for each segment, doing some math.
	--       The only benefit is that a new C API to draw dashed lines isn't needed.
	--       In an ideal world, this could check if an optimized C API exists, and if not, fallback to this
	--       Lua implementation.
	--
	local dy = y2 - y1
	local dx = x2 - x1

	-- TODO: this also doesn't work for vertical lines. I think there is some nifty trick
	-- like swapping dy and dx or something
	-- using trigonometry seems like a waste
	if dx == 0 then
		error("vertical dashed lines not supported yet", 2)
	end

	local line_slope = dy/dx
	local line_len = math.sqrt(dy*dy + dx*dx)

	if step == nil then
		step = 10
	end

	if duty_cycle == nil then
		duty_cycle = 0.5
	end

	local piece_y = y1
	local piece_x = x1
	for i=0,line_len,step do
		local piece_dy = dx*line_slope/line_len*step
		local piece_dx = dx/line_len*step

		local piece_y2 = math.floor(piece_y + piece_dy*duty_cycle)
		local piece_x2 = math.floor(piece_x + piece_dx*duty_cycle)
		alexgames.draw_line(colour, thickness,
		                     piece_y, piece_x,
		                     piece_y2, piece_x2)
		piece_y = math.floor(piece_y + piece_dy)
		piece_x = math.floor(piece_x + piece_dx)
	end
end

return draw_more
