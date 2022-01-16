#!/usr/bin/env bash

groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc

chown -R abc:abc /videos

s6-setuidgid abc \
rclone mount -v \
    --cache-dir /tmp/cache \
    --config="$RCLONE_CONFIG" \
    --vfs-cache-mode writes \
    "${RCLONE_MOUNT_DIR}" \
    "/videos" &
rclone_pid=$!

# Wait for mount up to 1 minute
for _ in $(seq 1 60); do
    if mountpoint -q /videos; then
        break
    fi
    sleep 1
done

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
