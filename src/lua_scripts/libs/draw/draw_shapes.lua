
local draw_shapes = {}
local alexgames = require("alexgames")

function draw_shapes.draw_rect_outline(colour, line_width, y1, x1, y2, x2)
	alexgames.draw_line(colour, line_width, y1, x1, y1, x2)
	alexgames.draw_line(colour, line_width, y1, x1, y2, x1)
	alexgames.draw_line(colour, line_width, y2, x2, y1, x2)
	alexgames.draw_line(colour, line_width, y2, x2, y2, x1)
end

function draw_shapes.draw_triangle_lr(line_colour, line_width, bg_colour, pointing_left, y1, x1, y2, x2)

	local pt1, pt2, pt3
	if pointing_left then
		pt1 = { y = math.floor((y2 + y1)/2), x = x1 }
		pt2 = { y = y1, x = x2 }
		pt3 = { y = y2, x = x2 }
	else
		pt1 = { y = math.floor((y2 + y1)/2), x = x2 }
		pt2 = { y = y1, x = x1 }
		pt3 = { y = y2, x = x1 }
	end

	if bg_colour ~= nil then
		-- TODO this file was written before I added a "fill_triangle" API.
		-- obviously it should use that instead
		alexgames.draw_rect(bg_colour, y1, x1, y2, x2)
	end

	if line_colour ~= nil then
		alexgames.draw_line(line_colour, line_width, pt1.y, pt1.x, pt2.y, pt2.x)
		alexgames.draw_line(line_colour, line_width, pt2.y, pt2.x, pt3.y, pt3.x)
		alexgames.draw_line(line_colour, line_width, pt3.y, pt3.x, pt1.y, pt1.x)
	end
end

function draw_shapes.draw_triangle_outline(line_colour, line_width,
                                           y1, x1,
                                           y2, x2,
                                           y3, x3)
	alexgames.draw_line(line_colour, line_width, y1, x1, y2, x2)
	alexgames.draw_line(line_colour, line_width, y2, x2, y3, x3)
	alexgames.draw_line(line_colour, line_width, y3, x3, y1, x1)
end

return draw_shapes
