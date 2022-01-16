#!/usr/bin/env bash

groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc

chown abc:abc /videos

s6-setuidgid abc \
rclone mount -v \
    --cache-dir /tmp/cache \
    --config="$RCLONE_CONFIG" \
    --vfs-cache-mode writes \
    "${RCLONE_MOUNT_DIR}" \
    "/videos" &
rclone_pid=$!

while true; do

    s6-setuidgid abc \
    convert.sh

    # Check if rclone is still running
    if ! kill -0 "$rclone_pid" 2>/dev/null; then
        echo "rclone has died"
        exit 1
    fi

    sleep 1h

done
