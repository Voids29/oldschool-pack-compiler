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
TAG=$(basename "$out"); export TAG LOGDIR GAMEDIR STUDIOMDL
: >"$LOGDIR/$TAG.failed"
echo "compiling $(find "$src" -name '*.qc' | wc -l) models -> $TAG"
find "$src" -name '*.qc' -print0 | xargs -r -0 -n1 -P"${JOBS:-8}" "$ROOT/lib/studiomdl.sh"
if [ -s "$LOGDIR/$TAG.failed" ]; then
	echo "err: $(wc -l <"$LOGDIR/$TAG.failed") models failed, see $LOGDIR/$TAG.failed" >&2; exit 1
fi
[ -d "$GAMEDIR/models" ] || { echo "err: studiomdl++ produced no models dir" >&2; exit 1; }
rm -rf "$out"; mkdir -p "$out"; mv "$GAMEDIR/models" "$out/models"
