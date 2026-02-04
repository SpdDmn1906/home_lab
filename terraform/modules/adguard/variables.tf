# AdGuard Home Module Variables

variable "timezone" {
  description = "Timezone for AdGuard Home"
  type        = string
  default     = "America/New_York"
}

variable "admin_username" {
  description = "AdGuard Home admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "AdGuard Home web interface password"
  type        = string
  sensitive   = true
}

variable "enable_unbound" {
  description = "Enable Unbound recursive DNS resolver"
  type        = bool
  default     = true
}

variable "unbound_port" {
  description = "Unbound DNS port"
  type        = number
  default     = 5335
}

variable "upstream_dns" {
  description = "Upstream DNS servers (used if Unbound disabled)"
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1", "8.8.8.8", "8.8.4.4"]
}

variable "enable_dnssec" {
  description = "Enable DNSSEC validation"
  type        = bool
  default     = true
}

variable "enable_edns_client_subnet" {
  description = "Enable EDNS Client Subnet"
  type        = bool
  default     = true
}

variable "enable_fastest_addr" {
  description = "Use fastest IP address"
  type        = bool
  default     = true
}

variable "enable_parallel_requests" {
  description = "Enable parallel DNS requests"
  type        = bool
  default     = true
}

variable "network_name" {
  description = "Docker network name for AdGuard Home"
  type        = string
  default     = "adguard"
}

variable "network_subnet" {
  description = "Docker network subnet"
  type        = string
  default     = "172.21.0.0/16"
}

variable "config_path" {
  description = "Host path for AdGuard Home configuration"
  type        = string
  default     = "/opt/adguard/conf"
}

variable "work_path" {
  description = "Host path for AdGuard Home work directory"
  type        = string
  default     = "/opt/adguard/work"
}

variable "unbound_config_path" {
  description = "Host path for Unbound configuration"
  type        = string
  default     = "/opt/adguard/unbound"
}

variable "enable_dhcp" {
  description = "Enable DHCP server in AdGuard Home"
  type        = bool
  default     = false
}

variable "ipv4_address" {
  description = "IPv4 address for AdGuard Home"
  type        = string
  default     = "192.168.1.11"
}

variable "dhcp_range_start" {
  description = "DHCP range start"
  type        = string
  default     = "192.168.1.100"
}

variable "dhcp_range_end" {
  description = "DHCP range end"
  type        = string
  default     = "192.168.1.200"
}

variable "dhcp_gateway" {
  description = "DHCP gateway IP"
  type        = string
  default     = "192.168.1.1"
}

variable "dhcp_subnet_mask" {
  description = "DHCP subnet mask"
  type        = string
  default     = "255.255.255.0"
}

variable "dhcp_lease_time" {
  description = "DHCP lease time (in hours)"
  type        = number
  default     = 24
}

variable "filtering_enabled" {
  description = "Enable DNS filtering"
  type        = bool
  default     = true
}

variable "blocking_mode" {
  description = "Blocking mode: default, nxdomain, null_ip, custom_ip"
  type        = string
  default     = "default"
}

variable "blocking_ip" {
  description = "Custom IP for blocking (if blocking_mode is custom_ip)"
  type        = string
  default     = "0.0.0.0"
}

variable "blocklist_urls" {
  description = "List of blocklist URLs"
  type        = list(string)
  default = [
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
    "https://mirror1.malwaredomains.com/files/justdomains",
    "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt",
    "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt",
    "https://hosts-file.net/ad_servers.txt",
    "https://adaway.org/hosts.txt",
    "https://someonewhocares.org/hosts/zero/hosts",
    "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/MobileFilter/sections/adservers.txt",
    "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/SpywareFilter/sections/tracking_servers.txt"
  ]
}

variable "allowlist_urls" {
  description = "List of allowlist URLs"
  type        = list(string)
  default     = []
}

variable "custom_dns_records" {
  description = "Custom DNS records"
  type = list(object({
    domain = string
    ip     = string
  }))
  default = []
}

variable "rewrite_rules" {
  description = "DNS rewrite rules for local services"
  type = list(object({
    domain = string
    answer = string
  }))
  default = []
}

variable "lan_dns_records" {
  description = "LAN DNS records for local devices"
  type = list(object({
    hostname = string
    ip       = string
  }))
  default = [
    {
      hostname = "plex"
      ip       = "192.168.1.11"
    },
    {
      hostname = "nas"
      ip       = "192.168.1.20"
    },
    {
      hostname = "grafana"
      ip       = "192.168.1.11"
    },
    {
      hostname = "prometheus"
      ip       = "192.168.1.11"
    }
  ]
}

variable "dhcp_reservations" {
  description = "DHCP reservations for consistent IPs"
  type = list(object({
    hostname = string
    ip       = string
    mac      = string
  }))
  default = []
}

variable "enable_monitoring" {
  description = "Enable AdGuard Home monitoring with Prometheus"
  type        = bool
  default     = true
}

variable "query_log_enabled" {
  description = "Enable DNS query logging"
  type        = bool
  default     = true
}

variable "query_log_interval" {
  description = "Query log rotation interval (hours)"
  type        = number
  default     = 24
}

variable "query_log_size_memory" {
  description = "Query log memory size (entries)"
  type        = number
  default     = 1000
}

variable "enable_rate_limiting" {
  description = "Enable DNS rate limiting"
  type        = bool
  default     = true
}

variable "ratelimit" {
  description = "DNS queries per second limit"
  type        = number
  default     = 20
}

