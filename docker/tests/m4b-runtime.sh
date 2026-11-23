#!/bin/sh
# Exercise the complete runtime as the app user without network or library access.
set -eu
export TMPDIR=/tmp
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir "$work/input"
for tool in php ffmpeg ffprobe mp4info mp4chaps mp4tags m4b-tool; do
    command -v "$tool"
done
ffmpeg -v error -f lavfi -i sine=frequency=440:duration=2 -c:a libmp3lame "$work/input/01.mp3"
ffmpeg -v error -f lavfi -i sine=frequency=880:duration=2 -c:a libmp3lame "$work/input/02.mp3"
m4b-tool merge "$work/input" -n --audio-codec=aac --audio-bitrate=64k \
    --skip-cover --use-filenames-as-chapters --no-chapter-reindexing \
    --output-file="$work/result.m4b"
ffprobe -v error -show_entries stream=codec_name -of csv=p=0 "$work/result.m4b" | grep -q '^aac$'
duration=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$work/result.m4b")
awk -v duration="$duration" 'BEGIN {exit !(duration >= 3.8 && duration <= 4.5)}'
chapters=$(ffprobe -v error -show_entries chapter=id -of csv=p=0 "$work/result.m4b" | wc -l)
test "$chapters" -eq 2
printf 'M4B runtime passed: AAC, %ss, %s chapters\n' "$duration" "$chapters"
