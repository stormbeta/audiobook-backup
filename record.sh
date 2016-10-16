#!/usr/bin/env bash

#TODO: try using sysdefault audio device instead

BOOK_SECONDS="$(echo "$1" | perl -pe 's/(\d+):(\d+):(\d+)/\1*3600+\2*60+\3/' | bc)"

SAMPLE_RATE='44100'

SPEED='1.5'
BOOK_SECONDS="$(echo "$BOOK_SECONDS / $SPEED" | bc)"

echo "Recording for $BOOK_SECONDS seconds"

#Opus requires floating-point pcm, but the ancient optiplex only does S32_LE?
timeout "${BOOK_SECONDS}s" \
    arecord -D hw -f S32_LE -c 2 -r ${SAMPLE_RATE} \
  | ffmpeg -i - -acodec pcm_f32le -ar ${SAMPLE_RATE} -f wav -loglevel warning - \
  | opusenc --downmix-mono - "${2:-output.opus}"
