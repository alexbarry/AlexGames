#include <emscripten.h>
#include <stdio.h>
#include <time.h>

#include "c_dictionary.h"

EM_JS(void*, em_js_dict_init, (const char *language_ptr), {
	console.log("[dict] emscripten_c_dict_api: em_js_dict_init called. Using C dictionary after words file download complete.\n");

	if (em_js_dict_init.call_counts === undefined) {
		em_js_dict_init.call_counts = 0;
	}
	em_js_dict_init.call_counts += 1;

	if (em_js_dict_init.call_counts > 2) {
		console.error("em_js_dict_init.call_counts is", em_js_dict_init.call_counts);
		return;
	}

	js_c_dict_init();

});
static void *g_dict_handle = NULL;

static bool dict2_is_dict_ready(void) {
	return g_dict_handle != NULL;
}

static bool dict2_is_valid_word(void *dict_handle, const char *word_ptr) {
	return get_c_dictionary_api()->is_valid_word(g_dict_handle, word_ptr);
}

static word_freq_t dict2_get_word_freq(void *dict_handle, const char *word_ptr) {
	return get_c_dictionary_api()->get_word_freq(g_dict_handle, word_ptr);
}

static int dict2_get_random_word(void *dict_handle,
                                 const struct word_query_params *params,
                                 char *word_out, size_t max_word_out_len,
                                 int *possib_word_count_out) {
	return get_c_dictionary_api()->get_random_word(g_dict_handle,
	                                               params,
	                                               word_out, max_word_out_len,
	                                               possib_word_count_out);
}

static const struct game_dict_api api = {
	dict2_is_dict_ready,
	em_js_dict_init,
	dict2_is_valid_word,
	dict2_get_word_freq,
	dict2_get_random_word,
	NULL,
};

const struct game_dict_api *get_emscripten_game_dict_api(void) {
	return &api;
}

EMSCRIPTEN_KEEPALIVE
void update_dict() {
	printf("update_dict called, seeding random number generator\n");
	srandom(time(NULL));
	g_dict_handle = build_word_dict_from_file("words-en.txt");
}
