# Recyclarr

Syncs TRaSH-Guides settings into Radarr and Sonarr once a day. Deployed by Terraform
(`terraform/modules/starr/recyclarr.tf`, image pinned at `8.7.2`).

**What it manages:** TRaSH naming (Plex TMDb/TVDb), propers/repacks mode, and seven custom formats
(BR-DISK, 3D, Extras, AV1 blocked; Repack/Proper preferred) scored into the profiles actually in use.
**What it deliberately leaves alone:** quality definitions (the size caps), quality profiles, and every
custom format it did not create. The reasons are in `docs/guides/starr-trash-alignment.md`.

## Host setup

```bash
sudo install -d -o 1000 -g 1004 -m 750 /usr/local/bin/recyclarr/config   # puid:pgid
cp recyclarr.yml /usr/local/bin/recyclarr/config/
# secrets.yml: copy secrets.yml.example, fill in both API keys, chmod 600
```

## Everyday commands

```bash
docker exec recyclarr recyclarr sync --preview   # what would change (add -t to docker exec for tables)
docker exec recyclarr recyclarr sync             # sync now instead of waiting for the cron
docker logs recyclarr                            # cron runs
```

**Gotchas:**
- Instance names must be unique across Radarr *and* Sonarr. A duplicate makes Recyclarr skip the
  instance and log it only at debug level, so a sync "succeeds" and does nothing.
- Preview tables only render with a TTY (`docker exec -t` / `docker run -t`).
- Manual UI edits to anything listed above get reverted at the next daily sync. Change the YAML instead.
- **Adding a UHD profile later** (once a 4K player is in the house): add a TRaSH UHD quality profile +
  its custom formats here, assign it to chosen titles only. Still do **not** add `quality_definition`.
