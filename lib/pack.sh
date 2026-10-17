#!/bin/dash
# Packs staged trees into VPKs and builds the release + source zips.
set -eu
o=$BUILD/out s=$BUILD/stage
pk() { "$VPKCLI" -s "$s/$1"; mv "$s/$1.vpk" "$o/$2.vpk"; }
pk default "oldschool_fortress_v$VER"
pk hr "oldschool_fortress_hr_v$VER"
pn=oldschool_fortress_particles_v$VER
if [ "$PART" = build ]; then pk particle "$pn"
else
	t=$BUILD/prev; mkdir -p "$t"
	gh release download "$LAST" -R "$PACK_SLUG" -p '*.zip' -D "$t"
	for z in "$t"/*.zip; do
		case $z in *_source.zip) ;; *) unzip -qjo "$z" '*particles*.vpk' -d "$t/vpk" || true;; esac
	done
	set -- "$t"/vpk/*particles*.vpk
	[ -f "$1" ] || { echo "err: no old particle vpk found; rerun with --particles" >&2; exit 1; }
	cp "$1" "$o/$pn.vpk"
fi
cp "$PACK/misc/readme.txt" "$o/readme.txt"
(cd "$o" && zip -q "oldschool_fortress_v$VER.zip" ./*.vpk readme.txt && rm readme.txt)
(cd "$s" && zip -qr "$o/oldschool_fortress_v${VER}_source.zip" default)
ls -1 "$o"
