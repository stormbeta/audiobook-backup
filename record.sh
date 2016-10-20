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

mode="$(echo "${OUTPUT_NAME}" | grep -oP '\w{4}$')"

case $mode in
  flac)
    arecord --duration=${RECORD_SECONDS} \
            --format=S24_3LE \
            --channels=2 \
            --rate=${SAMPLE_RATE} \
            --file-type raw \
      | flac - -f -o "${OUTPUT_NAME}"
    ;;
  opus)
    arecord --duration=${RECORD_SECONDS} \
            --format=FLOAT_LE \
            --channels=2 \
            --file-type raw \
            --rate=${SAMPLE_RATE} \
      | opusenc --downmix-mono - "${OUTPUT_NAME}"
    ;;
  *)
    echo "unknown mode ${mode}"
    exit 2
esac
