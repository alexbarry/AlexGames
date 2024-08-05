#!/usr/bin/env bash
#
# I needed to run this when running docker desktop on macOS:
#
#     docker pull nginx:latest
#
# But I don't remember having to do this on linux docker cli installed
# from the package manager.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${DIR}/../../"

DOCKER_TAG=alexgames_http_build

set -eux

# Change this to remove the old image
if [ 1 -eq 0 ]; then
	prev_img_id=$(docker images -q ${DOCKER_TAG})
	if [ -n "${prev_img_id}" ]; then
		echo "Removing previous image ${prev_img_id}"
		sudo docker rmi "${prev_img_id}"
	fi
fi

prev_img_id=$(docker images -q ${DOCKER_TAG})
if [ -z "${prev_img_id}" ]; then

	sudo docker build -t "${DOCKER_TAG}" \
		-f docker/http_server/Dockerfile.build_wasm \
		.
	img_id=$(docker images -q ${DOCKER_TAG})

	echo "Successfully built docker image ${DOCKER_TAG} to image id ${img_id}"
fi

sudo docker run \
	--rm \
	-v $(pwd):/app \
	"${DOCKER_TAG}"
