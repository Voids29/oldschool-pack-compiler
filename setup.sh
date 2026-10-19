#!/bin/dash
# Clones/updates the pack repo (main) into src/pack and the no-hats-addon branch into src/nha.
set -eu
cd "$(dirname "$0")"
. ./config.sh
mkdir -p src
if [ -d src/pack/.git ]; then git -C src/pack pull --ff-only
else git clone "https://github.com/$PACK_SLUG.git" src/pack; fi
git -C src/pack fetch --tags origin no-hats-addon
if [ -d src/nha ]; then git -C src/nha checkout -q --detach origin/no-hats-addon
else git -C src/pack worktree add --detach ../nha origin/no-hats-addon; fi
if [ -z "${STUDIOMDL:-}" ] && [ ! -x tools/tools++_linux/studiomdl++ ]; then
	mkdir -p tools
	curl -fsSL https://github.com/ficool2/misc_tools/releases/download/v1/tools++_linux.tar.gz | tar xz -C tools
fi
echo "setup done"
