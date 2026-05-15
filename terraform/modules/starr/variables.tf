variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "timezone" {
  description = "Timezone for containers"
  type        = string
  default     = "America/New_York"
}

variable "puid" {
  description = "User ID for containers"
  type        = number
  default     = 1000
}

variable "pgid" {
  description = "Group ID for containers"
  type        = number
  default     = 1004
}

# Gluetun VPN Configuration
variable "vpn_service_provider" {
  description = "VPN service provider (pia, nordvpn, surfshark, etc.)"
  type        = string
  default     = "pia"
}

variable "vpn_server_regions" {
  description = "Preferred VPN server regions. For PIA with port forwarding, use a region that supports it (e.g. CA Montreal, Germany, Netherlands); US East does not."
  type        = string
  default     = "CA Montreal"
}

variable "gluetun_config_path" {
  description = "Path to Gluetun configuration directory on host (must contain credentials.txt file)"
  type        = string
  default     = "/home/youruser/Docker/config/data_gluetun"
}

# qBittorrent Configuration
variable "qbittorrent_config_path" {
  description = "Path to qBittorrent config directory on host"
  type        = string
  default     = "/usr/local/bin/qbittorrent/config"
}

variable "qbittorrent_downloads_path" {
  description = "Path to qBittorrent downloads directory"
  type        = string
  default     = "/data/media/downloads"
}

variable "qbittorrent_torrents_path" {
  description = "Path to qBittorrent torrents directory"
  type        = string
  default     = "/external/media/torrents"
}

variable "external_media_path" {
  description = "Path to external media directory"
  type        = string
  default     = "/external/media"
}

# Radarr Configuration
variable "radarr_config_path" {
  description = "Path to Radarr config directory on host"
  type        = string
  default     = "/usr/local/bin/radarr/config"
}

variable "media_root_path" {
  description = "Path to media root directory"
  type        = string
  default     = "/data/media"
}

variable "synology_path" {
  description = "Path to Synology NAS mount"
  type        = string
  default     = "/home/youruser/synology"
}

# Sonarr Configuration
variable "sonarr_config_path" {
  description = "Path to Sonarr config directory on host"
  type        = string
  default     = "/usr/local/bin/sonarr/config"
}

# Prowlarr Configuration
variable "prowlarr_config_path" {
  description = "Path to Prowlarr config directory on host"
  type        = string
  default     = "/usr/local/bin/prowlarr/data"
}

# FlareSolverr Configuration
variable "flaresolverr_config_path" {
  description = "Path to FlareSolverr config directory on host"
  type        = string
  default     = "/usr/local/bin/flaresolverr/data"
}

# Bazarr Configuration
variable "bazarr_config_path" {
  description = "Path to Bazarr config directory on host"
  type        = string
  default     = "/usr/local/bin/bazarr/config"
}
