# Eero Latency Fix - Step-by-Step Guide

**Issue**: High latency on "SC Home_Ext" (Eero mesh) - 34-35ms average, spikes to 210ms
**Status**: ⚠️ **CRITICAL** - Not suitable for 4K streaming
**Solution**: Channel optimization and configuration fixes

> **Scope note (2025-12-30)**: This guide targets **Wi‑Fi/mesh latency**.
> If Plex is “freezing” even on `SC Home` and especially when Direct Play is reported, also review:
> - [PLEX_PLAYBACK_FREEZING_INVESTIGATION.md](PLEX_PLAYBACK_FREEZING_INVESTIGATION.md)

---

## 🎯 Quick Fix (30 minutes)

### Step 1: Check Asus Router Channel (5 minutes)

1. **Access Asus Router:**
   ```
   URL: http://192.168.1.1
   Login: (your credentials)
   ```

2. **Find 5GHz Channel:**
   - Navigate to: **Wireless** → **Professional** (or **5GHz** settings)
   - Note: **Current 5GHz Channel** (e.g., 36, 149, etc.)
   - Note: **Channel Bandwidth** (20/40/80MHz)

3. **Document:**
   ```
   Asus 5GHz Channel: ______
   Asus Bandwidth: ______ MHz
   ```

### Step 2: Change Eero Channel (10 minutes)

1. **Open Eero App:**
   - Launch Eero app on your phone
   - Ensure you're on the network

2. **Access Channel Settings:**
   - Tap: **Settings** (bottom right)
   - Tap: **Network Settings**
   - Tap: **Advanced Settings**
   - Look for: **Channel Selection** or **WiFi Settings**

3. **Change Channel:**

   **Option A: Automatic (Easiest)**
   - Enable "Automatic Channel Selection"
   - Eero will choose best channel
   - Wait 5 minutes for change to apply

   **Option B: Manual (Recommended)**
   - Disable automatic
   - Select **High Band (149-165)** if Asus on Low/Mid
   - Or select **Low Band (36-48)** if Asus on High
   - **Reduce bandwidth to 40MHz** (less interference)

4. **Save and Wait:**
   - Save changes
   - Wait 5-10 minutes for Eero to reconfigure
   - Nodes will restart automatically

### Step 3: Test Latency (15 minutes)

1. **Connect to "SC Home_Ext":**
   - On your Mac, connect to "SC Home_Ext" WiFi
   - Wait for connection to stabilize

2. **Run Diagnostic:**
   ```bash
   cd ~/Documents/Personal/home_lab
   ./advanced_network_diagnostics.sh
   ```

3. **Compare Results:**
   ```
   Before: 34-35ms avg, 41-53ms stddev, spikes to 210ms
   Target: <20ms avg, <10ms stddev, spikes <50ms
   ```

4. **If Still High:**
   - Try different channel (if manual mode)
   - Reduce bandwidth further (20MHz)
   - Check node placement (next step)

---

## 🔧 Advanced Fixes (If Quick Fix Doesn't Work)

### Fix #2: Optimize Eero Node Placement

**Check Signal Strength:**
1. Eero app → **Network** → **Devices**
2. Check signal strength for each node
3. Look for "Weak" or "Fair" connections

**Reposition Nodes:**
- Move nodes closer together (if too far)
- Ensure line-of-sight where possible
- Avoid interference sources:
  - Microwaves
  - Metal objects
  - Thick walls
  - Other electronics

**Ideal Placement:**
- Gateway node: Near Asus router (Ethernet connection)
- Satellite nodes: 30-50 feet apart
- All nodes: Same floor (if possible)

### Fix #3: Use Ethernet Backhaul (Best Performance)

**If Possible:**
1. Connect Eero gateway node to Asus router via Ethernet
2. Connect satellite nodes to gateway via Ethernet (if possible)
3. This eliminates WiFi backhaul issues

**Benefits:**
- Eliminates mesh backhaul latency
- More stable connection
- Better performance

### Fix #4: Reduce Network Load

**Move High-Bandwidth Devices:**
1. **Move to "SC Home" (Asus):**
   - Plex streaming devices
   - Gaming consoles
   - 4K-capable devices
   - High-bandwidth devices

2. **Keep on "SC Home_Ext" (Eero):**
   - IoT devices (smart plugs, bulbs)
   - Low-bandwidth devices
   - Devices far from Asus router

---

## 📊 Expected Results

### Before Fix
```
Asus Router (192.168.1.1):
  Average: 34-35ms
  Stddev: 41-53ms
  Spikes: Up to 210ms
  Status: 🔴 NOT SUITABLE FOR 4K
```

### After Fix (Target)
```
Asus Router (192.168.1.1):
  Average: <20ms (ideally <15ms)
  Stddev: <10ms (ideally <5ms)
  Spikes: <50ms (ideally <30ms)
  Status: ✅ SUITABLE FOR STREAMING
```

---

## ✅ Verification Checklist

After implementing fixes:

- [ ] Eero channel changed to non-overlapping
- [ ] Eero bandwidth reduced to 40MHz (or 20MHz)
- [ ] All Eero nodes restarted
- [ ] Reconnected to "SC Home_Ext" network
- [ ] Ran diagnostic: `./advanced_network_diagnostics.sh`
- [ ] Latency improved: <20ms average
- [ ] Variability reduced: <10ms stddev
- [ ] Spikes reduced: <50ms maximum
- [ ] Tested with Plex streaming (no buffering)

---

## 🎯 Impact on Your Goals

### Immediate Action Required

**For 4K Goals:**
- ✅ **Use "SC Home" (Asus) for ALL 4K devices** (immediate)
- ⚠️ **Do NOT use "SC Home_Ext" (Eero) for 4K until fixed**
- 🔴 Current Eero latency (34-35ms, spikes 210ms) will cause 4K buffering

**Device Assignment:**
- **"SC Home" (Asus)**: 4K streaming devices, Plex clients, gaming consoles
- **"SC Home_Ext" (Eero)**: IoT devices, low-bandwidth devices (until fixed)

### After Fix

Once Eero latency is <20ms:
- Can use for 1080p streaming
- Can use for general devices
- Still recommend Asus for 4K (better performance)

---

## 🆘 Troubleshooting

### Latency Still High After Channel Change

**Try:**
1. **Different Channel:**
   - If tried High band, try Low band (or vice versa)
   - Use 20MHz bandwidth (maximum compatibility)

2. **Check Node Placement:**
   - Move nodes closer together
   - Check signal strength in Eero app

3. **Restart Everything:**
   - Restart all Eero nodes
   - Restart Asus router
   - Restart your device

4. **Test with Ethernet:**
   - Connect device directly to Eero via Ethernet
   - If latency improves, it's WiFi issue
   - If still high, it's Eero configuration issue

### Still Not Working

**Consider:**
1. **Disable Eero WiFi:**
   - Use Eero nodes as Ethernet switches only
   - All WiFi via Asus "SC Home"

2. **Replace Eero:**
   - Consider Asus AiMesh nodes (better integration)
   - Or additional Asus access points

3. **Accept Limitation:**
   - Use Asus for all streaming
   - Use Eero for IoT only

---

## 📚 Related Documentation

- [EERO_LATENCY_ANALYSIS.md](EERO_LATENCY_ANALYSIS.md) - Complete analysis
- [PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md](PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md) - 4K goals
- [NETWORK_SERVICE_AND_CIFS_FIXES.md](NETWORK_SERVICE_AND_CIFS_FIXES.md) - Network config

---

**Priority**: 🔴 **HIGH** - Affects 4K streaming capability
**Time**: 30 minutes (quick fix)
**Impact**: Enables Eero network for streaming (after fix)

