#!/usr/bin/env bash

# Downpour unnecessarily splits up audiobook files, we want to merge them back together so each book is a single file
# You can download the parts manually, or use browser-downpour-script.js
# with TamperMonkey in Chrome, then right-click the book from the library page

# Usage: ./downpour.sh path/to/files/book-*

# Requirements:
# * ffmpeg
# * AtomicParsley (to preserve book cover)

OUTPUT_DIR='/Volumes/dropbox/Archive/Audiobooks/'

ls -q ${1}*.m4b | sed -r "s/^(.*)/file '\1'/g" > input
FILE1="$(ls -q ${1}*.m4b | head -n 1)"

fields="$(AtomicParsley "${FILE1}" -t | sed -r 's/^.*Atom "(.*+)" contains: (.*)$/\1=\2/g')"

AUTHOR="$(echo -e "${fields}" | grep '©ART' | sed -r 's/^©ART=(.*)$/\1/')"
NAME="$(echo -e "${fields}" | grep '©alb' | perl -pe 's/^©alb=(.*?)($| \(Unabridged\))/\1/')"
ENC="$(echo -e "${fields}" | grep '©enc' | sed -r 's/^©enc=(.*)$/\1/')"
PUBLISHER="$(echo -e "${fields}" | grep 'cprt' | sed -r 's/^cprt=(.*)$/\1/')"
echo "NAME: ${NAME}"
echo "AUTHOR: ${AUTHOR}"

# Bizarrely, ffmpeg cannot handle album art, so we have to add it back in ourselves
# See: https://trac.ffmpeg.org/ticket/2798
artwork="$(AtomicParsley $(ls -q ${1}*.m4b | head -n 1) --extractPix | grep -oP '(?<= )[^ ]*\.(jpg|png)$')"

ffmpeg -f concat -safe 0 -i input -vn -c copy output.m4a

AtomicParsley output.m4a \
  --title "${NAME}" \
  --artist "${AUTHOR}" \
  --artwork "${artwork}" \
  --copyright "${PUBLISHER}" \
  --encodedBy "${ENC}"

OUTPUT_NAME="${NAME} - ${AUTHOR}.m4a"
rsync --progress -h output-temp*.m4a "${OUTPUT_DIR}/${OUTPUT_NAME}" && \
  rm output-temp*.m4a

#if [[ "$(uname -s)" == "Darwin" ]] && command -v dropbox; then
  #(
    #cd "${CWD}"
    ## Use NAS to upload if available
    #if [[ -e '/Volumes/dropbox/Archive' ]]; then
      #cp "${OUTPUT_DIR}/${OUTPUT_NAME}" "/Volumes/dropbox/Archive/Audiobooks/${OUTPUT_NAME}"
    #else
      ## TODO: Prompt for upload
      ##uses https://github.com/andreafabrizi/Dropbox-Uploader
      #dropbox upload "${OUTPUT_DIR}/${OUTPUT_NAME}" "Archive/Audiobooks/${OUTPUT_NAME}" &
      #DROPBOX_PID="$!"
      #echo "DROPBOX_PID: ${DROPBOX_PID}"
      #trap "kill ${DROPBOX_PID}; pkill -f curl.*dropbox" SIGINT SIGTERM
      ##NOTE: Mac only - ensures laptop won't sleep while uploading
      #caffeinate -w "${DROPBOX_PID}"
    #fi
  #)
#fi
