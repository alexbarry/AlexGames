cmake_minimum_required(VERSION 3.4.1)
project(alexgames_wasm VERSION "0.1.1")


get_filename_component(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)

add_definitions(-DALEXGAMES_WASM)

set(SRC_DIR "${PROJECT_ROOT}/src")
set(LUA_SCRIPT_SRC "${SRC_DIR}/lua_scripts")
set(HTML_OUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/out/")

set(ENABLE_MEM_SANITIZER 0)


set(ENABLE_RUST_GAMES "ON")
set(RUST_TARGET  "wasm32-unknown-emscripten")

#set(WASM_USE_C_DICT_API OFF) # uncomment this line to try the JS dictionary instead of the C dictionary
option(WASM_USE_C_DICT_API "Use the C implementation of the dictionary API. The alternative is something in javascript that seems to use a lot of memory" ON)


set(ALEXGAMES_ZLIB_SRC "${PROJECT_ROOT}/third_party/zlib")
set(ALEXGAMES_ZLIB_LIB_DIR  "${ALEXGAMES_ZLIB_SRC}/build/wasm")
execute_process(COMMAND mkdir -p ${ALEXGAMES_ZLIB_LIB_DIR})
set(ALEXGAMES_ZLIB_LIB_PATH "${ALEXGAMES_ZLIB_LIB_DIR}/libz.a")
if(EXISTS ${ALEXGAMES_ZLIB_LIB_PATH})
message("Found libz.a for wasm build at ${ALEXGAMES_ZLIB_LIB_PATH}")
else()
message("Building zlib (libz.a) for wasm...")

execute_process(
	COMMAND "${ALEXGAMES_ZLIB_SRC}/configure"
	WORKING_DIRECTORY ${ALEXGAMES_ZLIB_LIB_DIR}
)

execute_process(
	COMMAND emcmake cmake ${ALEXGAMES_ZLIB_SRC}
	WORKING_DIRECTORY ${ALEXGAMES_ZLIB_LIB_DIR}
)

execute_process(
	COMMAND cmake --build .
	WORKING_DIRECTORY ${ALEXGAMES_ZLIB_LIB_DIR}
)
execute_process(
	COMMAND cp ${ALEXGAMES_ZLIB_SRC}/zconf.h ${ALEXGAMES_ZLIB_LIB_DIR}
)
execute_process(
	COMMAND cp ${ALEXGAMES_ZLIB_SRC}/zlib.h ${ALEXGAMES_ZLIB_LIB_DIR}
)

execute_process(COMMAND ls ${ALEXGAMES_ZLIB_LIB_PATH})
if (EXISTS ${ALEXGAMES_ZLIB_LIB_PATH})
message("Succssfully built ${ALEXGAMES_ZLIB_LIB_PATH}")
else()
message(FATAL_ERROR "Unable to build zlib for wasm (could not find output libz.a at ${ALEXGAMES_ZLIB_LIB_PATH}")
endif()
endif()

# TODO would like to make cmake rebuild if lua_scripts change, not sure how to do that

# Note that all my code and the Lua interpreter is plain C right now, so CXX_COMPILER isn't used
#set(CMAKE_CXX_COMPILER "emcc")
#set(CMAKE_C_COMPILER "emcc")
#set(CMAKE_AR  "emar")
#set(CMAKE_RANLIB  "emranlib")

# I replaced these with EMSCRIPTEN_KEEPALIVE
#list(APPEND EXPORTED_FUNCTIONS_WASM
#     "[ \
#        \"_get_game_count\", \
#        \"_get_game_name\", \
#        \"_init_game_api\", \
#        \"_draw_board\", \
#        \"_handle_user_string_input\", \
#        \"_handle_user_clicked\", \
#        \"_handle_mousemove\", \
#        \"_handle_mouse_evt\", \
#        \"_handle_wheel_changed\", \
#        \"_handle_key_evt\", \
#        \"_handle_touch_evt\", \
#        \"_handle_msg_received\", \
#        \"_handle_btn_clicked\", \
#        \"_handle_popup_btn_clicked\", \
#        \"_load_state\", \
#        \"_lua_run_cmd\", \
#        \"_destroy_game\" \
#        ]")
list(APPEND EXPORTED_FUNCTIONS_WASM
     "[ \
        \"_malloc\", \
        \"_free\" \
        ]")


# On Linux, I get an error when trying to preload files
# that are in parent directories (LUA_SCRIPT_SRC). So copy the scripts into
# a folder in the output path (".") and then preload that instead.
# TODO figure out a good way to make these work on windows too
set(LUA_SCRIPT_PRELOAD_OUT "preload")
execute_process(COMMAND mkdir -p "${LUA_SCRIPT_PRELOAD_OUT}")
execute_process(COMMAND cp -r "${LUA_SCRIPT_SRC}/." "${LUA_SCRIPT_PRELOAD_OUT}/")

list(APPEND EMCC_LINK_OPTS "-Wall")
list(APPEND EMCC_LINK_OPTS "-s DISABLE_EXCEPTION_CATCHING=0")
list(APPEND EMCC_LINK_OPTS "-s EXPORTED_FUNCTIONS='${EXPORTED_FUNCTIONS_WASM}'")
list(APPEND EMCC_LINK_OPTS "-s EXPORTED_RUNTIME_METHODS='[\"ccall\", \"cwrap\", \"setValue\", \"UTF8ToString\"]'")
list(APPEND EMCC_LINK_OPTS "-s NO_EXIT_RUNTIME=1")
# NOTE: if you see this failure:
#     Error: Embedding "preload/lua_scripts" which is below the current directory "build/wasm/out".
#     This is invalid since the current directory becomes the root that the generated code will see
# It can be caused if src/lua_scripts contains a symlink to itself.
# The wxWidgets build was doing this for me at some point
# when creating a symlink with `ln -fs` to create a symlink whether the symlink already exists or not.
# But if the symlink is to a directory, then that can create a symlink within the existing symlink's target.
# The fix on my system was to call `ln -fns`, the `-n` argument telling `ln` not to follow symlinks.
# But apparently this isn't standard POSIX :(
list(APPEND EMCC_LINK_OPTS "--preload-file ${LUA_SCRIPT_PRELOAD_OUT}")
list(APPEND EMCC_LINK_OPTS "-s MODULARIZE=1")
list(APPEND EMCC_LINK_OPTS "-s 'EXPORT_NAME=\"createMyModule\"'")
list(APPEND EMCC_LINK_OPTS "-s LLD_REPORT_UNDEFINED")
list(APPEND EMCC_LINK_OPTS "-s USE_ZLIB=1")
# Without WASM_BIGINT, calling Module.setValue(ptr, val, 'i64') will
# fail if val is too big, and it seems to be too big on some browsers
# (at least the WKWebView on the iOS app running on the simulator)
# when handling touch events, it seems the touch.identifier is
# large in that case
list(APPEND EMCC_LINK_OPTS "-s WASM_BIGINT")
list(APPEND EMCC_LINK_OPTS "-sSUPPORT_LONGJMP=emscripten")
list(APPEND EMCC_LINK_OPTS "-Wno-unused-main")

list(APPEND EMCC_LINK_OPTS
	"-Werror"
	"-s ALLOW_MEMORY_GROWTH=1"

	# tested in a few games on 2023-09-24. It will likely need to grow a lot once
	# the dictionary is loaded into WASM memory.
	#"-s TOTAL_MEMORY=2MB"

	# Now that the dictionary is loaded into WASM memory, that takes ~6.2 MB.
	"-s TOTAL_MEMORY=8MB"

	# I never plan on actually using this much stack.
	# Setting this to 32 kB seemed to work on 2023-09-24.
	# However, when building on macOS, it started crashing when I was
	# inadvertently loading a 64 kB structure on the stack. This was confusing, because I've built on
	# linux and WSL before and never knowingly encountered that. 
	# So my assumption is that this limit was 64 kB on mac OS, but something much higher on the others--
	# or objects when building on macOS are much larger for some reason.
	"-s TOTAL_STACK=128KB"

	# "-s"
	# "-ps"
	#"s"
)
if (ENABLE_MEM_SANITIZER)
list(APPEND EMCC_LINK_OPTS "-fsanitize=undefined")
endif()

list(APPEND EMCC_COMPILE_OPTS
    "-s" "DISABLE_EXCEPTION_CATCHING=0"
    "-Wall"
    "-Werror"
	"-Wno-error=cpp"
	"-Wno-error=sign-compare"
	"-Wno-unused-main"
    "-O3")

if (ALEXGAMES_DEBUG_BUILD)
list(APPEND EMCC_COMPILE_OPTS
    "-g")
endif()

if (ENABLE_MEM_SANITIZER)
list(APPEND EMCC_COMPILE_OPTS
    "-fsanitize=undefined")
endif()

message("WASM_USE_C_DICT_API is ${WASM_USE_C_DICT_API}")
if (WASM_USE_C_DICT_API MATCHES "ON")
message("Using C dictionary implementation")
	#add_library(alexgames_wasm_dict
	#	"${SRC_DIR}/emscripten/emscripten_c_dict_api.c")
	#target_include_directories(alexgames_wasm_dict PRIVATE "${SRC_DIR}/lua_api")
	#target_include_directories(alexgames_wasm_dict PRIVATE "${SRC_DIR}/game_api")
	#target_include_directories(alexgames_wasm_dict PRIVATE "${SRC_DIR}/dictionary")
	list(APPEND libs "alexgames_c_dict")
	list(APPEND extra_em_srcs "${SRC_DIR}/emscripten/emscripten_c_dict_api.c")
	#list(APPEND libs "alexgames_wasm_dict")
elseif (WASM_USE_C_DICT_API MATCHES "OFF")
message("Using JS dictionary implementation")
	list(APPEND extra_em_srcs "${SRC_DIR}/emscripten/emscripten_dict_api.c")
add_definitions(-DALEXGAMES_C_DICT_NOT_INCLUDED)
		
else()
error("Unexpected option for WASM_USE_C_DICT_API: ${WASM_USE_C_DICT_API}")
endif()

add_subdirectory("${SRC_DIR}/" out/alexgames_core)

add_subdirectory("${SRC_DIR}/dictionary" out/dictionary)

add_executable(alexgames_wasm
	"${SRC_DIR}/emscripten/emscripten_api.c"
	# Note that any functions exposed to Javascript must be defined here...
	# well maybe I could build them in a separate library and include that instead.
	${extra_em_srcs})
target_include_directories(alexgames_wasm PRIVATE "${SRC_DIR}/lua_api")
target_include_directories(alexgames_wasm PRIVATE "${SRC_DIR}/game_api")
target_compile_options(alexgames_core  PRIVATE "${EMCC_COMPILE_OPTS}")
target_compile_options(alexgames_wasm PRIVATE "${EMCC_COMPILE_OPTS}")
target_link_libraries(alexgames_wasm  PRIVATE alexgames_core ${libs} "${EMCC_LINK_OPTS}")

add_dependencies(alexgames_wasm generate_dict_file)
#target_link_libraries(alexgames_wasm  PRIVATE cpp_stick "${EMCC_LINK_OPTS}")

# Rebuild if any lua scripts change
# TODO figure out how to make this automatically link the entire lua_scripts dir recursively
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/go")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/wu")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/libs/cards")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/31s")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/life")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/checkers")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/libs/multiplayer")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/crib")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/card_sim")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/touch_test")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/solitaire")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/test")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/libs/serialize")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/minesweeper")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/hospital")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/bound")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/sudoku")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/libs/draw")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/libs/")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/backgammon")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/chess")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/libs/dice")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/blue")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/thrust")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/swarm")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/libs/ui")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/spider_swing")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/poker_chips")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/poker_chips/ui")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/word_mastermind")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/crossword_letters")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/crossword_builder")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/fluid_mix")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/endless_runner")
list(APPEND LINK_DEPS "${LUA_SCRIPT_SRC}/games/minesweeper_life")
set_target_properties(alexgames_wasm PROPERTIES LINK_DEPENDS "${LINK_DEPS}")

# NOTE: if `zip` isn't available on your system, then
#       you can just remove this whole part below. It's simply
#       to provide an example zip game bundle that can be
#       downloaded and re-uploaded for users to try making
#       their own games.


# -j argument removes the path from the contents of the zip, so the zip contains only the files, not
#    all the subfolders like src/lua_scripts/games/api_demo etc
#
execute_process(COMMAND zip "example_game_apidemo.zip"
	"-j" # removes the paths of the files below, so in the zip they're
	     # just "game.lua" instead of "src/lua_scripts/games/api_demo/game.lua".
	"--must-match" # to give an error if a file is not found
	"${LUA_SCRIPT_SRC}/games/api_demo/game_core.lua"
	"${LUA_SCRIPT_SRC}/games/api_demo/game_draw.lua"
	"${LUA_SCRIPT_SRC}/games/api_demo/game.lua"
	RESULT_VARIABLE API_DEMO_ZIP_CMD_RC)
IF ("${API_DEMO_ZIP_CMD_RC}" EQUAL "0")
	message("successfully zipped example_game_apidemo.zip, rc=${API_DEMO_ZIP_CMD_RC}")
ELSE()
	# If this is failing then you can just comment it out,
	# If you are just trying out this project then you don't need this.
	message(FATAL_ERROR "error, zip for example_game_apidemo.zip returned rc=${API_DEMO_ZIP_CMD_RC}")
ENDIF()
