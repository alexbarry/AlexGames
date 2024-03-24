#include "wx/wx.h"
#include "wx/defs.h"
#include "wx/sizer.h"
#include "wx/popupwin.h"

typedef void (*host_server_callback_t)(const char *server_addr);
typedef void (*join_server_callback_t)(const char *server_addr);

class NetworkPopup : public wxDialog {
	public:
	NetworkPopup(wxFrame *parent);
	void set_host_server_callback(host_server_callback_t callback);
	void set_join_server_callback(join_server_callback_t callback);
	void set_default_port(int port);

	protected:
	void OnButton(wxCommandEvent& event);

	private:
	wxTextCtrl join_server_addr_input;
	wxButton   join_server_btn;

	wxTextCtrl host_server_addr_input;
	wxButton   host_server_btn;

	host_server_callback_t host_server_callback = nullptr;
	join_server_callback_t join_server_callback = nullptr;
	int default_port = 0;
	
	wxDECLARE_EVENT_TABLE();
};
