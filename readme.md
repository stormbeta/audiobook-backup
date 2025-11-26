# Audiobook encoding for personal backups

Set output directory for all non-browser scripts in config.sh

## Direct rip (requires key)

Decrypts and preserves cover image, output extension is m4b

Set the activation bytes and output dir in `config.sh`

`./audible.sh AAX_FILES`

Requirements:

* ffmpeg
* AtomicParsley (for cover art)

## Downpour Helper

Downpour makes things needlessly complicated by forcing you to download multiple files. `downpour.sh` is meant to help concatenate everything back into a single convenient file for archival.

Just move all the `m4b` files into the same directory, and run `./downpour.sh PREFIX`

## Graphic Audiobook

./graphicaudio.sh "AUTHOR NAME" book_zips...
