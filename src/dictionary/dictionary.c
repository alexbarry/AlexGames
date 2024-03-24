// TODO: rename this to sqlite_dictionary.c or something
// I originally added this when trying to use sqlite as my dictionary.
// I thought it was convenient that it could load in the entire dictionary in
// a reasonably compact way, rather than having to parse a large text file.
// For clients besides web, I think this is fine-- the database is a few megabytes, and the
// added code of sqlite is a few megabytes as well.
//
// But for web, this doesn't make sense. It adds ~2 MB of WASM just to include sqlite, and ultimately
// all it does is parse the db file and loop through it all anyway. (Admittedly I never tried adding an index).
//
// I'm keeping it around in case I ever decide that I need to support arbitrary queries for word games.

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <sqlite3.h>

#include "dictionary.h"


static int print_word(void *handle, const char *word, float freq) {
	printf("handle = %p, word = \"%s\", freq = %e\n", handle, word, freq);
	return 0;
}

#if 0
static int callback(void *handle, int argc, char **argv, char **colName) {
	printf("%s: %s called\n", __FILE__, __func__);
	const struct word_callback_data *data = handle;
	data->create_word_table(data->handle);

	int i;
	for (i=0; i<argc; i+= 3) {
		printf("%s = %s\n", colName[i], argv[i] ? argv[i] : "NULL");
		char *word = argv[i];
		char *freq_str = argv[i+1];
		assert(argv[i+2] == NULL);

		float freq = strtof(freq_str, NULL);

		data->add_word_to_list_func(data->handle, word, freq);

	}
	data->word_table_done(data->handle);
	//printf("\n");
	return 0;
}
#endif

static size_t get_file_size(const char *fname) {
	FILE *f = fopen(fname, "r");
	if (f == NULL) {
		fprintf(stderr, "File \"%s\" is NULL\n", fname);
		return -1;
	}
	fseek(f, 0L, SEEK_END);
	size_t sz = ftell(f);
	fclose(f);
	return sz;
}

void *init_dict() {

	printf("File size is: %zu\n", get_file_size("preload/word_dict.db"));

	sqlite3 *db;

	int rc = sqlite3_open("preload/word_dict.db", &db);
	if (rc) {
		fprintf(stderr, "Can not open database: \"%s\"\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		return 0;
	}

	printf("Successfully initialized sqlite DB, handle = %p\n", db);
	return db;
}

void get_words(void *dict_handle, const char *query, struct word_callback_data *data) {
	sqlite3 *db = dict_handle;

	//static const char query[] =
	//	//"SELECT word, freq FROM words ORDER BY LENGTH(word) DESC, freq DESC";
	//	"SELECT word, freq FROM words WHERE LENGTH(word) = 7 ORDER BY LENGTH(word) DESC, freq DESC LIMIT 10";

	char *errMsg = 0;

	//struct word_callback_data data;
	//data.handle = (void*)12345;
	//data.add_word_to_list_func = print_word;

	//printf("dictionary get_words called with query \"%s\"\n", query);
	sqlite3_stmt *statement;
	int rc = sqlite3_prepare_v2(db, query, -1, &statement, NULL);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "SQL error: \"%s\"\n", sqlite3_errmsg(db)); // TODO does this error message need to be freed?
		//sqlite3_free(errMsg);
	}
	//printf("done sqlite3_prepare_v2\n");

	//data->create_word_table(data->handle);
	int row_idx = 0;
	while ((rc = sqlite3_step(statement)) == SQLITE_ROW) {
		//printf("row_idx = %d\n", row_idx);
		int argc = sqlite3_column_count(statement);
		const unsigned char **argv = malloc(argc*sizeof(*argv));
		if (argv == NULL) {
			fprintf(stderr, "Failed to allocate memory at %s:%d (%s)\n", __FILE__, __LINE__, __func__);
			return;
		}
		int i;
		for (i=0; i<argc; i++) {
			//printf("arg idx = %d\n", i);
			// TODO does this work for non text columns?
			argv[i] = sqlite3_column_text(statement, i);
		}
		data->add_word_to_list_func(data->handle, row_idx, argc, argv);
		row_idx++;
		free(argv);
		//printf("done looping through words\n");
	}
	//printf("done calling get_words\n");
	//data->word_table_done(data->handle);
}

void teardown_dict(void *dict_handle) {
	sqlite3 *db = dict_handle;
	sqlite3_close(db);
}
