#!/usr/bin/env bash

# Script to help automate bandcamp backups

# Only pushes unzipped albums to Dropbox for now

#jjjjjjjjjj

FULLPATH="$(readlink -f "$1")"
FOLDER="$(basename "${FULLPATH}" | sed -r 's/\.zip//')"

# 7z is incapable of reading some non-ascii filenames
# Can't use unzip as it chokes on other stuff
RENAMED="upload-${RANDOM}"

cp "$FULLPATH" /tmp/
(
  cd /tmp
  if [[ "${FOLDER}" != "${RENAMED}" ]]; then
    mv "${FOLDER}.zip" "${RENAMED}.zip"
  fi
  7z x "${RENAMED}.zip" -o"${FOLDER}"
  for i in "${FOLDER}"/*; do
    # Use NAS to upload if available
    if [[ -e '/Volumes/dropbox/Archive' ]]; then
      mkdir -p "$(dirname "/Volumes/dropbox/Archive/Music/${i}")"
      cp -r "${i}" "/Volumes/dropbox/Archive/Music/${i}"
    else
      echo dropbox upload "${i}" "/Archive/Music/${i}"
    fi
  done
)

