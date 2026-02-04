# qBittorrent Performance Check (2026-01-29)

## Summary

**Status:** Poor performance is caused mainly by **no VPN port forwarding** and **downloads on network storage (NAS)**.

---

## Findings

### 1. **No PIA port forwarding (critical)**

- Gluetun logs: `401 Unauthorized` when fetching PIA token → **no forwarded port**.
- qBittorrent API `/v1/openvpn/portforwarded` returns `{"port":0}`.
- File `/tmp/gluetun/forwarded_port` does not exist in Gluetun.
- **Effect:** Incoming connections from the internet cannot reach qBittorrent. You only get outbound connections → fewer peers, slow downloads, poor ratio.

**Action:** Fix PIA so port forwarding works:

1. Confirm your PIA account supports port forwarding and that credentials in `credentials.txt` (in `gluetun_config_path`) are correct.
2. If PIA uses a separate “token” or API auth, ensure Gluetun has what it needs Run `./scripts/test_pia_token.sh <path-to-credentials.txt>` to verify credentials (see [PIA manual scripts](https://helpdesk.privateinternetaccess.com/kb/articles/manual-connection-and-port-forwarding-scripts-for-linux)).
3. After Gluetun gets a forwarded port:
   - Run: `docker exec gluetun cat /tmp/gluetun/forwarded_port`
   - In qBittorrent WebUI: **Settings → Connection → Listening Port** = that port, and disable **Use UPnP / NAT-PMP** if you rely on the VPN port.

### 2. **Listen port not using VPN forward**

- Current **Listening port:** `6881` (classic BitTorrent port).
- With no PIA forward, 6881 is not reachable from the internet through the VPN.
- When PIA port forwarding works, you must set qBittorrent’s listening port to the **forwarded** port.

### 3. **Download path on NAS (likely bottleneck)**

- Download path: **`//192.168.1.20/Hulk/Media`** (CIFS/SMB), ~5.4 TB, ~90% used.
- Network storage often has higher latency and lower IOPS than local disk → can limit write speed and cause stalls when many torrents are active.

**Optional improvement:** Use a local SSD (or fast local disk) for *active* downloads, then move completed files to the NAS (e.g. with a script or Radarr/Sonarr). Or ensure the NAS and network (e.g. 1 Gbps+) are not saturated.

### 4. **Current settings (OK)**

- **uTP:** Enabled (`bittorrent_protocol`: 0 = TCP + μTP).
- **DHT / PeX:** Enabled.
- **Connection limits:** max_connec 700, max_connec_per_torrent 200, max_uploads 20, max_uploads_per_torrent 4.
- **Connection status:** Connected.
- **Containers:** Gluetun and qBittorrent healthy (VPN region: CA Montreal).

### 5. **Observed at check time**

- **Transfer:** ~27 KB/s down, ~10 KB/s up.
- **Torrents:** 366.
- **Net I/O (container):** 15.3 GB down / 8.35 GB up (lifetime).

---

## Quick reference

| Item              | Current                         | Recommendation                          |
|------------------|----------------------------------|----------------------------------------|
| PIA port forward | None (401)                       | Fix PIA credentials/token; use forwarded port in qBittorrent |
| Listening port   | 6881                             | Set to PIA forwarded port once available |
| Download path    | NAS `//192.168.1.20/...`         | Consider local SSD for active downloads |
| uTP              | On                               | Keep on                                |
| VPN region       | CA Montreal                      | OK for PIA port forwarding             |

---

## Commands used (on media server)

```bash
# Forwarded port (when PIA works)
docker exec gluetun cat /tmp/gluetun/forwarded_port

# qBittorrent preferences (with auth)
# Use WebUI or API with cookie login; listen_port and random_port are under Connection.
```

After fixing PIA and setting the listening port, run the maintenance script if desired:

```bash
QBITTORRENT_USER='admin' QBITTORRENT_PASSWORD='YOUR_PASSWORD' ~/qbittorrent_maintenance.sh
```
