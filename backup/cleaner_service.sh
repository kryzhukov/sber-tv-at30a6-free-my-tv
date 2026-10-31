#!/system/bin/sh
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done
sleep 30

clean_once() {
    rm -f /cache/update_*.bin 2>/dev/null
    rm -f /cache/*.apk 2>/dev/null
    rm -f /cache/*.tmp 2>/dev/null
    pm trim-caches 2000M 2>/dev/null
    rm -f /data/local/tmp/*.tmp 2>/dev/null
    rm -f /data/local/tmp/*.tar.gz 2>/dev/null
    rm -f /data/local/tmp/test_* 2>/dev/null
    for c in /data/data/*/cache /sdcard/Android/data/*/cache; do
        if [ -d "$c" ]; then
            rm -rf "$c"/* 2>/dev/null
        fi
    done
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
}

clean_once

while true; do
    sleep 1800
    clean_once
done
