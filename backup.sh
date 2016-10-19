#!/usr/bin/env bash

if [[ $# -le 1 ]]; then
  echo "Usage: $0 HH:MM:SS BOOK_NAME.opus [INPUT_SPEED]"
  exit 1
fi

BOOK_LENGTH="$(echo "$1" | perl -pe 's/(\d+):(\d+):(\d+)/\1*3600+\2*60+\3/' | bc)"
SPEED="${3:-1.0}"
RECORD_SECONDS="$(echo "$BOOK_LENGTH / $SPEED" | bc)"

echo "Book length ${BOOK_LENGTH} at ${SPEED}x speed is ${RECORD_SECONDS} seconds"

timeout --foreground "${RECORD_SECONDS}s" ./record.sh "${2:-output.opus}"
