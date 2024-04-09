local alexgames = require("alexgames")

local core = require("games/crossword_builder/crossword_builder_core")
local draw = require("games/crossword_builder/crossword_builder_draw")

local touch_to_mouse_evts = require("libs/touch_to_mouse_evts")

local words_lib = require("libs/words")


local state = {
	game = core.new_state(1),
	touch_to_mouse_evts = nil,
	draw = nil,
}

local player_idx = 1


state.draw = draw.init(state.game)

--[[
table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx = 5, x_idx = 6 }, letter = "T" } )
table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx = 6, x_idx = 6 }, letter = "R" } )
table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx = 7, x_idx = 6 }, letter = "A" } )
table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx = 8, x_idx = 6 }, letter = "I" } )
table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx = 9, x_idx = 6 }, letter = "N" } )
table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx =10, x_idx = 6 }, letter = "E" } )
table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx =11, x_idx = 6 }, letter = "E" } )

local placed_tiles = draw.get_placed_tiles(state.draw)
local submit_info = core.submit(state.game, placed_tiles)
draw.update_state(state.draw, state.game)

table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx = 3, x_idx = 7 }, letter = "T" } )
table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx = 4, x_idx = 7 }, letter = "O" } )
table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx = 5, x_idx = 7 }, letter = "E" } )

local placed_tiles = draw.get_placed_tiles(state.draw)
local submit_info = core.submit(state.game, placed_tiles)
draw.update_state(state.draw, state.game)

table.insert(state.draw.tiles.placed_tiles, { pos = { grid_idx = 1, y_idx = 6, x_idx = 7 }, letter = "S" } )
--]]

function update()
	draw.draw(state.draw)
end

function handle_mouse_evt(evt_id, pos_y, pos_x, params)
	--print(string.format("handle_mouse_evt(evt_id=%s, pos_y=%d, pos_x=%d)", evt_id, pos_y, pos_x))
	draw.handle_mouse_evt(state.draw, evt_id, pos_y, pos_x, params)
	update()
end

function handle_mousemove(pos_y, pos_x, params)
	--print(string.format("handle_mousemove(pos_y=%d, pos_x=%d)", pos_y, pos_x))
	draw.handle_mousemove(state.draw, pos_y, pos_x, params)
	update()
end

function handle_touch_evt(evt_id, changed_touches)
	touch_to_mouse_evts.handle_touch_evt(state.touch_to_mouse_evts, evt_id, changed_touches)
end

function handle_btn_clicked(btn_id)
	print(string.format("handle_btn_clicked(id=%s)", btn_id))
	local action = draw.handle_btn_clicked(state.draw, btn_id)

	if action == draw.ACTION_SUBMIT then
		local placed_tiles = draw.get_placed_tiles(state.draw)
		local submit_info = core.submit(state.game, player_idx, placed_tiles)
		print(string.format("submit returned: %s, %d", submit_info, submit_info.rc))
		if submit_info.rc == core.RC_SUCCESS then
			alexgames.set_status_msg(string.format("Successfully formed words: %s", submit_info.word))
			draw.update_state(state.draw, state.game)
			draw.draw(state.draw)
		else
			local msg = core.submit_info_to_msg(submit_info)
			print("rc is not success... " .. msg)
			alexgames.set_status_err(msg)
		end
	end
end

function start_game()
	alexgames.enable_evt("mouse_updown")
	alexgames.enable_evt("mouse_move")
	state.touch_to_mouse_evts = touch_to_mouse_evts.init({
		handle_mouse_evt  = handle_mouse_evt,
		handle_mousemove  = handle_mousemove,
	})
end
