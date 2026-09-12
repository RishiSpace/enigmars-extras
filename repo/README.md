# enigmars-extras pacman repository

Built packages live in `x86_64/` after `./scripts/build-all.sh`. That
directory is gitignored; GitHub Releases is the public mirror.

Pacman only GETs:

- `enigmars-extras.db` (regular file, not a symlink)
- then the `.pkg.tar.zst` files named in that database

```text
https://github.com/RishiSpace/enigmars-extras/releases/latest/download/<filename>
```
