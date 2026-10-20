#!/bin/dash
# usage: compile.sh <qc dir> <out root>   -> <out root>/models
# studiomdl++ writes into $GAMEDIR/models (a private build dir, never a real game install).
set -eu
src=$1 out=$2
: "${STUDIOMDL:?}" "${GAMEDIR:?}" "${LOGDIR:?}"
[ -x "$STUDIOMDL" ] || { echo "err: studiomdl++ not executable at $STUDIOMDL" >&2; exit 1; }
[ -f "$GAMEDIR/gameinfo.txt" ] || { echo "err: $GAMEDIR not set up (lib/gamedir.sh)" >&2; exit 1; }
[ -d "$src" ] || { echo "err: qc dir '$src' not found" >&2; exit 1; }
rm -rf "$GAMEDIR/models"
# Crowbar QCs use Windows backslashes in $modelname; studiomdl++ on Linux then writes
# output to wrong paths ("md: not found"). Compile from a private copy with forward
# slashes in that line (hardlinked, so cheap; sed -i breaks the link, originals stay intact).
work=${BUILD:?}/qc/$(basename "$out")
rm -rf "$work"; mkdir -p "$(dirname "$work")"
cp -al "$src" "$work" 2>/dev/null || cp -a "$src" "$work"
find "$work" \( -name '*.qc' -o -name '*.qci' \) -exec sed -i '/^[[:space:]]*\$modelname/ s#\\#/#g' {} +
TAG=$(basename "$out"); export TAG LOGDIR GAMEDIR STUDIOMDL
# The QCs were made on Windows, where file names are case-insensitive. On Linux a QC that
# says "Foo.smd" for a file named "foo.smd" fails, so add symlinks (in the private copy
# only) for any referenced file whose case differs. Fixes are listed in $TAG.casefix.
: >"$LOGDIR/$TAG.casefix"
find "$work" -name '*.qc' | while IFS= read -r q; do
	d=$(dirname "$q")
	grep -oiE '"[^"]+\.(smd|dmx|qci)"' "$q" | tr -d '"\r' | tr '\\' '/' | while IFS= read -r ref; do
		[ -e "$d/$ref" ] && continue
		real=$(find "$d/$(dirname "$ref")" -maxdepth 1 -iname "$(basename "$ref")" -print -quit 2>/dev/null || true)
		if [ -n "$real" ]; then ln -sf "$real" "$d/$ref" && echo "$q: $ref -> $(basename "$real")" >>"$LOGDIR/$TAG.casefix"; fi
	done || true
done
[ ! -s "$LOGDIR/$TAG.casefix" ] || echo "note: fixed $(wc -l <"$LOGDIR/$TAG.casefix") file-name case mismatches (see $LOGDIR/$TAG.casefix)"
: >"$LOGDIR/$TAG.failed"
echo "compiling $(find "$work" -name '*.qc' | wc -l) models -> $TAG"
find "$work" -name '*.qc' -print0 | xargs -r -0 -n1 -P"${JOBS:-8}" "$ROOT/lib/studiomdl.sh"
if [ -s "$LOGDIR/$TAG.failed" ]; then
	echo "err: $(wc -l <"$LOGDIR/$TAG.failed") models failed, see $LOGDIR/$TAG.failed" >&2; exit 1
fi
[ -d "$GAMEDIR/models" ] || { echo "err: studiomdl++ produced no models dir" >&2; exit 1; }
rm -rf "$out"; mkdir -p "$out"; mv "$GAMEDIR/models" "$out/models"
