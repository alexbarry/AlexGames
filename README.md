# AlexGames

A collection of simple Lua and Rust games, and an API for playing them including an English dictionary (for word puzzles), websocket multiplayer, state sharing via URL, and auto saving with undo/redo. You can also upload your own Lua games and play in the public web version.

Try the web version here: https://alexbarry.github.io/AlexGames

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/net.alexbarry.alexgames/)

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
