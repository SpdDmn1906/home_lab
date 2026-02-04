# Home Lab Infrastructure Variables
# Define all configurable variables for the home lab setup

# Network Configuration
variable "network" {
  description = "Network configuration settings"
  type = object({
    unified_subnet = string
    gateway_ip     = string
    dhcp_range     = list(string)
    dns_servers    = list(string)
  })

  default = {
    unified_subnet = "192.168.1.0/24"
    gateway_ip     = "192.168.1.1"
    dhcp_range     = ["192.168.1.100", "192.168.1.200"]
    dns_servers    = ["192.168.1.1", "8.8.8.8"]
  }
}

# Service Credentials
variable "plex" {
  description = "Plex Media Server configuration"
  type = object({
    claim_token = string
  })
  sensitive = true
}

variable "grafana" {
  description = "Grafana configuration"
  type = object({
    admin_password = string
  })
  sensitive = true
}

# System settings
variable "system" {
  description = "System-wide settings"
  type = object({
    timezone = string
  })
  default = {
    timezone = "America/New_York"
  }
}

# Environment Settings
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production"
  }
}

# Docker (Terraform-managed containers)
variable "docker_networks" {
  description = "Docker networks to create (Terraform-managed)"
  type        = list(string)
  default     = []
}

variable "docker_network_subnets" {
  description = "Optional subnet per Docker network"
  type        = map(string)
  default     = {}
}

variable "docker_volumes" {
  description = "Named Docker volumes to create (Terraform-managed)"
  type        = map(object({}))
  default     = {}
}

variable "docker_services" {
  description = "Docker containers/services to run (Terraform-managed)."
  type = map(object({
    image       = string
    ports       = optional(list(string))
    environment = optional(list(string))
    volumes     = optional(list(string))
    networks    = optional(list(string))
    command     = optional(list(string))
    restart     = optional(string)
    labels      = optional(map(string))
    healthcheck = optional(object({
      test     = list(string)
      interval = optional(string)
      timeout  = optional(string)
      retries  = optional(number)
    }))
    cap_add      = optional(list(string))
    cap_drop     = optional(list(string))
    security_opt = optional(list(string))
    user         = optional(string)
    working_dir  = optional(string)
  }))
  default = {}
}

# Server Configuration
variable "server_config" {
  description = "Media server hardware configuration"
  type = object({
    hostname    = string
    ip_address  = string
    cpu_cores   = number
    memory_gb   = number
    storage_gb  = number
  })

  default = {
    hostname   = "mediaserver"
    ip_address = "192.168.1.11"
    cpu_cores  = 4
    memory_gb  = 16
    storage_gb = 1000
  }
}

# Monitoring Configuration
variable "monitoring" {
  description = "Monitoring stack configuration"
  type = object({
    retention_days     = number
    alert_email        = string
    slack_webhook      = optional(string)
    pushover_token     = optional(string)
    enable_external_alerts = bool
  })

  default = {
    retention_days     = 30
    alert_email        = ""
    enable_external_alerts = false
  }
}

# Backup Configuration
variable "backup" {
  description = "Backup system configuration"
  type = object({
    enabled         = bool
    schedule        = string
    retention_days  = number
    destination     = string
    encryption      = bool
  })

  default = {
    enabled        = true
    schedule       = "0 2 * * *"
    retention_days = 30
    destination    = "/mnt/backup"
    encryption     = true
  }
}

# Security Configuration
variable "security" {
  description = "Security settings"
  type = object({
    enable_fail2ban     = bool
    enable_firewall     = bool
    ssh_port           = number
    allowed_ips        = list(string)
    password_policy    = string
  })

  default = {
    enable_fail2ban    = true
    enable_firewall    = true
    ssh_port          = 22
    allowed_ips       = ["192.168.1.0/24"]
    password_policy   = "strong"
  }
}

# AdGuard Home Configuration
variable "adguard" {
  description = "AdGuard Home ad blocking configuration"
  type = object({
    admin_username = string
    admin_password = string
  })
  default = {
    admin_username = "admin"
    admin_password = ""
  }
  sensitive = true
}

# STARR Stack Configuration
variable "starr" {
  description = "STARR stack configuration (Gluetun VPN + qBittorrent + Radarr + Sonarr + Prowlarr + FlareSolverr). Note: VPN credentials are read from credentials.txt file in gluetun_config_path."
  type = object({
    puid                      = number
    pgid                      = number
    vpn_service_provider      = string
    vpn_server_regions        = string
    gluetun_config_path       = string  # Must contain credentials.txt file
    qbittorrent_config_path   = string
    qbittorrent_downloads_path = string
    qbittorrent_torrents_path = string
    external_media_path       = string
    radarr_config_path        = string
    sonarr_config_path        = string
    prowlarr_config_path      = string
    flaresolverr_config_path  = string
    media_root_path           = string
    synology_path             = string
  })
  sensitive = false  # No sensitive data, credentials are in file
}

# Feature Flags
variable "features" {
  description = "Enable/disable optional features"
  type = object({
    enable_adguard           = bool
    enable_parental_controls = bool
    enable_remote_access     = bool
    enable_ai_assistant      = bool
    enable_starr             = bool
    vpn_server              = bool
    reverse_proxy            = bool
    load_balancer            = bool
    distributed_storage      = bool
    gpu_passthrough          = bool
  })

  default = {
    enable_adguard           = true
    enable_parental_controls = false
    enable_remote_access     = true
    enable_ai_assistant      = false  # Resource intensive, enable when ready
    enable_starr             = false  # Enable when ready to deploy STARR stack
    vpn_server              = true
    reverse_proxy            = true
    load_balancer            = false
    distributed_storage      = false
    gpu_passthrough          = false
  }
}

# Cloud Integration (optional)
variable "cloud" {
  description = "Cloud service integration"
  type = object({
    provider           = string
    backup_bucket      = optional(string)
    domain_name        = optional(string)
    enable_cdn         = bool
  })

  default = {
    provider    = "none"
    enable_cdn  = false
  }
}

# Development/Testing Settings
variable "debug" {
  description = "Debug and development settings"
  type = object({
    enable_logs       = bool
    verbose_output    = bool
    skip_validation   = bool
  })

  default = {
    enable_logs     = true
    verbose_output  = false
    skip_validation = false
  }
}
