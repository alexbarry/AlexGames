#include<stdbool.h>
#include<stdlib.h>

#include "varint.h"


uint32_t read_varint(const uint8_t **data, size_t *data_len, int *bytes_read_out) {
	uint32_t val = 0;
	const uint8_t *ptr = *data;

	int num_bytes = 1;
	while (*ptr & 0x80) {
		if (num_bytes >= *data_len) {
			val = -1;
			num_bytes = 0;
			break;
		}
		ptr++;
		num_bytes++;
	}
	ptr = *data;
	for (int i=0; i<num_bytes; i++) {
		val = val | ((ptr[i] & 0x7F)<<(i*7));
	}
	*data_len -= num_bytes;
	*bytes_read_out = num_bytes;
	*data += num_bytes;
	if (bytes_read_out != NULL) { *bytes_read_out = num_bytes; }
	return val;
}

int write_varint(uint32_t value, uint8_t **data, size_t *data_space_rem, int *bytes_written_out) {
	uint8_t *ptr = *data;
	int num_bytes = 1;
	while (true) {
		if (num_bytes > *data_space_rem) {
			return -1;
		}
		*ptr = (value & 0x7F) | ((value>>7) ? 0x80 : 0);
		value >>= 7;
		if (value == 0) {
			break;
		}
		num_bytes++;
		ptr++;
	}

	*data += num_bytes;
	*data_space_rem -= num_bytes;
	if (bytes_written_out != NULL) { *bytes_written_out = num_bytes; }

	return 0;
}
