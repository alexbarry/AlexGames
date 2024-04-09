local alexgames = require("alexgames")
local cards = require("libs/cards/cards")

local core = {}

core.PICK_UP_EVT_ID  = 2
core.PUT_DOWN_EVT_ID = 1
core.MOVE_EVT_ID     = 3

-- when drawing a deck of cards, draw cards in `offset_count` distinct positions,
-- evenly distributed `offset_size` pixels away from the start.
local offset_count = 4
local offset_size = 8

function core.init(args)
	local state = {
		height = args.height,
		width  = args.width,
		reveal_area = args.reveal_area,

		card_height    = args.card_height,
		card_width     = args.card_width,


		player_states = {},

		cards = {},
	}

	for i=1,args.player_count do
		state.player_states[i] = {
			y = nil,
			x = nil,

			card_idx = nil,
			-- either the numeric ID of the touch, or 'mouse' for mouse
			input_src = nil,
			card_orig_y = nil,
			card_orig_x = nil,
		}
	end

	local deck = cards.new_deck()
	cards.shuffle(deck)

	for i, card in ipairs(deck) do
		local offset = math.floor(i*offset_count/#deck) * offset_size / offset_count
		state.cards[#state.cards+1] = {
			recvd = false,
			held_by = nil,
			revealed_to_all    = false,
			revealed_to_player = nil,
			card = card,
			y = math.floor(args.width/2 + offset),
			x = math.floor(args.height/2 - offset),
		}
	end
	return state
end


function core.find_card_under_cursor(state, pos_y, pos_x)
	for i=#state.cards,1,-1 do
		local card_info = state.cards[i]
		if card_info.y - state.card_height/2 <= pos_y and pos_y <= card_info.y + state.card_height/2 and
		   card_info.x - state.card_width/2  <= pos_x and pos_x <= card_info.x + state.card_width/2 then
			return i
		end
	end
	return nil
end

function core.in_revealed_area(state, pos_y, pos_x)
	if (0 <= pos_y and pos_y <= state.reveal_area) then
		return 2
	elseif (state.height - state.reveal_area <= pos_y and pos_y <= state.height) then
		return 1
	else
		return nil
	end
	       
end


local function player_move(state, player_idx, input_src, pos_y, pos_x)
	if not(1 <= player_idx and player_idx <= #state.player_states) then
		error("Invalid player_idx " .. player_idx)
	end
	local player_state = state.player_states[player_idx]
	player_state.y = pos_y
	player_state.x = pos_x
	if player_state.card_idx ~= nil and player_state.input_src == input_src then
		state.cards[player_state.card_idx].y = pos_y
		state.cards[player_state.card_idx].x = pos_x

		local reveal_player = core.in_revealed_area(state, pos_y, pos_x)
		state.cards[player_state.card_idx].revealed_to_player = reveal_player
		if reveal_player ~= nil then
			state.cards[player_state.card_idx].revealed_all = false
		end
	end
end

function core.handle_mousemove(state, player_idx, pos_y, pos_x)
	local input_src = 'mouse'
	player_move(state, player_idx, input_src, pos_y, pos_x)
end

local function touch_start_to_move(state, player_idx, input_src, pos_y, pos_x)
	local player_state = state.player_states[player_idx]
	local card_idx = core.find_card_under_cursor(state, pos_y, pos_x)
	if card_idx == nil then
		print(string.format("Player %d: Found no card at pos y=%f, x=%f", player_idx, pos_y, pos_x))
		return nil
	end
	if state.cards[card_idx].held_by ~= nil then
		print(string.format("Player %d: Card is already held by player %s", player_idx, 
			state.cards[card_idx].held_by))
		return nil
	end

	return { player = player_idx,
			 input_src = input_src,
	         move_type = core.PICK_UP_EVT_ID,
	         y = math.floor(pos_y),
	         x = math.floor(pos_x)
	}
end


local function pick_up_card(state, player_idx, input_src, pos_y, pos_x)
	local player_state = state.player_states[player_idx]
	local card_idx = core.find_card_under_cursor(state, pos_y, pos_x)
	if card_idx == nil then
		print(string.format("Player %d: Found no card at pos y=%f, x=%f", player_idx, pos_y, pos_x))
		return
	end
	if state.cards[card_idx].held_by ~= nil then
		print(string.format("Player %d: Card is already held by player %s", player_idx, 
			state.cards[card_idx].held_by))
		return
	end
	-- note that calling this with card_idx nil will remove the last card
	local tmp = table.remove(state.cards, card_idx)
	local old_card_idx = card_idx
	tmp.held_by = player_idx
	table.insert(state.cards, tmp)
	player_state.card_idx = #state.cards
	player_state.input_src = input_src
	player_state.card_orig_y = pos_y
	player_state.card_orig_x = pos_x
	if player_state.card_idx ~= nil then
		print(string.format("Player %d picked up card idx %d, input_src %s", player_idx, player_state.card_idx, input_src))
	end
	for i = 1, #state.player_states do
		if i == player_idx then
			goto next_player
		end
		if state.player_states[i].card_idx ~= nil and 
		   state.player_states[i].card_idx > old_card_idx then
			state.player_states[i].card_idx = state.player_states[i].card_idx - 1 
		end
		
		::next_player::
	end
end


local function touch_end_to_move(state, player_idx, touch_id, touch_y, touch_x)
	local move = {
		player = player_idx,
		move_type = core.PUT_DOWN_EVT_ID,
		input_src = touch_id,
		y = math.floor(touch_y),
		x = math.floor(touch_x) }
	return move
end

local function touch_move_to_move(state, player_idx, touch_id, touch_y, touch_x)
	local move = {
		player = player_idx,
		move_type = core.MOVE_EVT_ID,
		input_src = touch_id,
		y = math.floor(touch_y),
		x = math.floor(touch_x) }
	return move
end

local function put_down_card(state, player_idx, input_src, pos_y, pos_x)
	local player_state = state.player_states[player_idx]
	if player_state.card_idx ~= nil then
		print(string.format("Player %d Put down card, input_src %s", player_idx, player_state.card_idx, input_src))
		state.cards[player_state.card_idx].held_by = nil
	end

	-- if a card is held, it has not moved, and it is not in a revealed area,
	-- then reveal it to all if clicked
	if player_state.card_idx ~= nil and
	   -- TODO should change this to be a flag that is cleared once it has moved.
	   -- otherwise, if you move it to exactly the same position you took it from,
	   -- it would be revealed
	   pos_y == player_state.card_orig_y and pos_x == player_state.card_orig_x and
	   core.in_revealed_area(state, pos_y, pos_x) == nil then
	
		state.cards[player_state.card_idx].revealed_all = not state.cards[player_state.card_idx].revealed_all
	end
	player_state.card_idx = nil
	player_state.input_src = nil
end



function core.handle_mouse_evt(state, player_idx, evt_id, pos_y, pos_x)
	local input_src = 'mouse'
	if evt_id == 2 then
		pick_up_card(state, player_idx, input_src, pos_y, pos_x)
	elseif evt_id == 1 or
	       evt_id == 3 then
		put_down_card(state, player_idx, input_src, pos_y, pos_x)
	else
		error("Unhandled evt " .. evt_id)
	end
end


function core.touches_to_moves(state, player_idx, evt_id, changed_touches)
	local moves = {}
	local player_state = state.player_states[player_idx]
	if evt_id == 'touchstart' then
		for _, touch in ipairs(changed_touches) do
			local move = touch_start_to_move(state, player_idx, touch.id, touch.y, touch.x)
			table.insert(moves, move)
		end
	elseif evt_id == 'touchmove' then
		for _, touch in ipairs(changed_touches) do
			local move = touch_move_to_move(state, player_idx, touch.id, touch.y, touch.x)
			table.insert(moves, move)
		end
	elseif evt_id == 'touchend' or
	       evt_id == 'touchcancel' then
		for _, touch in ipairs(changed_touches) do
			local move = touch_end_to_move(state, player_idx, touch.id, touch.y, touch.x)
			table.insert(moves, move)
		end
	end
	return moves
end

function core.handle_touch_evt(state, player_idx, evt_id, changed_touches)
	local moves = core.touches_to_moves(state, player_idx, evt_id, changed_touches)
	for _, move in ipairs(moves) do
		if move.move_type == core.PICK_UP_EVT_ID then
			pick_up_card(state, move.player, move.input_src, move.y, move.x)
		elseif move.move_type == core.PUT_DOWN_EVT_ID then
			put_down_card(state, move.player, move.input_src, move.y, move.x)
		elseif move.move_type == core.MOVE_EVT_ID then
			player_move(state, move.player, move.input_src, move.y, move.x)
		else
			error(string.format("Unhandled move type %s", move.move_type))
		end
	end
end

return core
