# Oldschool Fortress Release Compiler

Automates building a release of the [Oldschool Fortress pack fix](https://github.com/Voids29/oldschool-pack-fix) for TF2.
One command compiles the models, stages the files, packs the VPKs and builds the release zips.

```
./release.sh <version> [options]
```

This is the `oldschool-compiler` fork of [TF2-QC-Compiler](https://github.com/Voids29/TF2-QC-Compiler). It replaces the `genall.sh` / `.compile.sh` scripts.

## What it produces

All output lands in `build/<version>/out/`:

| File | Contents |
|---|---|
| `oldschool_fortress_v<ver>.vpk` | Default pack |
| `oldschool_fortress_hr_v<ver>.vpk` | Hat removal (HR) pack |
| `oldschool_fortress_particles_v<ver>.vpk` | Particles |
| `oldschool_fortress_v<ver>.zip` | The three VPKs + `readme.txt` (the release download) |
| `oldschool_fortress_v<ver>_source.zip` | The unpacked default pack, for easy editing |

Compiled models are never committed to a repo. They only exist in `build/` and in releases.

## Requirements

- Linux (or WSL)
- A TF2 install containing `bin/studiomdl.exe`
- `wine`
- `git` and `git-lfs`
- `zip`, `unzip`, `curl`
- [VPKEdit](https://github.com/craftablescience/VPKEdit) CLI (`vpkeditcli`) on your `PATH`
- [GitHub CLI](https://cli.github.com/) (`gh`), only needed for `--publish` and for reusing an old particle VPK

## Setup

```sh
git clone git@github.com:Voids29/oldschool-pack-compiler.git
cd oldschol-pack-compiler
cp config.example.sh config.sh     # then edit it
./setup.sh
```

`setup.sh` clones the pack repo (`main`) into `src/pack` and checks out the `no-hats-addon` branch as a worktree in `src/nha`. Run it again any time to pull the latest changes.

### config.sh

| Variable | Meaning |
|---|---|
| `WINTF2DIR` | Path to your TF2 install (the folder containing `bin/` and `tf/`) |
| `PACK_SLUG` | GitHub repo holding the pack and its releases |
| `VPKCLI` | VPKEdit CLI command name |
| `JOBS` | Number of parallel studiomdl jobs |
| `ITEMS_GAME` | Optional path to `items_game.txt`, copied into `nhm_factory/` (it is required there and isn't in the repo) |
| `NHDB_URL` | Optional override for the `nhcustom2` database download URL |

## Usage

```
./release.sh <version> [options]

  --particles    Force rebuilding the particle VPK
  --publish      Create a DRAFT GitHub release (v<version>) with the zips attached
  -h, --help, -? Show help
```

By default the particle VPK is only rebuilt if `particles/` changed since the last git tag. Otherwise the old one is pulled from that tag's release zip with `gh` and renamed to the new version. If no old VPK can be found, rerun with `--particles`.

Extra materials the particle VPK needs go in `particle_assets.txt`, one path per line, relative to `materials/`.

`--publish` tags the release at the pack repo's `HEAD`, so push the pack repo first. GameBanana has no upload API, so that upload stays manual.

## How it works

1. **Compile base models.** Every `.qc` under `src/pack/models/decompiled` is compiled with `studiomdl` (in parallel) into the `base` layer.
2. **Build the no-hats addon.** Runs the `no-hats-addon` pipeline (`genqc.sh`, compile, `nhcustom2`) into the `nha` layer. `nhcustom2` needs a `database.csv`, which is downloaded automatically.
3. **Stage.** Each pack is assembled from layers, where later layers override earlier ones:
   - `default` = `base` + shared assets
   - `hr` = `nha`, then `base` on top, + shared assets
   - `particle` = `particles/` + the assets in `particle_assets.txt`

   Shared assets are `materials/`, `textures/vtf/` (merged into `materials/`), `scripts/`, `info.vdf`, and `misc/jsons/<pack>/mod.json` for each pack.
4. **Pack.** Each staged folder is packed with `vpkeditcli -s`, then the zips are built.

### Layout

```
release.sh          entry point
setup.sh            clones/updates src/pack and src/nha
config.example.sh   copy to config.sh
particle_assets.txt extra materials for the particle VPK
lib/compile.sh      qc dir -> compiled models (via studiomdl)
lib/studiomdl.sh    compiles one QC (called by compile.sh)
lib/nha.sh          no-hats-addon pipeline
lib/stage.sh        builds default / hr / particle trees
lib/pack.sh         VPKs + zips
src/                (generated) pack repo + NHA worktree
build/<version>/    (generated) layers, staged trees, logs, out/
```

## Notes and troubleshooting

- **Your `tf/models` folder is protected.** `studiomdl` always writes to `<TF2>/tf/models`, so any existing loose copy is moved to `tf/models.oldschool_bak` for the build and restored on exit, even on failure. If a run crashes hard and that backup is left behind, the next run refuses to start until you restore it manually.
- **Failed models fail the release.** Compile logs and the list of failed QCs are in `build/<version>/logs/`.
- **`couldn't load the database`** comes from `nhcustom2` and means `src/nha/nhcustom2/database.csv` is missing or invalid. The script tries to download it. If that fails, download it manually from `https://pevhs.ch/tf2/nhcustom2/database.csv` or generate one with NHSchema.
- **`items_game.txt` missing.** Put it in `src/nha/nhm_factory/` or set `ITEMS_GAME` in `config.sh`.
- The `--particles` reuse relies on git tags and GitHub releases in the pack repo, so tag each release as `v<version>`.

## License
 
Released into the public domain under [The Unlicense](LICENSE), the same license used by Fedora31's [no-hats-bgum](https://github.com/Fedora31/no-hats-bgum) tooling that these scripts are based on.
 
Note that this applies to the scripts in this repository only. The pack itself ([oldschool-pack-fix](https://github.com/Voids29/oldschool-pack-fix)) has its own license.
