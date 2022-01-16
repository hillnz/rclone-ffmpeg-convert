#!/usr/bin/env bash

VIDEO_EXTENSIONS=('mp4' 'mkv' 'mov' 'm4v' 'ts')
TARGET_CODEC="hevc"
TARGET_ENCODER="libx265"

tmp_dir="$(mktemp -d)"
this=

cleanup() {
    rm -rf "$tmp_dir" || true
    rm -rf "$this.tmp" || true
}
trap 'cleanup' EXIT

shopt -s globstar
for ext in "${VIDEO_EXTENSIONS[@]}"; do

    for f in **/*."$ext"; do
        if [ "$f" = "**/*.$ext" ]; then
            continue
        fi

        this="$f"
        output="${tmp_dir}/$(basename "$f")"

        codec="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$this")"
        if [ -z "$codec" ] || [ "$codec" = "$TARGET_CODEC" ]; then
            continue
        fi

        echo "Converting $this"
        if ! nice -n 10 ffmpeg -i "$this" -c:v "$TARGET_ENCODER" -c:a copy "$output"; then
            echo "Failed to convert $this"
            rm "$output"
            continue
        fi
        
        mv "$output" "$this.tmp"
        mv "$this.tmp" "$this"

    done


done
