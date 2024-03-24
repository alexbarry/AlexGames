#include<stdint.h>
#include<stdio.h>
#include<string.h>


#include<string>
#include<iostream>

#include "varint.h"

std::string to_str(const uint8_t *bytes, int num_bytes) {
	std::string s = "{";
	
	for (int i=0; i<num_bytes; i++) {
		char buff[8];
		snprintf(buff, sizeof(buff), "%02x, ", bytes[i]);
		s += std::string(buff);
	}

	return s + "}";
}

struct test {
	uint8_t  encoded[4];
	int      bytes_used;
	int32_t expected;
};

#define ARY_LEN(x) (sizeof(x) / sizeof(x[0]))

int main(void) {

#if 1
	static const struct test tests[] = {
		{ {0x96, 0x01}, 2, 150 },
		{ {0x97, 0x01}, 2, 151 },
		{ {0x98, 0x01}, 2, 152 },

		{ {0x96, 0x02}, 2, 150 + 0x80 },
		{ {0x96, 0x03}, 2, 150 + 2*0x80 },
		{ {0x96, 0x04}, 2, 150 + 3*0x80 },
		{ {0x96},       1, -1 },
	};

	bool any_failures = false;

	int i;
	for (i=0; i<ARY_LEN(tests); i++) {
		const struct test test = tests[i];
		const uint8_t *enc_data = test.encoded;
		int bytes_read = 0;
		size_t bytes_rem = test.bytes_used;
		uint32_t actual = read_varint(&enc_data, &bytes_rem, &bytes_read);
		const uint8_t *expected_new_ptr = test.encoded + (test.expected == -1 ? 0 : test.bytes_used);

		{
			int bytes_written = 0;
			uint8_t buff[5];
			memset(buff, sizeof(buff), 0);
			uint8_t *buff_ptr = buff;
			size_t bytes_rem2 = sizeof(buff);
			write_varint(test.expected, &buff_ptr, &bytes_rem2, &bytes_written);

			if (bytes_written != test.bytes_used || memcmp(test.encoded, buff, test.bytes_used) != 0) {
				printf("Test %3d err encoding 0x%04x: expected %s, actual %s\n",
				       i,
				       test.expected,
				       to_str(test.encoded, test.bytes_used).c_str(),
				       to_str(buff, bytes_written).c_str() );
				any_failures = true;
			}
		}

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
#endif

#if 0
	for (long int i=0; i<0x100000000; i++) {
		uint8_t buff[8];
		uint8_t *ptr = buff;
		int bytes_written = 0;
		size_t size_rem = sizeof(buff);
		write_varint(i, &ptr, &size_rem, &bytes_written);
		const uint8_t *ptr2 = buff;
		size_t size_rem2 = sizeof(buff);
		int bytes_read = 0;
		int decoded_varint = read_varint(&ptr2, &size_rem2, &bytes_read);

		if ( (i & 0xfffffff) == 0) {
			std::cout << "val " << i << " decoded into: " << to_str(buff, bytes_read) << std::endl;
		}
		if (decoded_varint != i) {
			std::cout << "Test failed for val " << i << std::endl;
		}
	}
#endif
	
}
