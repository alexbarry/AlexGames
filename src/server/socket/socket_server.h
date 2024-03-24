#ifdef __cplusplus
extern "C" {
#endif

#include<stdint.h>
#include<stddef.h>

int network_init(void);

int join_server(const char *addr, int port, void **handle_out);

/**
 * call this once to setup a server socket
 */
int host_server(int port, void **server_handle_out);

/**
 * call this in a loop to handle client connctions to server socket
 */
int wait_for_connections(const void *server_handle, void **client_handle_out);

int send_msg(void *handle, const uint8_t *msg, size_t msg_size);
int recv_msg(void *handle, size_t max_msg_size, uint8_t *msg, size_t *msg_size);

void get_client_name(void *handle, const char *name_out, size_t max_name_len, size_t *name_len_out);

#ifdef __cplusplus
}
#endif
