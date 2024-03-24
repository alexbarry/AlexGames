set -e
set -u
set -x

DEVICE_ID=emulator-5554
CACHE_DIR=/data/user/0/net.alexbarry.alexgames/files

# adb -s $DEVICE_ID mkdir -p $CACHE_DIR
adb -s $DEVICE_ID push src/lua_scripts $CACHE_DIR/src/lua_scripts
adb -s $DEVICE_ID push img $CACHE_DIR/img

adb -s $DEVICE_ID shell chmod a+rwx $CACHE_DIR/*
adb -s $DEVICE_ID shell chmod a+rwx $CACHE_DIR/*/*
adb -s $DEVICE_ID shell chmod a+rwx $CACHE_DIR/*/*/*
adb -s $DEVICE_ID shell chmod a+rwx $CACHE_DIR/*/*/*/*
adb -s $DEVICE_ID shell chmod a+rwx $CACHE_DIR/*/*/*/*/*
adb -s $DEVICE_ID shell chmod a+rwx $CACHE_DIR/*/*/*/*/*/*

adb -s $DEVICE_ID shell chown u0_a136 $CACHE_DIR/*
adb -s $DEVICE_ID shell chown u0_a136 $CACHE_DIR/*/*
adb -s $DEVICE_ID shell chown u0_a136 $CACHE_DIR/*/*/*
adb -s $DEVICE_ID shell chown u0_a136 $CACHE_DIR/*/*/*/*
adb -s $DEVICE_ID shell chown u0_a136 $CACHE_DIR/*/*/*/*/*
adb -s $DEVICE_ID shell chown u0_a136 $CACHE_DIR/*/*/*/*/*/*

# adb -s $DEVICE_ID shell chgrp u0_a136 $CACHE_DIR/*
# adb -s $DEVICE_ID shell chgrp u0_a136 $CACHE_DIR/*/*
# adb -s $DEVICE_ID shell chgrp u0_a136 $CACHE_DIR/*/*/*
# adb -s $DEVICE_ID shell chgrp u0_a136 $CACHE_DIR/*/*/*/*
# adb -s $DEVICE_ID shell chgrp u0_a136 $CACHE_DIR/*/*/*/*/*
# adb -s $DEVICE_ID shell chgrp u0_a136 $CACHE_DIR/*/*/*/*/*/*
