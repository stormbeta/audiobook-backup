#!/usr/bin/env bash

# NOTE:
# This script was never really used - it was put together as a last resort before I discovered better ways to archive audiobooks

if [[ $# -le 1 ]]; then
  echo "Usage: $0 HH:MM:SS BOOK_NAME.opus [INPUT_SPEED]"
  exit 1
fi

export BOOK_LENGTH="$(echo "$1" | perl -pe 's/(\d+):(\d+):(\d+)/\1*3600+\2*60+\3/' | bc)"
export SPEED="${3:-1.0}"
export RECORD_SECONDS="$(echo "$BOOK_LENGTH / $SPEED" | bc)"
export OUTPUT_NAME="${2:-output.opus}"

echo "Book length ${BOOK_LENGTH} at ${SPEED}x speed is ${RECORD_SECONDS} seconds"
export SAMPLE_RATE='44100'
export CHANNELS='1'

mode="$(echo "${OUTPUT_NAME}" | grep -oP '\w{4}$')"

case $mode in
  flac)
    #TODO: will exit early due to non-raw format
    arecord --duration=${RECORD_SECONDS} \
            --format=S24_3LE \
            --channels=${CHANNELS} \
            --rate=${SAMPLE_RATE} \
      | flac - -f -o "${OUTPUT_NAME}"
    ;;
  opus)
    arecord --duration=${RECORD_SECONDS} \
            --format=S16_LE \
            --channels=${CHANNELS} \
            --file-type raw \
            --rate=${SAMPLE_RATE} \
      | opusenc --downmix-mono \
            --raw \
            --raw-rate ${SAMPLE_RATE} \
            --raw-chan ${CHANNELS} \
            --raw-bits 16 \
            - "${OUTPUT_NAME}"
    ;;
  *)
    echo "unknown mode ${mode}"
    exit 2
esac
