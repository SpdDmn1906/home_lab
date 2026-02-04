# Remote Access Module Variables

variable "network_name" {
  description = "Docker network name"
  type        = string
  default     = "homelab"
}

variable "timezone" {
  description = "Timezone"
  type        = string
  default     = "America/New_York"
}

variable "server_domain" {
  description = "Server domain name for remote access"
  type        = string
  default     = "homelab.local"
}

# WireGuard VPN
variable "enable_wireguard" {
  description = "Enable WireGuard VPN server"
  type        = bool
  default     = true
}

variable "wireguard_config_path" {
  description = "Path for WireGuard configuration"
  type        = string
  default     = "/opt/wireguard"
}

variable "wireguard_peers" {
  description = "WireGuard peer configurations"
  type = list(object({
    name       = string
    public_key = optional(string)
    allowed_ips = optional(string)
  }))
  default = [
    {
      name = "admin"
    },
    {
      name = "laptop"
    }
  ]
}

variable "wireguard_peer_dns" {
  description = "DNS server for WireGuard peers"
  type        = string
  default     = "192.168.1.1"
}

variable "wireguard_internal_subnet" {
  description = "WireGuard internal subnet"
  type        = string
  default     = "10.0.10.0/24"
}

variable "wireguard_allowed_ips" {
  description = "Allowed IPs for WireGuard peers"
  type        = string
  default     = "0.0.0.0/0"
}

# OpenVPN
variable "enable_openvpn" {
  description = "Enable OpenVPN server"
  type        = bool
  default     = false
}

variable "openvpn_config_path" {
  description = "Path for OpenVPN configuration"
  type        = string
  default     = "/opt/openvpn"
}

# Remote Desktop
variable "enable_nomachine" {
  description = "Enable NoMachine remote desktop"
  type        = bool
  default     = false
}

variable "nomachine_user" {
  description = "NoMachine username"
  type        = string
  default     = "homelab"
}

variable "nomachine_password" {
  description = "NoMachine password"
  type        = string
  sensitive   = true
}

variable "enable_guacamole" {
  description = "Enable Apache Guacamole web remote desktop"
  type        = bool
  default     = true
}

variable "guacamole_db_password" {
  description = "Guacamole database password"
  type        = string
  sensitive   = true
}

variable "guacamole_db_path" {
  description = "Path for Guacamole database"
  type        = string
  default     = "/opt/guacamole/db"
}

# SSH Access
variable "enable_ssh_jump" {
  description = "Enable SSH jump host"
  type        = bool
  default     = true
}

variable "ssh_config_path" {
  description = "Path for SSH configuration"
  type        = string
  default     = "/opt/ssh-jump"
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "homelab"
}

variable "ssh_password" {
  description = "SSH password"
  type        = string
  sensitive   = true
}

# Tailscale
variable "enable_tailscale" {
  description = "Enable Tailscale mesh VPN"
  type        = bool
  default     = false
}

variable "tailscale_auth_key" {
  description = "Tailscale authentication key"
  type        = string
  sensitive   = true
}

# Reverse Proxy
variable "enable_reverse_proxy" {
  description = "Enable Traefik reverse proxy"
  type        = bool
  default     = true
}

variable "traefik_config_path" {
  description = "Path for Traefik configuration"
  type        = string
  default     = "/opt/traefik"
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificates"
  type        = string
  default     = ""
}

# Security
variable "enable_ssl" {
  description = "Enable SSL/TLS for all services"
  type        = bool
  default     = true
}

variable "allowed_networks" {
  description = "Networks allowed remote access"
  type        = list(string)
  default     = ["192.168.1.0/24", "10.0.10.0/24"]  # Local + VPN
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable monitoring for remote access services"
  type        = bool
  default     = true
}


