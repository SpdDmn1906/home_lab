# Fix Browser Access to Radarr/Sonarr/qBittorrent

**Problem**: Browsers say "unreachable" but curl works
**Impact**: Can't access web UIs to manage media
**Status**: Ports are open, services respond, laptop can connect

---

## 🎯 **QUICK FIXES** (Try These First)

### **1. Open with Terminal Command**

Instead of typing in browser, use Terminal to launch:

```bash
# Open all services:
open http://192.168.1.11:7878  # Radarr
open http://192.168.1.11:8989  # Sonarr
open http://192.168.1.11:8080  # qBittorrent
open http://192.168.1.11:32400/web  # Plex
```

This bypasses any browser auto-complete or proxy issues.

---

### **2. Try Safari Specifically**

```bash
# Force Safari:
open -a Safari http://192.168.1.11:7878
open -a Safari http://192.168.1.11:8989
open -a Safari http://192.168.1.11:8080
```

---

### **3. Check macOS Network Settings**

1. Open **System Preferences** → **Network**
2. Select **Wi-Fi** (left sidebar)
3. Click **Advanced** (bottom right)
4. Go to **Proxies** tab
5. **UNCHECK ALL** proxy options:
   - ☐ Auto Proxy Discovery
   - ☐ Automatic Proxy Configuration
   - ☐ Web Proxy (HTTP)
   - ☐ Secure Web Proxy (HTTPS)
   - ☐ SOCKS Proxy
   - ☐ FTP Proxy
   - ☐ Streaming Proxy (RTSP)
6. Click **OK** → **Apply**
7. Try browsers again

---

### **4. Check Browser Proxy Settings**

**Chrome/Brave/Edge:**
```
1. Settings → Search "proxy"
2. Click "Open your computer's proxy settings"
3. Make sure all proxies are OFF
4. Restart browser
```

**Firefox:**
```
1. Settings → General
2. Scroll to "Network Settings"
3. Click "Settings"
4. Select "No proxy"
5. Click OK
6. Restart Firefox
```

**Safari:**
```
Safari → Settings → Advanced → Proxies → Change Settings
(Should use System Settings from step 3 above)
```

---

## 🔍 **DIAGNOSTIC TESTS**

### **Test 1: Verify Network Connectivity**

```bash
# Run this in Terminal:
curl -v http://192.168.1.11:7878 2>&1 | grep -E "Connected|HTTP"
```

**Expected output:**
```
* Connected to 192.168.1.11 (192.168.1.11) port 7878
< HTTP/1.1 401 Unauthorized
```

If you see "Connected" and "HTTP", network is fine - it's a browser issue.

---

### **Test 2: Check for VPN or Security Software**

Do you have any of these installed?

**VPNs:**
- [ ] ExpressVPN
- [ ] NordVPN
- [ ] Private Internet Access (PIA)
- [ ] ProtonVPN
- [ ] Surfshark
- [ ] Other VPN?

**Security Software:**
- [ ] Little Snitch (firewall)
- [ ] Lulu (firewall)
- [ ] Malwarebytes
- [ ] Norton/Symantec
- [ ] McAfee
- [ ] Kaspersky
- [ ] Corporate security software

**If YES to any**: Temporarily **disable** it and test browser access.

---

### **Test 3: Check Browser Extensions**

Disable these types of extensions:
- **Ad blockers** (uBlock Origin, AdBlock Plus)
- **Privacy extensions** (Privacy Badger, Ghostery)
- **Security extensions** (HTTPS Everywhere)
- **VPN extensions**

**Quick test:**
- Open **Incognito/Private mode** (Cmd+Shift+N in Chrome, Cmd+Shift+P in Firefox)
- Try: `http://192.168.1.11:7878`
- If it works in incognito → An extension is blocking

---

### **Test 4: DNS Resolution**

```bash
# Check DNS:
nslookup 192.168.1.11
```

**Expected**: Should return the IP without issues.

---

### **Test 5: Check Hosts File**

```bash
# Check if 192.168.1.11 is blocked:
cat /etc/hosts | grep 192.168.1.11
```

**Expected**: No output (no entries for this IP).

**If you see entries**, they might be blocking access. Remove them:
```bash
sudo nano /etc/hosts
# Delete any lines with 192.168.1.11
# Press Ctrl+X, Y, Enter to save
```

---

## 🛠️ **ADVANCED FIXES**

### **Fix 1: Clear Browser Cache**

**Chrome/Brave:**
```
Cmd+Shift+Delete →
Select "All time" →
Check:
  ☑ Browsing history
  ☑ Cookies
  ☑ Cached images and files
  ☑ Hosted app data
→ Clear data
```

**Firefox:**
```
Cmd+Shift+Delete →
Select "Everything" →
Check:
  ☑ Browsing & Download History
  ☑ Cookies
  ☑ Cache
→ Clear Now
```

**Safari:**
```
Safari → Clear History →
Select "all history" →
Clear History
```

---

### **Fix 2: Flush DNS Cache (macOS)**

```bash
# Flush DNS:
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Test again:
open http://192.168.1.11:7878
```

---

### **Fix 3: Reset Network Settings**

**Last resort:**
```bash
# Turn Wi-Fi off/on:
networksetup -setairportpower en0 off
sleep 2
networksetup -setairportpower en0 on

# Wait for reconnection, then test
```

---

## 🚨 **IF STILL NOT WORKING**

### **Workaround: Use Mobile Device**

While troubleshooting laptop:
1. Connect phone/tablet to "SC Home" network
2. Open browser on mobile
3. Go to: `http://192.168.1.11:7878`
4. Manage Radarr from mobile temporarily

---

### **Alternative: Terminal-Based Management**

You can manage everything via Terminal:

**Check Radarr missing movies:**
```bash
sshpass -p "$SSH_PASSWORD" ssh youruser@192.168.1.11 'RADARR_KEY=$(docker exec radarr cat /config/config.xml | grep "<ApiKey>" | sed "s/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/"); curl -s -H "X-Api-Key: $RADARR_KEY" "http://localhost:7878/api/v3/wanted/missing?pageSize=25" | grep -o "\"title\":\"[^\"]*\"" | cut -d\" -f4'
```

**Trigger Radarr search:**
```bash
sshpass -p "$SSH_PASSWORD" ssh youruser@192.168.1.11 'RADARR_KEY=$(docker exec radarr cat /config/config.xml | grep "<ApiKey>" | sed "s/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/"); curl -s -X POST -H "X-Api-Key: $RADARR_KEY" "http://localhost:7878/api/v3/command" -d "{\"name\": \"missingMoviesSearch\"}"'
```

---

## ✅ **SUCCESS CHECKLIST**

Once browser access works, you should see:

- [ ] **Radarr login page** or dashboard at `http://192.168.1.11:7878`
- [ ] **Sonarr dashboard** at `http://192.168.1.11:8989`
- [ ] **qBittorrent login** at `http://192.168.1.11:8080`
- [ ] **Plex web interface** at `http://192.168.1.11:32400/web`

**Then proceed to**: `RADARR_MANUAL_FIX_GUIDE.md` to fix the missing movies issue!

---

## 📞 **WHAT TO TRY FIRST**

Priority order:
1. ✅ Use Terminal `open` commands (easiest)
2. ✅ Check/disable proxy settings (most common cause)
3. ✅ Try Safari if using Chrome/Firefox
4. ✅ Disable VPN/security software
5. ✅ Clear browser cache
6. ✅ Test in incognito mode
7. ✅ Check browser extensions

**One of these will work!** 🎯

