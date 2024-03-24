//typedef int (*create_word_table_t    )(void *handle);
typedef int (*add_word_to_list_func_t)(void *handle, int row_idx, int argc, const unsigned char **argv);
//typedef int (*word_table_done_t      )(void *handle);

struct word_callback_data {
	void *handle;
	//create_word_table_t     create_word_table;
	add_word_to_list_func_t add_word_to_list_func;
	//word_table_done_t       word_table_done;
};

void *init_dict();
void get_words(void *dict_handle, const char *query, struct word_callback_data *data);
void teardown_dict(void *dict_handle);
