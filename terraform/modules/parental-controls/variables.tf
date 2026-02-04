# Parental Controls Module Variables

variable "network_name" {
  description = "Docker network name"
  type        = string
  default     = "homelab"
}

variable "timezone" {
  description = "Timezone for scheduling"
  type        = string
  default     = "America/New_York"
}

variable "network_range" {
  description = "Network range to monitor"
  type        = string
  default     = "192.168.1.0/24"
}

# Device restrictions
variable "restricted_devices" {
  description = "Devices under parental control"
  type = list(object({
    name          = string
    mac           = string
    ip            = optional(string)
    allowed_hours = string
    blocked_sites = optional(list(string), [])
  }))
  default = []
}

# Time restrictions
variable "time_restrictions" {
  description = "Time-based access restrictions"
  type = list(object({
    device     = string
    start_time = string
    end_time   = string
    days       = list(string)
  }))
  default = []
}

# Content filtering
variable "blocked_domains" {
  description = "Domains to block for all restricted devices"
  type        = list(string)
  default = [
    "youtube.com",
    "tiktok.com",
    "instagram.com",
    "facebook.com",
    "twitter.com",
    "snapchat.com",
    "discord.com",
    "roblox.com",
    "minecraft.net",
    "fortnite.com"
  ]
}

variable "allowed_domains" {
  description = "Domains explicitly allowed (whitelist)"
  type        = list(string)
  default = [
    "edu",
    "gov",
    "school",
    "library"
  ]
}

# Parental DNS (OpenDNS FamilyShield)
variable "parental_dns_servers" {
  description = "DNS servers for parental control"
  type        = list(string)
  default     = ["208.67.222.123", "208.67.220.123"]  # OpenDNS FamilyShield
}

# Monitoring configuration
variable "monitor_config_path" {
  description = "Path for monitoring configuration"
  type        = string
  default     = "/opt/parental-monitor/config"
}

variable "monitor_data_path" {
  description = "Path for monitoring data"
  type        = string
  default     = "/opt/parental-monitor/data"
}

variable "monitor_interval" {
  description = "Monitoring check interval"
  type        = string
  default     = "30s"
}

# Dashboard configuration
variable "enable_dashboard" {
  description = "Enable parental control dashboard"
  type        = bool
  default     = true
}

variable "dashboard_config_path" {
  description = "Path for dashboard configuration"
  type        = string
  default     = "/opt/parental-dashboard"
}

# Alert configuration
variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

variable "smtp_config" {
  description = "SMTP configuration for email alerts"
  type = object({
    server   = string
    port     = number
    username = string
    password = string
    use_tls  = bool
  })
  default = {
    server   = ""
    port     = 587
    username = ""
    password = ""
    use_tls  = true
  }
  sensitive = true
}

# Advanced features
variable "enable_device_shutdown" {
  description = "Enable remote device shutdown capability"
  type        = bool
  default     = false
}

variable "enable_screen_time_tracking" {
  description = "Enable detailed screen time tracking"
  type        = bool
  default     = true
}

variable "enable_content_filtering" {
  description = "Enable advanced content filtering"
  type        = bool
  default     = true
}

variable "max_daily_screen_time" {
  description = "Maximum daily screen time in hours"
  type        = map(number)
  default = {
    "child1" = 2
    "child2" = 2
  }
}

# Integration settings
variable "integrate_with_adguard" {
  description = "Integrate with AdGuard Home for DNS-based filtering (planned; module currently provides monitoring scaffolding)"
  type        = bool
  default     = false
}

variable "integrate_with_grafana" {
  description = "Create Grafana dashboards for parental controls"
  type        = bool
  default     = true
}


