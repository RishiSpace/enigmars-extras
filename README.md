# enigmars-extras

Pacman repo for Enigmars userspace packages. The kernel stays in
[linux-enigmarsos](https://github.com/enigmars-project/linux-enigmarsos).

Each program stays in its own git. This repo only builds Arch packages
from those checkouts and publishes a pacman database.

```ini
[enigmars-extras]
SigLevel = Optional TrustAll
Server = https://github.com/enigmars-project/enigmars-extras/releases/latest/download
```

```bash
sudo pacman -Sy enigmars-utils
```

## Add a program

1. Give the app an Arch PKGBUILD (Utils already has `packaging/arch/PKGBUILD.local`).
2. Drop a file in `packages.d/`:

   ```bash
   # packages.d/enigmars-theme.conf
   NAME=enigmars-theme
   SRC=../enigmars-theme
   GIT=https://github.com/RishiSpace/enigmars-theme.git
   PKGBUILD_DIR=packaging/arch
   PKGBUILD=PKGBUILD.local
   ```

   `SRC` is a sibling of this repo (`~/Git-Repos/...`). If that folder is
   missing, `build-all.sh` clones `GIT` into `work/`.

3. Rebuild and (optionally) upload Latest:

   ```bash
   ./scripts/build-all.sh
   ./scripts/upload-release-mirror.sh
   ```

`build-all.sh` replaces only that package's `.pkg.tar.zst` and reindexes
the whole `repo/x86_64` folder, so older extras stay in the db.

## Layout

| Path | What |
| --- | --- |
| `packages.d/*.conf` | What to build |
| `scripts/build-all.sh` | `makepkg` each source → `repo/x86_64` |
| `scripts/publish-repo.sh` | `repo-add` + real `.db` files (not symlinks) |
| `scripts/upload-release-mirror.sh` | GitHub Release assets (`gh` required) |

Do not commit `.pkg.tar.zst` files. GitHub Releases holds the binaries.
