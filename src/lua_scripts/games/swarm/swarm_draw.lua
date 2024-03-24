local draw = {}

local core = require("games/swarm/swarm_core")
local touchpad = require("libs/ui/touchpad")
local alex_c_api = require("alex_c_api")

draw.ACTION_PLAYER_VEC_CHANGE = 1

local height = 480
local width  = 480

local padding = 5

local TOUCHPAD_RADIUS = 85
local TOUCHPAD_POS = {
	y = height - TOUCHPAD_RADIUS - padding,
	x = width  - TOUCHPAD_RADIUS - padding,
}

local BACKGROUND_COLOUR = '#0f7901'

local function get_attack_img(attack_type)
	local MAP = {
		[core.ATTACK_TYPE_BROCCOLI] = "swarm_broccoli",
		[core.ATTACK_TYPE_HAMMER]   = "swarm_hammer",
	}
	return MAP[attack_type]
end

local function get_screen_pos(state, game_pos)
	return {
		y = math.floor(height/2 - state.players[1].y + game_pos.y),
		x = math.floor(width/2  - state.players[1].x + game_pos.x),
	}
end

local function draw_bg(state, player_idx)
	--alex_c_api.draw_rect(BACKGROUND_COLOUR, 0, 0, height, width)

	for _, bg_y_idx in ipairs({0, 1}) do
		for _, bg_x_idx in ipairs({0, 1}) do
			local bg = get_screen_pos(state, {
				y = (math.floor(state.players[player_idx].y/height) + bg_y_idx)*height,
				x = (math.floor(state.players[player_idx].x/width) + bg_x_idx)*width,
			})
			alex_c_api.draw_graphic("swarm_grass_bg1", bg.y, bg.x, height, width)
		end
	end
end

local function draw_attacks_state(state, player_idx)
	local player_state = state.players[player_idx]
	for attack_type, attack_state in pairs(player_state.attack_states) do
		local img_id = get_attack_img(attack_type)
		local positions = attack_state.get_positions(state, player_state, attack_state)
		--local broccoli_positions = core.get_broccoli_particle_positions(state, state.players[player_idx], state.players[player_idx].attack_states[core.ATTACK_TYPE_BROCCOLI])
		for _, pos in ipairs(positions) do
			local screen_pos = get_screen_pos(state, pos)
			local attack_info = core.ATTACK_INFO[attack_type]
			alex_c_api.draw_graphic(img_id, screen_pos.y, screen_pos.x,
				attack_info.size_y, attack_info.size_x)
		end
	end

end

function draw.draw_state(state, ui_state, player_idx)
	alex_c_api.draw_clear()

	draw_bg(state, player_idx)

	alex_c_api.draw_text("player", '#000000', height/2, width/2, 12, 0)
	draw_attacks_state(state, player_idx)
	--alex_c_api.draw_graphic("swarm_broccoli", height/4, width/4, 80, 80)
	--alex_c_api.draw_graphic("swarm_hammer", height/4, width/4, 50, 50)

	for enemy_idx, enemy in ipairs(state.enemies) do
		local screen_pos = get_screen_pos(state, enemy)
		alex_c_api.draw_text(string.format("%d", enemy_idx), '#000000', screen_pos.y, screen_pos.x, 12, 0)
	end

	alex_c_api.draw_graphic('hospital_ui_dirpad',
	                        ui_state.touchpad.pos.y,
	                        ui_state.touchpad.pos.x,
	                        2*ui_state.touchpad.radius,
	                        2*ui_state.touchpad.radius)
	                        

end

function draw.handle_touch_evts(state, evt_id, touches)
	local actions = {}

	local new_player_vec = touchpad.handle_touch_evts(state.touchpad, evt_id, touches)
	if new_player_vec ~= nil then
		table.insert(actions, {
			action_type = draw.ACTION_PLAYER_VEC_CHANGE,
			new_player_vec = new_player_vec,
		})
	end

	return actions
end

function draw.init(height, width)
	local state = {
		touchpad = touchpad.new_state(TOUCHPAD_POS, TOUCHPAD_RADIUS),
	}
	return state
end

return draw
