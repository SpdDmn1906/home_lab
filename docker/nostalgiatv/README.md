# NostalgiaTV server

Builds live-TV style channels from the existing Plex library and exposes an
HDHR/IPTV tuner so Plex DVR, Channels, Jellyfin or TiviMate can tune in.
Same category as ErsatzTV / Tunarr — it schedules content already owned.

- **Host:** media host, `/home/<user>/Docker/nostalgiatv/`
- **UI:** `http://<media-host>:19850/configure` · watch at `/watch`
- **Tuner:** `/channels.m3u` (playlist) · `/xmltv.xml` (EPG) · `/stream/{channelId}`
- **Deployed:** 2026-09-29, image pinned at `0.10.14-20260929-1914`

## Why the limits are not optional

This host is a 4-core i5-4690K already running Plex, the STARR stack and ~19
containers, and it hung hard in Aug 2026. The compose file caps the service at
**2.0 CPUs** and sets **`cpu_shares: 512`** so Plex (default 1024) wins any
contention. Memory is capped at 2G.

🔴 **Do not enable the `SILENCE` mid-break mode on this host.** It runs real
ffmpeg silence detection across the library and will saturate this CPU.

## Supply-chain posture — read before upgrading

- **Closed source.** No public repository; the image is the only artifact.
- Publisher registered 2026-03-29, **2 stars** against ~35K pulls.
- Pre-1.0 and shipping **multiple builds per day**.

Consequences, both deliberate:
- **The tag is pinned.** Never move this to `:latest` — a silent bump breaking
  the DVR is a real failure mode at that cadence. Bump on purpose, and read the
  changes first.
- **Capabilities are dropped to the minimum.** `cap_drop: ALL` plus only the
  five the entrypoint needs to chown its mounts and drop from root to `appuser`
  (`CHOWN`, `DAC_OVERRIDE`, `FOWNER`, `SETUID`, `SETGID`). Dropping ALL with no
  add-backs crash-loops on `failed switching to "appuser"` — verified, not
  theoretical. `no-new-privileges` is on. Verified running as uid 1000, not root.

## ⚠️ Credential scope

Connecting a media server hands this container a token that can read the whole
library. **Use a Plex Home managed user scoped to the libraries you want as
channels — not the admin account.** Closed-source image, unknown publisher.

## Storage

Bind mounts live on `/` (118G free). Deliberately **not** `/external/media`,
which is at 100%.
