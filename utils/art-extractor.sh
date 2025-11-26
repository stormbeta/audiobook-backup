#!/usr/bin/env bash

source ../config.sh

# Continually look for *.aax.part partial downloads from Audible
# Then copy out book artwork to a local jpg
# Intended for getting artwork of older books without having to redownload the entire book

while true; do
  while read BOOK; do
    echo "'${BOOK}'"
    BOOK_DATA="$(ffmpeg -i "${BOOK}" 2>&1 || true)"
    BOOK_TITLE="$(echo "${BOOK_DATA}" \
                  | grep '^    title' \
                  | grep -Po '(?<=: ).*' \
                  | sed -r 's/ \(Unabridged\)$//' \
                  | sed -r 's/:/ -/g')"
    BOOK_AUTHOR="$(echo "${BOOK_DATA}" \
                   | grep '^    artist ' \
                   | grep -oP '(?<=: ).*')"
    OUTPUT_NAME="${BOOK_TITLE} - ${BOOK_AUTHOR}.jpg"
    if [[ ! -e "$OUTPUT_NAME" ]]; then
      ffmpeg -activation_bytes "${ACTIVATION_BYTES}" -i "${BOOK}" "$OUTPUT_NAME"
    fi
  done <<< "$(ls "${HOME}/Downloads/"*.aax.part )"
  sleep 0.5
done
