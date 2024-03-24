#include <unistd.h>

#include "socket_server.h"

static const int port = 5678;

int main(void) {
	void *handle;
	printf("Connecting to server on port %d\n", port);
	int rc = join_server("127.0.0.1", port, &handle);

	if (rc != 0) {
		printf("Unable to join server, rc=%d\n", rc);
		return -1;
	}

	char buff[1024];
	size_t bytes_recvd = 0;
	recv_msg(handle, sizeof(buff), buff, &bytes_recvd);

	printf("Recvd msg from server: %.*s\n", bytes_recvd, buff);

	for (int i=0; i<10; i++) {
		int msg_len = snprintf(buff, sizeof(buff), "Hello from client msg %d", i);
		send_msg(handle, buff, msg_len);
		sleep(1);
	}

	return 0;
}
