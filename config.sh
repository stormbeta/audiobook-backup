#!/usr/bin/env bash

# NOTE: Intended to be sourced by other scripts
# Configures audio backup scripts

export ACTIVATION_BYTES=''

if [[ -e '/Volumes/dropbox' ]]; then
  export OUTPUT_DIR='/Volumes/dropbox/Archive/Audiobooks'
elif [[ -e '/mnt/dropbox' ]]; then
  export OUTPUT_DIR='/mnt/dropbox/Archive/Audiobooks'
elif [[ -e "${HOME}/storage/downloads" ]]; then
  # Termux-specific directory mapping
  export OUTPUT_DIR="${HOME}/storage/downloads"
else
  echo "WARNING: No preset output dir found, will use /tmp instead!" 1>&2
  export OUTPUT_DIR='/tmp'
fi

if command -v atomicparsley &>/dev/null; then
  alias AtomicParsley=atomicparsley
fi
