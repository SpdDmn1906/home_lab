# Network Migration Plan: Unified Home Lab Network

## Current Network Setup (UPDATED)

### Important Discovery: Eero Already in Bridge Mode
- **Xfinity Xfi**: Primary router providing internet, DHCP, DNS
- **Eero Mesh**: Already configured in **Bridge/Access Point mode**
- **Asus Nighthawk**: Secondary router on separate network (192.168.1.0/24)
- **Result**: Two isolated networks with no direct communication

### Current Network Topology
```
Internet → Xfinity Xfi (Router Mode: 10.0.0.0/8)
           ├── WiFi: "SC Network" (2.4G/5G)
           └── Eero Mesh (Bridge Mode) → WiFi: "SC Home"
               └── Connected devices: PS5, iPads, cameras, etc.

           Asus Nighthawk (Router Mode: 192.168.1.0/24) [ISOLATED]
           ├── WiFi: "SC_Internal_2/5"
           └── Connected devices: Media server, NAS, external drive
```

### Migration Impact & Simplification
Since Eero is already in bridge mode, the migration is **significantly simplified**:

**What Changes:**
- ❌ **Eliminated**: Phase 4 "Convert Eero to Access Point Mode" (already done!)
- ✅ **Simplified**: Eero will automatically join the new Asus network
- ✅ **Faster**: Reduced downtime and configuration steps
- ✅ **Lower Risk**: One less configuration step that could go wrong

**Migration Flow:**
1. Put Xfinity Xfi in bridge mode
2. Configure Asus Nighthawk as primary router
3. **Eero automatically extends the new network** (no manual config needed!)
4. Test and verify connectivity

## Current Problem Analysis

Your current dual-network setup is causing performance issues because:

1. **Network Isolation**: Devices on 10.0.0.0/8 (Xfi/Eero) cannot communicate with devices on 192.168.1.0/24 (Asus)
2. **Double NAT**: Both routers are performing NAT, causing routing inefficiencies
3. **Media Streaming Issues**: Plex clients can't efficiently reach the media server
4. **File Transfer Problems**: Large photo/video files must route through internet instead of local network

## Recommended Solution: Unified Network

### Option 1: Asus Nighthawk as Primary Router (RECOMMENDED)

**Benefits:**
- Keep your critical services on the Asus network
- Better router features and configuration options
- Maintain current IP addresses for media server/NAS
- Single point of management

**Migration Steps:**

#### Phase 1: Preparation (30 minutes)
1. **Backup Current Configurations**
   ```bash
   # Document current settings
   echo "Xfinity Xfi: $(ip route show | grep default)"
   echo "Asus Nighthawk: 192.168.1.1"
   echo "Eero Gateway IP: Check Eero app"
   ```

2. **Document Device IPs**
   - Media Server: `192.168.1.___`
   - NAS: `192.168.1.___`
   - External Drive: `192.168.1.___`
   - Any static IPs on Eero network

3. **Choose New Network Range**
   - Keep `192.168.1.0/24` (Asus network)
   - Or choose `10.0.0.0/24` (Xfinity network)
   - **Recommendation**: Keep 192.168.1.0/24 since your critical devices are already configured

4. **Plan WiFi Network Changes**
   - **Current SSIDs to disappear**: "SC Network" (Xfi), "SC Home" (Eero)
   - **New primary SSID**: "SC Home" (Asus Nighthawk - your best router)
   - **Prepare devices**: Have WiFi passwords ready for reconnection
   - **Children's iPads**: Plan to update parental controls after migration

#### Phase 2: Bridge Xfinity Xfi (10 minutes)

**⚠️ Critical: This will disconnect ALL devices on Xfi and Eero networks for 2-5 minutes**

### Step-by-Step Bridge Mode Instructions:

1. **Prepare Your Devices**:
   - Have phone/tablet ready (you'll lose WiFi temporarily)
   - Note current WiFi password (it stays the same)

2. **Access Xfi Admin Panel**:
   - Open web browser on device connected to Xfi network
   - Go to: `http://10.0.0.1`
   - Login with your Xfinity username/password (same as My Account app)

3. **Navigate to Bridge Mode**:
   - Click **"Gateway"** in the left menu (or "Internet" → "Gateway")
   - Click **"At a Glance"** tab
   - Scroll down to find **"Bridge Mode"** section

4. **Enable Bridge Mode**:
   - Check the box: **"Enable Bridge Mode"**
   - Click **"Save"** or **"Enable Bridge Mode"** button
   - Xfi will show warning: *"This will disable WiFi and make Xfi a modem only"*

5. **Confirm and Wait**:
   - Click **"OK"** or **"Confirm"** to proceed
   - Xfi will reboot (2-3 minutes)
   - **Do NOT power cycle Xfi during reboot**

6. **Verify Bridge Mode Success**:
   - After reboot, try accessing `http://10.0.0.1`
   - Should show **"Bridge Mode: Enabled"**
   - Xfi WiFi networks ("SC Network") will be gone
   - Internet light should still be solid (Xfi is now modem-only)

### What Happens Immediately:
- ❌ **Xfi WiFi disappears**: "SC Network" 2.4G/5G networks shut down
- ❌ **Eero loses connection**: Temporarily no internet (1-2 minutes)
- ❌ **All connected devices disconnect**: Brief WiFi outage
- ✅ **Xfi becomes pure modem**: Still provides internet to Asus

### Alternative Access Methods (if 10.0.0.1 doesn't work):
- **Xfinity App**: Settings → Internet → Gateway → More → Bridge Mode
- **My Account Website**: xfinity.com → My Account → Internet → Manage Gateway
- **Try different IPs**: 10.0.0.2, 10.0.0.3, or 10.0.0.4

### Emergency Recovery (if something goes wrong):
1. **Power cycle Xfi**: Unplug for 30 seconds, plug back in
2. **Wait 5 minutes**: Let Xfi fully reboot
3. **Access admin**: Try 10.0.0.1 again
4. **Disable bridge mode**: Uncheck "Enable Bridge Mode" and save
5. **Full factory reset**: If needed, press reset button on Xfi for 30 seconds

### Success Indicators:
- ✅ Xfi admin shows "Bridge Mode: Enabled"
- ✅ No WiFi networks broadcast from Xfi
- ✅ Asus router can get internet connection
- ✅ Eero automatically reconnects to Asus network

#### Phase 3: Configure Asus as Primary (15 minutes)
1. Connect computer directly to Asus router
2. Access Asus admin: `http://192.168.1.1`
3. **WAN Settings**:
   - Connection Type: Automatic IP
   - This gets IP from Xfinity Xfi (now in bridge mode)
4. **LAN Settings** (should already be correct):
   - IP Address: 192.168.1.1
   - Subnet Mask: 255.255.255.0
   - DHCP Range: 192.168.1.100-192.168.1.200

5. **WiFi Settings - Smart Connect SSID**:
   - Navigate to Wireless settings
   - **Recommended**: Use same SSID for both bands
     - Set both 2.4GHz and 5GHz to **"SC Home"**
     - Enable **Smart Connect** or **Band Steering** (Asus calls this "Smart Connect")
     - Devices automatically choose the best band
   - **Alternative**: Separate SSIDs (if you prefer manual control)
     - 2.4GHz: **"SC Home"**
     - 5GHz: **"SC Home_5G"**
   - Keep same passwords (devices will auto-reconnect)
   - Enable both 2.4GHz and 5GHz bands

#### Phase 4: Eero Automatically Joins New Network (5 minutes)
**Since Eero is already in bridge mode, this phase is greatly simplified:**

1. **Eero Status Check**: Verify Eero is currently in bridge mode (confirmed ✅)
2. **WiFi SSID Decision** - **For your mesh setup with wired satellites, use Option B:**

   **REQUIRED for your configuration**: Keep Eero WiFi enabled as "SC Home_Ext"
   - **Critical**: Eero #2 has wired devices that would lose connectivity if WiFi disabled
   - **Essential**: Eero #3 (garage) serves outdoor Nest cams too far from main router
   - **Mesh preservation**: Satellite Eeros connect wirelessly back to main Eero
   - **Rename in Eero app**: Change SSID to "SC Home_Ext" (both 2.4GHz and 5GHz)

   **Why Option A (disable Eero WiFi) would break your setup:**
   - Eero #2: Wired devices lose internet connectivity
   - Eero #3: Outdoor Nest cams lose connection (too far from main router)
   - Mesh backhaul: Satellite-to-satellite wireless connections fail
   - **Result**: Significant portions of your home lose network coverage

   **Option B drawbacks (acceptable for your needs):**
   - Slight WiFi roaming complexity between Asus and Eero coverage areas
   - Two SSID names to manage ("SC Home" + "SC Home_Ext")
   - But preserves all your existing wired and wireless device connections
   - **WiFi Optimization**: Monitor device distribution in router admin panels after migration

3. **Automatic Reconnection**: Once Xfi goes into bridge mode, Eero will:
   - Automatically detect the new Asus network
   - Start extending the 192.168.1.0/24 network
   - **No manual reconfiguration needed!**

4. **Device Impact**: Current "SC Home" WiFi will disappear when Xfi bridges, but Eero will create new WiFi if you keep it enabled

#### Phase 5: Verification (15 minutes)
1. **Test Connectivity**:
   ```bash
   # From any device, test all services
   ping 192.168.1.1        # Asus router
   ping <media_server_ip> # Media server
   ping <nas_ip>           # NAS
   ```

2. **Verify Plex Access**:
   - Open Plex app on devices from both old networks
   - Should now connect directly to media server

3. **Test File Transfers**:
   - Transfer large file from NAS to computer
   - Should be much faster (local network speeds)

## Alternative: Xfinity Xfi as Primary Router

If you prefer to keep Xfinity Xfi features:

1. Put Asus Nighthawk in Access Point mode
2. Configure Asus to use 10.0.0.0/24 network
3. Keep Eero in Bridge mode
4. **Drawback**: May need to reconfigure all device IPs

## WiFi Network Changes Summary

### Before Migration
- **"SC Network"** (2.4G/5G): Xfinity Xfi router WiFi → **SHUT DOWN**
- **"SC Home"**: Eero mesh WiFi → **RENAMED/CONVERTED**
- **"SC_Internal_2/5"**: Asus Nighthawk WiFi → **RENAMED to "SC Home"**

### After Migration
- **"SC Home"** (2.4G + 5G): Smart Connect WiFi from Asus Nighthawk (recommended)
  - Devices automatically choose the best band
  - Alternative: "SC Home" (2.4G) and "SC Home_5G" (5G) separate
- **Eero WiFi**: Renamed to "SC Home_Ext" (required for your mesh setup)

## WiFi SSID Strategy: Smart Connect vs Separate Networks

### **Recommended: Smart Connect (Same SSID)**
**Why it's better for your setup:**
- **Automatic Optimization**: Asus Nighthawk intelligently directs devices to best band
- **Gaming Priority**: PS5 automatically gets 5GHz for lowest latency
- **Camera Optimization**: Nest/Eufy cameras get 2.4GHz for better range
- **iPad Handling**: Children's iPads automatically get optimal band
- **Seamless Roaming**: Devices switch bands without reconnecting
- **Simple Management**: One network name for all devices

**Asus Smart Connect Features:**
- Band steering based on device capabilities
- Signal strength optimization
- Load balancing between bands
- Automatic failover

### **Alternative: Separate SSIDs**
Choose this if you need manual control:
- "SC Home" (2.4GHz) - Better range, compatible with older devices
- "SC Home_5G" (5GHz) - Faster speeds, gaming/streaming priority

### **Final Recommendation**
**Use Smart Connect with single "SC Home" SSID** - your Asus Nighthawk RAX50 has excellent band steering technology that will automatically optimize performance for all your devices (gaming consoles, cameras, iPads, etc.).

### User Experience During Migration
1. **Bridge Mode Activation**: "SC Network" WiFi disappears
2. **Eero Transition**: Current "SC Home" WiFi temporarily disconnects, then **reappears as "SC Home_Ext"** (preserving your mesh coverage for garage cameras and wired satellite devices)
3. **Asus Activation**: New "SC Home" WiFi appears from Asus (Smart Connect)
4. **Device Reconnection**: Devices connect to Asus "SC Home" network and auto-optimize
5. **Camera Reconnection**: Security cameras connected to Eero need manual reconnection to "SC Home_Ext"
6. **Minimal Downtime**: Most devices auto-reconnect within 1-2 minutes

## Device-Specific Migration Notes

### Media Server
- **Current**: 192.168.1.x (Asus network)
- **After Migration**: Stays on same IP (no change needed)
- **WiFi Impact**: No change (wired connection recommended)
- **Verify**: Docker services restart properly

### NAS and External Drive
- **Current**: 192.168.1.x (Asus network)
- **After Migration**: Stays on same IP (no change needed)
- **WiFi Impact**: No change (wired connections)
- **Verify**: Network shares accessible from all devices

### Gaming Devices (PS5, Switch)
- **Current**: 10.0.0.x (Eero "SC Home" network)
- **After Migration**: Gets new IP from Asus DHCP (192.168.1.x)
- **WiFi Impact**: Must reconnect to new "SC Home" network
- **Action**: Select "SC Home" or "SC Home_5G" WiFi, same password

### Security Cameras (Nest, Eufy, Abode)
- **Current**: 10.0.0.x (Eero "SC Home" network)
- **After Migration**: Gets new IP from Asus DHCP (192.168.1.x)
- **WiFi Impact**: Cameras connected to Eero WiFi will disconnect and need reconnection
- **Action Required**: Use camera apps to reconnect to "SC Home_Ext" WiFi
- **Performance Note**: Cameras near main Asus router can use "SC Home" for better performance
- **Note**: Wired cameras (if any) unaffected

### Mobile Devices (iPads, iPhones, Android)
- **Current**: Various networks (Xfi "SC Network" or Eero "SC Home")
- **After Migration**: Gets new IP from Asus DHCP (192.168.1.x)
- **WiFi Impact**: Must reconnect to "SC Home" network
- **Action**: Select "SC Home" or "SC Home_5G" WiFi, same password
- **Children's iPads**: Will need parental control reconfiguration

### Smart Home Devices
- **Current**: 10.0.0.x (Eero "SC Home" network)
- **After Migration**: Gets new IP from Asus DHCP (192.168.1.x)
- **WiFi Impact**: Must reconnect to "SC Home" network
- **Action**: May require device reset or app reconfiguration

## QoS and Port Forwarding Migration

### Port Forwarding
**Current Setup**: Configure on both routers
**After Migration**: Configure only on Asus router

Required ports for your services:
- Plex: 32400 (TCP)
- SSH: 22 (TCP) - if exposed
- Any gaming ports as needed

### QoS Rules
Configure on Asus router:
- **Gaming Priority**: PS5/Switch traffic (highest)
- **Media Streaming**: Plex traffic (high)
- **Security Cameras**: Camera streams (medium)
- **Background**: Smart home devices (low)

## Monitoring Updates

After migration, update your monitoring:
1. **Prometheus**: Update network targets
2. **Grafana**: Verify all devices are discovered
3. **Alerts**: Test notification system

## Rollback Plan

If issues occur during migration:

### Emergency Rollback (5 minutes)
1. **Put Xfinity Xfi back in router mode**:
   - Access: `http://10.0.0.1` (if accessible)
   - Or factory reset Xfi and reconfigure
2. **Reconnect Eero to Xfi**:
   - Plug Ethernet cable back to Xfi LAN port
   - Put Eero back in router mode
3. **Wait**: 5 minutes for network to stabilize
4. **Test**: Verify devices reconnect to original WiFi networks:
   - "SC Network" (Xfi) should reappear
   - "SC Home" (Eero) should reappear
   - "SC_Internal_2/5" (Asus) remains available

### Partial Rollback Options
- **Keep Asus as primary**: Just disable Eero bridge mode
- **Keep Xfi features**: Reconfigure Asus as access point only
- **WiFi-only rollback**: Keep unified network but restore original SSID names

### WiFi Network Restoration
- **Xfi Networks**: "SC Network" 2.4G/5G will return
- **Eero Networks**: "SC Home" will return
- **Asus Networks**: "SC_Internal_2/5" remain available
- **Device Reconnection**: Automatic (same passwords)

## Expected Performance Improvements

After migration, you should see:
- **Faster Plex streaming** (no cross-network routing)
- **Better gaming performance** (single NAT)
- **Faster file transfers** (local network speeds)
- **Simplified management** (one router to configure)
- **Better remote access** (single port forwarding)

## Timeline

**Total Time**: 45-60 minutes (reduced since Eero is already configured)
- Preparation: 20 minutes
- Configuration: 20 minutes (Eero phase eliminated)
- Testing: 15 minutes
- Optimization: 10 minutes

**Best Time**: Weekend when you can monitor and fix any issues

## WiFi Transition Summary

### What Changes During Migration
```
BEFORE MIGRATION:
├── Xfinity Xfi Router
│   ├── WiFi: "SC Network" (2.4G/5G) → SHUT DOWN
│   └── Connected to Eero
└── Eero Mesh System
    ├── WiFi: "SC Home" → TEMPORARILY DOWN
    └── Asus Nighthawk Router
        └── WiFi: "SC_Internal_2/5" → BECOMES "SC Home"

AFTER MIGRATION:
└── Asus Nighthawk Router (Primary)
    ├── WiFi: "SC Home" (Smart Connect 2.4G + 5G) ⭐ PRIMARY COVERAGE
    │   └── Devices automatically choose optimal band
    └── Eero Mesh (Access Point)
        ├── WiFi: "SC Home_Ext" (2.4G + 5G) ⭐ EXTENDED COVERAGE
        │   └── Preserves mesh for garage cameras + wired satellites
        ├── Eero #1 (wired to router) → Main mesh node
        ├── Eero #2 (mesh + wired devices) → Extended coverage
        └── Eero #3 (garage mesh) → Outdoor camera coverage
```

### Device Reconnection Guide
1. **After Phase 2**: "SC Network" disappears - devices disconnect
2. **After Phase 4**: "SC Home" appears from Asus, "SC Home_Ext" from Eero
3. **Same Passwords**: WiFi passwords remain the same
4. **Camera Setup**: Reconnect security cameras to "SC Home_Ext" via their apps
4. **Best Signal**: Connect to "SC Home_5G" for faster speeds when possible

### Expected Downtime
- **WiFi Outage**: 2-5 minutes (Eero already in bridge mode = faster transition)
- **Internet**: 2 minutes during bridge mode activation
- **Services**: None (all services remain on Asus network)
- **Eero WiFi**: 1-2 minutes for automatic reconnection to new network

### Troubleshooting Eero Latency Issues

**Your Symptoms:** High latency variation (7-93ms with 27ms std dev) on "SC Home_Ext" while "SC Home" works perfectly. Router-to-router connectivity is good, so the issue is Eero mesh routing instability.

#### Root Cause Analysis:
The **periodic high latency with good baseline connectivity** indicates **Eero mesh node handoffs** and **WiFi interference**, not basic network issues. Your setup requires Eero WiFi for wired satellites and garage cameras, so we need to optimize, not eliminate it.

#### Phase 1: Quick Eero Health Check
1. **Update Eero Firmware**: Eero app → Settings → About → Check for updates on all nodes
2. **Restart Mesh Network**: Unplug all Eero nodes for 30 seconds, then plug back in
3. **Verify Bridge Mode**: Eero app should show "Bridge Mode: Enabled" with DHCP disabled

#### Phase 2: WiFi Interference Resolution (Most Critical)
**High latency variation suggests channel conflicts between Asus and Eero.**

1. **Check Asus Channels**:
   - Asus admin (192.168.1.1) → Advanced Settings → Wireless
   - Note current 2.4GHz and 5GHz channels

2. **Change Eero Channels**:
   - Eero app → WiFi → Advanced Settings
   - **2.4GHz**: Set to channel 1, 6, or 11 (opposite of Asus)
   - **5GHz**: Set to channel 36, 149, or 161 (avoid Asus channel)

3. **Test Results**: Run ping tests immediately after channel changes

#### Phase 3: DHCP and Routing Conflicts
1. **Confirm Eero DHCP Disabled**:
   - Eero app → Network Settings → Advanced → DHCP: **OFF**
   - Asus handles all DHCP (192.168.1.100-192.168.1.200 range)

2. **Clear Device DHCP Leases**:
   - Disconnect/reconnect devices from "SC Home_Ext"
   - Force fresh IP assignments from Asus router

#### Phase 4: Mesh Node Optimization
1. **Check Node Signal Strength**:
   - Eero app → Network Map → Check signal bars between nodes
   - Reposition nodes if signal is weak

2. **Test Individual Nodes**:
   - Connect test device directly next to each Eero node
   - Run ping tests to isolate which node causes latency

#### Phase 5: Advanced Diagnostics
```bash
# From device on SC Home_Ext - run for 2-3 minutes
ping -t 120 192.168.1.1  # Monitor latency to Asus router

# Check for interference
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s

# Test specific Eero node performance
arp -a  # Check if device ARP table shows routing issues
```

#### Phase 6: Eero Factory Reset (Last Resort)
**✅ COMPLETED**: You have successfully performed a comprehensive Eero reset:
- Reset each node individually
- Removed and recreated the network
- Reconnected nodes one by one
- Re-enabled bridge mode
- Renamed to "SC Home_Ext"

If latency still persists after this complete reset, the issue may be fundamental to the Eero mesh in your environment.

#### 🎉 EXCELLENT NEWS: Eero Latency Issue RESOLVED!

**Your Latest Test Results Show PERFECT Performance:**
- **Asus Router Latency**: 5.9-13.7ms (avg 9.2ms) ✅ **Perfect**
- **Internet Latency**: 18.3-21ms (avg 19.8ms) ✅ **Good**
- **0% Packet Loss** ✅
- **DNS Resolution**: 0.051s ✅ **Fast**
- **Channel 36**: 5GHz WiFi 6 connection

**Key Discovery**: Your test was actually on "SC Home" (Asus), not "SC Home_Ext" (Eero). This means your **primary network is working flawlessly**.

#### ✅ FINAL CONFIRMATION: Eero Latency RESOLVED!

**Test Results on "SC Home_Ext" Network:**
- **Asus Router Latency**: 4.9-9.2ms (avg 6.9ms) ✅ **PERFECT**
- **Internet Latency**: 16.4-26.2ms (avg 20.9ms) ✅ **EXCELLENT**
- **0% Packet Loss** ✅
- **DNS Resolution**: 0.046s ✅ **FAST**
- **Max Latency**: 26.2ms ✅ **WELL UNDER 50ms threshold**

**CONFIRMED**: Eero mesh latency issues have been completely resolved through the factory reset procedure.

---

## 📊 **Network Migration: COMPLETE** ✅

**Status**: **FULL SUCCESS** - Unified network operational with excellent performance on both SSIDs

**What Was Accomplished:**
- ✅ **Single Network**: 192.168.1.0/24 (eliminated double NAT)
- ✅ **Primary Router**: Asus Nighthawk (DHCP, DNS, main WiFi "SC Home")
- ✅ **Mesh Extension**: Eero in bridge mode ("SC Home_Ext" with perfect performance)
- ✅ **Performance**: Excellent latency (<27ms max) and 0% packet loss on both networks
- ✅ **Coverage**: Full home coverage with dual SSID setup
- ✅ **Stability**: Resolved Eero latency through comprehensive factory reset
- ✅ **Foundation**: Solid network infrastructure ready for advanced services

**Final Performance Metrics:**
- **SC Home (Asus)**: 5.9-13.7ms router, 18-21ms internet
- **SC Home_Ext (Eero)**: 4.9-9.2ms router, 16.4-26.2ms internet
- **Both networks**: 0% packet loss, <0.05s DNS resolution

---

## 🎯 **Next Steps: Advanced Home Lab Features**

With your network foundation solid and performing perfectly, here are the logical next priorities:

### **1. Device Naming & DNS Resolution**
**Goal**: Enable `ping CloudNAS` and device name resolution
- Set up static DHCP leases on Asus router for critical devices
- Use the `find_device_macs.sh` script to identify device MAC addresses
- Follow `DNS_SETUP_GUIDE.md` for detailed instructions

### **2. Network-Wide Ad Blocking**
**Goal**: Block ads and trackers across all devices
- Deploy AdGuard Home + Unbound
- Configure DHCP to use AdGuard as LAN DNS server
- Test ad blocking effectiveness

### **3. Parental Controls & Security**
**Goal**: Monitor and control children's iPad usage
- Implement device-specific restrictions
- Set up remote monitoring and shutdown capabilities
- Configure content filtering and time limits

### **4. Remote Access Setup**
**Goal**: Secure access to your home lab from anywhere
- Deploy WireGuard VPN for secure remote connections
- Set up Apache Guacamole for web-based remote desktop
- Configure firewall rules and access controls

### **5. AI Assistant Development**
**Goal**: In-house secure AI capabilities
- Deploy Ollama with local LLM models
- Set up voice interface and automation
- Integrate with home automation systems

### **6. Monitoring & Maintenance**
**Goal**: Proactive system health and performance tracking
- Enhance Prometheus/Grafana monitoring stack
- Set up automated health checks and alerts
- Implement backup strategies for critical data

2. **Location-Based Testing**:
   - Test latency next to each Eero node individually
   - Identify which specific node(s) cause the 89ms+ spikes
   - Reposition or isolate problematic nodes

3. **Wired-Only Eero Mode** (Preserves Your Setup):
   - **Keep Eero WiFi disabled** permanently
   - **Use only Asus "SC Home"** for all wireless devices
   - **Keep Eero satellites for wired devices** (your NAS, cameras stay connected)
   - **Benefits**: Eliminates mesh routing issues while preserving wired connectivity

4. **Performance Monitoring**:
   - Track which devices experience latency spikes
   - Note correlation with specific Eero nodes
   - Monitor if latency increases with more devices

#### Monitoring Long-Term
- **Track latency patterns**: Note times when latency spikes occur
- **Device correlation**: Which devices experience the most latency?
- **Location correlation**: Does latency occur near certain Eero nodes?
- **Load correlation**: Does latency increase with more devices connected?

### WiFi Roaming with Dual SSIDs
**What to expect with "SC Home" + "SC Home_Ext":**
- **Primary Coverage**: "SC Home" (Asus) covers main living areas with best performance
- **Extended Coverage**: "SC Home_Ext" (Eero) covers garage, outdoor areas, and dead zones
- **Automatic Roaming**: Modern devices will prefer "SC Home" when available
- **Fallback Coverage**: Devices automatically switch to "SC Home_Ext" in extended areas
- **No Manual Switching**: Users don't need to change WiFi networks manually

**Device-Specific Behavior:**
- **iPads**: May need manual reconnection initially, then roam automatically
- **Gaming Consoles**: Will prefer "SC Home" for best gaming performance
- **Smart Home Devices**: Will connect to whichever SSID provides strongest signal
- **Security Cameras**: Outdoor Nest cams will use "SC Home_Ext" (Eero #3 coverage)

### Security Camera Reconnection Procedures

**For Outdoor Nest Cameras:**
1. Open Google Home app on your phone
2. Select the Nest camera → Settings → WiFi
3. Choose "SC Home_Ext" from available networks
4. Enter the same WiFi password as before
5. Camera will reconnect and upload footage to cloud

**For Eufy Cameras:**
1. Open Eufy Security app
2. Go to camera settings → WiFi Settings
3. Select "SC Home_Ext" network
4. Enter WiFi password
5. Camera reconnects to Eufy Homebase automatically

**Optimization Tips:**
- Place cameras near Eero nodes for best signal
- Consider moving cameras closer to main Asus router for "SC Home" if possible
- Test camera connectivity in Google Home/Eufy apps after reconnection
- Check camera firmware updates post-migration

## Support Resources

- [Asus Nighthawk Manual](https://www.asus.com/support/)
- [Eero Bridge Mode Guide](https://support.eero.com/hc/en-us/articles/209636813)
- [Xfinity Bridge Mode](https://www.xfinity.com/support/articles/configure-bridge-mode-xfi)

---

## DNS Name Resolution Setup (Post-Migration)

Now that your unified network is working, set up proper DNS name resolution so you can connect to devices by name instead of IP addresses.

### Step 1: Configure Static DHCP Leases

**Prevent IP Address Changes:**
1. Access Asus admin: `http://192.168.1.1`
2. Go to **Advanced Settings** → **LAN** → **DHCP Server**
3. Enable **"Enable Manual Assignment"**
4. Add static leases for your key devices:

| Device | Suggested Hostname | Static IP | Purpose |
|--------|-------------------|-----------|---------|
| Media Server | mediaserver | 192.168.1.11 | Docker services |
| Synology NAS | nas | 192.168.1.20 | File storage |
| Gaming PC | gaming-pc | 192.168.1.30 | Gaming |
| PS5 | ps5 | 192.168.1.40 | Gaming console |
| Nintendo Switch | switch | 192.168.1.41 | Gaming console |
| iPad Child1 | child1-ipad | 192.168.1.50 | Children's device |
| iPad Child2 | child2-ipad | 192.168.1.51 | Children's device |

**How to Find MAC Addresses:**
- Asus admin → LAN → DHCP Server → Client List
- Or check device settings → Network → Hardware Address

### Step 2: Configure Local DNS Records

**Option A: Asus Router DNS (Simplest)**
1. Asus admin → LAN → DHCP Server → DNS Server
2. Ensure DNS Server is set to: `192.168.1.1` (your Asus)
3. The router will automatically resolve hostnames from DHCP leases

**Option B: AdGuard Home + Unbound (When Deployed)**
1. Deploy AdGuard using Terraform: `./infrastructure-manager.sh deploy`
2. Access AdGuard admin: `http://192.168.1.11:3000`
3. Go to **DNS rewrites** (local DNS) and add records
4. Add custom records for consistent naming

### Step 3: Test Name Resolution

**Verification Commands:**
```bash
# Test hostname resolution
nslookup mediaserver
nslookup nas

# Test connectivity by name
ping mediaserver
ping nas

# Test service access
ssh user@mediaserver
http://grafana.homelab.local
```

**Expected Results:**
- ✅ Hostnames resolve to static IPs
- ✅ No more IP address hunting
- ✅ Consistent device connections

### Step 4: Advanced DNS Setup (Optional)

**Custom Domain Setup:**
- Set local domain: `homelab.local`
- Access services as: `plex.homelab.local`, `grafana.homelab.local`

**DNS Hierarchy:**
1. **Local DNS** (AdGuard/Asus) - Resolves local devices
2. **Upstream DNS** (Quad9/Cloudflare) - Resolves internet
3. **Fallback** - Google DNS (8.8.8.8)

### Benefits Achieved

- ✅ **No IP Dependencies** - Connect by name forever
- ✅ **Static Addresses** - IPs never change unexpectedly
- ✅ **Easy Access** - `ssh mediaserver` instead of `ssh 192.168.1.11`
- ✅ **Future-Proof** - Add new devices with consistent naming
- ✅ **Parental Controls** - Block sites by device name

**Ready to proceed?** Start with the diagnostic script to confirm current issues, then follow the migration steps. The unified network will solve your performance problems!
