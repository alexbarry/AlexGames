#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<errno.h>
#include<assert.h>

// for mkdir
#include<sys/stat.h>
// for dirname
#ifndef WIN32
#include<libgen.h>
#endif

#ifndef WIN32
// for access() to check if file exists from uploaded game
#include<unistd.h>
#endif

#ifdef WIN32
#define F_OK (0)
#endif

#include "game_api.h"
#include "game_api_utils.h"

#include "lua_api.h"

#include "utils/str_eq_literal.h"

#ifdef ENABLE_ZIP_UPLOAD
// TODO move this to separate file?
#include "zip.h"
#endif

// TODO make a proper header for this
extern const struct game_api *get_stick_api();

#include "history_browse_ui.h"

#define ARY_LEN(x) (sizeof(x)/sizeof((x)[0]))

static void (*alexgames_mutex_take_ptr)(void) = NULL;
static void (*alexgames_mutex_release_ptr)(void) = NULL;

static bool g_root_dir_set = false;
static char g_root_dir[4096];

static log_func_t g_log_func = NULL;
static log_func_t g_log_func_err = NULL;

void set_alex_log_func(log_func_t log_func) {
	g_log_func = log_func;
}
void set_alex_log_err_func(log_func_t log_func) {
	g_log_func_err = log_func;
}

void alex_log(const char *format, ...) {
	va_list args;
	va_start(args, format);
	if (g_log_func != NULL) {
		g_log_func(format, args);
	} else {
		vprintf(format, args);
	}
	va_end(args);
}

void alex_log_err_va(const char *format, va_list va_args) {
	if (g_log_func_err != NULL) {
		g_log_func_err(format, va_args);
	} else {
		vfprintf(stderr, format, va_args);
		if (format[strlen(format)-1] != '\n') {
			fprintf(stderr, "\n");
		}
	}
}

void alex_log_err(const char *format, ...) {
	va_list args;
	va_start(args, format);
	alex_log_err_va(format, args);
	va_end(args);
}

void alex_set_status_err_v(const struct game_api_callbacks *api_callbacks, const char *format, va_list args) {
	char str_err[1024];
	int str_err_len = vsnprintf(str_err, sizeof(str_err), format, args);
	api_callbacks->set_status_err(str_err, str_err_len);
}

void alex_set_status_err_vargs(const struct game_api_callbacks *api_callbacks, const char *format, ...) {
	va_list args;
	va_start(args, format);
	alex_set_status_err_v(api_callbacks, format, args);
	va_end(args);
}

void alex_log_err_user_visible(const struct game_api_callbacks *api, const char *format, ...) {
	va_list args;
	va_start(args, format);
	if (api && api->set_status_err) {
		alex_set_status_err_v(api, format, args);
	}
	alex_log_err_va(format, args);
	va_end(args);
}



static const char *GAMES_LIST[] = {
	"solitaire",
	"word_mastermind",
	"crossword_letters",
	"chess",
	"go",
	"crib",
	"checkers",
	"backgammon",
	"endless_runner",
	"minesweeper",
	"spider_swing",
	"31s",
	"wu",
	"fluid_mix",
	"thrust",
	"hospital",
	"life",
	"bound",
	"card_sim",
	"sudoku",
	//"stick",
	"blue",
	"swarm",

	"crossword_builder",

	//"timer_test",
};

int alex_get_game_count() {
	int len = ARY_LEN(GAMES_LIST);
	return len;
}

const char *alex_get_game_name(int idx) {
	if (idx < 0 || idx >= ARY_LEN(GAMES_LIST)) {
		return NULL;
	} else {
		const char *str = GAMES_LIST[idx];
		return str;
	}
}



// TODO ideally this should be stored in the L param that is passed around
const struct game_api *game_api = NULL;

void set_game_api(const struct game_api *game_api_arg) {
	game_api = game_api_arg;
}


FILE *alex_new_file(void *L, const char *fname) {
	FILE *f = fopen(fname, "wb");
	return f;
}


static char to_nice_ascii(uint8_t val) {
	if (val < ' ' || val >= 0x7f) { return '.'; }
	else { return val; }
}

void alex_write_to_file(void *L, FILE *f, const uint8_t *data, size_t data_len) {
#if 0
	printf("writing: ");
	for (int i=0; i<data_len; i++) {
		if (i % 16 == 0 && i != 0) {
			printf("  ");
			for (int j=i; j<i+16; j++) {
				printf("%c", to_nice_ascii(data[j]));
			}
			printf("\n");
		}
		printf("%02x ", data[i]);
	}
#endif


	int rc = fwrite(data, 1, data_len, f);
	if (rc != data_len) {
		fprintf(stderr, "fwrite returned %d when writing %zu bytes of data\n", rc, data_len);
	}
}

void alex_close_file(void *L, FILE *f) {
	fclose(f);
}

void alex_dump_file(void *L, const char *fname) {
	FILE *f = fopen(fname, "rb");
	int i = 0;
	uint8_t buff[16];
	while (1) {
		int bytes_read = fread(buff, 1, sizeof(buff), f);
		if (bytes_read <= 0) { break; }
		printf("%04x: ", i);
		int i2;
		for (i2=0; i2<bytes_read; i2++) {
			printf( "%02x ", buff[i2]);
		}
		printf(" ");
		for (i2=0; i2<bytes_read; i2++) {
			uint8_t val = buff[i2];
			//printf( "%c", (val <= ' ' || val >= 0x7f) ? '.' : val);
			printf( "%c", to_nice_ascii(val));
		}
		printf("\n");
		i += bytes_read;
	}
	fclose(f);
}

void mkdir_p(char *path, int mode) {
	char *sep = strrchr(path, '/');
	if (sep != NULL) {
		*sep = 0;
		mkdir_p(path, mode);
		*sep = '/';
	}
	int rc = mkdir(path, mode);
	if (rc && errno != EEXIST) {
		fprintf(stderr, "error %d %d creating dir \"%s\"\n", rc, errno, path);
	}
}

#ifdef ENABLE_ZIP_UPLOAD

void alex_unzip_file(void *L, const char *fname, const char *dst_name) {
	int err = 0;
	zip_t *z = zip_open(fname, ZIP_RDONLY, &err);
	if (z == NULL) {
		zip_error_t error;
		zip_error_init_with_code(&error, err);
		fprintf(stderr, "Error opening file %s: \"%s\"\n", fname, zip_error_strerror(&error));
		return;
	}

	{
		char *dst_name_copy = strdup(dst_name);
		mkdir_p(dst_name_copy, 0777);
		free(dst_name_copy);
	}

	int num_files = zip_get_num_entries(z, 0);

	printf("Found %d files in zip archive:\n", num_files);
	for (int i=0; i<num_files; i++) {
		zip_stat_t sb;
		{
			int rc = zip_stat_index(z, i, 0, &sb);
			if (rc != 0) {
				fprintf(stderr, "zip_stat_index returned %d\n", rc);
				continue;
			}
		}

		printf("File %3d: name=\"%s\", size:%llu\n", i, sb.name, sb.size);


		// TODO should check if zf is directory (and make a directory), otherwise extract file.
		// Doing both every time is bad, extracting directories is failing

		zip_file_t *zf = zip_fopen_index(z, i, ZIP_RDONLY);
		if (zf == NULL) {
			// TODO will this happen for directories?
			fprintf(stderr, "Failed to open file idx %d (%s)\n", i, sb.name);
			continue;
		}

		bool is_dir = (sb.name[strlen(sb.name)-1] == '/');


		FILE *fout;
		{
			char fout_name[1024];
			snprintf(fout_name, sizeof(fout_name), "%s/%s", dst_name, sb.name);

			if (is_dir) {
				printf("Creating new directory \"%s\"\n", fout_name);
				//int rc = mkdir(new_dir, 0755);
				mkdir_p(fout_name, 0777);
				continue;
			}

			printf("Writing to file \"%s\"\n", fout_name);
			fout = fopen(fout_name, "wb");
			if (fout == NULL) {
				fprintf(stderr, "Failed to open output file %s\n", fout_name);
				continue;
			}
		}


		uint8_t buff[4096];
		while (true) {
			int bytes_read = zip_fread(zf, buff, sizeof(buff));
			if (bytes_read <= 0) { break; }
			fwrite(buff, 1, bytes_read, fout);
		}
		fclose(fout);
	}
}

#endif

void *alex_init_game(const struct game_api_callbacks *api_callbacks,
                     const char *game_str, int game_str_len) {
	printf("[init] game_api.c: alex_init_game called\n");
	{
		char init_msg[256];
		int init_msg_len = snprintf(init_msg, sizeof(init_msg), "Starting game \"%s\"", game_str);
		api_callbacks->set_status_msg(init_msg, init_msg_len);
	}

	const char *lua_game_path = NULL;
	
	if (strcmp(game_str, GAME_ID_UPLOADED) == 0) {
		// For now I'm just hardcoding it, but this should be specified in the manifest some day
		lua_game_path = GAME_UPLOAD_PATH "/" UPLOADED_GAME_MAIN_FILE;

		if (access(GAME_UPLOAD_PATH, F_OK) != 0) {
			// TODO this too HTML specific.
			alex_set_status_err_vargs(api_callbacks,
			                          "No contents found at \"%s\", please upload a game or select another "
			                          "(preloaded) game. "
			                          "If you refreshed the page then you must re-upload your game zip.",
			                          GAME_UPLOAD_PATH);
			return NULL;
		} else if (access(lua_game_path, F_OK) != 0) {
			alex_log_err("Uploaded game does not contain game main file \"%s\"\n", lua_game_path);
			alex_set_status_err_vargs(api_callbacks,
			                          "Uploaded game does not contain game main file \"%s\"\n",
			                          UPLOADED_GAME_MAIN_FILE);
			return NULL;
		} else {
			printf("Confirmed that %s exists.\n", lua_game_path);
		}
	} else {
		lua_game_path = get_lua_game_path(game_str, game_str_len);
		printf("ROOT_DIR=\"%s\"\n", ROOT_DIR);
		printf("Loading Lua game path \"%s\"\n", lua_game_path);
	}

	if (lua_game_path != NULL) {
		return start_lua_game(api_callbacks, lua_game_path);
#if 0
	} else if (str_eq_literal(game_str, "stick", game_str_len)) {
		const struct game_api *game_api = get_stick_api();
		set_game_api(game_api);
		return game_api->init_lua_api(api_callbacks, game_str, game_str_len);
#endif
	} else if (str_eq_literal(game_str, "history_browse", game_str_len)) {
		const struct game_api *game_api = get_history_browse_api();
		set_game_api(game_api);
		return game_api->init_lua_api(api_callbacks, game_str, game_str_len);
	} else {
		alex_log_err("game %.*s not handled\n", game_str_len, game_str);
		char err_msg[128];
		int rc = snprintf(err_msg, sizeof(err_msg), "Game \"%.*s\" not handled", game_str_len, game_str);
		if (rc > 0) {
			api_callbacks->set_status_err(err_msg, rc);
		} else {
			const char err2[] = "Game not handled";
			api_callbacks->set_status_err(err2, sizeof(err2));
		}
		return 0;
	}
}

struct draw_graphic_params default_draw_graphic_params(void) {
	struct draw_graphic_params params = {
		0,     /* angle_degrees */
		false, /* flip_y */
		false, /* flip_x */
		100,   /* brightness_percent */
		false,
	};
	return params;
}

struct popup_info empty_popup_info(void) {
	struct popup_info info;
	strncpy(info.title, "Popup", sizeof(info.title));
	info.item_count = 0;
	return info;
}

void popup_info_add_button(struct popup_info *info, int btn_id, const char *btn_text) {
	if (info->item_count >= MAX_POPUP_ITEMS) {
		fprintf(stderr, "%s: max popup item info reached, can not add button\n", __func__);
		return;
	}
	int i = info->item_count;
	info->item_count++;

	info->items[i].type = POPUP_ITEM_TYPE_BTN;
	info->items[i].info.btn.id = btn_id;
	strncpy(info->items[i].info.btn.text, btn_text, sizeof(info->items[i].info.btn.text));
}


void alex_start_game_b64(const struct game_api *game_api, const struct game_api_callbacks *api_callbacks,
                         void *L,
                         int session_id,
                         const char *b64_enc_state, size_t b64_enc_state_len) {
	if (api_callbacks == NULL) {
		alex_log_err_user_visible(api_callbacks, "%s: api_callbacks is null\n", __func__);
		return;
	}

	size_t max_decoded_state_len = b64_encoded_size_to_max_decoded_size(b64_enc_state_len);
	if (max_decoded_state_len > 1024*1024) {
		alex_log_err_user_visible(api_callbacks, "%s: received input len %zu enc (max %zu dec), too large\n", __func__,
		                          b64_enc_state_len, max_decoded_state_len);
#if 0
		char msg[512];
		int msg_len = snprintf(msg, sizeof(msg),
		                       "%s: received input len %zu enc (max %zu dec), too large\n", __func__,
		                       b64_enc_state_len, max_decoded_state_len);
		alex_log_err(msg);
		api_callbacks->set_status_err(msg, msg_len);
#endif
		return;
	}

	uint8_t *decoded_state = malloc(max_decoded_state_len);
	if (decoded_state == NULL) {
		alex_log_err_user_visible(api_callbacks, "%s: malloc returned NULL\n", __func__);
		return;
	}

	size_t decoded_state_len = decode_b64(decoded_state, max_decoded_state_len,
	                                      b64_enc_state, b64_enc_state_len);

	alex_log("%s: enc state: len %zu, %s\n", __func__, b64_enc_state_len, b64_enc_state);
	char log_msg[1024*64];
	int i=0;
	i += snprintf(log_msg, sizeof(log_msg), "%s: dec state: len %zu, ", __func__, decoded_state_len);
	for (int j=0; j<decoded_state_len; j++) {
		i+= snprintf(log_msg + i, sizeof(log_msg) - i, "%02x ", decoded_state[j]);
	}
	i+= snprintf(log_msg + i, sizeof(log_msg) - i, "\n");

	alex_log(log_msg, i);

	if (api_callbacks->get_new_session_id == NULL || game_api->start_game == NULL) {
		alex_log_err_user_visible(api_callbacks, "%s: api_callbacks->get_new_session_id (func=%p) and/or game_api->start_game (func=%p) are null\n",
		                          __func__, api_callbacks->get_new_session_id, game_api->start_game);
		goto err;
	}
	if (session_id < 0) {
		session_id = api_callbacks->get_new_session_id();
	}
	game_api->start_game(L, session_id, decoded_state, decoded_state_len);

	err:
	free(decoded_state);
}



#if 0
void show_popup_btns(const game_api *api,
                     const char *popup_id, size_t popup_id_str_len,
	                 const struct popup_info *info) {
	char btn_str_ary[MAX_POPUP_ITEMS][MAX_POPUP_BTN_TEXT_LEN];
	int i;
	for (i=0; i<info->item_count; i++) {
		const struct *item = info->items[i];
		if (item->type != POPUP_ITEM_TYPE_BUTTON) {
			// TODO error?
			continue;
		}
		strncpy(btn_str_ary[i], item.btn.
	}
#endif

void write_str(char **dst, size_t *len_remaining, const char *to_write) {
	strncpy(*dst, to_write, *len_remaining);
	size_t this_len = strlen(to_write);
	*dst += this_len;
	*len_remaining -= this_len;
}

void write_json_str(char **dst_str, size_t *len_remaining, const char *src_str) {
	char c;
	do {
		c = *src_str++;

		if (c == '"') {
			write_str(dst_str, len_remaining, "\\\"");
		} else if (c == '\n') {
			write_str(dst_str, len_remaining, "\\n");
		} else if (c == '\0') {
			**dst_str = c;
		} else {
			**dst_str = c;
			*dst_str += 1;
			*len_remaining -= 1;
		}
	} while(c != '\0');
}

void write_json_int(char **dst_str, size_t *len_remaining, int val) {
	char buff[16];
	snprintf(buff, sizeof(buff), "%d", val);
	write_str(dst_str, len_remaining, buff);
}

size_t popup_info_to_json_str_old(char *info_json_str, size_t info_json_str_len,
                                  const char *title, size_t title_len,
                                  const char *msg, size_t msg_len,
                                  const char * const *btn_str_ary, size_t ary_len) {
	//char info_json_str[10*1024];
	char *ptr = info_json_str;
	size_t len = 0;

	*ptr++ = '{';

	// TODO need to remove double quotes from strings in JSON

	len = sprintf(ptr, "\"%s\": \"%*s\",", "title", (int)title_len, title);
	ptr += len;

	len = sprintf(ptr, "\"items\": [");
	ptr += len;

	if (msg_len > 0) {
		len = sprintf(ptr, "{");
		ptr += len;
	
		len = sprintf(ptr, "\"%s\": %d,", "type", POPUP_ITEM_TYPE_MSG);
		ptr += len;
	
		len = sprintf(ptr, "\"%s\": \"", "msg");
		ptr += len;

		write_json_str(&ptr, &len, msg);

		len = sprintf(ptr, "\"");
		ptr += len;
	
		len = sprintf(ptr, "}");
		ptr += len;

		if (ary_len > 0) {
			len = sprintf(ptr, ",");
			ptr += len;
		}
	}

	int i;
	for (i=0; i<ary_len; i++) {

		if (i != 0) {
			len = sprintf(ptr, ",");
			ptr += len;
		}

		len = sprintf(ptr, "{");
		ptr += len;
	
		len = sprintf(ptr, "\"%s\": %d,", "type", POPUP_ITEM_TYPE_BTN);
		ptr += len;

		//len = sprintf(ptr, "\"%s\": \"%s\",", "id", btn_id);
		//ptr += len;

		len = sprintf(ptr, "\"%s\": %d,", "id", i);
		ptr += len;
	
		len = sprintf(ptr, "\"%s\": \"", "text");
		ptr += len;
		write_json_str(&ptr, &len, btn_str_ary[i]);
		len = sprintf(ptr, "\"");
		ptr += len;

		len = sprintf(ptr, "}");
		ptr += len;
	}


	len = sprintf(ptr, "]");
	ptr += len;

	len = sprintf(ptr, "}");
	ptr += len;

	return ptr - info_json_str;
}

size_t popup_info_to_json_str(char *info_json_str, size_t info_json_str_len,
                              const struct popup_info *popup_info) {

	size_t orig_dst_remaining = info_json_str_len;
	char *ptr = info_json_str;

	write_str(&ptr, &info_json_str_len, "{\"title\":\"");
	write_json_str(&ptr, &info_json_str_len, popup_info->title);
	write_str(&ptr, &info_json_str_len, "\", \"items\": [");
	int i;
	for (i=0; i<popup_info->item_count; i++) {
		const struct popup_item *item = &popup_info->items[i];
		if (i != 0) {
			write_str(&ptr, &info_json_str_len, ",");
		}
		write_str(&ptr, &info_json_str_len, "{\"type\":");
		write_json_int(&ptr, &info_json_str_len, item->type);
		switch(item->type) {
			{
				case POPUP_ITEM_TYPE_MSG:
				write_str(&ptr, &info_json_str_len, ",\"msg\":\"");
				write_json_str(&ptr, &info_json_str_len, item->info.msg.msg);
				write_str(&ptr, &info_json_str_len, "\"}");
				break;
			}
			{
				case POPUP_ITEM_TYPE_DROPDOWN:
				write_str(&ptr, &info_json_str_len, ",\"label\":\"");
				write_json_str(&ptr, &info_json_str_len, item->info.dropdown.label);
				write_str(&ptr, &info_json_str_len, "\",\"id\":");
				write_json_int(&ptr, &info_json_str_len, item->info.dropdown.id);
				write_str(&ptr, &info_json_str_len, ",\"options\":[");
				int option_idx;
				for (option_idx=0; option_idx<item->info.dropdown.option_count; option_idx++) {
					const char *option_str = item->info.dropdown.options[option_idx];
					if (option_idx != 0) { write_str(&ptr, &info_json_str_len, ","); }
					write_str(&ptr, &info_json_str_len, "\"");
					write_json_str(&ptr, &info_json_str_len, option_str);
					write_str(&ptr, &info_json_str_len, "\"");
				}
				write_str(&ptr, &info_json_str_len, "]}");
				break;
			}
			{
				case POPUP_ITEM_TYPE_BTN:
				write_str(&ptr, &info_json_str_len, ",\"id\":");
				write_json_int(&ptr, &info_json_str_len, item->info.btn.id);

				write_str(&ptr, &info_json_str_len, ",\"text\":\"");
				write_json_str(&ptr, &info_json_str_len, item->info.btn.text);
				write_str(&ptr, &info_json_str_len, "\"}");
				break;
			}
			default:
				fprintf(stderr, "%s: Unhandled popup item type %d", __func__, item->type);
				write_str(&ptr, &info_json_str_len, ", \"err\": \"unhandled\"}");
				// TODO error
				continue;
		}

	}
	write_str(&ptr, &info_json_str_len, "]}");

	{
		size_t actual = strlen(info_json_str);
		size_t expected = orig_dst_remaining - info_json_str_len;
		if (expected != actual) {
			fprintf(stderr, "%s: String is %zu bytes, expected to have written %zu\n",
			        __func__, actual, expected);
		}
	}
	
	return ptr - info_json_str;
}


size_t option_info_to_json_str(char *json_str_out, const size_t max_json_str_out_len,
                               const struct option_info *option_info) {
	const size_t orig_dst_remaining = max_json_str_out_len;
	size_t dst_remaining = max_json_str_out_len;
	char *ptr = json_str_out;

	write_str(     &ptr, &dst_remaining, "{");
	write_str(     &ptr, &dst_remaining, "\"type\":");
	write_json_int(&ptr, &dst_remaining, option_info->option_type);
	write_str(     &ptr, &dst_remaining, ",");
	write_str(     &ptr, &dst_remaining, "\"label\":\"");
	write_json_str(&ptr, &dst_remaining, option_info->label);
	write_str(     &ptr, &dst_remaining, "\"");
	if (option_info->option_type == OPTION_TYPE_TOGGLE) {
		write_str(     &ptr, &dst_remaining, ",");
		write_str(     &ptr, &dst_remaining, "\"value\":");
		if (option_info->value) {
			write_str(     &ptr, &dst_remaining, "true");
		} else {
			write_str(     &ptr, &dst_remaining, "false");
		}
	}
	write_str(     &ptr, &dst_remaining, "}");

	{
		size_t actual = strlen(json_str_out);
		size_t expected = orig_dst_remaining - dst_remaining;
		if (expected != actual) {
			fprintf(stderr, "%s: String is %zu bytes, expected to have written %zu\n",
			                __func__, actual, expected);
		}
	}

	return ptr - json_str_out;
}


void alexgames_mutex_take() {
	if (alexgames_mutex_take_ptr != NULL) {
		alexgames_mutex_take_ptr();
	}
}

void alexgames_mutex_release() {
	if (alexgames_mutex_release_ptr != NULL) {
		alexgames_mutex_release_ptr();
	}
}

void alexgames_set_mutex_take_func(void (*func)(void)) {
	alexgames_mutex_take_ptr = func;
}

void alexgames_set_mutex_release_func(void (*func)(void)) {
	alexgames_mutex_release_ptr = func;
}

void alex_set_root_dir(const char *root_dir) {
	strncpy(g_root_dir, root_dir, sizeof(g_root_dir));
	g_root_dir_set = true;
}

int alex_get_root_dir(char *root_dir_out, size_t root_dir_out_len) {
	int rc;
	int str_len;
	if (g_root_dir_set) {
		rc = snprintf(root_dir_out, root_dir_out_len, "%s", g_root_dir);
		str_len = strnlen(g_root_dir, sizeof(g_root_dir));
	} else {
		rc = snprintf(root_dir_out, root_dir_out_len, "%s", ROOT_DIR);
		str_len = strlen(ROOT_DIR);
	}

	if (rc != str_len) {
		return -1;
	} else {
		return 0;
	}
}
