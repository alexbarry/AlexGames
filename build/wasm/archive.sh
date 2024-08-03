#!/usr/bin/env bash
set -e
set -u
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${DIR}"

ARCHIVE_NAME_NO_EXT="alexgames_web"

cd out
tar cvf ${ARCHIVE_NAME_NO_EXT}.tar http_out/*
gzip -f "${ARCHIVE_NAME_NO_EXT}.tar"

echo "Created archive at \"${DIR}/out/${ARCHIVE_NAME_NO_EXT}.tar.gz\""
