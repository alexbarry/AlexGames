/**
 * This file is bindings to the javascript implementation of the dictionary.
 * I think the C dictionary is better: it uses significantly less memory.
 *
 * But this file will remain so I can switch between them at build time if needed.
 */
#include <emscripten.h>

#include "game_api_words.h"

// TODO call all the functions defined in alexgames_dict.js
// then add Lua bindings for these APIs.
// Then maybe move the SQL ones to a C lib that is used on Android and wxWidgets

EM_JS(bool, js_is_dict_ready, (void), {
	console.debug("js_is_dict_ready:", gfx.dict);
	return !!gfx.dict;
});

EM_JS(void*, em_js_dict_init, (const char *language_ptr), {
	console.log("[dict] emscripten_dict_api.c: js_dict_init called. Using JS dictionary\n");
	// maybe call below EM_JS

	// gfx.dict = fetch_words_list("words.txt");
	let language = UTF8ToString(language_ptr);
	js_dict_init(language);
});

EM_JS(bool, js_is_valid_word, (void *dict_handle, const char *word_ptr), {
	let word = UTF8ToString(word_ptr);
	console.log("checking if word", word, "is a valid word");
	return is_valid_word(gfx.dict, word);
});

EM_JS(word_freq_t, js_get_word_freq, (void *dict_handle, const char *word_ptr), {
	let word = UTF8ToString(word_ptr);
	return get_word_freq(gfx.dict, word);
});

//int js_get_random_word(void *dict_handle,
//                                const struct word_query_params *params,
//                                char *word_out, size_t max_word_out_len,
//                                int *possib_word_count_out) {
EM_JS(int, js_get_random_word_wrapper, (void *dict_handle,
                                //const struct word_query_params *params,
                                int min_length, int max_length, float min_freq,
                                char *word_out, size_t max_word_out_len,
                                int *possib_word_count_out), {

	if (!gfx.dict) {
		console.warn("word_dict not yet loaded! Returning empty word, hopefully the game will be reloaded soon");
		writeStringToPtr(word_out, max_word_out_len, "");
		return 0;
	}
	//console.log("params: ", params, "manually enumerating fields:", params.min_length, params.max_length, params.min_freq);
	let params = {
		min_length: min_length,
		max_length: max_length,
		min_freq:   min_freq,
	};
	let word = get_random_word(gfx.dict, params);

	writeStringToPtr(word_out, max_word_out_len, word);

	return word.length;
});

int js_get_random_word(void *dict_handle,
                                const struct word_query_params *params,
                                char *word_out, size_t max_word_out_len,
                                int *possib_word_count_out) {
	return js_get_random_word_wrapper(dict_handle, params->min_length, params->max_length, params->min_freq,
	                                  word_out, max_word_out_len, possib_word_count_out);
}

static int js_get_words_made_from_letters(void *dict_handle,
                                       const struct word_query_params *params,
                                       const char *letters) {
	// TODO
	return 0;
}


const struct game_dict_api *get_emscripten_game_dict_api(void) {
	static const struct game_dict_api api = {
		js_is_dict_ready,
		em_js_dict_init,
		js_is_valid_word,
		js_get_word_freq,
		js_get_random_word,
		js_get_words_made_from_letters,
	};

	return &api;
}
