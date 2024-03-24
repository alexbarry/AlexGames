#include<stdint.h>
#include<stdlib.h>

// TODO remove this if I don't end up using it

uint32_t read_utf8_val(const uint8_t **data, size_t data_len, int *bytes_read_out) {
	uint32_t val = 0;
	int bytes_read = 0;

	const uint8_t *byte = *data;

	if ( data_len >= 1 && (byte[0] & 0x80) == 0) {
		val = byte[0];
		bytes_read = 1;
	} else if ( data_len >= 2 &&
	            (byte[0] & 0xE0) == 0xC0 &&
	            (byte[1] & 0xC0) == 0x80) {
		val = ((byte[0] & ~0xE0) << 6) | (byte[1] & ~0xC0);
		bytes_read = 2;
	} else if ( data_len >= 3 &&
	            (byte[0] & 0xF0) == 0xE0 &&
	            (byte[1] & 0xC0) == 0x80 &&
	            (byte[2] & 0xC0) == 0x80) {
		val = ((byte[0] & ~0xE0) << (2*6)) | ((byte[1] & ~0xC0)<<6) | (byte[2] & ~0xC0);
		bytes_read = 3;
	} else if ( data_len >= 4 &&
	            (byte[0] & 0xF8) == 0xF0 &&
	            (byte[1] & 0xC0) == 0x80 &&
	            (byte[2] & 0xC0) == 0x80 &&
	            (byte[3] & 0xC0) == 0x80) {
		val = ((byte[0] & ~0xF0) << (3*6)) |
		      ((byte[1] & ~0xC0)<<(2*6)) |
		      ((byte[2] & ~0xC0)<<6) |
		       (byte[3] & ~0xC0);
		bytes_read = 4;
	} else {
		val = -1;
		bytes_read = 0;
	}
	*data += bytes_read;

	*bytes_read_out = bytes_read;
	return val;
}
