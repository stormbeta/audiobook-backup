#!/usr/bin/env bash

ACTIVATION_BYTES=''
OUTPUT_DIR=''

for BOOK in $@; do
  echo "Book: ${BOOK}"
  BOOK_MP4="$(echo "$(basename "${BOOK}")" | sed -r 's/aax$/mp4/')"
  BOOK_TITLE="$(ffmpeg -i "${BOOK}" 2>&1 | grep '^    title' | grep -Po '(?<=: ).*' | sed -r 's/ \(Unabridged\)$//')"
  ffmpeg -activation_bytes ${ACTIVATION_BYTES} -i "${BOOK}" -vn -c:a copy "${OUTPUT_DIR}/${BOOK_MP4}" && \
    mv "${OUTPUT_DIR}/${BOOK_MP4}" "${OUTPUT_DIR}/${BOOK_TITLE}.mp4" && \
    rm "${BOOK}"
done
