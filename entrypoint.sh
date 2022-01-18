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
echo "Waiting for mount..."
for _ in $(seq 1 60); do
    if s6-setuidgid abc mountpoint -q /videos; then
        break
    fi
    sleep 1
    echo "Still waiting for mount..."
done

if ! s6-setuidgid abc mountpoint -q /videos; then
    echo "Failed to mount"
    exit 1
fi

while true; do

    s6-setuidgid abc \
    python3 "$(which convert.py)"

    # Check if rclone is still running
    if ! kill -0 "$rclone_pid" 2>/dev/null; then
        echo "rclone has died"
        exit 1
    fi

    sleep 1h

done
