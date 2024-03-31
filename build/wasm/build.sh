set -e
set -u
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${DIR}"

# source ./setup_env.sh
mkdir -p out
cd out
#. ~/repo/emsdk/emsdk_env.sh
#alias emcmake=~/repo/emsdk/upstream/emscripten/emcmake
emcmake cmake ../ 
cmake --build . $@

# Rather than leave everything in this directory, I think it make sense
# to move the output to a separate directory for only the content that should be hosted
# by the HTTP server.
# I am adding this now because in iOS/XCode, I can reference a specific folder and seemingly
# reference all of its contents-- and I don't want all the CMake intermediate stuff
# to be bundled into the iOS app.
# But I think it makes sense to separate it anyway, since I also have a script that
# selectively adds files to a zip bundle for transferring it to a server, and it
# doesn't make sense to have to duplicate the list of important HTML/JS/etc files in more than one place
# In fact, doing that led me to forget to upload the word dictionary at some point in the past.
HTTP_OUT=http_out
mkdir -p ${HTTP_OUT}

# words-en.txt is a list of English words, used for words puzzles
cp -r ../../../out/words-*.txt ${HTTP_OUT}/

cp -r ../../../src/html/* ${HTTP_OUT}/
mkdir -p ${HTTP_OUT}/img
cp -r ../../../img/* ${HTTP_OUT}/img/

# CMake outputs that I want to be accessible on the HTTP server
cp -r *.js *.wasm *.data ${HTTP_OUT}/

# This is an example Lua game that the user can download,
# optionally edit, and re-upload to see how to make their own game.
cp -r example_game_apidemo.zip ${HTTP_OUT}/
