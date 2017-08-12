#!/usr/bin/env bash

set -eo pipefail

TMPDIR="$(mktemp -d)"
echo "${TMPDIR}"
trap "rm -rf '${TMPDIR}'" SIGINT SIGTERM EXIT

(
  cd ${TMPDIR}
  # TODO: These must be manually downloaded
  ls -q ${1}*.m4b | sed -r "s/^(.*)/file '\1'/g" > input
  FILE1="$(ls -q ${1}*.m4b | head -n 1)"

  fields="$(AtomicParsley "${FILE1}" -t | sed -r 's/^Atom "(.*+)" contains: (.*)$/\1=\2/g')"

  AUTHOR="$(echo -e "${fields}" | grep 'aART' | sed -r 's/^aART=(.*)$/\1/')"
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
  OUTPUT_PATH="${PWD}/${OUTPUT_NAME}"
  mv output-temp*.m4a "${OUTPUT_PATH}"
)
