

#ifdef __cplusplus
extern "C" {
#endif

#include "game_api.h"

void *saved_state_db_init(void *L, const struct game_api_callbacks *callbacks);
void saved_state_db_save_state(void *handle, const char *game_id, int session_id, const uint8_t *state, size_t state_len);
int saved_state_db_get_new_session_id(void *handle);
int saved_state_db_get_last_session_id(void *handle, const char *game_id);
bool saved_state_db_has_saved_state_offset(void *handle, int session_id, int move_id_offset);
int saved_state_db_get_saved_state_offset(void *handle, int session_id, int move_id_offset, uint8_t *state, size_t state_len);



#ifdef __cplusplus
}
#endif
