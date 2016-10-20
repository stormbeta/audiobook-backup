#!/usr/bin/env bash

if [[ $# -le 1 ]]; then
  echo "Usage: $0 HH:MM:SS BOOK_NAME.opus [INPUT_SPEED]"
  exit 1
fi

BOOK_LENGTH="$(echo "$1" | perl -pe 's/(\d+):(\d+):(\d+)/\1*3600+\2*60+\3/' | bc)"
SPEED="${3:-1.0}"
RECORD_SECONDS="$(echo "$BOOK_LENGTH / $SPEED" | bc)"
OUTPUT_NAME="${2:-output.opus}"

echo "Book length ${BOOK_LENGTH} at ${SPEED}x speed is ${RECORD_SECONDS} seconds"
SAMPLE_RATE='44100'
CHANNELS='2'

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
            --format=FLOAT_LE \
            --channels=${CHANNELS} \
            --file-type raw \
            --rate=${SAMPLE_RATE} \
      | opusenc --downmix-mono \
            --raw \
            --raw-rate ${SAMPLE_RATE} \
            --raw-chan ${CHANNELS} \
            --raw-bits 32 \ #TODO: Verify this is correct for FLOAT_LE
            - "${OUTPUT_NAME}"
    ;;
  *)
    echo "unknown mode ${mode}"
    exit 2
esac
