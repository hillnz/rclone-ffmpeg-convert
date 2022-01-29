#!/usr/bin/env python3

from glob import iglob
from os import remove
from os.path import basename, join
from shutil import move, rmtree
from subprocess import PIPE, run
from tempfile import mkdtemp

VIDEO_DIR = '/videos'
VIDEO_EXTENSIONS = ('mp4', 'mkv', 'mov', 'm4v', 'ts')
TARGET_CODEC = "hevc"
TARGET_ENCODER = "libx265"
TARGET_CRF = "26"

tmp_dir = mkdtemp()
this = ""

def cleanup():
    rmtree(tmp_dir)
    try:
        if this:
            remove(this)
    except FileNotFoundError:
        pass


def get_duration(file):
    cmd = ['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', file]
    return float(run(cmd, check=True, stdout=PIPE).stdout.decode('utf-8').strip())


try:

    for ext in VIDEO_EXTENSIONS:

        print(f"Checking files with extension {ext}...")

        for f in iglob(f"{VIDEO_DIR}/**/*.{ext}", recursive=True):

            print(f"Checking {f}...")

            this = f
            output = join(tmp_dir, basename(f))

            try:
                codec = run([
                    'ffprobe', 
                    '-v', 'error', 
                    '-select_streams', 'v:0', 
                    '-show_entries', 'stream=codec_name', 
                    '-of', 'default=noprint_wrappers=1:nokey=1', 
                    this
                ], check=True, stdout=PIPE).stdout.decode('utf-8').strip()
            except Exception as err:
                print(err)
                print(f"ffprobe couldn't read {f}")
                continue
            
            if not codec or codec == TARGET_CODEC:
                continue

            print(f"Converting {this}")
            try:
                original_duration = get_duration(this)

                run([
                    'nice', '-n', '10', 
                    'ffmpeg', 
                    '-i', this,
                    '-c:v', TARGET_ENCODER,
                    '-crf', TARGET_CRF,
                    '-c:a', 'copy',
                    output
                ], check=True)

                # sense check - duration should be almost the same
                new_duration = get_duration(output)
                if abs(original_duration - new_duration) > 1:
                    print(f"Error: {this} duration changed from {original_duration} to {new_duration}")
                    raise Exception("Duration changed")
            except Exception:
                print(f"Failed to convert {this}")
                remove(output)
                continue
            
            tmp = f"{this}.tmp"
            move(output, tmp)
            move(tmp, this)

finally:
    cleanup()
