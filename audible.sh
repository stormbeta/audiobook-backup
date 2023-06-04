#!/usr/bin/env bash

ACTIVATION_BYTES=''

if [[ -e '/Volumes/dropbox' ]]; then
  OUTPUT_DIR='/Volumes/dropbox/Archive/Audiobooks'
elif [[ -e '/mnt/dropbox' ]]; then
  OUTPUT_DIR='/mnt/dropbox/Archive/Audiobooks'
else
  OUTPUT_DIR='/tmp'
fi

# Set proper error handling, log all output from stdout/stderr
set -eo pipefail
exec &> >(tee -a "/tmp/$(basename "$0").log")

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
BOOK_M4A="$(echo "$(basename "${BOOK}")" | sed -r 's/aax$/m4a/')"
BOOK_DATA="$(ffmpeg -i "${BOOK}" 2>&1 || true)"
BOOK_TITLE="$(echo "${BOOK_DATA}" | grep '^    title' | grep -Po '(?<=: ).*' \
  | sed -r 's/ \(Unabridged\)$//' | sed -r 's/:/ -/g')"
BOOK_AUTHOR="$(echo "${BOOK_DATA}" | grep '^    artist ' | grep -oP '(?<=: ).*')"
OUTPUT_NAME="${BOOK_TITLE} - ${BOOK_AUTHOR}.m4a"
echo "OUTPUT: ${TMPDIR}/${OUTPUT_NAME}"

# Extract cover art first
ffmpeg -activation_bytes "${ACTIVATION_BYTES}" -i "${BOOK}" "${BOOK}.png"

# Actual conversion - no re-encode needed, copies audio as-is and preserves chapters
ffmpeg -ss 2 -activation_bytes "${ACTIVATION_BYTES}" -i "${BOOK}" -vn -c:a copy "${TMPDIR}/output.m4a"

echo "File size: $(du -sh "${TMPDIR}/output.m4a")" 1>&2

if command -v AtomicParsley; then
  artwork="${BOOK}.png"
  AtomicParsley "${TMPDIR}/output.m4a" --title "$BOOK_TITLE" --artwork "$artwork"
  mv ${TMPDIR}/output-temp*.m4a "${TMPDIR}/output.m4a"
else
  echo "AtomicParsley not found - cover art will be missing from output!" 1>&2
fi

echo "Copying to output directory" 1>&2
rsync --progress -h "${TMPDIR}/output.m4a" "${OUTPUT_DIR}/${OUTPUT_NAME}"

if [[ "$OUTPUT_DIR" == "/tmp" ]]; then
  echo "Uploading directly to dropbox as mount not found" 1>&2
  if [[ "$(uname -s)" == "Darwin" ]] && command -v dropbox; then
    (
      cd "${OUTPUT_DIR}"
      #uses https://github.com/andreafabrizi/Dropbox-Uploader
      dropbox upload "${OUTPUT_NAME}" "Archive/Audiobooks/${OUTPUT_NAME}" &
      DROPBOX_PID="$!"
      echo "DROPBOX_PID: ${DROPBOX_PID}"
      trap "kill ${DROPBOX_PID}; pkill -f curl.*dropbox" SIGINT SIGTERM
      #NOTE: Mac only - ensures laptop won't sleep while uploading
      caffeinate -w "${DROPBOX_PID}"
    )
  else
    echo "Skipping direct dropbox upload as command not found or not on macOS" 1>&2
  fi
fi
