local alex_c_api = require("alex_c_api")
local cards = require("libs/cards/cards")
local card_draw = require("libs/cards/cards_draw")

local draw = {}

local card_height    = nil
local card_width     = nil
local card_font_size = nil

local REVEAL_AREA_COLOUR = '#8888ff33'
local REVEAL_AREA_TEXT   = 'Revealed'
local REVEAL_AREA_TEXT_COLOUR = '#0000ff88'
local REVEAL_AREA_TEXT_SIZE = 18
local text_y_size = 25

local width  = nil
local height = nil
local reveal_area = nil

local PLAYER_CURSOR_RADIUS = 5
local PLAYER_COLOURS = {
	{ fill = '#ff000088', outline = '#ff0000' },
	{ fill = '#0000ff88', outline = '#0000ff' },
	{ fill = '#00ff0088', outline = '#00ff00' },
	{ fill = '#00888888', outline = '#00ffff' },
}

function draw.init(args)
	width  = args.width
	height = args.height
	reveal_area    = args.reveal_area
	card_height    = args.card_height
	card_width     = args.card_width
	card_font_size = args.card_font_size
end

function draw.draw(state, player)
	alex_c_api.draw_clear()

	if state == nil then
		return
	end

	alex_c_api.draw_rect(REVEAL_AREA_COLOUR,
		0, 0, reveal_area, width)
	alex_c_api.draw_text(REVEAL_AREA_TEXT, REVEAL_AREA_TEXT_COLOUR,
		text_y_size, 0, REVEAL_AREA_TEXT_SIZE, 1, 0)

	alex_c_api.draw_rect(REVEAL_AREA_COLOUR,
		height - reveal_area, 0, height, width)
	alex_c_api.draw_text(REVEAL_AREA_TEXT, REVEAL_AREA_TEXT_COLOUR,
		height - reveal_area + text_y_size, 0, REVEAL_AREA_TEXT_SIZE, 1, 0)
	for _, card_info in ipairs(state.cards) do
		local card = nil
		if card_info.recvd or card_info.revealed_all or card_info.revealed_to_player == player then
			card = card_info.card
		else
			card = cards.UNREVEALED_CARD
		end
		card_draw.draw_card(card,
			math.floor(card_info.y - card_height/2),
			math.floor(card_info.x - card_width/2),
			card_width, card_height, card_font_size, false, 0)
	end

	for i=1,#state.player_states do
		if state.player_states[i].y == nil or
		   state.player_states[i].x == nil then
			goto next_player_cursor
		end
		alex_c_api.draw_circle(PLAYER_COLOURS[i].fill, PLAYER_COLOURS[i].outline,
			state.player_states[i].y,
			state.player_states[i].x,
			PLAYER_CURSOR_RADIUS)
		::next_player_cursor::
	end

	alex_c_api.draw_refresh()
end

return draw
