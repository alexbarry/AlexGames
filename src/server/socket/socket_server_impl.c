
#ifdef _WIN32
#include <Winsock2.h>
#include <ws2tcpip.h>

#pragma comment(lib,"ws2_32.lib") //Winsock Library

// No idea if it's okay to do all this...
#define socklen_t void
#define SO_REUSEPORT 0

#else

#include <unistd.h> // has read
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define SOCKET int

#endif

#include <stdio.h>
#include <stdlib.h>

#include "socket_server.h"

struct handle {
	SOCKET socket;
	struct sockaddr_in address;
};

#ifdef _WIN32
static WSADATA wsa;
#endif

int network_init(void) {
#ifdef _WIN32
	if (WSAStartup(MAKEWORD(2,2), &wsa) != 0) {
		fprintf(stderr, "Error initializing wsa, error:%d\n", WSAGetLastError());
		return -1;
	}
#endif
	return 0;
}

int join_server(const char *addr, int port, void **handle_out) {
	struct handle *handle = malloc(sizeof(struct handle));
	printf("Creating socket...\n");
	handle->socket = socket(AF_INET, SOCK_STREAM, 0);
	if (handle->socket == 0) {
		fprintf(stderr, "socket returned 0\n");
		free(handle);
		return -1;
	}

	int rc;

	handle->address.sin_family = AF_INET;
	//address.sin_addr.s_addr = inet_addr("192.168.0.5");
	// TODO learn how to use `getaddrinfo`, this one couldn't resolve names (even "localhost")
	handle->address.sin_addr.s_addr = inet_addr(addr);
	handle->address.sin_port = htons( port );

	printf("Connecting...\n");
	rc = connect(handle->socket, (struct sockaddr *)&handle->address, sizeof(handle->address));
	if (rc < 0) {
		fprintf(stderr, "connect returned %d\n", rc);
		free(handle);
		return -1;
	}
	printf("Connected!\n");
	*handle_out = handle;
	return 0;

}


int host_server(int port, void **server_handle_out) {
	SOCKET server_s = socket(AF_INET, SOCK_STREAM, 0);
	if (server_s == 0) {
		fprintf(stderr, "socket returned 0\n");
		return -1;
	}

	int opt = 1;

	int rc = setsockopt(server_s, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt));
	if (rc != 0) {
		fprintf(stderr, "setsockopt returned %d\n", rc);
		return -1;
	}

	struct handle *handle = malloc(sizeof(struct handle));
	handle->socket = server_s;

	handle->address.sin_family = AF_INET;
	handle->address.sin_addr.s_addr = INADDR_ANY;
	handle->address.sin_port = htons( port );

	rc = bind(handle->socket, (struct sockaddr *)&handle->address, sizeof(handle->address));
	if (rc < 0) {
		fprintf(stderr, "bind returned %d\n", rc);
		return -1;
	}

	*server_handle_out = handle;
	return 0;
}

int wait_for_connections(const void *server_handle_arg, void **client_handle_out) {
	struct handle *server_handle = server_handle_arg;

	//printf("Listening for clients on port %d...\n", PORT);
	int rc = listen(server_handle->socket, 3);
	if (rc < 0) {
		fprintf(stderr, "listen returned %d\n", rc);
		return -1;
	}

	int addrlen = sizeof(server_handle->address);
	int session_s = accept(server_handle->socket, (struct sockaddr *)&server_handle->address, (socklen_t*)&addrlen);

	if (session_s < 0) {
		fprintf(stderr, "accept returned %d\n", session_s);
		return -1;
	}
	struct handle *client_handle = malloc(sizeof(struct handle));
	client_handle->socket = session_s;
	
	*client_handle_out = client_handle;
	return 0;
}

int send_msg(void *handle_arg, const uint8_t *msg, size_t msg_size) {
	struct handle *handle = handle_arg;
	return send(handle->socket, msg, msg_size, 0);
}

int recv_msg(void *handle_arg, size_t max_buff_len, uint8_t *buff, size_t *buff_len) {
	struct handle *handle = handle_arg;

	int bytes_read = recv(handle->socket, buff, max_buff_len, 0);
	if (bytes_read >= 0) {
		printf("Read %d bytes: %.*s\n", bytes_read, bytes_read, buff);
	} else {
		printf("Error reading from socket, rc=%d\n", bytes_read);
		*buff_len = 0;
	}
	*buff_len = bytes_read;
	return bytes_read;
}


void get_client_name(void *handle_arg, const char *name_out, size_t max_name_len, size_t *name_len_out) {
	struct handle *handle = handle_arg;

	struct sockaddr_storage addr;
	int len = sizeof(addr);
	//getpeername(handle->socket, &addr, &len);
	getpeername(handle->socket, (struct sockaddr*)&addr, &len);

	char addr_str[256];
	addr_str[0] = 0;
	int port = -1;
	if (addr.ss_family == AF_INET) {
		struct sockaddr_in *s = (struct sockaddr_in*)&addr;
		inet_ntop(AF_INET, &s->sin_addr, addr_str, sizeof(addr_str));
		port = ntohs(s->sin_port);
	} else if (addr.ss_family == AF_INET6) {
		// TODO haven't actually tested IPv6
		struct sockaddr_in6 *s = (struct sockaddr_in6*)&addr;
		inet_ntop(AF_INET6, &s->sin6_addr, addr_str, sizeof(addr_str));
		port = ntohs(s->sin6_port);
	} else {
		fprintf(stderr, "unexpected addr.ss_family = %d\n", addr.ss_family);
		*name_len_out = snprintf(name_out, max_name_len, "err");
		return;
	}
	*name_len_out = snprintf(name_out, max_name_len, "%s:%d", addr_str, port);
}
