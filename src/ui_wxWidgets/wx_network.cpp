#include<list>
#include<stdint.h>

#ifdef _WIN32
#include <windows.h>
#endif

#include "wx/wx.h"

#include "wx_network.h"
#include "socket_server.h"

#define MAX_MSG_LEN (4096)

void wx_network_init(void) {
	network_init();
}

ServerThread::ServerThread(wxWindow *parent, int port) {
	this->parent = parent;
	this->port = port;
}

void ServerThread::set_handle_msg_recvd_callback(handle_msg_recvd_callback_t callback)  {
	this->handle_msg_recvd_callback = callback;
}

void ServerThread::set_client_connected_callback(client_connected_callback_t callback) {
	this->client_connected_callback = callback;
}

wxThread::ExitCode ServerThread::Entry(void) {
	void *server_handle;
	int rc = host_server(port, &server_handle);
	if (rc != 0) {
		printf("Unable to host server, rc=%d\n", rc);
		return 0;
	}


	while (true) {
		void *client_handle;
		int rc = wait_for_connections(server_handle, &client_handle);
		if (rc != 0) {
			printf("Unable to wait for connection, rc=%d\n", rc);
			return 0;
		}


		std::string client_name;
		{
			char name[1024];
			name[0] = 0;
			size_t name_len;
			get_client_name(client_handle, name, sizeof(name), &name_len);
			client_name = std::string(name);
		}

		printf("Received connection creating thread...\n");
		ClientHandlerThread *client_handler_thread = new ClientHandlerThread(parent, client_handle, client_name);
		this->client_connected_callback(client_name.c_str(), client_name.size());

		wxThreadError thread_rc = client_handler_thread->Create();
		if (thread_rc != wxTHREAD_NO_ERROR) {
			printf("Error creating thread\n");
			return 0;
		}
	
		client_handler_thread->set_handle_msg_recvd_callback(handle_msg_recvd_callback);
		client_handler_thread->set_client_connected_callback(client_connected_callback);
		thread_rc = client_handler_thread->Run();
	
		if (thread_rc != wxTHREAD_NO_ERROR) {
			printf("Error running thread\n");
			return 0;
		}

		client_threads[client_name] = client_handler_thread;
	}

	return 0;
}

void ServerThread::send_message(std::string dst, const uint8_t *msg, size_t msg_len) {
	if (dst == "all") {
		for (const auto &client: client_threads) {
			auto client_thread = client.second;
			client_thread->send_message(msg, msg_len);
		}
	} else if (client_threads.find(dst) != client_threads.end()) {
		client_threads[dst]->send_message(msg, msg_len);
	} else {
		fprintf(stderr, "tried to message unknown player \"%s\"\n", dst.c_str());
		return;
	}
}

ClientHandlerThread::ClientHandlerThread(wxWindow *parent, void *client_handle, std::string client_name) {
	this->parent = parent;
	this->client_handle = client_handle;
	this->client_name   = client_name;
}

void ClientHandlerThread::set_handle_msg_recvd_callback(handle_msg_recvd_callback_t callback)  {
	this->handle_msg_recvd_callback = callback;
}

void ClientHandlerThread::set_client_connected_callback(client_connected_callback_t callback) {
	this->client_connected_callback = callback;
}

wxThread::ExitCode ClientHandlerThread::Entry() {
	printf("Started client_thread_handler...\n");

	//static const uint8_t msg[] = "Hello, world! This is a message from the server.";
	//send_msg(client_handle, msg, sizeof(msg));

	while (1) {
		//uint8_t buff[4096];
		// TODO should probably use a real queue or cap this somehow
		// to avoid memory leak if spammed (which could happen accidentally)
		uint8_t *msg = (uint8_t*)malloc(MAX_MSG_LEN);
		size_t bytes_recvd = 0;
		int rc = recv_msg(client_handle, MAX_MSG_LEN, msg, &bytes_recvd);
		if (rc <= 0) {
			printf("recv_msg returned %d, ClientThread returning\n", rc);
			free(msg);
			break;
		}
		this->handle_msg_recvd_callback(client_name.c_str(), client_name.size(),
		                                msg, bytes_recvd);
		//printf("Recvd msg from server: %.*s\n", bytes_recvd, msg);
	}

	free(client_handle);
	return 0;
}

void ClientHandlerThread::send_message(const uint8_t *msg, size_t msg_len) {
	printf("server sending message to client %s (%d bytes): %.*s\n",
	       client_name.c_str(),
	       msg_len, msg_len, msg);

	send_msg(client_handle, msg, msg_len);
}

ClientThread::ClientThread(wxWindow *parent, std::string addr, int port) {
	this->parent = parent;
	this->addr = addr;
	this->port = port;
}

void ClientThread::set_handle_msg_recvd_callback(handle_msg_recvd_callback_t callback)  {
	this->handle_msg_recvd_callback = callback;
}

wxThread::ExitCode ClientThread::Entry(void) {
	int rc = join_server(this->addr.c_str(), this->port, &handle);

	if (rc != 0) {
		printf("Unable to join server, rc=%d\n", rc);
		return 0;
	}

	{
		char name[1024];
		name[0] = 0;
		size_t name_len;
		get_client_name(handle, name, sizeof(name), &name_len);
		this->client_name = std::string(name);
	}


	while (1) {
		//uint8_t buff[4096];
		// TODO should probably use a real queue or cap this somehow
		// to avoid memory leak if spammed (which could happen accidentally)
		uint8_t *msg = (uint8_t*)malloc(MAX_MSG_LEN);
		size_t bytes_recvd = 0;
		int rc = recv_msg(handle, MAX_MSG_LEN, msg, &bytes_recvd);
		if (rc <= 0) {
			printf("recv_msg returned %d, ClientThread returning\n", rc);
			free(msg);
			break;
		}
		this->handle_msg_recvd_callback(client_name.c_str(), client_name.size(),
		                                msg, bytes_recvd);
		//printf("Recvd msg from server: %.*s\n", bytes_recvd, msg);
	}

	// TODO close socket and stuff?
	free(handle);
	return 0;
}


void ClientThread::send_message(std::string dst, const uint8_t *msg, size_t msg_len) {
	// TODO maybe check that dst matches client_name?
	// if we're connected to a server, we shouldn't be trying to anything to anyone
	// besides the server (though I think I still use "all" in a lot of older games)
	printf("client sending message (%d bytes): %.*s\n", msg_len, msg_len, msg);
	send_msg(handle, msg, msg_len);
}
