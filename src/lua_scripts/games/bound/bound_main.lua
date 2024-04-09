
local core = require("games/bound/bound_core")
local draw = require("games/bound/bound_draw")
local serialize = require("games/bound/bound_serialize")

local wait_for_players = require("libs/multiplayer/wait_for_players")

local alexgames = require("alexgames")

--[[
	TODO:
	* fix cursor, make it always go towards closest cell...
      right now it's hard to select something to the top left of you if
	  there's something else (perhaps a full cell away) to the bottom right
	* implement multiplayer
	* implement score, right now I just hardcoded +10 and -100 in animations,
	  but the sum isn't tracked anywhere
	* fix arrow keys as client, didn't work on calc.alexbarry.net
	* I saw "player 'all' joined" as host on calc.alexbarry.net

	* need to fix delay on client when joining a mobile host... it's unplayable
	* missing some things from serializiation like the "time to fix" level, and animations

* Need to make some sort of progression.

# Future ideas for progression

* start out with one of each illness at a time, maybe a few random ones.
	- one of each, in order, then maybe another one of each in a random order
	- in these cases, make a new patient just as the previous one was cured-- so no
	  stress when learning, and fast if you know what you're doing
* then two at once for a bit, three at once
* one some limit is reached (10 patients?) need some unlocks

possible unlocks:
* a nurse who can reveal patients' needs
* another nurse who can also help patients with low fluids
* a nurse or some mechanism of automating everything? But then there are twice as many illnesses occurring
* a new wing of the hospital that opens up, so you have twice as many patients to worry about--
  now you need to keep an eye on more places, and see if the AI working in the other wing is sufficient or needs help
* coffee or some powerup to help you move much faster between wings 
* a pager or cell phone so that you can see if people need help nearby?
* an alarm for code blues, so that people who need defibrillation will be noticed right away, and you don't
  have to keep an eye on everyone?
* an ambulance that could drive inside the hospital and help people? Or that you could use to move around quickly?

The goal is that you start out individually doing everything, but by the end game you should be able
to help something like 10 times as many patients, getting 10 times as many points, and hopefully
10 times the fun and pressure...

Maybe over time, you just get more and more wings of the hospital to work on? It just keeps
growing forever, and you're limited by how quickly you can get around, or how much you can keep an eye on everyone?

That would be interesting... the amount of work remains constant, but the number of places that you may be needed
keeps increasing infinitely... and the transportation delay can hopefully be mitigated somehow, so that the only factor
that affects your skill is awareness. Maybe there are conveyor belts that help you move around very quickly?
Or a highway or something?

Maybe multiple levels in the same hospital... oh just an elevator with no travel time? That would be an easy way to
spread the hospital out infinitely. Although at that point what does it matter? I guess you have to manage where
you leave equipment?



* new challenges: have a mini map to see where you're needed, but you also need to keep an eye on where you step.
	- vomit: sticky, slow you down?
	- broken glass: similar
	- spilled water: make you slide in a random direction
	- slow patients in wheel chairs
	- coffee is a power up to make you move quickly
	- find an empty wheel chair to move quickly
	- banana peel to slip and fall
	- crowd of people wandering
	- marbles/toys on the ground
	- residents/students

new illnesses:
	- dialysis: either bring them a dialysis machine or take them to it.
	- diabetics: insulin or sugar
	- transplant: take a kidney out of one person, bring it to another
	- needs surgery? Appendicits?
	- eyes? glaucoma? need glasses? bring them to the eye chart?
	- ears: iconic ear examining thing




--]]

local players = {
	[1] = "You",
}
local player = 1
local is_client = false
local player_name_to_idx = {}

local FPS = 20
local dt = math.floor(1000.0/FPS)
local keys_down = {}

local screen_width  = 480
local screen_height = 480
local player = 1
local game_params = {
	y_size = 10,
	x_size = 10,
	num_players = 1,
}

local ui_state = draw.init(screen_width, screen_height, game_params)
local state = nil

function draw_board()
	if state == nil then
		return
	end

	draw.update_animations(state, dt)

	-- TODO need to handle animations for client players
	if not is_client then
		local events = core.update_state(state, dt)
		draw.add_animations_for_events(state, ui_state, events)
	end

	draw.draw_state(state, ui_state, player)
	send_state_updates_if_host()
end

local function handle_actions_host(actions, player)
	if state == nil then
		return
	end
	for _, action in ipairs(actions) do
		if action.action == core.ACTION_DIR_PAD_POS_CHANGE then
			core.handle_player_dirpad_update(state, player, action.vec_y, action.vec_x)
		elseif action.action == core.ACTION_USE_BTN_DOWN then
			core.handle_player_use_btn(state, player, true)
		elseif action.action == core.ACTION_USE_BTN_RELEASE then
			core.handle_player_use_btn(state, player, false)
		elseif action.action == core.ACTION_DROP_BTN_DOWN then
			core.handle_player_drop_btn(state, player, true)
		elseif action.action == core.ACTION_DROP_BTN_RELEASE then
			core.handle_player_drop_btn(state, player, false)
		end
	end
end



local function handle_recv_action(src, msg)
	local src_player_idx = player_name_to_idx[src]
	if src_player_idx == nil then
		error("unexpected player src " .. src)
	end
	local m = msg:gmatch("(%d),(.*)")
	if m == nil then
		error(string.format("invalid action msg recvd %s", msg))
	end
	local action_type, payload = m()
	action_type = tonumber(action_type)

	local action = {
		action = action_type,
	}

	if action.action == core.ACTION_DIR_PAD_POS_CHANGE then
		local m2 = payload:gmatch("(-?%d*),(-?%d*)")
		if m2 == nil then
			error(string.format("invalid action dir pad pos msg payload recvd: %s", payload))
		end
		local vec_y_int, vec_x_int = m2()
		vec_y_int = tonumber(vec_y_int)
		vec_x_int = tonumber(vec_x_int)
		action.vec_y = vec_y_int*1.0/1000
		action.vec_x = vec_x_int*1.0/1000
	end

	handle_actions_host({action}, src_player_idx)
	
end

-- Could also throttle this to not send the same position more than once in a row,
-- or within some factor or something
--
-- TODO need to make sure this doesn't happen for keypresses
local last_dirpad_update_time = nil
local MIN_DIRPAD_POS_UPDATE_PERIOD_MS = 50
local function handle_actions_client(actions, player)
	for _, action in ipairs(actions) do
		local payload = ""
		if action.action == core.ACTION_DIR_PAD_POS_CHANGE then
			local curr_time = alexgames.get_time_ms()
			if action.vec_y ~= 0 and action.vec_x ~= 0 and
			   last_dirpad_update_time ~= nil and
			   curr_time - last_dirpad_update_time < MIN_DIRPAD_POS_UPDATE_PERIOD_MS then
				goto next_action
			end
			last_dirpad_update_time = curr_time
			payload = string.format("%d,%d", math.floor(action.vec_y*1000),
			                                 math.floor(action.vec_x*1000))
		end
		local msg = string.format("action:%d,%s", action.action, payload)
		alexgames.send_message("all", msg)
		::next_action::
	end
end

local function handle_actions(actions, player)
	if is_client then
		handle_actions_client(actions, player)
	else
		handle_actions_host(actions, player)
	end
end



function handle_touch_evt(evt_id, changed_touches)
	draw.set_input_type(ui_state, draw.INPUT_TYPE_TOUCH)
	local actions = draw.touches_to_actions(state, ui_state, evt_id, changed_touches)
	handle_actions(actions, player)
end

local movement_keys = {
       ["ArrowUp"]    = true,
       ["ArrowLeft"]  = true,
       ["ArrowRight"] = true,
       ["ArrowDown"]  = true,
       ["KeyH"]       = true,
       ["KeyJ"]       = true,
       ["KeyK"]       = true,
       ["KeyL"]       = true,
}

function handle_key_evt(evt_id, key_code)
	local handled = false
	draw.set_input_type(ui_state, draw.INPUT_TYPE_KEYBOARD)
	local prev_state = keys_down[key_code]
	if evt_id == 'keydown' then
		keys_down[key_code] = true
	elseif evt_id == 'keyup' then
		keys_down[key_code] = false
	else
		error(string.format("Unhandled key_evt \"%s\"", evt_id))
	end

	if prev_state == keys_down[key_code] then
		-- If the key was one of the movement keys, tell the client that we've handled it.
		-- This is to avoid duplicate arrow keys (sent when you hold one down, after a second or so)
		-- causing the browser to scroll.
		return movement_keys[key_code]
	end

	local vec_y = 0
	local vec_x = 0

	if keys_down["ArrowUp"] or keys_down["KeyK"] then
		vec_y = -1
	elseif keys_down["ArrowDown"] or keys_down["KeyJ"] then
		vec_y = 1
	end

	if keys_down["ArrowLeft"] or keys_down["KeyH"] then
		vec_x = -1
	elseif keys_down["ArrowRight"] or keys_down["KeyL"] then
		vec_x = 1
	end

	local mag = math.sqrt(vec_y*vec_y + vec_x*vec_x)

	if mag > 0 then
		vec_y = vec_y / mag
		vec_x = vec_x / mag
	end

	if movement_keys[key_code] then
		handle_actions({{
			-- TODO move this to core
			action = core.ACTION_DIR_PAD_POS_CHANGE,
			vec_y = vec_y,
			vec_x = vec_x,
		}}, player)
		handled = true
	end

	if key_code == 'KeyZ' then
		if evt_id == 'keydown' then
			handle_actions({{
				action = core.ACTION_USE_BTN_DOWN,
			}}, player)
		elseif evt_id == 'keyup' then
			handle_actions({{
				action = core.ACTION_USE_BTN_RELEASE,
			}}, player)
		else
			error(string.format("unhandled evt_id = %s", evt_id))
		end
		handled = true
	end

	if key_code == 'KeyX' then
		if evt_id == 'keydown' then
			handle_actions({{
				action = core.ACTION_DROP_BTN_DOWN,
			}}, player)
		elseif evt_id == 'keyup' then
			handle_actions({{
				action = core.ACTION_DROP_BTN_RELEASE,
			}}, player)
		else
			error(string.format("unhandled evt_id = %s", evt_id))
		end
		handled = true
	end

	return handled

end

function new_game(player_count)
	game_params.num_players = player_count
	state = core.init(game_params)
end

function send_state_updates_if_host()
	if is_client then
		return
	end

	if state == nil then
		return
	end

	for dst_player, player_name in pairs(players) do
		if dst_player == player then
			goto next_player
		end
		local state_msg = "state:" .. serialize.serialize_state(state)
		alexgames.send_message(player_name, state_msg)
		::next_player::
	end
end



local function start_host_game(players_arg, player_arg, player_name_to_idx_arg)
	print("Starting game as host")
	players = players_arg
	player  = player_arg
	player_name_to_idx = player_name_to_idx_arg
	is_client = false
	new_game(#players)
	send_state_updates_if_host()
	draw_board()
end

local function start_client_game(players_arg, player_arg, player_name_to_idx_arg)
	print("Starting game as client")
	players = players_arg
	player  = player_arg
	player_name_to_idx = player_name_to_idx_arg
	is_client = true
	-- no need to draw board here, a state update should soon follow
end

function handle_msg_received(src, msg)

	local handled = wait_for_players.handle_msg_received(src, msg)
	if handled then
		return
	end
	local m = msg:gmatch("([^:]+):(.*)")
	local header, payload
	header, payload = m()

	if header == "state" then
		if not is_client then
			error("Received state as host")
		end
		state = serialize.deserialize_state(payload)
	elseif header == "player_joined" or
	       header == "player_left" then
		-- ignore I guess?
	elseif header == "action" then
		handle_recv_action(src, payload)
	else
		error(string.format("Unhandled message %s", header))
	end

	send_state_updates_if_host()
	draw_board()
end 

function handle_popup_btn_clicked(popup_id, btn_idx)
	local handled = wait_for_players.handle_popup_btn_clicked(popup_id, btn_idx)
	if handled then
		return
	end
end


alexgames.enable_evt('touch')
alexgames.enable_evt('key')
alexgames.set_timer_update_ms(math.floor(dt))

wait_for_players.init(players, player, start_host_game, start_client_game)
