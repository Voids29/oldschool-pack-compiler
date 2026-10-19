#!/bin/dash
# Builds a minimal, self-contained game dir for studiomdl++ so no TF2 install is needed.
# Contents: a stub gameinfo.txt + the pack's own materials (+ optional EXTRA_MATERIALS).
set -eu
g=$GAMEDIR
rm -rf "$g"; mkdir -p "$g/materials"
cat >"$g/gameinfo.txt" <<'GI'
"GameInfo"
{
	game "oldschool build"
	FileSystem
	{
		SearchPaths
		{
			game+game+mod+mod_write+default_write_path	|gameinfo_path|.
		}
	}
}
GI
# later entries override earlier ones; hardlink when possible (cheap), else copy
for m in ${EXTRA_MATERIALS:+"$EXTRA_MATERIALS"} "$PACK/materials" "$PACK/textures/vtf"; do
	if [ -d "$m" ]; then cp -alf "$m/." "$g/materials/" 2>/dev/null || cp -af "$m/." "$g/materials/"; fi
done
