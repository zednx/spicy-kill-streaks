#!/usr/bin/env bash
# Makes the quieter copies of the voice packs that friends' kills and deaths play:
# every sound under SpicyKillStreaks/sounds (but custom/ and quiet/ itself) at 75% volume, as
# Ogg Vorbis mono 22050 Hz, in SpicyKillStreaks/sounds/quiet/ with the same folders and names
# (an .mp3 becomes .ogg). Run it again after adding or changing a sound. Needs ffmpeg.
set -euo pipefail
cd "$(dirname "$0")/../SpicyKillStreaks/sounds"
VOLUME="${VOLUME:-0.75}"
rm -rf quiet
find . \( -path ./quiet -o -path ./custom \) -prune -o -type f \( -name '*.ogg' -o -name '*.mp3' \) -print | sort |
while read -r f; do
	out="quiet/${f#./}"
	out="${out%.*}.ogg"
	mkdir -p "$(dirname "$out")"
	ffmpeg -nostdin -hide_banner -loglevel error -y -i "$f" -map_metadata -1 -af "volume=$VOLUME" \
		-ac 1 -ar 22050 -c:a libvorbis -q:a 3 "$out"
done
echo "Made $(find quiet -name '*.ogg' | wc -l) quiet copies at ${VOLUME} volume."
