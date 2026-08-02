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
  description = "The binhex/arch-qbittorrentvpn image passes this straight through as VPN_REMOTE_SERVER, which its wireguard.sh expects to be a literal PIA server IP address (e.g. 147.90.227.142) - NOT a friendly region name. Get real, currently-live IPs from https://serverlist.piaservers.net/vpninfo/servers/v6 (filter for port_forward: true, since STRICT_PORT_FORWARD=yes is set below). Named 'CA Montreal' historically but was never actually wired to anything until 2026-08-02 - the default below is illustrative only, always verify against the live server list before using it."
  type        = string
  default     = "147.90.227.142" # DE Frankfurt, port_forward=true as of 2026-08-02 - verify freshness before reuse
}

variable "gluetun_config_path" {
  description = "Path to Gluetun configuration directory on host (must contain pia_user.txt/pia_pass.txt). Set the real value in terraform.tfvars (gitignored) — do not hardcode a real path here. PIA requires the password to contain lowercase, uppercase, AND numbers — a pure-hex generator (e.g. `openssl rand -hex N`) will be silently rejected at the WireGuard handshake (interface comes up, 0 bytes ever received back). Use `tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24` instead."
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
  description = "Path to Synology NAS mount. Set the real value in terraform.tfvars (gitignored) — do not hardcode a real path here."
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
