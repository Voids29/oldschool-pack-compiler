#!/bin/dash
# usage: compile.sh <qc dir> <out root>   -> <out root>/models
# studiomdl always writes to $WINTF2DIR/tf/models, so any existing loose copy is
# moved aside first and restored on exit (even on failure).
set -eu
src=$1 out=$2
: "${WINTF2DIR:?}" "${LOGDIR:?}"
M=$WINTF2DIR/tf/models BAK=$WINTF2DIR/tf/models.oldschool_bak
[ -f "$WINTF2DIR/bin/studiomdl.exe" ] || { echo "err: no studiomdl.exe in $WINTF2DIR/bin" >&2; exit 1; }
[ -d "$src" ] || { echo "err: qc dir '$src' not found" >&2; exit 1; }
[ ! -e "$BAK" ] || { echo "err: $BAK exists (crashed run?); restore it manually" >&2; exit 1; }
restore() { rm -rf "$M"; if [ -e "$BAK" ]; then mv "$BAK" "$M"; fi; return 0; }
if [ -e "$M" ]; then mv "$M" "$BAK"; fi
trap restore EXIT
TAG=$(basename "$out"); export TAG LOGDIR WINTF2DIR
: >"$LOGDIR/$TAG.failed"
echo "compiling $(find "$src" -name '*.qc' | wc -l) models -> $TAG"
find "$src" -name '*.qc' -print0 | xargs -0 -n1 -P"${JOBS:-8}" "$ROOT/lib/studiomdl.sh"
if [ -s "$LOGDIR/$TAG.failed" ]; then
	echo "err: $(wc -l <"$LOGDIR/$TAG.failed") models failed, see $LOGDIR/$TAG.failed" >&2; exit 1
fi
[ -d "$M" ] || { echo "err: studiomdl produced no models dir" >&2; exit 1; }
rm -rf "$out"; mkdir -p "$out"; mv "$M" "$out/models"
