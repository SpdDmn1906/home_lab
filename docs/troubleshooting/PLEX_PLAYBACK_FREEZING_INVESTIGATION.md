# Plex Playback Freezing Investigation (Direct Play, Low Bitrate)

**Date**: 2025-12-30
**Server**: mediaserver (`192.168.1.11`)
**Purpose**: Capture the latest “freezing while Direct Play” findings and the most likely root causes + next actions.

---

## 🔎 Symptom Summary

- Plex playback freezes even when dashboard shows **Direct Play** (sometimes as low as ~1 Mbps).
- Issue reproduced on:
  - **LG webOS TV** (wired into an **Eero wireless satellite**)
  - **Phone on "SC Home"** (Wi‑Fi) — intermittent freezes also observed during the investigation window
- **Redownloading** the same title has historically “fixed” the issue for some files, but this investigation found broader infrastructure causes.

---

## ✅ What We Confirmed (High Confidence)

### 1) The server NIC + USB topology matters (major)

During the investigation, the server was using a **USB Ethernet adapter** (ASIX AX88179A, `ax88179_178a`) and serving media from a **USB external drive**.

`lsusb -t` showed both devices hanging off the **same USB 3 hub**:

- **USB Hub**
  - **Mass Storage (UAS)** → external media drive (`/external/media`)
  - **AX88179 Ethernet** → server network interface

This topology can create **micro-stalls** that feel like buffering/freezing, because disk reads and NIC TX compete on the same USB bus/hub.

### 2) Onboard NIC is gigabit-capable (and more stable)

The motherboard NIC (`eno1`, Intel **I217‑V**, driver `e1000e`) supports **1GbE** (`1000baseT/Full`).

When the cable was moved from USB NIC → onboard NIC:
- The server successfully routed via `eno1`
- Server→TV ping jitter improved materially

### 3) The LG TV session showed receiver-side stalls (TCP evidence)

On the server, `ss -ti sport = :32400` repeatedly showed the TV’s Plex connection with:
- **`rwnd_limited` ~99%**
- large **`notsent`** backlog
- **TCP backoff**

This is consistent with: **the TV client (or its last-hop path) not consuming data**, even when the server is trying to send.

This can be caused by:
- wireless satellite backhaul hiccups (even with “wired to satellite” clients)
- client app / TV network stack stalls
- client decode pipeline stalls

---

## ⚠️ What We Did *Not* Prove (Yet)

- A definitive “file corruption” root cause for the reported title(s).
  - Spot-read tests of the file from multiple offsets succeeded.
  - We do not currently have `ffmpeg/ffprobe` installed on the server to run a quick decode validation pass.

---

## 🎯 Recommended Next Actions (Lowest Cost → Highest Impact)

### A) Keep Plex traffic off the shared USB NIC

- Prefer **onboard NIC (`eno1`)** for Plex traffic.
- If you need >1GbE for internet (2Gb Xfinity), do **not** “upgrade” with another shared USB NIC on the same hub:
  - Prefer **PCIe 2.5GbE** (Intel i225/i226 or similar), or
  - If using USB 2.5GbE (RTL8156), ensure it’s on a **separate controller** than the external media drive.

### B) Stop “wired-to-wireless-satellite” as a reliability strategy

Wiring into a wireless satellite still depends on the **wireless backhaul**. For stability:
- Use **MoCA** if you have coax near the gateway and the satellite room.
- Or run Ethernet / relocate nodes for better backhaul.

### C) Reduce client variability for 4K goals

For your “4K locally, no buffering” goal:
- Consider a dedicated client (Apple TV 4K / NVIDIA Shield) for the TV.
- Treat the smart-TV Plex app as “best effort,” not “SLO-grade.”

### D) Add a fast “is it file vs network vs client” triage loop

- Compare the same title on:
  - TV (problem client)
  - phone
  - a wired client (laptop/desktop)
- Use server-side `ss -ti sport = :32400` to see which client is `rwnd_limited`.

---

## 🧰 Useful Commands (Server)

```bash
# TCP telemetry for Plex connections
ss -ti sport = :32400 | sed -n '1,200p'

# Short jitter sample (server -> client)
ping -c 50 -i 0.2 192.168.1.X | tail -5

# USB topology (look for shared hubs)
lsusb -t

# Confirm default route interface
ip route get 8.8.8.8
```


