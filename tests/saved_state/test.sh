set -e
set -u
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${DIR}"

mkdir -p out
cd out/

cmake make ../ 
cmake --build . $@
./test_saved_state
