# Security Camera & IoT Network Security Guide

## Overview

This guide provides specific security recommendations for your security camera and IoT device setup, including Nest cameras, Eufy cameras, and the Abode security system.

## Device Inventory

### Security Cameras
- **1x Nest Outdoor WiFi Camera**
- **2x Nest Indoor WiFi Cameras**
- **2x Eufy Outdoor WiFi Cameras** (connected to Homebase hub)

### Security System
- **Abode Security System**
  - 2 motion sensors
  - 5 entry point monitors (doors/windows)

### Network Requirements

**Nest Cameras:**
- Require continuous internet connectivity
- Upload video to Google cloud storage
- Typical bandwidth: 1-4 Mbps per camera (upload)
- Uses standard HTTPS/WebRTC protocols

**Eufy Cameras:**
- Connect to Homebase hub via WiFi
- Can use local storage (Homebase) or cloud storage
- Homebase requires internet for remote access
- Typical bandwidth: 1-4 Mbps per camera (varies by quality)

**Abode Security System:**
- Gateway connects via Ethernet or WiFi
- Sensors communicate wirelessly to gateway
- Requires internet for monitoring services
- Minimal bandwidth requirements (<1 Mbps)

## Network Architecture Recommendations

### VLAN Segmentation

**Recommended: IoT & Security VLAN (192.168.20.0/24)**

```
┌─────────────────────────────────────────┐
│     IoT & Security VLAN (Isolated)      │
│         192.168.20.0/24                 │
├─────────────────────────────────────────┤
│  • Nest Cameras (3x)                    │
│  • Eufy Cameras + Homebase (2x)         │
│  • Abode Security System                │
│  • Smart Plugs/Bulbs                    │
│  • Other IoT Devices                    │
│                                         │
│  Internet Access: ✓                     │
│  Management Network Access: ✗           │
│  Media Network Access: ✗                │
└─────────────────────────────────────────┘
```

### Firewall Rules

**IoT/Security VLAN Firewall Configuration:**

```bash
# Allow outbound HTTPS (for cloud services)
iptables -A FORWARD -s 192.168.20.0/24 -d 0.0.0.0/0 -p tcp --dport 443 -j ACCEPT

# Allow outbound DNS
iptables -A FORWARD -s 192.168.20.0/24 -d 0.0.0.0/0 -p udp --dport 53 -j ACCEPT

# Allow outbound NTP (time sync)
iptables -A FORWARD -s 192.168.20.0/24 -d 0.0.0.0/0 -p udp --dport 123 -j ACCEPT

# Block all inter-VLAN traffic
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.1.0/24 -j DROP
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.10.0/24 -j DROP

# Block all inbound connections
iptables -A FORWARD -d 192.168.20.0/24 -j DROP

# Log blocked attempts (for monitoring)
iptables -A FORWARD -s 192.168.20.0/24 -j LOG --log-prefix "IoT-Blocked: "
```

## Camera-Specific Security

### Nest Camera Security

**Account Security:**
1. **Enable 2FA** on Google account
   - Use authenticator app (not SMS)
   - Backup recovery codes securely

2. **Strong Password**
   - Unique password for Google account
   - Use password manager
   - Minimum 16 characters

3. **Review Account Access**
   - Check who has access to Nest cameras
   - Remove unnecessary users
   - Review activity log regularly

**Camera Settings:**
1. **Privacy Zones**
   - Configure to avoid recording private areas
   - Review and adjust as needed

2. **Recording Settings**
   - Disable audio recording if not needed
   - Adjust motion detection sensitivity
   - Set appropriate recording quality

3. **Sharing Settings**
   - Limit who can view cameras
   - Disable public sharing
   - Review sharing permissions regularly

4. **Notifications**
   - Configure motion alerts appropriately
   - Avoid notification fatigue
   - Use facial recognition if available (privacy trade-off)

**Network Configuration:**
- Connect to isolated IoT VLAN
- Use strong WiFi password (WPA2/WPA3)
- Disable camera access from internet (use Nest app only)
- Monitor bandwidth usage

### Eufy Camera Security

**Homebase Security:**
1. **Change Default Password**
   - Set strong, unique password
   - Change immediately after setup
   - Store in password manager

2. **Enable Encryption**
   - Enable encryption on Homebase
   - Use local storage encryption if available
   - Secure Homebase physical location

3. **Firmware Updates**
   - Enable automatic updates
   - Check for updates monthly
   - Review release notes for security patches

**Camera Configuration:**
1. **WiFi Security**
   - Use dedicated SSID for cameras (recommended)
   - Strong WPA2/WPA3 password
   - Hide SSID if possible (minimal security benefit)

2. **Storage Configuration**
   - Prefer local storage over cloud (privacy)
   - Enable encryption for local storage
   - Regular backup of important recordings

3. **Motion Detection**
   - Configure sensitivity appropriately
   - Set activity zones
   - Reduce false alarms

**Remote Access:**
- Use Eufy app for remote access (secure)
- Avoid exposing Homebase to internet directly
- Review remote access logs
- Disable if not needed

### Abode Security System Security

**Gateway Security:**
1. **Change Default Credentials**
   - Change admin password immediately
   - Use strong, unique password
   - Enable 2FA on Abode account

2. **Physical Security**
   - Secure gateway placement
   - Not easily accessible to intruders
   - Consider tamper alerts

3. **Network Configuration**
   - Connect via Ethernet if possible (more reliable)
   - Use strong WiFi password if wireless
   - Place on IoT VLAN (isolated)

**Sensor Configuration:**
1. **Motion Sensors**
   - Configure sensitivity
   - Set appropriate detection zones
   - Test regularly

2. **Entry Point Monitors**
   - Test each sensor regularly
   - Check battery levels
   - Review tamper detection settings

3. **Monitoring Service**
   - Review monitoring plan
   - Test alarm system monthly
   - Verify emergency contact information

**App Security:**
- Enable 2FA on Abode account
- Review app permissions
- Monitor access logs
- Disable remote access if not needed

## Network Bandwidth Considerations

### Bandwidth Requirements

**Per Camera:**
- **Nest Cameras**: 1-4 Mbps upload (continuous)
- **Eufy Cameras**: 1-4 Mbps upload (varies by quality)
- **Total Camera Upload**: ~5-20 Mbps (depending on quality settings)

**Impact on Network:**
- Continuous upload can affect other devices
- Configure QoS to limit camera bandwidth
- Consider reducing video quality during off-peak hours
- Monitor total bandwidth usage

### QoS Configuration for Cameras

**Recommended Settings:**
```
Camera Traffic Priority: Medium (not high priority)
Maximum Upload Bandwidth: 15 Mbps total for all cameras
Guaranteed Upload Bandwidth: 5 Mbps (ensures cameras work)
```

**Configuration Example:**
- Limit total camera upload to 50% of upload bandwidth
- Ensure cameras have minimum bandwidth guarantee
- Lower priority than gaming/streaming
- Higher priority than background syncs

## Privacy Considerations

### Recording Privacy

**Best Practices:**
1. **Privacy Zones**: Configure to avoid private areas
2. **Audio Recording**: Disable if not needed
3. **Indoor Cameras**: Review placement and angles
4. **Notification Settings**: Balance security with privacy
5. **Storage Retention**: Review and limit retention periods

### Access Control

**Who Should Have Access:**
- Limit to household members only
- Remove access for former residents
- Review access logs regularly
- Use strong authentication (2FA)

**Sharing:**
- Avoid public sharing
- Be cautious with temporary access
- Review shared links regularly
- Use time-limited access when possible

## Monitoring & Maintenance

### Regular Tasks

**Weekly:**
- Review camera feeds for functionality
- Check for firmware updates
- Review motion detection events

**Monthly:**
- Test all cameras and sensors
- Review access logs
- Check bandwidth usage
- Update firmware
- Review privacy settings

**Quarterly:**
- Full security audit
- Review and update firewall rules
- Check for security advisories
- Test backup/restore procedures
- Review and clean up old recordings

### Monitoring Checklist

- [ ] All cameras online and recording
- [ ] Motion detection working correctly
- [ ] Alerts/notifications functioning
- [ ] Storage space adequate (cloud or local)
- [ ] Bandwidth usage within limits
- [ ] No unauthorized access attempts
- [ ] Firmware up to date
- [ ] Privacy settings appropriate
- [ ] Access logs reviewed
- [ ] Backup procedures tested

## Troubleshooting

### Common Issues

**Cameras Going Offline:**
1. Check WiFi connectivity
2. Verify router/mesh node placement
3. Check for interference
4. Review router logs
5. Restart camera/Homebase

**Poor Video Quality:**
1. Check bandwidth availability
2. Verify WiFi signal strength
3. Adjust video quality settings
4. Check for network congestion
5. Review QoS settings

**High Bandwidth Usage:**
1. Reduce video quality
2. Limit number of active streams
3. Configure QoS limits
4. Check for bandwidth hogs
5. Review camera settings

**Connection Issues:**
1. Check firewall rules
2. Verify VLAN configuration
3. Test internet connectivity
4. Review DNS settings
5. Check for blocked ports

## Security Incident Response

### If Camera is Compromised

1. **Immediate Actions:**
   - Disconnect camera from network
   - Change account passwords
   - Review access logs
   - Check for unauthorized access

2. **Investigation:**
   - Review camera logs
   - Check network traffic logs
   - Identify compromise vector
   - Document findings

3. **Recovery:**
   - Factory reset camera
   - Reconfigure with secure settings
   - Restore from known good configuration
   - Update all credentials

4. **Prevention:**
   - Update firmware
   - Review security settings
   - Strengthen network security
   - Enhance monitoring

## Resources

- [Nest Camera Security](https://support.google.com/googlenest/answer/7072285)
- [Eufy Security Center](https://support.eufylife.com/)
- [Abode Security Support](https://support.goabode.com/)
- [IoT Security Best Practices](https://www.nist.gov/itl/applied-cybersecurity/nist-cybersecurity-iot-program)



