# Saved State DB

This library allows games to blindly call a method that stores game state (as a bytearray) over and over in a data structure that handles moving between previous states (e.g. undo and redo buttons).

It uses the these APIs defined in `game_api.h`:
* `store_data(string key, byte[] data)`: write data (bytearray), referenced by key (string).
* `byte[] read_stored_data(string key)`: read data stored at key.

It provides new APIs used by games (or Lua bindings):
* `int get_new_session_id()`: meant to be called by a game at the beginning of a new game session. This ID is used to group saved states together.
* `save_state(int session_id, byte[] state)`: games can call repeatedly every time the player makes a significant move. The library should automatically store the state in a data structure that makes it easy to access later.
* `bool has_saved_state_offset(int session_id, int move_id_offset)`:
* `byte[] adjust_saved_state_offset(int session_id, int move_id_offset)`

TODO: finish this
