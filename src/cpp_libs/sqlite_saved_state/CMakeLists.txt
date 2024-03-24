

add_library(alexgames_sqlite_saved_state STATIC
            sqlite_saved_state.c)
target_include_directories(alexgames_sqlite_saved_state  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(alexgames_sqlite_saved_state PUBLIC sqlite3)
