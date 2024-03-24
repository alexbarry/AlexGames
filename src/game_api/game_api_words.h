#ifndef GAME_API_WORDS_H
#define GAME_API_WORDS_H

#include<stdbool.h>
#include<stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_WORD_LEN (64)

typedef float word_freq_t;

struct word_query_params {
	int min_length;
	int max_length;
	word_freq_t min_freq;
	bool include_weird_or_vulgar;
};


struct game_dict_api {
	bool (*is_ready)(void);

	void* (*init)(const char *language);

	/**
	 * Checks if word is in the dictionary.
	 */
	bool (*is_valid_word)(void *dict_handle, const char *word);

	word_freq_t (*get_word_freq)(void *dict_handle, const char *word);

	/**
	 * Gets random word of specified length and minimum frequency.
	 */
	int (*get_random_word)(void *dict_handle,
	                       const struct word_query_params *params,
	                       char *word_out, size_t max_word_out_len,
	                       int *possib_word_count_out);

	/**
	 * Gets list of words that can be made from a subset of the
	 * provided letters.
	 */
	int (*get_words_made_from_letters)(void *dict_handle,
	                                   const struct word_query_params *params,
	                                   const char *letters);
};

struct word_query_params get_default_params(void);

const struct game_dict_api *get_game_dict_api(void);

void set_game_dict_api(const struct game_dict_api *dict_api);

#ifdef __cplusplus
}
#endif

#endif
