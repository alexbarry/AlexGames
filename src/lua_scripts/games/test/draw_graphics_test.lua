local alexgames = require("alexgames")

local y = 200
local x = 100

local width = 75
local height = 75

local i = 0
local prop = 0

function update()
	alexgames.draw_clear()

	if prop % 2 == 0 then
		flip_y_vals = { false, true }
		flip_x_vals = { false, true }
		
		local flip_y_used = nil
		local flip_x_used = nil
		
		local j = 0
		
		for _, flip_x in ipairs(flip_x_vals) do
			for _, flip_y in ipairs(flip_y_vals) do
				if j ~= i % 4 then
					goto next_iter
				end
			
				alexgames.draw_graphic('hospital_ventilator', y, x,
				                        width, height,
				                        { flip_y = flip_y, flip_x = flip_x })
				flip_y_used = flip_y
				flip_x_used = flip_x
				::next_iter::
				j = j + 1
			end
		
		end
	
		local text1 = string.format("flip_y: %s", flip_y_used)
		local text2 = string.format("flip_x: %s", flip_x_used)
		alexgames.draw_text(text1, '#000000', 300, 0, 12, alexgames.TEXT_ALIGN_LEFT)
		alexgames.draw_text(text2, '#000000', 330, 0, 12, alexgames.TEXT_ALIGN_LEFT)
	
	
	else 
		local angle_degrees = i * 15
		alexgames.draw_graphic('hospital_ventilator', y, x,
		                        width, height,
		                        { angle_degrees = angle_degrees })
	
		local text1 = string.format("angle: %s", angle_degrees)
		alexgames.draw_text(text1, '#000000', 300, 0, 12, alexgames.TEXT_ALIGN_LEFT)
	
	end
	alexgames.draw_circle('#ff0000', '#ff0000', y, x, 5)

	alexgames.draw_refresh()
end

local BTN_ID_NEXT_FRAME = "btn_next_frame"
local BTN_ID_NEXT_PROP  = "btn_next_prop"

function handle_btn_clicked(btn_id)
	if btn_id == BTN_ID_NEXT_FRAME then
		i = i + 1
		update()
	elseif btn_id == BTN_ID_NEXT_PROP then
		prop = prop + 1
		update()
	else
		error(string.format("Unhandled btn id %s", btn_id))
	end
end

function start_game()
	alexgames.create_btn(BTN_ID_NEXT_FRAME, "Next Frame", 1)
	alexgames.create_btn(BTN_ID_NEXT_PROP,  "Next Property", 1)
end
