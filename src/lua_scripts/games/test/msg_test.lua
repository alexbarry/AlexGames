local alexgames = require('alexgames')
local buttons = require('libs/ui/buttons')

print("[alexgames-msg-test] main script starting")

local BTN_ID_SEND_MSG_HELLO  = "btn_hello"
local BTN_ID_SEND_MSG_BINARY = "btn_binary"
local BTN_ID_SEND_MSG_EMPTY  = "btn_empty"

local BTN_MSG = {
	[BTN_ID_SEND_MSG_HELLO]  = "Hello, world!",
	[BTN_ID_SEND_MSG_BINARY] = { 10, 20, 30, 40, 0, 1, 2, 3, 0, 0, 0, 0 },
	[BTN_ID_SEND_MSG_EMPTY]  = "",
}

local function byte_ary_to_str(msg)
	local s = '['
	for idx, val in ipairs(msg) do
		if idx > 1 then
			s = s .. ', '
		end
		s = s .. tostring(val)
	end
	s = s .. ']'
	return s
end

local function byte_str_to_byte_ary(byte_str)
	local byte_ary = {}
	for i=1,#byte_str do
		table.insert(byte_ary, string.byte(byte_str:sub(i,i)))
	end
	return byte_ary
end

local function to_escaped_str(msg)
	local s = '"'
	for i=1,#msg do
		local c = msg:sub(i,i)
		if string.byte(c) < 0x20 or string.byte(c) > 0x7f then
			c = string.format('\\x%02x', string.byte(c))
		end
		s = s .. c
	end
	s = s .. '"'
	return s
end

local function to_human_readable(msg)
	if type(msg) == 'string' then
		return to_escaped_str(msg)
	elseif type(msg) == 'table' then
		return byte_ary_to_str(msg)
	else
		error(string.format("Unhandled msg type %s", type(msg)))
	end
end

local board_width = 480
local BTN_Y_SIZE = 50
local PADDING = 10
local btn_state = buttons.new_state()
local i = 0
for id, msg in pairs(BTN_MSG) do
	print(string.format("[alexgames-msg-test] initializing button %s", id))

	buttons.new_button(btn_state, {
		id   = id,
		text = to_human_readable(msg),
		y_start = PADDING +  i    * (BTN_Y_SIZE + PADDING),
		y_end   = PADDING + (i+1) * (BTN_Y_SIZE),
		x_start = PADDING,
		x_end   = board_width - PADDING,
	})
	i = i + 1
end


function update()
	print(string.format("[alexgames-msg-test] update called"))
	alexgames.draw_clear()

	buttons.draw(btn_state)

	alexgames.draw_refresh()
end

function byte_ary_to_byte_str(byte_ary)
	local s = ''
	for _, val in ipairs(byte_ary) do
		s = s .. string.char(val)
	end
	return s
end


function handle_user_clicked(y_pos, x_pos)
	print(string.format("[alexgames-msg-test] user clicked %d %d", y_pos, x_pos))
	local id = buttons.on_user_click(btn_state, y_pos, x_pos)
	if id ~= nil then
		print(string.format("[alexgames-msg-test] user clicked btn %s", id))
		local msg = BTN_MSG[id]
		log_msg = string.format("[alexgames-msg-test] Sending msg %s", to_human_readable(msg))
		print(log_msg)
		alexgames.set_status_msg(log_msg)

		if type(msg) == 'table' then
			msg = byte_ary_to_byte_str(msg)
		end
		alexgames.send_message("all", msg)
	end
end

function handle_msg_received(src, msg)
	local msg_byte_ary = byte_str_to_byte_ary(msg)
	local log_msg = string.format("[alexgames-msg-test] Received msg from %s: %s (%s)", src, byte_ary_to_str(msg_byte_ary), to_escaped_str(msg))
	print(log_msg)
	alexgames.set_status_msg(log_msg)
end

function start_game()
	print("[alexgames-msg-test] start_game called")
end

print("[alexgames-msg-test] main script finished")
