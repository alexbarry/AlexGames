
local alexgames = require("alexgames")

local TEXT_SIZE = 12
local PADDING = 5
local TEXT_COLOUR = "#ff0000"

local BTN_ID_TIMER1_TOGGLE = "timer1_toggle"
local BTN_ID_TIMER2_TOGGLE = "timer2_toggle"

local TIMER1_PERIOD_MS = 1000
local TIMER2_PERIOD_MS = 1500

local timer1 = nil
local timer2 = nil

local program_start_time = 0

local total_updates = 0
local recent_updates = {}

local function internal_draw_board()
	alexgames.draw_clear()

	for i, info in ipairs(recent_updates) do
		local y = (TEXT_SIZE + PADDING) * (i)
		local msg = string.format("%3.3f: draw_board fired, dt_ms: %d", info.time_ms/1000, info.dt_ms)
		alexgames.draw_text(msg, TEXT_COLOUR, y, 0, TEXT_SIZE, alexgames.TEXT_ALIGN_LEFT)
	end

	alexgames.draw_text(string.format("Timer 1 (1 s) handle: %s", timer1), TEXT_COLOUR,
	                     400, 0, TEXT_SIZE, alexgames.TEXT_ALIGN_LEFT)
	alexgames.draw_text(string.format("Timer 2 (1.5 s) handle: %s", timer2), TEXT_COLOUR,
	                     400 + TEXT_SIZE + PADDING, 0, TEXT_SIZE, alexgames.TEXT_ALIGN_LEFT)
	alexgames.draw_refresh()
end

function draw_board(dt_ms)
	local time_ms = alexgames.get_time_ms() - program_start_time
	total_updates = total_updates + 1
	table.insert(recent_updates, { dt_ms = dt_ms, time_ms = time_ms })
	while #recent_updates > 15 do
		table.remove(recent_updates, 1)
	end

	internal_draw_board()
end

function handle_btn_clicked(btn_id)
	if btn_id == BTN_ID_TIMER1_TOGGLE then
		if timer1 == nil then
			timer1 = alexgames.set_timer_update_ms(TIMER1_PERIOD_MS)
		else
			alexgames.delete_timer(timer1)
			timer1 = nil
		end
	else
		if timer2 == nil then
			timer2 = alexgames.set_timer_update_ms(TIMER2_PERIOD_MS)
		else
			alexgames.delete_timer(timer2)
			timer2 = nil
		end
	end

	internal_draw_board()
end


function start_game()
	program_start_time = alexgames.get_time_ms()
	timer1 = alexgames.set_timer_update_ms(TIMER1_PERIOD_MS)
	timer2 = alexgames.set_timer_update_ms(TIMER2_PERIOD_MS)

	-- TODO remove
	--alexgames.delete_timer(timer1)
	--timer1 = nil

	alexgames.create_btn(BTN_ID_TIMER1_TOGGLE, "Toggle timer 1", 1)
	alexgames.create_btn(BTN_ID_TIMER2_TOGGLE, "Toggle timer 2", 1)
end
