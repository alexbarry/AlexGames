
local core = require("games/sudoku/sudoku_core")
local draw = require("games/sudoku/sudoku_draw")

local ui_state = draw.init(480, 480)
local state = core.new_game()

function update()
	draw.draw_state(state, ui_state)
end

function handle_user_clicked(pos_y, pos_x)
	local cell = draw.get_cell_coords(pos_y, pos_x)
	if cell ~= nil then
		print("user clicked: " .. cell.y .. ", " .. cell.x)
		draw.handle_user_sel(ui_state, cell)
	end


	local num_choice = draw.get_num_choice(ui_state, pos_y, pos_x)
	if num_choice ~= nil and ui_state.selected ~= nil then
		print("user chose ", num_choice)
		core.user_enter(state, ui_state.selected.y, ui_state.selected.x, num_choice)
	end

	update()
	
end

function start_game()
end
