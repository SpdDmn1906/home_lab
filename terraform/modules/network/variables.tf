# Network Module Variables

variable "interface" {
  description = "Network interface name"
  type        = string
  default     = "eth0"
}

variable "ip_address" {
  description = "Static IP address for the server"
  type        = string
  default     = "192.168.1.11"
}

variable "netmask" {
  description = "Network netmask"
  type        = string
  default     = "24"
}

variable "gateway" {
  description = "Default gateway IP"
  type        = string
  default     = "192.168.1.1"
}

variable "subnet" {
  description = "Network subnet"
  type        = string
  default     = "192.168.1.0"
}

variable "dhcp_range" {
  description = "DHCP IP range [start, end]"
  type        = list(string)
  default     = ["192.168.1.100", "192.168.1.200"]
}

variable "dns_servers" {
  description = "DNS server IPs"
  type        = list(string)
  default     = ["192.168.1.1", "8.8.8.8"]
}

variable "domain_name" {
  description = "Local domain name"
  type        = string
  default     = "homelab.local"
}

variable "dns_records" {
  description = "DNS A records"
  type        = map(string)
  default = {
    "plex.homelab.local"     = "192.168.1.11"
    "nas.homelab.local"      = "192.168.1.20"
    "grafana.homelab.local"  = "192.168.1.11"
    "prometheus.homelab.local" = "192.168.1.11"
  }
}

variable "enable_vlans" {
  description = "Enable VLAN configuration"
  type        = bool
  default     = false
}

variable "vlan_config" {
  description = "VLAN configuration"
  type = list(object({
    id     = number
    name   = string
    subnet = string
  }))
  default = []
}

variable "enable_firewall" {
  description = "Enable firewall configuration"
  type        = bool
  default     = true
}

variable "allowed_ports" {
  description = "Allowed inbound ports"
  type        = list(object({
    port     = number
    protocol = string
    source   = string
  }))
  default = [
    {
      port     = 22
      protocol = "tcp"
      source   = "192.168.1.0/24"
    },
    {
      port     = 32400
      protocol = "tcp"
      source   = "0.0.0.0/0"
    }
  ]
}

variable "trusted_networks" {
  description = "Trusted network subnets"
  type        = list(string)
  default     = ["192.168.1.0/24"]
}

variable "enable_monitoring" {
  description = "Enable network monitoring"
  type        = bool
  default     = true
}

variable "network_devices" {
  description = "Network devices to monitor"
  type        = list(string)
  default     = ["192.168.1.1:161"] # SNMP
}


