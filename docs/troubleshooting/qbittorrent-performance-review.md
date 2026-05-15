# qBittorrent Performance Review (Current)

**Reviewed:** Configuration file, live API preferences, volume mounts, and queue state.

---

## 1. Storage & Paths

| What | Value |
|------|--------|
| **Download location (effective)** | SSD: `/home/youruser/local_downloads` |
| **Container path** | `/config/qBittorrent/downloads` (and `/downloads`) |
| **Config file `DefaultSavePath`** | `/data/torrents` (overridden by category/volume; actual writes go to SSD) |
| **API `save_path`** | `/config/qBittorrent/downloads` ✓ |

**Mounts:**
`/config/qBittorrent/downloads` and `/downloads` both point to the SSD. NAS is at `/data` (media root). So downloads land on SSD; Radarr/Sonarr copy to NAS and (with “Remove” enabled) delete from the client.

**Verdict:** Paths are correct for the current “SSD for speed, copy-to-NAS then remove” setup.

---

## 2. Queue & Concurrency (Critical for SSD)

| Setting | Config file | Live API | Notes |
|---------|-------------|----------|--------|
| **Max active downloads** | 3 | 3 ✓ | Limits concurrent downloads to avoid overflowing SSD. |
| **Max active torrents** | -1 | -1 ✓ | No cap on total active (download + seed). |
| **Max active uploads** | -1 | -1 ✓ | All completed torrents can seed; no queue blocking. |
| **Queueing enabled** | true | true ✓ | Queue rules are active. |

**Verdict:** Queue limits match intent: 3 downloads at a time, no artificial cap on seeding so completed items can finish and be removed by Radarr.

---

## 3. Seeding / Share Limits (Deletion behavior)

| Setting | Config file | Live API | Notes |
|---------|-------------|----------|--------|
| **Global max ratio** | 0.01 | (see below) | In file: 0.01. |
| **Global max seeding time** | 1 min | (see below) | In file: 1. |
| **Share limit action** | Stop | - | Stop when limit hit (Radarr then removes). |
| **max_ratio_enabled** | - | **false** ⚠️ | Ratio limit may be off in running app. |
| **max_seeding_time_enabled** | - | **false** ⚠️ | Seeding time limit may be off. |

**Issue:** Config file has ratio and time limits, but the live app has `max_ratio_enabled: false` and `max_seeding_time_enabled: false`. That can leave torrents “seeding” forever and never trigger “finished,” so Radarr won’t remove them and SSD fills.

**Action:** In qBittorrent Web UI: **Tools → Options → BitTorrent** (or Queue).
- Enable **“When ratio reaches”** and set to **0.01**.
- Enable **“When seeding time reaches”** and set to **1** minute.
- **“Then:”** **Stop** (or Remove, if you prefer auto-remove from client).

After a restart, the config file values should be re-applied; re-check the UI to ensure both limits stay enabled.

---

## 4. Performance / Cache

| Setting | Config file | Live API | Notes |
|---------|-------------|----------|--------|
| **Disk cache size** | 4096 (4 GB) | **-1** | -1 = use app default; may be smaller than 4 GB. |
| **Disk cache TTL** | 60 s | 60 ✓ | |
| **Async I/O threads** | 16 | 10 | API lower; file value used on next start. |
| **Preallocation** | false | - | Good for network/SSD. |

**Suggestion:** After setting ratio/seeding limits in the UI, in **Options → Advanced** set **“Disk cache”** to **4096** MiB so the 4 GB cache is guaranteed. Restart qBittorrent so both config and cache size stick.

---

## 5. Slow-torrent / Queue behavior

| Setting | Config file | Live API |
|---------|-------------|----------|
| **Ignore slow torrents for queue** | true | dont_count_slow_torrents: false ⚠️ |
| **Slow torrent DL rate** | 2 KiB/s | 5 (API unit may differ) |
| **Slow torrent inactive timer** | 30 s | 60 s |

Config uses 30 s and 2 KiB/s to skip stalled torrents; the running app may use 60 s and a different threshold. Restarting qBittorrent will re-apply the config file (30 s, 2 KiB/s). If you still see stalled items blocking the queue, we can align the API/UI with the config.

---

## 6. Current queue state (at review time)

- **metaDL:** 1
- **queuedDL:** 41
- **stalledDL:** 2
- **Seeding / completed:** 0 (after recent purge)

So 3 “active” slots in use (1 meta + 2 stalled), 41 waiting. Matches **Max active downloads = 3**.

---

## 7. Summary & checklist

**Working as intended**

- Downloads on SSD, paths and mounts correct.
- Max 3 active downloads; unlimited uploads/torrents so completed items don’t stay queued.
- Radarr remote path mapping in place; imports and purge of completed seeding torrents have been done.

**Fix in qBittorrent UI (then restart)**

1. **BitTorrent / Queue:** Turn on **ratio limit (0.01)** and **seeding time limit (1 min)**, action **Stop**.
2. **Advanced:** Set **Disk cache** to **4096** MiB.
3. Restart qBittorrent (or the qbittorrentvpn container) so:
   - Ratio and time limits stay enabled (and match config file).
   - 4 GB cache and 30 s slow-torrent timer from config are applied.

**Ongoing**

- Keep **“Remove completed”** enabled in Radarr (and Sonarr) so they delete the download from the client after import.
- If the SSD ever fills again, re-check that ratio and seeding time limits are still **enabled** in the UI and that “Remove” is still on in Radarr/Sonarr.
