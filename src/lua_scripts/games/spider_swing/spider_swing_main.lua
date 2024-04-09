-- Game:   Spider Swing
-- Author: Alex Barry (github.com/alexbarry)
--
--[[
-- TODO:
--   * add different stages, including moving swing spots such as:
--	     - butterflies (moving eratically, perhaps? Or any direction)
--       - leaves (could just fall down, or blow up, or blow side to side steadily)
--]]

local core = require("games/spider_swing/spider_swing_core")
local draw = require("games/spider_swing/spider_swing_draw")

local alexgames = require("alexgames")

local state = {}
state.game = core.new_state()
local player_idx = 1

local player_won = false

local FPS = 60
local TIME_PER_FRAME_MS = 1000/FPS

local GAME_OPTION_NEW_GAME = "option_new_game"

function update(dt_ms)
	if state.game.game_over then 
		state.game.game_over = false
		core.reset_player_state(state.game, player_idx)
		player_won = false
	end
	--print(string.format("Pos is now {y=%.1f, x=%.1f}", state.game.players[1].y, state.game.players[1].x))
	if not player_won then
		player_won = core.player_won(state.game, player_idx)
		if player_won then
			draw.player_finished()
		end
	end
	core.update_state(state.game, dt_ms)
	draw.draw_state(state.game, player_idx, dt_ms)
end

local function user_press(pos_y, pos_x)
	local pos = draw.get_mouse_pos_in_game(state.game, player_idx, pos_y, pos_x)
	local node_idx = core.get_closest_swing_spot(state.game, pos)
	core.player_attach_swing(state.game, player_idx, node_idx)
end

local function user_release()
	core.player_release_swing(state.game, player_idx)
end


function handle_mouse_evt(evt_id, pos_y, pos_x)
	-- print("handle_mouse_evt" .. evt_id)
	if evt_id == 2 then
		user_press(pos_y, pos_x)
	elseif evt_id == 1 then
		user_release()
	end
end

function handle_touch_evt(evt_id, changed_touches)
	-- print("handle_touch_evt: " .. evt_id)
	if evt_id == "touchstart" then
		user_press(changed_touches[1].y, changed_touches[1].x)
	elseif evt_id == "touchend" then
		user_release()
	end
end

function handle_game_option_evt(option_id)
	if option_id == GAME_OPTION_NEW_GAME then
		state.game = core.new_state()
		player_won = false
	end
end

-- Since this game is fast, it doesn't really make sense to share the state.
-- Well, it sort of does, since it's randomly generated, maybe you really want to
-- try again on a different device.
-- But since I didn't implement saving state yet, I didn't implement serialization,
-- so for now I am just going to return nil here to suppress the warning.
function get_state()
	return nil
end

function start_game()
	alexgames.set_timer_update_ms(TIME_PER_FRAME_MS)
	alexgames.enable_evt("mouse_updown")
	alexgames.enable_evt("touch")

	alexgames.add_game_option(GAME_OPTION_NEW_GAME, { label = "New game", type = alexgames.OPTION_TYPE_BTN })
end
