
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <sqlite3.h>

#define TABLE_NAME "alexgames_saved_state"

static int callback_check_tbl_exists(void *arg, int argc, char **argv, char **colName) {
	if (argc != 1) {
		fprintf(stderr, "Error, expected argc to be 1\n");
		return -1;
	}

	int *arg_int = (int*)arg;
	*arg_int = atoi(argv[0]);

	return 0;
}

void *init_sqlite_saved_state(const char *fname) {
	printf("[saved state] Initializing saved state sqlite DB at \"%s\"...\n", fname);
	sqlite3 *db;
	char *err_msg = NULL;

	int rc = sqlite3_open(fname, &db);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "Can not open sqlite3 database (\"%s\"): \"%s\"\n", 
		        fname, sqlite3_errmsg(db));
		sqlite3_close(db);
		return NULL;
	}

	const char *SQL_TABLE_CHECK = "SELECT COUNT(*) "
	                              "FROM sqlite_master "
	                              "WHERE type='table' "
	                              "AND name='" TABLE_NAME "' "
	                              ";";
	int table_exists = 0;
	rc = sqlite3_exec(db, SQL_TABLE_CHECK, callback_check_tbl_exists, &table_exists, &err_msg);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "sqlite3 error: %s\n", err_msg);
		sqlite3_free(err_msg);
		return NULL;
	}

	if (!table_exists) {
		printf("[saved state] Table %s not present in database, creating...\n", TABLE_NAME);
		const char *SQL_CREATE_TABLE = "CREATE TABLE " TABLE_NAME  "("
		                                  "key varchar(128) PRIMARY KEY, "
		                                  "value BLOB"
		                               ");";
		rc = sqlite3_exec(db, SQL_CREATE_TABLE, 0, 0, &err_msg);
		if (rc != SQLITE_OK) {
			fprintf(stderr, "sqlite3 error: %s\n", err_msg);
			sqlite3_free(err_msg);
			return NULL;
		}
	}


	printf("[saved state] Successfully initialized sqlite DB, handle = %p\n", db);

	return db;
}

int set_value(void *handle, const char *key,
              const uint8_t *value, size_t value_len) {
	sqlite3 *db = (sqlite3*)handle;
	const char *SQL_INSERT_OR_REPLACE = "INSERT OR REPLACE INTO alexgames_saved_state "
	                                    "VALUES (?, ?);";

	sqlite3_stmt *stmt;

	int rc = sqlite3_prepare_v2(db, SQL_INSERT_OR_REPLACE, -1, &stmt, 0);

	if (rc != SQLITE_OK) {
		fprintf(stderr, "%s: sqlite3_prepare_v2 error %d, %s\n",
		        __func__, rc, sqlite3_errmsg(db));
		return -1;
	}

	sqlite3_bind_text(stmt, 1, key, -1, SQLITE_STATIC);
	sqlite3_bind_blob(stmt, 2, value, value_len, SQLITE_STATIC);

	rc = sqlite3_step(stmt);

	if (rc != SQLITE_DONE) {
		fprintf(stderr, "%s: sqlite3_step err %d, %s\n", __func__, rc, sqlite3_errmsg(db));
		return -1;
	}

	sqlite3_finalize(stmt);

	//sqlite3_exec(db, "COMMIT;", 0, 0, 0);

	return value_len;
}

int get_value(void *handle, const char *key,
              uint8_t *value_out, size_t max_value_len) {
	sqlite3 *db = (sqlite3*)handle;
	const char *SQL_READ_VALUE = "SELECT value "
	                             "FROM " TABLE_NAME " "
	                             "WHERE key = ?;";

	sqlite3_stmt *stmt;

	int rc = sqlite3_prepare_v2(db, SQL_READ_VALUE, -1, &stmt, 0);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "%s: sqlite3_prepare_v2 err %d: %s\n", __func__, rc, sqlite3_errmsg(db));
		return -1;
	}

	sqlite3_bind_text(stmt, 1, key, -1, SQLITE_STATIC);

	rc = sqlite3_step(stmt);

	if (rc == SQLITE_DONE) {
		return -1;
	} else if (rc != SQLITE_ROW) {
		// TODO error
		fprintf(stderr, "%s: expected first step call to return row or done, instead %d %s\n",
		        __func__, rc, sqlite3_errmsg(db));
		return -1;
	}


	const uint8_t *data = sqlite3_column_blob(stmt, 0);
	int data_len = sqlite3_column_bytes(stmt, 0);

	if (max_value_len == 0) {
		return data_len;
	}

	if (data_len > max_value_len) {
		fprintf(stderr, "%s: value %s is %d long, larger than buff %d\n",
		        __func__, key, data_len, max_value_len);
		data_len = max_value_len;
	}

	memcpy(value_out, data, data_len);


	rc = sqlite3_step(stmt);
	if (rc != SQLITE_DONE) {
		fprintf(stderr, "%s: expected second step call to return SQLITE_DONE, instead %d %s\n",
		        __func__, rc, sqlite3_errmsg(db));
		return -1;
	}

	sqlite3_finalize(stmt);

	return data_len;
}

void destroy_sqlite_saved_state(void *handle) {
	printf("[saved state] Closing saved state DB...\n");
	sqlite3 *db = (sqlite3*)handle;

	int rc = sqlite3_close(db);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "%s: Error closing saved state db: %d %s\n",
		        __func__, rc, sqlite3_errmsg(db));
		return;
	}
	printf("[saved state] Successfully closing saved state DB\n");
}
