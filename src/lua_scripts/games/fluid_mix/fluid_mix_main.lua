
local core = require("games/fluid_mix/fluid_mix_core")
local draw = require("games/fluid_mix/fluid_mix_draw")
local serialize = require("games/fluid_mix/fluid_mix_serialize")

local alexgames  = require("alexgames")


local g_session_id = nil
local g_state = nil
local draw_state = draw.new_state()
local vial_selected = nil
local g_win_anim_shown = nil

local BTN_ID_NEW_GAME = "btn_new_game"
draw.init()

alexgames.add_game_option(BTN_ID_NEW_GAME, { type = alexgames.OPTION_TYPE_BTN, label = "New Game"})


function update(dt_ms)
	if g_state == nil then return end
	if dt_ms ~= nil then
		draw.update_state(draw_state, dt_ms)
	end
	draw.draw_state(g_session_id, g_state, draw_state)
end

local function save_state()
	local state_serialized = serialize.serialize(g_state)
	alexgames.save_state(g_session_id, state_serialized)
end

function handle_user_clicked(pos_y, pos_x)
	local move = draw.handle_user_clicked(g_state, draw_state, pos_y, pos_x)
	if move ~= nil then
		local rc = core.move(g_state, move.src, move.dst)
		save_state()
	end
	if core.game_won(g_state) and not g_win_anim_shown then
		alexgames.set_status_msg("Congratulations, you win!")
		g_win_anim_shown = true
		draw.trigger_win_anim(draw_state, 60)
	end
	draw.draw_state(g_session_id, g_state, draw_state)
end

function load_state_offset(move_offset)
	local state_serialized = alexgames.adjust_saved_state_offset(g_session_id, move_offset)
	g_state = serialize.deserialize(state_serialized)
	g_win_anim_shown = false
	update()
end

function handle_btn_clicked(btn_id)
	if btn_id == draw.BTN_ID_UNDO then
		load_state_offset(-1)
	elseif btn_id == draw.BTN_ID_REDO then
		load_state_offset(1)
	else
		error(string.format("Unhandled btn_id %s", btn_id))
	end
end

function handle_game_option_evt(option_id)
	if option_id == BTN_ID_NEW_GAME then
		g_session_id = alexgames.get_new_session_id()
		g_state = core.new_state(11, 3, 4)
		g_win_anim_shown = false
		save_state()
		update()
	else
		error(string.format("Unhandled game option evt id=%s", option_id))
	end
end

function start_game(session_id, state_serialized)
	g_win_anim_shown = false
	if state_serialized ~= nil then
		g_session_id = session_id
		g_state = serialize.deserialize(state_serialized)
		update()
	else
		local prev_session_id = alexgames.get_last_session_id()
		print(string.format("Read previous session ID %s", prev_session_id))
		if prev_session_id ~= nil then
			g_session_id = prev_session_id
			state_serialized = alexgames.adjust_saved_state_offset(g_session_id, 0)
			g_state = serialize.deserialize(state_serialized)
			alexgames.set_status_msg(string.format("Loaded saved state from session %d", g_session_id))
		else
			g_session_id = alexgames.get_new_session_id()
			g_state = core.new_state(11, 3, 4)
		end
	end
end

function get_state()
	return serialize.serialize(g_state)
end

function get_init_state()
	local init_state = core.new_state(11, 3, 4, { seed_x = g_state.seed_x, g_state.seed_y })
	return serialize.serialize(init_state)
end
