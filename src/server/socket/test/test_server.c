#include<pthread.h>

#include "socket_server.h"

#define MAX_CLIENTS 10

static const int port = 5678;


static void client_thread_handler(void **arg) {
		printf("Started client_thread_handler...\n");

		void *client_handle = *arg;

		static const char msg[] = "Hello, world! This is a message from the server.";
		send_msg(client_handle, msg, sizeof(msg));

		while (1) {
			char buff[1024];
			size_t bytes_recvd = 0;
			int rc = recv_msg(client_handle, sizeof(buff), buff, &bytes_recvd);

			if (rc <= 0) {
				printf("Received rc=%d, exiting client handler\n", rc);
				return;
			}

			printf("Recvd msg from client: %.*s\n", bytes_recvd, buff);
		}
}

int main(void) {
	void *server_handle;
	int rc = host_server(port, &server_handle);
	if (rc != 0) {
		printf("Unable to host server, rc=%d\n", rc);
		return 0;
	}

	int client_idx = 0;
	pthread_t client_threads[MAX_CLIENTS];

	while (client_idx < MAX_CLIENTS) {
		void **client_handle = malloc(sizeof(void*));
		int rc = wait_for_connections(server_handle, client_handle);
		if (rc != 0) {
			printf("Unable to wait for connection, rc=%d\n", rc);
			return 0;
		}
		printf("Received connection, creating thread...\n");
		rc = pthread_create(&client_threads[client_idx], NULL, client_thread_handler, client_handle);
		if (rc != 0) {
			printf("Unable to create pthread\n");
			return 0;
		}
		client_idx++;
	}
}
