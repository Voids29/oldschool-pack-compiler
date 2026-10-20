#!/bin/dash
# usage: release.sh <version> [--particles] [--publish]
set -eu
usage() {
	cat <<'USAGE'
usage: release.sh <version> [options]

Builds the default, hr and particle VPKs plus the release and source zips
into build/<version>/out/.

arguments:
  <version>      Release version number, e.g. 1.4.0 (used in all file names)

options:
  --particles    Force rebuilding the particle VPK. Without this, it is only
                 rebuilt if particles/ changed since the last git tag;
                 otherwise the old one is reused from that tag's release zip.
  --publish      After building, create a DRAFT GitHub release (v<version>)
                 with the release and source zips attached (needs gh).
  -h, --help, -? Show this help and exit.
USAGE
}
ROOT=$(cd "$(dirname "$0")" && pwd)
FORCE=0 PUBLISH=0 VER=
for a; do case $a in
	-h|--help|'-?') usage; exit 0;;
	--particles) FORCE=1;; --publish) PUBLISH=1;;
	-*) echo "unknown option $a" >&2; usage >&2; exit 1;; *) VER=$a;;
esac; done
[ -n "$VER" ] || { usage >&2; exit 1; }
[ -f "$ROOT/config.sh" ] || { echo "copy config.example.sh to config.sh and edit it" >&2; exit 1; }
. "$ROOT/config.sh"
: "${PACK_SLUG:?}"
# config.sh value (name or path) > studiomdl++ on PATH > copy downloaded by setup.sh
STUDIOMDL=$(command -v "${STUDIOMDL:-studiomdl++}" || echo "${STUDIOMDL:-$ROOT/tools/tools++_linux/studiomdl++}")
[ -x "$STUDIOMDL" ] || { echo "err: studiomdl++ not found at $STUDIOMDL (put studiomdl++ on your PATH, run ./setup.sh, or set STUDIOMDL)" >&2; exit 1; }
STUDIOMDL=$(realpath "$STUDIOMDL") EXTRA_MATERIALS=${EXTRA_MATERIALS:-} STUDIOMDL_FLAGS=${STUDIOMDL_FLAGS:-}
VPKCLI=${VPKCLI:-vpkeditcli} JOBS=${JOBS:-8} ITEMS_GAME=${ITEMS_GAME:-}
PACK=$ROOT/src/pack NHA=$ROOT/src/nha BUILD=$ROOT/build/$VER LOGDIR=$ROOT/build/$VER/logs GAMEDIR=$ROOT/build/$VER/game
[ -d "$PACK" ] && [ -d "$NHA" ] || { echo "run ./setup.sh first" >&2; exit 1; }
for t in xargs zip unzip git "$VPKCLI"; do
	command -v "$t" >/dev/null || { echo "missing tool: $t" >&2; exit 1; }
done
[ "$PUBLISH" = 0 ] || command -v gh >/dev/null || { echo "missing tool: gh" >&2; exit 1; }

# particle VPK: rebuild only if forced, never released, or particles/ changed since last tag
PART=build LAST=
if [ "$FORCE" = 0 ]; then
	LAST=$(git -C "$PACK" describe --tags --abbrev=0 2>/dev/null || true)
	[ -z "$LAST" ] || ! git -C "$PACK" diff --quiet "$LAST" -- particles || PART=reuse
fi
export ROOT VER STUDIOMDL STUDIOMDL_FLAGS GAMEDIR EXTRA_MATERIALS PACK_SLUG VPKCLI JOBS ITEMS_GAME PACK NHA BUILD LOGDIR PART LAST
echo "== release $VER (particles: $PART${LAST:+, last tag $LAST})"

rm -rf "$BUILD"; mkdir -p "$BUILD/layers" "$BUILD/out" "$LOGDIR"
"$ROOT/lib/gamedir.sh"
"$ROOT/lib/compile.sh" "$PACK/models/decompiled" "$BUILD/layers/base"
"$ROOT/lib/nha.sh" "$BUILD/layers/nha"
"$ROOT/lib/stage.sh" default base
"$ROOT/lib/stage.sh" hr nha base          # later layers win: base overrides NHA
[ "$PART" = build ] && "$ROOT/lib/stage.sh" particle
"$ROOT/lib/pack.sh"

if [ "$PUBLISH" = 1 ]; then
	gh release create "v$VER" -R "$PACK_SLUG" --draft --title "v$VER" \
		--target "$(git -C "$PACK" rev-parse HEAD)" \
		"$BUILD/out/oldschool_fortress_v$VER.zip" "$BUILD/out/oldschool_fortress_v${VER}_source.zip"
fi
echo "== done: $BUILD/out"
