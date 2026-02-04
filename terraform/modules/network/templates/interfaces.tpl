# Home Lab Network Interface Configuration
# Managed by Terraform - DO NOT EDIT MANUALLY

auto ${interface}
iface ${interface} inet static
    address ${ip_address}/${netmask}
    gateway ${gateway}
    dns-nameservers ${dns_servers}

# VLAN interfaces (if configured)
%{ if enable_vlans ~}
%{ for vlan in vlans ~}
auto ${interface}.${vlan.id}
iface ${interface}.${vlan.id} inet static
    address ${vlan.ip_address}
    netmask ${vlan.netmask}
    vlan-raw-device ${interface}
%{ endfor ~}
%{ endif ~}


