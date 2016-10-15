#!/usr/bin/env bash

#TODO: try using sysdefault audio device instead

BOOK_SECONDS="$(echo "$1" | perl -pe 's/(\d+):(\d+):(\d+)/\1*3600+\2*60+\3/' | bc)"

#Opus requires floating-point pcm, but the ancient optiplex only does S32_LE?
timeout "${BOOK_SECONDS}s" \
    arecord -D hw -c 2 -r 44100 -f S32_LE \
  | ffmpeg -i - -acodec pcm_f32le -ar 44100 -f wav - \
  | opusenc --downmix-mono - "${2:-output.opus}"
