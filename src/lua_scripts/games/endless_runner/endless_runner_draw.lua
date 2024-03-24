local draw = {}

local core = require("games/endless_runner/endless_runner_core")

local buttons = require("libs/ui/buttons")

local alex_c_api = require("alex_c_api")

local PLAYER_FILL_COLOUR = '#ff0000'
local PLAYER_OUTLINE_COLOUR = '#000000'
local PLAYER_RADIUS = 20


local WALL_COLOUR = '#0000ff'
local WALL_THICKNESS = 10

local BTN_BACKGROUND_COLOUR = '#888'

local board_width  = 480
local board_height = 480

local player_pos_y = board_height/2
local player_pos_x = board_height/4

local SCORE_TEXT_SIZE = 24
local padding = 5

local buttons_state = buttons.new_state()
local BTN_ID_NEW_GAME = "btn_new_game"

buttons.new_button(buttons_state, {
	id   = BTN_ID_NEW_GAME,
	text = "New Game",
	-- TODO add defaults for all of these
	bg_colour = "#888",
	fg_colour = "#000",
	outline_colour = "#000",
	outline_width = 3,
	text_size = 24,

	y_start = padding,
	y_end   = padding + 75,

	x_start = board_width - padding - 200,
	x_end   = board_width - padding,
})


local WALL_TO_PIXEL_SCALE = 480/10

local function game_pos_to_screen_pos(state, pt)
	local screen_pt = {}
	screen_pt.y = board_height - (pt.y * WALL_TO_PIXEL_SCALE)
	screen_pt.x = (pt.x - state.player_x) * WALL_TO_PIXEL_SCALE + player_pos_x

	return screen_pt
end

function draw.draw_board(state, dt_ms)
	alex_c_api.draw_clear()

	for _, wall in ipairs(state.walls) do
		local pt1 = game_pos_to_screen_pos(state, { y = wall.y_outer, x = wall.x - core.WALL_SIZE_X/2 })
		local pt2 = game_pos_to_screen_pos(state, { y = wall.y_inner, x = wall.x + core.WALL_SIZE_X/2 })
		--alex_c_api.draw_line(WALL_COLOUR, WALL_THICKNESS,
		--                     pt1.y, pt1.x,
		 --                    pt2.y, pt2.x)
		alex_c_api.draw_rect(WALL_COLOUR,
		                     pt1.y, pt1.x,
		                     pt2.y, pt2.x)
	end

	local player_ul = { y = state.player_y + core.PLAYER_SIZE_Y/2, x = state.player_x - core.PLAYER_SIZE_X/2 }
	local player_lr = { y = state.player_y - core.PLAYER_SIZE_Y/2, x = state.player_x + core.PLAYER_SIZE_X/2 }
	player_ul = game_pos_to_screen_pos(state, player_ul)
	player_lr = game_pos_to_screen_pos(state, player_lr)
	--alex_c_api.draw_circle(PLAYER_FILL_COLOUR, PLAYER_OUTLINE_COLOUR,
	--                       player_pos.y, player_pos.x, PLAYER_RADIUS)
	alex_c_api.draw_rect(PLAYER_FILL_COLOUR,
	                     player_ul.y, player_ul.x,
	                     player_lr.y, player_lr.x)

	local score_text = string.format("%d", core.score(state))
	alex_c_api.draw_text(score_text, '#880000',
	                     SCORE_TEXT_SIZE + padding,
	                     board_width/2,
	                     SCORE_TEXT_SIZE, alex_c_api.TEXT_ALIGN_CENTRE)

	buttons.set_visible(buttons_state, BTN_ID_NEW_GAME, state.game_over)

	buttons.draw(buttons_state)

	alex_c_api.draw_refresh()
end


function draw.in_new_game_btn(state, pos_y, pos_x)
	if buttons.on_user_click(buttons_state, pos_y, pos_x) then
		return true
	end

	return false
end

return draw
