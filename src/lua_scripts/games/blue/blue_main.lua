
--[[
-- TODO:
--  * draw player names (or just "Player 1" for now) by each game card
--  * change player turn
--  * on end of turn, commit pieces from staging area to card if possible, calculate points
--  * implement state serialization for network multiplayer
--  * use save state API
--]]


local ui   = require("games/blue/blue_ui")
local core = require("games/blue/blue_core")
local draw = require("games/blue/blue_draw")

local g_game_state = core.new_game(4)
local g_ui_state   = ui.new_state(g_game_state)

local function get_player()
	return 1 -- TODO
end

function update()
	draw.draw_state(g_ui_state, get_player())
end

function handle_user_clicked(y_pos, x_pos)
	local click_info = draw.pos_to_action(g_ui_state, y_pos, x_pos)
	if click_info ~= nil then
		print(string.format("User clicked { action=%s, arg=%s }", click_info.action, click_info.action_arg_idx))
		local rc = ui.handle_action(g_ui_state, get_player(), click_info.action, click_info.action_arg_idx)
		update()
	end
end
	
