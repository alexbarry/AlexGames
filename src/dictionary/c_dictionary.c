#include "game_api_words.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#include <time.h>
#include<sys/time.h>

#include "c_dictionary.h"
#include "game_api.h"

#ifdef ALEXGAMES_WASM
#include<emscripten.h>
#endif

#define WORD_METADATA_NONE            ((word_metadata_t)0)
#define WORD_METADATA_VULGAR_OR_WEIRD ((word_metadata_t)1)

typedef uint8_t word_metadata_t;


#define WORD_NOT_FOUND_FREQ (-1)

#define WORD_FRAME_SIZE (4*1024)

struct word_dict_frame {
	struct word_dict_frame *next;
	int word_count;
	char data[WORD_FRAME_SIZE - sizeof(void*) - sizeof(int)];
};

struct word_info_ptrs {
	const char *word;
	word_freq_t *freq;
	word_metadata_t *metadata;
};

static int get_word_count(const struct word_dict_frame *frame);
static bool dict_is_valid_word(void *dict_handle, const char *word);
static word_freq_t get_word_freq_in_frame(const struct word_dict_frame *frame, const char *word);

static struct word_dict_frame* create_frame(void) {
	static int frame_count = 0;
	//printf("Created %d frames so far...\n", ++frame_count);
	struct word_dict_frame *frame = malloc(sizeof(struct word_dict_frame));
	assert(frame != NULL);
	frame->word_count = 0;
	frame->next = NULL;
	return frame;
}


long long timeInMilliseconds(void) {
    struct timeval tv;

    gettimeofday(&tv,NULL);
    return (((long long)tv.tv_sec)*1000)+(tv.tv_usec/1000);
}

static int add_word_to_frame(struct word_dict_frame *frame, int pos, const char *word, int word_len, word_freq_t freq, word_metadata_t word_metadata) {
	//printf("Adding word %.*s to frame\n", word_len, word);
	//printf("pos=%d, word_len=%d, sizeof(frame->data)=%d\n", pos, word_len, sizeof(frame->data));

	if (pos + word_len + 1 + sizeof(freq) + sizeof(word_metadata) + 1 > sizeof(frame->data)) {
		return 0;
	}
	const int orig_pos = pos;

	memcpy(frame->data + pos, word, word_len);
	frame->word_count++;
	frame->data[pos + word_len] = '\0';

	pos += word_len + 1;

	// TODO truncate this to one byte, that's probably all the resolution I need...
	// maybe use 4 bits for the exponent and the other 4 for the mantissa
	memcpy(frame->data + pos, &freq, sizeof(freq));
	pos += sizeof(freq);

	memcpy(frame->data + pos, &word_metadata, sizeof(word_metadata));
	pos += sizeof(word_metadata);

	assert(pos - orig_pos == word_len + 1 + sizeof(freq) + sizeof(word_metadata));

	return pos - orig_pos;
}

static void add_word_to_frames(struct word_dict_frame **frame, int *pos, const char *word, int word_len, word_freq_t freq, word_metadata_t word_metadata) {
	int old_pos = *pos;
	int bytes_written = add_word_to_frame(*frame, *pos, word, word_len, freq, word_metadata);

	if (bytes_written == 0) {
		(*frame)->data[*pos] = '\0';

		struct word_dict_frame *new_frame = create_frame();
		(*frame)->next = new_frame;
		*frame = new_frame;
		*pos = 0;
		bytes_written = add_word_to_frame(*frame, *pos, word, word_len, freq, word_metadata);
		assert(bytes_written > 0);
		*pos += bytes_written;
		//printf("Wrote word %-32.*s to (newly created) frame, old_pos=%3d, new_pos=%3d\n", word_len, word, old_pos, *pos);
	} else {
		*pos += bytes_written;
		//printf("Wrote word %-32.*s to frame, old_pos=%3d, new_pos=%3d\n", word_len, word, old_pos, *pos);
#if 0
		for (int i=0; i<*pos; i++) {
			printf("%c", (*frame)->data[i]);
		}
		printf("\n");
#endif
	}
}

/** Returns true if a word was found, false otherwise. */
static bool get_next_word_from_frame(const struct word_dict_frame *frame, int *pos, struct word_info_ptrs *word_info_out) {
#if 0
	printf("\nnext word data debug: ");
	for (int i=0; i<80; i++) {
		printf("%c", frame->data[i]);
	}
	printf("\n");
#endif


	if (frame->data[*pos] == '\0') {
		return false;
	}

	int old_pos = *pos;
	word_info_out->word = frame->data + *pos;

	while (1) {
		//printf("checking pos=%3d, val=%c\n", *pos, frame->data[*pos]);
		if (frame->data[*pos] == '\0') {
			break;
		}
		(*pos)++;
	}
	(*pos)++;
	word_info_out->freq = (word_freq_t*) (frame->data + *pos);
	//printf("found word %s, freq=%.1e\n", word_info_out->word, *word_info_out->freq);
	//memcpy(freq, frame->data + *pos, sizeof(word_freq_t));
	*pos += sizeof(word_freq_t);

	word_info_out->metadata = frame->data + *pos;
	*pos += sizeof(word_metadata_t);

	int next_word_present = frame->data[*pos] != '\0';

	//printf("\nget_next_word, old_pos=%3d, new_pos=%3d, done: %d\n", old_pos, *pos, word_present);
	return true;
}

static void dump_frame(const struct word_dict_frame *frame) {
	int prev_pos = -1;
	int pos = 0;
	while (true) { 
		struct word_info_ptrs word_info;
		prev_pos = pos;
		bool word_found = get_next_word_from_frame(frame, &pos, &word_info);
		if (!word_found) {
			break;
		}
		printf("pos %6d to %6d: freq=%.1f, word=\"%s\"\n", prev_pos, pos, *word_info.freq, word_info.word);
	}
	printf("Done at pos %d. Total frame size is %d\n", pos, sizeof(*frame));
}

int find_char(const char *str, size_t str_len, char c, int start_pos) {
	for (int i=start_pos; i<str_len; i++) {
		if (str[i] == '\0') {
			return -1;
		}
		if (str[i] == c) {
			return i;
		}
	}
	return -1;
}

float str_and_len_to_float(const char *str, size_t len) {
	#define MAX_LEN (128)
	char tmp_str[MAX_LEN];
	if (len-1 >= MAX_LEN) {
		alex_log_err("[dict] ERROR: str %.*s (len %d) is larger than max buff len %d\n", len, str, len, MAX_LEN);
		return 0;
	}
	memcpy(tmp_str, str, len);
	tmp_str[len] = '\0';
	return strtof(tmp_str, NULL);
	
}

void *build_word_dict_from_file(const char *fname) {
	long long start_time = timeInMilliseconds();
	//printf("opening file %s...\n", fname);
	FILE *f = fopen(fname, "r");

	if (f == NULL) {
		alex_log_err("[dict] ERROR: file %s could not be opened\n", fname);
		return NULL;
	}
	//printf("file %s opened.\n", fname);

	struct word_dict_frame * const dict = create_frame();
	struct word_dict_frame *current_dict_frame = dict;

	struct word_dict_frame *prev_frame = NULL;
	int frame_pos = 0;

	int line_count = 0;
	int frame_count = 0;
	
	char line[1024];
	do {
		if (line_count % 10000 == 0) {
			//printf("Processing line %8d of %s\n", line_count, fname);
		}
		line_count++;

		// TODO how can I check the length of read bytes?
		// lines longer than my buffer would cause an assert here
		char *rc = fgets(line, sizeof(line), f);
		if (rc <= 0) {
			break;
		}
		int delim_idx = find_char(line, sizeof(line), ',', 0);
		int line_end  = find_char(line, sizeof(line), '\n', delim_idx);
		assert(delim_idx != -1);
		assert(line_end != -1);
		int delim2_idx = find_char(line, sizeof(line), ',', delim_idx + 1);
		int freq_str_len;
		if (delim2_idx == -1) {
			freq_str_len  = line_end - delim_idx - 1;
		} else {
			freq_str_len  = delim2_idx - delim_idx - 1;
		}
		word_metadata_t word_metadata = WORD_METADATA_NONE;
		const char *word_metadata_str = NULL;
		int word_metadata_str_len = 0;
		if (delim2_idx != -1) {
			//const char *word_metadata_str = line + delim2_idx + 1;
			word_metadata_str = line + delim2_idx + 1;
			word_metadata_str_len = line_end - delim2_idx - 1;

			assert(word_metadata_str_len == 1);
			if (word_metadata_str_len == 1) {
				// currently this is just "1", but I could increase this
				// to be any other single character and then use separate bits to
				// indicate different things.
				word_metadata = *word_metadata_str - '0';
			}
			// currently this is the only possibility,
			assert(word_metadata == WORD_METADATA_VULGAR_OR_WEIRD);
		}
		const char *freq_str = line + delim_idx + 1;
#if 0
		if (memcmp(line, "bitch", 5) == 0) {
		printf("freq_str_len is %d, delim_idx = %d, delim2_idx = %d\n", freq_str_len, delim_idx, delim2_idx);
		printf("word=%-32.*s, freq_str=%.*s, word_metadata=%.*s\n",
		       delim_idx, line,
		       freq_str_len, freq_str,
		       word_metadata_str_len, word_metadata_str);
		}
#endif
		//memcpy(freq_str, line + delim_idx + 1, freq_str_len);
		//freq_str[freq_str_len + 1] = '\0';


#ifndef ALEXGAMES_WASM
		// This line is really slow on WASM.
		// Calling it 200k times seems to add ~500 ms on Firefox 119.0 for linux
		//word_freq_t freq = strtof(freq_str, freq_str + freq_str_len);
		word_freq_t freq = str_and_len_to_float(freq_str, freq_str_len);
#else
		// TODO refactor this into a nice portable helper function
		// don't put emscripten specific stuff here.
		word_freq_t freq = EM_ASM_DOUBLE({
			let s = UTF8ToString($0, $1);
			let freq = Number(s);
			//console.log(`Parsed string ${s} to num=${freq}`);
			return freq;
		}, freq_str, freq_str_len);
#endif

		//printf("read=%3d, word=%-32.*s, freq=%.*s, freq_str_len=%d, freq=%e\n", line_end, delim_idx, line, freq_str_len, freq_str, freq_str_len, freq);
		//printf("(read=%3d): \"%.*s\"\n", line_end, line_end, line);
		//printf("%.*s,%.*s\n", delim_idx, line, freq_str_len, freq_str);
		add_word_to_frames(&current_dict_frame, &frame_pos,
		                   line, delim_idx, freq, word_metadata);
		if (prev_frame != current_dict_frame) {
			frame_count++;
			if (frame_count % 50 == 0) {
				//printf("Created %d frames so far\n", frame_count);
			}
		}
		prev_frame = current_dict_frame;
	} while (true);

	int word_count = get_word_count(dict);

	long long end_time = timeInMilliseconds();

	//printf("Created %d frames total. Closing file %s...\n", frame_count, fname);
	fclose(f);
	//printf("File %s closed.\n", fname);
	alex_log("Total dict init took %4lld ms. Created %d frames (%.1f MB), containing a total of %d words.\n", end_time - start_time, frame_count, frame_count*sizeof(struct word_dict_frame)/1e6, word_count);


	return dict;
}

static bool dict_is_ready(void) {
	// TODO
#warning "implement dict_is_ready"
	return true;
}


static void *dict_init(const char *language) {
	alex_log("[dict] c_dictionary: dict_init called\n");

	srandom(time(NULL));

	const char *fname = NULL;

	if (strcmp(language, "en") == 0) {
		if (strlen(ROOT_DIR) > 0) {
			// TODO it looks like ROOT_DIR points to the games, but now that I have a dictionary, that's in
			// a parent directory. 
			fname = ROOT_DIR "/../" "words-en.txt";
		} else {
			fname = "words-en.txt";
		}
	} else {
		// TODO show user visible error saying that only English is supported right now?
		return NULL;
	}

	struct word_dict_frame *dict = build_word_dict_from_file(fname);

	return dict;
}

static struct word_dict_frame* find_frame_containing_word(const struct word_dict_frame *frame, const char *word) {
	const struct word_dict_frame *prev_frame = NULL;
	while (frame != NULL) {
		int strcmp_val = strcmp(frame->data, word);
		if (strcmp_val < 0) {
			// do nothing, go to next frame
		} else if (strcmp_val == 0) {
			return frame;
		} else if (strcmp_val > 0) {
			return prev_frame;
		}
		prev_frame = frame;
		frame = frame->next;
	}
	return NULL;
}

static word_freq_t get_word_freq_in_frame(const struct word_dict_frame *frame, const char *word) {
	int pos = 0;
	struct word_info_ptrs word_info;
	while (get_next_word_from_frame(frame, &pos, &word_info)) {
		int strcmp_val = strcmp(word_info.word, word);
		if (strcmp_val < 0) {
			// next
		} else if (strcmp_val == 0) {
			return *word_info.freq;
		} else if (strcmp_val > 0) {
			break;
		}
	}
	return WORD_NOT_FOUND_FREQ;
}

static word_freq_t get_word_freq_in_dict(const struct word_dict_frame *dict, const char *word) {
	struct word_dict_frame *frame = find_frame_containing_word(dict, word);
	if (frame == NULL) {
		return WORD_NOT_FOUND_FREQ;
	}

	return get_word_freq_in_frame(frame, word);
}

static bool dict_is_valid_word(void *dict_handle, const char *word) {
	assert(dict_handle != NULL);
	struct word_dict_frame *dict = (struct word_dict_frame*)dict_handle;
	return get_word_freq_in_dict(dict, word) != WORD_NOT_FOUND_FREQ;
}

static word_freq_t dict_get_word_freq(void *dict_handle, const char *word) {
	assert(dict_handle != NULL);
	struct word_dict_frame *dict = (struct word_dict_frame*)dict_handle;
	return get_word_freq_in_dict(dict, word);
}

static int get_word_count(const struct word_dict_frame *frame) {
	int total_word_count = 0;
	while (frame != NULL) {
		total_word_count += frame->word_count;
		frame = frame->next;
	}

	return total_word_count;
}

static void get_word_at_index(const struct word_dict_frame *frame,
                              int word_idx,
                              struct word_info_ptrs *word_info_out) {
	int prev_frame_word_count = 0;
	int frame_word_count = 0;
	const struct word_dict_frame *prev_frame = frame;
	while (frame_word_count <= word_idx) {
		//printf("finding frame: frame_word_count = %d, idx=%d, this frame word count %d\n", frame_word_count, word_idx, frame->word_count);
		//assert(frame->next != NULL);

		prev_frame_word_count = frame_word_count;
		frame_word_count += frame->word_count;
		prev_frame = frame;
		frame = frame->next;
	}

	struct word_info_ptrs word_info;
	word_info.word = NULL;
	int pos = 0;
	while(prev_frame_word_count <= word_idx) {
		bool rc = get_next_word_from_frame(prev_frame, &pos, &word_info);
		assert(rc);
		//printf("finding word: prev_frame_word_count = %d, word = %s\n", prev_frame_word_count, word_info.word);

		prev_frame_word_count++;
	}
	assert(word_info.word != NULL);

	*word_info_out = word_info;
	//printf("DONE %s!\n", __func__);
}

static bool word_matches_params(const struct word_query_params *params, const struct word_info_ptrs *word_info) {
	int word_len = strlen(word_info->word);
	if ( !(params->min_length <= word_len && word_len <= params->max_length) ) {
		return false;
	}

	if ( !(params->min_freq <= *word_info->freq) ) {
		return false;
	}

	if (!params->include_weird_or_vulgar &&
	    *word_info->metadata != WORD_METADATA_NONE) {
		//printf("Skipping word %.*s because its metadata is %d\n", word_len,
		//       word_info->word, *word_info->metadata);
		return false;
	}

	return true;
}
                                     

static int get_words_matching_params(const struct word_dict_frame *frame,
                                     const struct word_query_params *params) {
	int count = 0;
	while (frame != NULL) {
		struct word_info_ptrs word_info;
		int pos = 0;
		while (get_next_word_from_frame(frame, &pos, &word_info)) {
			if (word_matches_params(params, &word_info)) {
				count++;
			}
		}

		frame = frame->next;
	}

	return count;
}

static void get_word_matching_params_idx(const struct word_dict_frame *frame,
                                         const struct word_query_params *params,
                                         int word_idx,
                                         struct word_info_ptrs *word_info_out) {
	int count = 0;
	while (frame != NULL) {
		struct word_info_ptrs word_info;
		int pos = 0;
		while (get_next_word_from_frame(frame, &pos, &word_info)) {
			if (word_matches_params(params, &word_info)) {
				if (count == word_idx) {
					*word_info_out = word_info;
					return;
				}
				count++;
			}
		}

		frame = frame->next;
	}

	assert(false);
}

static int dict_get_random_word(void *dict_handle,
                                const struct word_query_params *params,
                                char *word_out, size_t max_word_out_len,
                                int *possib_word_count_out) {
	alex_log("[dict] %s(handle=%p)\n", __func__, dict_handle);
	assert(dict_handle != NULL);
	struct word_dict_frame *dict = (struct word_dict_frame*)dict_handle;

	int word_count = get_words_matching_params(dict, params);
	alex_log("found matching word count of %d\n", word_count);

	// TODO fix this to be less biased
	int word_idx = random() % word_count;
	alex_log("chose random word idx %d\n", word_idx);

	struct word_info_ptrs word_info;
	word_info.word = NULL;
	//get_word_at_index(dict, word_idx, &word_info);
	get_word_matching_params_idx(dict, params, word_idx, &word_info);
	assert(word_info.word != NULL);

	//alex_log("word_out = %p\n", word_out);
	strncpy(word_out, word_info.word, max_word_out_len);
	if (possib_word_count_out != NULL) {
		*possib_word_count_out = word_count;
	}
	return strlen(word_info.word);
}

static int dict_get_words_made_from_letters(void *dict_handle,
                                            const struct word_query_params *params,
                                            const char *letters) {
	// TODO
	return 0;
}

static const struct game_dict_api api = {
	dict_is_ready,
	dict_init,
	dict_is_valid_word,
	dict_get_word_freq,
	dict_get_random_word,
	dict_get_words_made_from_letters,
};

#if 0
const struct game_dict_api *get_game_dict_api(void) {
	return &api;
}
#endif

const struct game_dict_api *get_c_dictionary_api(void) {
	return &api;
}
