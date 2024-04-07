cmake_minimum_required(VERSION 3.4.1)

# Not supported yet in the android native version. The web version embedded in the Android app should
# still support this, though.
set(ENABLE_ZIP_UPLOAD OFF CACHE BOOL "Enable the ability to upload custom games in zip files. Includes libzip and zlib." FORCE)

set(SRC_DIR "../../../../..")
# add_definitions(-DROOT_DIR="res/assets/")
# TODO I think this works now for testing...
# but long term this would have to be set at runtime, the output of getCacheDir()
#add_definitions(-DROOT_DIR="/data/data/net.alexbarry.alexgames/cache/")
# on the Nexus 5X emulator, this path is the cache directory
# TODO I really need to set this at runtime
#add_definitions(-DROOT_DIR="/data/user/0/net.alexbarry.alexgames/cache/")
#add_definitions(-DROOT_DIR="/data/user/0/net.alexbarry.alexgames/files/games/")


add_definitions(-DLUA_USE_APICHECK)
# add_definitions(-DLUA_NOBUILTIN)
add_definitions(-DLUAI_ASSERT)
#add_definitions(-DLUA_ANSI)
#add_definitions(-DLUA_USE_LINUX)
# add_definitions(-O0)

#SET(CMAKE_C_FLAGS    "${CMAKE_C_FLAGS} -O0")
#SET(CMAKE_CXX_CFLAGS "${CMAKE_CXX_CFLAGS} -O0")

# add_subdirectory("${SRC_DIR}/lua_api" derp_out/lua_api)
add_subdirectory("${SRC_DIR}" out/alexgames_core)

add_library(alex_games_android_jni SHARED
            alex_games_android_jni.cpp)

#SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--exclude-libs,liblua_core.a")
target_include_directories(alex_games_android_jni PUBLIC "${SRC_DIR}/game_api")
target_include_directories(alex_games_android_jni PUBLIC "${SRC_DIR}/game_api/libzip_out")
# target_compile_options(alexgames_core  PRIVATE "-pie")
# target_compile_options(alexgames_core PRIVATE "-fPIE")
#target_compile_options(alexgames_core PRIVATE "-fPIC")
target_link_libraries(alex_games_android_jni
					  PRIVATE
                      alexgames_core
                      alexgames_c_dict
                      android
                      log dl)
#						"-Wl,--no-warn-shared-textrel" "-w" "-frtti")

