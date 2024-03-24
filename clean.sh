#!/bin/bash 
set -e
set -u
set -x

# navigate to same directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${DIR}"

WX_WIDGETS_VS=build/wxWidgets/.vs
ANDROID_GRADLE=src/android/.gradle
ANDROID_IDEA=src/android/.idea
ANDROID_CXX=src/android/app/.cxx
ANDROID_COPIED_ASSETS=src/android/app/src/main/assets/games/*
ANDROID_COPIED_HTML_GAMES=src/android/app/src/main/assets/html/*

if ls logs/*.log >/dev/null 2>&1; then
	rm logs/*.log
fi

if ls build/*/out/ >/dev/null 2>&1; then
	rm -r build/*/out/
fi

if ls tests/*/out/ >/dev/null 2>&1; then
	rm -r tests/*/out/
fi

if ls third_party >/dev/null 2>&1; then
	rm -rf third_party
fi

if ls "$WX_WIDGETS_VS" 2>&1 1>/dev/null; then
	rm -r "$WX_WIDGETS_VS"
fi

if ls "$ANDROID_GRADLE" 2>&1 1>/dev/null; then
	rm -r "$ANDROID_GRADLE"
fi

if ls "$ANDROID_IDEA" 2>&1 1>/dev/null; then
	rm -r "$ANDROID_IDEA"
fi

if ls $ANDROID_COPIED_ASSETS 2>&1 1>/dev/null; then
	rm -r $ANDROID_COPIED_ASSETS
fi

if ls $ANDROID_COPIED_HTML_GAMES 2>&1 1>/dev/null; then
	rm -r $ANDROID_COPIED_HTML_GAMES
fi

if ls $ANDROID_CXX 2>&1 1>/dev/null; then
	rm -r $ANDROID_CXX
fi

if ls tests/out/ >/dev/null 2>&1; then
	rm -r tests/out/
fi

if ls cscope.out >/dev/null 2>&1; then
	rm cscope.out
fi

(
	cd src/android;
	./gradlew clean;
)
