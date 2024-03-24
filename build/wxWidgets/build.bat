rem Run this from a command line "x64 Native Tools Command Prompt for VS ..."
mkdir out
cd out
cmake ..
cmake build .
msbuild alexgames.sln
