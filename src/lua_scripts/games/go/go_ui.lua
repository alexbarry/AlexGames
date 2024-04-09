local go_ui = {}
local go    = require("games/go/go_core")
local draw_more = require("libs/draw/draw_more")
local alexgames = require("alexgames");

local board_line_size = 2

local board_size = nil
local height = nil
local width = nil
local piece_space_size = nil
local board_piece_size = nil

go_ui.BTN_ID_UNDO = "undo"
go_ui.BTN_ID_REDO = "redo"
go_ui.BTN_ID_PASS = "pass"

local function update_undo_redo_btns(session_id)
	alexgames.set_btn_enabled(go_ui.BTN_ID_UNDO, alexgames.has_saved_state_offset(session_id, -1))
	alexgames.set_btn_enabled(go_ui.BTN_ID_REDO, alexgames.has_saved_state_offset(session_id,  1))
end

function go_ui.get_board_piece_size()
	return board_piece_size
end

function go_ui.set_board_piece_size(board_piece_size_arg)
	board_piece_size = board_piece_size_arg
	piece_space_size = board_size*1.0/(board_piece_size+1)
end

function go_ui.init_ui(session_id, board_piece_size_arg, screen_width, screen_height)
	board_size = math.min(screen_width, screen_height)
	height = screen_height
	width  = screen_width
	go_ui.set_board_piece_size(board_piece_size_arg)

	alexgames.create_btn(go_ui.BTN_ID_UNDO, "Undo", 1)
	alexgames.create_btn(go_ui.BTN_ID_REDO, "Redo", 1)
	alexgames.create_btn(go_ui.BTN_ID_PASS, "Pass", 2)
	alexgames.set_btn_enabled(go_ui.BTN_ID_UNDO, false)
	alexgames.set_btn_enabled(go_ui.BTN_ID_REDO, false)

	update_undo_redo_btns(session_id)
end

function go_ui.draw_board(session_id, board, last_y, last_x)

	alexgames.draw_clear()

	draw_more.draw_graphic_ul("board", 0, 0, board_size, board_size)

	local piece_size = piece_space_size*0.90
	piece_size = math.floor(piece_size)

	for i=0, board_piece_size-1 do
		local y1 = piece_space_size
		local y2 = board_size - piece_space_size
		local x1 = piece_space_size*(i+1)
		local x2 = x1
		alexgames.draw_line("#000000", board_line_size, y1, x1, y2, x2)
	end

	for i=0, board_piece_size-1 do
		local x1 = piece_space_size
		local x2 = board_size - piece_space_size
		local y1 = piece_space_size*(i+1)
		local y2 = y1
		alexgames.draw_line("#000000", board_line_size, y1, x1, y2, x2)
	end

	for y_idx=0, board_piece_size-1 do
		for x_idx=0, board_piece_size-1 do
			local y_pos = piece_space_size/2 + y_idx * piece_space_size
			local x_pos = piece_space_size/2 + x_idx * piece_space_size
			local img_id = nil
			if y_idx > #board or x_idx > #board[1] then
				error(string.format("draw_board: {y=%d, x=%d} out of range of board size {y=%d,x=%d}", y_idx+1, x_idx+1, #board, #board[1]))
			end
			local piece_type = board[y_idx+1][x_idx+1]
			-- TODO replace 1 and 2 with go.PLAYER1 and go.PLAYER2
			if piece_type == go.PLAYER1 then
				img_id = "piece_black"
			elseif piece_type == go.PLAYER2 then
				img_id = "piece_white"
			end
			if img_id ~= nil then
				draw_more.draw_graphic_ul(img_id, y_pos, x_pos, math.floor(piece_size), math.floor(piece_size))
			end


			if y_idx+1 == last_y and x_idx+1 == last_x then
				draw_more.draw_graphic_ul("piece_highlight", y_pos, x_pos, math.floor(piece_size), math.floor(piece_size))
			end
		end
	end

	alexgames.draw_refresh()
	update_undo_redo_btns(session_id)
end

function go_ui.user_pos_to_piece_idx(pos_y, pos_x)
	local y_idx = math.floor((pos_y - piece_space_size/2)/piece_space_size) + 1
	local x_idx = math.floor((pos_x - piece_space_size/2)/piece_space_size) + 1
	local to_return = {
		y = y_idx,
		x = x_idx
	}
	return to_return
end

return go_ui
