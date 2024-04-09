
local draw = {}

local alexgames = require("alexgames")
local draw_more = require("libs/draw/draw_more")
local draw_celebration_anim = require("libs/draw/draw_celebration_anim")

local cell_size = 35

local MINE_COUNT_TO_IMG_ID_MAP = {
	[0] = 'minesweeper_box_empty',
	[1] = 'minesweeper_box1',
	[2] = 'minesweeper_box2',
	[3] = 'minesweeper_box3',
	[4] = 'minesweeper_box4',
	[5] = 'minesweeper_box5',
	[6] = 'minesweeper_box6',
	[7] = 'minesweeper_box7',
	[8] = 'minesweeper_box8',
}

local FLAGGED_TO_IMG_ID_MAP = {
	[1] = 'minesweeper_box_flagged_red',
	[2] = 'minesweeper_box_flagged_blue',
}

local BACKGROUND_COLOUR = '#bbbbbb'
local TEXT_COLOUR       = '#000000'
--local TEXT_BACKGROUND_COLOUR = '#ffffffbb'
local TEXT_BACKGROUND_COLOUR = '#bbbbbbbb'
local TEXT_FONT_SIZE    = 18

draw.draw_flag_flash = false

local board_width  = nil
local board_height = nil

local g_victory_anim_timer = nil
local anim_state = draw_celebration_anim.new_state({
})

local function cell_to_img_id(cell)
	if not cell.revealed then
		if cell.flagged_by_player == nil then
			return 'minesweeper_box_unclicked'
		else
			local flag_img = FLAGGED_TO_IMG_ID_MAP[cell.flagged_by_player]
			if flag_img == nil then
				error(string.format("flagged_by_player %s not found in map", cell.flagged_by_player)) 
			end
			return flag_img
		end
	elseif cell.has_mine then
		return 'minesweeper_mine'
	else
		local img_id = MINE_COUNT_TO_IMG_ID_MAP[cell.touching_mine_count]
		if img_id == nil then
			error(string.format("touching_mine_count %s not found in map", cell.touching_mine_count))
		end
		return img_id
	end
end

function draw.init(board_width_arg, board_height_arg, cell_size_arg)
	board_width  = board_width_arg
	board_height = board_height_arg
	cell_size    = cell_size_arg
end

function draw.update(dt_ms)
	draw_celebration_anim.update(anim_state, dt_ms/1000.0)
end

function draw.draw_state(state, player)
	alexgames.draw_clear()
	if state == nil or state.game == nil then
		return
	end
	alexgames.draw_rect(BACKGROUND_COLOUR, 0, 0, board_width, board_height)
	-- TODO only draw cells that are (partially or fully) visible
	for y, row in ipairs(state.game.board) do
		for x, cell in ipairs(row) do
			local offset_y = state.players[player].offset_y
			local offset_x = state.players[player].offset_x

			local pos_y = (y-1)*cell_size - offset_y
			local pos_x = (x-1)*cell_size - offset_x

			local zoom_fact = state.players[player].zoom_fact

			pos_y = math.floor(pos_y * zoom_fact)
			pos_x = math.floor(pos_x * zoom_fact)

			local actual_cell_size = math.floor(cell_size * zoom_fact)

			local in_range = true
			if pos_y + actual_cell_size <= 0 or
			   pos_x + actual_cell_size <= 0 or
			   pos_y >= board_height or
			   pos_x >= board_width then
				in_range = false
			end

			if in_range then
				draw_more.draw_graphic_ul(cell_to_img_id(cell),
				                        pos_y, pos_x,
				                        actual_cell_size, actual_cell_size)
			end
		end
	end

	local text_height = 30
	local player_text_width  = 165
	local text_padding = 10
	alexgames.draw_rect(TEXT_BACKGROUND_COLOUR,
	                     board_height - #state.players*text_height - text_padding,
	                     board_width  - player_text_width - text_padding,
	                     board_height, board_width)
	for i=0,#state.players-1 do
		local player_idx = #state.players - i
		alexgames.draw_text(string.format("Player %d: %4d", player_idx, state.players[player_idx].score),
		                     TEXT_COLOUR,
		                     board_height - i * text_height - text_padding,
							 board_width - text_padding,
		                     TEXT_FONT_SIZE,
		                     -1)
		                     
	end

	local mines_text_width = 115
	alexgames.draw_rect(TEXT_BACKGROUND_COLOUR,
	                     board_height - text_height - text_padding,
	                     0,
	                     board_height, mines_text_width + text_padding)
	alexgames.draw_text(string.format("Mines: %3d", state.game.mines_unrevealed),
	                     TEXT_COLOUR,
	                     board_height - text_padding,
	                     text_padding,
	                     TEXT_FONT_SIZE,
	                     alexgames.TEXT_ALIGN_LEFT)

	if draw.draw_flag_flash then
		alexgames.draw_rect('#ffffff88', 0, 0, 480, 480)
		draw.draw_flag_flash = false
	end
	draw_celebration_anim.draw(anim_state)
	alexgames.draw_refresh()
end

function draw.pos_to_cell_coords(state, player, pos_y, pos_x)
	local zoom_fact = state.players[player].zoom_fact
	return {
		y = 1 + math.floor((state.players[player].offset_y + pos_y/zoom_fact)/cell_size),
		x = 1 + math.floor((state.players[player].offset_x + pos_x/zoom_fact)/cell_size),
	}
end

function draw.victory_animation(fps)
	print("setting timer")
	if g_victory_anim_timer ~= nil then
		error(string.format("victory_animation: anim_timer is not nil"))
	end
	g_victory_anim_timer = alexgames.set_timer_update_ms(1000/fps)
	draw_celebration_anim.fireworks_display(anim_state, {
		colour_pref = "light",
		on_finish = function ()
			if g_victory_anim_timer == nil then
				alexgames.set_status_err("warning: g_victory_anim_timer is nil on anim complete")
			else
				alexgames.delete_timer(g_victory_anim_timer)
				g_victory_anim_timer = nil
			end
			--print("animation finished! Resuming timer")
			--alexgames.set_timer_update_ms(0)
			--alexgames.set_timer_update_ms(1000/60)
		end,
	})
end



return draw
