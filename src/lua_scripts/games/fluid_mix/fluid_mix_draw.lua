local draw = {}
local alex_c_api  = require("alex_c_api")
local draw_shapes = require("libs/draw/draw_shapes")

local draw_celebration_anim = require("libs/draw/draw_celebration_anim")

local OUTLINE_COLOUR = '#000000'
local OUTLINE_WIDTH  = 3
local HIGHLIGHT_OUTLINE_WIDTH  = 5
local HIGHLIGHT_COLOUR = '#ffff0066'
local HIGHLIGHT_OUTLINE_COLOUR = '#ffff00'
local COLOUR_MAP = {
	'#ff0000',
	'#00ff00',
	'#0000ff',
	'#ffff00',
	'#00ffff',
	'#ff00ff',
	'#ffffff',
	'#ff8800',
	'#ff0088',
	'#ff8888',
	'#00ff88',
	'#88ff00',
	'#88ff88',
	'#0088ff',
	'#8800ff',
	'#8888ff',
	'#888888',
}

local board_width  = 480
local board_height = 480

local vial_padding = 15

draw.BTN_ID_UNDO = "btn_undo"
draw.BTN_ID_REDO = "btn_redo"

local anim_state = draw_celebration_anim.new_state({
})
-- TODO this probably should be included in the anim state?
-- Perhaps as an option, for games that don't otherwise require a timer
local g_victory_anim_timer = nil


function draw.init()
	alex_c_api.create_btn(draw.BTN_ID_UNDO, "Undo", 1)
	alex_c_api.create_btn(draw.BTN_ID_REDO, "Redo", 1)
end

function draw.new_state()
	return {
		selected = nil
	}
end

local function get_size_params(state, num_rows)
	local vials_per_row = math.ceil(#state.vials/num_rows)
	local vial_width = math.floor((board_width - (vials_per_row+1) * vial_padding)/vials_per_row)
	local vial_height = math.floor(board_height/num_rows) - 2*vial_padding

	print(string.format("width: %s, height: %s", vial_width, vial_height))

	return {
		vials_per_row = vials_per_row,
		width         = vial_width,
		height        = vial_height,
	}
end

local function get_vial_params(params, i)
	local vial_y_idx = math.floor((i-1)/params.vials_per_row)
	local vial_x_idx = (i-1) % params.vials_per_row

	return {
		y_start = (params.height + vial_padding) * vial_y_idx     + vial_padding,
		x_start = (params.width  + vial_padding) * vial_x_idx     + vial_padding,
		y_end   = (params.height + vial_padding) * (vial_y_idx+1),
		x_end   = (params.width  + vial_padding) * (vial_x_idx+1),
	}
end

local function get_num_rows(vial_count)
	return 2
end

function draw.update_state(draw_state, dt_ms)
	draw_celebration_anim.update(anim_state, dt_ms/1000.0)
end

function draw.draw_state(session_id, state, draw_state)
	alex_c_api.draw_clear()

	local num_rows = get_num_rows(#state.vials)
	local params = get_size_params(state, num_rows)

	for vial_idx, vial in ipairs(state.vials) do
		local vial_params = get_vial_params(params, vial_idx)

		draw_shapes.draw_rect_outline(OUTLINE_COLOUR, OUTLINE_WIDTH,
		                              vial_params.y_start, vial_params.x_start,
		                              vial_params.y_end,   vial_params.x_end)

		for seg_idx, colour_idx in ipairs(vial) do
			if colour_idx == 0 then
				goto draw_highlight
			end
			local colour = COLOUR_MAP[colour_idx]
			if colour == nil then
				error(string.format("could not resolve colour idx %s", colour_idx))
			end
			seg_idx = state.num_segments - seg_idx + 1
			alex_c_api.draw_rect(colour,
			                     vial_params.y_start + (seg_idx-1)*params.height/state.num_segments, vial_params.x_start,
			                     vial_params.y_start + (seg_idx)*params.height/state.num_segments,   vial_params.x_end)
			alex_c_api.draw_text(string.format("%d", colour_idx), OUTLINE_COLOUR,
			                     vial_params.y_start + params.height/2/state.num_segments + (seg_idx-1)*params.height/state.num_segments,
			                     vial_params.x_start + params.width/2,
			                     12, alex_c_api.TEXT_ALIGN_CENTRE)
		end
		::draw_highlight::
		if vial_idx == draw_state.selected then
			alex_c_api.draw_rect(HIGHLIGHT_COLOUR,
			                     vial_params.y_start, vial_params.x_start,
			                     vial_params.y_end,   vial_params.x_end)
			draw_shapes.draw_rect_outline(HIGHLIGHT_OUTLINE_COLOUR, HIGHLIGHT_OUTLINE_WIDTH,
			                     vial_params.y_start, vial_params.x_start,
			                     vial_params.y_end,   vial_params.x_end)
		end
	end
	
	draw_celebration_anim.draw(anim_state)
	alex_c_api.draw_refresh()

	alex_c_api.set_btn_enabled(draw.BTN_ID_UNDO, alex_c_api.has_saved_state_offset(session_id, -1))
	alex_c_api.set_btn_enabled(draw.BTN_ID_REDO, alex_c_api.has_saved_state_offset(session_id,  1))
end

function draw.coords_to_vial_idx(state, pos_y, pos_x)
	local num_rows = get_num_rows(#state.vials)
	local params = get_size_params(state, num_rows)

	for vial_idx, _ in ipairs(state.vials) do
		local vial_params = get_vial_params(params, vial_idx)
		if vial_params.y_start <= pos_y and pos_y <= vial_params.y_end and
		   vial_params.x_start <= pos_x and pos_x <= vial_params.x_end then
			return vial_idx
		end
	end
end

function draw.handle_user_clicked(state, draw_state, pos_y, pos_x)
	local vial_idx = draw.coords_to_vial_idx(state, pos_y, pos_x)
	if vial_idx == nil then return end
	if draw_state.selected == nil then
		draw_state.selected = vial_idx
	else
		local to_return = {
			src = draw_state.selected,
			dst = vial_idx,
		}
		draw_state.selected = nil
		return to_return
	end
end

function draw.trigger_win_anim(draw_state, fps)
	print("setting timer")
	if g_victory_anim_timer ~= nil then
		error(string.format("victory_animation: anim_timer is not nil"))
	end
	g_victory_anim_timer = alex_c_api.set_timer_update_ms(1000/fps)
	draw_celebration_anim.fireworks_display(anim_state, {
		colour_pref = "light",
		on_finish = function ()
			if g_victory_anim_timer == nil then
				alex_c_api.set_status_err("warning: g_victory_anim_timer is nil on anim complete")
			else
				alex_c_api.delete_timer(g_victory_anim_timer)
				g_victory_anim_timer = nil
			end
			--print("animation finished! Resuming timer")
			--alex_c_api.set_timer_update_ms(0)
			--alex_c_api.set_timer_update_ms(1000/60)
		end,
	})
end

return draw
