#!/usr/bin/env bash

set -eo pipefail
shopt -qs extglob

if [[ $# -lt 1 ]]; then
  echo "Usage: ${0} GRAPHIC_AUDIO_ZIPFILE" 1>&2
  exit 1
fi

readonly zipfile="$1"
readonly author="Brandon Sanderson"

if [[ -d /mnt/dropbox/Archive/Audiobooks ]]; then
  output="/mnt/dropbox/Archive/Audiobooks/Graphic Audio"
elif [[ -d /Volumes/dropbox/Archive/Audiobooks ]]; then
  output="/Volumes/dropbox/Archive/Audiobooks/Graphic Audio"
else
  echo "dropbox mount not found on /mnt or /Volumes" 1>&2
  exit 2
fi

readonly title="$(zipinfo -1 "$zipfile" | head -n1 | sed -E 's:/::g')"

unzip "$zipfile"
echo "Copying M4B file to archival..." 1>&2
mv "${title}/"*.m4b "${output}/${title} - ${author}.m4b"
rmdir "${title}"
