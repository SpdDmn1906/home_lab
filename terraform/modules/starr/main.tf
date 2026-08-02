# STARR Stack Module with Binhex qBittorrentVPN (WireGuard)
# Replaces Gluetun + qBittorrent with a single container supporting PIA WireGuard
# All other STARR services route through this container

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# qBittorrentVPN Container (Binhex)
# Acts as the VPN Gateway for the stack
resource "docker_container" "qbittorrentvpn" {
  name  = "qbittorrentvpn"
  image = "binhex/arch-qbittorrentvpn:latest"

  # Networking
  # We expose all ports for the stack here since other containers attach to this network
  ports {
    internal = 8080
    external = 8080
    protocol = "tcp"
  }
  # Privoxy (HTTP Proxy provided by binhex)
  ports {
    internal = 8118
    external = 8118
    protocol = "tcp"
  }
  # Radarr
  ports {
    internal = 7878
    external = 7878
    protocol = "tcp"
  }
  # Sonarr
  ports {
    internal = 8989
    external = 8989
    protocol = "tcp"
  }
  # Prowlarr
  ports {
    internal = 9696
    external = 9696
    protocol = "tcp"
  }
  # FlareSolverr
  ports {
    internal = 8191
    external = 8191
    protocol = "tcp"
  }
  # Bazarr
  ports {
    internal = 6767
    external = 6767
    protocol = "tcp"
  }

  # Privileged mode required for WireGuard kernel module access and iptables
  privileged = true
  
  # sysctls required for WireGuard
  sysctls = {
    "net.ipv4.conf.all.src_valid_mark" = 1
  }

  capabilities {
    add = ["NET_ADMIN"]
  }

  # Environment variables for VPN and App
  env = [
    "VPN_ENABLED=yes",
    "VPN_USER=${trimspace(file("${var.gluetun_config_path}/config/pia_user.txt"))}",
    "VPN_PASS=${trimspace(file("${var.gluetun_config_path}/config/pia_pass.txt"))}",
    "VPN_PROV=pia",
    "VPN_CLIENT=wireguard",
    "VPN_INPUT_PORTS=7878,8989,9696,8191,6767",
    "VPN_OPTIONS=", # Optional: add extra openvpn/wireguard options
    "STRICT_PORT_FORWARD=yes",
    "ENABLE_PRIVOXY=yes",
    "LAN_NETWORK=192.168.1.0/24", # Allow local access
    "NAME_SERVERS=1.1.1.1,8.8.8.8",
    "PUID=${var.puid}",
    "PGID=${var.pgid}",
    "TZ=${var.timezone}",
    "UMASK=000",
    "DEBUG=false"
  ]

  # Volumes
  # Config
  volumes {
    host_path      = var.qbittorrent_config_path
    container_path = "/config"
  }

  # Downloads - Map to /downloads to match existing Radarr/Sonarr path expectations
  # Note: Binhex defaults to /data, but we use /downloads to minimize config changes
  volumes {
    host_path      = var.qbittorrent_downloads_path
    container_path = "/downloads"
  }

  # Map qBittorrent config path downloads for legacy compatibility
  volumes {
    host_path      = var.qbittorrent_downloads_path
    container_path = "/config/qBittorrent/downloads"
  }

  # Map NAS /data/media to /data for Direct Download & Hardlinks
  volumes {
    host_path      = var.media_root_path
    container_path = "/data"
  }

  # Torrents directory (if used separately)
  volumes {
    host_path      = var.qbittorrent_torrents_path
    container_path = "/data/torrents"
  }

  # Labels
  labels {
    label = "homelab.service"
    value = "media"
  }
  labels {
    label = "homelab.type"
    value = "download_vpn"
  }
  labels {
    label = "managed_by"
    value = "terraform"
  }

  restart = "unless-stopped"
  must_run = true
}

# Radarr Container
resource "docker_container" "radarr" {
  name  = "radarr"
  image = "lscr.io/linuxserver/radarr:latest"

  # Network mode - uses qBittorrentVPN's network
  network_mode = "container:qbittorrentvpn"

  # Environment variables
  env = [
    "PUID=${var.puid}",
    "PGID=${var.pgid}",
    "TZ=${var.timezone}"
  ]

  # Volumes
  volumes {
    host_path      = "/etc/localtime"
    container_path = "/etc/localtime"
    read_only      = true
  }

  volumes {
    host_path      = var.radarr_config_path
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
    host_path      = var.qbittorrent_downloads_path
    container_path = "/downloads"
  }

  # Map qBittorrent config path downloads for legacy compatibility
  volumes {
    host_path      = var.qbittorrent_downloads_path
    container_path = "/config/qBittorrent/downloads"
  }

  volumes {
    host_path      = var.external_media_path
    container_path = "/external"
  }

  # Security options
  security_opts = ["no-new-privileges:true"]

  # Health check
  healthcheck {
    test        = ["CMD-SHELL", "curl -f http://localhost:7878/api/v3/system/status || curl -s -o /dev/null -w '%%{http_code}' http://localhost:7878/api/v3/system/status | grep -q '401'"]
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

# Sonarr Container
resource "docker_container" "sonarr" {
  name  = "sonarr"
  image = "lscr.io/linuxserver/sonarr:latest"

  # Network mode - uses qBittorrentVPN's network
  network_mode = "container:qbittorrentvpn"

  # Environment variables
  env = [
    "PUID=${var.puid}",
    "PGID=${var.pgid}",
    "TZ=${var.timezone}"
  ]

  # Volumes
  volumes {
    host_path      = "/etc/localtime"
    container_path = "/etc/localtime"
    read_only      = true
  }

  volumes {
    host_path      = var.sonarr_config_path
    container_path = "/config"
  }

  volumes {
    host_path      = var.media_root_path
    container_path = "/data"
  }

  volumes {
    host_path      = "${var.media_root_path}/TV Shows"
    container_path = "/TV Shows"
  }

  volumes {
    host_path      = var.qbittorrent_downloads_path
    container_path = "/downloads"
  }

  # Map qBittorrent config path downloads for legacy compatibility
  volumes {
    host_path      = var.qbittorrent_downloads_path
    container_path = "/config/qBittorrent/downloads"
  }

  volumes {
    host_path      = var.external_media_path
    container_path = "/external"
  }

  # Security options
  security_opts = ["no-new-privileges:true"]

  # Health check
  healthcheck {
    test        = ["CMD-SHELL", "curl -f http://localhost:8989/api/v3/system/status || curl -s -o /dev/null -w '%%{http_code}' http://localhost:8989/api/v3/system/status | grep -q '401'"]
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

# Prowlarr Container
resource "docker_container" "prowlarr" {
  name  = "prowlarr"
  image = "lscr.io/linuxserver/prowlarr:latest"

  # Network mode - uses qBittorrentVPN's network
  network_mode = "container:qbittorrentvpn"

  env = [
    "PUID=${var.puid}",
    "PGID=${var.pgid}",
    "TZ=${var.timezone}"
  ]

  volumes {
    host_path      = var.prowlarr_config_path
    container_path = "/config"
  }

  security_opts = ["no-new-privileges:true"]

  healthcheck {
    test        = ["CMD-SHELL", "curl -f http://localhost:9696/api/v1/system/status || curl -s -o /dev/null -w '%%{http_code}' http://localhost:9696/api/v1/system/status | grep -q '401'"]
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
  depends_on = [docker_container.qbittorrentvpn, docker_container.flaresolverr]
}

# FlareSolverr Container
resource "docker_container" "flaresolverr" {
  name  = "flaresolverr"
  image = "ghcr.io/flaresolverr/flaresolverr:latest"

  # Network mode - uses qBittorrentVPN's network
  network_mode = "container:qbittorrentvpn"

  env = [
    "TZ=${var.timezone}",
    "LOG_LEVEL=info",
    "LOG_FILE="
  ]

  volumes {
    host_path      = var.flaresolverr_config_path
    container_path = "/config"
  }

  security_opts = ["no-new-privileges:true"]

  healthcheck {
    test        = ["CMD-SHELL", "curl -f http://localhost:8191/v1 || curl -s -o /dev/null -w '%%{http_code}' http://localhost:8191/v1 | grep -qE '(200|405)'"]
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
  must_run = true
}
