#!/bin/dash
# usage: stage.sh <default|hr|particle> [layer ...]   later layers override earlier ones
set -eu
name=$1; shift
d=$BUILD/stage/$name
rm -rf "$d"; mkdir -p "$d/materials"
for l; do cp -a "$BUILD/layers/$l/." "$d/"; done
if [ "$name" = particle ]; then
	cp -a "$PACK/particles" "$d/particles"
	if [ -f "$ROOT/particle_assets.txt" ]; then
		grep -Ev '^[[:space:]]*(#|$)' "$ROOT/particle_assets.txt" | while IFS= read -r p; do
			found=0
			for s in "$PACK/materials/$p" "$PACK/textures/vtf/$p"; do
				if [ -d "$s" ]; then mkdir -p "$d/materials/$p"; cp -a "$s/." "$d/materials/$p/"; found=1
				elif [ -f "$s" ]; then mkdir -p "$d/materials/$(dirname "$p")"; cp -a "$s" "$d/materials/$p"; found=1; fi
			done
			[ "$found" = 1 ] || echo "warn: particle asset '$p' not found" >&2
		done || true
	fi
else
	cp -a "$PACK/materials/." "$d/materials/"
	cp -a "$PACK/textures/vtf/." "$d/materials/"      # vtf -> materials/
	mkdir -p "$d/scripts"; cp -a "$PACK/scripts/." "$d/scripts/"
	cp "$PACK/info.vdf" "$d/"
fi
cp "$PACK/misc/jsons/$name/mod.json" "$d/mod.json"
echo "staged $name"
