#!/usr/bin/env bash

# Set proper error handling, log all output from stdout/stderr
set -eo pipefail
exec &> >(tee -a "/tmp/$(basename "$0").log")

source config.sh

if [[ -z "$ACTIVATION_BYTES" ]]; then
  echo "ACTIVATION_BYTES not set, cannot continue!" 1>&2
  exit 2
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: ${0} BOOK.aax" 1>&2
  exit 3
fi

BOOK="$1"
if [[ ! -e "$BOOK" ]]; then
  echo "File does not exist: ${BOOK}" 1>&2
  exit 4
fi
echo "Book: ${BOOK}"

TMPDIR="$(mktemp -d)"
echo "${TMPDIR}"
trap "rm -rf '${TMPDIR}'" SIGINT SIGTERM EXIT

# Heuristics to extract proper title and author into common form from metadata
BOOK_M4A="$(echo "$(basename "${BOOK}")" \
            | sed -r 's/aax$/m4a/')"
BOOK_DATA="$(ffmpeg -i "${BOOK}" 2>&1 || true)"
BOOK_TITLE="$(echo "${BOOK_DATA}" \
              | grep '^    title' \
              | grep -Po '(?<=: ).*' \
              | sed -r 's/ \(Unabridged\)$//' \
              | sed -r 's/:/ -/g')"
BOOK_AUTHOR="$(echo "${BOOK_DATA}" \
               | grep '^    artist ' \
               | grep -oP '(?<=: ).*')"
OUTPUT_NAME="${BOOK_TITLE} - ${BOOK_AUTHOR}.m4b"
echo "OUTPUT: ${TMPDIR}/${OUTPUT_NAME}"

# Extract cover art first
ffmpeg -activation_bytes "${ACTIVATION_BYTES}" -i "${BOOK}" "${BOOK}.${COVER_FORMAT}"

# Offsets - used to strip useless intro/outro messages not part of actual book
start_offset="2"
end_offset="4"
eof_timestamp="$(ffprobe -activation_bytes "$ACTIVATION_BYTES" -i "$BOOK" 2>&1 | grep Duration | awk '{print $2}' | sed 's/,//' | awk -F: '{print ($1*3600+$2*60+$3)-'$end_offset'}')"

echo "EOF Seconds: $eof_timestamp" 1>&2

# Actual conversion - no re-encode needed, copies audio as-is and preserves chapters
ffmpeg -activation_bytes "${ACTIVATION_BYTES}" -i "$BOOK" -ss "$start_offset" -to "$eof_timestamp" -vn -c:a copy "${TMPDIR}/output.m4a"

echo "File size: $(du -sh "${TMPDIR}/output.m4a")" 1>&2

embed_cmd="$(command -v AtomicParsley || command -v atomicparsley)"
if [[ -n "$embed_cmd" ]]; then
  artwork="${BOOK}.${COVER_FORMAT}"
  $embed_cmd "${TMPDIR}/output.m4a" --title "$BOOK_TITLE" --artwork "$artwork"
  mv ${TMPDIR}/output-temp*.m4a "${TMPDIR}/output.m4a"
else
  echo "AtomicParsley not found - cover art will be missing from output!" 1>&2
fi

echo "Copying to output directory: ${OUTPUT_DIR}/${OUTPUT_NAME}" 1>&2
rsync --progress -h "${TMPDIR}/output.m4a" "${OUTPUT_DIR}/${OUTPUT_NAME}"
