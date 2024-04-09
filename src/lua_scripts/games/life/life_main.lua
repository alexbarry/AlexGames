local life_core = require("games/life/life_core")
local life_draw = require("games/life/life_draw")
local alexgames = require("alexgames")

local BTN_ID_TOGGLE_PLAY_PAUSE = "toggle_play_pause"
local BTN_ID_STEP              = "step"
local BTN_ID_RANDOM            = "random"
local BTN_ID_CLEAR             = "clear"

local cell_size = 10
local board_width = 480
local board_height = 480
--local cells_y = 40
--local cells_x = 30
local cells_y = math.floor(board_height/cell_size)
local cells_x = math.floor(board_width/cell_size)

local state = nil
local is_drawing = true

function draw_board_internal()
	life_core.update_state(state)
	life_draw.update(life_core.get_active_board(state))
end

function update()
	if is_drawing then
		draw_board_internal()
	end
end

function handle_user_clicked(y_coords, x_coords)
	local cell_pos = life_draw.coords_to_cell_idx(y_coords, x_coords)
	life_core.toggle_cell_state(state, cell_pos)
	life_draw.update(life_core.get_active_board(state))
end

function handle_btn_clicked(btn_id)
	if btn_id == BTN_ID_STEP then
		life_core.update_state(state)
		life_draw.update(life_core.get_active_board(state))
	elseif btn_id == BTN_ID_TOGGLE_PLAY_PAUSE then
		is_drawing = not is_drawing
	elseif btn_id == BTN_ID_RANDOM then
		life_core.random_board(state)
		life_draw.update(life_core.get_active_board(state))
	elseif btn_id == BTN_ID_CLEAR then
		life_core.clear_board(state)
		life_draw.update(life_core.get_active_board(state))
	else
		print(string.format("Unhandled btn_id \"%s\"", btn_id))
	end
end

function get_state()
	-- TODO it wouldn't be unreasonable to implement importing/exporting state for this, but
	-- since it's more of a tech demo than a game, I don't want to bother
	-- with it right now.
	return nil
end

life_draw.init(cell_size)

function start_game()
	alexgames.create_btn(BTN_ID_TOGGLE_PLAY_PAUSE, "Play/pause", 1)
	alexgames.create_btn(BTN_ID_STEP,              "Step",       1)
	alexgames.create_btn(BTN_ID_RANDOM,            "Random",     1)
	alexgames.create_btn(BTN_ID_CLEAR,             "Clear",      1)
	
	state = life_core.new_state(cells_y, cells_x)
	
	alexgames.set_timer_update_ms(math.floor(1000/20))
end
