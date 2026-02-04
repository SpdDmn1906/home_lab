# DNS Name Resolution Setup Guide

## Overview

This guide shows you how to set up proper DNS name resolution for your home lab devices so you can connect using hostnames instead of IP addresses, even if IPs change.

## Current Situation

Your Asus router is currently handling DHCP and DNS, but devices are accessed by IP addresses that can change. We need to:

1. **Reserve static IP addresses** for key devices
2. **Set up local DNS resolution** for hostname access
3. **Configure proper naming conventions**

## Step 1: Static DHCP Leases (Most Important)

### Why Static IPs?
- IPs never change unexpectedly
- Hostnames resolve consistently
- Easier device management
- Better for services and automation

### Asus Router Static IP Setup

1. **Access Router Admin:**
   - Open browser: `http://192.168.1.1`
   - Login with your credentials

2. **Navigate to DHCP Settings:**
   - **Advanced Settings** → **LAN** → **DHCP Server**
   - Find **"Enable Manual Assignment"** section

3. **Add Static Leases:**

   Click **"Add"** or **"+"** button and add these entries:

   | Device | Hostname | MAC Address | IP Address |
   |--------|----------|-------------|------------|
| Media Server | mediaserver | `XX:XX:XX:XX:XX:XX` | 192.168.1.11 |
   | Synology NAS | nas | `XX:XX:XX:XX:XX:XX` | 192.168.1.20 |
| Gaming PC | gaming-pc | `XX:XX:XX:XX:XX:XX` | 192.168.1.30 |
| PS5 | ps5 | `XX:XX:XX:XX:XX:XX` | 192.168.1.40 |
   | Nintendo Switch | switch | `XX:XX:XX:XX:XX:XX` | 192.168.1.41 |
   | iPad Child1 | child1-ipad | `XX:XX:XX:XX:XX:XX` | 192.168.1.50 |
   | iPad Child2 | child2-ipad | `XX:XX:XX:XX:XX:XX` | 192.168.1.51 |

4. **Find MAC Addresses:**
   - **Current DHCP Clients:** Asus admin → LAN → DHCP Server → Client List
   - **Device Settings:** Check each device:
     - **Windows:** Settings → Network → Hardware Address
     - **macOS:** System Settings → WiFi → Details → Hardware Address
     - **iPad/iPhone:** Settings → WiFi → Network Name → Info icon
     - **PS5:** Settings → Network → Settings → View Connection Status

5. **Save and Apply:**
   - Click **"Apply"** button
   - Router will restart DHCP service
   - Devices will get their static IPs on next connection

## Step 2: Test Static IP Assignment

### Verification Steps:

1. **Reconnect Devices:**
   ```bash
   # Disconnect and reconnect each device from WiFi
   # Or restart devices to get new IP assignments
   ```

2. **Check IP Assignments:**
   ```bash
   # From each device, check assigned IP:
   ipconfig /all    # Windows
   ifconfig         # macOS/Linux
   # Or check router admin → DHCP Client List
   ```

3. **Verify Static IPs:**
- Media Server: Should be 192.168.1.11
   - NAS: Should be 192.168.1.20
   - PS5: Should be 192.168.1.40
   - iPads: Should be 192.168.1.50/51

## Step 3: Test Hostname Resolution

### Basic Testing:

1. **From any device on your network:**
   ```bash
   # Test ping by hostname
   ping mediaserver
   ping nas
   ping ps5

   # Should resolve to correct static IPs
   ```

2. **If hostnames don't resolve:**
   - **Windows:** May need to disable NetBIOS or adjust DNS settings
   - **macOS:** Usually works automatically
   - **iOS:** Usually works automatically

## Step 4: Advanced DNS Setup (Optional)

### Option A: Custom Domain Names

**Add `.homelab.local` domain:**
1. Asus admin → LAN → DHCP Server
2. Set **"Domain Name"** to: `homelab.local`
3. Now access devices as:
   - `mediaserver.homelab.local`
   - `nas.homelab.local`
   - `plex.homelab.local`

### Option B: AdGuard Home + Unbound (Recommended)

**Enhanced DNS with AdGuard Home:**
1. Deploy AdGuard Home (Terraform module or `docker/adguard/docker-compose.yml`)
2. Access AdGuard admin UI: `http://192.168.1.11:3000`
3. Configure **Upstream DNS** to use Unbound (`unbound:53`) if deployed together
4. Add **DNS rewrites** (local hostnames) for better organization

## Step 5: Service Access by Name

### Common Service URLs:

**With Hostnames:**
```
Plex:          http://mediaserver:32400
Grafana:       http://mediaserver:3000
SSH to server: ssh user@mediaserver
NAS access:    \\nas or smb://nas
PS5 remote:    Use ps5 hostname in apps
```

**With Domain Names (Optional):**
```
Plex:          http://plex.homelab.local
Grafana:       http://grafana.homelab.local
Prometheus:    http://prometheus.homelab.local
```

## Step 6: Troubleshooting

### Common Issues:

1. **Hostnames Don't Resolve:**
   ```bash
   # Check DNS server
   nslookup mediaserver 192.168.1.1

   # Clear DNS cache
   ipconfig /flushdns    # Windows
   sudo dscacheutil -flushcache  # macOS
   ```

2. **Wrong IP Assigned:**
   - Check Asus router DHCP client list
   - Verify MAC address in static lease
   - Remove and re-add the static lease

3. **Device Not Getting Static IP:**
   - Force device to renew DHCP lease
   - Restart device
   - Check if MAC address is correct

4. **Parental Controls Breaking:**
   - Update parental control rules to use hostnames instead of IPs
   - Test time restrictions with new static IPs

## Step 7: Maintenance

### Regular Tasks:

1. **Monitor Static Leases:**
   - Check router admin periodically
   - Ensure all devices have correct static IPs

2. **Add New Devices:**
   - Get MAC address of new device
   - Add static lease in Asus router
   - Test hostname resolution

3. **Update Documentation:**
   - Keep track of device hostnames and IPs
   - Update network diagrams

## Benefits Achieved

✅ **Reliable Access:** Connect to devices by name, not IP
✅ **No IP Hunting:** Never search for device addresses again
✅ **Consistent Connections:** IPs don't change unexpectedly
✅ **Easy Sharing:** Share device names instead of confusing IPs
✅ **Future-Proof:** Add new devices with predictable naming
✅ **Automation Ready:** Scripts and configs use stable hostnames

## Next Steps

1. **Set up static DHCP leases** for your key devices
2. **Test hostname resolution** from different devices
3. **Update bookmarks/shortcuts** to use hostnames
4. **Deploy AdGuard Home + Unbound** for enhanced DNS features (recommended)
5. **Configure parental controls** using hostnames (optional)

---

**With DNS name resolution set up, your home lab will be much easier to manage and access reliably!** 🎯
