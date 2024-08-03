set(SRC_DIR ../src)

execute_process(COMMAND git log --pretty=format:'%h' -n 1
                OUTPUT_VARIABLE GIT_HEAD_HASH)

set(OUT_DIR_NAME alexgames_core)

# contains definitions of computer specific paths, like
# lua source code (stored outside this repo)
include(../local_env.cmake)

configure_file("${SRC_DIR}/alexgames_config.h.in" ./alexgames_config.h)

set(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")
set(LIBZIP_DIR "${PROJECT_ROOT}/third_party/libzip/")
set(ZLIB_DIR   "${PROJECT_ROOT}/third_party/zlib/")
set(SQLITE_DIR "${PROJECT_ROOT}/third_party/sqlite/")

set(LUA_DL_DIR "${PROJECT_ROOT}/third_party/lua/")
set(WORDLIST_DL_DIR "${PROJECT_ROOT}/third_party/wordlist/")

# NOTE: this variable should be set in the build specific cmake files, e.g.
# build/wasm/CMakeLists.txt . It should point to the target architecture's
# build of zlib.
get_filename_component(ZLIB_LIBRARY "${ALEXGAMES_ZLIB_LIB_PATH}" ABSOLUTE)
get_filename_component(ZLIB_INCLUDE_DIR "${ALEXGAMES_ZLIB_LIB_DIR}" ABSOLUTE)

# Originally I had made this different for wxWidgets in visual studio, but I think a symlink 
# called "preload" in the build directory, pointing to `src`, has mitigated this.
set(ALEXGAMES_LUA_SCRIPT_ROOT_DIR "" CACHE STRING "Root directory to look for lua scripts. This can be left blank unless your IDE requires you to run the executable from a specific path. Alternatively, you can place a symlink there.")
add_definitions(-DROOT_DIR="\"${ALEXGAMES_LUA_SCRIPT_ROOT_DIR}\"")

option(ENABLE_ZIP_UPLOAD "Enable the ability to upload custom games in zip files. Includes libzip and zlib." ON)

# TODO using sqlite3 increases my WASM output from like 700 kB to ~2.8 MB.
# This does not seem to be worth it, since I thin kthe only algorithm most games
# need is "check if word is valid" and "get random word of length n with frequency 
# above some threshold"
option(ENABLE_WORD_DICT  "Enable the word dictionary. Allows for word puzzle games." ON)

option(ENABLE_SQLITE3_SAVED_STATE "Instead of requiring the platform to implement their own store_data and read_store_data APIs, use SQLite3 and filesystem APIs." OFF)

option (ENABLE_RUST_GAMES "Build rust games" ON)
option (RUST_TARGET  "Rust target (leave blank for native, wasm32-unknown-emscripten for wasm)" "")

option(ALEXGAMES_DEBUG_BUILD "Set to true/on to create a debug build, false for release" OFF)

message("ENABLE_ZIP_UPLOAD is ${ENABLE_ZIP_UPLOAD}")
message("ENABLE_SQLITE3_SAVED_STATE is ${ENABLE_SQLITE3_SAVED_STATE}")
IF (ENABLE_ZIP_UPLOAD)

IF (EXISTS ${ZLIB_DIR})
	message("Found zlib in ${ZLIB_DIR}")
else()
	message("Downloading zlib into ${ZLIB_DIR}")
	execute_process(COMMAND git clone https://github.com/madler/zlib.git ${ZLIB_DIR})
endif()

execute_process(COMMAND ls "${ZLIB_LIBRARY}")
#execute_process(COMMAND ls "${ZLIB_LIBRARY}/asdflkjasdflkjasdflkj.a")
#message(FATAL_ERROR "test")

message("ZLIB_INCLUDE_DIR is ${ZLIB_INCLUDE_DIR}")
message("ZLIB_LIBRARY     is ${ZLIB_LIBRARY}")

#message("adding zlib subdirectory")
#add_subdirectory(${PROJECT_ROOT}/third_party/libzip/ zlib_out)


IF (EXISTS ${LIBZIP_DIR})
	message("Found libzip in ${LIBZIP_DIR}")
else()
	message("Downloading libzip into ${LIBZIP_DIR}")
	execute_process(COMMAND git clone https://github.com/nih-at/libzip.git ${LIBZIP_DIR})
endif()

add_subdirectory(${PROJECT_ROOT}/third_party/libzip/ libzip_out)
# TODO not sure how to suppress CMP0063 from including libzip
# cmake_policy(CXX_VISIBILITY_PRESENT NEW)


# TODO I don't really understand why it's in OUT_DIR_NAME ...
# there must be a better way to get this path
set(ZIPCONF_H_PATH ${CMAKE_BINARY_DIR}/out/${OUT_DIR_NAME}/libzip_out/)

if (EXISTS ${ZIPCONF_H_PATH}/zipconf.h)
message("found zipconf.h in ${ZIPCONF_H_PATH}")
else()
message(FATAL_ERROR "could not find zipconf.h in ${ZIPCONF_H_PATH}")
endif()

endif()

if (ENABLE_WORD_DICT)
IF (EXISTS ${SQLITE_DIR}/sqlite-amalgamation-3420000/sqlite3.c)
	message("Found SQLite in ${SQLITE_DIR}")
else()
	message("Downloading SQLite into ${SQLITE_DIR}")
	execute_process(COMMAND mkdir -p ${SQLITE_DIR}/)
	execute_process(COMMAND wget https://sqlite.org/2023/sqlite-amalgamation-3420000.zip -O ${SQLITE_DIR}/sqlite.zip)
	execute_process(COMMAND unzip ${SQLITE_DIR}/sqlite.zip -d ${SQLITE_DIR})
	# execute_process(COMMAND git clone https://github.com/nih-at/libzip.git ${SQLITE_DIR})
endif()
endif()

if (ENABLE_SQLITE3_SAVED_STATE)
	message("Using SQLite3 for saved state")
	# TODO git clone and etc
	add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/cpp_libs/sqlite_saved_state)
endif()

if(EXISTS ${LUA_SRC_DIR}/lua.h)
# good
else()

if(EXISTS ${LUA_DL_DIR}/lua.h)
#good
else()
execute_process(COMMAND git clone https://github.com/lua/lua.git ${LUA_DL_DIR})
message("Switching to v5.4.6 of lua repo.")
execute_process(
       COMMAND git checkout v5.4.6
       WORKING_DIRECTORY ${LUA_DL_DIR}
)

endif()

set(LUA_SRC_DIR ${LUA_DL_DIR})

if(EXISTS ${LUA_SRC_DIR}/lua.h)
#good
else()
message(FATAL_ERROR "Could not find lua.h in ${LUA_SRC_DIR}. Make sure you set \${LUA_SRC_DIR} in local_env.cmake or allow this makefile to download the repo from github")
endif()
endif()

if (EXISTS ${WORDLIST_DL_DIR})
# good
else()
message("Cloning wordlist git repo into ${WORDLIST_DL_DIR}")
execute_process(COMMAND git clone https://github.com/wordnik/wordlist ${WORDLIST_DL_DIR})
endif()

if (EXISTS ${WORDLIST_ALEXGAMES})
# good
else()
#message("Running script to generate AlexGames English dictionary file")
#execute_process(COMMAND python3 ${PROJECT_ROOT}/src/dictionary/build_word_list_w_freq.py)
endif()


message("Building with LUA_SRC_DIR ${LUA_SRC_DIR}")

#set_source_files_properties(
#	${LUA_SRC_DIR}/lundump.c 
#	PROPERTIES
#	COMPILE_FLAGS -Wno-string-plus-int
#)

aux_source_directory(${LUA_SRC_DIR} LUA_CORE_SRC_LIST)
# This is a duplicate of all the other C files in the repo.
# Including this would cause duplicate function linker errors.
list(FILTER LUA_CORE_SRC_LIST EXCLUDE REGEX "\/onelua.c$")
# This is the standalone interpreter, which defines a main function that
# I do not want to include.
list(FILTER LUA_CORE_SRC_LIST EXCLUDE REGEX "\/lua.c$")

# not currently using lua_user_cfg.h, loading my library manually in C instead
#include_directories(${SRC_DIR}/main)
#add_definitions(-DLUA_USER_H=\"lua_user_cfg.h\" -Dderp)

if (ENABLE_WORD_DICT)
#add_subdirectory(${PROJECT_ROOT}/third_party/sqlite/sqlite-amalgamation-3420000)
#add_library(sqlite STATIC
#	${PROJECT_ROOT}/third_party/sqlite/sqlite-amalgamation-3420000/sqlite3.h
#	${PROJECT_ROOT}/third_party/sqlite/sqlite-amalgamation-3420000/sqlite3.c)

#add_library(alexgames_dict STATIC
#	dictionary/dictionary.c)
#target_include_directories(alexgames_dict PUBLIC ${PROJECT_ROOT}/third_party/sqlite/sqlite-amalgamation-3420000/)
#target_link_libraries(alexgames_dict sqlite)
endif()

#add_library(sqlite STATIC
#	${PROJECT_ROOT}/third_party/sqlite/sqlite-amalgamation-3420000/sqlite3.h
#	${PROJECT_ROOT}/third_party/sqlite/sqlite-amalgamation-3420000/sqlite3.c)
#add_library(alexgames_sqlite_dict STATIC
#	dictionary/dictionary.c)
#target_include_directories(alexgames_sqlite_dict PUBLIC ${PROJECT_ROOT}/third_party/sqlite/sqlite-amalgamation-3420000/)
#target_link_libraries(alexgames_sqlite_dict sqlite)

# For now, this shouldn't be included with the WASM implementation.
# For that one I've chosen to implement the dictionary in Javascript.
# Maybe it would actually make a lot more sense to do it in C,
# but at first I wanted a hashmap (before I discovered how much memory it would consume).
# Also I wasn't exactly sure how to asynchronously download the file from C,
# though I suspect it would be easy.
# TODO: try using this in WASM and seeing if it performs better than the Javascript implementation.
# Somehow firefox uses like 12 MB of memory for strings alone, even though the entirety of this file is 3 MB or so.
add_library(alexgames_c_dict STATIC
	dictionary/c_dictionary.c)
target_include_directories(alexgames_c_dict PRIVATE game_api/)

add_library(lua ${LUA_CORE_SRC_LIST})


# Rust games
if (ENABLE_RUST_GAMES)


message("Rust target is ${RUST_TARGET}")
if (NOT RUST_TARGET)
	set(RUST_TARGET_PATH  "")
	set(RUST_TARGET_CMD  "")
else()
	set(RUST_TARGET_PATH  "${RUST_TARGET}")
	set(RUST_TARGET_CMD  "--target=${RUST_TARGET}")
endif()

# TODO replace "debug" with "release" (or blank?) if not debug build
set(RUST_LIB ${CMAKE_CURRENT_SOURCE_DIR}/rust_games/target/${RUST_TARGET_PATH}/debug/libalexgames_rust.a)

file(GLOB_RECURSE RUST_SOURCE_FILES
	${CMAKE_CURRENT_SOURCE_DIR}/rust_games/*.rs
	${CMAKE_CURRENT_SOURCE_DIR}/rust_games/*.toml
)

message("Rust sources: ${RUST_SOURCE_FILES}")

# TODO add --release if ALEXGAMES_DEBUG_BUILD is not set
add_custom_command(
	OUTPUT "${RUST_LIB}"
	COMMAND cargo build "${RUST_TARGET_CMD}"
	WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/rust_games"
	COMMENT "Building alexgames rust_games library with cargo"
	DEPENDS ${RUST_SOURCE_FILES}
)

add_custom_target(
	alexgames_rust_lib ALL
	DEPENDS "${RUST_LIB}"
)

file(GLOB RUST_LIBS "${CMAKE_CURRENT_SOURCE_DIR}/rust_games/target/wasm32-unknown-unknown/debug/deps/*.a")
message(INFO, "Found libs ${RUST_LIBS}")

list(APPEND libs ${RUST_LIBS})

add_library(alexgames_rust_api STATIC "${CMAKE_CURRENT_SOURCE_DIR}/rust_games/rust_game_api.c")
add_dependencies(alexgames_rust_api alexgames_rust_lib)
add_library(alexgames_rust STATIC IMPORTED)
target_include_directories(alexgames_rust_api PRIVATE game_api/)
target_link_libraries(alexgames_rust INTERFACE "${RUST_LIBS};alexgames_rust_api")
set_target_properties(alexgames_rust PROPERTIES
	IMPORTED_LOCATION ${RUST_LIB}
)


# TODO I'd like to add a sanity check here, but I'm not sure how
#if(EXISTS ${RUST_LIB})
##good
#else()
#message(FATAL_ERROR "could not find rust build output lib at ${RUST_LIB}")
#endif()



endif()

add_library(alexgames_core STATIC
	lua_api/lua_api.c
	lua_api/lua_api_dict.c
	lua_api/lua_api_utils.c
	game_api/game_api.c
	game_api/game_api_words.c
	game_api/game_api_utils.c

	# TODO rename from "emscripten" to "alex_games" or something
	#cpp_games/stick/io/emscripten/main.cpp
	#cpp_games/stick/io/emscripten/draw_game.cpp

	cpp_libs/history_browse_ui/history_browse_ui.cpp
	cpp_libs/touch_scroll_handler/touch_scroll_handler.cpp
	cpp_libs/mouse_scroll_handler/mouse_scroll_handler.cpp
	cpp_libs/game_api_helper/game_api_helper.cpp
	cpp_libs/saved_state_db/saved_state_db.cpp
	cpp_libs/saved_state_db/saved_state_db_c_api.cpp
	cpp_libs/button_helper/button_helper.cpp
	cpp_libs/touch_press_handler/touch_press_handler.cpp
)


target_include_directories(alexgames_core PRIVATE ${LUA_SRC_DIR})
target_include_directories(alexgames_core PRIVATE cpp_libs/utils)
target_include_directories(alexgames_core PRIVATE ${ZIPCONF_H_PATH})
target_include_directories(alexgames_core PUBLIC ${CMAKE_CURRENT_BINARY_DIR})

#add_subdirectory("${SRC_DIR}/cpp_games/stick" out/cpp_stick)

if (ENABLE_WORD_DICT)
#list(APPEND libs alexgames_dict)
endif()

list(APPEND libs "lua")

if( WIN32 )
else()
list(APPEND libs "m")
endif()

if (ENABLE_ZIP_UPLOAD)
list(APPEND libs "zip")
target_compile_definitions(alexgames_core PUBLIC ENABLE_ZIP_UPLOAD)
endif()

if (ENABLE_WORD_DICT)
target_compile_definitions(alexgames_core PRIVATE ENABLE_WORD_DICT)
endif()

if (ENABLE_RUST_GAMES)
list(APPEND libs "alexgames_rust")
target_include_directories(alexgames_core PUBLIC rust_games/)
endif()

message("Including libs: ${libs}")
if( WIN32 )
# TODO split into array and only call target_link_libraries once
target_link_libraries(alexgames_core ${libs})
else()
message("Linking libraries: ${libs}")
target_link_libraries(alexgames_core ${libs})
endif()
target_include_directories(alexgames_core PUBLIC lua_api)
target_include_directories(alexgames_core PUBLIC game_api)
target_include_directories(alexgames_core PUBLIC cpp_libs/history_browse_ui)
target_include_directories(alexgames_core PUBLIC cpp_libs/touch_scroll_handler)
target_include_directories(alexgames_core PUBLIC cpp_libs/mouse_scroll_handler)
target_include_directories(alexgames_core PUBLIC cpp_libs/game_api_helper)
target_include_directories(alexgames_core PUBLIC cpp_libs/saved_state_db)
target_include_directories(alexgames_core PUBLIC cpp_libs/button_helper)
target_include_directories(alexgames_core PUBLIC cpp_libs/touch_press_handler)
target_include_directories(alexgames_core PUBLIC cpp_libs)
if (ENABLE_WORD_DICT)
target_include_directories(alexgames_core PUBLIC dictionary)
endif()
