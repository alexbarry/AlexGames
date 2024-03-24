#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void *init_sqlite_saved_state(const char *fname);
int set_value(void *handle, const char *key,
              const uint8_t *value, size_t value_len);
int get_value(void *handle, const char *key,
              uint8_t *value_out, size_t max_value_len);
void destroy_sqlite_saved_state(void *handle);


#ifdef __cplusplus
}
#endif
