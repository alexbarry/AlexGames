# TODO have the ws and http server inherit from a common image
# to avoid duplicating so many dependencies
FROM nginx:latest as base

# Install OS dependencies
# TODO double check that all of these are actually needed
# zip: used to zip some lua files as an example game to be uploaded
RUN apt-get update && apt-get install -y \
	cmake \
	git \
	python3 \
	python3-pip \
	pipx \
	ninja-build \
	wget \
	xz-utils \
	zlib1g-dev \
	zip

RUN which zip

# Create a python venv to suppress nginx complaining about
# installing packages to system python.
# (Not sure why this is needed inside a docker container)
RUN python3 -m venv /alexgames_python_venv
ENV PATH="/alexgames_python_venv/bin:$PATH"

# Install python dependencies
RUN pip3 install wordfreq # needed to generate dictionary file

# Install Emscripten
WORKDIR /app
RUN if [ ! -f "emsdk" ]; then \
	echo "Cloning emsdk repo..."; \
	git clone https://github.com/emscripten-core/emsdk.git emsdk ; \
else \
	echo "emsdk repo already present"; \
fi
WORKDIR /app/emsdk
RUN ./emsdk install latest
RUN ./emsdk activate latest
RUN . ./emsdk_env.sh
ENV PATH="${PATH}:/app/emsdk"
#ENV EM_CONFIG="/root/.emscripten"
RUN /bin/bash -c "source ./emsdk_env.sh"
ENV PATH="${PATH}:/app/emsdk/upstream/emscripten"
RUN emcc --version


# Install and build zlib for wasm (using emscripten)
WORKDIR /app/third_party/
RUN if [ ! -d "zlib" ]; then \
	git clone https://github.com/madler/zlib.git ; \
fi
WORKDIR /app/third_party/zlib/
RUN if [ ! -f "libz.a" ]; then \
	emconfigure ./configure ; \
	emcmake cmake . ; \
	# omitting emcmake below seemed to be necessary \
	cmake --build . ; \
fi
RUN ls libz.a





# Build alexgames
WORKDIR /app
COPY . .
#RUN mkdir -p build/wasm/out/
#RUN mkdir -p build/wasm/out/http_out
WORKDIR build/wasm/
RUN bash ./build.sh

# Copy build output to nginx serving path
RUN cp -r out/http_out/* /usr/share/nginx/html/

FROM scratch as export_output
COPY --from=base /app/build/wasm/out/http_out/ /

FROM base as server
# Use base nginx entrypoint to host HTTP server
