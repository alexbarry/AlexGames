local draw = {}
local core = require("games/spider_swing/spider_swing_core")

local draw_celebration_anim = require("libs/draw/draw_celebration_anim")

local alexgames = require("alexgames")

local PLAYER_COLOURS = {
	[1] = { fill = '#cc8888', outline = '#ff0000', },
}
local PLAYER_RADIUS = 20
local PLAYER_WIDTH = 70
local PLAYER_HEIGHT = 50
local WEB_OFFSET = 10

local SWING_SPOT_RADIUS = 5
local SWING_SPOT_COLOUR = { fill = '#00ffff', outline = '#0000ff', }

local ROPE_THICKNESS = 4

local anim_state = draw_celebration_anim.new_state({
	on_finish = function ()
	end,
})


local function get_camera_pos(game_state, player_idx)
	--local camera = { y = 240, x = 240 }
	--local camera = { y = 0, x = 0 }
	local player = game_state.players[player_idx]
	local camera = {
		--y = player.y - 480/2,
		y = 0,
		x = math.max(player.x - 480/3, -480/3),
	}
	return camera
end


-- translate mouse position to game position
function draw.get_mouse_pos_in_game(game_state, player_idx, pos_y, pos_x)
	local player = game_state.players[player_idx]
	local camera = get_camera_pos(game_state, player_idx)
	local pos = {
		y = camera.y + pos_y,
	    x = camera.x + pos_x,
	}
	return pos
end

local function draw_finish_line(screen_x_pos, bg_height)

	local checker_count_y = 20
	local checker_count_x = 3
	local checker_size = bg_height / checker_count_y

	local FINISH_LINE_OUTLINE_COLOUR = '#888888'

	alexgames.draw_line(FINISH_LINE_OUTLINE_COLOUR, 1,
	                     0,   screen_x_pos,
	                     bg_height, screen_x_pos)
	alexgames.draw_line(FINISH_LINE_OUTLINE_COLOUR, 1,
	                     0,   screen_x_pos + checker_size * checker_count_x,
	                     bg_height, screen_x_pos + checker_size * checker_count_x)

	for i=0,checker_count_y-1 do
		for j=0,checker_count_x-1 do
			local checker_colour
			if (i*checker_count_x + j) % 2 == 0 then
				checker_colour = '#000000'
			else
				checker_colour = '#ffffff'
			end

			alexgames.draw_rect(checker_colour,
			                     (i  )*checker_size, screen_x_pos + (j  )*checker_size,
			                     (i+1)*checker_size, screen_x_pos + (j+1)*checker_size)
		end
	end
end

function draw.draw_state(game_state, player_idx, dt_ms)
	local camera = get_camera_pos(game_state, player_idx)
	alexgames.draw_clear()

	--alexgames.draw_rect('#aaaaaa', 0, 0, 480, 480)
	local bg_height = 480
	local bg_width = 480
	local screen_bg_pos = {
		y = math.floor(-(camera.y-math.floor(camera.y/bg_height)*bg_height)),
		x = math.floor(-(camera.x-math.floor(camera.x/bg_width)*bg_width)),
	}

	-- Draw two tiles of the background, that's the most that are ever visible at a time.
	for i=0,1 do
		local offset = 3 -- WTF why is this needed? Why doesn't my image tile nicely with this "offset" set to 0??
		                 -- ah, I shouldn't have the brick outline on both sides. TODO remove outline on right

		-- TODO I couldn't figure out how to make the bg image stop tiling at a certain position
		--if i == 1 then print(string.format("camera_real_pos_x = %8.1f", camera.x + i*bg_width)) end
		--if camera.x + (i+1)*bg_width > game_state.max_x then
		--	goto draw_bg_continue
		--end
		alexgames.draw_rect('#aaaaaa', math.floor(screen_bg_pos.y),             math.floor(screen_bg_pos.x + i * bg_width-offset),
		                                math.floor(screen_bg_pos.y) + bg_height, math.floor(screen_bg_pos.x + i * bg_width-offset) + bg_width)
		alexgames.draw_graphic('brick_wall',
		                        screen_bg_pos.y + bg_height/2, i*(bg_width-offset) + math.floor(screen_bg_pos.x) + bg_width/2, bg_width, bg_height)
		::draw_bg_continue::
	end

	draw_finish_line(game_state.finish_line_x - camera.x, bg_height)

	for player_idx, player in ipairs(game_state.players) do
		--alexgames.draw_circle(PLAYER_COLOURS[player_idx].fill, PLAYER_COLOURS[player_idx].outline,
		--                       math.floor(player.y - camera.y), math.floor(player.x - camera.x), PLAYER_RADIUS)
		local angle = 0
		if player.angle then
			angle = -math.floor(player.angle*180/math.pi)
		end
		alexgames.draw_graphic("spider",
		                       math.floor(player.y - camera.y), math.floor(player.x - camera.x), PLAYER_WIDTH, PLAYER_HEIGHT, { angle_degrees = angle })
		if player.swinging_on ~= nil then
			--local y2 = player.y + 30 * math.sin(player.swing_angle + math.pi/2)
			--local x2 = player.x + 30 * math.cos(player.swing_angle + math.pi/2)
			local node = game_state.swing_spots[player.swinging_on]
			local y1 = player.y - WEB_OFFSET * math.cos(player.angle)
			local x1 = player.x - WEB_OFFSET * math.sin(player.angle)
			local y2 = node.y
			local x2 = node.x
			alexgames.draw_line('#dddddd', ROPE_THICKNESS, math.floor(y1 - camera.y), math.floor(x1 - camera.x), math.floor(y2 - camera.y), math.floor(x2 - camera.x))

			--[[
			local dy = player.y - node.y
			local dx = player.x - node.x
			local angle = math.atan(dy,dx) - math.pi/2
			local y3 = player.y + 30 * math.sin(angle)
			local x3 = player.x + 30 * math.cos(angle)
			alexgames.draw_line('#00ff00', 2, math.floor(player.y - camera.y), math.floor(player.x - camera.x), math.floor(y3 - camera.y), math.floor(x3 - camera.x))
			--]]
		end
		alexgames.draw_text(string.format("E: %5.0f", math.floor(core.get_energy(game_state, player_idx)/100)), '#ff0000', 24, 5, 24, 1)
		alexgames.draw_text(string.format("pos: %5.0f", math.floor(player.x/10)), '#ff0000', 24, 480-150, 24, 1)
	end

	for _, node in ipairs(game_state.swing_spots) do
		alexgames.draw_circle(SWING_SPOT_COLOUR.fill, SWING_SPOT_COLOUR.outline,
		                       math.floor(node.y - camera.y), math.floor(node.x - camera.x), SWING_SPOT_RADIUS)
	end

	if dt_ms ~= 0 then
		draw_celebration_anim.update(anim_state, dt_ms/1000.0)
	end
	draw_celebration_anim.draw(anim_state)
	alexgames.draw_refresh()
end

function draw.player_finished()
	draw_celebration_anim.fireworks_display(anim_state, {
		-- I didn't implement dark mode in this game, so 
		-- when showing the fireworks display, the dark background
		-- needs to be drawn so that the fireworks are more visible.
		colour_pref = "light",
	})
end

return draw
