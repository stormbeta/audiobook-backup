#!/usr/bin/env python3
"""
Sound Booth Theater — extract & combine downloaded audio with chapter markers.

Requirements:
  ffmpeg + ffprobe  (for combining, chapters, and art embedding)

Usage:
  python3 sbt_extract.py [--output DIR]

  --output  Where to write the combined file (default: ~/Music)
"""

import argparse
import glob
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

APP_DATA = Path("/home/jason/projects/com.mobile.soundbooththeater")
DB_PATH  = APP_DATA / "files" / "powersync-dart.db"
SBT_PATH = APP_DATA / "app_flutter" / "sbt"


def find_downloaded_groups():
    """Return {group_id: [Path, ...]} for every group with MP3s on disk."""
    groups = {}
    for mp3 in SBT_PATH.rglob("*.mp3"):
        parts = mp3.relative_to(SBT_PATH).parts
        # parts: <account>/<profile>/group_<id>/<item_id>/<resource_id>.mp3
        if len(parts) >= 4 and parts[2].startswith("group_"):
            gid = parts[2][len("group_"):]
            groups.setdefault(gid, []).append(mp3)
    return groups


def episode_num(slug: str) -> int:
    m = re.match(r"episode-(\d+)-", slug or "")
    return int(m.group(1)) if m else 9999


def cover_url(display_options_json: str) -> str | None:
    try:
        opts = json.loads(display_options_json or "{}")
        for key in ("imageSquare", "image"):
            att = opts.get(key, {}).get("attachment", {})
            for k in ("url1024Jpg", "originalUrl", "url"):
                if att.get(k):
                    return att[k]
    except Exception:
        pass
    return None


def require_ffmpeg():
    if shutil.which("ffmpeg") is None:
        sys.exit(
            "ffmpeg not found.\n"
            "  Arch:   sudo pacman -S ffmpeg\n"
            "  Debian: sudo apt install ffmpeg\n"
            "Files were extracted with proper names — re-run after installing ffmpeg."
        )


def get_duration_ms(path: Path) -> int:
    result = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", str(path)],
        capture_output=True, text=True, check=True,
    )
    return int(float(result.stdout.strip()) * 1000)


def encode_segment(src: Path, dest: Path):
    subprocess.run(
        ["ffmpeg", "-y", "-i", str(src), "-c:a", "aac", "-b:a", "256k", str(dest)],
        check=True, capture_output=True, stdin=subprocess.DEVNULL,
    )


def write_ffmetadata(path: Path, chapters: list[tuple[str, int, int]], album: str):
    """Write an ffmetadata file with titled ID3v2 CHAP entries."""
    lines = [
        ";FFMETADATA1\n",
        f"album={album}\n",
        "artist=Sound Booth Theater\n",
        "\n",
    ]
    for title, start_ms, end_ms in chapters:
        lines += [
            "[CHAPTER]\n",
            "TIMEBASE=1/1000\n",
            f"START={start_ms}\n",
            f"END={end_ms}\n",
            f"title={title}\n",
            "\n",
        ]
    path.write_text("".join(lines), encoding="utf-8")


def run(*args):
    subprocess.run(args, check=True, stdin=subprocess.DEVNULL)


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--output", type=Path, default=Path.home() / "Music",
        help="Output directory (default: ~/Music)",
    )
    args = parser.parse_args()

    if not DB_PATH.exists():
        sys.exit(f"Database not found: {DB_PATH}")

    db = sqlite3.connect(str(DB_PATH))
    db.row_factory = sqlite3.Row

    # ── Discover downloaded groups ────────────────────────────────────────────
    print("Scanning for downloaded content...")
    group_files = find_downloaded_groups()
    if not group_files:
        sys.exit("No downloaded MP3s found.")

    ids = list(group_files.keys())
    rows = db.execute(
        f"""
        SELECT g.id, g.name, s.name AS series_name, g.displayOptions
        FROM groups g JOIN series s ON s.id = g.seriesId
        WHERE g.id IN ({','.join('?' * len(ids))})
        ORDER BY s.name, g.name
        """,
        ids,
    ).fetchall()

    # ── Group selection ───────────────────────────────────────────────────────
    print("\nAvailable groups:")
    for i, g in enumerate(rows):
        count = len(group_files[g["id"]])
        print(f"  {i+1:2d}.  {g['series_name']} — {g['name']}  ({count} files)")

    try:
        selected = rows[int(input("\nSelect group (number): ").strip()) - 1]
    except (ValueError, IndexError):
        sys.exit("Invalid selection.")

    group_id    = selected["id"]
    series_name = selected["series_name"]
    group_name  = selected["name"]
    safe_name   = re.sub(r'[<>:"/\\|?*]', "_", f"{series_name} - {group_name}")

    print(f"\nExtracting: {series_name} — {group_name}")

    # ── Prepare output directory ──────────────────────────────────────────────
    args.output.mkdir(parents=True, exist_ok=True)
    work_dir = args.output / safe_name
    work_dir.mkdir(exist_ok=True)

    # ── Cover art ─────────────────────────────────────────────────────────────
    art_url = cover_url(selected["displayOptions"])
    cover   = None
    if art_url:
        cover = work_dir / "cover.jpg"
        print("Downloading cover art...")
        try:
            urllib.request.urlretrieve(art_url, cover)
        except Exception as e:
            print(f"  Warning — could not download cover art: {e}")
            cover = None

    # ── Fetch ordered resources from DB ──────────────────────────────────────
    resources = db.execute(
        """
        SELECT ir.id, ir.number, ir.name AS chapter,
               i.name AS item_name, i.id AS item_id, i.slug, i.releaseAt
        FROM item_resources ir
        JOIN items i ON ir.itemId = i.id
        WHERE i.groupId = ?
        """,
        (group_id,),
    ).fetchall()

    if not resources:
        sys.exit("No resources found in the database for this group.")

    # Sort by release date first, then slug episode number as tie-breaker (for
    # series where multiple items share the same release timestamp), then chapter.
    resources = sorted(resources, key=lambda r: (r["releaseAt"] or "", episode_num(r["slug"]), r["number"]))

    # ── Copy files with proper names ──────────────────────────────────────────
    print(f"Preparing {len(resources)} files...")
    ordered = []   # list of (src_path, dest_path, chapter_title)
    missing = []

    for r in resources:
        pattern = str(SBT_PATH / "*" / "*" / f"group_{group_id}" / r["item_id"] / f"{r['id']}.mp3")
        matches = glob.glob(pattern)
        if not matches:
            missing.append(f"{r['item_name']} — {r['chapter']}")
            continue
        src   = Path(matches[0])
        ep    = episode_num(r["slug"])
        fname = f"{ep:02d}-{r['number']:02d} {r['item_name']} — {r['chapter']}.mp3"
        dest  = work_dir / fname
        shutil.copy2(src, dest)
        ordered.append((src, dest, f"{r['item_name']} — {r['chapter']}"))

    if missing:
        print(f"  Warning: {len(missing)} file(s) not on disk (skipped):")
        for m in missing[:5]:
            print(f"    {m}")
        if len(missing) > 5:
            print(f"    … and {len(missing) - 5} more")

    if not ordered:
        sys.exit("No files to combine.")

    print(f"  {len(ordered)} files ready.")

    require_ffmpeg()

    # ── Build chapter timestamps from source durations ────────────────────────
    print("Measuring chapter durations...")
    chapters  = []
    cursor_ms = 0
    for src, dest, title in ordered:
        duration_ms = get_duration_ms(src)
        chapters.append((title, cursor_ms, cursor_ms + duration_ms))
        cursor_ms += duration_ms

    # ── Parallel AAC encode ───────────────────────────────────────────────────
    n_workers = os.cpu_count() or 4
    enc_dir   = work_dir / "_enc"
    enc_dir.mkdir(exist_ok=True)
    enc_paths = [enc_dir / f"{i:04d}.m4a" for i in range(len(ordered))]

    print(f"Encoding {len(ordered)} segments (×{n_workers} parallel)...")
    with ThreadPoolExecutor(max_workers=n_workers) as pool:
        future_to_idx = {
            pool.submit(encode_segment, src, enc_paths[i]): i
            for i, (src, _, _) in enumerate(ordered)
        }
        done = 0
        for future in as_completed(future_to_idx):
            future.result()  # re-raises any ffmpeg error
            done += 1
            print(f"  {done}/{len(ordered)}", end="\r", flush=True)
    print()

    # ── Write ffmetadata ──────────────────────────────────────────────────────
    metadata_file = work_dir / "_metadata.ffmeta"
    write_ffmetadata(metadata_file, chapters, album=f"{series_name} — {group_name}")

    # ── Concat encoded segments (copy, no re-encode) + apply chapters ─────────
    # enc_paths are 0000.m4a … NNNN.m4a — no special characters, no quoting needed.
    concat_list = work_dir / "_concat_list.txt"
    concat_list.write_text(
        "\n".join(f"file '{p}'" for p in enc_paths) + "\n",
        encoding="utf-8",
    )

    output_file = args.output / f"{safe_name}.m4a"
    print(f"Combining → {output_file}")
    run(
        "ffmpeg", "-y",
        "-f", "concat", "-safe", "0", "-i", str(concat_list),
        "-i", str(metadata_file),
        "-map_metadata", "1", "-map_chapters", "1", "-map", "0:a",
        "-c:a", "copy",
        str(output_file),
    )

    # ── Embed cover art via mutagen (ffmpeg's ipod muxer rejects image streams) ──
    if cover and cover.exists():
        try:
            from mutagen.mp4 import MP4, MP4Cover
            fmt = MP4Cover.FORMAT_JPEG if cover.suffix.lower() in (".jpg", ".jpeg") else MP4Cover.FORMAT_PNG
            tags = MP4(str(output_file))
            tags["covr"] = [MP4Cover(cover.read_bytes(), imageformat=fmt)]
            tags.save()
            print("  Cover art embedded.")
        except ImportError:
            print("  Cover art skipped — install mutagen to embed it: pip install mutagen")

    # ── Cleanup ───────────────────────────────────────────────────────────────
    shutil.rmtree(enc_dir)
    concat_list.unlink()
    metadata_file.unlink()

    print(f"\nDone!")
    print(f"  Combined file:    {output_file}")
    print(f"  Individual files: {work_dir}/")
    print(f"  Chapters: {len(chapters)}")


if __name__ == "__main__":
    main()
