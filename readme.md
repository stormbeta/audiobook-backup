# Audiobook encoding for personal backups

## Direct rip (requires key)

Set the activation bytes and output dir in `backup.sh`

`./backup.sh AAX_FILES`


## Analog recording
Read audio from line in and encode it with opus

`./record.sh HH:MM:SS OUTPUT.opus [SPEED]`

## Downpour Helper

Downpour makes things needlessly complicated by forcing you to download multiple files. `downpour.sh` is meant to help concatenate everything back into a single convenient file for archival.

Just move all the `m4b` files into the same directory, and run `./downpour.sh PREFIX`
