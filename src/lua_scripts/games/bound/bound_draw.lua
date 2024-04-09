local draw = {}

local core       = require("games/bound/bound_core")
local alexgames = require("alexgames")
local draw_more = require("libs/draw/draw_more")

draw.INPUT_TYPE_KEYBOARD = 1
draw.INPUT_TYPE_TOUCH    = 2

local ANIM_TYPE_FLOAT_TEXT = 1

local TIME_LEFT_BG_COLOUR      = '#66666666'
local TIME_LEFT_FG_GOOD_COLOUR = '#008800aa'
local TIME_LEFT_FG_MED_COLOUR  = '#ffff00ff'
local TIME_LEFT_FG_BAD_COLOUR  = '#ff0000ff'
local TIME_LEFT_FG_BAD_COLOUR2 = '#bb5500ff'

local FIX_TIME_PROGRSS_BAR_BG_COLOUR = '#66ff6666'
local FIX_TIME_PROGRSS_BAR_FG_COLOUR = '#22ff22cc'

local HIGHLIGHT_COLOUR     = '#ffff00'
local CONTROLS_TEXT_COLOUR = '#000000'
local CONTROLS_TEXT_SIZE = 12

local TIME_LEFT_ICON_WIDTH = 10
local PADDING = 3

local PLAYER_HIGHLIGHT_COLOURS = {
	{ fill = "#20a4a966", stroke = "#0000ff99" },
	{ fill = "#a72ea566", stroke = "#ff008899" },
	{ fill = "#774a1e66", stroke = "#f7aa5e99" },
	{ fill = "#c5202066", stroke = "#ff000099" },
}

local animations = {}

local highlight_line_size = 5

local TILE_SIZE = 25
local SCREEN_ORIGIN = {
	y = 480/2,
	x = 480/2,
}

local draw_pt_order = nil

local UI_PADDING = 10
local DIRPAD_SIZE = 170
local DIRPAD_SIZE_Y = DIRPAD_SIZE
local DIRPAD_SIZE_X = DIRPAD_SIZE
local dirpad_pos_y  = nil
local dirpad_pos_x  = nil

local THUMB_BUTTONS_SIZE = 150
local THUMB_BUTTONS_SIZE_Y = THUMB_BUTTONS_SIZE
local THUMB_BUTTONS_SIZE_X = THUMB_BUTTONS_SIZE
local thumb_buttons_pos_y = nil
local thumb_buttons_pos_x = nil

local screen_width  = nil
local screen_height = nil



local function point(y, x)
	return { y = y, x = x }
end

-- "cart" (cartesian) meaning the game space, convert it to
-- an isometric grid (how it's drawn)
local function cart_to_iso(pt)
    local x = (pt.x - pt.y)
    local y = (pt.x + pt.y)/2
    return point(y,x)
end

local function iso_to_cart(pt)
    local x = (2*pt.y + pt.x)/2
    local y = (2*pt.y - pt.x)/2
    return point(y,x)
end

local function game_pt_to_gfx_pt(pt, ui_state)
	if pt.x == nil or pt.y == nil then
		error("nil pt.x or y", 2)
	end
	pt = point(pt.y, pt.x)
	pt.y = pt.y + ui_state.offset_y
	pt.x = pt.x + ui_state.offset_x
    pt = point(pt.y*TILE_SIZE, pt.x*TILE_SIZE)
    pt = cart_to_iso(pt)
    pt = point(pt.y + SCREEN_ORIGIN.y, pt.x + SCREEN_ORIGIN.x)
    return pt
end

local function get_doctor_img_id(player_idx)
	local map = {
		[1] = 'hospital_doctor1',
		[2] = 'hospital_doctor2',
		[3] = 'hospital_doctor3',
		[4] = 'hospital_doctor4',
	}
	local img_id = map[player_idx]
	if img_id == nil then
		error(string.format("Could not find doctor img_id for %d", player_idx))
	end
	return img_id
end

local function generate_draw_pt_order(y_size, x_size)
--[[
	local pt_order = {}
	for y=0,y_size-1 do
		local x = 0
		while y >= 0 and x < x_size do
			table.insert(pt_order, { y = y, x = x })
			y = y - 1
			x = x + 1
		end
	end

	for x=0,x_size-1 do
		local y = y_size-1
		while y >= 0 and x < x_size do
			table.insert(pt_order, { y = y, x = x })
			y = y - 1
			x = x + 1
		end
	end
	return pt_order
]]--

	local pt_order = {}
	for y=1,y_size do
		for x=1, x_size do
			table.insert(pt_order, {y=y, x=x})
		end
	end
	return pt_order
end

function draw.init(width, height, game_params)

	screen_width  = width
	screen_height = height

	thumb_buttons_pos_y = height - THUMB_BUTTONS_SIZE_Y - UI_PADDING
	thumb_buttons_pos_x = width  - THUMB_BUTTONS_SIZE_X - UI_PADDING

	dirpad_pos_y  = height - DIRPAD_SIZE_Y - UI_PADDING
	dirpad_pos_x  = UI_PADDING

	local ui_state = {
		dirpad_touch_id   = nil,
		use_btn_touch_id  = nil,
		drop_btn_touch_id = nil,
	}

	--draw_pt_order = generate_draw_pt_order(game_params.y_size, game_params.x_size)
	draw_pt_order = generate_draw_pt_order(game_params.y_size, game_params.x_size) -- TODO FIX THIS TODO TODO TODO
	return ui_state
end

function draw.set_input_type(ui_state, input_type)
	ui_state.input_type = input_type
end

local function get_item_img_id(item_id)
	local map = {
		[core.ITEM_ID_PATIENT_IN_BED] = "hospital_patient_in_bed",
		[core.ITEM_ID_PATIENT_IN_BED_FLIPPED] = "hospital_patient_in_bed_flipped",
		[core.ITEM_ID_BED]        = "hospital_bed",
		[core.ITEM_ID_BED_FLIPPED]= "hospital_bed_flipped",
		[core.ITEM_ID_IV_BAG]     = "hospital_iv_bag",
		[core.ITEM_ID_DEFIB]      = "hospital_defib",
		[core.ITEM_ID_VENTILATOR] = "hospital_ventilator",
		[core.ITEM_ID_XRAY_SHEET] = "hospital_xray_sheet",
		[core.ITEM_ID_XRAY_SOURCE] = "hospital_xray_source",

	}
	local img_id = map[item_id]
	if img_id == nil then
		error(string.format("Could not find image id for item id %s", item_id))
	end
	return img_id
end

local function get_item_size(item_id)
	local sizes = {
		[core.ITEM_ID_PLAYER]         = { x= 1.5*TILE_SIZE,  y= 2*TILE_SIZE },
		[core.ITEM_ID_BED]            = { x= 2.9*TILE_SIZE,  y= 2.2*TILE_SIZE },
		[core.ITEM_ID_BED_FLIPPED]    = { x= 2.9*TILE_SIZE,  y= 2.2*TILE_SIZE },
		[core.ITEM_ID_PATIENT_IN_BED] = { x= 2.0*TILE_SIZE,  y= 1.5*TILE_SIZE },
		[core.ITEM_ID_PATIENT_IN_BED_FLIPPED] = { x= 2.0*TILE_SIZE,  y= 1.5*TILE_SIZE },
		[core.ITEM_ID_IV_BAG]         = { x= 2*TILE_SIZE,    y= 3*TILE_SIZE },
		[core.ITEM_ID_VENTILATOR]     = { x= 1.8*TILE_SIZE,  y= 2.2*TILE_SIZE },
		[core.ITEM_ID_XRAY_SHEET]     = { x= 2.0*TILE_SIZE,  y= 3.0*TILE_SIZE },
		[core.ITEM_ID_XRAY_SOURCE]    = { x= 2.0*TILE_SIZE,  y= 3.0*TILE_SIZE },
		--[core.ITEM_ID_OXYGEN_TANK]    = { x= 2*TILE_SIZE,    y= 3*TILE_SIZE },
		[core.ITEM_ID_DEFIB]          = { x= 2*TILE_SIZE,    y= 2*TILE_SIZE },
	}
	local size = sizes[item_id]
	if size == nil then
		error(string.format("could not find size for id %s", item_id))
	end
	return size
end

local function get_item_offset(item_id)
	local offsets = {
		[core.ITEM_ID_PLAYER] =         { x= 0.50, y= 0.80 },
		[core.ITEM_ID_BED] =            { x= 0.35, y= 0.55 },
		[core.ITEM_ID_BED_FLIPPED] =    { x= 0.35, y= 0.55 },
		[core.ITEM_ID_PATIENT_IN_BED] = { x= 0.35, y= 0.90 },
		[core.ITEM_ID_PATIENT_IN_BED_FLIPPED] = { x= 0.35, y= 0.90 },
		[core.ITEM_ID_IV_BAG] =   { x= 0.6,  y= 0.7  },
		[core.ITEM_ID_VENTILATOR] =     { x= 0.50, y= 0.55 },
		[core.ITEM_ID_XRAY_SHEET] =     { x= 0.60, y= 0.60 },
		[core.ITEM_ID_XRAY_SOURCE] =    { x= 0.50, y= 0.68 },
		--[core.ITEM_ID_OXYGEN_TANK] =    { x= 0.45, y= 0.65 },
		--[core.ITEM_ID_FLOOR_TILE] =       { x= 0.50, y= 0.00 },
		--[core.ITEM_ID_FLOOR_HIGHLIGHT] =  { x= 0.50, y= 0.00 },
		[core.ITEM_ID_DEFIB] =  { x= 0.55, y= 0.50 },
		--[core.ITEM_ID_PATIENT_NEEDS_ICON] =  { x= 0.0, y= 1.5 },
		--[core.ITEM_ID_TUT_NEED_ACTION] =     { x= 0.5, y= 1.5 },
		--[core.ITEM_ID_FIXER_ICON] =          { x= 0.5, y= 1.5 },
		--[core.ITEM_ID_PROGRESS_CIRCLE] =     { x= 0.55, y= 2.20 },
		--[core.ITEM_ID_PATIENT_HEALTH_INDICATORS] =  { x= 0.55, y= 2.20 },
		--[core.ITEM_ID_PATIENT_IND_ICON] =  { x= 0.0*TILE_SIZE, y= 0.0*TILE_SIZE },
	}
	local offset = offsets[item_id]
	if offset == nil then
		error(string.format("could not find offset for id %s", item_id))
	end
	return offset
end

local function draw_item(state, ui_state, item_info, pt)
	local gfx_pt = game_pt_to_gfx_pt(point(pt.y, pt.x), ui_state)
	local size = get_item_size(item_info.id)
	local offset = get_item_offset(item_info.id)
	gfx_pt.y = gfx_pt.y - size.y*offset.y
	gfx_pt.x = gfx_pt.x - size.x*offset.x
	draw_more.draw_graphic_ul(get_item_img_id(item_info.id),
	                        math.floor(gfx_pt.y), math.floor(gfx_pt.x),
	                        math.floor(size.x), math.floor(size.y))
end

local function draw_using_progress(state, ui_state, player_idx)
	local player_state = state.players[player_idx]
	local gfx_pt = game_pt_to_gfx_pt(point(player_state.y, player_state.x), ui_state)
	local size   = { x = 2.5*TILE_SIZE,   y = 0.5*TILE_SIZE }
	local offset = { x = 0.5, y = 4.00 }
	local draw_pt = point(gfx_pt.y - offset.y*size.y,
	                      gfx_pt.x - offset.x*size.x);


	local progress = player_state.use_progress/100.0
	alexgames.draw_rect(PLAYER_HIGHLIGHT_COLOURS[player_idx].fill,
	                     math.floor(draw_pt.y), math.floor(draw_pt.x),
	                     math.floor(draw_pt.y + size.y), math.floor(draw_pt.x + size.x))

	alexgames.draw_rect(PLAYER_HIGHLIGHT_COLOURS[player_idx].stroke,
	                     math.floor(draw_pt.y), math.floor(draw_pt.x),
	                     math.floor(draw_pt.y + size.y), math.floor(draw_pt.x + progress*size.x))

end

local function draw_player(state, ui_state, item_info)
	local player_state = state.players[item_info.player_idx]
	local gfx_pt = game_pt_to_gfx_pt(point(player_state.y, player_state.x), ui_state)
	local size   = { x = 1.5*TILE_SIZE,   y = 2*TILE_SIZE }
	local offset = { x = 0.50, y = 0.80 }

	local draw_pt = point(gfx_pt.y - offset.y*size.y,
	                      gfx_pt.x - offset.x*size.x);

	draw_more.draw_graphic_ul(get_doctor_img_id(item_info.player_idx),
	                        math.floor(draw_pt.y), math.floor(draw_pt.x),
	                        math.floor(size.x),    math.floor(size.y))

	if player_state.holding ~= nil then
		draw_item(state, ui_state, player_state.holding, player_state)
	end

	if player_state.is_using then
		draw_using_progress(state, ui_state, item_info.player_idx)
	end
end

local function do_nothing(arg1, arg2, arg3)
end

local draw_funcs = {
	[core.ITEM_ID_BED_SEGMENT_2] = do_nothing,
	[core.ITEM_ID_PLAYER] = draw_player,
}

local function draw_items(state, ui_state, player)
	for _, pt in ipairs(draw_pt_order) do
		if state.cells[pt.y][pt.x] == nil then
			goto next_pt
		end
		for _, item_info in ipairs(state.cells[pt.y][pt.x]) do
			local draw_func = draw_funcs[item_info.id]
			if draw_func == draw_player then
				-- do nothing, handled elsewhere now
			elseif draw_func ~= nil then
				draw_func(state, ui_state, item_info)
			else
				draw_item(state, ui_state, item_info, pt)
			end
		end
		::next_pt::
	end

	for i, _ in ipairs(state.players) do
		draw_player(state, ui_state, { player_idx = i })
	end
end

local function patient_to_needs_img_id(patient_info)
	local needs_to_img_id_map = {
		[core.NEEDS_LOW_FLUIDS]   = 'hospital_ui_patient_needs_low_fluids',
		[core.NEEDS_LOW_OXYGEN]   = 'hospital_ui_patient_needs_low_oxygen',
		[core.NEEDS_NO_HEARTBEAT] = 'hospital_ui_patient_needs_no_heartbeat',
		[core.NEEDS_BROKEN_BONE]  = 'hospital_ui_patient_needs_broken_bone',
	}
	if not patient_info.needs_revealed then
		return 'hospital_ui_patient_needs_attention'
	else
		return needs_to_img_id_map[patient_info.needs_type]
	end

end

local function get_time_left_colour(portion)
	if portion > 0.7 then
		return TIME_LEFT_FG_GOOD_COLOUR
	elseif portion > 0.4 then
		return TIME_LEFT_FG_MED_COLOUR
	else
		-- blinking animation
		local time_ms = alexgames.get_time_ms()
		if math.floor(time_ms/200) % 2 == 1 then
			return TIME_LEFT_FG_BAD_COLOUR
		else
			return TIME_LEFT_FG_BAD_COLOUR2
		end
	end
end

local function draw_ui_layer_patient(state, ui_state, player, patient)
	if patient.requires_help then
		local pos_pt = patient
		if patient.held_by ~= nil then
			pos_pt = patient.held_by
		end
           local gfx_pt = game_pt_to_gfx_pt(pos_pt, ui_state)
		gfx_pt.y = math.floor(gfx_pt.y - 4.0*TILE_SIZE)
		gfx_pt.x = math.floor(gfx_pt.x)
		local size = { x = math.floor(TILE_SIZE*2.0), y = math.floor(TILE_SIZE*2.5) }
		draw_more.draw_graphic_ul('hospital_ui_patient_needs_bg', 
		                        gfx_pt.y, gfx_pt.x,
		                        size.x, size.y)
		local needs_img_id = patient_to_needs_img_id(patient)
		draw_more.draw_graphic_ul(needs_img_id,
		                        gfx_pt.y, gfx_pt.x,
		                        size.x, size.y)
		if patient.needs_revealed then
		local portion = patient.time_left / patient.orig_time_left
			alexgames.draw_rect(TIME_LEFT_BG_COLOUR,
			                     gfx_pt.y,
			                     gfx_pt.x - TIME_LEFT_ICON_WIDTH - PADDING,
			                     gfx_pt.y + size.y,
			                     gfx_pt.x - PADDING)

			alexgames.draw_rect(get_time_left_colour(portion),
			                     gfx_pt.y + math.floor((1-portion) * size.y),
			                     gfx_pt.x - TIME_LEFT_ICON_WIDTH - PADDING,
			                     gfx_pt.y + size.y,
			                     gfx_pt.x - PADDING)
		end

		if patient.fix_time ~= nil then
			-- TODO draw a little green cross icon
			local cross_size = {
				y = 10,
				x = 10,
			}

			local fix_bar_pos = {
				y = gfx_pt.y,
				x = gfx_pt.x - 2*TIME_LEFT_ICON_WIDTH - 2*PADDING,
			}
			local fix_bar_size = {
				y = size.y,
				x = TIME_LEFT_ICON_WIDTH,
			}
			draw_more.draw_graphic_ul('hospital_ui_green_cross',
			                        math.floor(fix_bar_pos.y - cross_size.y - PADDING),
			                        math.floor(fix_bar_pos.x),
			                        math.floor(cross_size.y),
			                        math.floor(cross_size.x))
			local portion = patient.fix_time / patient.orig_fix_time
			alexgames.draw_rect(FIX_TIME_PROGRSS_BAR_BG_COLOUR,
			                     fix_bar_pos.y,
			                     fix_bar_pos.x,
			                     fix_bar_pos.y + fix_bar_size.y,
			                     fix_bar_pos.x + fix_bar_size.x)
			alexgames.draw_rect(FIX_TIME_PROGRSS_BAR_FG_COLOUR,
			                     fix_bar_pos.y + math.floor(portion*size.y),
			                     fix_bar_pos.x,
			                     fix_bar_pos.y + fix_bar_size.y,
			                     fix_bar_pos.x + fix_bar_size.x)
		end
	end
end

local function draw_ui_layer(state, ui_state, player)
	local highlight_needs_types = {}
	for _, patient in ipairs(state.patients) do
		if patient.requires_help and patient.needs_revealed then
			highlight_needs_types[patient.needs_type] = true
		end
	end

	for y=0, state.y_size-1 do
		for x=0, state.x_size-1 do
			for _, item in ipairs(state.cells[y][x]) do
				local items_needs_type = core.get_item_needs_type(item.id)
				if highlight_needs_types[item_needs_type] then
					-- TODO draw fixer icon
				end
			end
		end
	end
			                        
	for _, patient in ipairs(state.patients) do
		draw_ui_layer_patient(state, ui_state, player, patient)
	end

end

local function draw_highlight_floor_cell(ui_state, colour, y, x)
	local padding = 0.1
	local ia = game_pt_to_gfx_pt(point(y - padding,x - padding), ui_state)
	local ib = game_pt_to_gfx_pt(point(y+1+padding,x+0-padding), ui_state)
	local ic = game_pt_to_gfx_pt(point(y+1+padding,x+1+padding), ui_state)
	local id = game_pt_to_gfx_pt(point(y+0-padding,x+1+padding), ui_state)
	alexgames.draw_line(colour, highlight_line_size,
	                     math.floor(ia.y), math.floor(ia.x),
	                     math.floor(ib.y), math.floor(ib.x))
	alexgames.draw_line(colour, highlight_line_size,
	                     math.floor(ib.y), math.floor(ib.x),
	                     math.floor(ic.y), math.floor(ic.x))
	alexgames.draw_line(colour, highlight_line_size,
	                     math.floor(ic.y), math.floor(ic.x),
	                     math.floor(id.y), math.floor(id.x))
	alexgames.draw_line(colour, highlight_line_size,
	                     math.floor(id.y), math.floor(id.x),
	                     math.floor(ia.y), math.floor(ia.x))
end

local function draw_touch_input()
	draw_more.draw_graphic_ul('hospital_ui_dirpad',
	                        dirpad_pos_y,  dirpad_pos_x,
	                        DIRPAD_SIZE_Y, DIRPAD_SIZE_X)

	draw_more.draw_graphic_ul('hospital_ui_thumb_buttons',
	                        thumb_buttons_pos_y,  thumb_buttons_pos_x,
	                        THUMB_BUTTONS_SIZE_Y, THUMB_BUTTONS_SIZE_X)
end

local function draw_keyboard_input()
	alexgames.draw_text('[Z]: Pick up / use', CONTROLS_TEXT_COLOUR,
	                     screen_height - 50, 10, CONTROLS_TEXT_SIZE, 1)
	alexgames.draw_text('[X]: Drop', CONTROLS_TEXT_COLOUR,
	                     screen_height - 20, 10, CONTROLS_TEXT_SIZE, 1)
	alexgames.draw_text('[Arrows]: Move', CONTROLS_TEXT_COLOUR,
	                     screen_height - 20, screen_width - 10, CONTROLS_TEXT_SIZE, -1)
end

local function draw_unknown_input()
	alexgames.draw_text('Touch screen or use keyboard to select input', CONTROLS_TEXT_COLOUR,
	                     screen_height - 20, math.floor(screen_width/2), CONTROLS_TEXT_SIZE, 0)
end

local function draw_animations(animations)
	for _, anim in ipairs(animations) do
		if anim.anim_type == ANIM_TYPE_FLOAT_TEXT then
			alexgames.draw_text(anim.text, anim.text_colour,
			                     math.floor(anim.y), math.floor(anim.x),
			                     anim.font_size, 0)
		else
			error("unhandled anim type", anim.anim_type)
		end
	end
end

function draw.draw_state(state, ui_state, player)
	alexgames.draw_clear()

	if state == nil then
		return
	end

	local player_state = state.players[player]

	ui_state.offset_y = -player_state.y
	ui_state.offset_x = -player_state.x

    for y, row in pairs(state.cells) do
    	for x, cell in pairs(row) do

            local ia = game_pt_to_gfx_pt(point(y,x), ui_state)
			local tile_id = 'hospital_floor_tile'

			if state.tile_bad(y, x) then
				tile_id = 'hospital_floor_tile_bad'
			end

            draw_more.draw_graphic_ul(tile_id,
			                        math.floor(ia.y), math.floor(ia.x - TILE_SIZE),
			                        2*TILE_SIZE, TILE_SIZE);
		end
	end

	for _, cell in ipairs(core.get_cells_to_highlight(state, player)) do
		if cell.y == nil or cell.x == nil then
			error("cell has nil coords")
		end
		draw_highlight_floor_cell(ui_state, HIGHLIGHT_COLOUR,
		                          cell.y, cell.x)
	end

	for player_idx, _ in ipairs(state.players) do
		local highlight_cell = core.get_closest_item_cell(state, player_idx)
		if highlight_cell ~= nil then
			draw_highlight_floor_cell(ui_state, PLAYER_HIGHLIGHT_COLOURS[player_idx].stroke,
			                          highlight_cell.y, highlight_cell.x)
		end
	end

	draw_items(state, ui_state, player)
	draw_ui_layer(state, ui_state, player)
	draw_animations(animations)

	if ui_state.input_type == draw.INPUT_TYPE_TOUCH then
		draw_touch_input()
	elseif ui_state.input_type == draw.INPUT_TYPE_KEYBOARD then
		draw_keyboard_input()
	else
		draw_unknown_input()
	end

	alexgames.draw_text(string.format('Level %d', state.tile_bad_level_idx), CONTROLS_TEXT_COLOUR,
	                     50, 10, CONTROLS_TEXT_SIZE, 1)

	alexgames.draw_refresh()
end

local function sign(x)
	if x >= 0 then return 1
	else return -1 end
end

local function get_dirpad_vec(touch)
	local centre_y = math.floor(dirpad_pos_y + DIRPAD_SIZE_Y/2)
	local centre_x = math.floor(dirpad_pos_x + DIRPAD_SIZE_X/2)

	local vec_y = ((touch.y - centre_y)*1.0/(DIRPAD_SIZE/2))
	local vec_x = ((touch.x - centre_x)*1.0/(DIRPAD_SIZE/2))

	local mag = math.sqrt(vec_y*vec_y + vec_x*vec_x)

	if mag > 1.0 then
		vec_y = vec_y / mag
		vec_x = vec_x / mag
	end

	local mag = math.sqrt(vec_y*vec_y + vec_x*vec_x)

	return { y = vec_y, x = vec_x}
end

local function touch_in_dirpad(pos)
	local centre_y = math.floor(dirpad_pos_y + DIRPAD_SIZE_Y/2)
	local centre_x = math.floor(dirpad_pos_x + DIRPAD_SIZE_X/2)

	local dy = (pos.y - centre_y)
	local dx = (pos.x - centre_x)

	return (math.abs(dy) <= DIRPAD_SIZE_Y/2 and
	        math.abs(dx) <= DIRPAD_SIZE_X/2)
end

local function touch_in_use_btn(pos)
	local top    = thumb_buttons_pos_y
	local bottom = thumb_buttons_pos_y + THUMB_BUTTONS_SIZE_Y
	local left   = thumb_buttons_pos_x
	local right  = thumb_buttons_pos_x + THUMB_BUTTONS_SIZE_X

	return top  <= pos.y and pos.y <= bottom and
	       left <= pos.x and pos.x <= right and
	       (pos.y - top) >= (pos.x - left)
end

local function touch_in_drop_btn(pos)
	local top    = thumb_buttons_pos_y
	local bottom = thumb_buttons_pos_y + THUMB_BUTTONS_SIZE_Y
	local left   = thumb_buttons_pos_x
	local right  = thumb_buttons_pos_x + THUMB_BUTTONS_SIZE_X

	return top  <= pos.y and pos.y <= bottom and
	       left <= pos.x and pos.x <= right and
	       (pos.y - top) < (pos.x - left)
end

function draw.touches_to_actions(state, ui_state, evt_id, touches)
	local actions = {}
	for _, touch in ipairs(touches) do
		if evt_id == 'touchstart' and ui_state.dirpad_touch_id == nil and touch_in_dirpad(touch) then
			ui_state.dirpad_touch_id = touch.id
		elseif (evt_id == 'touchend' or evt_id == 'touchcancel') and ui_state.dirpad_touch_id == touch.id then
			ui_state.dirpad_touch_id = nil
			local action = {
				action = core.ACTION_DIR_PAD_POS_CHANGE,
				vec_y = 0,
				vec_x = 0,
			}
			table.insert(actions, action)
		end
		if ui_state.dirpad_touch_id == touch.id then
			local vec = get_dirpad_vec(touch)
			local action = {
				action = core.ACTION_DIR_PAD_POS_CHANGE,
				vec_y = vec.y,
				vec_x = vec.x
			}
			table.insert(actions, action)
		end

		if evt_id == 'touchstart' and ui_state.use_btn_touch_id == nil and touch_in_use_btn(touch) then
			ui_state.use_btn_touch_id = touch.id
			table.insert(actions, { action = core.ACTION_USE_BTN_DOWN })
		elseif (evt_id == 'touchend' or evt_id == 'touchcancel') and ui_state.use_btn_touch_id == touch.id then
			ui_state.use_btn_touch_id = nil
			table.insert(actions, { action = core.ACTION_USE_BTN_RELEASE })
		end

		if evt_id == 'touchstart' and ui_state.drop_btn_touch_id == nil and touch_in_drop_btn(touch) then
			ui_state.drop_btn_touch_id = touch.id
			table.insert(actions, { action = core.ACTION_DROP_BTN_DOWN })
		elseif (evt_id == 'touchend' or evt_id == 'touchcancel') and ui_state.drop_btn_touch_id == touch.id then
			ui_state.drop_btn_touch_id = nil
			table.insert(actions, { action = core.ACTION_DROP_BTN_RELEASE })
		end
	end
	return actions
end

function draw.add_animations_for_events(state, ui_state, events)
	for _, event in ipairs(events) do
		if event.event == core.EVT_PATIENT_NEED_EXPIRED then
			local pt = event.patient
			local gfx_pt = game_pt_to_gfx_pt(event.patient, ui_state)
			table.insert(animations, {
				anim_type = ANIM_TYPE_FLOAT_TEXT,
				text        = '-100',
				text_colour = '#ff0000ff',
				font_size   = 16,
				orig_y = gfx_pt.y,
				orig_x = gfx_pt.x,

				y = gfx_pt.y,
				x = gfx_pt.x,

				dst_y = gfx_pt.y - 70,
				dst_x = gfx_pt.x,

				orig_time_left = 3000,
				time_left = 3000,
			})
		elseif event.event == core.EVT_PATIENT_CURED then
			local pt = event.patient
			local gfx_pt = game_pt_to_gfx_pt(event.patient, ui_state)
			table.insert(animations, {
				anim_type = ANIM_TYPE_FLOAT_TEXT,
				text      = '+10',
				text_colour = '#008800cc',
				font_size   = 16,

				orig_y = gfx_pt.y,
				orig_x = gfx_pt.x,

				y = gfx_pt.y,
				x = gfx_pt.x,

				dst_y = gfx_pt.y - 70,
				dst_x = gfx_pt.x,

				orig_time_left = 3000,
				time_left = 3000,
			})
		else
			error("unhandled event", event.event)
		end
	end
end

function draw.update_animations(state, dt)
	for _, anim in ipairs(animations) do
		local dy = (anim.dst_y - anim.orig_y)*1.0/anim.orig_time_left
		local dx = (anim.dst_x - anim.orig_x)*1.0/anim.orig_time_left

		anim.y = anim.y + dy * dt
		anim.x = anim.x + dx * dt
		anim.time_left = anim.time_left - dt
	end

	local i=1
	while i <= #animations do
		if animations[i].time_left <= 0 then
			table.remove(animations, i)
		else
			i = i + 1
		end
	end
end


return draw
