project(alexgames)
cmake_minimum_required(VERSION 3.10)

include(../../local_env.cmake)

get_filename_component(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)

# TODO this is causing syntax errors when I try to cmake build
# add_definitions(-D"api_check(L,o)=assert(o)")

set(CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD 17) # This was needed on MacOS for me

add_definitions(-DROOT_DIR="\"${ALEXGAMES_LUA_SCRIPT_ROOT_DIR}\"")

set(ENABLE_SQLITE3_SAVED_STATE ON CACHE BOOL "Enable SQLIte3 saved state" FORCE)

set(SRC_DIR "../../src")
#set(PROJECT_ROOT "${SRC_DIR}/../")
set(LUA_SCRIPT_SRC "../${SRC_DIR}/lua_scripts")


# TODO maybe move this to a separate file? It's distracting
# And ideally it could be shared with emscripten
if(ENABLE_ZIP_UPLOAD)
set(ALEXGAMES_ZLIB_SRC "${PROJECT_ROOT}/third_party/zlib")
set(ALEXGAMES_ZLIB_LIB_DIR  "${ALEXGAMES_ZLIB_SRC}/build/native")
execute_process(COMMAND mkdir -p ${ALEXGAMES_ZLIB_LIB_DIR})
set(ALEXGAMES_ZLIB_LIB_PATH "${ALEXGAMES_ZLIB_LIB_DIR}/libz.a")
if(EXISTS ${ALEXGAMES_ZLIB_LIB_PATH})
message("Found libz.a for native build at ${ALEXGAMES_ZLIB_LIB_PATH}")
else()
message("Building zlib (libz.a) for native...")

execute_process(
	COMMAND "${ALEXGAMES_ZLIB_SRC}/configure"
	WORKING_DIRECTORY ${ALEXGAMES_ZLIB_LIB_DIR}
)

execute_process(
	COMMAND make
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
message(FATAL_ERROR "Unable to build zlib for native (could not find output libz.a at ${ALEXGAMES_ZLIB_LIB_PATH}")
endif()
endif()
endif()


#set(WXWIDGETS_DL_DIR ${PROJECT_ROOT}/third_party/wxwidgets)
#execute_process(COMMAND git clone https://github.com/wxWidgets/wxWidgets.git ${WXWIDGETS_DL_DIR})
#set(wxWidgets_INCLUDE_DIRS ${WXWIDGETS_DL_DIR})
#set(wxWidgets_LIBRARIES    ${WXWIDGETS_DL_DIR}/alex_out)
#set(wxBUILD_SHARED OFF)
#message("adding wxwidgets (${WXWIDGETS_DL_DIR}) as a subdirectory...")
#add_subdirectory(${WXWIDGETS_DL_DIR} wxwidgets_out)
#message("done adding wxwidgets (${WXWIDGETS_DL_DIR}) as a subdirectory")


# aux_source_directory(. 'minimal.cpp')
SET(SRC_LIST
	../../src/ui_wxWidgets/wx_main.cpp
	../../src/ui_wxWidgets/wx_network_ui.cpp
	../../src/ui_wxWidgets/wx_network.cpp
	../../src/ui_wxWidgets/wx_game_popup.cpp
	../../src/server/socket/socket_server_impl.c
)

# find_package(wxWidgets COMPONENTS core base REQUIRED)
# NOTE: if this fails, you likely need to install wxWidgets
# * windows: I think I downloaded the source and built it myself in a separate
#            directory on my PC, then set `wxWidgets_INCLUDE_DIRS` and `wxWidgets_LIBRARIES`
#            in `local_env.cmake` at the root of this repo.
# * macOS: `brew install wxwidgets`
# * linux: search your package manager for wxwidgets-gtk3
# *  - arch: `pacman -S wxwidgets-gtk3 wxwidgets-common`
#
message("Finding wxWidgets, using wxWidgets_INCLUDE_DIRS=${wxWidgets_INCLUDE_DIRS}")
find_package(wxWidgets COMPONENTS core base REQUIRED)
if(EXISTS ${wxWidgets_USE_FILE})
include(${wxWidgets_USE_FILE})
else()
message(FATAL_ERROR "\${wxWidgets_USE_FILE} not set!")
endif()

# TODO move this makefile to somewhere else
add_subdirectory("${SRC_DIR}/" out/alexgames_core)

list(APPEND libs alexgames_core)
list(APPEND libs alexgames_c_dict)
list(APPEND libs alexgames_sqlite_saved_state)

# TODO include param to disable this
# TODO actually this should probably be included in the common src/CMakeLists.txt, and have platform specific CMakeLists.txt just set a param
# to enable it
list(APPEND libs "alexgames_lua_mcts")

add_executable(${PROJECT_NAME} ${SRC_LIST})
#target_link_libraries(${PROJECT_NAME} ${wxWidgets_LIBRARIES})
#target_include_directories(${PROJECT_NAME} PRIVATE "${WXWIDGETS_DL_DIR}/alex_out/lib/wx/include/osx_cocoa-unicode-3.3/")
#target_include_directories(${PROJECT_NAME} PRIVATE "${WXWIDGETS_DL_DIR}/include")
target_include_directories(${PROJECT_NAME} PRIVATE "${SRC_DIR}/lua_api")
target_include_directories(${PROJECT_NAME} PRIVATE "${SRC_DIR}/server/socket")
target_include_directories(${PROJECT_NAME} PUBLIC .)
#target_link_libraries(${PROJECT_NAME}  PRIVATE cpp_stick)
target_link_libraries(${PROJECT_NAME}  PRIVATE ${libs} ${wxWidgets_LIBRARIES})
