local core = {}

local shuffle = require("libs/shuffle")

core.PIECE_EMPTY = 0

core.PIECES = {
	["white" ]    = 1,
	["black" ]    = 2,
	["red"   ]    = 3,
	["yellow"]    = 4,
	["blue"  ]    = 5,
}

core.PIECE_COLOUR_COUNT     = 5
core.PIECE_PER_COLOUR_COUNT = 20
core.PIECES_PER_PILE        = 4

-- Passed as an argument to core.place_piece to indicate
-- that the player is selecting from the discard pile
core.PILE_DISCARD = -1

core.RC_SUCCESS      = 0
core.RC_ROW_OCCUPIED = 1

function core.rc_to_string(rc)
	local MAP = {
		[core.RC_SUCCESS]      = "Success",
		[core.RC_ROW_OCCUPIED] = "This row already contains a different colour piece",
	}
	return MAP[rc]
end

function core.get_card_piece_type(y, x)
	return 1 + ((y-1 + -x ) % core.PIECE_COLOUR_COUNT)
end

local function get_num_piles(num_players)
	local MAP = {
		[2] = 5,
		[3] = 7,
		[4] = 9,
	}
	return MAP[num_players]
end

function core.new_game(num_players)
	local state = {
		pieces = {},
		piles = {},
		discard_penalty = true,
		discard_pile = {},
		player_states = {},
	}

	for _, piece_colour in pairs(core.PIECES) do
		for _=1,core.PIECE_PER_COLOUR_COUNT do
			table.insert(state.pieces, piece_colour)
		end
	end
	shuffle.shuffle(state.pieces)

	for pile_idx=1,get_num_piles(num_players) do
		state.piles[pile_idx] = {}
		for i=1,core.PIECES_PER_PILE do
			local piece = table.remove(state.pieces)
			table.insert(state.piles[pile_idx], piece)
		end
	end

	for i=1,num_players do
		state.player_states[i] = {
			score   =  0,
			staging = {},
			card    = {},
		}

		for y=1,core.PIECE_COLOUR_COUNT do
			state.player_states[i].staging[y] = { colour = nil, count = 0 }
			state.player_states[i].card[y] = {}
			for x=1,core.PIECE_COLOUR_COUNT do
				state.player_states[i].card[y][x] = core.PIECE_EMPTY
			end
		end

		
	end

	return state
end

function core.can_place_piece(state, player, selected_pile, selected_piece_colour, dst_row)
	local staging_row = state.player_states[player].staging[dst_row]
	return staging_row.count == 0 or 
	       (staging_row.colour == selected_piece_colour and staging_row.count < dst_row)
end

function core.place_piece(state, player, selected_pile, selected_piece_colour, dst_row)
	print(string.format("place_piece(player=%s, selected_pile=%s, selected_colour=%s, dst_row=%s)",
	                    player, selected_pile, selected_piece_colour, dst_row))
	if not core.can_place_piece(state, player, selected_pile, selected_piece_colour, dst_row) then
		return core.RC_ROW_OCCUPIED
	end

	local penalty = 0
	local pile
	if selected_pile == core.PILE_DISCARD then
		pile = state.discard_pile
		if state.discard_penalty then
			-- TODO handle discard penalty
			penalty = -1
			state.discard_penalty = false
		end
	else
		pile = state.piles[selected_pile]
		state.piles[selected_pile] = nil
	end
	local pieces_to_move = {}
	local pieces_to_discard = {}
	for _, piece in ipairs(pile) do
		if piece == selected_piece_colour then
			table.insert(pieces_to_move, piece)
		else
			table.insert(pieces_to_discard, piece)
		end
	end

	if pile == state.discard_pile then
		state.discard_pile = {}
	end

	for _, piece in ipairs(pieces_to_discard) do
		table.insert(state.discard_pile, piece)
	end

	local staging = state.player_states[player].staging
	-- TODO handle putting too many in staging area
	staging[dst_row].colour = pieces_to_move[1]
	staging[dst_row].count  = staging[dst_row].count + #pieces_to_move

	return core.RC_SUCCESS
end

return core
