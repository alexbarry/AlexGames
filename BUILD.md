# Building manually

See README.md for how to build using docker. This page is for how to build manually, which I find more convenient for incremental builds while developing.

## Prerequisite: Install Emscripten

Install emscripten following [these instructions](https://emscripten.org/docs/getting_started/downloads.html):

	mkdkir -p ~/repo/
	cd ~/repo/
	git clone https://github.com/emscripten-core/emsdk.git
	./emsdk install latest
	./emsdk activate latest

Alternatively, install it anywhere, but update `build/wasm/setup_env.sh`.

## Prerequisite: Install virtualenv and python dependencies

Install virtualenv with your package manager.

	virtualenv venv
	source venv/bin/activate

Now install python dependencies

	# for generating the word dictionary
	pip3 install wordfreq

	# for hosting the websocket server
	pip3 install websocket

Now you are ready to build the web version and host the websocket server in
the next steps.

Once you want to stop hosting the websocket server, and exit the virtual
python environment, you can run this command:

	deactivate

## Building zlib to wasm

I'm not sure why this is sometimes necessary, I thought emscripten was supposed
to include zlib. On some computers that I have tried building this project on,
I did not need to perform these steps.

I would recommend only following these if you get an error like
"can't find zlib, set `ZLIB_LIBRARY` and `ZLIB_INCLUDE_DIR`".

```
cd third_party/zlib
emconfigure ./configure
emcmake cmake .
# omitting emcmake below seemed to be necessary
cmake --build .
```

Then uncomment these two lines in `src/CMakeLists.txt`:

```
get_filename_component(ZLIB_LIBRARY "${PROJECT_ROOT}/third_party/zlib/libz.a" ABSOLUTE)
get_filename_component(ZLIB_INCLUDE_DIR "${PROJECT_ROOT}/third_party/zlib" ABSOLUTE)
```

## Building AlexGames web

Simply run:

	build/wasm/build.sh -- -j32

Optionally omitting the `-- -j32` to only use one thread when compiling,
which makes finding errors in the output easier.

This should automatically download all the dependencies you'd need into
`third_party/`.

Now you can just host the static HTML content in `build/wasm/out/http_out/` 
and you are mostly done. (See next section for guidance).

## How to host server

Host websocket server (make sure you installed the `websocket` dependency
already from a previous step):

	python3 src/server/ws/ws_server.py

And in another terminal, host the HTTP server (note: don't do this on a
public server, this is for development only):

	cd build/wasm/out/http_out
	python3 -m http.server 1234

(Where 1234 is a port. You can choose a different number.)

Then navigate to this in a browser:

	http://localhost:1234
