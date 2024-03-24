-- Crossword letters
-- Author: Alex Barry (github.com/alexbarry)
--
-- TODO:
--     * user still needs to enter words that were revealed completely by hints...
--       should automatically add word to "found words" if it was revealed with hints.
--       Make sure to check for the win condition in that case, too.
--
local alex_c_api  = require("alex_c_api")
local alex_dict   = require("alex_c_api.dict")

local core    = require("games/crossword_letters/crossword_letters_core")
local draw    = require("games/crossword_letters/crossword_letters_draw")
local puzzles = require("games/crossword_letters/crossword_letters_puzzles")
local serialize = require("games/crossword_letters/crossword_letters_serialize")
local show_buttons_popup = require("libs/ui/show_buttons_popup")

local PUZZLE_IDX_KEY = "crossword_letters_puzzle_idx"
local OLD_SAVED_STATE_KEY = "crossword_letters_state"

local GAME_OPTION_RESET_PUZZLE = "opt_reset_puzzle"

local POPUP_ID_RESET_PUZZLE_CONFIRM = "popup_id_reset_puzzle"

local state = {
	game_state = nil,
	ui_state   = nil,
}

-- TODO clean this up
state.ui_state   = draw.init({
	num_puzzles  = #puzzles.puzzles,
})

local function get_words(query)
	--print(query)
	local word_info = alex_dict.get_words(query, LANGUAGE)
	local words = {}
	for _, info in ipairs(word_info) do
		table.insert(words, info[1])
	end
	--print(string.format("found %d words", #words))
	return words
end

core.set_get_words_func(get_words)

local function get_saved_state_key(puzzle_id)
	if puzzle_id == nil then error("puzzle_id is nil", 2) end
	return string.format("crossword_letters_state_%04d", puzzle_id)
end

function draw_board()
	draw.draw_state(state.ui_state, state.game_state)
	update_saved_state()
end

function update_saved_state()
	if state.game_state == nil then return end
	local serialized_state = serialize.serialize_state(state.game_state)
	alex_c_api.store_data(PUZZLE_IDX_KEY, tostring(state.game_state.puzzle_id))
	alex_c_api.store_data(get_saved_state_key(state.game_state.puzzle_id), serialized_state)
end

local function str_list_to_str(str_list)
	local output = "{"
	for i, s in ipairs(str_list) do
		if i ~= 1 then
			output = output .. ", "
		end
		output = output .. s
	end
	return output .. "}"
end

local function new_puzzle(puzzle_id)
	print("Starting to generate game")
	local params = {
		min_word_len  = 3,
		min_word_freq = 1e-6,
		crossword_height = 12,
		crossword_width  = 12,
	}


	if puzzle_id == nil then
		puzzle_id = math.random(1, #puzzles.puzzles)
	end
	state.game_state = core.new_game_from_pregen_puzzle(puzzle_id, puzzles.puzzles[puzzle_id], params)
	draw.draw_state(state.ui_state, state.game_state)
	local letters_list_str = str_list_to_str(state.game_state.letters)
	alex_c_api.set_status_msg(string.format("Starting new game with letters: %s", letters_list_str))
	--update_saved_state()
end

local function str_array_eq(arr1, arr2)
	if #arr1 ~= #arr2 then return false end
	for i=1,#arr1 do
		if arr1[i] ~= arr2[i] then
			return false
		end
	end
	return true
end

local function find_puzzle_id(puzzles, game_state)
	for puzzle_id, puzzle in ipairs(puzzles) do
		if str_array_eq(game_state.letters, puzzle.letters) then
			return puzzle_id
		end
	end
	return nil
end

local function switch_puzzle(puzzle_id)
	local serialized_state = alex_c_api.read_stored_data(get_saved_state_key(puzzle_id))

	if serialized_state == nil then
		new_puzzle(puzzle_id)
	else
		state.game_state = serialize.deserialize_state(serialized_state)
	end

	print("Done generating game")

	draw.draw_state(state.ui_state, state.game_state)
	update_saved_state()
	print("Done drawing state")

end

function get_state()
	return serialize.serialize_state(state.game_state)
end

function start_game(session_idx, serialized_state)
	local puzzle_idx_serialized = alex_c_api.read_stored_data(PUZZLE_IDX_KEY)

	if serialized_state ~= nil then
		state.game_state = serialize.deserialize_state(serialized_state)
	elseif puzzle_idx_serialized == nil then

		-- TODO BEFORE PUBLISHING remove
		serialized_state = alex_c_api.read_stored_data(OLD_SAVED_STATE_KEY)

		-- legacy state, TODO BEFORE PUBLISHING remove
		if serialized_state ~= nil then
			state.game_state = serialize.deserialize_state(serialized_state)
	
			-- TODO BEFORE PUBLISHING remove this. Puzzle ID should be stored in the state.
			if state.game_state.puzzle_id == nil then
				state.game_state.puzzle_id = find_puzzle_id(puzzles.puzzles, state.game_state)
			end
	
			if state.game_state.puzzle_id ~= nil then
				alex_c_api.store_data(get_saved_state_key(state.game_state.puzzle_id), serialized_state)
			end
		-- no previous state
		else
			switch_puzzle(1)
		end
	else
		print(string.format("puzzle_idx_serialized is %s", puzzle_idx_serialized))
		local puzzle_id = tonumber(puzzle_idx_serialized)
		switch_puzzle(puzzle_id)
	end

	alex_c_api.set_status_msg("Come up with as many words as you can, using the provided letters. " ..
	                          "They should fit into the crossword. If you get stuck, press the " ..
	                          "\"hint\" button to reveal a letter.")
	alex_c_api.enable_evt("key")

	alex_c_api.add_game_option(GAME_OPTION_RESET_PUZZLE, { label = "Reset puzzle", type = alex_c_api.OPTION_TYPE_BTN })
end

function handle_game_option_evt(option_id)
	if option_id == GAME_OPTION_RESET_PUZZLE then
		show_buttons_popup.show_popup(POPUP_ID_RESET_PUZZLE_CONFIRM,
                              "Reset puzzle?",
                              "Are you sure you want to reset this puzzle?",
                              { "Cancel", "Reset Puzzle" })

	else
		error(string.format("Unhandled game option id = \"%s\"", option_id))
	end
end

local function get_hint_status_str(game_state)
	if #game_state.hint_letters == 0 then
		return "no hints"
	else
		return string.format("%d hints", #game_state.hint_letters)
	end
end

local function handle_submit()
	local word = draw.get_word(state.ui_state)
	local rc = core.word_input(state.game_state, word)
	if rc == core.RC_SUCCESS then
		local msg = string.format("Revealed word \"%s\" in puzzle.", string.lower(word))
		alex_c_api.set_status_msg(msg)
		if state.game_state.finished then
			local hint_status_str = get_hint_status_str(state.game_state)
			alex_c_api.set_status_msg(string.format("Congratulations! You win, with %s. Press the '>' button at the top right to switch to the next puzzle.", hint_status_str))
			draw.player_won(state.ui_state)
		end
	else
		local msg = string.format("Word \"%s\": %s", string.lower(word), core.rc_to_msg(rc))
		alex_c_api.set_status_err(msg)
	end
	draw.clear_input(state.ui_state)
	draw.draw_state(state.ui_state, state.game_state)
	update_saved_state()
end

function handle_key_evt(evt_id, key_code)
	if evt_id == "keydown" then
		if key_code == "Enter" then
			print("User pressed enter")
			handle_submit()
		elseif key_code == "Backspace" then
			draw.backspace(state.ui_state)
			draw.draw_state(state.ui_state, state.game_state)
		else
			local m = string.match(key_code, "Key(%a)")
			if m == nil then 
				print(string.format("Unrecognized key_code %s", key_code))
				return
			end
			local letter = m
			print(string.format("User pressed letter %q", letter))
			local rc = draw.input_letter(state.ui_state, state.game_state, letter)
			if rc ~= core.RC_SUCCESS then
				local msg = string.format("Letter \"%s\": %s", letter, core.rc_to_msg(rc))
				alex_c_api.set_status_err(msg)
			end
			draw.draw_state(state.ui_state, state.game_state)
		end
	end
end

function handle_btn_clicked(btn_id)
	print(string.format("handle_btn_clicked(id=%s)", btn_id))
	local action = draw.handle_btn_clicked(state.ui_state, btn_id)

	if action == draw.ACTION_SUBMIT then
		handle_submit()
	elseif action == draw.ACTION_HINT then
		core.hint(state.game_state)
	end
	draw.draw_state(state.ui_state, state.game_state)
	update_saved_state()
end

function handle_popup_btn_clicked(popup_id, btn_id)
	print(string.format("handle_popup_btn_clicked(popup_id=%s, btn_id=%s)", popup_id, btn_id))
	if popup_id == POPUP_ID_RESET_PUZZLE_CONFIRM then
		if btn_id == 0 then
			alex_c_api.hide_popup()
			-- do nothing
		elseif btn_id == 1 then
			alex_c_api.hide_popup()
			new_puzzle(state.game_state.puzzle_id)
		end
	end
end

function handle_user_clicked(pos_y, pos_x)
	local action = draw.handle_user_clicked(state.ui_state, state.game_state, pos_y, pos_x)
	if action == nil then
		-- do nothing
	elseif action == draw.ACTION_PREV_PUZZLE then
		local puzzle_id = state.game_state.puzzle_id
		puzzle_id = puzzle_id - 1
		if puzzle_id < 1 then puzzle_id = 1 end
		switch_puzzle(puzzle_id)
	elseif action == draw.ACTION_NEXT_PUZZLE then
		local puzzle_id = state.game_state.puzzle_id
		puzzle_id = puzzle_id + 1
		if puzzle_id > #puzzles.puzzles then puzzle_id = #puzzles.puzzles end
		switch_puzzle(puzzle_id)
	else
		error(string.format("Unhandled action ID %s", action))
	end
	draw.draw_state(state.ui_state, state.game_state)
	update_saved_state()
end
