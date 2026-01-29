# Audiobook Backup/Archival Scripts

Set output directory for all non-browser scripts in config.sh

## Audible

Requirements: ffmpeg

Converts directly to plain m4b, preserving cover/metadata, does not reencode

Set your activation code in `config.sh`

`./audible.sh AAX_FILES`

## Downpour Helper

Requirements: ffmpeg

Downpour makes things needlessly complicated by forcing you to download multiple files. `downpour.sh` is meant to help concatenate everything back into a single file that's more convenient

`./downpour.sh M4B_1 M4B_2 ...`

## Graphic Audiobook

Extract and give a proper name to Graphic Audio downloads

./graphicaudio.sh "AUTHOR NAME" book_zips...
