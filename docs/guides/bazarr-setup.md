# Bazarr Setup Guide (STARR Subtitles)

Bazarr fetches subtitles (e.g. `.srt`) for TV and movies managed by Sonarr and Radarr, and saves them next to the media files so Plex picks them up automatically. Use it to automate the manual "download 24 .srt files" workflow.

## Prerequisites

- Sonarr and Radarr already running and configured (same stack as this compose).
- Same **media path** used by Sonarr/Radarr so Bazarr can read and write next to files.

## Deploy Bazarr (docker-compose)

### 1. Set environment variables

Ensure your `.env` (or `config/mediaserver.env` on the server) includes:

```bash
# Bazarr config (persistent)
BAZARR_CONFIG_PATH=/usr/local/bin/bazarr/config

# Must match Sonarr/Radarr - same host path they use for media
MEDIA_PATH=/data/media
```

Create the config directory on the host if it doesn't exist:

```bash
sudo mkdir -p /usr/local/bin/bazarr/config
sudo chown -R 1000:1004 /usr/local/bin/bazarr/config   # match PUID/PGID
```

### 2. Start Bazarr

From the directory containing `docker-compose.yml` (e.g. `docker/`):

```bash
docker compose up -d bazarr
```

Or start the whole stack:

```bash
docker compose up -d
```

Bazarr listens on **port 6767**. Open: `http://<server-ip>:6767`.

### 3. One-time wizard and connections

1. **Language** – Choose your preferred subtitle language(s), e.g. English.
2. **Sonarr** – Add connection:
   - **Hostname:** `sonarr` (Docker service name)
   - **Port:** `8989`
   - **API Key:** From Sonarr → Settings → General → API Key
   - **Path mapping (if needed):** If Sonarr’s root folder is `/data`, leave Bazarr’s mapping empty or set Sonarr path `/data` → Bazarr path `/data` (Bazarr mounts the same `MEDIA_PATH` as `/data`).
3. **Radarr** – Add connection:
   - **Hostname:** `radarr`
   - **Port:** `7878`
   - **API Key:** From Radarr → Settings → General → API Key
   - Same path mapping idea as Sonarr (Bazarr’s `/data` = same as Radarr’s `/data`).

### 4. Subtitle providers (e.g. OpenSubtitles)

- Go to **Settings → Providers**.
- Enable **OpenSubtitles** (and optionally others).
- For OpenSubtitles:
  - Create a free account at [OpenSubtitles.org](https://www.opensubtitles.org/).
  - In Bazarr, use **OpenSubtitles (v2)** and sign in with username/password (or the newer OpenSubtitles API if the UI offers it).

### 5. Trigger subtitle search for existing series (e.g. 24 episodes)

- **Settings → Sonarr** (or Radarr): ensure the connection is **tested and saved**.
- **Series** (or **Movies**): you’ll see series/movies synced from Sonarr/Radarr.
- For a given series (e.g. Demon Slayer):
  - Open the series → **Search** (or use “Search for missing subtitles” for the whole series).
- Or use **Settings → Tasks** to run “Search for missing subtitles” on a schedule (e.g. daily).

Bazarr will download `.srt` files next to the video files (same folder, same base name). Plex will detect them after a library refresh or scan.

## Path mapping (important)

Bazarr must see the **same paths** as Sonarr/Radarr for episode/movie files. In this stack:

- Sonarr and Radarr mount `${MEDIA_PATH}` as `/data` inside the container.
- Bazarr mounts the same `${MEDIA_PATH}` as `/data`.

So when Sonarr reports an episode path like `/data/TV Shows/Demon Slayer/Season 01/...`, Bazarr’s `/data` is the same directory; no path mapping is usually needed. If your Sonarr/Radarr root folders use different names (e.g. `/tv`, `/movies`), add the corresponding mapping in Bazarr’s Sonarr/Radarr settings (Sonarr path → Bazarr path).

## Optional: Terraform STARR stack

If you run Sonarr/Radarr via **Terraform** (e.g. `terraform/modules/starr`) with VPN and different network, add a Bazarr container there too:

- Use the same **media_root_path** (and optional **external_media_path**) so Bazarr can read/write the same files.
- Connect Bazarr to Sonarr/Radarr via the hostnames/IPs and ports that work in that network (e.g. `localhost` if Bazarr shares the same network namespace as the VPN container, or the service names if they’re on a shared Docker network).
- Reuse the same path logic: Bazarr’s mount paths must match what Sonarr/Radarr use.

## Troubleshooting

- **“No subtitles found”** – Check provider (e.g. OpenSubtitles) is enabled and signed in; try another provider.
- **“Path does not exist”** – Fix path mapping so Bazarr’s paths match Sonarr/Radarr (see above).
- **Subtitles not appearing in Plex** – Ensure the `.srt` is in the same folder as the video with the same base name (e.g. `Show - S01E01.en.srt` next to `Show - S01E01.mkv`). Refresh the library or the show in Plex.

## References

- [Bazarr](https://www.bazarr.media/)
- [LinuxServer Bazarr image](https://docs.linuxserver.io/images/docker-bazarr/)
- [Bazarr Wiki – Settings](https://wiki.bazarr.media/Additional-Configuration/Settings/)
