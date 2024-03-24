#include <vector>
#include <string>
#include <unordered_map>
#include <stdint.h>

#include "wx/wx.h"
#include "wx/defs.h"
#include "wx/sizer.h"
#include "wx/popupwin.h"

typedef void (*popup_btn_pressed_callback_t)(void       *game_handle,
                                             const char *popup_id,
                                             int         popup_btn_id,
                                             const struct popup_state *popup_state);

class GamePopupStateItem;

class GamePopup : public wxDialog {
	public:
	GamePopup(wxFrame *parent, std::string popup_id, const struct popup_info *popup_info, void *game_handle);
	virtual ~GamePopup(void);
	void set_popup_btn_pressed_callback(popup_btn_pressed_callback_t callback);

	protected:
	void OnButton(wxCommandEvent& event);

	private:
	struct popup_state get_state(void) const;

	std::vector<GamePopupStateItem*> popup_state_items;

	wxBoxSizer *sizer;
	std::string popup_id;
	void *game_handle;
	popup_btn_pressed_callback_t callback;
	std::vector<wxObject*> children;
	std::unordered_map<wxObject*, int> button_game_ids;

	std::vector<wxString*> dropdown_choices_strings;
	std::vector<wxBoxSizer*>  dropdown_sizers;

	wxDECLARE_EVENT_TABLE();
};

class GamePopupStateItem {
	public:
	virtual struct popup_state_item get_state(void) const = 0;
};

class GamePopupStateItemDropdown : public GamePopupStateItem {
	public:
	GamePopupStateItemDropdown(uint32_t game_popup_item_id, wxChoice *elem);

	virtual struct popup_state_item get_state(void) const;

	private:
	uint32_t game_popup_item_id;
	wxChoice *elem;
};
