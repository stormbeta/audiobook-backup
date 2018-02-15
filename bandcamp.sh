#!/usr/bin/env bash

# Script to help automate bandcamp backups

# Only pushes unzipped albums to Dropbox for now

FULLPATH="$(readlink -f "$1")"
FOLDER="$(basename "${FULLPATH}" | sed -r 's/\.zip//')"

# 7z is incapable of reading files with ä in the name for some reason
# Can't use unzip as it chokes on other stuff
RENAMED="$(echo "$FOLDER" | sed -r 's/ä/a')"

cp "$FULLPATH" /tmp/
(
  cd /tmp
  if [[ "${FOLDER}" != "${RENAMED}" ]]; then
    mv "${FOLDER}.zip" "${RENAMED}.zip"
  fi
  7z x "${RENAMED}.zip" -o"${FOLDER}"
  for i in "${FOLDER}"/*; do
    dropbox upload "${i}" "/Archive/Music/${i}"
  done
)

