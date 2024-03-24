#include<stdio.h>
#include<stdint.h>
#include<stdlib.h>
#include<assert.h>

// for log function
#include "game_api.h"


const static char ENC_TABLE[] = {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
	'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
	'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
	'+', '/'
};

static bool decoding_table_init = false;
static char decoding_table[256];

const static uint8_t MOD_TABLE[] = {0, 2, 1};


static void init_decoding_table(void);

static uint8_t enc_val(uint32_t val) {
	assert(val < sizeof(ENC_TABLE));
	return ENC_TABLE[val];
}

size_t write_b64(char *state_out, size_t state_out_len, const uint8_t *input_buff, size_t input_buff_len) {
	printf("called %s\n", __func__);
	const int output_length = 4 * ((input_buff_len + 2)/3);
	if (state_out_len <= output_length) {
		alex_log_err("%s: output buff (%d bytes) is too small to write encoded input (unenc %d, enc %d)\n",
		             __func__, state_out_len, input_buff_len, output_length);
		return 0;
	}

	int i;
	int output_idx = 0;
	for (i=0; i<input_buff_len;) {
		uint32_t a = i < input_buff_len ? input_buff[i++] : 0;
		uint32_t b = i < input_buff_len ? input_buff[i++] : 0;
		uint32_t c = i < input_buff_len ? input_buff[i++] : 0;

		uint32_t val = (a << 0x10) | (b << 0x08) | c;

		state_out[output_idx++] = enc_val((val >> 3 * 6) & 0x3F);
		state_out[output_idx++] = enc_val((val >> 2 * 6) & 0x3F);
		state_out[output_idx++] = enc_val((val >> 1 * 6) & 0x3F);
		state_out[output_idx++] = enc_val((val >> 0 * 6) & 0x3F);
	}

	for (i = 0; i<MOD_TABLE[input_buff_len % 3]; i++) {
		state_out[output_length - 1 - i] = '=';
	}

	return output_idx;
}

size_t b64_encoded_size_to_max_decoded_size(size_t encoded_input_len) {
	return encoded_input_len / 4 * 3;
}

size_t decode_b64(uint8_t *decoded_out, size_t decoded_out_max_len,
                  const char *encoded_input, size_t encoded_input_len) {

	if (!decoding_table_init) {
		init_decoding_table();
	}

	if (encoded_input_len % 4 != 0) {
		alex_log_err("%s: input length %d is not a multiple of 4\n",
		             __func__, encoded_input_len);
		return 0;
	}

	size_t output_length = b64_encoded_size_to_max_decoded_size(encoded_input_len);

	if (encoded_input[encoded_input_len - 1] == '=') { output_length--; }
	if (encoded_input[encoded_input_len - 2] == '=') { output_length--; }

	int i, j;
	for (i=0, j=0; i<encoded_input_len;) {
		uint32_t a = encoded_input[i] == '=' ? 0 : decoding_table[(int)encoded_input[i]];
		i++;
		uint32_t b = encoded_input[i] == '=' ? 0 : decoding_table[(int)encoded_input[i]];
		i++;
		uint32_t c = encoded_input[i] == '=' ? 0 : decoding_table[(int)encoded_input[i]];
		i++;
		uint32_t d = encoded_input[i] == '=' ? 0 : decoding_table[(int)encoded_input[i]];
		i++;

		uint32_t val = (a << 3 * 6) |
		               (b << 2 * 6) |
		               (c << 1 * 6) |
		               (d << 0 * 6);

		if (j < output_length) { decoded_out[j++] = (val >> 2 * 8) & 0xFF; }
		if (j < output_length) { decoded_out[j++] = (val >> 1 * 8) & 0xFF; }
		if (j < output_length) { decoded_out[j++] = (val >> 0 * 8) & 0xFF; }
	}

	return output_length;
}

static void init_decoding_table(void) {
	int i;	
	for (i=0; i<sizeof(ENC_TABLE); i++) {
		decoding_table[(int)ENC_TABLE[i]] = i;
	}
	decoding_table_init = true;
}
