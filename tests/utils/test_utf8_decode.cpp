#include<stdint.h>
#include<stdio.h>

static uint32_t read_utf8_val(const uint8_t **data, size_t data_len, int *bytes_read_out) {
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

struct test {
	uint8_t  encoded[4];
	int      bytes_used;
	int32_t expected;
};

#define ARY_LEN(x) (sizeof(x) / sizeof(x[0]))

int main(void) {

	static const struct test tests[] = {
		{ {0xE2, 0x82, 0xAC       }, 3,  0x20AC },
		{ {0x24                   }, 1,  0x0024 },
		{ {0xC2, 0xA3             }, 2,  0x00A3 },
		{ {0xE0, 0xA4, 0xB9       }, 3,  0x0939 },
		{ {0xED, 0x95, 0x9C       }, 3,  0xD55C },
		{ {0xF0, 0x90, 0x8D, 0x88 }, 4, 0x10348 },

		// These ones are invalid utf8
		{ {0xC2, 0xc3             }, 0,  -1 },
		{ {0xE0, 0xC4, 0xB9       }, 0,  -1 },
		{ {0xE0, 0xA4, 0xC9       }, 0,  -1 },
		{ {0xF0, 0xf0, 0x8D, 0x88 }, 0,  -1 },
	};

	bool any_failures = false;

	int i;
	for (i=0; i<ARY_LEN(tests); i++) {
		const struct test test = tests[i];
		const uint8_t *enc_data = test.encoded;
		int bytes_read = 0;
		uint32_t actual = read_utf8_val(&enc_data, sizeof(test.encoded), &bytes_read);
		const uint8_t *expected_new_ptr = test.encoded + test.bytes_used;

		if (actual != test.expected ||
		    enc_data != expected_new_ptr) {
			printf("Test %3d: actual = %04x, expected = %04x, actual_end_pos = %p, expected_end_pos = %p\n",
			       i, actual, test.expected,
			       enc_data, expected_new_ptr);
			
			any_failures = true;
		}
	}

	if (any_failures) {
		return -1;
	}

	printf("%d tests run, all passed!\n", i);
	return 0;
	
}
