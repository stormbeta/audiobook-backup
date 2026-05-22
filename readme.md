# Audiobook Backup/Archival Scripts

Set output directory for all non-browser scripts in config.sh

## Audible

Requirements: ffmpeg, mp4art/AtomicParsley (optional)

Converts directly to plain m4b, preserving cover/metadata, does not reencode

Set your activation code in `config.sh`

`./audible.sh AAX_FILES`

## Downpour Helper

Requirements: ffmpeg

Downpour makes things needlessly complicated by forcing you to download multiple files. `downpour.sh` is meant to help concatenate everything back into a single file that's more convenient

`./downpour.sh M4B_1 M4B_2 ...`

## Soundbooth Theater

Requirements: ffmpeg, mutagen (optional)

SBT uses plain mp3 files for each chapter/subchapter, but it's app-based so the formatting is weird

1. On an Android device/VM with SBT installed, ensure every item in a book is downloaded (tap on track, tap on Download)
2. Copy `/data/data/com.mobile.soundbooththeater` to same directory as `sbt_extract.py`
   You will need root or access to the VM data store e.g. Waydroid
   Fix file ownership if needed (e.g. `chown -R $USER:$USER com.mobile.soundbooththeater`)
3. `python3 sbt_extract.py`, select which one you want to do

Waydroid path: `~/.local/share/waydroid/data/data/com.mobile.soundbooththeater`

NOTE: This transcodes the audio from mp3 to mp4, which can be slow. This was done because most
players, including my preferred ListenAudiobookPlayer, do not support MP3 chapters

TODO: Does not yet honor config values in config.sh

TODO: Add option to preserve MP3 format instead of transcoding

## Graphic Audiobook

Graphic Audio downloads are simple zip archives

Extract and give a proper name to Graphic Audio downloads

./graphicaudio.sh "AUTHOR NAME" book_zips...
