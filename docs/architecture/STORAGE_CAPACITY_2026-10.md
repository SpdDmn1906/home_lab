# Storage Capacity Analysis — 2026-10-01

**Trigger:** NAS reported 100% full (again).
**Method:** per-directory `du` over CIFS from the media host, then locally on the NAS once SSH was enabled; file-type breakdown by bytes; cross-volume title comparison for duplication.
**Scope of this doc:** public, sanitized. Household and business specifics are in `docs/private/` (gitignored).

---

## Result (2026-10-01)

**~296 GB reclaimed** (recycle bin 22.6 GB + render caches 106 GB + verified duplicate archives 167.4 GB). NAS: 1.4 GB free → **284 GB free**. The external drive is **still at 100%** — untouched by this pass.

## Headline

**Two volumes were at 100%, not one — and the cause is capacity, not waste.**

| Volume | Type | Capacity | Free (before) |
|---|---|---:|---:|
| NAS share (DS213j) | CIFS | 5.4 TB | **1.4 GB** |
| External drive on the media host | local NTFS (`fuseblk`) | 2.2 TB | **1.5 GB** |
| Media host root | ext4 | 228 GB | 128 GB |

**≈ 7.5 TB used of 7.6 TB** (by `df`; an earlier draft said 7.3 TB from summing `du` categories). Everything on both drives is content placed there deliberately. Reclaimable hygiene (recycle bin, Docker, a stray path) totalled **under 1%** of usage.

## Where the space is

| Category | NAS | External | Total |
|---|---:|---:|---:|
| Movies (adult) | 2.0 TB | 413 GB | **~2.4 TB** |
| TV (adult) | 1.0 TB | 248 GB | **~1.25 TB** |
| Kids media (movies + TV) | 296 GB | 1.04 TB | **~1.34 TB** |
| Household / business archive share | 1.8 TB | — | **1.8 TB** |
| Unclassified share on the external drive | — | 446 GB | 446 GB |
| Other share | 32 GB | — | 32 GB |
| Download staging | — | ~29 GB | ~29 GB |

**The archive share is the single largest non-media consumer — about a third of the NAS — and it is not media.** It competes with the Plex library for the same volume, which is why pruning media alone never keeps the NAS below full.

## What was ruled out

- **Movie-library duplication — none.** Movie titles on the external drive vs the NAS: **0 overlap** (189 vs 909). Split libraries, not copies. *(TV and Kids folders not cross-checked.)*
- ⚠️ **Correction (audit, 2026-10-01): cross-volume duplication *does* exist elsewhere.** The external drive holds a second copy of the archive share's video-editor libraries, with their source footage. An earlier draft of this doc said "no cross-volume duplication" on the strength of the Movies check alone.
- **Runaway download staging — no.** ~29 GB total.
- **Photoshop scratch / temp files — no.** Under 6 GB of PSDs and no scratch-file signatures.

## Findings and fixes

### 1. Recycle Bin + a 60-second probe = 230,000 files *(fixed: bin cleared; probe fix pending)*
The CIFS mount-health check runs **every 60 s**, touches a write-probe file on both NAS mounts, then deletes it. With Recycle Bin enabled on the share, every delete is retained: **2 files/min × 1,440 min ≈ 2,880 files/day**, ~230K after ~80 days. Zero bytes each, but they made every NAS scan crawl (enumerating the bin alone exceeded 30 minutes).

- **Cleared 2026-10-01:** 22.6 GB of real deleted content (bulk from a misconfigured path, see #2) plus the probe swamp. Free space 1.4 GB → 24 GB.
- **Pending:** change the probe to overwrite one fixed-name file instead of create+delete — still proves writability, generates no deletions.
- ⚠️ The check script and its systemd units are **hand-installed on the host, not in this repo**. It is also the "CIFS mount lost" alert that the Phase 4 roadmap still lists as unbuilt. It should be brought under version control.

### 2. Radarr's recycle-bin path is joined twice *(root cause verified; fix pending)*
Radarr's Media Management → Recycling Bin is set to `/data/synology/Media/trash`. Inside the container `/data` **is already** the NAS `Media` share, so upgraded-away files land at `Media/synology/Media/trash`. Radarr deletes them after 7 days — over SMB — and the share's Recycle Bin then keeps them **indefinitely**. Every movie upgrade is held twice. Observed live: a 10 GB replaced file written there during this audit; ~18 GB of earlier ones in the share Recycle Bin.

- **Fix:** set Radarr's recycle bin to empty (permanent delete), or to a correctly-rooted path with short retention. Sonarr's is already empty.
- *(An earlier draft attributed this to "the STARR chain" unverified; a mid-audit revision blamed the media-integrity scripts. Both are superseded by the setting read from Radarr's API.)*

### 3. Hardlinks are structurally impossible
The download client is mounted into three different devices (NAS via CIFS, the external NTFS drive, and the root ext4 volume). Hardlinks cannot cross device boundaries, and CIFS barely supports them within one. **Any import that crosses devices is a full copy**, so seeding + library = two copies. Not the cause today (staging is small), but it makes space disappear faster than it should as content grows.

### 4. The NAS itself is the bottleneck
DS213j: ARM, capped at DSM 7.0.1, cannot run Docker. Enumerating ~23 GB of small files took longer than a full scan of the 2.1 TB external drive. It slows every Plex scan and every monitoring probe that touches it.

## Reclaimable without deleting wanted content

| Item | Size | Status |
|---|---:|---|
| Recycle Bin | 22.6 GB | ✅ cleared 2026-10-01 |
| Video-editor **render/analysis caches** (archive share) | **106 GB** | ✅ deleted 2026-10-01 — only after confirming 65/67 source clips exist on the external drive (the other 2: an iCloud placeholder and one PNG) |
| Video-editor **proxy media** | 3.5 GB | ❌ **held** — 10 of 14 proxies have no original on either volume; for those, the proxy *is* the footage |
| Docker images | 2.1 GB | ⏳ |
| Duplicate archives in the archive share | **167.4 GB** | ✅ deleted 2026-10-01 after **per-file SHA-256** of every member vs its loose copy (3,047/3,047, 3,047/3,047, 457/457; 0 mismatches). A same-size "twin" pair failed whole-file hashing; member-level SHA-256 proved identical photos (13/13) before the redundant one was removed. |
| Second identical loose copy of one photo set | ~84 GB | ⏳ owner decision — the two loose copies are now the only copies |

## ⚠️ The bigger risk the scan surfaced

About **600 GB** of the archive share is irreplaceable photo work that exists **only inside zip archives, with no second copy on the NAS** — and one of those archives is a truncated download (cut off at ~4.47 GB; entries before the cut are likely recoverable with a zip-repair tool). The external drive has **not** yet been checked for copies of these. Single copies of irreplaceable data, on the oldest and fullest device in the house, outrank the capacity problem. Details in `docs/private/`.

## Recommended order

1. **Establish a second copy of the single-copy archive data, off this NAS.** Then move the household/business archive off the media NAS onto its own storage. Solves capacity *and* the business-continuity risk of irreplaceable data on the oldest device. Highest-value single action.
2. **Fix the CIFS probe** to stop feeding the recycle bin, and bring it into this repo.
3. **Find the double-joined path** writing to `Media/synology/...`.
4. **Plan NAS replacement as a capacity + supportability decision** (Theme A). 7.3 of 7.6 TB means any growth hits the wall again within weeks.
5. **Build the disk-usage >85% alert** (Phase 4). This is the second time a volume has silently hit 100%.
