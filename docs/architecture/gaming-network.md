# Gaming Console Network Configuration Guide

## Overview

This guide provides network optimization recommendations for PlayStation 5 and Nintendo Switch to ensure optimal gaming performance on your home network.

## Console Inventory

- **PlayStation 5 (PS5)**: PlayStation Plus membership services
- **Nintendo Switch**: Online gaming and services

## Network Requirements

### PlayStation 5 Requirements

**Port Forwarding:**
- **TCP**: 1935, 3478-3480, 443, 465, 993, 3478, 3479, 3480
- **UDP**: 3478-3480, 9307-9308, 49152-65535
- **Primary Ports**: 9307-9308 (UDP), 1935 (TCP), 3478-3480 (TCP/UDP)

**Bandwidth Requirements:**
- **Minimum**: 3 Mbps download, 1 Mbps upload
- **Recommended**: 15+ Mbps download, 5+ Mbps upload
- **Optimal**: 25+ Mbps download, 10+ Mbps upload
- **For 2GB connection**: No bandwidth concerns, focus on latency

**NAT Type:**
- **Type 1 (Open)**: Best - Direct connection to internet
- **Type 2 (Moderate)**: Good - Behind router with UPnP
- **Type 3 (Strict)**: Poor - May have connectivity issues

### Nintendo Switch Requirements

**Port Forwarding:**
- **TCP**: 6667, 12400, 28910, 29900-29901, 1024-65535
- **UDP**: 1-65535 (all UDP ports)
- **Primary Ports**: 1024-65535 (TCP/UDP)

**Bandwidth Requirements:**
- **Minimum**: 1 Mbps download, 1 Mbps upload
- **Recommended**: 3+ Mbps download, 1+ Mbps upload
- **Optimal**: 10+ Mbps download, 3+ Mbps upload

**NAT Type:**
- **Type A (Open)**: Best - Full connectivity
- **Type B (Moderate)**: Good - Most features work
- **Type C (Strict)**: Limited - Some features may not work
- **Type D (Fail)**: Poor - Limited connectivity

## Network Configuration

### Recommended VLAN Placement

**Gaming VLAN (192.168.10.0/24) - Media & Gaming Network**

Place gaming consoles on the Media/Gaming VLAN, not the IoT VLAN:
- Better QoS prioritization
- Can access media services (Plex, NAS) if needed
- Separate from IoT devices
- Better security posture

### QoS Configuration

**Priority Level: High**

Gaming requires low latency and consistent performance. Configure QoS to prioritize gaming traffic:

**Bandwidth Allocation:**
```
Gaming Traffic (PS5 + Switch):
- Guaranteed: 20% of total bandwidth
- Maximum: 40% of total bandwidth
- Priority: High (second only to critical services)
```

**QoS Rules:**
1. **PS5 Traffic**: Prioritize ports 9307-9308 (UDP), 3478-3480 (TCP/UDP)
2. **Switch Traffic**: Prioritize ports 1024-65535 (TCP/UDP)
3. **Game Downloads**: Lower priority than active gameplay (can throttle during downloads)

### Port Forwarding Setup

#### PlayStation 5 Port Forwarding

**Option 1: UPnP (Recommended if supported)**
- Enable UPnP on router for gaming VLAN
- PS5 will automatically configure ports
- Easier setup, dynamic port assignment

**Option 2: Manual Port Forwarding**
```
Protocol: UDP
External Port: 9307-9308
Internal IP: <PS5_IP_ADDRESS>
Internal Port: 9307-9308

Protocol: TCP
External Port: 1935
Internal IP: <PS5_IP_ADDRESS>
Internal Port: 1935

Protocol: TCP/UDP
External Port: 3478-3480
Internal IP: <PS5_IP_ADDRESS>
Internal Port: 3478-3480
```

#### Nintendo Switch Port Forwarding

**Option 1: UPnP (Recommended)**
- Enable UPnP on router for gaming VLAN
- Switch will automatically configure ports

**Option 2: Manual Port Forwarding**
```
Protocol: UDP
External Port: 1-65535
Internal IP: <SWITCH_IP_ADDRESS>
Internal Port: 1-65535

Protocol: TCP
External Port: 6667, 12400, 28910, 29900-29901
Internal IP: <SWITCH_IP_ADDRESS>
Internal Port: 6667, 12400, 28910, 29900-29901

Protocol: TCP
External Port: 1024-65535
Internal IP: <SWITCH_IP_ADDRESS>
Internal Port: 1024-65535
```

**Security Note**: Wide port ranges (especially 1-65535 UDP for Switch) should only be on gaming VLAN, not management network.

### Static IP Assignment

**Recommendation**: Assign static IPs to gaming consoles for port forwarding consistency.

**PS5 Static IP**: 192.168.10.50
**Switch Static IP**: 192.168.10.51

**Configuration Methods:**
1. **Router DHCP Reservation** (Recommended)
   - Configure in router admin panel
   - Bind MAC address to IP address
   - Ensures consistent IP assignment

2. **Static IP on Console** (Alternative)
   - Configure on console itself
   - Must match router subnet and gateway
   - Ensure IP is outside DHCP range

### NAT Configuration

**Goal**: Achieve Type 1/Type 2 NAT for PS5, Type A/Type B for Switch

**Configuration Steps:**
1. Enable UPnP on router (for gaming VLAN)
2. Configure port forwarding (if UPnP not available)
3. Place console on DMZ (temporary test only, not recommended for security)
4. Test NAT type in console network settings

**If NAT Type is Strict (Type 3):**
- Check firewall rules (allow gaming ports)
- Verify UPnP is enabled
- Check for double NAT (configure bridge mode)
- Verify port forwarding is correct
- Test with console in DMZ (temporary)

## Performance Optimization

### Latency Optimization

**Wired Connection (Recommended):**
- Use Ethernet cable for PS5 (if available)
- Reduces latency vs WiFi
- More stable connection
- No interference issues

**WiFi Optimization (If Wired Not Available):**
- Use 5GHz band (lower latency than 2.4GHz)
- Position console near router/mesh node
- Use dedicated gaming SSID (optional)
- Enable QoS on WiFi (WMM)
- Minimize interference

### Bandwidth Optimization

**During Active Gaming:**
- Prioritize gaming traffic
- Limit background downloads
- Pause media streaming if needed
- Close unnecessary network applications

**During Downloads:**
- Downloads can use lower priority
- Throttle downloads during active gaming
- Schedule large downloads during off-peak hours
- Pause downloads during multiplayer sessions

### Router Settings

**Enable:**
- UPnP (for automatic port configuration)
- QoS/WMM (for traffic prioritization)
- IPv6 (if supported by ISP)
- Port forwarding (if UPnP not working)

**Disable:**
- SIP ALG (can interfere with gaming)
- SPI Firewall strict mode (may block legitimate traffic)
- Deep packet inspection on gaming VLAN

## Network Troubleshooting

### PS5 Network Issues

**Cannot Connect to PSN:**
1. Test internet connectivity
2. Check PSN status (https://status.playstation.com)
3. Verify DNS settings (try 8.8.8.8, 1.1.1.1)
4. Check firewall rules
5. Test NAT type

**NAT Type 3 (Strict):**
1. Enable UPnP on router
2. Configure port forwarding
3. Check for double NAT
4. Verify firewall allows gaming ports
5. Test with DMZ (temporary)

**Poor Download Speeds:**
1. Check bandwidth availability
2. Verify QoS settings
3. Pause other downloads/streams
4. Test with wired connection
5. Check router CPU usage

**High Latency/Lag:**
1. Use wired connection
2. Check network congestion
3. Verify QoS prioritization
4. Test during off-peak hours
5. Check for interference (WiFi)

### Switch Network Issues

**Cannot Connect Online:**
1. Test internet connectivity
2. Check Nintendo Online status
3. Verify DNS settings
4. Check firewall rules
5. Test NAT type

**NAT Type C or D:**
1. Enable UPnP on router
2. Configure port forwarding (wide range needed)
3. Check for double NAT
4. Verify firewall allows gaming ports
5. Consider DMZ (temporary test)

**Connection Errors:**
1. Check error code (Nintendo support)
2. Verify port forwarding
3. Test with different network
4. Update console firmware
5. Reset network settings

### General Troubleshooting

**Test Network Performance:**
```bash
# Test latency to gaming servers
ping -c 10 <gaming_server_ip>

# Test bandwidth
speedtest-cli

# Check for packet loss
mtr <gaming_server_ip>

# Monitor network traffic
iftop
```

**Common Issues:**
1. **Double NAT**: Configure bridge mode on secondary router
2. **Port Conflicts**: Ensure ports not used by other devices
3. **Firewall Blocking**: Verify firewall rules allow gaming traffic
4. **QoS Misconfiguration**: Check QoS priority settings
5. **Network Congestion**: Monitor bandwidth during gaming

## Security Considerations

### Network Isolation

**Gaming VLAN Security:**
- Isolated from management network
- Can access media services if needed
- No access to IoT/security cameras
- Internet access required

### Firewall Rules

**Allow (Outbound):**
- Gaming ports (as configured above)
- HTTPS (for updates, store access)
- DNS
- NTP (time sync)

**Block (Inbound):**
- All unsolicited inbound traffic
- Only allow established connections

### Best Practices

1. **Keep Consoles Updated**: Regular firmware updates
2. **Strong Account Security**: Enable 2FA on PSN and Nintendo accounts
3. **Review Privacy Settings**: Limit data sharing
4. **Monitor Network Activity**: Watch for unusual traffic
5. **Regular Security Audits**: Review firewall rules and access

## Monitoring

### Key Metrics to Monitor

**Network Performance:**
- Latency to gaming servers
- Packet loss percentage
- Bandwidth usage during gaming
- Connection stability

**QoS Effectiveness:**
- Gaming traffic priority
- Bandwidth allocation
- Congestion during peak hours
- Impact on other services

### Monitoring Tools

- **Router Admin Panel**: Check connected devices, bandwidth usage
- **Prometheus/Grafana**: Monitor network metrics (if configured)
- **Console Network Tests**: Built-in connection tests
- **External Tools**: Speedtest, ping tests, traceroute

## Maintenance

### Regular Tasks

**Weekly:**
- Test network connection quality
- Check for firmware updates
- Review QoS effectiveness

**Monthly:**
- Full network performance test
- Review port forwarding configuration
- Check for security updates
- Monitor bandwidth usage patterns

**Quarterly:**
- Complete network audit
- Review and optimize QoS settings
- Test NAT configuration
- Review firewall rules

## Resources

- [PlayStation Network Status](https://status.playstation.com)
- [Nintendo Network Status](https://www.nintendo.com/switch/online-service/status/)
- [PlayStation Network Ports](https://www.playstation.com/en-us/support/hardware/network-ports-used-by-ps4/)
- [Nintendo Switch Online Support](https://en-americas-support.nintendo.com/app/answers/detail/a_id/22381)



