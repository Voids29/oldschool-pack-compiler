#!/bin/dash
# usage: nha.sh <out root>   runs the no-hats-addon pipeline (genqc -> compile -> nhcustom2)
set -eu
out=$1 f=$NHA/nhm_factory c=$NHA/nhcustom2 raw=$BUILD/layers/nha_raw
[ -d "$f" ] && [ -d "$c" ] || { echo "err: nhm_factory/nhcustom2 missing in $NHA" >&2; exit 1; }
[ -z "${ITEMS_GAME:-}" ] || cp "$ITEMS_GAME" "$f/items_game.txt"
[ -f "$f/items_game.txt" ] || { echo "err: need $f/items_game.txt (or set ITEMS_GAME)" >&2; exit 1; }
(cd "$f" && ./genqc.sh "$f")
"$ROOT/lib/compile.sh" "$f/out_nhu2/uncompiled" "$raw"
cp -a "$f/out_nhu2/0kb_files/." "$raw/"
rm -rf "$c/input"/* "$c/output"/*
cp -a "$raw/." "$c/input/"
# nhcustom2 aborts with "couldn't load the database" without database.csv next to it
db=$c/database.csv
if curl -fsSL -o "$db.new" "${NHDB_URL:-https://pevhs.ch/tf2/nhcustom2/database.csv}"; then mv "$db.new" "$db"
else rm -f "$db.new"; echo "warn: couldn't download database.csv, using existing copy if any" >&2; fi
if [ ! -s "$db" ] || head -c 300 "$db" | grep -qi '<html'; then
	echo "err: $db missing or invalid; download it manually or generate it with NHSchema" >&2; exit 1
fi
(cd "$c" && ./nhcustom2.sh)
mkdir -p "$out"; cp -a "$c/output/." "$out/"
