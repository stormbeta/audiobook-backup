#!/usr/bin/env bash

arecord -D hw -c 2 -r 44100 -f S32_LE | ffmpeg -i - -acodec pcm_f32le -ar 44100 "${1:-output.wav}"
