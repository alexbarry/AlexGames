# AlexGames

A collection of simple Lua and Rust games, and an API for playing them including an English dictionary (for word puzzles), websocket multiplayer, state sharing via URL, and auto saving with undo/redo. You can also upload your own Lua games and play in the public web version.

Try the web version here: https://alexbarry.github.io/AlexGames

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/net.alexbarry.alexgames/)

## Brief technical overview

High level:
* Simple API for handling input/output defined in [`game_api.h`](src/game_api/game_api.h). e.g. "draw rectangle", "handle touch", "send/receive multiplayer message".
* Wrappers to this API for [Lua](src/lua_api/lua_api.c), [Rust](src/rust_games/rust_game_api.rs). (C/C++ can call the API directly).
* Games are written for this API in [Lua](src/lua_scripts/games) and [Rust](src/rust_games). (See the "history browser" (described below) for an example of implementing the game API in C++).
* The API is implemented by the following platforms:
    * web (HTML/JS/WASM): ([C wrapper](src/emscripten/emscripten_api.c), [JS callbacks](src/html/js/alexgames_wasm_api.js), [JS Game APIs](src/html/js/alexgames_wasm_wrapper.js)),
    * [wxWidgets](src/ui_wxWidgets/wx_main.cpp), and
    * Android bundles the web version for offline play, and _(experimental)_ Android supports the native AlexGames API, no browser or WebView required: ([C wrapper](src/android/app/src/main/cpp/alex_games_android_jni.cpp), [Java JNI Interface](src/android/app/src/main/java/net/alexbarry/alexgames/AlexGamesJni.java), [Android canvas writes](src/android/app/src/main/java/net/alexbarry/alexgames/graphics/AlexGamesCanvas.java)).

The web version is polished and fairly robust. The wxWidgets and Android native versions serve more as proof of concepts for now, demonstrating how relatively easy it is to bring up a new platform that supports all the games. But they are lacking some functionality.

Some other cool features:
* [History Browser](src/cpp_libs/history_browse_ui/history_browse_ui.cpp) allows you to view previously saved game states, including a preview. The history browser code itself implements the same API as the games, so it should be easy to support it on a new platform. The history browser code also uses the games' code to render previews, meaning it runs them as games within itself, which is also implementing the game interface.
* [Saved State database](src/cpp_libs/saved_state_db) to keep the API simple, the only persistent state is writing to key value pairs (based on HTML local storage). The "saved state database" is a C++ wrapper to allow games to simply call `save_state` with a `uint8_t` array  every time there is a state change, and the saved state database keeps track of the move ID. It also handles distinguishing between game sessions, and supports undo/redo and loading initial state on game start (e.g. browser refresh).
* _(Experimental)_ [Android web games server](src/android/app/src/main/java/net/alexbarry/alexgames/server): this isn't often a useful feature, but if you had a WiFi network with no public internet access, and IP isolation isn't enforced, you could use a phone with the AlexGames Android app to host the simple static HTTP and websocket server. This would allow you to play games with your friends on your local network, without relying on the public internet.

## How to build

### Using docker

**TL;DR:** you can simply run `sudo docker-compose up --build`, then navigate to http://localhost:1234 . This hosts an HTML server on port 1234, and a websocket server on port 55433. But if you want to host it on a public server, you should build the static HTML separately, copy that to your HTML server content path, and run the websocket server separately (see below).

#### Build and host static HTML/JS/WASM

Run this script to build and run the docker image to build the HTML/WASM implementation. This mounts the project as a volume, so that incremental builds are supported. (NOTE: you will need to remove `build/wasm/out` if you have previously built from outside the docker image.)

```
docker/http_server/build.sh
```

For development purposes, you can host a simple HTTP server like this, on port 1234:
```
docker/http_server/start_http_server.sh
```

Alternatively, copy `build/wasm/out/http_out/*` to your HTTP server path.

#### Build and host the websocket server

For development purposes, from a separate terminal, run this command to host the websocket server:
```
sudo docker build -t alexgames_ws_server -f docker/ws_server/Dockerfile .
sudo docker run -p 55433:55433 -it alexgames_ws_server
```

But for hosting on a public server, assuming you are using SSL (HTTPS), you will need to pass your SSL certs to the websocket server:

```
sudo docker run -p 55433:55433 -it alexgames_ws_server \
	--use_ssl \
	--ssl_fullchain /path/to/your_fullchain.pem \
	--ssl_privkey /path/to/your_privkey.pem
```

#### Try your server

If you ran the command to host the static HTML on port 1234, then simply navigate to http://localhost:1234.

If you copied it to your existing HTTP server, then you should be able to open it now.

### How to build manually

See BUILD.md. I find this much more convenient for incremental builds.

## Contact

* Email: `alexbarry.dev2 [ at ] gmail.com`.
* Matrix: [`#alexgames:matrix.org`](https://matrix.to/#/#alexgames:matrix.org)
* Github: https://github.com/alexbarry/AlexGames
* Discord: https://discord.gg/rhy8SuHPYU
* Lemmy: [`!alexgames@lemmy.ca`](https://lemmyverse.link/c/alexgames@lemmy.ca)
