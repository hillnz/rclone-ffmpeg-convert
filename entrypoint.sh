#!/usr/bin/env bash

rclone mount -v \
    --config="$RCLONE_CONFIG" \
    --vfs-cache-mode writes \
    "${RCLONE_MOUNT_DIR}" \
    "/videos" &
rclone_pid=$!

while true; do

    convert.sh

    # Check if rclone is still running
    if ! kill -0 "$rclone_pid" 2>/dev/null; then
        echo "rclone has died"
        exit 1
    fi

    sleep 1h

done
