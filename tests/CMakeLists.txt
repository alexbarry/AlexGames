set(SRC_DIR "../src")

add_definitions(-DROOT_DIR=\\"\\")

add_subdirectory("${SRC_DIR}/" out/alexgames_core)

add_executable(test_varint
	utils/test_varint.cpp)
target_include_directories(test_varint PRIVATE "${SRC_DIR}/cpp_libs/utils")
target_link_libraries(test_varint PRIVATE alexgames_varint)

add_executable(test_utf8
	utils/test_utf8_decode.cpp)
target_include_directories(test_utf8 PRIVATE "${SRC_DIR}/cpp_libs/utils")
target_link_libraries(test_utf8 PRIVATE alexgames_utf8)
