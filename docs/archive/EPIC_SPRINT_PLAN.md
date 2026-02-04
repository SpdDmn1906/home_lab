# Epic / Sprint Plan (Problem → Solution → Implementation)

**Last Updated**: 2025-12-30
**Owner**: Stephen (DevOps)
**Environment**: Home lab (low budget), mixed IoT + media + security, Docker-first, IaC desired

---

## 🎯 Guiding Principles

- **Stability before scale**: eliminate “mystery freezes” and boot/mount issues before expanding services.
- **Security before exposure**: no root containers, no privileged exporters, strong secrets.
- **Fortress-mode mindset**: local services should keep working if WAN is down.
- **Incremental IaC**: codify what’s running after it’s stable (avoid “template drift”).

---

## Sprint 0 (Prep / Baseline) — 0.5 day

### EPIC 0: Baseline & Change Control

**Problem**
- Changes happen without a stable baseline (hard to prove improvement/regression).

**Solution**
- Establish a repeatable “baseline capture” and a single source of truth for decisions.

**Implementation**
- **Docs**
  - Use `COMPREHENSIVE_FINAL_REVIEW.md` as the canonical roadmap.
  - Use `PLEX_PLAYBACK_FREEZING_INVESTIGATION.md` as the canonical Plex-freezing notes.
- **Baseline capture**
  - Capture: `docker ps`, `docker stats`, `df -h`, `mount`, `ip route`, and a 2–5 min Plex playback sample on:
    - one “good client” + one “problem client”
- **Acceptance criteria**
  - A baseline run exists and is repeatable.

---

## Sprint 1 (Stabilize the Core) — 1 week

### EPIC 1: Plex Playback Reliability (Local)

**Problem**
- Plex freezes even on Direct Play; root cause not always “Wi‑Fi latency”.
- We found a high-risk topology pattern: **USB NIC + USB media drive on the same USB hub**, and evidence of **client receiver stalls**.

**Solution**
- Remove known stall sources (shared USB path), harden the physical path to the TV, and standardize the primary playback client.

**Implementation**
- **Server network path**
  - Keep Plex traffic on **onboard NIC `eno1`** (Intel I217‑V) unless/until a dedicated 2.5GbE PCIe NIC is installed.
  - If a USB NIC is required later, ensure it’s on a **different controller** than the USB media drive.
- **Client path**
  - Treat “wired to wireless satellite” as **not** equivalent to wired.
  - Plan a **MoCA backhaul test** (coax in next room) for the satellite location.
- **Client standardization**
  - If the LG webOS app remains unstable, define a “gold client” (Apple TV 4K / Shield / PS5) for the main TV.
- **Acceptance criteria**
  - 30+ minutes continuous playback of a known-problem title with **no freezes** on the primary TV viewing setup.
- **Dependencies**
  - Physical access to cabling / coax / node placement.

### EPIC 2: Critical Security Hardening (Containers + Secrets)

**Problem**
- Root-running STARR stack services and privileged exporters create “one exploit = full host compromise”.

**Solution**
- Move services to least privilege + safe defaults.

**Implementation**
- STARR stack: migrate PUID/PGID from `0` → non-root user (UID/GID per server).
- Node exporter: remove privileged mode and excessive caps.
- Grafana: rotate admin password; store as secret.
- **Acceptance criteria**
  - No internet-facing service is running as root.
  - No “privileged: true” in monitoring stack.

### EPIC 3: Storage Headroom (Reliability + 4K readiness)

**Problem**
- Storage is near/at capacity; this causes unpredictable behavior and blocks transcode buffers.

**Solution**
- Create predictable headroom targets and enforce them.

**Implementation**
- Target headroom:
  - External: **>= 200GB free**
  - NAS: **>= 100GB free** (minimum), ideally more
- Cleanup:
  - prune old downloads, remove duplicates, remove unused docker images/volumes
- Add “storage SLO”: alert at 85% / 90% / 95%
- **Acceptance criteria**
  - Storage under threshold for 7 days with no “disk full” incidents.

---

## Sprint 2 (Network + DNS Foundation) — 1 week

### EPIC 4: DNS / Ad Blocking (AdGuard Home + Unbound)

**Problem**
- DNS visibility and control is limited; fortress-mode needs local resolution.

**Solution**
- Deploy AdGuard Home + Unbound using Terraform (server-run IaC).

**Implementation**
- Deploy with Terraform module under `terraform/modules/adguard`.
- Configure router DHCP/DNS to point clients to AdGuard (or selectively per VLAN/subnet later).
- Add local DNS records for core services (`plex`, `nas`, `grafana`, etc.).
- **Acceptance criteria**
  - All LAN clients resolve internal hostnames reliably.
  - DNS continues to work during brief WAN outages (within limits of upstream availability).

### EPIC 5: Network Consistency + Backhaul Plan for “SC Home_Ext”

**Problem**
- Outdoor/remote devices need Wi‑Fi reach; wireless backhaul introduces jitter.

**Solution**
- Keep Asus as primary; make the extension network predictable with a backhaul upgrade path.

**Implementation**
- Short-term:
  - Ensure single DHCP server and consistent addressing
  - Node placement + channel/bandwidth choices per `EERO_LATENCY_FIX_GUIDE.md`
- Medium-term:
  - **MoCA** trial (coax) to convert satellite → wired backhaul
- **Acceptance criteria**
  - Satellite node shows stable link quality and supports 4K Direct Play without freezes for 30 minutes.

---

## Sprint 3 (Observability + Operations) — 1–2 weeks

### EPIC 6: Monitoring + Alerting (SLO-driven)

**Problem**
- You can’t easily answer “is it network, disk, Plex, or client?”

**Solution**
- Build dashboards + alerts around the problems you actually hit.

**Implementation**
- Prometheus + Grafana:
  - Add host metrics, docker metrics, disk usage alerts, basic network latency checks
- “Plex freeze triage” panel:
  - concurrent sessions, bandwidth, resource usage, disk IO, basic ping/jitter
- **Acceptance criteria**
  - One dashboard answers: “why is Plex stalling right now?”
  - Alerts fire on low disk space and service down.

### EPIC 7: Boot/Mount Reliability (fstab + CIFS)

**Problem**
- Boot delays, CIFS errors, unpredictable mount states can cascade into app issues.

**Solution**
- Make mounts predictable and dependency-safe.

**Implementation**
- Apply the recommended `fstab` structure from `OPTIMIZED_FSTAB_AND_CONFIGURATIONS.md`.
- Ensure mounts used by Plex/containers are available before services start.
- **Acceptance criteria**
  - Reboot completes cleanly; mounts present; Plex can start and serve media immediately.

---

## Sprint 4 (Fortress Mode + Remote Streaming Quality Gates) — 1 week

### EPIC 8: Fortress Mode (Local-First Operation)

**Problem**
- WAN outages degrade usability (DNS, auth, camera apps, etc.).

**Solution**
- Make core services continue to function locally and document what cannot.

**Implementation**
- Plex:
  - Set LAN networks correctly; validate local playback when WAN down
- DNS:
  - Keep local resolution + allowlist critical domains needed for auth where required
- Cameras:
  - Document per ecosystem (Nest/Eufy/Abode) what works offline; prioritize future replacement path
- **Acceptance criteria**
  - Local Plex playback works during WAN outage simulation.
  - Local DNS works; critical automations do not break.

### EPIC 9: External Streaming Non-Interference

**Problem**
- External streams can compete with local playback.

**Solution**
- Limit/shape external streaming and set expectations per upload capacity.

**Implementation**
- Plex remote:
  - Set remote quality caps (1080p target), limit concurrent transcodes
- Router:
  - Basic QoS / bandwidth reservation if available
- **Acceptance criteria**
  - Local 4K remains smooth while one external 1080p stream runs.

---

## Backlog (Future / Optional)

- **Hardware**: PCIe 2.5GbE NIC; dedicated SSD for transcode; eventual server refresh.
- **Network**: UniFi migration (switch + APs) after backhaul is solved.
- **Security**: VLAN segmentation (IoT / cameras / trusted / guests).
- **Automation**: CI checks for Terraform/Ansible, nightly backups, config drift detection.


