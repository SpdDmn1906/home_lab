# STARR vs TRaSH Guides — what applies here (2026-10-04)

**Question:** should the STARR stack follow [TRaSH Guides](https://trash-guides.info/) to be more efficient?
**Answer:** partly. TRaSH's **structure** guidance (folder layout, hardlinks, naming) fits and is being
adopted. Its **quality profiles** target a different setup (private trackers, quality-first, large
files) and would break this one if applied wholesale. Evidence for each is below. All of it was checked
against the live Radarr/Sonarr/qBittorrent config and TRaSH's own JSON, not from memory.

## Current state (read from the APIs)

| Area | Radarr 6.0 | Sonarr 4.0 |
|---|---|---|
| Profile in use | `1080p Movies Max 4GB`: 1,555 of 1,562 movies | `1080p with 720p Fallback Under 1GB`: 72 of 73 series |
| Size control | Global quality definitions: 1080p max **35 MB/min** (≈4.2 GB for a 2 h film) | 1080p max **50 MB/min** |
| Indexers | Prowlarr-synced (work) **plus** 4 hand-added `Torznab-*` duplicates (failing 6 h+) | same pattern, 4 duplicates incl. long-dead RARBG |
| Naming | `{Movie Title} ({Release Year})`; no ID in folder | `{Series TitleYear}`; no ID in folder |
| Hardlinks setting | on | on |

qBittorrent: automatic torrent management off, so every download lands in one local folder on the OS
disk. It stops seeding at **ratio 0.01 / 1 minute**.

## TRaSH guidance that applies

### Folder structure and hardlinks — adopt on the kids partition; design the NAS replacement around it
TRaSH's core rule: downloads and media on **one filesystem, in one mount**, so imports are hardlinks or
atomic moves, not copy + delete. Here they cannot be. Downloads sit on the OS disk, and media spans
three devices (NAS over CIFS, the NTFS partition, the ext4 kids partition). **Every import is a full
copy.**

- **What it costs today: little.** Torrents stop seeding almost immediately, so there is never a
  seeding copy alongside the library copy. The cost is copy time and disk I/O per import, not space.
- **Kids partition:** laid out the TRaSH way (`media/movies`, `media/tv`, with room for `torrents/`).
  Pointing the kids download categories there would make kids imports instant hardlinks. That needs the
  `/kids` mount on the VPN gateway container, which recreates it and every container sharing its
  network. Deferred as a separate decision.
- **The real payoff is the NAS replacement (Theme A).** Buying another SMB-only NAS keeps imports as
  copies forever. Storage the media host sees as one local filesystem, or a box that runs the stack
  itself, gets hardlinks for the whole library.

### Naming — adopt (Plex TMDb/TVDb), it also covers Jellyfin
TRaSH "Plex (TMDb)" puts the TMDb ID in the folder name: `{Movie CleanTitle} ({Release Year}) {tmdb-{TmdbId}}`.
An ID in the path makes matching deterministic. This session's Plex mismatches (*LeapFrog Letter
Factory*, *Space Jam: A New Legacy*) are exactly the failure it prevents.

**Plex vs Jellyfin:** TRaSH lists separate Jellyfin formats (`[tmdbid-…]`), and most forum answers say
the two are incompatible. Jellyfin's current parser (`PathExtensions.GetAttributeValue`, master as of
v12.1, 2026-09) accepts `[`, `(` **or `{`** as the bracket and `tmdb`/`tvdb`/`imdb` as aliases. So
the Plex-style `{tmdb-123}` / `{tvdb-123}` tags work in both. One scheme, no Jellyfin rename later.

### Media management — adopt two settings
- **Analyse video files: on.** TRaSH filenames use MediaInfo tokens (codec, audio, HDR), which are
  empty without it.
- **Free-space check: on** (Radarr had *skip free space check when importing* enabled). Not a TRaSH item,
  but it is how a volume silently reached 100% twice (2026-08-05, 2026-10-01).

### Indexers — Prowlarr owns them
The failing `Torznab-*` entries predate Prowlarr and duplicate Prowlarr-synced indexers that work.
Recent grabs all came through Prowlarr (Radarr last grab 2026-10-02, Sonarr 2026-10-01). Disable the
duplicates rather than delete them.

## TRaSH guidance that does NOT fit (as-is)

### Quality profiles and custom formats — do not apply wholesale
Checked against TRaSH's own JSON (`docs/json/radarr/cf/`):

- **`LQ` (score −10000)** blocks the release groups most of this library comes from, among them
  `YTS`, `YIFY`, `RARBG`, `GalaxyRG`, `PSA`, `MeGusta`, `Pahe` and `Tigole`. On public trackers that
  turns most searches into "no acceptable release".
- **`x265 (HD)` (score −10000)** blocks 1080p HEVC, which is exactly the encode that fits a 4 GB cap.
- **TRaSH quality definitions** (file-size limits) would replace the 35/50 MB-per-minute caps that keep
  files small. **Never sync quality definitions while the size-capped approach is wanted.**

TRaSH optimises for quality per title. This stack optimises for titles per terabyte. Neither is wrong,
but mixing them silently would empty the freed space.

### Where TRaSH profiles *would* fit — an owner decision
The household's stated priority for the Shield is **4K direct play and lossless audio**. The stack
acquires neither: the profile on 1,555 of 1,562 movies excludes 2160p, and lossless audio (TrueHD/DTS-HD) does not fit in a
4 GB 1080p encode. A TRaSH **UHD Bluray + WEB** profile, synced by Recyclarr and applied only to
hand-picked titles, would deliver that goal. Budget roughly 15–30 GB per film. Kids content stays on
the capped profile.

## Status

| Item | State |
|---|---|
| Kids ext4 partition + Radarr/Sonarr `/kids` mount | ✅ 2026-10-04 |
| Bazarr `/kids` mount (path parity with Radarr/Sonarr) | ✅ 2026-10-04 (targeted apply, Bazarr only) |
| Layout, naming, media-management, indexer changes | ✅ 2026-10-04 (`configure.py --apply`; re-run as a dry run shows nothing pending) |
| Kids library copy (1,524 files, 1,122.6 GB → 566 GB headroom left) | 🔄 running since 2026-10-04 (~40 MB/s, ~8 h); sources untouched |
| Re-point Radarr/Sonarr/Plex at the copies + TRaSH renames | ⏳ after the copy — needs go-ahead |
| Delete the NTFS originals + residue | ⏳ needs explicit go-ahead |
| Recyclarr: naming + 7 custom formats (BR-DISK, 3D, Extras, AV1 blocked; repacks preferred) | ✅ synced 2026-10-04 · daily container planned (`docker/recyclarr/`), waits on its host config dir |
| Kids downloads → `/kids/torrents` (hardlinks) | 🤔 decision — recreates the VPN gateway; small gain while torrents don't seed |
| TRaSH UHD profile via Recyclarr for chosen titles | ⏸️ deferred by owner until a 4K-capable player (Shield) is in the house |
