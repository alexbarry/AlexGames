#include <unordered_map>
#include <string>
#include "wx/wx.h"

typedef void (*handle_msg_recvd_callback_t)(const char    *src, size_t src_len,
                                            const uint8_t *msg, size_t msg_len);
typedef void (*client_connected_callback_t)(const char *name, size_t name_len);

void wx_network_init(void);

class ClientHandlerThread;

class ServerThread : public wxThread {
	public:
	ServerThread(wxWindow *parent, int port);
	void set_handle_msg_recvd_callback(handle_msg_recvd_callback_t callback);
	void set_client_connected_callback(client_connected_callback_t callback);
	void send_message(std::string dst, const uint8_t *msg, size_t msg_len);
	virtual ExitCode Entry(void);
	private:
	int port;
	wxWindow *parent;
	handle_msg_recvd_callback_t handle_msg_recvd_callback;
	client_connected_callback_t client_connected_callback;
	std::unordered_map<std::string, ClientHandlerThread*> client_threads;
};

class ClientHandlerThread : public wxThread {
	public:
	ClientHandlerThread(wxWindow *parent, void *client_handle, std::string client_name);
	virtual ~ClientHandlerThread(void) { };
	virtual ExitCode Entry();
	void set_handle_msg_recvd_callback(handle_msg_recvd_callback_t callback);
	void set_client_connected_callback(client_connected_callback_t callback);
	void send_message(const uint8_t *msg, size_t msg_len);
	private:
	wxWindow *parent;
	std::string client_name;
	void *client_handle;
	handle_msg_recvd_callback_t handle_msg_recvd_callback;
	client_connected_callback_t client_connected_callback;
};

class ClientThread : public wxThread {
	public:
	ClientThread(wxWindow *parent, std::string addr, int port);
	virtual ~ClientThread(void) { };
	virtual ExitCode Entry();
	void set_handle_msg_recvd_callback(handle_msg_recvd_callback_t callback);
	void send_message(std::string dst, const uint8_t *msg, size_t msg_len);

	private:
	wxWindow *parent;
	void *handle;
	std::string addr;
	int port;
	std::string client_name;
	handle_msg_recvd_callback_t handle_msg_recvd_callback;
};
