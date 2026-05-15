# Eero Mesh Latency Analysis & Resolution

**Date**: 2025-12-29
**Issue**: High latency on "SC Home_Ext" (Eero mesh network)
**Status**: ✅ **LATENCY IMPROVED** - See [NETWORK_LATENCY_IMPROVEMENT_ANALYSIS.md](NETWORK_LATENCY_IMPROVEMENT_ANALYSIS.md) for latest results

> **2026-02-06 Update**: Confirmed "Node Failure" congestion mode.
> When Eero Node 3 ("Garage") went offline, the Nest Cam roamed to Node 2 ("Living Room"), causing congestion that affected the TV on the same node.
> **Fix**: Reconnecting Node 3 resolved the congestion. TV latency dropped to ~3ms.
> **Lesson**: If Eero latency spikes, check for offline nodes causing "crowding" on remaining nodes.

> **2025-12-30 Note**: Not all Plex “freezing” symptoms are caused by Eero latency.
> During live testing, we identified **server USB topology risks** (USB NIC + USB media drive on the same hub) and **client receiver-window stalls** that can manifest even on `SC Home`.
> See: [PLEX_PLAYBACK_FREEZING_INVESTIGATION.md](PLEX_PLAYBACK_FREEZING_INVESTIGATION.md).

---

## 🔍 Diagnostic Results Analysis

### Test Results Summary

**Test Environment:**
- Network: "SC Home_Ext" (Eero mesh)
- Testing from: Mac (WiFi connected)
- Concurrent activity: Plex 1080p stream running
- **User Confirmed**: Switching to "SC Home" (Asus) resolved issues ✅

### Key Findings

#### 1. **Asus Router Latency (192.168.1.1)**

**Test 1:**
- Min/Avg/Max: 6.442 / 34.428 / 116.576 ms
- Standard Deviation: 41.083 ms (HIGH VARIABILITY)
- Packet Loss: 0%

**Test 2:**
- Min/Avg/Max: 6.586 / 35.218 / 155.195 ms
- Standard Deviation: 52.922 ms (VERY HIGH VARIABILITY)
- Packet Loss: 0%

**Detailed Test:**
- Spikes observed: 16ms → 66ms → **210ms** → 7ms (stabilizing)
- Pattern: Initial high latency, then stabilizes to 5-10ms

**Analysis:**
- ⚠️ **High average latency** (34-35ms) - Should be <10ms
- 🔴 **Extreme spikes** (up to 210ms) - Indicates interference or congestion
- ⚠️ **High variability** (stddev 41-53ms) - Unstable connection
- ✅ **Stabilizes after initial spikes** - Suggests buffer/queue issues

#### 2. **Internet Gateway Latency (8.8.8.8)**

**Test 1:**
- Min/Avg/Max: 16.457 / 25.501 / 33.618 ms
- Standard Deviation: 5.522 ms
- Packet Loss: 0%

**Test 2:**
- Min/Avg/Max: 15.692 / 19.852 / 23.889 ms
- Standard Deviation: 3.205 ms
- Packet Loss: 0%

**Detailed Test:**
- Spikes: 138ms, 122ms, 96ms, 159ms
- Normal: 17-27ms

**Analysis:**
- ⚠️ **Spikes up to 159ms** - Should be consistent 20-25ms
- ✅ **Average acceptable** (20-25ms) - Normal for internet
- ⚠️ **Intermittent spikes** - Network congestion or routing issues

#### 3. **Xfinity Modem Latency (10.0.0.1)**

**Test Results:**
- Min/Avg/Max: 4.519 / 5.205 / 6.200 ms
- Standard Deviation: 0.690 ms
- Packet Loss: 0%

**Analysis:**
- ✅ **Excellent performance** - Stable, low latency
- ✅ **No issues** - Modem working correctly

#### 4. **DNS Resolution**

**Test Results:**
- Resolution time: 0.040-0.073 seconds
- Status: ✅ Working correctly
- Server: 192.168.1.1 (Asus router)

**Analysis:**
- ✅ **DNS working fine** - Not the issue

---

## 🎯 Root Cause Analysis

### Primary Issue: Eero Mesh Network Instability

**Evidence:**
1. ✅ **"SC Home" (Asus) works perfectly** - User confirmed (switching resolved issues)
2. ⚠️ **"SC Home_Ext" (Eero) shows latency** - This analysis
3. 🔴 **High latency spikes** (up to 210ms to router) - **CRITICAL**
4. ⚠️ **High variability** (stddev 41-53ms) - **UNSTABLE**
5. ⚠️ **Pattern**: Initial spikes then stabilization - Suggests buffer/queue issues

### Likely Causes

#### 1. **WiFi Channel Interference** (Most Likely - HIGH PROBABILITY)

**Problem:**
- Eero mesh nodes on channel 36 (5GHz, 80MHz)
- Asus router likely on overlapping or adjacent channel
- Both networks broadcasting on same frequency band
- Channel overlap causing interference and retransmissions

**Evidence:**
- Initial spikes then stabilization (typical of interference)
- High variability (channel conflict pattern)
- Works fine on Asus network (isolated to Eero)
- **User confirmed**: Asus network works perfectly

**Impact:**
- Causes packet retransmissions
- Increases latency
- Reduces throughput
- Affects all devices on Eero network

#### 2. **Eero Mesh Backhaul Issues**

**Problem:**
- Eero nodes communicating via WiFi backhaul
- Backhaul congestion or interference
- Node placement causing poor signal

**Evidence:**
- Latency spikes during high activity (Plex streaming)
- Stabilizes when traffic reduces

#### 3. **Buffer/Queue Congestion**

**Problem:**
- Eero mesh buffers filling during high traffic
- Queue management issues
- Bandwidth contention between nodes

**Evidence:**
- Initial high latency, then stabilizes
- Spikes correlate with activity

#### 4. **Eero Bridge Mode Configuration**

**Problem:**
- Eero in bridge mode but may have configuration issues
- DHCP conflicts (though not detected)
- Routing inefficiencies

**Evidence:**
- Works on Asus (primary router)
- Issues only on Eero network

---

## ✅ Resolution Steps

### Immediate Fixes (Try First)

#### Fix #1: Optimize Eero Channel Selection (HIGH PRIORITY)

**Goal:** Avoid interference with Asus router

**Steps:**
1. **Check Asus Router Channels:**
   ```bash
   # Access Asus router admin: http://192.168.1.1
   # Navigate to: Wireless → Professional
   # Note current 5GHz channel and bandwidth (20/40/80MHz)
   ```

2. **Identify Non-Overlapping Channels:**
   - **5GHz Channel Groups:**
     - Low: 36-48 (DFS channels, 80MHz uses 36-48)
     - Mid: 52-64 (DFS channels)
     - High: 149-165 (non-DFS, best for avoiding interference)

   - **If Asus on Low (36-48)**: Use High (149-165) for Eero
   - **If Asus on High (149-165)**: Use Low (36-48) for Eero
   - **If Asus on Mid (52-64)**: Use High (149-165) for Eero

3. **Change Eero Channels:**
   - Open Eero app
   - Settings → Network Settings → Advanced → Channel Selection
   - **Option A**: Enable "Automatic" (Eero will choose best channel)
   - **Option B**: Manual selection (choose non-overlapping channel)
   - **Recommended**: Use High band (149-165) if available

4. **Reduce Eero Bandwidth:**
   - Change from 80MHz to 40MHz (less interference, still fast)
   - Or use 20MHz for maximum compatibility

5. **Test After Change:**
   ```bash
   # Re-run diagnostic on "SC Home_Ext" network
   ./advanced_network_diagnostics.sh
   ./troubleshoot_eero_latency_detailed.sh

   # Compare results:
   # Before: 34-35ms avg, 41-53ms stddev, spikes to 210ms
   # Target: <20ms avg, <10ms stddev, spikes <50ms
   ```

#### Fix #2: Optimize Eero Node Placement

**Goal:** Improve mesh backhaul performance

**Steps:**
1. **Check Node Signal Strength:**
   - Eero app → Network → Check signal strength
   - Ensure nodes have good connection to each other

2. **Reposition Nodes:**
   - Place nodes closer together (if too far)
   - Avoid interference sources (microwaves, metal, etc.)
   - Ensure line-of-sight where possible

3. **Use Ethernet Backhaul (If Possible):**
   - Connect Eero nodes via Ethernet (best performance)
   - Eliminates WiFi backhaul issues

#### Fix #3: Update Eero Firmware

**Goal:** Fix any known bugs

**Steps:**
1. Open Eero app
2. Check for firmware updates
3. Update all nodes
4. Restart network

#### Fix #4: Reduce Eero Network Load

**Goal:** Minimize congestion

**Steps:**
1. **Move High-Bandwidth Devices to Asus:**
   - Connect Plex server to Asus (wired or "SC Home" WiFi)
   - Move streaming devices to "SC Home" network
   - Use "SC Home_Ext" for IoT/low-bandwidth devices

2. **Limit Devices on Eero:**
   - Move devices to Asus network where possible
   - Reduce concurrent connections on Eero

---

### Advanced Fixes (If Immediate Fixes Don't Work)

#### Fix #5: Disable Eero WiFi (Use Ethernet Only)

**If Eero WiFi Issues Persist:**

**Option:** Use Eero nodes as Ethernet switches only
- Disable WiFi on Eero nodes
- Use Ethernet ports for wired connections
- All WiFi via Asus "SC Home" network

**Steps:**
1. Eero app → Settings → Advanced
2. Disable WiFi (if option available)
3. Or physically disable via Eero settings

#### Fix #6: Separate Eero Network Completely

**Alternative Approach:**
- Keep Eero as separate network for specific devices
- Use Asus "SC Home" for primary devices
- Configure routing between networks if needed

#### Fix #7: Replace Eero with Additional Asus Access Points

**If Issues Continue:**
- Consider replacing Eero with Asus AiMesh nodes
- Unified network management
- Better integration with existing router

---

## 📊 Performance Targets

### Expected Performance

**Asus Router ("SC Home"):**
- Latency: <10ms average
- Variability: <5ms stddev
- Status: ✅ **Achieved** (user confirmed - switching resolved issues)

**Eero Mesh ("SC Home_Ext"):**
- Target Latency: <20ms average (ideally <15ms)
- Target Variability: <10ms stddev (ideally <5ms)
- Current: **34-35ms average, 41-53ms stddev** ⚠️
- Current Spikes: **Up to 210ms** 🔴
- Status: ⚠️ **Needs Improvement** - **Not suitable for 4K streaming**

**Internet Gateway:**
- Target: 20-25ms average
- Current: 20-25ms average (acceptable)
- Spikes: Should be <50ms
- Status: ⚠️ **Spikes need reduction**

---

## 🔧 Diagnostic Commands

### Test Eero Network Performance

```bash
# Test from device on "SC Home_Ext" network
ping -c 20 192.168.1.1  # Asus router
ping -c 20 192.168.1.11  # Media server
ping -c 20 8.8.8.8       # Internet

# Check for packet loss
ping -c 100 192.168.1.1 | grep packet

# Test during Plex streaming
# Start Plex stream, then run:
ping -c 50 192.168.1.1
```

### Compare Networks

```bash
# Test on "SC Home" (Asus)
# Note: Should show <10ms average

# Test on "SC Home_Ext" (Eero)
# Note: Currently showing 34-35ms average

# Compare results
```

---

## 🎯 Impact on Your Goals

### 4K Plex Performance

**Current Impact:**
- 🔴 **Eero latency (34-35ms avg, spikes to 210ms) NOT suitable for 4K**
- ✅ **Asus network working perfectly** - **MUST use for 4K devices**
- ⚠️ High latency spikes will cause buffering in 4K streams

**Critical Recommendation:**
- **Use "SC Home" (Asus) for ALL 4K streaming devices** (immediate action)
- **Do NOT use "SC Home_Ext" (Eero) for 4K until latency fixed**
- Use "SC Home_Ext" (Eero) for IoT/low-bandwidth devices only
- Fix Eero latency before considering 4K devices on that network

**4K Streaming Requirements:**
- Latency: <20ms (ideally <10ms) for smooth playback
- Stability: <5ms stddev for consistent performance
- Current Eero: 34-35ms avg, 41-53ms stddev - **INSUFFICIENT**

### External Streaming

**Current Impact:**
- ⚠️ Eero latency spikes (up to 210ms) could affect external streaming
- ✅ Server on Asus network (192.168.1.11) - not affected

**Recommendation:**
- Server is on Asus network (good)
- External streaming not directly affected
- Monitor if external users report issues

### Fortress Mode

**Current Impact:**
- ✅ Local network latency doesn't affect offline operation
- ⚠️ High latency may slow local access during internet outages

**Recommendation:**
- Fix Eero latency for better local performance
- Ensure critical devices on stable "SC Home" network

---

## 📋 Action Plan

### This Week (IMMEDIATE)

1. **Day 1: Channel Optimization** (HIGH PRIORITY)
   - Check Asus router 5GHz channel (via admin panel)
   - Change Eero to non-overlapping channel (High band 149-165 recommended)
   - Reduce Eero bandwidth to 40MHz (less interference)
   - Test latency improvement immediately

2. **Day 2: Node Optimization**
   - Check Eero node placement (Eero app → Network)
   - Verify signal strength between nodes
   - Reposition nodes if signal weak
   - Consider Ethernet backhaul if possible

3. **Day 3: Firmware & Testing**
   - Update Eero firmware (Eero app → Settings)
   - Restart all Eero nodes
   - Re-run diagnostics on "SC Home_Ext"
   - Compare before/after results
   - **Verify latency <20ms average before using for streaming**

**Success Criteria:**
- Latency to router: <20ms average (target <15ms)
- Standard deviation: <10ms (target <5ms)
- Maximum spikes: <50ms (target <30ms)
- **Must achieve before using for 4K devices**

### Next Week (If Issues Persist)

4. **Advanced Troubleshooting**
   - Consider Ethernet backhaul
   - Evaluate disabling Eero WiFi
   - Test alternative configurations

---

## 🔍 Monitoring

### Track Latency Over Time

```bash
# Create monitoring script
cat > monitor_eero_latency.sh << 'EOF'
#!/bin/bash
while true; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    latency=$(ping -c 5 192.168.1.1 | grep 'avg' | awk -F'/' '{print $5}')
    echo "$timestamp - Latency: ${latency}ms"
    sleep 60
done
EOF

chmod +x monitor_eero_latency.sh
```

### Grafana Dashboard

**Add to Monitoring:**
- Track latency to router (192.168.1.1)
- Track latency to server (192.168.1.11)
- Alert on latency >50ms
- Alert on spikes >100ms

---

## ✅ Verification

After implementing fixes:

```bash
# Re-run diagnostics
./advanced_network_diagnostics.sh
./troubleshoot_eero_latency_detailed.sh

# Compare results:
# Before: 34-35ms average, 41-53ms stddev, spikes to 210ms
# Target: <20ms average, <10ms stddev, spikes <50ms
```

---

## 📚 Related Documentation

- [NETWORK_SERVICE_AND_CIFS_FIXES.md](NETWORK_SERVICE_AND_CIFS_FIXES.md) - Network configuration
- [COMPREHENSIVE_FINAL_REVIEW.md](COMPREHENSIVE_FINAL_REVIEW.md) - Overall strategy
- [PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md](PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md) - 4K goals

---

**Status**: ⚠️ **LATENCY ISSUES IDENTIFIED**
**Priority**: Medium (affects Eero network only, Asus working fine)
**Recommended Action**: Optimize Eero channels and node placement
**Timeline**: Fix this week (before 4K optimization)

