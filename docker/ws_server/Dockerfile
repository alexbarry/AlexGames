# TODO have the ws and http server inherit from a common image
# to avoid duplicating so many dependencies
FROM nginx:latest

RUN apt-get update && apt-get install -y \
	python3 \
	python3-pip \
	pipx

RUN python3 -m venv /alexgames_python_venv
ENV PATH="/alexgames_python_venv/bin:$PATH"

RUN pip3 install websockets


WORKDIR /app
COPY . .
ENTRYPOINT [ "python3", "src/server/ws/ws_server.py" ]
