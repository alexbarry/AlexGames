local dice_draw = {}

local alexgames = require("alexgames")
local draw_more  = require("libs/draw/draw_more")

local DICE_IMG_MAP = {
	"dice1",
	"dice2",
	"dice3",
	"dice4",
	"dice5",
	"dice6",
}

function dice_draw.draw_one_die(die_val, y_pos, x_pos, y_size, x_size, idx, args)
	if args ~= nil and args.background_colour ~= nil then
		alexgames.draw_rect(args.background_colour,
		                     y_pos, x_pos,
		                     y_pos + y_size, x_pos + x_size)
	end
	local img_id = DICE_IMG_MAP[die_val]
	local graphic_params = nil
	if args ~= nil then
		graphic_params = {
			brightness_percent = args.brightness_percent,
			invert             = args.invert
		}
	end
	draw_more.draw_graphic_ul(img_id, y_pos, x_pos, x_size, y_size, graphic_params)
	if args.used_dice ~= nil and args.used_dice[idx] then
		if args.dice_used_overlay_colour == nil then
			error("args.dice_used_overlay_colour is nil, but args.used_dice is specified", 2)
		end
		alexgames.draw_rect(args.dice_used_overlay_colour, y_pos, x_pos, y_pos + y_size, x_pos + x_size)
	end
end

function dice_draw.draw_dice(dice_vals, y_pos, x_pos, y_size, x_size, args)
	for dice_idx, dice_val in ipairs(dice_vals) do
		x_pos2 = x_pos + (dice_idx-1)*x_size
		if args ~= nil and args.padding ~= nil then
			x_pos2 = x_pos2 + (dice_idx-1)*args.padding
		end
		dice_draw.draw_one_die(dice_val, y_pos, x_pos2, y_size, x_size, dice_idx, args)
	end
end

return dice_draw

