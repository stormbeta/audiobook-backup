#!/usr/bin/env bash

source ../config.sh

# NOTE: Requires mp4art
#       It's ridiculously faster than AtomicParsley to simply update artwork
#       And it's safer with the index feature as the first image is the one used
#       E.g. ListenAudiobookPlayer fails to load art if the first image is PNG

#export book="$1"

if ! command -v mp4art &>/dev/null; then
  echo "ERROR: mp4art is required!" 1>&2
  exit 2
fi

function replaceCover {
  local book="$1"
  local cover="$2"
  if [[ ! -e "$book" ]]; then
    echo "ERROR: Cannot find file '${book}'!" 1>&2
    exit 1
  fi
  local original_ts="$(stat "$book" -c '%y')"
  mp4art --art-index 0 --replace "$art_path" "$book"
  echo "Restoring original timestamp" 1>&2
  touch -d "$original_ts" "$book"
}

while read book; do
  extension="${book##*.}"
  # TODO: Technically this excludes mp3, but mp3 requires a whole different tool to edit artwork and virtually none of my files are mp3
  if [[ ! "$extension" =~ ^(m4a|m4b|mp4)$ ]]; then
    echo "WARNING: ${book} is not an MPEG4 audio file, skipping" 1>&2
    continue
  fi
  base="$(basename "${book%.*}")"
  if [[ -e "$book" ]]; then
    echo "Book: ${book}" 1>&2
    cover_type="$(mp4art --list --art-index 0 "$book" | tail -n+3 | awk '{print $4}')"
    art_path="${ART_ARCHIVE}/${base}.jpg"
    if [[ "$cover_type" == 'png' ]]; then
      mp4art --art-index 0 --extract "$book"
      echo "Cover is PNG, converting to JPG" 1>&2
      ffmpeg -y -i "$book" "$art_path"
      replaceCover "$book" "$art_path"
    elif [[ "$cover_type" == "jpeg" ]]; then
      echo "Cover is already JPG, skipping" 1>&2
      continue
    elif [[ -z "$cover_type" ]]; then
      echo "WARNING: Cover missing, skipping" 1>&2
    else
      echo "ERROR: Cover in unknown format: '${cover_type}'" 1>&2
      exit 3
    fi
    echo ''
  else
    echo "WARNING: Book not found: ${book}" 1>&2
  fi
done <<< "$(ls /mnt/dropbox/Archive/Audiobooks/*)"
