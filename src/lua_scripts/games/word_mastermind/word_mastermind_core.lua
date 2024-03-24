local core = {}

local words_lib = require("libs/words")

local LANGUAGE = "en" -- TODO get from state

core.LETTER_UNUSED          = 1
core.LETTER_PRESENT_IN_WORD = 2
core.LETTER_PRESENT_IN_POS  = 3
core.LETTER_UNKNOWN         = 4

core.RC_SUCCESS         =  0
core.RC_WRONG_GUESS_LEN = -1
core.RC_NOT_VALID_WORD  = -2

VALID_GUESS_FREQ       = 1e-8
VALID_SECRET_WORD_FREQ = 1e-6

local ERR_MSGS = {
	[core.RC_WRONG_GUESS_LEN] = "Guess not correct length",
	[core.RC_NOT_VALID_WORD]  = "Guess is not in dictionary",
}

function core.dict_ready()
	return words_lib.is_ready()
end

function core.rc_to_str(rc)
	return ERR_MSGS[rc]
end

local function get_random_word(len)
	return words_lib.get_random_word(LANGUAGE, VALID_SECRET_WORD_FREQ, len)
end

local function get_possib_word_count(len)
	return words_lib.get_possib_word_count(LANGUAGE, VALID_SECRET_WORD_FREQ, len)
end


local function is_valid_word(word)
	return words_lib.is_valid_word(LANGUAGE, word)
end

function core.init_lib()
	words_lib.init(LANGUAGE)
end

function core.new_game(word_len, max_guesses, word)
	local state = {
		word_len       = word_len,
		max_guesses    = max_guesses,
		possible_words = nil,
		word           = nil,
		guesses        = {},
		letter_states  = {},
		game_over      = false,
	}
	if word == nil then
		--print(string.format("Got random word: %q", state.word))
		state.word = get_random_word(word_len)
	else
		word = string.lower(word)
		state.word = word
	end
	state.possible_words = get_possib_word_count(word_len)

	print(string.format("There are %d possible words of length %d in this dictionary",
	                    state.possible_words, word_len))

	return state
end

local function get_word_letter_scores(answer, guess)
	local word_len = #answer
	if #guess ~= word_len then
		error("answer and guess must have some number of letters", 2)
	end
	local letter_scores = {}
	for _=1,word_len do
		table.insert(letter_scores, core.LETTER_UNUSED)
	end

	local answer_letter_counts = {}
	for i=1,word_len do
		if answer:sub(i,i) == guess:sub(i,i) then
			letter_scores[i] = core.LETTER_PRESENT_IN_POS
		else
			if answer_letter_counts[answer:sub(i,i)] == nil then
				answer_letter_counts[answer:sub(i,i)] = 0
			end
			answer_letter_counts[answer:sub(i,i)] = answer_letter_counts[answer:sub(i,i)] + 1
		end
	end

	for i=1,word_len do
		if answer:sub(i,i) ~= guess:sub(i,i) then
			local count = answer_letter_counts[guess:sub(i,i)]
			if count ~= nil and count > 0 then
				letter_scores[i] = core.LETTER_PRESENT_IN_WORD
				answer_letter_counts[guess:sub(i,i)] = answer_letter_counts[guess:sub(i,i)] - 1
			end
		end
	end

	return letter_scores
end


local function update_letter_states(state, guess, letter_scores)
	local word_len = #guess
	for i=1,word_len do
		local c = guess:sub(i,i)
		local c_score = letter_scores[i]
		if state.letter_states[c] == core.LETTER_PRESENT_IN_POS then
			goto next_letter
		end

		if c_score == core.LETTER_PRESENT_IN_POS then
			state.letter_states[c] = core.LETTER_PRESENT_IN_POS
		elseif c_score == core.LETTER_PRESENT_IN_WORD then
			state.letter_states[c] = core.LETTER_PRESENT_IN_WORD
		end

		if state.letter_states[c] ~= core.LETTER_PRESENT_IN_WORD then
			if c_score == core.LETTER_UNUSED then
				state.letter_states[c] = core.LETTER_UNUSED
			end
		end
		::next_letter::
	end
end

function core.validate_word(state, word_input)
	local word_len = #state.word
	if #word_input ~= word_len then
		print(string.format("Guess length is %d, need length %d", #word_input, word_len))
		return core.RC_WRONG_GUESS_LEN
	end

	if not is_valid_word(word_input) then
		return core.RC_NOT_VALID_WORD
	end

	return core.RC_SUCCESS
end

-- like the normal "guess" call that a player would call, but
-- without any dictionary checks. This is for loading games from save state.
function core.force_guess(state, guess)
	local letter_scores = get_word_letter_scores(state.word, guess)

	update_letter_states(state, guess, letter_scores)

	table.insert(state.guesses, {
		word  = guess,
		score = letter_scores,
	})

	if state.word == guess or
	   #state.guesses >= state.max_guesses then
		state.game_over = true
	end
end

-- This is what players should call when making a guess (with a full word).
function core.guess(state, guess)

	local rc = core.validate_word(state, guess)
	if rc ~= core.RC_SUCCESS then
		return rc
	end

	-- TODO add the option to only allow words that fit
	-- the existing knowledge?

	core.force_guess(state, guess)

	return core.RC_SUCCESS
end

function core.user_won(state, guess)
	return #state.guesses > 0 and state.guesses[#state.guesses].word == state.word
end

local function print_state_pretty(state)
	for guess_idx=1,state.max_guesses do
		if guess_idx <= #state.guesses then
			local guess = state.guesses[guess_idx]
			for i=1,state.word_len do
				if guess.score[i] == core.LETTER_PRESENT_IN_WORD then
					io.write("\27[43;30m")
				elseif guess.score[i] == core.LETTER_PRESENT_IN_POS then
					io.write("\27[42;30m")
				end
				local c = guess.word:sub(i,i)
				io.write(" " .. c .. " ")
				io.write("\27[0m")
				io.write(" ")
			end
			io.write("\n")
		else
			for i=1,state.word_len do
				io.write("___ ")
			end
			io.write("\n")
		end
	end

	print("")

	local keyboard = {
		"qwertyuiop",
		"asdfghjkl",
		"zxcvbnm",
	}

	for row_idx, keyboard_row in ipairs(keyboard) do
		for i=0,row_idx-2 do
			io.write(" ")
		end
		for i=1,#keyboard_row do
			local c = keyboard_row:sub(i,i)
			local key_state = state.letter_states[c]
			if key_state == core.LETTER_PRESENT_IN_WORD then
				io.write("\27[43;30m")
			elseif key_state == core.LETTER_PRESENT_IN_POS then
				io.write("\27[42;30m")
			elseif key_state == core.LETTER_UNUSED then
				c = ' '
			end
			io.write(c)
			io.write("\27[0m")
			io.write(" ")
		end
		io.write("\n")
	end
end

local function example_main_loop()
	local word_len    = 5
	local max_guesses = 6

	local state = core.new_game(word_len, max_guesses)

	while true do
		::new_guess::
		io.write("Enter a guess: ")
		local guess = io.read("*l")
		guess = guess:gsub("%s+", "")
		io.write("\n\n")
	
		local rc = core.guess(state, guess)
		if rc ~= core.RC_SUCCESS then
			--print(string.format("Error %d", rc))
			print(core.rc_to_str(rc))
			goto new_guess
		end

		print_state_pretty(state)

		if state.game_over then
			if state.guesses[#state.guesses].word ~= state.word then
				print(string.format("Game over! The word was \"%s\"", state.word))
			else
				print(string.format("You guessed the word in %d guesses.", #state.guesses))
			end
			break
		end
	end


end

-- example_main_loop()

--local scores = get_word_letter_scores("crane", "creep")
--for i, score in ipairs(scores) do
--	print(string.format("%d: %s", i, score))
--end

return core
