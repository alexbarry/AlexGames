local show_buttons_popup = {}

local alex_c_api = require("alex_c_api")

-- This shows a popup with a single message and 0 to many buttons.
--
-- This is originally how the show_popup API worked, so I'm adding
-- this API for compatibility, rather than changing all the old
-- games to use the new API.
function show_buttons_popup.show_popup(popup_id, title, msg, btn_ary)
	local info = {
		title = title,
		items = {},
	}

	table.insert(info.items, {
		item_type = alex_c_api.POPUP_ITEM_TYPE_MSG,
		msg       = msg,
	})

	for btn_id, btn_text in ipairs(btn_ary) do
		table.insert(info.items, {
			item_type = alex_c_api.POPUP_ITEM_TYPE_BTN,
			text      = btn_ary[btn_id],
			id        = (btn_id - 1),
		})
	end

	alex_c_api.show_popup(popup_id, info)
end

return show_buttons_popup
