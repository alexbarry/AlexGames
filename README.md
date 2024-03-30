# AlexGames

A collection of simple Lua games, and a web engine for playing them including an English dictionary (for word puzzles), websocket multiplayer, state sharing via URL, and auto saving with undo/redo. You can also upload your own games and play in the public web version.

Try the web version here: https://alexbarry.github.io/AlexGames

## How to build

### Using docker

**TL;DR:** you can simply run `sudo docker-compose up`, then navigate to http://localhost:1234 . This hosts an HTML server on port 1234, and a websocket server on port 55433. But if you want to host it on a public server, you should build the static HTML separately, copy that to your HTML server content path, and run the websocket server separately.

#### Build and host static HTML/JS/WASM

```
sudo docker build -t alexgames_http_server -f docker/http_server/Dockerfile .
```

For development purposes, you can host a simple HTTP server like this, on port 1234:
```
sudo docker run -p 1234:80 alexgames_http_server
```

Alternatively, to copy the static HTML to your own HTTP server, you can get it from the docker image like this:
```
# create a temporary container to get the build output
sudo docker create --name alexgames_http_server_image alexgames_http_server
# Change the last argument (the dot) to the path where you want to copy it to
sudo docker cp alexgames_http_server_image:/app/build/wasm/out/http_out .

# clean up the temporary container
sudo docker rm alexgames_http_server_image

# Note that you may want to change the owner from root, to do that you can
# run the below command (changing `your_username` to your username):
sudo chown -R your_username http_out
```

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
