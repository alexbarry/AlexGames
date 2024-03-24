#include "wx/wx.h"
#include "wx/defs.h"
#include "wx/sizer.h"
#include "wx/popupwin.h"

#include<iostream>


#include "wx_network_ui.h"

wxBEGIN_EVENT_TABLE(NetworkPopup, wxDialog)
	EVT_BUTTON(wxID_ANY, NetworkPopup::OnButton)
wxEND_EVENT_TABLE()


NetworkPopup::NetworkPopup(wxFrame *parent) :
	wxDialog(parent, wxID_ANY, wxT("Network Settings"),
		wxDefaultPosition, wxSize(300, 400),
		wxDEFAULT_DIALOG_STYLE | wxSTAY_ON_TOP),
	join_server_addr_input(this, wxID_ANY),
	join_server_btn(this, wxID_ANY, "Join"),
	host_server_addr_input(this, wxID_ANY),
	host_server_btn(this, wxID_ANY, "Host")
{

	wxBoxSizer *sizer = new wxBoxSizer(wxVERTICAL);

	sizer->Add(new wxStaticText(this, wxID_STATIC, wxT("Join a server")), 0, wxALL|wxALIGN_CENTER_HORIZONTAL, 0);
	wxBoxSizer *join_server_name = new wxBoxSizer(wxHORIZONTAL);
	join_server_name->Add(new wxStaticText(this, wxID_STATIC, wxT("Server address")));
	join_server_name->Add(&join_server_addr_input, 1);
	sizer->Add(join_server_name, 0, wxEXPAND);
	sizer->Add(&join_server_btn, 0, wxEXPAND);

	sizer->Add(new wxStaticText(this, wxID_STATIC, wxT("Host a server")), 0, wxALL|wxALIGN_CENTER_HORIZONTAL, 0);
	wxBoxSizer *host_server_name = new wxBoxSizer(wxHORIZONTAL);
	host_server_name->Add(new wxStaticText(this, wxID_STATIC, wxT("Port")));
	host_server_name->Add(&host_server_addr_input, 1);
	sizer->Add(host_server_name, 0, wxEXPAND);
	sizer->Add(&host_server_btn, 0, wxEXPAND);

	this->SetSizer(sizer);
}

void NetworkPopup::OnButton(wxCommandEvent& event) {
	if (event.GetEventObject() == &host_server_btn) {
		wxString server_addr = host_server_addr_input.GetValue();
		if (this->host_server_callback == nullptr) {
			std::cerr << "host_server_callback not set" << std::endl;
			return;
		}
		this->host_server_callback(server_addr.c_str());
	} else if (event.GetEventObject() == &join_server_btn) {
		wxString server_addr = join_server_addr_input.GetValue();
		if (this->join_server_callback == nullptr) {
			std::cerr << "join_server_callback not set" << std::endl;
			return;
		}
		this->join_server_callback(server_addr.c_str());
	} else {
		std::cerr << "Unhandled button pressed" << std::endl;
	}
}


void NetworkPopup::set_host_server_callback(host_server_callback_t callback) {
	this->host_server_callback = callback;
}
void NetworkPopup::set_join_server_callback(join_server_callback_t callback) {
	this->join_server_callback = callback;
}

void NetworkPopup::set_default_port(int port) {
	this->default_port = port;
	host_server_addr_input.SetValue(std::to_string(port));
}
