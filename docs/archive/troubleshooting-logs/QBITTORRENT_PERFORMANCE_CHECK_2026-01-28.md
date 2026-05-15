# qBittorrent Performance Check — 28 Jan 2026

## Summary

Containers are up ~45 hours and healthy. Two main issues are limiting how many downloads finish:

1. **VPN restarts** — Gluetun’s internal healthcheck has restarted the VPN at least **3 times in the last 2 days** when `1.1.1.1:443` was briefly unreachable (connection refused or i/o timeout). Each restart drops all active torrent connections and pauses downloads until the VPN is back up.
2. **Disk 99% full** — The media volume is **99% full** (5.4T used, ~59G free). qBittorrent can stall or fail when there isn’t enough space to complete or move files.

---

## 1. VPN restarts (fix applied in Terraform)

**Observed in Gluetun logs:**
- **26 Jan 18:55** — Healthcheck: `dial tcp4 1.1.1.1:443: connect: connection refused` → VPN restarted.
- **26 Jan 21:43** — Healthcheck: `dial tcp4 1.1.1.1:443: i/o timeout` → VPN restarted.
- **27 Jan 19:01** — Healthcheck: `dial tcp4 1.1.1.1:443: i/o timeout` → VPN restarted.

Default behavior is to restart the VPN after about **6 seconds** of failed healthchecks. Short blips (e.g. 10–20s) to 1.1.1.1:443 are enough to trigger that and kill all active downloads.

**Change in Terraform (`terraform/modules/starr/main.tf`):**
- `HEALTH_VPN_DURATION_INITIAL=60s` — VPN is only restarted after **60 seconds** of failed healthchecks (instead of ~6s).
- `HEALTH_VPN_DURATION_ADDITION=30s` — Extra time per additional failure.

So brief timeouts to 1.1.1.1:443 no longer cause an immediate restart; only longer outages do. That should reduce unnecessary VPN restarts and improve completion of downloads.

**To apply:** Recreate Gluetun so it picks up the new env vars (e.g. from the project root):

```bash
cd /home/youruser/home_lab/terraform/modules/starr
terraform apply -target=docker_container.gluetun -auto-approve -var-file=../../terraform.tfvars
# Then recreate STARR containers that depend on Gluetun if needed
```

Or apply the full STARR stack if you use the root Terraform config.

---

## 2. Disk 99% full (action required on your side)

**Current state:**
- Volume: `//192.168.1.20/Hulk/Media` → `/data/media`
- **5.4T used, ~59G free** → **~99% full**

**Impact:**
- New or completing torrents may fail or stall when writing/moving files.
- Fewer downloads will “finish” until there is more free space.

**Suggested actions:**
1. **Free space on the NAS (Hulk/Media):** Remove or move old/unwanted media, clear completed downloads from qBittorrent’s download dir, empty recycle bin, etc.
2. **Point qBittorrent to a less full path (if you have one):** e.g. another share or disk with more free space, then move or re-add torrents as needed.
3. **Monitor:** Ensure at least **50–100GB+ free** (or more for large 4K/remux) so completions and moves can succeed.

---

## 3. Other checks (no change needed)

- **qBittorrent / Gluetun:** Up 45 hours, healthy; no errors in qBittorrent logs in the last 48h.
- **Network I/O (containers):** ~55.5 GB down / ~22.6 GB up — traffic is flowing when the VPN is up.
- **Config:** `HEALTH_TARGET_ADDRESS=1.1.1.1:443`, `DNS_SERVERS=192.168.1.11`, `DOT=off` — already set for stability.
- **Downloads dir:** `/data/media/downloads` — Movies ~597G, TV Shows ~174G; space here is limited by the same 99%‑full volume.

---

## 4. What to expect after fixes

- **After applying the Gluetun healthcheck change:** Fewer VPN restarts; active downloads should run longer without being dropped by short 1.1.1.1:443 timeouts.
- **After freeing disk space:** More torrents should be able to complete and move; fewer stalls or “disk full” type failures.

If you want, we can next: (a) double-check Terraform apply steps for your setup, or (b) add a small script to alert when `/data/media` (or download dir) goes above e.g. 95% usage.
