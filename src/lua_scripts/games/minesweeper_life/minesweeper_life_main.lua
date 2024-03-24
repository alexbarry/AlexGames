
local core      = require("games/minesweeper_life/minesweeper_life_core")
local draw      = require("games/minesweeper_life/minesweeper_draw")
local serialize = require("games/minesweeper_life/minesweeper_serialize")

local wait_for_players = require("libs/multiplayer/wait_for_players")
local show_buttons_popup = require("libs/ui/show_buttons_popup")

local alex_c_api = require("alex_c_api")

-- TODO add:
--    * vibrate phone when flag has appeared? Show red circle so user knows when flag appears
--      even if it is covered by their finger?
--
-- TODO for multiplayer:
--    * TODO add a graphic for "cell is loading". For now it is probably fine to just leave it as unclicked because
--      of the low latency. (Actually, even on my LAN, I see a decent bit of latency when hosting on my phone and
--      using my laptop as a client.)
--    * animate points appearing over where you click 


-- maximum y or x distance that a player can move their finger/mouse before their gesture is no longer
-- interpreted as a click
local MAX_CLICK_MOVE = 2

local game_size_y = 20
local game_size_x = 20

local player = 1
local player_count = 1
local cell_size = core.cell_size
-- TODO initialize player state but not game state
local state = core.new_state(player_count, game_size_y, game_size_x, cell_size, core.DEFAULT_MINE_PORTION)
local win_anim_shown = false
local state_set = false
local g_session_id = alex_c_api.get_new_session_id()
local g_multiplayer_init = false
		
--local state = nil
local user_input_down = false
local user_input_down_timer_fired = false
local user_input_down_time = nil
local user_input_moved = false

-- These are only set on touchdown
local user_input_pos_y = nil
local user_input_pos_x = nil

-- These are updated on touchdown and touchmove events
local user_input_pos_move_y = nil
local user_input_pos_move_x = nil

local user_input2_pos_move_y = nil
local user_input2_pos_move_x = nil
local user_init_touch_dist  = nil
local user_offset_y = 0
local user_offset_x = 0
local active_touch  = nil
local active_touch2 = nil

local players = {
	[1] = "You",
}
local player = 1
local is_client = false
local player_name_to_idx = {}

local GAME_OPT_NEW_GAME = "game_opt_new_game"


local USER_INPUT_DOWN_TIME_THRESHOLD_MS = 300

local POPUP_ID_LEVEL_SEL = "popup_level_sel"

local DIFFICULTY_EASY = 0
local DIFFICULTY_MEDIUM = 1
local DIFFICULTY_HARD = 2

local levels = {
	{ label = "", premade = 1 },
	{ label = "", premade = 2 },
	{ label = "Five period oscillator", premade = 3 },
	{ label = "16 period oscillator", premade = 4 },

	{ label = "",   portion = 0.25 },
	{ label = "",   portion = 0.30 },
	{ label = "",   portion = 0.35 },
	{ label = "",   portion = 0.45 },
	{ label = "",   portion = 0.45 },
	{ label = "",   portion = 0.55 },
	{ label = "",   portion = 0.65 },
	{ label = "",   portion = 0.75 },
}

local difficulty_btns = {}
for _, level in ipairs(levels) do
	local output = ""
	if #level.label > 0 then
		output = level.label .. " "
	end
	if level.portion then
		output = output .. string.format("Random (%.0f%% mines)", level.portion*100)
	end

	if level.premade then
		output = output .. string.format("Premade puzzle %d", level.premade)
	end
	table.insert(difficulty_btns, output)
end

local function prompt_level()
	show_buttons_popup.show_popup(POPUP_ID_LEVEL_SEL,
	                           "Select Puzzle Type",
	                           "Select a puzzle type",
	                           difficulty_btns)
end


local function handle_move_client(state, player, move, y, x)
	local msg = string.format("move:%d,%d,%d,%d", player, move, y, x)
	-- TODO only message the host in the future?
	alex_c_api.send_message("all", msg)
	return core.RC_SUCCESS
end

local function handle_move(state, player, move, y, x)
	local rc = nil
	if is_client then
		rc = handle_move_client(state, player, move, y, x)
	else
		rc = core.handle_move(state, player, move, y, x)
	end
	local state_serialized = serialize.serialize_state(state)
	if move == core.MOVE_FLAG_CELL then
		draw.draw_flag_flash = true
	end
	alex_c_api.save_state(g_session_id, state_serialized)

	if core.is_game_over(state) and not win_anim_shown then
		print('alex showing victory animation')
		win_anim_shown = true
		draw.victory_animation(60)
	end
end

local function check_for_input_time_done()
	if not user_input_down then
		return
	end

	local time_diff = alex_c_api.get_time_ms() - user_input_down_time
	if user_input_down and 
	   time_diff >= USER_INPUT_DOWN_TIME_THRESHOLD_MS and
		not user_input_moved and
		not user_input_down_timer_fired then
		user_input_down_timer_fired = true
		local cell_coords = draw.pos_to_cell_coords(state, player, user_input_pos_y, user_input_pos_x)
		handle_move(state, player, core.MOVE_FLAG_CELL, cell_coords.y, cell_coords.x)
		send_state_updates_if_host()
		draw_board()
	end
end

-- TODO change draw_board to some "update_evt" or something
function draw_board(dt_ms)
	if dt_ms ~= nil then
		draw.update(dt_ms)
	end
	draw.draw_state(state, player)
	check_for_input_time_done()
end

local function handle_user_input_down(pos_y, pos_x)
		user_input_down_time = alex_c_api.get_time_ms()
		user_input_down = true
		user_input_moved = false
		user_input_down_timer_fired = false
		user_input_pos_y = pos_y
		user_input_pos_x = pos_x
		user_input_pos_move_y = pos_y
		user_input_pos_move_x = pos_x
		user_offset_y = state.players[player].offset_y
		user_offset_x = state.players[player].offset_x
end

local function handle_user_input_release(pos_y, pos_x, cancel)
	if not cancel and not user_input_moved and not user_input_down_timer_fired then
		local cell_coords = draw.pos_to_cell_coords(state, player, pos_y, pos_x)
		local time_diff = alex_c_api.get_time_ms() - user_input_down_time
		local move_type = nil
		if time_diff <= USER_INPUT_DOWN_TIME_THRESHOLD_MS then
			move_type = core.MOVE_CLICK_CELL
		else
			move_type = core.MOVE_FLAG_CELL
		end
		handle_move(state, player, move_type, cell_coords.y, cell_coords.x)
		draw_board()
		send_state_updates_if_host()
	end
	user_input_down = false
	user_input_down_timer_fired = false
end

function handle_mouse_evt(evt_id, pos_y, pos_x)
	if evt_id == alex_c_api.MOUSE_EVT_DOWN then
		handle_user_input_down(pos_y, pos_x)
	elseif evt_id == alex_c_api.MOUSE_EVT_UP then
		handle_user_input_release(pos_y, pos_x, false)
	elseif evt_id == alex_c_api.MOUSE_EVT_LEAVE then
		handle_user_input_release(pos_y, pos_x, true)
	elseif evt_id == alex_c_api.MOUSE_EVT_ALT_DOWN then
		local cell_coords = draw.pos_to_cell_coords(state, player, pos_y, pos_x)
		handle_move(state, player, core.MOVE_FLAG_CELL, cell_coords.y, cell_coords.x)
	else
		print(string.format('unhandled evt_id %s', evt_id))
	end
end

local function handle_user_input_move(pos_y, pos_x)
	if user_input_down and (
	      math.abs(user_input_pos_y - pos_y) > MAX_CLICK_MOVE or
	      math.abs(user_input_pos_x - pos_x) > MAX_CLICK_MOVE) then
		user_input_moved = true
	end
	if user_input_down then
		local offset_adj_y = user_input_pos_y - pos_y
		local offset_adj_x = user_input_pos_x - pos_x
		user_input_pos_move_y = pos_y
		user_input_pos_move_x = pos_x
		core.adjust_offset(state, player,
			math.floor(user_offset_y + offset_adj_y),
			math.floor(user_offset_x + offset_adj_x))
		draw_board()
	end
end

function handle_mousemove(pos_y, pos_x)
	handle_user_input_move(pos_y, pos_x)
end

function handle_user_clicked()
end

local function get_touch_dist()
	local dy = user_input2_pos_move_y - user_input_pos_move_y
	local dx = user_input2_pos_move_x - user_input_pos_move_x
	return math.sqrt(dy*dy + dx*dx)
end

function handle_touch_evt(evt_id, changed_touches)
	for _, touch in ipairs(changed_touches) do
		if evt_id == 'touchstart' then
			if active_touch == nil then
				active_touch = touch.id
				handle_user_input_down(touch.y, touch.x)
			elseif active_touch2 == nil then
				active_touch2 = touch.id
				user_input_moved = true
				user_input2_pos_move_y = touch.y
				user_input2_pos_move_x = touch.x
				user_init_touch_dist = get_touch_dist()
				init_zoom = core.get_zoom_fact(state, player)
			end
		elseif evt_id == 'touchmove' then

			if active_touch == touch.id then
				handle_user_input_move(touch.y, touch.x)
			end

			if active_touch2 ~= nil then
				if active_touch2 == touch.id then
					user_input2_pos_move_y = touch.y
					user_input2_pos_move_x = touch.x
				end
				local touch_dist_fact = get_touch_dist() / user_init_touch_dist
				local zoom_fact = init_zoom * touch_dist_fact
				--alex_c_api.set_status_msg(
				--     string.format("Touch dist fact is %.3f, dist=%.0f, orig=%.0f",
				--                   touch_dist_fact, get_touch_dist(), user_init_touch_dist))
				core.set_zoom_fact(state, player, zoom_fact)
			end

		elseif evt_id == 'touchend' or
		       evt_id == 'touchcancel' then
			local is_cancel = (evt_id == 'touchcancel')
			if active_touch == touch.id then
				handle_user_input_release(touch.y, touch.x, is_cancel)
				active_touch = nil
			elseif active_touch2 == touch.id then
				active_touch2 = nil
			end
		end
	end
end

function handle_wheel_changed(dy, dx)
	print(string.format("handle_wheel(dy=%s, dx=%s)", dy, dx))

	local zoom_fact = core.get_zoom_fact(state, player)

	zoom_fact = zoom_fact + -dy/114 * 0.1

	core.set_zoom_fact(state, player, zoom_fact)

	draw_board()
end

function send_state_updates_if_host()
	print("send_state_updates_if_host", is_client, wait_for_players.is_host_tentative(),  state)
	if is_client and not wait_for_players.is_host_tentative() then
		print("return 1 send_state_updates_if_host", is_client, wait_for_players.is_host_tentative(),  state)
		return
	end

	if state == nil then
		print("return 2 send_state_updates_if_host", is_client, wait_for_players.is_host_tentative(),  state)
		return
	end

	for dst_player, player_name in pairs(wait_for_players.players_tentative()) do
		if dst_player == player then
			goto next_player
		end
		print("Sending state update")
		local state_msg = "state:" .. serialize.serialize_client_game_state(state, dst_player)
		alex_c_api.send_message(player_name, state_msg)
		::next_player::
	end
end

function apply_shape(state, shape, y, x)
	for dy=0,#shape-1 do
		for dx=0,#shape[1]-1 do
			if y+dy < state.game.height and
			   x+dx < state.game.width then
				state.game.board[y+dy][x+dx].has_mine = (shape[1+dy][1+dx] > 0)
			end
		end
	end

end

function new_game(player_count, level)
	print(string.format("Starting game with %d players, level %d", player_count, level))
	local puzzle_info = levels[level+1]
	if not puzzle_info.premade then
		local mine_portion = puzzle_info.portion
		print(string.format("Initializing game with mine portion %.0f%% (level idx %d)", mine_portion*100, level))
		alex_c_api.set_status_msg(string.format("Initializing game with mine portion %.0f%%", mine_portion*100))
		state = core.new_state(player_count, game_size_y, game_size_x, cell_size, mine_portion)
	elseif puzzle_info.premade == 1 then
		state = core.new_state(player_count, game_size_y, game_size_x, cell_size, 0)
		local shape1 = {
			{ 1, 0, 0},
			{ 0, 1, 1},
			{ 1, 1, 0},
		}

		local delta = 5
		for i=0,8 do
			for y=1,game_size_y,delta do
				apply_shape(state, shape1, y + delta*i, 2 + delta*i)
			end
		end

		local shape2 = {
			{ 0, 1, 1},
			{ 1, 1, 0},
			{ 0, 0, 1},
		}

		local delta = 5
		for i=0,8 do
			apply_shape(state, shape2, 2 + delta*i, 16 + delta*i)
			apply_shape(state, shape2, 2 + delta*i, 11 + delta*i)
		end

		core.reveal_cell(state, 1, game_size_y, game_size_x)

		core.get_touching_mine_count(state)
	elseif puzzle_info.premade == 2 then
		state = core.new_state(player_count, 30, 30, cell_size, 0)
		shape = {
			{ 0, 1, 1},
			{ 1, 1, 0},
			{ 0, 1, 0},
		}

		for y=4,state.game.height,8 do
			for x=4,state.game.width,8 do
				apply_shape(state, shape, y, x)
			end
		end

		core.reveal_cell(state, 1, 30, 1)

		core.get_touching_mine_count(state)
	elseif puzzle_info.premade == 3 then
		state = core.new_state(player_count, game_size_y, game_size_x, cell_size, 0)
		shape = {
			{ 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0 },
			{ 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0 },
			{ 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0 },
			{ 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1 },
			{ 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0 },
			{ 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0 },
			{ 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
		}

		apply_shape(state, shape, 3, 3)

		--core.reveal_cell(state, 1, game_size_y, game_size_x)

		core.get_touching_mine_count(state)

		alex_c_api.set_status_msg("Spoiler: See https://conwaylife.appspot.com/pattern/average for this pattern")
	elseif puzzle_info.premade == 4 then
		state = core.new_state(player_count, game_size_y, game_size_x, cell_size, 0)
		shape = {
			{ 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0 },
			{ 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0 },
			{ 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0 },
			{ 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
			{ 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1 },
			{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1 },
			{ 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0 },
			{ 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0 },
			{ 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
			{ 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0 },
		}

		apply_shape(state, shape, 2, 2)

		core.reveal_cell(state, 1, game_size_y, game_size_x)

		core.get_touching_mine_count(state)

		alex_c_api.set_status_msg("Spoiler: see https://conwaylife.appspot.com/pattern/achimsp16 for this pattern")
	else
		error(string.format("Unhandled premade index %s", puzzle_info.premade))
	end
	win_anim_shown = false
	g_session_id = alex_c_api.get_new_session_id()
end


local function start_host_game(players_arg, player_arg, player_name_to_idx_arg)
	print("Starting game as host")
	players = players_arg
	player  = player_arg
	player_name_to_idx = player_name_to_idx_arg
	is_client = false

	if not state_set then
		prompt_level()
	end
	send_state_updates_if_host()
	draw_board()
end

local function start_client_game(players_arg, player_arg, player_name_to_idx_arg)
	print("Starting game as client")
	players = players_arg
	player  = player_arg
	player_name_to_idx = player_name_to_idx_arg
	is_client = true
	-- TODO only initialize player_state here?
	state = core.new_state(#players, 20, 20, cell_size, core.DEFAULT_MINE_PORTION) -- TODO hacky to include mine portion here, this should never be used...
	-- no need to draw board here, a state update should soon follow
end

function handle_msg_received(src, msg)

	local handled = wait_for_players.handle_msg_received(src, msg)

	local m = msg:gmatch("([^:]+):(.*)")
	local header, payload
	header, payload = m()

	if handled and header ~= "joined" then
		return
	end

	if header == "state" then
		--if not is_client and not wait_for_players.is_host_tentative() then
		--	error("Received state as host")
		--end
		serialize.deserialize_client_game_state(state, payload)
	elseif header == "joined" then
		print("player_joined")
		send_state_updates_if_host()
	elseif header == "player_joined" or
	       header == "player_left" then
		-- ignore I guess?
	elseif header == "move" then
		if not is_client then
			local m2 = payload:gmatch("(%d+),(%d+),(%d+),(%d+)")
			if m2 == nil then
				error(string.format("invalid move payload %s", payload))
			end
			local player_str, move_type_str, y_str, x_str = m2()
			local player    = tonumber(player_str)
			local move_type = tonumber(move_type_str)
			local y         = tonumber(y_str)
			local x         = tonumber(x_str)

			if player ~= player_name_to_idx[src] then
				error(string.format("received move for player idx %s from player_name %s (%d)",
				      player, src, player_name_to_idx[src]))
			end
			handle_move(state, player, move_type, y, x)
			send_state_updates_if_host()
		end
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

	if popup_id == POPUP_ID_LEVEL_SEL then
		new_game(#players, btn_idx)
		alex_c_api.hide_popup()

		if not g_multiplayer_init then
			wait_for_players.init(players, player, start_host_game, start_client_game)
		end
	else
		error(string.format("Unhandled popup id %s", popup_id))
	end
end

function handle_game_option_evt(game_opt_id, value)
	if game_opt_id == GAME_OPT_NEW_GAME then
		--new_game(#players)
		prompt_level()
		draw_board()
	end
end

local function load_state_offset(offset)
	local ui_states = core.copy_player_ui_states(state)
	local state_serialized = alex_c_api.get_saved_state_offset(g_session_id, offset) 
	if state_serialized ~= nil then
		state = serialize.deserialize_state(state_serialized)
		core.apply_player_ui_states(state, ui_states)
		draw.draw_state(state, player)
	end
end

function handle_btn_clicked(btn_id)
	if btn_id == draw.BTN_ID_UNDO then
		load_state_offset(-1)
	elseif btn_id == draw.BTN_ID_REDO then
		load_state_offset(1)
	end
end

function get_state()
	return serialize.serialize_state(state)
end

-- TODO need proper state saving

draw.init(480, 480, cell_size)

function start_game(session_id, state_serialized)
	if state_serialized ~= nil then
		g_session_id = session_id
		state = serialize.deserialize_state(state_serialized)
		state_set = true
	else
		local last_sess_id = alex_c_api.get_last_session_id()
		if last_sess_id ~= nil then
			state_serialized = alex_c_api.get_saved_state_offset(last_sess_id, 0) 
			g_session_id = last_sess_id
			state = serialize.deserialize_state(state_serialized)
			state_set = true
		end
	end

	if state_serialized ~= nil then
		wait_for_players.init(players, player, start_host_game, start_client_game)
		g_multiplayer_init = true
	else
		prompt_level()
	end

	alex_c_api.enable_evt("mouse_move")
	alex_c_api.enable_evt("mouse_updown")
	alex_c_api.enable_evt("mouse_alt_updown")
	alex_c_api.enable_evt("touch")
	alex_c_api.enable_evt("wheel")

	alex_c_api.add_game_option(GAME_OPT_NEW_GAME, {
		type  = alex_c_api.OPTION_TYPE_BTN,
		label = "New Game"
	})

	-- Kind of sucks that I only need this timer for measuring touch/mouse down time.
	-- Would be ideal if I could just set a 300 ms one off timer?
	alex_c_api.set_timer_update_ms(50)

end
