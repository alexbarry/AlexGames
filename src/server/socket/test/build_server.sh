set -e
set -u
set -x

gcc test_server.c -I.. ../*.c -o out/server -lpthread
