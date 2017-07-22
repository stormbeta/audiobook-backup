#!/usr/bin/env bash

if [[ $# -lt 3 ]]; then
  echo "Not enough args!" 1>&2
  exit 1
fi

# TODO: Download metadata automatically. Unfortunately it's not baked into the files downpour gives us
NAME="$2"
AUTHOR="$3"

# TODO: These must be manually downloaded 
ls -q ${1}*.m4b | sed -r "s/^(.*)/file '\1'/g" > input

# Bizarrely, ffmpeg cannot handle album art, so we have to add it back in ourselves
# See: https://trac.ffmpeg.org/ticket/2798
artwork="$(AtomicParsley $(ls -q ${1}*.m4b | head -n 1) --extractPix | grep -oP '(?<= )[^ ]*\.(jpg|png)$')"

ffmpeg -f concat -safe 0 -i input -vn -c copy output.m4a

AtomicParsley output.m4a --author "${AUTHOR}" --artwork "${artwork}" --title "${NAME}"

OUTPUT_NAME="${NAME} - ${AUTHOR}.m4a"
OUTPUT_DIR='/tmp'
mv output-temp*.m4a "/tmp/${OUTPUT_NAME}"

