# Network Configuration Module
# Manages network settings, DHCP, DNS, and VLAN configuration

# Network interface configuration
resource "local_file" "network_interfaces" {
  filename = "/etc/network/interfaces.d/homelab"
  content = templatefile("${path.module}/templates/interfaces.tpl", {
    interface    = var.interface
    ip_address   = var.ip_address
    netmask      = var.netmask
    gateway      = var.gateway
    dns_servers  = join(" ", var.dns_servers)
  })
}

# DHCP configuration
resource "local_file" "dhcpd_conf" {
  filename = "/etc/dhcp/dhcpd.conf"
  content = templatefile("${path.module}/templates/dhcpd.conf.tpl", {
    subnet       = var.subnet
    netmask      = var.netmask
    range_start  = var.dhcp_range[0]
    range_end    = var.dhcp_range[1]
    gateway      = var.gateway
    dns_servers  = var.dns_servers
    domain_name  = var.domain_name
  })
}

# DNS configuration
resource "local_file" "named_conf" {
  filename = "/etc/bind/named.conf.local"
  content = templatefile("${path.module}/templates/named.conf.tpl", {
    domain_name = var.domain_name
    subnet      = var.subnet
  })
}

# DNS zone file
resource "local_file" "zone_file" {
  filename = "/var/lib/bind/db.${var.domain_name}"
  content = templatefile("${path.module}/templates/zone.tpl", {
    domain_name = var.domain_name
    nameservers = var.dns_servers
    records     = var.dns_records
  })
}

# Firewall rules
resource "local_file" "firewall_rules" {
  filename = "/etc/iptables/rules.v4"
  content = templatefile("${path.module}/templates/iptables.tpl", {
    allowed_ports = var.allowed_ports
    trusted_networks = var.trusted_networks
  })
}

# VLAN configuration (if supported)
resource "local_file" "vlan_config" {
  count    = var.enable_vlans ? 1 : 0
  filename = "/etc/network/interfaces.d/vlans"
  content = templatefile("${path.module}/templates/vlans.tpl", {
    vlans = var.vlan_config
  })
}

# Network monitoring
resource "local_file" "network_monitoring" {
  filename = "/etc/prometheus/network.yml"
  content = yamlencode({
    scrape_configs = [
      {
        job_name = "network_devices"
        static_configs = [
          {
            targets = var.network_devices
          }
        ]
        scrape_interval = "60s"
      }
    ]
  })
}

# Generate network configuration report
resource "local_file" "network_report" {
  filename = "${path.module}/network_config_report.txt"
  content = <<EOF
Home Lab Network Configuration Report
====================================

Generated: ${timestamp()}

Network Settings:
- Interface: ${var.interface}
- IP Address: ${var.ip_address}/${var.netmask}
- Gateway: ${var.gateway}
- DNS Servers: ${join(", ", var.dns_servers)}
- Domain: ${var.domain_name}

DHCP Configuration:
- Subnet: ${var.subnet}/${var.netmask}
- Range: ${var.dhcp_range[0]} - ${var.dhcp_range[1]}

VLAN Configuration: ${var.enable_vlans ? "Enabled" : "Disabled"}
${var.enable_vlans ? "- VLANs: ${join(", ", [for v in var.vlan_config : "${v.name}(${v.id})"])}" : ""}

Firewall Status: ${var.enable_firewall ? "Enabled" : "Disabled"}
Network Monitoring: ${var.enable_monitoring ? "Enabled" : "Disabled"}

DNS Records:
${join("\n", [for k, v in var.dns_records : "- ${k} -> ${v}"])}

EOF
}


