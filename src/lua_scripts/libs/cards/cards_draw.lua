local cards = require("libs/cards/cards")
local draw_more = require("libs/draw/draw_more")
local draw_shapes = require("libs/draw/draw_shapes")
local alex_c_api = require("alex_c_api")

-- TODO make definitions of this in alex_c_api
local ALIGN_CENTRE = 0
local ALIGN_LEFT = 1

local DARK_OVERLAY_COLOUR_CARD_FACE = "#000000aa"
local DARK_OVERLAY_COLOUR_CARD_BACK = "#000000aa"

local font_size_small = 16
-- local font_size_small = 12

local cards_draw = {}

function cards_draw.draw_facedown_card(y, x, width, height, higlight, angle, brightness_percent)
	brightness_percent = nil -- overriding this because I am drawing the DARK_OVERLAY over the card
	draw_more.draw_graphic_ul("card_facedown", y, x, width, height, { angle_degrees = angle, brightness_percent = brightness_percent })

	if alex_c_api.get_user_colour_pref() == "dark" then
		local pts = draw_more.get_rotated_pts_ul(y, x, width, height, angle)
		alex_c_api.draw_rect(DARK_OVERLAY_COLOUR_CARD_BACK,
		                     pts.y, pts.x,
		                     pts.y + pts.height, pts.x + pts.width)
	end

	if higlight then
		local padding = math.floor(math.max(height*0.05, width*0.05))
		draw_more.draw_graphic_ul("card_highlight",
		                        y - padding, x - padding,
		                        width + 2*padding, height + 2*padding,
		                        { angle_degrees = angle })
	end

end

function cards_draw.draw_card(card, y, x, width, height, font_size, highlight, angle)
	if card == nil then
		error("card is nil");
	end


	local suits_to_graphic = {
		[cards.DIAMONDS] = "card_diamonds",
		[cards.HEARTS]   = "card_hearts",
		[cards.SPADES]   = "card_spades",
		[cards.CLUBS]    = "card_clubs",
	}

	local blank_card_colour = '#ffffff'
	local suit_colour_red   = "#ff0000"
	local suit_colour_black = "#000000"
	local card_outline           = '#000000'
	local card_outline_thickness = 2
	local brightness_percent_suit_icon = nil
	local brightness_percent_facedown_card = nil

	-- This looks fine on every browser except safari, which
	-- doesn't support it.
	-- So I will comment this out for now and just draw a transparent grey
	-- rectangle over all the cards
	-- Checking alex_c_api.is_feature_supported() here would be nice,
	-- but I wasn't sure how to check if these features are supported
	-- (or even if the user is using safari or not)
	if false and alex_c_api.get_user_colour_pref() == "dark" then
		blank_card_colour = '#444444'
		suit_colour_red   = "#AA0000"
		suit_colour_black = "#000000"
		card_outline      = '#000000'
		brightness_percent_suit_icon = 50
		brightness_percent_facedown_card = 35
	end

	if card == cards.UNREVEALED_CARD then
		cards_draw.draw_facedown_card(y, x, width, height, highlight, angle, brightness_percent_facedown_card)
		return
	end
	
	
	local suits_to_text_colour = {
		[cards.DIAMONDS] = suit_colour_red,
		[cards.HEARTS]   = suit_colour_red,
		[cards.SPADES]   = suit_colour_black,
		[cards.CLUBS]    = suit_colour_black,
	}

	local small_padding = math.floor(width*0.1)

	local suit_icon_big_width  = math.floor(width*0.45)
	local suit_icon_big_height = math.floor(height*0.45)

	local suit_icon_big_y
	local suit_icon_big_x
	local text_icon_big_y
	local text_icon_big_x

	local suit_icon_little_y
	local suit_icon_little_x
	local text_icon_little_y
	local text_icon_little_x

	local draw_big_suit_icon = false

	if angle ~= nil and angle ~= 0 and angle ~= 90 and angle ~= 180 and angle ~= 270 then
		error(string.format("draw_card for angle %s not supported", angle), 2)
	end

	if angle == 0 or angle == nil then
		suit_icon_big_y = y + width*0.1
		suit_icon_big_x = x + math.floor(width*(1-0.45)/2)
		text_icon_big_y = y + 0.9*height
		text_icon_big_x = x + 0.5*width

		suit_icon_little_y = y + small_padding
		suit_icon_little_x = x + math.floor(width*0.5)
		text_icon_little_y = y + math.floor(width*0.35)
		text_icon_little_x = x + math.floor(width*0.1)
	elseif angle == 90 then
		suit_icon_big_y = y + math.floor(width*(1-0.45)/2)
		suit_icon_big_x = x - height*0.1
		text_icon_big_y = y + 0.7*width
		text_icon_big_x = x - 0.8*height

		suit_icon_little_y = y + math.floor(width*0.5)
		suit_icon_little_x = x - small_padding
		text_icon_little_y = y + math.floor(width*0.35)
		text_icon_little_x = x - math.floor(width*0.35)
	elseif angle == 180 then
		suit_icon_big_y = y - width*0.1
		suit_icon_big_x = x - math.floor(width*(1 - 0.45)/2)
		text_icon_big_y = y - 0.6*height
		text_icon_big_x = x - 0.5*width

		suit_icon_little_y = y - small_padding
		suit_icon_little_x = x - math.floor(width*0.5)
		text_icon_little_y = y - math.floor(width*0.1)
		text_icon_little_x = x - math.floor(width*0.35)
	elseif angle == 270 then
		suit_icon_big_y = y - math.floor(width*(1-0.45)/2)
		suit_icon_big_x = x + height*0.1
		text_icon_big_y = y - 0.3*width
		text_icon_big_x = x + 0.8*height

		suit_icon_little_y = y - math.floor(width*0.5)
		suit_icon_little_x = x + small_padding
		text_icon_little_y = y - math.floor(width*0.1)
		text_icon_little_x = x + math.floor(width*0.1)
	end

	text_icon_big_y = math.floor(text_icon_big_y)
	text_icon_big_x = math.floor(text_icon_big_x)
	suit_icon_big_y = math.floor(suit_icon_big_y)
	suit_icon_big_x = math.floor(suit_icon_big_x)

	
	if angle ~= nil and angle ~= 0 then
		draw_more.draw_graphic_ul("card_blank", y, x, width, height, { angle_degrees = angle });
	else
		alex_c_api.draw_rect(blank_card_colour, y, x, y + height, x + width)
		draw_shapes.draw_rect_outline(card_outline, card_outline_thickness, y, x, y + height, x + width)
	end

	-- TODO clean this up, make sure it looks good for small cards (card sim, crib)
	-- maybe have the option to display either type of card
	-- maybe now is the time to refactor this to take in a table of size params,
	-- rather than a ton of integer arguments
	if not draw_big_suit_icon then
		-- TODO adjust the position for rotation here
		draw_more.draw_graphic_ul(suits_to_graphic[card.suit],
		                        suit_icon_little_y, suit_icon_little_x,
		                        math.floor(width/2) - small_padding,
		                        math.floor(1.2*width/2) - small_padding,
		                        { angle_degrees = angle , brightness_percent = brightness_percent_suit_icon})
		alex_c_api.draw_text(cards.val_to_string(card.val), suits_to_text_colour[card.suit],
		                     text_icon_little_y, text_icon_little_x,
		                     font_size_small, ALIGN_LEFT, angle)
	else
		draw_more.draw_graphic_ul(suits_to_graphic[card.suit],
		                        suit_icon_big_y, suit_icon_big_x,
		                        suit_icon_big_width, suit_icon_big_height,
		                        { angle_degrees = angle, brightness_percent = brightness_percent_suit_icon})
	end
	alex_c_api.draw_text(cards.val_to_string(card.val), suits_to_text_colour[card.suit],
	                     text_icon_big_y, text_icon_big_x, font_size, ALIGN_CENTRE, angle)

	if alex_c_api.get_user_colour_pref() == "dark" then
		alex_c_api.draw_rect(DARK_OVERLAY_COLOUR_CARD_FACE,
		                     y, x,
		                     y + height, x + width)
	end
	if highlight then
		local padding = math.floor(math.max(height*0.05, width*0.05))
		draw_more.draw_graphic_ul("card_highlight",
		                        y - padding, x - padding,
		                        width + 2*padding, height + 2*padding,
		                        { angle_degrees = angle })
	end
end

function cards_draw.draw_card_array(card_array, y_centre, x_centre, width, height, font_size, highlight, padding, offset_array)
	if #card_array > 0 and offset_ary ~= nil and #offset_array ~= #card_array then
		error(string.format("offset_ary len %d, card_array len %d", #offset_ary, #card_array))
	end

	for card_idx=1,#card_array do
		local y = math.floor(y_centre - height/2)
		if offset_array ~= nil then
			y = y + offset_array[card_idx]
		end
		local x = (x_centre - width/2) + math.floor(((card_idx-0.5 - #card_array/2))*(width + padding))
		cards_draw.draw_card(card_array[card_idx], y, x, width, height, font_size, highlight ~= nil and highlight[card_idx], 0)
	end
end

function cards_draw.draw_card_array_facedown(count, y_centre, x_centre, width, height, highlight, padding, offset_array)
	for card_idx=1,count do
		local y = math.floor(y_centre - height/2)
		if offset_array ~= nil then
			y = y + offset_array[card_idx]
		end
		local x = (x_centre - width/2) + math.floor(((card_idx-0.5 - count/2))*(width + padding))
		cards_draw.draw_facedown_card(y, x, width, height, highlight, 0)
	end
end

function cards_draw.card_array_coords_to_idx(count, y_centre, x_centre,
                                             width, height, padding,
                                             offset_array,
                                             coord_y, coord_x)
	local x_start = (x_centre - width/2) + math.floor(((0      -0.5 - count/2))*(width + padding))
	local x_end   = (x_centre - width/2) + math.floor(((count+1-0.5 - count/2))*(width + padding))
	if x_start <= coord_x and coord_x <= x_end then
		local idx = math.floor((coord_x - x_start) / (width + padding))
		if not(1 <= idx and idx <= count) then
			return nil
		end
		local y_start = math.floor(y_centre - height/2)
		local y_end   = math.floor(y_centre + height/2)
		if offset_ary ~= nil then
			y_start = y_start + offset_array[idx]
			y_end   = y_end   + offset_array[idx]
		end
		if y_start <= coord_y and coord_y <= y_end then
			local pos_within_card = (coord_x - x_start) % (width + padding)
			if pos_within_card <= width then
				return idx
			end
		end
	end

	return nil
end

return cards_draw
