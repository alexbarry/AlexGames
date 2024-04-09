-- TODO currently there's a bug where if you generate a custom puzzle via entering a
-- string and press "enter" with the keyboard, you see a 'Invalid guess ""' error message,
-- I guess the popup is being closed, and then the enter key is being processed.
local alexgames = require("alexgames")
local words_lib  = require("libs/words")

local core      = require("games/word_mastermind/word_mastermind_core")
local draw      = require("games/word_mastermind/word_mastermind_draw")
local serialize = require("games/word_mastermind/word_mastermind_serialize")

local WORD_LEN    = 5
local MAX_GUESSES = 6

local SAVED_STATE_KEY = "word_mastermind_saved_state"
local SESSION_ID_KEY  = "word_mastermind_session_id"

local state = {
	session_id = nil,
}
state.ui_state   = draw.init()

function update(dt_ms)
	draw.draw_state(state.ui_state, state.game_state, dt_ms)
end

local function internal_draw_board(dt_ms)
	draw.draw_state(state.ui_state, state.game_state, dt_ms)
end

local function save_state(game_state)
	local serialized_state = serialize.serialize_state(game_state)
	alexgames.store_data(SAVED_STATE_KEY, serialized_state)
	alexgames.store_data(SESSION_ID_KEY, serialize.serialize_session_id(state.session_id))

	alexgames.save_state(state.session_id, serialized_state)
end

local function new_game(word)
	alexgames.set_status_msg("Starting new game")
	state.session_id = alexgames.get_new_session_id()
	state.game_state = core.new_game(WORD_LEN, MAX_GUESSES, word)
	save_state(state.game_state)
	draw.draw_state(state.ui_state, state.game_state, 0)
end

local function prompt_custom_puzzle()
	local msg = "Enter your own word to generate a puzzle.\n" ..
	            "Then you can either let a friend play on your device, " ..
	            "or send them a link by pressing \"share state\" in the " ..
	            "options menu."
	alexgames.prompt_string("Custom puzzle", msg)
end

function get_state()
	local serialized_state = serialize.serialize_state(state.game_state)
	local byteary = {}
	for i=1,#serialized_state do
		table.insert(byteary, string.byte(serialized_state:sub(i,i)))
	end
	return byteary
end


function get_init_state()
	local init_state = core.new_game(#state.game_state.word, state.game_state.max_guesses, state.game_state.word)
	local serialized_state = serialize.serialize_state(init_state)
	local byteary = {}
	for i=1,#serialized_state do
		table.insert(byteary, string.byte(serialized_state:sub(i,i)))
	end
	return byteary
end

	

function handle_user_string_input(str_input, is_cancelled)
	print(string.format("handle_user_string_input: %s, is_cancelled=%s", str_input, is_cancelled))
	local rc = core.validate_word(state.game_state, str_input)
	if rc ~= core.RC_SUCCESS then
		alexgames.set_status_err(string.format("Invalid word \"%s\": %s", str_input, core.rc_to_str(rc)))
		return
	end
	new_game(str_input)
	internal_draw_board(0)
end

function start_game(session_id, serialized_state)
	core.init_lib()
	if not core.dict_ready() then
		alexgames.set_status_msg("Waiting for dictionary to load... not starting game yet")
		return
	end

	-- if state wasn't passed via param, then check if it's stored in
	-- persistent storage
	if serialized_state == nil then
		-- TODO now that the get_last_session_id() API was introduced, I should use that instead
		session_id = serialize.deserialize_session_id(alexgames.read_stored_data(SESSION_ID_KEY))
		serialized_state = alexgames.read_stored_data(SAVED_STATE_KEY)
	end

	-- if we do have some saved state, then deserialize it.
	-- otherwise, start a new game
	if serialized_state ~= nil then
		state.session_id = session_id
		state.game_state = serialize.deserialize_state(serialized_state)
	else
		new_game()
	end

	alexgames.enable_evt("key")
end

local function handle_guess(guess)
	local rc = core.guess(state.game_state, guess)
	if rc == core.RC_SUCCESS then
		save_state(state.game_state)
		draw.clear_user_input(state.ui_state)
		local msg = string.format("User guessed \"%s\"", guess)
		if state.game_state.game_over then
			if core.user_won(state.game_state) then
				msg = msg .. string.format(", you win! Correct answer in %d guesses.", #state.game_state.guesses)
				draw.player_won(state.ui_state)
			else
				msg = msg .. string.format(", game over! Correct answer was \"%s\"", state.game_state.word)
			end
		end
		alexgames.set_status_msg(msg)
	else
		alexgames.set_status_err(string.format("Invalid guess \"%s\", %s", guess, core.rc_to_str(rc)))
	end
end

-- I guess at some point I supported this?
-- The user_string_input callback could really use an identifier to see what the purpose
-- of the string is.
-- For now I'm only using string input for generating custom puzzles.
--[[
function handle_user_string_input(user_line, is_cancelled)
	if not is_cancelled then
		local guess = user_line
		handle_guess(guess)
		draw.draw_state(state.ui_state, state.game_state, 0)
	end
end
--]]


function handle_user_clicked(pos_y, pos_x)
	local word = draw.handle_user_clicked(state.ui_state, state.game_state, pos_y, pos_x)
	if word then
		handle_guess(word)
	end
	draw.draw_state(state.ui_state, state.game_state, 0)
end

function handle_key_evt(evt_id, key_code)
	--print(string.format("handle_key_evt(%s, %s)", evt_id, key_code))
	local key_info = draw.handle_key_evt(state.ui_state, state.game_state, evt_id, key_code)
	if key_info.guess_word ~= nil then
		handle_guess(key_info.guess_word)
	end
	draw.draw_state(state.ui_state, state.game_state, 0)
	return key_info.handled
end

local function handle_action(action)
	if action == nil then
		-- do nothing
	elseif action == draw.ACTION_NEW_GAME then
		new_game()
		internal_draw_board(0)
	elseif action == draw.ACTION_CUSTOM_PUZZLE then
		prompt_custom_puzzle()
		-- TODO
	else
		error(string.format("Unhandled action %s", action))
	end
end

function handle_btn_clicked(btn_id)
	local action = draw.handle_btn_pressed(state.game_state, state.ui_state, btn_id)
	handle_action(action)
end

function handle_popup_btn_clicked(popup_id, btn_id)
	local action = draw.handle_popup_btn_pressed(state.game_state, state.ui_state, popup_id, btn_id)
	handle_action(action)
end
