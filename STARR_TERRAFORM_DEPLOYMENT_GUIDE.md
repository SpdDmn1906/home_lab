# STARR Stack Terraform Deployment Guide (v2.0 - NAS Optimized)

## Overview

This guide documents the deployment of the STARR stack (Sonarr, Radarr, Prowlarr, qBittorrent, FlareSolverr) using **Terraform**.

**Current Architecture (v2.0):**
- **VPN Gateway:** `binhex/arch-qbittorrentvpn` (WireGuard) acts as the network gateway.
- **Storage:** Direct downloads to NAS (`/data/media/torrents`) with **Hardlinks** for instant imports.
- **Performance:** Optimized for high-speed downloads (30+ concurrent) without SSD bottlenecks.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│              STARR Stack (Networked via VPN)                │
├─────────────────────────────────────────────────────────────┤
│  qBittorrentVPN Container (Binhex)                          │
│  • VPN: PIA WireGuard                                       │
│  • Network Gateway for all other apps                       │
│  • Direct Storage Access: /data/media (NAS)                 │
├─────────────────────────────────────────────────────────────┤
│  Dependent Services (network_mode: "container:qbittorrentvpn") │
│  • Radarr (Movies)                                          │
│  • Sonarr (TV Shows)                                        │
│  • Prowlarr (Indexers)                                      │
│  • FlareSolverr (Proxy)                                     │
└─────────────────────────────────────────────────────────────┘
```

## Storage Workflow (Critical)

We use a **Direct NAS + Hardlink** workflow to prevent SSD overflow and enable instant imports.

| Path Type | Host Path | Container Path | Purpose |
| :--- | :--- | :--- | :--- |
| **NAS Root** | `/data/media` | `/data` | Common mount for all apps to enable hardlinks. |
| **Downloads** | `/data/media/torrents` | `/data/torrents` | qBittorrent saves files here directly. |
| **Movies** | `/data/media/Movies` | `/data/Movies` | Radarr destination. |
| **TV Shows** | `/data/media/TV Shows` | `/data/TV Shows` | Sonarr destination. |

**Why this works:**
1.  **No SSD Bottleneck:** Downloads write directly to the 5TB+ NAS array.
2.  **Instant Moves:** Because `/data/torrents` and `/data/Movies` are on the same filesystem (`/data`), Radarr uses **Hardlinks** (instant) instead of Copy+Delete.

## Deployment Steps

### 1. Terraform Configuration

The `main.tf` is configured to mount the NAS volume to `qbittorrentvpn`.

**Key Block in `modules/starr/main.tf`:**
```hcl
resource "docker_container" "qbittorrentvpn" {
  # ...
  
  # CRITICAL: Map NAS to /data for direct download access
  volumes {
    host_path      = var.media_root_path  # /data/media
    container_path = "/data"
  }
  
  # ...
}
```

### 2. qBittorrent Configuration (`qBittorrent.conf`)

The configuration file is persistent at `/usr/local/bin/qbittorrent/config/qBittorrent/qBittorrent.conf`.

**Essential Settings:**
```ini
[Downloads]
SavePath=/data/torrents

[Categories]
radarr\Name=radarr
radarr\SavePath=/data/torrents
sonarr\Name=sonarr
sonarr\SavePath=/data/torrents

[Session]
# Queueing Logic (Speed Optimization)
QueueingSystemEnabled=true
MaxActiveDownloads=30
MaxActiveUploads=-1
MaxActiveTorrents=-1

# Smart Skipping (Skip dead torrents)
IgnoreSlowTorrentsForQueueing=true
SlowTorrentDownloadRate=2
SlowTorrentInactivityTimer=60

# Seeding Limits (Keep queue moving)
GlobalMaxRatio=0.01
GlobalMaxSeedingMinutes=1
```

### 3. Prowlarr Configuration

Prowlarr manages the indexers. If downloads stall (0 seeds), Prowlarr is likely the culprit.

**Maintenance:**
- Ensure indexers (1337x, YTS, etc.) are **Enabled**.
- Ensure FlareSolverr is configured (`http://flaresolverr:8191`).
- If downloads stall, restart Prowlarr to force a sync with Radarr/Sonarr.

## Troubleshooting

### Issue: "0 GB Free Space" in qBittorrent UI
- **Cause:** Docker containers running on Linux cannot accurately read disk stats from CIFS/SMB network mounts.
- **Impact:** **Visual Only.** Downloads will work fine.
- **Solution:** Ignore it. Ensure `Preallocation=false` is set in config to prevent errors.

### Issue: SSD Filling Up
- **Cause:** Downloads are reverting to `/config/qBittorrent/downloads` (SSD).
- **Fix:** 
  1. Check `qBittorrent.conf` for the correct `[Categories]` and `[Downloads]` paths.
  2. Verify Radarr/Sonarr are NOT sending a hardcoded "Remote Path".
  3. Restart `qbittorrentvpn` to reload config.

### Issue: "Stalled" or "0 Seeds"
- **Cause:** Dead torrents from public trackers.
- **Fix:**
  1. Check Prowlarr indexer health.
  2. The "Smart Queueing" settings (`IgnoreSlowTorrents`) should automatically skip these after 60 seconds.
  3. If stuck, delete the torrent and let Radarr search for a better one.

## Maintenance Commands

**Restart Stack (Order Matters):**
```bash
docker restart qbittorrentvpn
sleep 10
docker restart radarr sonarr prowlarr flaresolverr
```

**Check Active Downloads:**
```bash
# Get qB cookie first (see scripts)
curl -s --cookie "$COOKIE" http://localhost:8080/api/v2/torrents/info?filter=downloading
```

**Check SSD Space:**
```bash
df -h /home/youruser/local_downloads
```
