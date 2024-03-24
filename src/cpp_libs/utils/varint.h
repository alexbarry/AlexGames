#ifdef __cplusplus
extern "C" {
#endif

#include<stdint.h>

uint32_t read_varint(const uint8_t **data, size_t *data_len, int *bytes_read_out);
int write_varint(uint32_t value, uint8_t **data, size_t *data_space_rem, int *bytes_written_out);

#ifdef __cplusplus
}
#endif
