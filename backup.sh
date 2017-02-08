#!/usr/bin/env bash

ACTIVATION_BYTES=''
OUTPUT_DIR=''

for BOOK in $@; do
  echo "Book: ${BOOK}"
  BOOK_M4A="$(echo "$(basename "${BOOK}")" | sed -r 's/aax$/m4a/')"
  BOOK_TITLE="$(ffmpeg -i "${BOOK}" 2>&1 | grep '^    title' | grep -Po '(?<=: ).*' | sed -r 's/ \(Unabridged\)$//')"
  BOOK_AUTHOR="$(ffmpeg -i "${BOOK}" 2>&1 | grep '^    artist ' | grep -oP '(?<=: ).*')"
  OUTPUT_NAME="${BOOK_TITLE} - ${BOOK_AUTHOR}.m4a"
  echo "OUTPUT: ${OUTPUT_DIR}/${OUTPUT_NAME}"
  ffmpeg -ss 2 -activation_bytes "${ACTIVATION_BYTES}" -i "${BOOK}" -vn -c:a copy "${OUTPUT_DIR}/${BOOK_M4A}"
  mv "${OUTPUT_DIR}/${BOOK_M4A}" "${OUTPUT_DIR}/${OUTPUT_NAME}"
  #if [[ "$(uname -s)" == "Darwin" ]] && command -v dropbox; then
    #(
      #cd "${OUTPUT_DIR}"
      ##uses https://github.com/andreafabrizi/Dropbox-Uploader
      #dropbox upload "${OUTPUT_NAME}" "Archive/Audiobooks/${OUTPUT_NAME}" &
      #DROPBOX_PID="$!"
      #echo "DROPBOX_PID: ${DROPBOX_PID}"
      #trap "kill ${DROPBOX_PID}; pkill -f curl.*dropbox" SIGINT SIGTERM
      ##NOTE: Mac only - ensures laptop won't sleep while uploading
      #caffeinate -w "${DROPBOX_PID}"
    #)
  #fi
done
