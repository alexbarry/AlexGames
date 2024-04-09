#include "saved_state_db.h"
#include "saved_state_db_c_api.h"

void *saved_state_db_init(void *L, const struct game_api_callbacks *callbacks) {
	SavedStateDb *db = new SavedStateDb(L, callbacks);
	db->refresh_internal_state();
	return db;
}

int saved_state_db_get_new_session_id(void *handle) {
	SavedStateDb *db = (SavedStateDb*)handle;
	return db->get_new_session_id();
}

int saved_state_db_get_last_session_id(void *handle, const char *game_id) {
	SavedStateDb *db = (SavedStateDb*)handle;
	return db->get_last_session_id(game_id);
}

void saved_state_db_save_state(void *handle, const char *game_id, int session_id, const uint8_t *state, size_t state_len) {
	SavedStateDb *db = (SavedStateDb*)handle;

	db->save_state(game_id, session_id, state, state_len);
}


bool saved_state_db_has_saved_state_offset(void *handle, int session_id, int move_id_offset) {
	SavedStateDb *db = (SavedStateDb*)handle;

	return db->has_saved_state_offset(session_id, move_id_offset);
}

int saved_state_db_get_saved_state_offset(void *handle, int session_id, int move_id_offset, uint8_t *state, size_t state_len) {
	SavedStateDb *db = (SavedStateDb*)handle;

	return db->adjust_saved_state_offset(session_id, move_id_offset, state, state_len);
}
