#!/usr/bin/env python3
import glob
import os
import subprocess
import json

"""
Messy script to consolidate SoundBoothTheater files into a single file with proper chapter headings

This is not easy to automate properly as they don't follow consistent naming patterns that sort cleanly, and the files themselves have to be extracted from an android device or VM with root, as SBT only has an app no proper site/software

TODO: inject album art - will have to pick one as some projects have multiple

So far I've only had to do this for two books:
Epithet Erased - was pretty straightforward as the tracks had consistent names/ordering
Dungeon Crawler Carl Audio Immersion Tunnel 01 - nightmare, ep1 had inconsistent naming, ending credits are named wrong, ordering of interludes is wrong, etc. I had to manual order everything by cross-referencing the app's UI
"""

def get_duration(filename: str) -> float:
    """Get the duration of the audio file using ffprobe."""
    result = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "json", filename],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    # Parse the JSON output
    info = json.loads(result.stdout)
    try:
        return float(info['format']['duration'])
    except KeyError:
        print(f"Malformed: {filename}")
        exit(1)

def create_chapters(files: list[str]) -> str:
    """Create chapter metadata based on file durations."""
    chapters = [";FFMETADATA1"]
    start_time = 0
    for idx, file in enumerate(files):
        print(file)
        duration = get_duration(file) * 1000  # Convert to milliseconds
        end_time = start_time + duration
        title: str = file.removesuffix('.mp3')
        chapters.append(f"[CHAPTER]")
        chapters.append(f"TIMEBASE=1/1000")
        chapters.append(f"START={int(start_time)}")
        chapters.append(f"END={int(end_time)}")
        chapters.append(f"title={title}")
        start_time = end_time
    return "\n".join(chapters)


def write_metadata(chapters_txt: str, output_file: str) -> None:
    with open(output_file, "w") as f:
        f.write(chapters_txt)


def concatenate_mp3s(files: list[str], output_file: str) -> None:
    with open("filelist.txt", "w") as f:
        for filename in files:
            f.write(f"file '{filename}'\n")
    subprocess.run(["ffmpeg", "-f", "concat", "-safe", "0", "-i", "filelist.txt", "-c", "copy", output_file])

if __name__ == "__main__":
    # Hacky command to try and make filenames make sense, SBT app arranges them weird
    #for i in *.mp3; do x="$(echo "$i" | grep -oP 'Episode_\d\d(\w+)(?=\.mp3$)' | sed -r 's/(Episode_[0-9]{2})[0-9A-Za-z_]+(S[0-9]{2}E[0-9]{2,4})_?A?([0-9A-Za-z_]+)+/\2 - \3/g;s/AIT_192k_//;s/_/ /g')"; mv "$i" "${x}.mp3"; done
    mp3_files: list[str] = glob.glob("S0*.mp3")
    mp3_files.sort()

    chapter_metadata: str = create_chapters(mp3_files)

    metadata_file: str = "chapters.txt"
    write_metadata(chapter_metadata, metadata_file)

    output_mp3 = "output.mp3"
    concatenate_mp3s(mp3_files, output_mp3)

    final_output = "final_output.mp3"
    subprocess.run(["ffmpeg", "-i", output_mp3, "-i", metadata_file, "-map_metadata", "1", "-codec", "copy", final_output])

    print(f"Chapters added and final file saved as {final_output}")
