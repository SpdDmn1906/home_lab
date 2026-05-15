
# Bazarr Container
resource "docker_container" "bazarr" {
  name  = "bazarr"
  image = "lscr.io/linuxserver/bazarr:latest"

  # Network mode - uses qBittorrentVPN's network
  network_mode = "container:qbittorrentvpn"

  env = [
    "PUID=${var.puid}",
    "PGID=${var.pgid}",
    "TZ=${var.timezone}"
  ]

  volumes {
    host_path      = "/etc/localtime"
    container_path = "/etc/localtime"
    read_only      = true
  }

  volumes {
    host_path      = var.bazarr_config_path
    container_path = "/config"
  }

  volumes {
    host_path      = var.media_root_path
    container_path = "/data"
  }

  volumes {
    host_path      = "${var.media_root_path}/Movies"
    container_path = "/Movies"
  }

  volumes {
    host_path      = "${var.media_root_path}/TV Shows"
    container_path = "/TV Shows"
  }

  volumes {
    host_path      = var.external_media_path
    container_path = "/external"
  }

  security_opts = ["no-new-privileges:true"]

  healthcheck {
    test        = ["CMD-SHELL", "curl -f http://localhost:6767/api/v1/system/status || curl -s -o /dev/null -w '%%{http_code}' http://localhost:6767/api/v1/system/status | grep -q '401'"]
    interval    = "30s"
    timeout     = "10s"
    retries     = 3
    start_period = "60s"
  }

  labels {
    label = "homelab.service"
    value = "media"
  }
  labels {
    label = "managed_by"
    value = "terraform"
  }

  restart = "unless-stopped"
  depends_on = [docker_container.qbittorrentvpn]
}
