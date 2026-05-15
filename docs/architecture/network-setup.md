# Network Setup Guide

## ✅ Unified Network Architecture (COMPLETED)

### Hardware Configuration
- **Primary Internet**: Comcast Xfinity 2GB with Xfinity Xfi modem (bridge mode)
- **Primary Router**: Asus Nighthawk RAX50 (DHCP, DNS, firewall)
- **Mesh Extension**: Amazon Eero (3 nodes in bridge mode)
- **Total Devices**: ~30 devices on unified network
- **Network**: Single 192.168.1.0/24 subnet

### Current Network Configuration (UNIFIED)

**Unified Network: 192.168.1.0/24**
- **Gateway**: Asus Nighthawk (192.168.1.1)
- **DHCP Server**: Asus Nighthawk (192.168.1.100-192.168.1.200)
- **DNS**: Asus Nighthawk + Cloudflare/Google (1.1.1.1, 8.8.8.8)
- **WiFi Networks**:
  - "SC Home" (Asus - primary coverage)
  - "SC Home_Ext" (Eero - extended coverage)
- **All Devices**: Unified communication across entire network

### Migration Accomplishments

✅ **Network Unification**: Eliminated double NAT and network isolation
✅ **Performance**: Excellent latency and 0% packet loss (verify periodically with scripts)
✅ **Dual SSID Coverage**: Full home coverage with seamless roaming
✅ **Device Communication**: All devices can communicate directly
✅ **Simplified Management**: Single router, single DHCP, single firewall
✅ **QoS Ready**: Unified bandwidth management and prioritization

## Recommended Network Architecture

### Current State Analysis

**Your Current Setup:**
```
Internet → Xfinity Xfi (Router Mode) → 10.0.0.0/8 Network
                                    └→ Eero Mesh (same network)

Internet → Asus Nighthawk (Router Mode) → 192.168.1.0/24 Network
                                        └→ Media Server, NAS, External Drive
```

**Problems:**
- Two separate networks cannot communicate directly
- Devices split between networks causes connectivity issues
- Double NAT on both networks
- Inefficient use of equipment

### Recommended Solution: Unified Network (Option 1 - RECOMMENDED)

**Goal**: Single network with one primary router for unified management

**Configuration:**
```
Internet → Xfinity Xfi (Bridge Mode - modem only)
    ↓
Asus Nighthawk (Primary Router - 192.168.1.0/24)
    ↓
Eero Mesh System (Access Point Mode - same network)
```

**Benefits:**
- Single unified network (192.168.1.0/24)
- All devices can communicate directly
- Single DHCP server (Asus Nighthawk)
- Single point for QoS, port forwarding, firewall rules
- Eliminates double NAT
- Better performance and troubleshooting

**Steps to Implement:**
1. **Put Xfinity Xfi in Bridge Mode**
   - Access: http://10.0.0.1
   - Navigate to Gateway > At a Glance
   - Enable Bridge Mode
   - This disables routing and WiFi on Xfi

2. **Configure Asus Nighthawk as Primary Router**
   - Connect to Asus admin panel (likely 192.168.1.1)
   - Set WAN connection type: Automatic IP (DHCP from Xfi)
   - LAN IP: 192.168.1.1 (keep current)
   - Subnet: 255.255.255.0 (/24)
   - DHCP range: 192.168.1.100 - 192.168.1.200

3. **Configure Eero in Bridge/Access Point Mode**
   - Open Eero app
   - Settings > Network Settings > Advanced Settings
   - Enable Bridge Mode or Access Point Mode
   - Connect Eero gateway to Asus router via Ethernet (LAN port)
   - Eero will now extend WiFi on the 192.168.1.0/24 network

4. **Migrate Devices**
   - Reconnect devices to unified network
   - Update static IP configurations if needed
   - Verify all devices can communicate

### Alternative: Keep Xfi as Primary (Option 2)

If you prefer to keep Xfinity Xfi as the primary router:

```
Internet → Xfinity Xfi (Router Mode - 10.0.0.0/24)
    ↓
Asus Nighthawk (Access Point Mode - extend 10.0.0.0/24)
    ↓
Eero Mesh System (Access Point Mode - extend 10.0.0.0/24)
```

**Note**: This requires reconfiguring the Asus Nighthawk network to match the Xfinity network, which may require resetting devices.

## Configuration Steps

### Step 1: Document Current Network State

Before making changes, document your current setup:

```bash
# On a device connected to 10.0.0.0/8 network (Xfinity/Eero)
ip addr show
ip route show
ping -c 3 192.168.1.1  # Should fail (different network)

# On a device connected to 192.168.1.0/24 network (Asus)
ip addr show
ip route show
ping -c 3 10.0.0.1     # Should fail (different network)

# Identify which devices are on which network
# Create a list of devices and their current IP addresses
```

**Device Inventory Checklist:**
- [ ] List devices on 10.0.0.0/8 network (Xfinity/Eero)
- [ ] List devices on 192.168.1.0/24 network (Asus)
- [ ] Identify critical devices (media server, NAS, etc.)
- [ ] Note any static IP configurations

### Step 2: Choose Your Primary Router

**Recommendation: Use Asus Nighthawk as Primary (192.168.1.0/24)**

**Reasons:**
- More advanced features (better QoS, VLAN support, more control)
- Likely better performance
- More configuration options
- Already on 192.168.1.0/24 (common standard)

### Step 3: Configure Unified Network (Recommended: Asus as Primary)

#### 3a. Put Xfinity Xfi in Bridge Mode

1. **Access Xfinity Xfi Admin:**
   - URL: http://10.0.0.1 (or check device label)
   - Login with Xfinity credentials

2. **Enable Bridge Mode:**
   - Navigate to: Gateway > At a Glance
   - Click "Enable Bridge Mode"
   - Confirm the change
   - **Note**: WiFi on Xfi will be disabled

3. **Verify Bridge Mode:**
   - Xfi should now act as modem only
   - Should obtain public IP from ISP
   - No routing functionality active

#### 3b. Configure Asus Nighthawk as Primary Router

1. **Access Asus Admin:**
   - URL: http://192.168.1.1
   - Login with admin credentials

2. **Configure WAN:**
   - WAN Connection Type: Automatic IP (DHCP)
   - Asus will get IP from Xfinity Xfi (bridge mode)

3. **Configure LAN:**
   - IP Address: 192.168.1.1 (keep current)
   - Subnet Mask: 255.255.255.0
   - DHCP Server: Enable
   - IP Pool: 192.168.1.100 - 192.168.1.200
   - Gateway: 192.168.1.1
   - DNS: 1.1.1.1, 8.8.8.8 (or auto from ISP)

4. **Configure WiFi (if using Asus WiFi):**
   - SSID: Your preferred name
   - Security: WPA2/WPA3
   - Channels: Auto or manual selection
   - Enable both 2.4GHz and 5GHz bands

#### 3c. Configure Eero in Access Point Mode

1. **Open Eero App:**
   - Ensure you're on the Eero network

2. **Enable Bridge Mode:**
   - Settings > Network Settings > Advanced Settings
   - Enable "Bridge Mode" or "Access Point Mode"
   - This disables Eero's routing/DHCP

3. **Physical Connection:**
   - Connect Eero gateway to Asus router via Ethernet
   - Use LAN port on Eero (not WAN port, if it has both)
   - Eero will now extend WiFi on 192.168.1.0/24 network

4. **Verify Eero Setup:**
   - Eero nodes should connect to gateway
   - WiFi should extend the 192.168.1.0/24 network
   - Check Eero app for status

#### 3d. Migrate Devices to Unified Network

1. **Reconnect Devices:**
   - Devices previously on 10.0.0.0/8 need to reconnect
   - They should now get 192.168.1.x addresses from Asus DHCP

2. **Update Static IPs:**
   - If any devices had static IPs on 10.0.0.0/8, update to 192.168.1.x
   - Update in device settings or router DHCP reservations

3. **Verify Connectivity:**
   ```bash
   # Test connectivity between devices
   ping 192.168.1.1    # Gateway
   ping 192.168.1.x    # Other devices
   # All devices should now be able to ping each other
   ```

### Step 4: Network Segmentation (Future Enhancement)

**Note**: For now, focus on unifying the network first. VLAN segmentation can be added later if your router supports it.

Once you have a unified network, consider creating VLANs:

**Unified Network Base: 192.168.1.0/24**
- **Management (192.168.1.0/24)**: Main network for now
  - Media server (static IP: 192.168.1.11)
  - NAS (static IP: 192.168.1.20)
  - Monitoring equipment
  - Admin devices

**Future VLANs (if router supports):**
- **Media/Gaming (192.168.10.0/24)**: Plex clients, gaming consoles
- **IoT/Security (192.168.20.0/24)**: Cameras, smart home devices
- **Guest (192.168.30.0/24)**: Visitor network

**For Now:**
- Use DHCP reservations for critical devices
- Assign static IPs to important devices
- Plan VLAN segmentation for future if needed

### Step 5: Post-Migration Verification

After unifying networks, verify everything works:

1. **Connectivity Tests:**
   ```bash
   # From any device, test connectivity
   ping 192.168.1.1          # Gateway
  ping 192.168.1.11         # Media server (if static IP)
  ping 192.168.1.20         # NAS (if static IP)

   # Test services
  curl http://192.168.1.11:32400/web  # Plex
  curl http://192.168.1.20:5000       # NAS (if web interface)
   ```

2. **Service Verification:**
   - Plex server accessible from all devices
   - NAS accessible from media server and other devices
   - All IoT devices can reach internet
   - Gaming consoles can connect online
   - Security cameras functional

3. **Performance Check:**
   - File transfer speeds between devices
   - Network latency
   - Bandwidth usage monitoring

### Step 4: Quality of Service (QoS)

**QoS Priority Configuration (High to Low):**

1. **Critical/Real-time** (Highest Priority)
   - Security system communications (Abode)
   - VoIP calls
   - Critical monitoring

2. **Gaming & Streaming** (High Priority)
   - PlayStation 5 (online gaming, downloads)
   - Nintendo Switch (online gaming)
   - Plex streaming (local and remote)
   - Real-time video calls

3. **Media Operations** (Medium-High Priority)
   - Large file transfers (NAS, photo/video editing)
   - Media library syncing
   - Plex metadata updates

4. **Security Cameras** (Medium Priority)
   - Nest camera streaming (continuous upload)
   - Eufy camera streaming
   - Cloud storage sync

5. **IoT & Background** (Low Priority)
   - Smart home device communications
   - Firmware updates
   - Background syncs
   - Downloads

**QoS Bandwidth Allocation Example:**
- Gaming/Streaming: 40% guaranteed, 60% maximum
- Media Operations: 30% guaranteed, 50% maximum
- Security Cameras: 20% guaranteed, 30% maximum
- IoT/Background: 10% guaranteed, 20% maximum

## Monitoring Setup

### Network Performance Monitoring
- Install SNMP on routers
- Configure NetFlow/sFlow export
- Set up bandwidth monitoring
- Create network topology maps

### Tools to Deploy
- **ntopng**: Real-time network traffic monitoring
- **Wireshark/tcpdump**: Packet analysis
- **iperf**: Bandwidth testing
- **ping/Traceroute**: Connectivity diagnostics

## Migration Considerations

### Impact Assessment

**Before Migration:**
- Media server and NAS isolated on 192.168.1.0/24
- Most devices on 10.0.0.0/8 network
- Devices cannot directly communicate across networks
- Plex clients may have issues finding server

**After Migration:**
- All devices on unified 192.168.1.0/24 network
- Direct communication between all devices
- Better performance (no internet routing for local traffic)
- Simplified management (single router, single network)

### Migration Risks

1. **Downtime**: Plan for 1-2 hours of network downtime
2. **Device Reconnection**: All devices need to reconnect to new network
3. **Configuration Changes**: May need to update static IPs, port forwarding
4. **Service Interruption**: Services may be temporarily unavailable

### Recommended Migration Approach

1. **Schedule during low-usage period** (late night, weekend)
2. **Backup all configurations** before starting
3. **Have rollback plan** ready
4. **Test thoroughly** after migration
5. **Monitor closely** for first 24-48 hours

See [Network Unification Checklist](network-unification-checklist.md) for detailed step-by-step instructions.

## Security Considerations

### Firewall Rules
- Block unwanted inbound traffic
- Allow necessary ports only (Plex: 32400, etc.)
- Implement geo-blocking for external access
- Set up VPN for remote access

### Device Isolation

**Security Camera Isolation:**
- **All security cameras on isolated IoT VLAN**
- **No access to management or media networks**
- **Internet access only** (for cloud services)
- **Firewall rules**: Block all inter-VLAN traffic from IoT network
- **Exception**: Abode Homebase may need limited access to management network (if using local storage)

**Gaming Console Considerations:**
- **Place on Media/Gaming VLAN** (not IoT)
- **Port forwarding requirements**:
  - PS5: Ports 9307-9308 (UDP), 1935, 3478-3480 (TCP/UDP)
  - Nintendo Switch: Ports 1-65535 (UDP), 6667, 12400, 28910, 29900-29901, 1024-65535 (TCP)
- **UPnP**: Enable for gaming consoles (on gaming VLAN only)
- **NAT Type**: Ensure proper NAT configuration for optimal gaming experience

**Network Isolation Rules:**
- Guest network: Complete isolation, internet only
- IoT network: Internet only, no internal network access
- Security cameras: Isolated, internet only (prevent unauthorized access)
- Gaming network: Can access management network (for Plex, NAS if needed)

## Performance Optimization

### WiFi Optimization
- Channel selection (avoid interference)
- Band steering configuration
- Transmit power adjustment
- Client steering between access points

### Wired Network
- Use gigabit switches
- Proper cable management
- Ethernet backhaul for mesh nodes
- Link aggregation for high-speed connections

## Troubleshooting Runbook

### Common Issues
1. **Slow WiFi**: Check channel congestion, interference
2. **Double NAT**: Configure bridge mode on secondary router
3. **IP Conflicts**: Check DHCP server configurations
4. **Poor Streaming**: QoS configuration, bandwidth allocation

### Port Forwarding Configuration

**Required for External Access:**

**Plex Media Server:**
```
Service: Plex Media Server
External Port: 32400
Internal Port: 32400
Protocol: TCP
Internal IP: 192.168.1.11
Router: Asus Nighthawk (192.168.1.1)
Location: WAN → Virtual Server / Port Forwarding
Status: ✅ Configured and working
```

**Configuration Steps (Asus Router):**
1. Access router admin: http://192.168.1.1
2. Navigate to: WAN → Virtual Server / Port Forwarding
3. Add new rule with above settings
4. Save and wait 2-3 minutes for changes to apply
5. Verify in Plex: Settings → Network → Remote Access should show "Fully accessible"

### Diagnostic Commands
```bash
# Network speed test
speedtest-cli

# WiFi signal strength
iwconfig

# Network latency
ping -c 10 8.8.8.8

# Port connectivity
telnet <device_ip> <port>

# Test Plex remote access (from external network)
curl http://YOUR_PUBLIC_IP:32400/web
```