#!/usr/bin/env bash

ACTIVATION_BYTES=''
OUTPUT_DIR=''

for BOOK in $@; do
  echo "Book: ${BOOK}"
  BOOK_M4A="$(echo "$(basename "${BOOK}")" | sed -r 's/aax$/m4a/')"
  BOOK_TITLE="$(ffmpeg -i "${BOOK}" 2>&1 | grep '^    title' | grep -Po '(?<=: ).*' | sed -r 's/ \(Unabridged\)$//')"
  BOOK_AUTHOR="$(ffmpeg -i "${BOOK}" 2>&1 | grep '^    artist ' | grep -oP '(?<=: ).*')"
  ffmpeg -ss 2 -activation_bytes ${ACTIVATION_BYTES} -i "${BOOK}" -vn -c:a copy "${OUTPUT_DIR}/${BOOK_M4A}" && \
    mv "${OUTPUT_DIR}/${BOOK_M4A}" "${OUTPUT_DIR}/${BOOK_TITLE} - ${BOOK_AUTHOR}.m4a"
    #rm "${BOOK}"
done
