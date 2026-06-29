#!/usr/bin/env bash

set -eo pipefail

# Graphic Audio is already DRM-free, and the files large enough that it rarely
# makes sense to combine them. We only need to unzip and rename.

function usage {
  echo "Usage: ${0} GRAPHIC_AUDIO_ZIPFILES..." 1>&2
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

source config.sh

output="${OUTPUT_DIR}/Graphic Audio"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

for zipfile in "$@"; do
  if [[ ! -f "$zipfile" ]]; then
    echo "'$zipfile' not found! Aborting" 1>&2
    exit 4
  fi

  filename="$(zipinfo -1 "$zipfile" | grep -E '\.m4b$')"
  unzip -q "$zipfile" -d "$tmpdir"
  filepath="$tmpdir/$filename"
  echo "FILENAME: $filename" 1>&2

  title="$(ffprobe -v error -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$filepath" \
    | perl -pe 's/(\d of \d)/Graphic Audio \1/;s/:/ -/g')"
  echo "TITLE: ${title}" 1>&2

  copyright="$(ffprobe -v error -show_entries format_tags=copyright -of default=noprint_wrappers=1:nokey=1 "$filepath")"
  author="$(echo "$copyright" | perl -ne 'print "$1" if /Copyright © \d+ (.+?)\. All rights/i')"
  if [[ -z "$author" ]]; then
    echo "ERROR: could not parse author from copyright tag: '$copyright'" 1>&2
    exit 5
  fi
  echo "AUTHOR: $author" 1>&2

  output_path="${output}/${title} - ${author}.m4b"
  echo "Copying M4B file to archival: ${output_path}" 1>&2
  mv "$filepath" "${output_path}"
done
