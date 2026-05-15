# Network Unification Checklist

## Pre-Migration Planning

### Current Network Documentation

**Network 1: Xfinity Xfi + Eero (10.0.0.0/8)**
- [ ] Document all devices on this network
- [ ] List current IP addresses
- [ ] Note any static IP configurations
- [ ] Document WiFi credentials (SSID, password)
- [ ] Note any port forwarding rules

**Network 2: Asus Nighthawk (192.168.1.0/24)**
- [ ] Document all devices on this network
  - [ ] Media server IP: _____________
  - [ ] NAS IP: _____________
  - [ ] External drive: _____________
- [ ] List current IP addresses
- [ ] Note any static IP configurations
- [ ] Document WiFi credentials (SSID, password)
- [ ] Note any port forwarding rules

### Backup Current Configuration

- [ ] Backup Asus router configuration (save to file)
- [ ] Screenshot current network settings from both routers
- [ ] Document current port forwarding rules
- [ ] Save current DHCP reservations
- [ ] Note current QoS settings

## Migration Steps

### Phase 1: Prepare for Migration

- [ ] **Choose migration time** (schedule during low-usage period)
- [ ] **Notify users** (if others use the network)
- [ ] **Backup critical data** from NAS/media server
- [ ] **Have backup plan** (know how to revert if needed)

### Phase 2: Configure Xfinity Xfi (Bridge Mode)

- [ ] Access Xfinity Xfi admin: http://10.0.0.1
- [ ] Login with Xfinity credentials
- [ ] Navigate to: Gateway > At a Glance
- [ ] Click "Enable Bridge Mode"
- [ ] Confirm the change
- [ ] **Note**: WiFi on Xfi will be disabled
- [ ] Wait for router to restart
- [ ] Verify bridge mode is active

**Troubleshooting:**
- If bridge mode option not available, contact Xfinity support
- Some Xfinity gateways require support to enable bridge mode

### Phase 3: Configure Asus Nighthawk (Primary Router)

- [ ] Access Asus admin: http://192.168.1.1
- [ ] Login with admin credentials

**WAN Configuration:**
- [ ] Set WAN Connection Type: Automatic IP (DHCP)
- [ ] Connect Ethernet cable from Xfinity Xfi to Asus WAN port
- [ ] Verify Asus gets IP address from Xfinity
- [ ] Test internet connectivity from Asus router

**LAN Configuration:**
- [ ] Verify LAN IP: 192.168.1.1
- [ ] Verify Subnet: 255.255.255.0 (/24)
- [ ] Enable DHCP Server
- [ ] Set DHCP Range: 192.168.1.100 - 192.168.1.200
- [ ] Set Gateway: 192.168.1.1
- [ ] Set DNS: 1.1.1.1, 8.8.8.8 (or preferred DNS)

**WiFi Configuration (if using Asus WiFi):**
- [ ] Configure 2.4GHz SSID and password
- [ ] Configure 5GHz SSID and password
- [ ] Set security: WPA2/WPA3
- [ ] Enable WiFi

**Static IP Reservations (Critical Devices):**
- [ ] Media Server: 192.168.1.11
- [ ] NAS: 192.168.1.20
- [ ] Add other critical devices as needed

### Phase 4: Configure Eero (Access Point Mode)

- [ ] Open Eero app (ensure you're connected to Eero network)
- [ ] Navigate to: Settings > Network Settings > Advanced Settings
- [ ] Enable "Bridge Mode" or "Access Point Mode"
- [ ] Confirm the change
- [ ] Wait for Eero to restart

**Physical Connection:**
- [ ] Connect Eero gateway to Asus router via Ethernet
- [ ] Use LAN port on Eero (not WAN port)
- [ ] Verify Eero connects to Asus network
- [ ] Check Eero app for status

**Eero Node Configuration:**
- [ ] Verify all Eero nodes connect to gateway
- [ ] Test WiFi coverage
- [ ] Verify nodes extend 192.168.1.0/24 network

### Phase 5: Migrate Devices

**Devices on 10.0.0.0/8 Network (need to reconnect):**
- [ ] All Eero-connected devices (automatically migrate)
- [ ] Security cameras (reconnect to new network)
- [ ] IoT devices (reconnect to new network)
- [ ] Gaming consoles (reconnect to new network)
- [ ] Mobile devices, tablets, phones (reconnect)
- [ ] TVs and streaming devices (reconnect)

**Devices on 192.168.1.0/24 Network (should still work):**
- [ ] Media server (verify connectivity)
- [ ] NAS (verify connectivity)
- [ ] External drive (verify connectivity)
- [ ] Any other devices connected to Asus

**Update Static IPs (if needed):**
- [ ] Check if any devices had static IPs on 10.0.0.0/8
- [ ] Update to 192.168.1.x range
- [ ] Configure in device settings or router DHCP reservations

## Post-Migration Verification

### Connectivity Tests

- [ ] **Gateway Connectivity:**
  ```bash
  ping 192.168.1.1
  # Should succeed from all devices
  ```

- [ ] **Device-to-Device Connectivity:**
  ```bash
  ping <media_server_ip>
  ping <nas_ip>
  # Should work from any device
  ```

- [ ] **Internet Connectivity:**
  ```bash
  ping 8.8.8.8
  ping google.com
  # Should work from all devices
  ```

### Service Verification

- [ ] **Plex Server:**
  - [ ] Accessible from all devices on network
  - [ ] Can stream to clients
  - [ ] Remote access still works (if configured)

- [ ] **NAS:**
  - [ ] Accessible from media server
  - [ ] Accessible from other devices
  - [ ] File transfers working
  - [ ] Web interface accessible (if applicable)

- [ ] **Security Cameras:**
  - [ ] All cameras online
  - [ ] Recording functioning
  - [ ] Mobile app can access cameras

- [ ] **Security System (Abode):**
  - [ ] System online
  - [ ] Sensors responding
  - [ ] Mobile app can access system

- [ ] **Gaming Consoles:**
  - [ ] PS5 can connect online
  - [ ] Nintendo Switch can connect online
  - [ ] NAT type acceptable (Type 2/Type B or better)
  - [ ] Online gaming functional

- [ ] **IoT Devices:**
  - [ ] All smart home devices connected
  - [ ] Mobile apps can control devices
  - [ ] Automation rules functioning

### Performance Verification

- [ ] **Network Speed:**
  ```bash
  speedtest-cli
  # Should show good speeds
  ```

- [ ] **File Transfer Speed:**
  - [ ] Test transfer from NAS to media server
  - [ ] Test transfer from media server to other device
  - [ ] Should be faster than before (same network)

- [ ] **Latency:**
  ```bash
  ping -c 10 192.168.1.1
  # Should be <5ms for local network
  ```

### Configuration Verification

- [ ] **Port Forwarding:**
  - [ ] Verify all port forwarding rules migrated
  - [ ] Test forwarded ports (Plex, gaming, etc.)
  - [ ] Update any rules that reference old IP addresses

- [ ] **QoS Settings:**
  - [ ] Configure QoS on Asus router
  - [ ] Set priorities for gaming, streaming, cameras
  - [ ] Test QoS effectiveness

- [ ] **Firewall Rules:**
  - [ ] Verify firewall rules working
  - [ ] Test blocked/allowed traffic
  - [ ] Update rules for unified network

## Troubleshooting

### Common Issues

**Issue: Devices can't connect to internet**
- [ ] Verify Xfinity bridge mode is active
- [ ] Verify Asus WAN gets IP from Xfinity
- [ ] Check DNS settings
- [ ] Restart Asus router

**Issue: Devices can't see each other**
- [ ] Verify all devices on 192.168.1.0/24 network
- [ ] Check firewall rules
- [ ] Verify subnet mask is 255.255.255.0
- [ ] Test ping between devices

**Issue: Eero not working in bridge mode**
- [ ] Verify Ethernet connection to Asus
- [ ] Check Eero app for errors
- [ ] Try resetting Eero and reconfiguring
- [ ] Contact Eero support if needed

**Issue: Plex can't find server**
- [ ] Verify media server IP address
- [ ] Check Plex network settings
- [ ] Verify firewall allows Plex ports
- [ ] Test direct connection: http://<server_ip>:32400/web

**Issue: NAS not accessible**
- [ ] Verify NAS IP address
- [ ] Check NAS network settings
- [ ] Test direct connection
- [ ] Verify SMB/NFS services running

### Rollback Plan

If migration fails:

1. **Revert Xfinity Xfi:**
   - Access admin panel
   - Disable bridge mode
   - Restore original settings

2. **Revert Asus Nighthawk:**
   - Restore configuration backup
   - Or reset to factory defaults and reconfigure

3. **Revert Eero:**
   - Disable bridge mode in Eero app
   - Restore original network settings

4. **Reconnect Devices:**
   - Reconnect to original networks
   - Verify connectivity restored

## Post-Migration Tasks

### Immediate (Day 1)

- [ ] Monitor network for issues
- [ ] Test all critical services
- [ ] Verify all devices connected
- [ ] Check for any connectivity problems

### Short Term (Week 1)

- [ ] Monitor network performance
- [ ] Configure QoS settings
- [ ] Update documentation with new IP addresses
- [ ] Review and optimize firewall rules
- [ ] Set up monitoring/alerts

### Long Term (Month 1)

- [ ] Review network performance metrics
- [ ] Optimize QoS settings based on usage
- [ ] Consider VLAN segmentation (if router supports)
- [ ] Update backup procedures
- [ ] Document lessons learned

## Success Criteria

Migration is successful when:

- [ ] All devices can communicate with each other
- [ ] All services (Plex, NAS, cameras, etc.) functional
- [ ] Internet connectivity working for all devices
- [ ] Network performance equal or better than before
- [ ] Single unified network (192.168.1.0/24)
- [ ] No double NAT issues
- [ ] All devices can access shared resources

## Notes

- Keep this checklist during migration
- Document any issues encountered
- Note IP addresses as you configure them
- Take screenshots of important configurations
- Test thoroughly before considering migration complete



