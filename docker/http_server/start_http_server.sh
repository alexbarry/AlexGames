#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${DIR}/../../"

sudo docker run \
	--rm \
	-v $(pwd)/build/wasm/out/http_out:/usr/share/nginx/html/ \
	-p 1234:80 \
	"nginx:latest"
