set -e
set -u
set -x

 
mkdir -p src/android/app/src/main/assets/games/preload/
cp -r src/lua_scripts/* src/android/app/src/main/assets/games/preload/
cp -r img/ src/android/app/src/main/assets/games/

mkdir -p src/android/app/src/main/assets/html
cp -r build/wasm/out/http_out/* src/android/app/src/main/assets/html/
cp -r out/words-en.txt src/android/app/src/main/assets/
