# Kids library migration — NTFS partition → ext4 kids partition

Moves the kids movie and TV libraries off the full NTFS data partition (`/external/media`) onto the
dedicated ext4 partition (`/external/kids`), into the TRaSH folder layout, with TRaSH naming applied
afterwards by Radarr/Sonarr. Run on the media host as the normal user. Python 3.6+, stdlib only.

**Every script is a dry run unless given `--apply`.** None of them deletes a source file.

| Step | What | How long | Reversible |
|---|---|---|---|
| 1 | `configure.py` — TRaSH layout (`media/movies`, `media/tv`), root folders, TRaSH naming, Radarr *analyse video files* on + free-space guard on, legacy Torznab indexers disabled, Plex kids libraries pointed at the new paths | seconds | yes — every value it changes is printed in the dry run |
| 2 | `migrate_copy.py` — SHA-256-verified copy of every kids video + sidecar (executables excluded), resumable via `~/kids-migration/manifest.jsonl` | hours (~1.1 TB, same physical disk) | yes — sources untouched |
| 3 | Re-point Radarr/Sonarr to the copies (editor, *move files: no*), rescan, add the unmanaged titles, then TRaSH folder + file rename (editor same root *move files: yes*, then Rename) — same filesystem, so instant. Pilot one movie and one series first. | minutes | yes, until step 4 |
| 4 | Plex: confirm every item has a part under `/external/kids`, remove the old NTFS location from the library **before** deleting files, refresh, empty trash. Then delete the verified sources and drop the old root folders. | minutes | **no** — needs the owner's explicit go-ahead |

```bash
cd ~/kids-migration/tool
python3 configure.py            # preview
python3 configure.py --apply
python3 migrate_copy.py         # preview: plan, residue list, space check
nohup setsid python3 migrate_copy.py --apply > ~/kids-migration/copy.log 2>&1 &
tail -f ~/kids-migration/copy.log
```

Not copied, left in place for an owner decision: release-group executables
(`RARBG_DO_NOT_MIRROR.exe`), unmanaged TV folders with no video in them (orphan subtitles/nfo/txt/png
from old torrents), and one folder verified byte-identical to a folder that is copied.

`trash/*.json` are TRaSH-Guides' own naming definitions (the files Recyclarr syncs from), vendored so
the scripts don't depend on GitHub at run time.
