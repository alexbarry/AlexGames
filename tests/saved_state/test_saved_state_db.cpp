#include<stdio.h>
#include<setjmp.h>

#include<iostream>
#include<string>
#include<vector>
#include<unordered_map>

#include "game_api.h"
#include "game_api_helper.h"
#include "saved_state_db.h"

static jmp_buf env_err;

static std::vector<uint8_t> c_data_to_vec(const uint8_t *value, size_t value_len) {
	std::vector<uint8_t> vec;
	for (int i=0; i<value_len; i++) {
		vec.push_back(value[i]);
	}
	return vec;
}

class TestState {
	public:
	struct game_api_callbacks callbacks;
	struct std::unordered_map<std::string, std::vector<uint8_t>> raw_stored_data;
	TestState() {
		this->callbacks = create_default_callbacks();
		
		callbacks.store_data = [](void *L_ptr, const char *key, const uint8_t *value, size_t value_len) {
			TestState *L = (TestState*)L_ptr;
			L->raw_stored_data[std::string(key)] = c_data_to_vec(value, value_len);
		};
		callbacks.read_stored_data = [](void *L_ptr, const char *key_ptr, uint8_t *value_out, size_t max_value_out_len) -> size_t {
			TestState *L = (TestState*)L_ptr;
			std::string key(key_ptr);
			if (L->raw_stored_data.find(key) == L->raw_stored_data.end()) {
				return -1;
			}
			std::vector<uint8_t> data = L->raw_stored_data[key];
			int i;
			for (i=0; i<max_value_out_len, i<data.size(); i++) {
				value_out[i] = data[i];
			}
			return i;
		};

		// TODO dammit, can I set the save/read state callbacks to lambdas?
	}
};

static std::string to_str(const std::vector<uint8_t> data) {
	std::string s = "{";
	for (int i=0; i<data.size(); i++) {
		char buff[8];
		snprintf( buff, sizeof(buff), "%02x ", data[i]);
		s += std::string(buff);
	}
	s += "}";
	return s;
}

void assert_eq_func(const std::vector<uint8_t> &actual,
                    const std::vector<uint8_t> &expected,
                    const char *file, int line, const char *msg) {
	bool vals_not_eq = false;

	if (actual.size() != expected.size()) {
		vals_not_eq = true;
	} else {
		for (int i=0; i<actual.size(); i++) {
			if (actual[i] != expected[i]) {
				vals_not_eq = true;
				break;
			}
		}
	}
	
	if (vals_not_eq) {
		std::cerr << "assert_eq failed, actual=" << to_str(actual)
		          << ", expected=" << to_str(expected)
		          << "; " << file << ":" << line
		          << " msg=" << msg
		          << std::endl;
		longjmp(env_err, -1);
	}
}



void assert_eq_func(int actual, int expected, const char *file, int line, const char *msg) {
	if (actual != expected) {
		std::cerr << "assert_eq failed, actual=" << actual
		          << ", expected=" << expected
		          << "; " << file << ":" << line
		          << " msg=" << msg
		          << std::endl;
		longjmp(env_err, -1);
	}
}

#define assert_eq_msg(actual, expected, msg) \
	assert_eq_func(actual, expected, __FILE__, __LINE__, msg)

#define assert_eq(actual, expected) \
	assert_eq_msg(actual, expected, "")


static std::vector<uint8_t> read_state(SavedStateDb *db, int session_id, int move_id) {
#if 0
	char game_id[128];
	char date_str[128];
	uint32_t move_count;

	db->read_state_info(session_id,
	                    game_id, sizeof(game_id),
	                    date_str, sizeof(date_str),
	                    &move_count);
	int move_id = move_count;
#endif
	uint8_t game_state[4096];
	size_t game_state_len = db->read_state(session_id, move_id,
	                                       game_state, sizeof(game_state));
	if (game_state_len == -1) {
		// This means that you tried to read state that isn't defined
		std::cerr << "db->read_state returned -1" << std::endl;
		longjmp(env_err, -1);
	}

	std::vector<uint8_t> game_state_vec(game_state_len);
	for (int i=0; i<game_state_len; i++) {
		game_state_vec[i] = game_state[i];
	}

	return game_state_vec;
}

static std::vector<uint8_t> generate_test_game_state(int sess, int move) {
#if 0
	sess += 6;
	move += 12;

	sess *= 41*41;
	move *= 71*41;
#endif

	return { (uint8_t)((sess>>8) & 0xFF), (uint8_t)(sess & 0xFF),
	         (uint8_t)((move>>8) & 0xFF), (uint8_t)(move & 0xFF) };
}

static int get_move_count(int session) {
	return (session * 17) + 1;
}

static std::string tostringf(const char *fmt, ...) {
	char buff[4096];
	va_list args;
	va_start(args, fmt);
	vsnprintf(buff, sizeof(buff), fmt, args);
	va_end(args);
	return std::string(buff);
}

static std::string get_game_id(int session) {
	return "test_game_id";
	//return tostringf("test_game_sess%03d", session);
}

static void save_state(SavedStateDb *db, int sess_id, int move_id) {
	const std::vector<uint8_t> data = generate_test_game_state(sess_id, move_id);
	db->save_state(get_game_id(sess_id).c_str(), sess_id, &data[0], data.size());
}

static void test_saved_state(SavedStateDb *db, int sess_id, int move_id) {
	const std::vector<uint8_t> expected = generate_test_game_state(sess_id, move_id);
	const std::vector<uint8_t> actual = read_state(db, sess_id, move_id);
	assert_eq(actual, expected);
}

static void test_all_sessions(SavedStateDb *db, int session_count, bool fill) {
	for (int session=0; session<session_count; session++) {

		int sess_id;
		if (fill) {
			sess_id = db->get_new_session_id();
			assert_eq(sess_id, session);
		} else {
			sess_id = session;
		}
		//printf("Starting test for sess=%d, sess_id=%d\n", session, sess_id);
	
		int move_count = get_move_count(session);
		for (int move_id=0; move_id<move_count; move_id++) {
			//printf("Saving state for sess=%d, move=%d\n", sess_id, move_id);

			const std::vector<uint8_t> data1 = generate_test_game_state(sess_id, move_id);
			if (fill) {
				db->save_state(get_game_id(sess_id), sess_id, &data1[0], data1.size());
				assert_eq(db->get_new_session_id(), session + 1);
			}
		
			assert_eq(db->get_session_id_tail(), 0);
			assert_eq_msg(read_state(db, sess_id, move_id), data1, tostringf("sess=%d, move=%d, fill=%b", session, move_id, fill).c_str());
		}
	}

}

int main(void) {

	TestState test_state;
	SavedStateDb db(&test_state, &test_state.callbacks);
	db.refresh_internal_state();

	if (setjmp(env_err)) {
		std::cout << "Test failed!" << std::endl;
		return -1;
	}


	assert_eq(db.get_new_session_id(), 0);
	assert_eq(db.get_session_id_tail(), 0);

	int session_count = 15;

	test_all_sessions(&db, session_count, true);
	test_all_sessions(&db, session_count, false);

	int extra_move_count = 123;
	for (int sess=session_count-1; sess>=0; sess--) {
		for (int extra_moves=0; extra_moves<extra_move_count; extra_moves++) {
			//printf("Saving state sess=%d, extra_move=%d\n", sess, extra_moves);
			int move = get_move_count(sess) + extra_moves;
			save_state(&db, sess, move);
		}
	}

	//printf("Testing all sessions again...\n");
	test_all_sessions(&db, session_count, false);
	for (int sess=0; sess<session_count; sess++) {
		for (int extra_moves=0; extra_moves<extra_move_count; extra_moves++) {
			//printf("Testing extra state move: sess=%d, extra_move=%d\n", sess, extra_moves);
			int move = get_move_count(sess) + extra_moves;
			test_saved_state(&db, sess, move);
		}
	}

	std::cout << "Test " << __FILE__ << " passed!" << std::endl;
	return 0;
}
