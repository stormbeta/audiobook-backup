#!/usr/bin/env bash

set -e

source config.sh

TMPDIR="$(mktemp -d)"
list="${TMPDIR}/list.txt"
for f in "$@"; do
    printf "file '%s'\n" "$f" >> "$list"
done

author=$(ffprobe -v error -show_entries format_tags=artist \
        -of default=nw=1:nk=1 "$1")
name="$(ffprobe -v error -show_entries format_tags=album \
        -of default=nw=1:nk=1 "$1")"
name="${name% (Unabridged)}"

echo -e "NAME: ${name}\nAUTHOR: ${author}" 1>&2

# NOTE: Requires two separate steps
#       ffmpeg's concat mode is REALLY stupid and wipes ALL
#       metadata + chokes on anything that isn't pure audio
concat="${TMPDIR}/concat.m4b"
output="${TMPDIR}/output.m4b"
trap "rm -rf '${TMPDIR}'" SIGINT SIGTERM EXIT
ffmpeg -hide_banner -loglevel error \
    -f concat -safe 0 -i "$list" \
    -vn -c copy \
    "$concat"
ffmpeg -i "$concat" -i "$1" \
  -map 0:a \
  -map 1:v? \
  -map_metadata 1 \
  -c copy \
  -disposition:v attached_pic \
  -metadata album="$name" \
  "$output"

rm "$list" "$concat"

OUTPUT_NAME="${name} - ${author}.m4b"
#OUTPUT_NAME="$(basename "$1")"
rsync --progress -h "$output" "${OUTPUT_DIR}/${OUTPUT_NAME}" && \
  rm "$output"
