#!/usr/bin/env bash
set -e
set -u
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${DIR}"

mkdir -p out
cd out

cmake ../
cmake --build . $@

# adding `-n` arg to avoid creating a symlink inside the destination
# if they already exist. This breaks the wasm build in a confusing way. 
ln -fns ../../../src/lua_scripts/ preload
ln -fns ../../../img/ img
ln -fns ../../../out/words-en.txt ./
