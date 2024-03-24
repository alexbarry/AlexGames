set(SRC_DIR ../../src)

# TODO remove this
add_definitions(-DROOT_DIR="\\"\\"")

add_subdirectory("${SRC_DIR}/" out/alexgames_core)

add_executable(test_saved_state 
	test_saved_state_db.cpp)
target_link_libraries(test_saved_state PRIVATE alexgames_core) 
target_include_directories(test_saved_state PUBLIC
                           ${SRC_DIR}/game_api 
                           ${SRC_DIR}/cpp_libs/game_api_helper)
