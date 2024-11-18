#!/usr/bin/env bash

set -eo pipefail
shopt -qs extglob

# Graphic Audio is already DRM-free, and the files large enough that it rarely
# makes sense to combine them. We only need to unzip and rename.

function usage {
  # Graphic Audio does not cleanly embed author name in their books - have to pass manually
  echo "Usage: ${0} 'AUTHOR' GRAPHIC_AUDIO_ZIPFILES..." 1>&2
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

if [[ -f "$1" ]]; then
  echo "ERROR: First argument should be quoted author name, but it looks like a file path, aborting" 1>&2
  usage
  exit 3
fi

source config.sh

author="$1"
shift 1

for zipfile in $@; do
  if [[ ! -f "$zipfile" ]]; then
    echo "'$zipfile' not found! Aborting" 1>&2
    exit 4
  fi
  filename="$(zipinfo -1 "$zipfile" | grep -E '\.m4b$')"
  unzip "$zipfile" -d /tmp
  echo "FILENAME: $filename" 1>&2
  (
    cd /tmp
    title="$(ffprobe -v error -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$filename" \
      | perl -pe 's/(\d of \d)/Graphic Audio \1/;s/:/ -/g')"
    output_path="${output}/${title} - ${author}.m4b"
    echo "Copying M4B file to archival: ${output_path}" 1>&2
    mv "$filename" "${output_path}"
  )
done
