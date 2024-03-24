

size_t b64_encoded_size_to_max_decoded_size(size_t encoded_input_len);

size_t write_b64(char *state_out, size_t state_out_len, const uint8_t *input_buff, size_t input_buff_len);
size_t decode_b64(uint8_t *decoded_out, size_t decoded_out_max_len,
                  const char *encoded_input, size_t encoded_input_len);
