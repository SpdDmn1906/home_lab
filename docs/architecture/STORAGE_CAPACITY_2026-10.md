# Storage Capacity Analysis — 2026-10-01

**Trigger:** NAS reported 100% full (again).
**Method:** per-directory `du` over CIFS from the media host, then locally on the NAS once SSH was enabled; file-type breakdown by bytes; cross-volume title comparison for duplication.
**Scope of this doc:** public, sanitized. Household and business specifics are in `docs/private/` (gitignored).

---

## Headline

**Two volumes were at 100%, not one — and the cause is capacity, not waste.**

| Volume | Type | Capacity | Free (before) |
|---|---|---:|---:|
| NAS share (DS213j) | CIFS | 5.4 TB | **1.4 GB** |
| External drive on the media host | local NTFS (`fuseblk`) | 2.2 TB | **1.5 GB** |
| Media host root | ext4 | 228 GB | 128 GB |

**≈ 7.3 TB used of 7.6 TB.** Everything on both drives is content placed there deliberately. Reclaimable hygiene (recycle bin, Docker, a stray path) totalled **under 1%** of usage.

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

- **Cross-volume duplication — none.** Movie titles on the external drive vs the NAS: **0 overlap** (189 vs 909). They are split libraries, not copies.
- **Runaway download staging — no.** ~29 GB total.
- **Photoshop scratch / temp files — no.** Under 6 GB of PSDs and no scratch-file signatures.

## Findings and fixes

### 1. Recycle Bin + a 60-second probe = 230,000 files *(fixed: bin cleared; probe fix pending)*
The CIFS mount-health check runs **every 60 s**, touches a write-probe file on both NAS mounts, then deletes it. With Recycle Bin enabled on the share, every delete is retained: **2 files/min × 1,440 min ≈ 2,880 files/day**, ~230K after ~80 days. Zero bytes each, but they made every NAS scan crawl (enumerating the bin alone exceeded 30 minutes).

- **Cleared 2026-10-01:** 22.6 GB of real deleted content (bulk from a misconfigured path, see #2) plus the probe swamp. Free space 1.4 GB → 24 GB.
- **Pending:** change the probe to overwrite one fixed-name file instead of create+delete — still proves writability, generates no deletions.
- ⚠️ The check script and its systemd units are **hand-installed on the host, not in this repo**. It is also the "CIFS mount lost" alert that the Phase 4 roadmap still lists as unbuilt. It should be brought under version control.

### 2. Misconfigured path writing to `Media/synology/Media/...`
A stray nested path held content that was later deleted (the largest item in the recycle bin, ~18 GB). Something in the STARR chain is joining a base path twice. Tiny today; it will recur until the path is found.

### 3. Hardlinks are structurally impossible
The download client is mounted into three different devices (NAS via CIFS, the external NTFS drive, and the root ext4 volume). Hardlinks cannot cross device boundaries, and CIFS barely supports them within one. **Any import that crosses devices is a full copy**, so seeding + library = two copies. Not the cause today (staging is small), but it makes space disappear faster than it should as content grows.

### 4. The NAS itself is the bottleneck
DS213j: ARM, capped at DSM 7.0.1, cannot run Docker. Enumerating ~23 GB of small files took longer than a full scan of the 2.1 TB external drive. It slows every Plex scan and every monitoring probe that touches it.

## Reclaimable without deleting wanted content

| Item | Size | Status |
|---|---:|---|
| Recycle Bin | 22.6 GB | ✅ cleared 2026-10-01 |
| Regenerable video-editor render/proxy media (archive share) | ~109 GB | ⏳ owner decision |
| Docker images | 2.1 GB | ⏳ |
| Duplicate archives in the archive share (zips whose contents also exist extracted — one set stored 3×) | **~167 GB** | ⏳ name+size verified; hash-verify before deleting |

## ⚠️ The bigger risk the scan surfaced

About **600 GB** of the archive share is irreplaceable photo work that exists **only inside zip archives, with no second copy on the NAS** — and one of those archives no longer opens. Single copies of irreplaceable data, on the oldest and fullest device in the house, outrank the capacity problem. Details in `docs/private/`.

## Recommended order

1. **Establish a second copy of the single-copy archive data, off this NAS.** Then move the household/business archive off the media NAS onto its own storage. Solves capacity *and* the business-continuity risk of irreplaceable data on the oldest device. Highest-value single action.
2. **Fix the CIFS probe** to stop feeding the recycle bin, and bring it into this repo.
3. **Find the double-joined path** writing to `Media/synology/...`.
4. **Plan NAS replacement as a capacity + supportability decision** (Theme A). 7.3 of 7.6 TB means any growth hits the wall again within weeks.
5. **Build the disk-usage >85% alert** (Phase 4). This is the second time a volume has silently hit 100%.
