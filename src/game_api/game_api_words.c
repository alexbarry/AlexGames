#include <stdio.h>

#include "game_api_words.h"

#include "c_dictionary.h"

static const struct game_dict_api *g_dict_api = NULL;

struct word_query_params get_default_params(void) {
	struct word_query_params params = {
		.min_length =  0,
		.max_length = 99,
		.min_freq   =  0e0,
		.include_weird_or_vulgar = false,
	};

	return params;
}


void set_game_dict_api(const struct game_dict_api *dict_api) {
	g_dict_api = dict_api;
}

const struct game_dict_api *get_game_dict_api(void) {
	if (g_dict_api != NULL) {
		printf("[dict] get_game_dict_api returning dict pointer set by set_game_dict_api\n");
		return g_dict_api;
	} else {
#ifdef ALEXGAMES_C_DICT_NOT_INCLUDED
		fprintf(stderr, "WARNING: get_game_dict_api() called without being set "
		                "by calling set_game_dict_api. Normally this would cause "
		                "the C dictionary implementation to be used, but it is "
		                "likely not linked in because ALEXGAMES_C_DICT_NOT_INCLUDED "
		                "is set.\n");
		return NULL;
#else
		printf("[dict] get_game_dict_api returning default C implementation\n");
		return get_c_dictionary_api();
#endif
	}
}
