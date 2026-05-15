# Troubleshooting Guide

## Critical Issues Resolution

### Issue 1: Desktop Media Server Boot Errors

#### Symptoms
- System fails to boot properly
- Error messages during startup
- Services don't start after boot

#### Diagnostic Steps
   ```bash
# Check system logs for boot errors
journalctl -b -p err

   # Check disk health
smartctl -a /dev/sda

# Check filesystem integrity
fsck -f /dev/sda1

# Check memory issues
memtest86+

# Check CPU temperature
sensors
```

#### Common Causes & Solutions

**Hardware Issues:**
- **Faulty RAM**: Test with memtest86+, replace if faulty
- **Hard Drive Failure**: Check SMART status, replace drive
- **Power Supply Issues**: Test PSU voltages, replace if unstable
- **CPU Overheating**: Check cooling, clean dust, replace thermal paste

**Software Issues:**
- **Corrupted Boot Loader**: Reinstall GRUB
```bash
sudo grub-install /dev/sda
sudo update-grub
```
- **Filesystem Corruption**: Run filesystem check
- **Driver Issues**: Update or reinstall problematic drivers

#### Recovery Procedures
```bash
# Boot into recovery mode
# Mount filesystem
mount /dev/sda1 /mnt

# Chroot into system
chroot /mnt

# Fix issues, then reboot
exit
reboot
```

### Issue 2: Plex Performance Issues

#### Symptoms
- Video playback lag or stuttering
- "Playback error" messages
- Slow loading of media libraries
- Transcoding failures

#### Performance Diagnostics
   ```bash
# Check Plex logs
tail -f /var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server/Logs/Plex\ Media\ Server.log

# Check system resources during playback
top -p $(pgrep plex)
iostat -x 1
   free -h

# Check network connectivity
ping -c 5 <plex_server_ip>
iperf3 -c <client_ip> -t 10

# Check Docker resource usage
docker stats
```

#### Optimization Steps

**Server-Side Optimizations:**
1. **Hardware Transcoding**: Enable Intel Quick Sync or NVIDIA GPU transcoding
2. **RAM Allocation**: Ensure sufficient RAM for transcoding (4GB+ recommended)
3. **Storage I/O**: Use SSD for Plex metadata, optimize library locations
4. **Network Tuning**: Enable Jumbo frames, optimize MTU

**Network Optimizations:**
1. **QoS Configuration**: Prioritize Plex traffic on router
2. **Port Forwarding**: Ensure proper port forwarding (32400)
3. **Firewall Rules**: Allow Plex traffic through firewall
4. **DNS Resolution**: Ensure fast DNS resolution

**Client-Side Issues:**
1. **Client Device Performance**: Check client device capabilities
2. **Network Speed**: Test client bandwidth
3. **Client App Updates**: Ensure latest Plex client version

#### Advanced Plex Tuning
```yaml
# docker-compose.yml Plex configuration
plex:
  image: plexinc/pms-docker
  environment:
    - PLEX_CLAIM=<claim_token>
    - PLEX_UID=1000
    - PLEX_GID=1000
    - TZ=America/New_York
  volumes:
    - /path/to/plex/database:/config
    - /path/to/media:/data
    - /path/to/transcode:/transcode
  ports:
    - "32400:32400/tcp"
devices:
    - /dev/dri:/dev/dri  # Hardware transcoding
  restart: unless-stopped
```

### Issue 3: Network Performance Problems

#### Symptoms
- Slow internet speeds
- WiFi disconnects
- High latency
- Packet loss

#### Network Diagnostics
   ```bash
# Internet speed test
   speedtest-cli

# Network latency and loss
ping -c 100 8.8.8.8
mtr google.com

# WiFi diagnostics
iwconfig
iwlist scan
wpa_cli status

# Router diagnostics
# Access router admin interface
# Check connected devices
# Review DHCP leases
# Check signal strength
```

#### Router Configuration Issues

**Double NAT Problems:**
- Put secondary router in bridge/AP mode
- Disable DHCP on secondary router
- Connect via LAN port, not WAN

**WiFi Interference:**
- Change WiFi channels (1, 6, 11 for 2.4GHz)
- Avoid channel overlap
- Reduce transmit power if too strong
- Use 5GHz for less interference

**QoS Configuration:**
```bash
# Example QoS setup (router-specific)
# Prioritize Plex traffic
# Limit bandwidth for background tasks
# Reserve bandwidth for VoIP/critical services
```

### Issue 5: Security Camera Performance Issues

#### Symptoms
- Cameras disconnecting from network
- Poor video quality or buffering
- Motion detection failures
- Storage issues on security systems

#### Camera-Specific Diagnostics
```bash
# Check camera connectivity
ping <camera_ip>

# Test camera web interface (if accessible)
curl -I http://<camera_ip>

# Check network bandwidth usage
iperf3 -c <camera_ip> -t 10
```

#### System-Specific Solutions

**Nest Cameras:**
- Check Google Home app for connectivity issues
- Verify Nest Aware subscription status
- Reset camera if unresponsive
- Check WiFi signal strength at camera location

**Eufy Cameras:**
- Check Homebase connectivity and LED status
- Verify local storage on Homebase
- Update Homebase and camera firmware
- Check Eufy app for system status

**Abode Security:**
- Check Abode app for system status
- Verify sensor battery levels
- Test entry point monitors
- Check cellular backup if applicable

#### Network Solutions for Cameras
- Ensure cameras are on dedicated VLAN
- Prioritize camera traffic with QoS
- Use wired connection when possible
- Optimize WiFi channels for camera locations

### Issue 6: Gaming Device Connectivity Issues

#### Symptoms
- PS5 disconnecting from PlayStation Network
- Nintendo Switch online service failures
- High latency during gaming
- Connection drops during gameplay

#### Gaming Device Diagnostics
```bash
# Test gaming device connectivity
ping <gaming_device_ip>

# Check DNS resolution for gaming services
nslookup playstation.net  # For PS5
nslookup nintendo.net     # For Switch

# Test port connectivity for gaming services
# PS5: Ports 80, 443, 1935, 3478-3480
# Switch: Ports 80, 443, 6667, 12400, 28910
```

#### Gaming Optimization
- Set up gaming QoS rules on router
- Use wired connection for gaming devices when possible
- Optimize DNS settings for gaming
- Monitor network latency and packet loss

### Issue 4: Power Protection (No UPS)

#### Immediate Actions
1. **Purchase UPS**: APC Back-UPS or CyberPower recommended
2. **Size Calculation**: Calculate VA rating needed
   - Media Server: ~500W
   - NAS: ~100W
   - Router/Switches: ~50W
   - **Total**: ~650W + 20% buffer = 780W minimum
3. **Runtime Requirements**: 15-30 minutes runtime needed

#### UPS Configuration
```bash
# Install monitoring software
sudo apt install apcupsd

# Configure apcupsd
sudo nano /etc/apcupsd/apcupsd.conf
# Set UPS type, device, and notification settings

# Configure shutdown scripts
sudo nano /etc/apcupsd/apccontrol
# Add graceful shutdown for Docker services
```

### General System Health Checks

#### Daily Health Monitoring
```bash
#!/bin/bash
# System health check script

echo "=== System Health Check ==="
echo "Date: $(date)"

# CPU Usage
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)"

# Memory Usage
echo "Memory Usage:"
free -h

# Disk Usage
echo "Disk Usage:"
df -h

# Network Interfaces
echo "Network Status:"
ip addr show

# Docker Services
echo "Docker Services:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Service Status
echo "Critical Services:"
systemctl status plexmediaserver prometheus grafana-server
```

#### Automated Monitoring Setup
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **Alertmanager**: Notification system
- **Node Exporter**: System metrics
- **cAdvisor**: Docker metrics

## Emergency Procedures

### Complete System Failure
1. **Power Cycle**: Unplug all devices, wait 30 seconds, restart in order
2. **Check Connections**: Verify all cables and power supplies
3. **Boot Diagnostics**: Use live USB to test hardware
4. **Data Recovery**: Mount drives externally if needed

### Data Loss Recovery
1. **Assess Damage**: Determine scope of data loss
2. **Backup Verification**: Check backup integrity
3. **Restore Procedures**: Follow documented restore process
4. **Service Restoration**: Bring services back online

### Network Outage
1. **ISP Status**: Check Comcast service status
2. **Modem Reset**: Power cycle modem (wait 2 minutes)
3. **Router Reset**: Reset router to factory, reconfigure
4. **Device Isolation**: Test each device individually

## Prevention Measures

### Regular Maintenance
- **Weekly**: System updates, log review
- **Monthly**: Full backup verification, security scans
- **Quarterly**: Hardware cleaning, cable inspection
- **Annually**: Hardware replacement planning

### Proactive Monitoring
- **Set up alerts** for critical metrics
- **Monitor trends** for capacity planning
- **Regular testing** of backup restores
- **Performance baselines** for comparison

## Getting Help

### Documentation Resources
- [Plex Troubleshooting](https://support.plex.tv/)
- [Docker Documentation](https://docs.docker.com/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Network+ Study Guide](https://www.comptia.org/certifications/network)

### Community Support
- **Reddit**: r/homelab, r/Plex, r/docker
- **Discord**: Various homelab communities
- **Forums**: Plex forums, Docker forums

### Professional Services
- **Local Tech Support**: For hardware issues
- **Network Specialists**: For complex network issues
- **Data Recovery Services**: For critical data loss