#include "wx_game_popup.h"
#include "game_api.h"



GamePopup::GamePopup(wxFrame *parent, std::string popup_id, const struct popup_info *popup_info, void *game_handle) :
	wxDialog(parent, wxID_ANY, (std::string("Game Popup: ") + std::string(popup_info->title)).c_str(),
	         wxDefaultPosition, wxSize(300, 400),
	         wxDEFAULT_DIALOG_STYLE | wxSTAY_ON_TOP)
 {

	wxScrolledWindow *scrolledWindow = new wxScrolledWindow(this, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxVSCROLL);

	this->sizer = new wxBoxSizer(wxVERTICAL);
	this->game_handle = game_handle;
	this->popup_id    = popup_id;


	// show title here
	//wxStaticText text(kjj

	for (int i=0; i<popup_info->item_count; i++) {
		const struct popup_item &item = popup_info->items[i];
		switch (item.type) {
			case POPUP_ITEM_TYPE_MSG: {
				wxString str(item.info.msg.msg);
				wxStaticText *text = new wxStaticText(scrolledWindow, wxID_STATIC, str);
				this->children.push_back(text);
				sizer->Add(text, 0, wxEXPAND, 0);
				break;
			}

			case POPUP_ITEM_TYPE_BTN: {
				wxButton *btn = new wxButton(scrolledWindow, wxID_ANY, item.info.btn.text);
				this->button_game_ids[btn] = item.info.btn.id;
				this->children.push_back(btn);
				sizer->Add(btn, 0, wxEXPAND, 0);
				break;
			}

			case POPUP_ITEM_TYPE_DROPDOWN: {
				wxBoxSizer *dropdown_sizer = new wxBoxSizer(wxHORIZONTAL);
				this->dropdown_sizers.push_back(dropdown_sizer);
				{
					wxString str(item.info.dropdown.label);
					wxStaticText *label_text = new wxStaticText(scrolledWindow, wxID_STATIC, str);
					dropdown_sizer->Add(label_text, 0, wxALL|wxALIGN_CENTER_VERTICAL);
				}
				{
					const int choices_len = item.info.dropdown.option_count;
					int init_selection = 0; // TODO receive state from game when implemented
					wxString value(item.info.dropdown.options[init_selection]);
					wxString *choices = new wxString[choices_len];
					this->dropdown_choices_strings.push_back(choices);
					wxPoint pos = wxDefaultPosition;
					wxSize size = wxDefaultSize;
					for (int i=0; i<choices_len; i++) {
						choices[i] = wxString(item.info.dropdown.options[i]);
					}
					long style = 0;
					wxChoice *choice = new wxChoice(scrolledWindow, wxID_ANY, pos, size, choices_len, choices, style);
					choice->SetSelection(0);
					this->children.push_back(choice);
					GamePopupStateItem *popup_state_item = new GamePopupStateItemDropdown(item.info.dropdown.id, choice);
					this->popup_state_items.push_back(popup_state_item);
					dropdown_sizer->Add(choice, 1, wxALL|wxALIGN_CENTER_VERTICAL);
				}
				sizer->Add(dropdown_sizer, 0, wxEXPAND);
				break;
			}
		}
	}

	scrolledWindow->SetSizer(sizer);
	scrolledWindow->SetScrollRate(0, 10);

	sizer->Fit(scrolledWindow);
	sizer->SetSizeHints(scrolledWindow);
}


void GamePopup::set_popup_btn_pressed_callback(popup_btn_pressed_callback_t callback) {
	this->callback = callback;
}


GamePopup::~GamePopup(void) {
	for (auto child : children) {
		delete child;
	}

	for (auto ary : dropdown_choices_strings) {
		delete[] ary;
	}

	for (auto popup_state_item : this->popup_state_items) {
		delete popup_state_item;
	}
}

void GamePopup::OnButton(wxCommandEvent& event) {
	wxObject *obj = event.GetEventObject();
	if (this->button_game_ids.find(obj) != this->button_game_ids.end()) {
		int btn_id = this->button_game_ids[obj];
		std::cout << "Popup btn_id \"" << btn_id << "\" pressed" << std::endl;

		struct popup_state popup_state = this->get_state();
		assert(this->callback != nullptr);
		this->callback(this->game_handle, this->popup_id.c_str(), btn_id, &popup_state);
	} else {
		std::cout << "Unhandled wxCommandEvent for obj " << obj << std::endl;
	}
}


struct popup_state GamePopup::get_state(void) const {
	struct popup_state state;
	state.items_count = 0;

	for (const auto &item : this->popup_state_items) {
		state.items[state.items_count++] = item->get_state();
	}

	return state;
}

GamePopupStateItemDropdown::GamePopupStateItemDropdown(uint32_t game_popup_item_id, wxChoice *elem) {
	this->game_popup_item_id = game_popup_item_id;
	this->elem = elem;
}

struct popup_state_item GamePopupStateItemDropdown::get_state(void) const {
	uint32_t selected = this->elem->GetSelection();

	struct popup_state_item state;
	state.id       = this->game_popup_item_id;
	state.selected = selected;

	return state;
}


wxBEGIN_EVENT_TABLE(GamePopup, wxDialog)
	EVT_BUTTON(wxID_ANY, GamePopup::OnButton)
wxEND_EVENT_TABLE()
