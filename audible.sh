#!/usr/bin/env bash

# Set proper error handling, log all output from stdout/stderr
set -eo pipefail
exec &> >(tee -a "/tmp/$(basename "$0").log")

source config.sh

if [[ -z "$ACTIVATION_BYTES" ]]; then
  echo "ACTIVATION_BYTES not set, cannot continue!" 1>&2
  exit 2
fi

function affprobe {
  ffprobe -activation_bytes $ACTIVATION_BYTES "$@"
}
function affmpeg {
  ffmpeg -activation_bytes $ACTIVATION_BYTES "$@"
}

function m4b_metadata {
  local m4b="$1"
  local field="$2"
  echo "$(affprobe -v error \
    -show_entries format_tags="$field" \
    -of default=nw=1:nk=1 "$m4b")"
}

if [[ $# -ne 1 ]]; then
  echo "Usage: ${0} BOOK.aax" 1>&2
  exit 3
fi

BOOK="$1"
if [[ ! -e "$BOOK" ]]; then
  echo "File does not exist: ${BOOK}" 1>&2
  exit 4
fi

TMPDIR="$(mktemp -d)"
echo "TMPDIR: ${TMPDIR}" 1>&2
final="${TMPDIR}/final.m4b"
decrypted="${TMPDIR}/decrypted.m4b"
trap "rm -rf '${TMPDIR}'" SIGINT SIGTERM EXIT

BOOK_M4B="${BOOK%.*}.m4b"
TITLE="$(m4b_metadata "$BOOK" title)"
TITLE="${TITLE% (Unabridged)}"
F_TITLE="$(echo "$TITLE" | sed -r 's/:/ -/g')"
AUTHOR="$(m4b_metadata "$BOOK" artist)"

OUTPUT_NAME="${F_TITLE} - ${AUTHOR}.m4b"

echo "OUTPUT: ${TMPDIR}/${OUTPUT_NAME}"

# Offsets - used to strip useless intro/outro messages not part of actual book
start_offset="2"
end_offset="4"
eof_timestamp="$(affprobe -i "$BOOK" 2>&1 | grep Duration | awk '{print $2}' | sed 's/,//' | awk -F: '{print ($1*3600+$2*60+$3)-'$end_offset'}')"

echo "EOF Seconds: $eof_timestamp" 1>&2

# Actual conversion - no re-encode needed, copies audio as-is and preserves chapters
affmpeg -i "$BOOK" -ss "$start_offset" -to "$eof_timestamp" -vn -c:a copy "$decrypted"

echo "File size: $(du -sh "$decrypted")" 1>&2

affmpeg -i "$decrypted" -i "$BOOK" \
  -map 0:a \
  -map 1:v? \
  -map_metadata 1 \
  -c copy \
  -disposition:v attached_pic \
  -metadata album="$TITLE" \
  "$final"

echo "Copying to output directory: ${OUTPUT_DIR}/${OUTPUT_NAME}" 1>&2
rsync --progress -h "$final" "${OUTPUT_DIR}/${OUTPUT_NAME}"
