#!/usr/bin/env bash

set -eo pipefail
shopt -qs extglob

# Graphic Audio is already DRM-free, and the files large enough that it rarely
# makes sense to combine them. We only need to unzip and rename.

if [[ $# -lt 1 ]]; then
  echo "Usage: ${0} GRAPHIC_AUDIO_ZIPFILES..." 1>&2
  exit 1
fi

if [[ -d /mnt/dropbox/Archive/Audiobooks ]]; then
  readonly output="/mnt/dropbox/Archive/Audiobooks/Graphic Audio"
elif [[ -d /Volumes/dropbox/Archive/Audiobooks ]]; then
  readonly output="/Volumes/dropbox/Archive/Audiobooks/Graphic Audio"
else
  echo "dropbox mount not found on /mnt or /Volumes" 1>&2
  exit 2
fi

# Graphic Audio does not cleanly embed author name in their books - have to set manually
author="Brent Weeks"

for zipfile in $@; do
  filename="$(zipinfo -1 "$zipfile" | grep -E '\.m4b$')"
  unzip "$zipfile" -d /tmp
  echo "FILENAME: $filename" 1>&2
  (
    cd /tmp
    title="$(ffprobe -v error -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$filename" \
      | perl -pe 's/(\d of \d)/Graphic Audio \1/g')"
    output_path="${output}/${title} - ${author}.m4b"
    echo "Copying M4B file to archival: ${output_path}" 1>&2
    mv "$filename" "${output_path}"
  )
done
