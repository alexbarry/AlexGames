

#include "game_api_words.h"

#ifdef __cplusplus
extern "C" {
#endif

void *build_word_dict_from_file(const char *fname);


const struct game_dict_api *get_game_dict_api(void);
const struct game_dict_api *get_c_dictionary_api(void);

#ifdef __cplusplus
}
#endif
