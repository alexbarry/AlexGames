
local draw = {}
local alex_c_api = require("alex_c_api")
local touchpad   = require("libs/ui/touchpad")
local core = require("games/thrust/thrust_core")

draw.ACTION_PLAYER_VEC_CHANGED = 1



local BG_COLOUR = '#000000'
local THRUST_COLOUR = '#ff8800'
local THRUST_COLOUR_OUTLINE = '#ffff00'
local STAR_COLOUR = '#ffffff'
local WALL_COLOUR = '#ff0000'
local height = 480
local width  = 480

local WALL_THICKNESS = 5
local CHECKPOINT_WALL_COLOUR_UNMET = '#00ff0077'
local CHECKPOINT_WALL_COLOUR_MET   = '#00880077'
local CHECKPOINT_THICKNESS_MET     = 1
local CHECKPOINT_THICKNESS_UNMET   = 2

local TEXT_COLOUR  = '#aaaaaa'
local TEXT_SIZE    = 24
local TEXT_PADDING = 3

local padding = 5
local TOUCHPAD_RADIUS = 85
local TOUCHPAD_POS = {
	y = height - TOUCHPAD_RADIUS - padding,
	x = width  - TOUCHPAD_RADIUS - padding,
}

local SHIP1 = "ship1"

local ship_graphics = {
	[SHIP1] = { img_id = "space_ship1", height = 150, width = 150 },
}

local function game_pt_to_screen_pt(state, player_state, pt)
	return {
		y = math.floor(state.zoom * (pt.y - player_state.y) + height/2),
		x = math.floor(state.zoom * (pt.x - player_state.x) + width/2),
	}
end

local function draw_walls(state, player_state)
	for _, wall_info in ipairs(state.walls) do
		--[[
		alex_c_api.draw_rect(WALL_COLOUR,
		                     wall_info.y_start - state.y, wall_info.x_start - state.x,
		                     wall_info.y_end   - state.y, wall_info.x_end   - state.x)
		--]]
		local pt1 = game_pt_to_screen_pt(state, player_state, { y = wall_info.y_start, x = wall_info.x_start})
		local pt2 = game_pt_to_screen_pt(state, player_state, { y = wall_info.y_end,   x = wall_info.x_end})
		alex_c_api.draw_line(WALL_COLOUR, WALL_THICKNESS,
		                     pt1.y, pt1.x,
		                     pt2.y, pt2.x)
		                     
	end

	for checkpoint_idx, wall_info in ipairs(state.checkpoints) do
		local pt1 = game_pt_to_screen_pt(state, player_state, { y = wall_info.y_start, x = wall_info.x_start})
		local pt2 = game_pt_to_screen_pt(state, player_state, { y = wall_info.y_end,   x = wall_info.x_end})
		local colour
		local thickness
		if player_state.met_checkpoints[checkpoint_idx] then
			colour = CHECKPOINT_WALL_COLOUR_MET
			thickness = CHECKPOINT_THICKNESS_MET
		else
			colour = CHECKPOINT_WALL_COLOUR_UNMET
			thickness = CHECKPOINT_THICKNESS_UNMET
		end
		alex_c_api.draw_line(colour, thickness,
		                     pt1.y, pt1.x,
		                     pt2.y, pt2.x)
	end

	local wall_info = state.finish_line
	local pt1 = game_pt_to_screen_pt(state, player_state, { y = wall_info.y_start, x = wall_info.x_start})
	local pt2 = game_pt_to_screen_pt(state, player_state, { y = wall_info.y_end,   x = wall_info.x_end})
	if not core.met_all_checkpoints(player_state) then
		colour = CHECKPOINT_WALL_COLOUR_MET
		thickness = CHECKPOINT_THICKNESS_MET
	else
		colour = CHECKPOINT_WALL_COLOUR_UNMET
		thickness = CHECKPOINT_THICKNESS_UNMET
	end
	alex_c_api.draw_line(colour, thickness,
	                     pt1.y, pt1.x,
	                     pt2.y, pt2.x)

end

local function draw_ship(ship_type, state, player_state)
	--print(string.format("ship_type=%s, y=%s, x=%s, angle=%s", ship_type, y, x, angle))
	local ship_img_info = ship_graphics[ship_type]

	local thrust_offset = 20
	local thrust_len    = 20
	local thrust_width  =  5
	local thrust_angle = player_state.angle_degrees/180*math.pi

	local thrust_radius = 10

	local y_pos = height/2
	local x_pos = width/2



	if player_state.thrust_on then
	alex_c_api.draw_circle(THRUST_COLOUR,
	                       THRUST_COLOUR_OUTLINE,
	                       math.floor(y_pos + thrust_offset*math.cos(thrust_angle)),
	                       math.floor(x_pos - thrust_offset*math.sin(thrust_angle)),
	                       math.floor(state.zoom*thrust_radius))
	--[[
	local thrust_angle = player_state.angle_degrees/180*math.pi
	alex_c_api.draw_rect(THRUST_COLOUR,
		math.floor(player_state.y + thrust_offset*math.cos(thrust_angle)),
		math.floor(player_state.x - thrust_width*math.sin(thrust_angle)),
		math.floor(player_state.y + (thrust_offset+thrust_len)*math.cos(thrust_angle)),
		math.floor(player_state.x + thrust_width*math.sin(thrust_angle)))
	--]]
	end

	alex_c_api.draw_graphic(ship_img_info.img_id,
	                        math.floor(y_pos),
	                        math.floor(x_pos),
	                        math.floor(state.zoom*ship_img_info.height),
	                        math.floor(state.zoom*ship_img_info.width), {
	                        	-- anchor_centre = true, -- TODO this should be the default, I think...
	                        	angle_degrees = math.floor(player_state.angle_degrees),
	                        })
	--[[
	alex_c_api.draw_rect('#ffffff', y - ship_img_info.height/2,
	                     x - ship_img_info.width/2,
	                     y - ship_img_info.height/2 + ship_img_info.height,
	                     x - ship_img_info.width/2 + ship_img_info.width)
	--]]
	                     
end

local function draw_stars_bg(state, player_state, star_move_fact)
	star_move_fact = star_move_fact / state.zoom
	for _, star in ipairs(state.stars) do
		alex_c_api.draw_circle(STAR_COLOUR, STAR_COLOUR,
		                       math.floor(star.y - player_state.y/star_move_fact), math.floor(star.x - player_state.x/star_move_fact),
		                       1)
	end
end

local function format_time(time_ms)
	local milliseconds = (time_ms % 1000)
	local seconds = math.floor(time_ms/1000)
	local minutes = math.floor(seconds/60)
	seconds = seconds % 60

	return string.format("%2d:%02d.%03d", minutes, seconds, milliseconds)
end

function draw.init()
	return {
		touchpad = touchpad.new_state(TOUCHPAD_POS, TOUCHPAD_RADIUS),
	}
end

function draw.draw_state(state, ui_state)
	alex_c_api.draw_clear()
	alex_c_api.draw_rect(BG_COLOUR, 0, 0, height, width)
	draw_stars_bg(state, state.players[1], 3)
	draw_walls(state, state.players[1])
	draw_ship(SHIP1, state, state.players[1])

	alex_c_api.draw_text(format_time(state.players[1].lap_time_ms), TEXT_COLOUR,
	                     TEXT_SIZE + TEXT_PADDING, TEXT_PADDING, TEXT_SIZE, 1)

	for lap_idx, lap_time in ipairs(state.players[1].lap_times) do
		local text = string.format('%d:%s', lap_idx, format_time(lap_time))
		alex_c_api.draw_text(text, TEXT_COLOUR,
		                     lap_idx*(TEXT_SIZE + TEXT_PADDING),
		                     width - TEXT_PADDING,
		                     TEXT_SIZE, -1)
	end

	alex_c_api.draw_graphic("hospital_ui_dirpad",
	                        ui_state.touchpad.pos.y,
	                        ui_state.touchpad.pos.x,
	                        2*ui_state.touchpad.radius,
	                        2*ui_state.touchpad.radius)

	alex_c_api.draw_refresh()
end

function draw.handle_touch_evts(ui_state, evt_id, touches)
	local actions = {}

	local player_vec = touchpad.handle_touch_evts(ui_state.touchpad, evt_id, touches)
	if player_vec ~= nil then
		table.insert(actions, {
			action = draw.ACTION_PLAYER_VEC_CHANGED,
			player_vec = player_vec,
		})
	end
		
	return actions
end

return draw
