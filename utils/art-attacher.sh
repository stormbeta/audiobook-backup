#!/usr/bin/env bash

source ../config.sh

mkdir -p artwork

while read COVER; do
  echo "'${COVER}'"
  base="${COVER%.jpg}"
  audiofile="${OUTPUT_DIR}/${base}.m4a"
  if [[ -e "$audiofile" ]]; then
    echo "Found book: ${audiofile}" 1>&2
    existing_art="$(ffprobe -i "$audiofile" 2>&1 | grep mjpeg)"
    original_ts="$(stat "$audiofile" -c '%y' | cut -f1 -d' ')"
    if [[ -n "$existing_art" ]]; then
      echo "WARNING: Book already has art, will replace!" 1>&2
      AtomicParsley "$audiofile" --artwork REMOVE_ALL --overWrite 1>&2
    fi
    AtomicParsley "$audiofile" --artwork "$COVER" --overWrite
    touch -d "$original_ts" "$audiofile"
    mv "$COVER" ./artwork
  else
    echo "Book not found" 1>&2
  fi
done <<< "$(ls *.jpg)"
