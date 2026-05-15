# Bazarr Deployment Fix - Provider Configuration

## Problem Summary
You had conflicting Bazarr configurations in both:
- `docker/docker-compose.yml` (docker-compose version)
- `terraform/modules/starr/bazarr.tf` (Terraform version)

This caused a **DuplicateKeyError** when running Terraform, preventing the container from starting.

## Solution Applied

### 1. Removed Docker-Compose Duplicate
Removed the `bazarr` service from `docker/docker-compose.yml` since you're using Terraform for the STARR stack management.

### 2. Fixed Terraform Configuration
Updated `terraform/modules/starr/bazarr.tf` with:
- Added `/etc/localtime` mount (for timezone consistency)
- Enabled and fixed the healthcheck endpoint
- Confirmed all volume mounts and networking

## Deployment Steps

### Step 1: Initialize/Update Terraform
```bash
cd terraform/modules/starr
terraform init
terraform plan
terraform apply
```

The Bazarr container will be created and attached to the `qbittorrentvpn` network namespace, sharing the same network as Radarr, Sonarr, etc.

### Step 2: Verify Container is Running
```bash
docker ps | grep bazarr
```

You should see the container running. Access the UI at: **http://192.168.1.11:6767** (or your server IP)

### Step 3: Initial Configuration in Bazarr UI

When you first open Bazarr, follow these steps:

#### 3a. Language Selection
- Choose your preferred subtitle language (English, etc.)

#### 3b. Connect to Sonarr
1. Go to **Settings → Sonarr**
2. Click **Add New Instance**
3. Fill in:
   - **Hostname:** `localhost` (shares qbittorrentvpn's network)
   - **Port:** `8989`
   - **API Key:** Copy from Sonarr → Settings → General → API Key
   - **SSL:** Off
   - **Default Bazarr profile:** Select a language profile
4. Click **Test** to verify connection
5. Click **Save**

#### 3c. Connect to Radarr
1. Go to **Settings → Radarr**
2. Click **Add New Instance**
3. Fill in:
   - **Hostname:** `localhost`
   - **Port:** `7878`
   - **API Key:** Copy from Radarr → Settings → General → API Key
   - **SSL:** Off
   - **Default Bazarr profile:** Select a language profile
4. Click **Test** to verify connection
5. Click **Save**

### Step 4: Enable Subtitle Providers

Go to **Settings → Providers** and enable your providers:

#### Subscene Provider
1. Enable **Subscene**
2. No authentication needed (free service)
3. This provider doesn't require API keys

#### YTS Provider
1. Enable **YTS** (YifySubtitles)
2. No authentication needed
3. Best for movies, limited TV show support

#### Shooter Provider
1. Enable **Shooter**
2. No authentication needed
3. Excellent for Asian content

#### Additional Recommended Providers
- **OpenSubtitles (v2)** - Most comprehensive; requires free account
  - Create account at https://www.opensubtitles.org/
  - In Bazarr: Use **OpenSubtitles (v2)** and sign in
- **PodnapisiSubtitles** - Good for multiple languages
- **Podnapisi** - Strong coverage for Eastern European content

### Step 5: Trigger Subtitle Search

#### For Existing Series (e.g., Demon Slayer)
1. Go to **Series** tab
2. Select the series
3. Click **Search** to download missing subtitles for all episodes

#### For Existing Movies
1. Go to **Movies** tab
2. Select the movie
3. Click **Search** to download subtitles

#### Automatic Search (Recommended)
1. Go to **Settings → Tasks**
2. Enable **Search for missing subtitles** and set frequency (e.g., daily)
3. Bazarr will automatically search for and download new subtitles

## Provider Priority (Recommended Order)

In **Settings → Providers**, set this search order for best results:

1. **Subscene** - Excellent coverage, many languages
2. **OpenSubtitles** - Comprehensive, reliable
3. **YTS** - Good for movies
4. **Shooter** - Great for Asian content
5. **PodnapisiSubtitles** - Good fallback

## Path Mapping

Bazarr is configured with:
- Mounts: `/data` → `${media_root_path}` (usually `/data/media`)
- This matches Sonarr/Radarr mounts exactly
- Path mapping: Usually not needed; use same paths as Sonarr/Radarr

If Sonarr/Radarr report paths like `/data/TV Shows/...`, Bazarr will see them the same way.

## Troubleshooting

### Container Won't Start
```bash
docker logs bazarr
```
Check for:
- Volume mount errors
- Network connectivity issues
- Config directory permissions

### "No subtitles found"
- Verify at least one provider is enabled
- Check provider authentication (OpenSubtitles needs account)
- Try searching for a different series/movie
- Check **Logs** in Settings for error messages

### Subtitles not syncing to Plex
- Ensure `.srt` files are in the same folder as video file
- Filename must match: `Show - S01E01.en.srt` next to `Show - S01E01.mkv`
- Refresh Plex library

### Can't connect to Sonarr/Radarr
- Verify both containers are running: `docker ps | grep -E 'sonarr|radarr'`
- Check container logs for errors
- Confirm API keys are correct
- Try `localhost` as hostname instead of container name

## References
- [Bazarr Official Docs](https://www.bazarr.media/)
- [Bazarr Wiki - Providers](https://wiki.bazarr.media/Additional-Configuration/Settings/#providers)
- [LinuxServer Bazarr Image](https://docs.linuxserver.io/images/docker-bazarr/)
