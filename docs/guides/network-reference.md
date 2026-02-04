# Network Configuration Reference

**Last Updated**: 2025-12-29
**Purpose**: Quick reference for network configuration settings

---

## 🔌 Router Configuration

### Asus Nighthawk RAX50

**Access:** http://192.168.1.1
**Network:** 192.168.1.0/24
**Gateway:** 192.168.1.1
**DHCP Range:** 192.168.1.100 - 192.168.1.200

---

## 🔀 Port Forwarding Rules

### Required Port Forwarding

#### Plex Media Server ✅ CONFIGURED

```
Service Name: Plex Media Server
External Port: 32400
Internal Port: 32400
Protocol: TCP
Internal IP: 192.168.1.11
Status: ✅ Active
Last Updated: 2025-12-29
Issue: Remote users couldn't access libraries
Resolution: Port forwarding configuration fixed issue
```

**Router Location:** WAN → Virtual Server / Port Forwarding

**Verification:**
- Plex Web UI → Settings → Network → Remote Access
- Should show: "Fully accessible outside your network"
- Test: http://YOUR_PUBLIC_IP:32400/web (from external network)

---

## 🌐 Network Services

### Plex Media Server

**Local Access:**
- URL: http://192.168.1.11:32400/web
- Port: 32400
- Network: Host mode (Docker)

**Remote Access:**
- Public Port: 32400
- Requires: Port forwarding configured ✅
- Status: ✅ Working (as of 2025-12-29)

### STARR Stack Services

**Access via Gluetun VPN:**
- Radarr: http://192.168.1.11:7878
- Sonarr: http://192.168.1.11:8989
- qBittorrent: http://192.168.1.11:8080
- Prowlarr: http://192.168.1.11:9696
- FlareSolverr: http://192.168.1.11:8191

**Note:** These are VPN-protected and not exposed externally (by design)

### Monitoring Stack

**Local Access:**
- Grafana: http://192.168.1.11:3000
- Prometheus: http://192.168.1.11:9090
- Node Exporter: http://192.168.1.11:9100

**Note:** Not exposed externally (internal monitoring only)

---

## 📍 Static IP Assignments

### Server Devices

| Device | IP Address | Purpose |
|--------|-----------|---------|
| Asus Router | 192.168.1.1 | Gateway, DHCP, DNS |
| Media Server | 192.168.1.11 | Docker containers, Plex |
| Synology NAS | 192.168.1.20 | Media storage |

---

## 🔧 Common Configuration Tasks

### Add New Port Forwarding Rule

1. Access router: http://192.168.1.1
2. Navigate: WAN → Virtual Server / Port Forwarding
3. Click: Add / Create New Rule
4. Configure:
   - Service Name: [Descriptive name]
   - External Port: [Public port]
   - Internal Port: [Service port]
   - Protocol: TCP / UDP / Both
   - Internal IP: [Target device IP]
5. Save and wait 2-3 minutes
6. Test from external network

### Verify Port Forwarding

**From External Network:**
```bash
# Test port connectivity
telnet YOUR_PUBLIC_IP PORT_NUMBER
# OR
nc -zv YOUR_PUBLIC_IP PORT_NUMBER

# Test HTTP service
curl http://YOUR_PUBLIC_IP:PORT_NUMBER
```

**From Router:**
- Check port forwarding list
- Verify rule is enabled
- Check internal IP is correct

---

## 🔒 Security Notes

### Exposed Services

**Currently Exposed:**
- Plex (Port 32400) - Required for remote access

**Recommendations:**
- Keep exposed ports to minimum
- Use strong passwords for all services
- Monitor access logs regularly
- Consider VPN for additional services if needed

### Internal Services (Not Exposed)

These services are intentionally not exposed externally:
- STARR Stack (VPN-protected)
- Monitoring Stack (internal only)
- Portainer (internal management)

---

## 📚 Related Documentation

- [PLEX_REMOTE_ACCESS_TROUBLESHOOTING.md](PLEX_REMOTE_ACCESS_TROUBLESHOOTING.md) - Plex remote access setup
- [docs/network-setup.md](docs/network-setup.md) - Complete network setup guide
- [NETWORK_MIGRATION_PLAN.md](NETWORK_MIGRATION_PLAN.md) - Network migration details

---

**Status**: ✅ Port forwarding configured and verified
**Last Verified**: 2025-12-29

