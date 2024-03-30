# paths to where external dependencies are on your computer
# I've changed this project to simply download its dependencies
# so that you may not even need to do anything here.

# I do this so I can build from WSL or windows command line.
# It is fine to omit the "IF" entirely and just specify a single
# value for each variable
if(WIN32)
#set(LUA_SRC_DIR C:/misc/lua_build/lua-5.4.3/src)

# Uhh so all of this works fine on my linux desktop, I guess CMake is able to find it?
# And trying to overwrite these variables must do nothing?

# SET(wxWidgets_ROOT_DIR 'C:/misc/wx_test')
#SET(wxWidgets_ROOT_DIR C:/misc/wx_test/)
#SET(wxWidgets_LIB_DIR C:/misc/wx_test/lib/vc_lib)

# I might have needed these when I built using visual studio
# instead of msbuild, but I'm not sure
#SET(wxWidgets_LIBRARIES C:/misc/wx_test/lib)
#SET(wxWidgets_INCLUDE_DIRS C:/misc/wx_text/)

# SET(wxWidgets_ROOT_DIR 'C:\\misc\\wx_test\\build\\vc_mswud')
set(wxWidgets_CONFIGURATION mswud)

else()
#set(LUA_SRC_DIR "/home/alex/repo/lua/lua-5.4.3/src")
endif()


set(ZLIB_LIBRARY     ${PROJECT_ROOT}/third_party/zlib/libz.a)
set(ZLIB_INCLUDE_DIR ${PROJECT_ROOT}/third_party/zlib/)

