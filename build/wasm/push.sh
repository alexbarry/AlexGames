#!/usr/bin/env bash
set -e
set -u
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

scp "${DIR}/out/alexgames_web.tar.gz" alexbarry.net:/home/alex/
