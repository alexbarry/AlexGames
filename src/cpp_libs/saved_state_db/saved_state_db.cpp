#include<stdio.h>
#include<iostream>

#include "game_api.h"

#include "saved_state_db.h"

//
// TODO:
// 		* need to store name of game along with each session
//

// TODO:
//  * if the user makes their first move, I'd like to support
//    undoing that move. But how? I don't save state for the empty board
//    at the beginning. Should I?

#define KEY_SESSION_HEAD ("state_db_sess_head")
#define KEY_SESSION_TAIL ("state_db_sess_tail")

#define UINT32_BYTES (sizeof(uint32_t))

static uint32_t parse_uint32_db_entry(const uint8_t *data, size_t data_len);
static void write_uint32_to_bytes(uint32_t val, uint8_t *data, size_t data_len);
static std::string get_key_state(int session_id, int move_id);
static std::string get_key_session_move_id(int session_id);
static std::string get_key_last_updated(int session_id);
static std::string get_key_game_id(int session_id);
static std::string get_key_last_session_id(std::string game_id);
static std::string get_key_last_session_id(const char *game_id);

SavedStateDb::SavedStateDb(void *L, const struct game_api_callbacks *callbacks) {
	this->L = L;
	this->callbacks = callbacks;
}

bool SavedStateDb::refresh_internal_state(void) {
	bool head_present = read_uint32(KEY_SESSION_HEAD, &this->session_head, 0);
	bool tail_present = read_uint32(KEY_SESSION_TAIL, &this->session_tail, 0);

	//std::cout << "SavedStateDb: Read head=" << session_head << ", tail=" << session_tail << std::endl;

	if (!head_present || !tail_present) {
		write_uint32(KEY_SESSION_HEAD, this->session_head);
		write_uint32(KEY_SESSION_TAIL, this->session_tail);
	}

	return true;
}

uint32_t SavedStateDb::get_new_session_id(void) {
	return session_head;
}

uint32_t SavedStateDb::get_session_id_tail(void) {
	return session_tail;
}
	

void SavedStateDb::save_state(std::string game_id, int session_id, const uint8_t *data, size_t data_len) {
	//std::cout << "SavedStateDb::save_state called, sesion_id=" << session_id << std::endl;
	// Maybe check if the session_id is valid? 

	// TODO need to handle wrapping...
	// TODO FIXME this doesn't work now, what did I break?
	// add tests for this...
	if (session_tail <= session_id && session_id < session_head) {
	//if (session_id == session_head) {
		//std::cout << "session_id=" << session_id << " is between tail=" << session_tail
		//          << " and head=" << session_head << ", not incrementing head" << std::endl;
		// this is okay, we're writing to an existing session
	} else if (session_id == session_head) {
		// we're writing to a new session here.
		//std::cout << "Storing new session " << session_id << std::endl;
		session_head++;
		write_uint32(KEY_SESSION_HEAD, this->session_head);
		callbacks->store_data(L, get_key_game_id(session_id).c_str(), (const uint8_t *)game_id.c_str(), game_id.size());
	} else {
		std::cerr << "save_state: invalid_session_id = " << session_id
		          << ", tail=" << session_tail << ", head=" << session_head
		          << std::endl;
		error("save_state: invalid session_id");
		return;
	}

	uint32_t move_id = -1;
	read_uint32(get_key_session_move_id(session_id).c_str(), &move_id, -1);
	//std::cout << "read move_id: " << move_id << std::endl;
	move_id++;

	// TODO need to delete (or fork, in the future) all following moves if
	// any exist? e.g. if you "undo" 1 or more times, then make a new move, the other moves
	// should be deleted-- you shouldn't be able to "redo" into them.
	write_state(session_id, move_id, data, data_len);

	char date_data[64];
	size_t date_len = callbacks->get_time_of_day(date_data, sizeof(date_data));
	callbacks->store_data(L, get_key_last_updated(session_id).c_str(), (const uint8_t*)date_data, date_len);


	//std::cout << "writing move_id: " << move_id << std::endl;
	write_uint32(get_key_session_move_id(session_id).c_str(), move_id);
	std::cout << "[saved_state] storing session id " << session_id << " move id: " << move_id << std::endl;

	write_uint32(get_key_last_session_id(game_id), session_id);
}


size_t SavedStateDb::read_state(int session_id, int move_id, uint8_t *state_out, size_t max_state_len) {
	//std::cout << "SavedStateDb::read_state {session_id = " << session_id << ", move_id = " << move_id << "}" << std::endl;

	return callbacks->read_stored_data(L, get_key_state(session_id, move_id).c_str(), state_out, max_state_len);
}

void SavedStateDb::read_state_info(int session_id,
                                   char *game_id_out,  size_t max_game_id_out_len,
                                   char *date_out,     size_t max_date_out_len,
                                   uint32_t *move_id_out) {
	read_stored_string(get_key_game_id(session_id).c_str(),      game_id_out, max_game_id_out_len);
	read_stored_string(get_key_last_updated(session_id).c_str(), date_out,    max_date_out_len);
	*move_id_out = get_next_move_id(session_id);
}

bool SavedStateDb::read_uint32(const char *key, uint32_t *out_val, uint32_t default_val) {
	uint8_t byte_ary[UINT32_BYTES];
	//printf("read_uint32 reading key \"%s\"\n", key);
	int bytes_read = callbacks->read_stored_data(L, key, byte_ary, sizeof(byte_ary));
	//for (int i=0; i<sizeof(byte_ary); i++) {
	//	printf("%02x ", byte_ary[i]);
	//}
	//printf("\n");
	if (bytes_read == -1) {
		//std::cout << "bytes_read is -1, returning default value" << std::endl;
		*out_val = default_val;
		return false;
	} else if (bytes_read != UINT32_BYTES) {
		fprintf(stderr, "read %d bytes from DB for key %s, expected %zu\n", bytes_read, key, UINT32_BYTES);
		error("read invalid number of bytes from db");
		return false;
	} else {
		*out_val = parse_uint32_db_entry(byte_ary, sizeof(byte_ary));
		return true;
	}
}

bool SavedStateDb::write_uint32(const char *key, uint32_t val) {
	uint8_t byte_ary[UINT32_BYTES];

	write_uint32_to_bytes(val, byte_ary, sizeof(byte_ary));

	callbacks->store_data(L, key, byte_ary, sizeof(byte_ary));

	// TODO may need to deal with local storage being full?
	return true;
}

bool SavedStateDb::write_uint32(std::string key, uint32_t val) {
	return write_uint32(key.c_str(), val);
}

bool SavedStateDb::write_state(int session_id, int move_id, const uint8_t *data, size_t data_len) {
	std::string db_key = get_key_state(session_id, move_id);
	callbacks->store_data(L, db_key.c_str(), data, data_len);
	return true;
}

uint32_t SavedStateDb::get_next_move_id(int session_id) {
	std::string key = get_key_session_move_id(session_id);

	uint32_t move_id = 0;
	read_uint32(key.c_str(), &move_id, 0);
	
	return move_id;
}

void SavedStateDb::error(std::string msg) {
	std::cerr << msg << std::endl;
	callbacks->set_status_err(msg.c_str(), msg.size());
}


void SavedStateDb::read_stored_string(const char *key, char *str_out, size_t max_str_out_len) {
	int bytes_read = callbacks->read_stored_data(L, key, (uint8_t*)str_out, max_str_out_len);
	if (bytes_read != -1) {
		str_out[bytes_read] = '\0';
	} else {
		str_out[0] = '\0';
	}
}


bool SavedStateDb::has_saved_state_offset(int session_id, int move_id_offset) {
	uint32_t move_id = -1;
	bool move_id_stored = read_uint32(get_key_session_move_id(session_id).c_str(), &move_id, -1);
	// is this ever possible in non erroneous conditions?
	if (!move_id_stored) {
		return false;
	}

	move_id += move_id_offset;

	int bytes_read = callbacks->read_stored_data(L, get_key_state(session_id, move_id).c_str(), NULL, 0);

	return bytes_read > 0;
}

int SavedStateDb::get_saved_state_offset(int session_id, int move_id_offset, uint8_t *state_out, size_t max_state_len) {
	uint32_t move_id = -1;
	bool move_id_stored = read_uint32(get_key_session_move_id(session_id).c_str(), &move_id, -1);
	// is this ever possible in non erroneous conditions?
	if (!move_id_stored) {
		return false;
	}

	move_id += move_id_offset;

	int bytes_read = callbacks->read_stored_data(L, get_key_state(session_id, move_id).c_str(), state_out, max_state_len);

	write_uint32(get_key_session_move_id(session_id).c_str(), move_id);

	return bytes_read;
}


uint32_t SavedStateDb::get_last_session_id(const char *game_id) {
	uint32_t session_id = -1;
	bool session_id_stored = read_uint32(get_key_last_session_id(game_id).c_str(), &session_id, -1);

	if (!session_id_stored) {
		return -1;
	}

	// TODO if there are no moves stored despite the last session ID being set,
	// then return -1 here and do a developer error message

	return session_id;
}

static uint32_t parse_uint32_db_entry(const uint8_t *data, size_t data_len) {
	if (data_len != 4) {
		std::cerr << "parse_uint32_db_entry called with " << data_len << " bytes" << std::endl;
		return -1;
	}

	uint32_t val = 0;
	for (int i=0; i<data_len; i++) {
		val |= data[i] << (8*(3-i));
		//printf("read byte %02x at pos %d, val is now %08x\n", data[i], i, val);
	}

	return val;
}

static void write_uint32_to_bytes(uint32_t val, uint8_t *data, size_t data_len) {
	if (data_len != 4) {
		std::cerr << "write_uint32_to_bytes called with " << data_len << " bytes" << std::endl;
		return;
	}

	for (int i=0; i<data_len; i++) {
		data[i] = (val >> (8*(3-i))) & 0xFF;
	}
}

static std::string get_key_state(int session_id, int move_id) {
	char db_key[128];
	snprintf(db_key, sizeof(db_key), "state_%04x_%04x", session_id, move_id);
	return std::string(db_key);
}

static std::string get_key_session_move_id(int session_id) {
	char db_key[128];
	snprintf(db_key, sizeof(db_key), "state_%04x_last_move_id", session_id);
	return std::string(db_key);
}

static std::string get_key_last_updated(int session_id) {
	char db_key[128];
	snprintf(db_key, sizeof(db_key), "state_%04x_last_updated", session_id);
	return std::string(db_key);
}

static std::string get_key_game_id(int session_id) {
	char db_key[128];
	snprintf(db_key, sizeof(db_key), "state_%04x_game_id", session_id);
	return std::string(db_key);
}
	

static std::string get_key_last_session_id(const char *game_id) {
	char db_key[128];
	snprintf(db_key, sizeof(db_key), "game_%s_last_sess_id", game_id);
	return std::string(db_key);
}

static std::string get_key_last_session_id(std::string game_id) {
	return get_key_last_session_id(game_id.c_str());
}
