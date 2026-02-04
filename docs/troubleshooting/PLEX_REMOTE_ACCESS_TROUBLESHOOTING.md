# Plex Remote Access Troubleshooting

**Issue**: Remote users cannot access Plex server libraries
**Server**: mediaserver (192.168.1.11)
**Date**: 2025-12-29
**Status**: ✅ **RESOLVED** - Port forwarding on Asus router fixed the issue

---

## 🔍 Quick Diagnostic Steps

### Step 1: Check Plex Remote Access Status

**On Server (192.168.1.11):**

```bash
# SSH into server
ssh youruser@192.168.1.11

# Check if Plex is running
docker ps | grep plex

# Check Plex logs for remote access errors
docker logs plex --tail 100 | grep -i "remote\|access\|port\|32400"

# Check if port 32400 is listening
sudo netstat -tlnp | grep 32400
# OR
sudo ss -tlnp | grep 32400
```

**Expected Output:**
- Plex container should be running
- Port 32400 should be listening on 0.0.0.0 or :::32400
- No "access denied" or "port closed" errors in logs

### Step 2: Check Plex Web UI Remote Access

1. **Access Plex Web UI:**
   - Local: http://192.168.1.11:32400/web
   - Or: http://localhost:32400/web (if on server)

2. **Check Remote Access Settings:**
   - Click: **Settings** (gear icon, top right)
   - Click: **Network** (left sidebar)
   - Scroll to: **Remote Access** section
   - Check status: Should show "Fully accessible outside your network"

3. **Current Status:**
   - ✅ **Green checkmark**: Remote access working
   - ⚠️ **Yellow warning**: Remote access partially working
   - ❌ **Red X**: Remote access not working

---

## 🚨 Common Issues & Fixes

### Issue #1: Remote Access Disabled in Plex

**Symptom:** Remote Access shows "Not available outside your network"

**Fix:**

1. **Enable Remote Access:**
   - Plex Web UI → Settings → Network → Remote Access
   - Click: **Enable Remote Access** button
   - Or toggle: **Manually specify public port**

2. **Configure Port:**
   - Public Port: `32400` (default)
   - Or: Custom port (requires router port forwarding)

3. **Save and Wait:**
   - Click: **Retry** or **Apply**
   - Wait 30-60 seconds for Plex to test connection
   - Check if status changes to "Fully accessible"

### Issue #2: Port Not Forwarded on Router ⭐ **MOST COMMON FIX**

**Symptom:** Plex shows "Not available outside your network" even when Remote Access is enabled

**Root Cause:** Router firewall blocking incoming connections - **This was the actual issue**

**Fix: Port Forwarding on Asus Router (CONFIRMED WORKING)**

1. **Access Router:**
   ```
   URL: http://192.168.1.1
   Login: (your credentials)
   ```

2. **Configure Port Forwarding:**
   - Navigate to: **WAN** → **Virtual Server / Port Forwarding**
   - Or: **Firewall** → **Port Forwarding**

3. **Add Rule:**
   ```
   Service Name: Plex
   External Port: 32400
   Internal Port: 32400
   Protocol: TCP (and UDP if available)
   Internal IP: 192.168.1.11
   Enable: Yes
   ```

4. **Save and Test:**
   - Save configuration
   - Wait 2-3 minutes for router to apply changes
   - Test in Plex Web UI (click Retry in Remote Access)

**Alternative: UPnP (Automatic)**

If your router supports UPnP:
- Plex Web UI → Settings → Network
- Enable: **Enable UPnP**
- Plex will automatically configure port forwarding
- Check status after 30-60 seconds

### Issue #3: Firewall Blocking Port

**Symptom:** Port forwarded but still not accessible

**Fix: Check Server Firewall**

```bash
# SSH into server
ssh youruser@192.168.1.11

# Check if firewall is running
sudo ufw status
# OR
sudo iptables -L -n | grep 32400

# If firewall is active, allow port 32400
sudo ufw allow 32400/tcp
sudo ufw allow 32400/udp

# Verify
sudo ufw status | grep 32400
```

**If using iptables directly:**
```bash
sudo iptables -A INPUT -p tcp --dport 32400 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 32400 -j ACCEPT
sudo iptables-save
```

### Issue #4: Double NAT / ISP Router Blocking

**Symptom:** Port forwarded but external users still can't connect

**Root Cause:** Xfinity modem in bridge mode, but may have firewall enabled

**Fix: Check Xfinity Modem**

1. **Access Xfinity Gateway:**
   ```
   URL: http://10.0.0.1 (if accessible)
   OR
   URL: http://gateway.xfinity.com
   ```

2. **Check Bridge Mode Status:**
   - Should show "Bridge Mode: Enabled"
   - If not, verify bridge mode is correctly configured

3. **If Not in Bridge Mode:**
   - May need to configure port forwarding on Xfinity gateway
   - Or ensure bridge mode is properly enabled

**Verify Double NAT:**
```bash
# From server, check default gateway
ip route | grep default

# Should show: default via 192.168.1.1 (Asus router)
# If shows 10.0.0.1, double NAT issue exists
```

### Issue #5: Plex Container Network Configuration

**Symptom:** Plex running but port not accessible

**Fix: Check Container Network**

```bash
# Check Plex container network mode
docker inspect plex --format '{{.HostConfig.NetworkMode}}'

# Should show: "host" (for direct port access)
# If shows "bridge" or other, port mapping may be needed
```

**If using host network (recommended):**
- Port should be directly accessible
- No port mapping needed in docker-compose

**If using bridge network:**
- Need port mapping: `"32400:32400"`
- Check docker-compose.yml for correct mapping

### Issue #6: Internet Upload Speed Too Low

**Symptom:** Remote access enabled but streams buffer/fail

**Fix: Configure Upload Speed in Plex**

1. **Plex Web UI → Settings → Network:**
   - Set: **Internet upload speed**: Your actual upload speed
   - Typical Xfinity: 35-40 Mbps
   - Set lower (30 Mbps) to account for overhead

2. **Limit Remote Quality:**
   - Settings → Remote Access
   - Set: **Limit remote stream bitrate**: 10 Mbps (1080p max)
   - Prevents exceeding upload bandwidth

---

## 🔧 Comprehensive Diagnostic Script

**Run on Server (192.168.1.11):**

```bash
#!/bin/bash
echo "🔍 Plex Remote Access Diagnostic"
echo "================================"
echo ""

# Check Plex container
echo "1. Plex Container Status:"
docker ps | grep plex
echo ""

# Check port listening
echo "2. Port 32400 Status:"
sudo netstat -tlnp | grep 32400 || sudo ss -tlnp | grep 32400
echo ""

# Check firewall
echo "3. Firewall Status:"
sudo ufw status | head -5
echo ""

# Check container network
echo "4. Plex Network Configuration:"
docker inspect plex --format 'Network Mode: {{.HostConfig.NetworkMode}}'
docker inspect plex --format 'Ports: {{.NetworkSettings.Ports}}'
echo ""

# Check Plex logs for errors
echo "5. Recent Plex Errors:"
docker logs plex --tail 50 | grep -iE "error|failed|denied|port|remote" | tail -10
echo ""

# Test local connection
echo "6. Local Connection Test:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:32400/web
echo ""

# Get public IP
echo "7. Public IP (for testing):"
curl -s ifconfig.me || curl -s ipinfo.io/ip
echo ""

echo "📋 Next Steps:"
echo "- Check router port forwarding (port 32400 → 192.168.1.11)"
echo "- Verify Plex Web UI shows 'Fully accessible outside your network'"
echo "- Test from external network: http://YOUR_PUBLIC_IP:32400/web"
```

**Save and run:**
```bash
# Save as diagnostic script
cat > plex_remote_diagnostic.sh << 'EOF'
# [paste script above]
EOF

chmod +x plex_remote_diagnostic.sh
./plex_remote_diagnostic.sh
```

---

## ✅ Step-by-Step Fix Procedure

### Complete Fix Process

1. **Enable Remote Access in Plex:**
   - Open Plex Web UI
   - Settings → Network → Remote Access
   - Click "Enable Remote Access"
   - Wait 60 seconds

2. **Check Status:**
   - If shows "Fully accessible" → Done!
   - If shows "Not available" → Continue to step 3

3. **Configure Router Port Forwarding:**
   - Access Asus router: http://192.168.1.1
   - Add port forward: 32400 → 192.168.1.11
   - Save and wait 2-3 minutes

4. **Check Server Firewall:**
   ```bash
   sudo ufw allow 32400/tcp
   sudo ufw allow 32400/udp
   ```

5. **Retest in Plex:**
   - Plex Web UI → Settings → Network → Remote Access
   - Click "Retry" button
   - Wait 60 seconds
   - Should show "Fully accessible"

6. **Test from External Network:**
   - Get public IP: `curl ifconfig.me` (from server)
   - From external device: `http://YOUR_PUBLIC_IP:32400/web`
   - Should load Plex login page

---

## 🔐 Security Considerations

### Secure Remote Access

1. **Use Strong Plex Password:**
   - Ensure all user accounts have strong passwords
   - Enable 2FA if available

2. **Limit Public Port Exposure:**
   - Consider using non-standard port (e.g., 8324)
   - Requires custom port forwarding

3. **VPN Access (More Secure):**
   - Connect remote users via VPN
   - Access Plex via local IP (192.168.1.11:32400)
   - More secure but requires VPN setup

---

## 📊 Expected Configuration

### Plex Settings (Web UI)

**Settings → Network:**
```
✅ Enable remote access: Yes
✅ Manually specify public port: 32400
✅ Internet upload speed: 35 Mbps (or your actual)
✅ Limit remote stream bitrate: 10 Mbps
```

**Settings → Remote Access:**
```
Status: Fully accessible outside your network
Public Address: http://YOUR_PUBLIC_IP:32400
```

### Router Configuration (Asus)

**Port Forwarding:**
```
Service Name: Plex Media Server
External Port: 32400
Internal Port: 32400
Protocol: TCP (and UDP)
Internal IP: 192.168.1.11
Enable: Yes
```

### Server Configuration

**Firewall:**
```bash
sudo ufw allow 32400/tcp
sudo ufw allow 32400/udp
```

**Container Network:**
- Network Mode: `host` (recommended)
- Port: 32400 (exposed directly)

---

## 🆘 Advanced Troubleshooting

### Check Router Logs

**Asus Router:**
- Admin Panel → System Log → Port Forwarding
- Check for blocked connections
- Verify port forwarding rules are active

### Test Port from External

**From External Network:**
```bash
# Test if port is open
telnet YOUR_PUBLIC_IP 32400
# OR
nc -zv YOUR_PUBLIC_IP 32400

# If connection successful, port is open
# If timeout, port forwarding issue
```

### Check ISP Blocking

**Some ISPs block common ports:**
- Contact ISP to verify port 32400 is not blocked
- May need to use alternative port (e.g., 8324)

### Verify Double NAT

**From Server:**
```bash
# Check default gateway
ip route | grep default

# Should show Asus router (192.168.1.1)
# If shows different IP, double NAT exists
```

---

## 📋 Verification Checklist

After implementing fixes:

- [ ] Plex Remote Access enabled in Web UI
- [ ] Status shows "Fully accessible outside your network"
- [ ] Router port forwarding configured (32400 → 192.168.1.11)
- [ ] Server firewall allows port 32400
- [ ] Container using host network mode
- [ ] Port 32400 listening on server
- [ ] Tested from external network (http://PUBLIC_IP:32400/web)
- [ ] Remote users can access libraries

---

## 🔄 Quick Test Commands

**From Server:**
```bash
# Test local access
curl http://localhost:32400/web

# Check port
sudo netstat -tlnp | grep 32400

# Check public IP
curl ifconfig.me
```

**From External Network:**
```bash
# Test public access
curl http://YOUR_PUBLIC_IP:32400/web

# Test port
telnet YOUR_PUBLIC_IP 32400
```

---

## 📚 Related Documentation

- [PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md](PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md) - External streaming configuration
- [SERVER_AUDIT_ANALYSIS.md](SERVER_AUDIT_ANALYSIS.md) - Server configuration details
- [docs/plex_docker_compose.md](docs/plex_docker_compose.md) - Container configuration

---

**Priority**: 🔴 **HIGH** - Blocks remote user access
**Time to Fix**: 15-30 minutes
**Impact**: Remote users cannot stream content

