#!/usr/bin/env bash

SAMPLE_RATE='44100'
mode="${2:-opus}"

case $mode in
  flac)
    arecord -f S24_3LE -c 2 -r ${SAMPLE_RATE} | \
      flac - -f -o "${1:-output.flac}"
    ;;
  opus)
    arecord -f FLOAT_LE -c 2 -r ${SAMPLE_RATE} | \
      opusenc --downmix-stereo - "${1:-output.opus}"
    ;;
  *)
    echo "unknown mode ${mode}"
    exit 2
esac
