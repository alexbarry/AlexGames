#include<stdint.h>
#include<string>
/**
 * When starting a new game session, games should request a session ID from this class.
 * This class will return the next available session ID.
 *
 * Whenever a game's state updates, it should pass its session ID and current state to this class.
 * This class will store that state in the database.
 *
 * When a user wishes to browse their previous saved game sessions, this class will allow for easy
 * traversal of them, from order of newest to oldest. 
 * 
 */
class SavedStateDb {
	public:
	SavedStateDb(void *L, const struct game_api_callbacks *callbacks);
	bool refresh_internal_state(void);

	/**
	 * Returns the next available session ID.
	 * If a game saves state to this session ID, it creates a new entry in the database,
	 * and the head is incremented.
	 */
	uint32_t get_new_session_id(void);

	/**
	 * Returns the last session ID for a given game. Returns -1 if
	 * none was found.
	 *
	 * This is helpful for games loading their last saved game when
	 * started. They can call this API to get the session ID, then
	 * `adjust_saved_state_offset(session_id=session_id, move_id_offset=0)`
	 * to load the last saved state.
	 */
	uint32_t get_last_session_id(const char *game_id);

	/**
	 * Returns the tail session ID. If this equals `get_new_session_id()` then no saved sessions
	 * are present.
	 */
	uint32_t get_session_id_tail(void);
	void save_state(std::string game_id, int session_id, const uint8_t *data, size_t data_len);


	size_t read_state(int session_id, int move_id, uint8_t *state_out, size_t max_state_len);
	void read_state_info(int session_id,
                         char *game_id_out,  size_t max_game_id_out_len,
                         char *date_out,     size_t max_date_out_len,
                         uint32_t *move_id_out);
	uint32_t get_next_move_id(int session_id);

	bool has_saved_state_offset(int session_id, int move_id_offset);
	int adjust_saved_state_offset(int session_id, int move_id_offset, uint8_t *state_out, size_t max_state_len);

	private:
	void *L;
	const struct game_api_callbacks *callbacks;

	/** Points to one greater than the last written database entry.
	 *  If equal to `session_tail`, then no data is present.
	 */
	uint32_t session_head;

	/**
	 * Points to the last database entry valid to be read.
	 * Entries less than this are invalid, they were deleted to free space.
     */
	uint32_t session_tail;

	void error(std::string msg);
	bool read_uint32(const char *key, uint32_t *out_val, uint32_t default_val);
	bool write_uint32(const char *key, uint32_t val);
	bool write_uint32(std::string key, uint32_t val);
	bool write_state(int session_id, int move_id, const uint8_t *state, size_t state_len);
	void read_stored_string(const char *key, char *str_out, size_t max_str_out_len);
};
