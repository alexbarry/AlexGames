
local cards      = require("libs/cards/cards") 
local cards_draw = require("libs/cards/cards_draw")
local draw_more  = require("libs/draw/draw_more")
local alexgames = require("alexgames")

local padding = 50
local card_height = 100
local card_width  =  70
--local card_height = 60
--local card_width  =  40
local card_font_size = 24

local BTN_ID_INC_ANGLE = "inc_angle"
local BTN_ID_DEC_ANGLE = "dec_angle"
local BTN_ID_TOGGLE_FACE_DN_UP = "toggle_face_dn_up"

local pos_y = 240
local pos_x = 240

local deck = cards.new_deck()
cards.shuffle(deck)

local angle_offset = 0
local cards_face_down = true

function draw_board()
	alexgames.set_status_msg(string.format("Drawing cards with angle offset = %d", angle_offset))
	alexgames.draw_clear()

	if not cards_face_down then
		cards_draw.draw_card(deck[1], pos_y + padding, pos_x,
			card_width, card_height,
			card_font_size, false, 0 + angle_offset)
		
		cards_draw.draw_card(deck[2], pos_y, pos_x - padding, 
			card_width, card_height,
			card_font_size, false, 90 + angle_offset)
		
		cards_draw.draw_card(deck[3], pos_y - padding, pos_x,
			card_width, card_height,
			card_font_size, false, 180 + angle_offset)
		
		cards_draw.draw_card(deck[4],  pos_y, pos_x + padding,
			card_width, card_height,
			card_font_size, false, 270 + angle_offset)
			alexgames.draw_refresh()
	else

		draw_more.draw_graphic_ul("card_facedown", 0, 0, card_width, card_height, { angle_degrees =   0 + angle_offset })
	
		draw_more.draw_graphic_ul("card_facedown", pos_y + padding, pos_x + padding, card_width, card_height, { angle_degrees =   0 + angle_offset })
		draw_more.draw_graphic_ul("card_facedown", pos_y + padding, pos_x - padding, card_width, card_height, { angle_degrees =  90 + angle_offset })
		draw_more.draw_graphic_ul("card_facedown", pos_y - padding, pos_x - padding, card_width, card_height, { angle_degrees = 180 + angle_offset })
		draw_more.draw_graphic_ul("card_facedown", pos_y - padding, pos_x + padding, card_width, card_height, { angle_degrees = 270 + angle_offset })
	
		alexgames.draw_circle('#ff0000', '#ff000055', pos_y + padding, pos_x + padding, 5)
		alexgames.draw_text('1', '#000000',           pos_y + padding, pos_x + padding, 12, 0)
		alexgames.draw_circle('#ff0000', '#ff000055', pos_y + padding, pos_x - padding, 5)
		alexgames.draw_text('2', '#000000',           pos_y + padding, pos_x - padding, 12, 0)
		alexgames.draw_circle('#ff0000', '#ff000055', pos_y - padding, pos_x - padding, 5)
		alexgames.draw_text('3', '#000000',           pos_y - padding, pos_x - padding, 12, 0)
		alexgames.draw_circle('#ff0000', '#ff000055', pos_y - padding, pos_x + padding, 5)
		alexgames.draw_text('4', '#000000',           pos_y - padding, pos_x + padding, 12, 0)
	end
end

function handle_btn_clicked(btn_id)
	if btn_id == BTN_ID_INC_ANGLE then
		angle_offset = angle_offset + 15
	elseif btn_id == BTN_ID_DEC_ANGLE then
		angle_offset = angle_offset - 15
	elseif btn_id == BTN_ID_TOGGLE_FACE_DN_UP then
		cards_face_down = not cards_face_down
	end
	draw_board()
end

alexgames.create_btn(BTN_ID_INC_ANGLE, "Increment Angle", 1)
alexgames.create_btn(BTN_ID_DEC_ANGLE, "Decrement Angle", 1)
alexgames.create_btn(BTN_ID_TOGGLE_FACE_DN_UP, "Toggle face dn/up", 1)
