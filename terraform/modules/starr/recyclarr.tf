# Recyclarr — syncs TRaSH-Guides naming + a curated set of custom formats into Radarr/Sonarr
# on a daily cron (added 2026-10-04). Config: docker/recyclarr/recyclarr.yml in this repo, copied to
# var.recyclarr_config_path on the host next to a host-only secrets.yml holding the API keys.
# What is deliberately not synced, and why: docs/guides/starr-trash-alignment.md
resource "docker_container" "recyclarr" {
  name = "recyclarr"
  # Pinned: Recyclarr ships breaking config changes in major versions (v8 removed several keys).
  image = "ghcr.io/recyclarr/recyclarr:8.7.2"

  # Host networking reaches Radarr/Sonarr on the ports the VPN container publishes, without
  # sharing the VPN network namespace (and its container-ID replace quirk).
  network_mode = "host"
  user         = "${var.puid}:${var.pgid}"

  env = [
    "TZ=${var.timezone}",
    "CRON_SCHEDULE=@daily"
  ]

  volumes {
    host_path      = var.recyclarr_config_path
    container_path = "/config"
  }

  security_opts = ["no-new-privileges:true"]

  labels {
    label = "homelab.service"
    value = "media"
  }
  labels {
    label = "managed_by"
    value = "terraform"
  }

  restart = "unless-stopped"
}
