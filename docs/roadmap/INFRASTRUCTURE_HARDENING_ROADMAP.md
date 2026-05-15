# Infrastructure Hardening & Recovery Roadmap

**Date**: 2026-05-09
**Status**: ACTIVE
**Primary Goal**: Stabilize media server host (mediaserver) and decouple critical services (DNS) from high-IO media storage.

---

## 🚨 **Phase 1: Emergency Stabilization** (✅ COMPLETED)
*Tasks performed following the 15-minute network outage on 2026-05-09.*

- [x] **Fix Hostname Resolution**: Added `127.0.1.1 mediaserver` to `/etc/hosts` to prevent `sudo` hangs and internal DNS lookups during outages.
- [x] **Harden NAS Mounts**: Updated `/etc/fstab` CIFS options to include `soft,timeo=600,retrans=3`. This prevents the kernel from entering an uninterruptible sleep state if the Synology NAS goes offline.
- [x] **Throttle Monitoring Overhead**: Changed `plex-fortress-guard.timer` interval from 30 seconds to **5 minutes** to reduce CPU/IO churn during system stress.
- [x] **Initial Hardware Audit**: Installed `smartmontools` and identified `/dev/sda` as a failing device.

---

## 🛠️ **Phase 2: Hardware Remediation** (URGENT)
*Goal: Remove failing hardware that is causing SATA bus resets and log corruption.*

- [ ] **Physical Decommissioning of `/dev/sda`**: 
    - [ ] Shut down server.
    - [ ] Physically disconnect the SATA/Power cables from the 2TB Seagate (SN: 9WM7TB5T).
    - [ ] Power up and verify system stability.
- [ ] **Data Recovery Plan for `/dev/sda`**:
    - [ ] **Critical Condition**: Drive is in "FAILED" state with 3,959+ reallocated sectors. No further writes should be made to this drive.
    - [ ] **Strategy**: Use `ddrescue` for a bit-level clone if a replacement 2TB+ drive is acquired.
    - [ ] **Current Constraint**: No local storage (NAS or USB) has the 2TB free space required for a disk image. 
    - [ ] **Alternative**: Targeted file recovery using `rsync` for critical directories ONLY (if drive allows mounting).

---

## 🌐 **Phase 3: Architectural Decoupling (The Raspberry Pi Project)**
*Goal: Ensure a server crash doesn't take down the entire home network.*

- [ ] **Secondary DNS Configuration**:
    - [ ] Update Router (192.168.1.1) DHCP settings to include a secondary DNS (e.g., `1.1.1.1` or `8.8.8.8`).
- [ ] **Primary DNS Isolation (Raspberry Pi)**:
    - [ ] **Hardware**: Raspberry Pi 4 or 5 (even a Zero 2W is sufficient for DNS).
    - [ ] **Software Stack**: 
        - [ ] DietPi or Raspberry Pi OS Lite (Minimal footprint).
        - [ ] **AdGuard Home**: Primary DNS sinkhole/filtering.
        - [ ] **Unbound**: Recursive DNS resolver (Privacy-focused, no upstream trust).
    - [ ] **Integration**: 
        - [ ] Assign static IP to Pi.
        - [ ] Point Router primary DNS to Pi IP.
        - [ ] Sync AdGuard settings from current media server to Pi.
    - [ ] **Goal**: DNS should not share a disk or CPU with the "STARR" media stack.

---

## 📈 **Phase 4: Resilience & Automation**
*Goal: Prevent future "IO Avalanches" through better scripting and make the host reproducible.*

- [ ] **CIFS Auto-Heal (as Ansible role, not bash)**:
    - [ ] Build `ansible/roles/cifs_mount/` that owns NAS mount definitions, fstab options, and a health-check handler.
    - [ ] Health-check task: detect hung mounts and force unmount (`umount -l`) before the Docker daemon hangs.
    - [ ] Idempotent — running the playbook on a fresh Ubuntu install reproduces all mounts.
    - [ ] Reused by Phase 3 Pi (same role mounts NAS on Pi if needed).
- [ ] **Monitoring Audit**:
    - [ ] Review all `cron` jobs and `systemd` timers.
    - [ ] Ensure no high-IO tasks (like media scanning) overlap or run too frequently.
- [ ] **Log Rotation Audit**:
    - [ ] Ensure Docker logs are capped (e.g., 10m, 3 files) to prevent massive JSON decoding overhead.
- [ ] **Loki/Promtail — Actually Ship Logs**:
    - [ ] Promtail config is present but needs to be wired to all container labels.
    - [ ] Once logs flow to Loki, tighten Docker `max-size` aggressively (logs persist in Loki, not on disk).
    - [ ] `log-error-scanner.sh` demoted to fallback; Grafana Explore (Loki) becomes primary log view.
- [ ] **Alerts-as-Code**:
    - [ ] `/dev/sda` (and any future drive) SMART failure → Prometheus alert.
    - [ ] CIFS mount lost (mountpoint missing in node-exporter filesystem metrics).
    - [ ] `plex_fortress_guard_state != 0` for >1h.
    - [ ] Container restart count increasing (`rate(container_start_time_seconds[15m]) > 0`).
    - [ ] Disk usage >85% on any local volume.
- [ ] **Ansible "Bare Metal → Running Lab" Playbook**:
    - [ ] Goal: `ansible-playbook site.yml` on a fresh Ubuntu install reproduces the entire stack in <10 min.
    - [ ] Roles: `cifs_mount`, `docker_host`, `plex_gpu` (if hardware transcode is used), `adguard`, `starr_stack`, `fortress_guard`, `monitoring_stack`.
    - [ ] Acceptance test: blow away the VM, run playbook, Plex serves a movie.

---

## 🚀 **Phase 5: Platform Maturity & Career Growth Track**
*Goal: Build legitimate platform-engineering experience on top of a stable lab — without destabilizing Phase 1–4 work. Each project is fortress-mode-aligned (adds resilience or learning sandbox isolation) AND produces a portfolio artifact.*

**Rule of thumb**: Nothing in Phase 5 starts until Phase 2 (failing disk) and Phase 3 (DNS isolation) are complete. Production stability beats resume polish.

### 5a. K3s Sidecar Cluster *(separate node, not main host)*
*Why this passes the smell test: a dedicated learning cluster doesn't put Plex at risk, and provides an isolation boundary for experimental workloads. The Pi from Phase 3 (or a second NUC) is the natural target.*

- [ ] **Hardware**: Reuse Phase 3 Pi (DNS first, K3s second) OR a separate mini-PC.
- [ ] **Cluster bring-up**: Single-node K3s with `--disable traefik --disable servicelb` (use Tailscale + nginx-ingress instead).
- [ ] **What runs there (NEVER prod Plex/STARR)**:
    - [ ] Experimental services (LLM inference, n8n, Vaultwarden, etc.) where K8s patterns are appropriate.
    - [ ] Sealed Secrets demo (real-world secret management story).
    - [ ] Pod Disruption Budget + HPA examples on something throwaway.
- [ ] **Hard boundary**: Plex, STARR, AdGuard, fortress guard, monitoring **stay on Docker on the media host**. They have host networking, GPU passthrough, and host iptables requirements that fight K8s.
- [ ] **Resume artifact**: Public GitHub repo of the cluster manifests + write-up of "why I chose hybrid Docker + K3s instead of full migration."

### 5b. ArgoCD on the K3s Cluster
*Why this passes the smell test: GitOps demonstrably works for K8s manifests; pairs naturally with 5a; does NOT require migrating prod stack.*

- [ ] Install ArgoCD into the K3s cluster (5a).
- [ ] Manifests live in a separate `home_lab_k3s/` repo (or subfolder), watched by ArgoCD.
- [ ] App-of-apps pattern for at least 3 workloads.
- [ ] Demonstrate: git push → automatic deploy → rollback via git revert.
- [ ] **Do not** try to GitOps the Docker-Compose stack. That's a different problem; if you want compose-GitOps later, look at `komodo` or `dockge`, not ArgoCD.

### 5c. Go CLI: `sb-lab` (bounded scope)
*Why this passes the smell test: bash struggles with structured Sonarr/Radarr/Plex API calls (JSON parsing, retries, concurrency, error handling). A Go CLI that targets specifically those operations is a real upgrade, not a rewrite.*

- [ ] **Do NOT** rewrite `infrastructure-manager.sh` or any working bash. Bash is correct for orchestrating docker/iptables/systemd.
- [ ] **Do** build `sb-lab` as a new tool that fills bash's actual weak spots:
    - [ ] `sb-lab media find-duplicates` — concurrent Sonarr/Radarr API calls, deduplicated output.
    - [ ] `sb-lab plex profile-check` — verifies managed user profiles are intact (early warning for the bug fortress guard fixes).
    - [ ] `sb-lab fortress status` — pretty-print of guard state + blocked IPs + Prometheus metric values.
    - [ ] `sb-lab backup verify` — checksums NAS-backed configs, alerts on drift.
- [ ] **Distribution**: Single static binary, installed to `/usr/local/bin/sb-lab` via the Ansible playbook (5a/5b's deployment story closes the loop).
- [ ] **Resume artifact**: Clean Go module with tests, GitHub Actions CI, semver releases.

### 5d. Observability Maturity (Stretch)
*Why this passes the smell test: bridges 4 and 5; demonstrates "I don't just install Grafana, I instrument my own services."*

- [ ] Expose custom Prometheus metrics from `sb-lab` (e.g., `sb_lab_duplicate_count`, `sb_lab_profile_check_passed`).
- [ ] OpenTelemetry traces for `sb-lab` operations that span multiple API calls.
- [ ] Grafana dashboard pulling from both Prometheus (metrics) and Loki (logs) on the same time range — "single pane of glass" story.

---

## 🧭 **Phase Ordering Rationale**
- Phases 1–3 are **non-negotiable prerequisites**. A failing disk and a single-node DNS dependency outrank every career-growth item.
- Phase 4 is **the platform foundation**: Ansible-based reproducibility + alerting + log shipping. Everything in Phase 5 implicitly depends on this.
- Phase 5 is **explicitly optional and parallelizable**. Pick one of 5a/5b/5c based on what you want to learn next. Skip any that stop being interesting.
- **Anti-goal**: Do not let any Phase 5 work cause regressions in Phases 1–4. If 5a's K3s cluster needs the Pi's CPU and Phase 3's DNS suffers, kill 5a and use a second box.

---

## 🌅 **Phase 6: North Star — 2-5 Year Vision**
*Goal: Capture the long-term destination so today's decisions point at the right horizon. This is a **vision section**, not a checklist. No dates, no commitments — just naming the destination.*

### The Guiding Principle: "Internet-Optional Household"
Fortress mode, generalized from Plex to the entire family. Everything important works without the public internet, and we own the data behind it. This principle drives every sub-theme below.

### Theme A — Storage Foundation *(dependency of everything else)*
- Move away from consumer cloud (iCloud Photos, Google Drive, Dropbox) for primary storage.
- 3-2-1 backup discipline: 3 copies, 2 media types, 1 offsite.
- Tiers: hot (SSD, working set), warm (HDD NAS, media + photos), cold (offsite or rotated drive).
- Likely path: expand Synology, then DIY TrueNAS box for capacity tier when Synology fills.

### Theme B — AI / Intelligence Layer
- Local LLM serving (Ollama / vLLM) for daily-use chat, retrieval over family docs, automation glue.
- Voice replacement for Amazon Echo: Home Assistant Voice (Whisper + Piper + local LLM) for fortress-mode-tolerant voice commands.
- AI-driven NVR for security cameras (Frigate with GPU/Coral inference).
- Hardware reality: requires GPU. Used 3090 (24GB VRAM) or Mac Studio with 64GB+ unified memory is the realistic entry point. Should NOT share hardware with Plex transcoding.

### Theme C — Tenant Isolation
- Wife's photography & stationary business: separate storage, separate backups, possibly separate hosting (website, file delivery to clients).
- Kids' devices: per-device DNS policies (AdGuard), screen time, MDM, content filtering. Already partial via AdGuard; needs structured profiles as devices proliferate.
- Personal dev/staging: future web and mobile app projects need real environments separate from prod media stack.
- This is where K3s + ArgoCD from Phase 5 stop being a learning sandbox and become genuinely useful — multi-tenant scheduling, declarative deploys, real isolation.

### Theme D — Household Automation
- Home Assistant as the control plane for: sprinklers, AC/HVAC, lights, curtains, power monitoring (CT clamps or Span panel), garden sensors, smart locks.
- ESPHome for DIY sensors; Zigbee/Z-Wave coordinator for off-the-shelf devices.
- Frigate (Theme B) integrates with HA for "person detected at front door" automation.
- Power optimization: meaningful only once monitoring is in place — visibility before optimization.

### Theme E — Connectivity & Portability
- Tailscale (or WireGuard) mesh: every node, every family device, no inbound holes punched.
- GitOps + Ansible reproducibility (Phases 4–5) means the whole household stack can be rebuilt on any hardware.
- Public-facing services for wife's business: Cloudflare Tunnel or Tailscale Funnel, never direct port forwards.
- Optional: redundant internet (5G failover, secondary ISP) — separately tracked in `docs/architecture/ISP-ASSESSMENT.md`.
- Private torrent trackers: VPN compliance + cross-seed + autobrr — tighter STARR stack discipline.

### Target Hardware Footprint (2-5 years)
A realistic multi-node lab, NOT one giant box:

| Node | Role | Status |
|---|---|---|
| **`mediaserver`** (current) | Media host: Plex, STARR, fortress guard, qBittorrent | Existing |
| **NAS** (Synology + future TrueNAS) | Primary storage tier, family backups, photos | Existing, needs expansion |
| **Pi / control node** | DNS (AdGuard + Unbound), Home Assistant, automation hub | Phase 3 |
| **AI / intelligence node** (GPU box) | Ollama, Frigate, voice (Whisper/Piper) | Theme B |
| **K3s / dev node** | Wife's business stack, dev/staging, ephemeral services | Phase 5a + Theme C |
| **(Optional) failover / offsite** | Cold backup target, possibly at a relative's house via Tailscale | Theme A |

### Decision Anchors for Today
Naming Phase 6 now lets us make Phase 2–4 hardware decisions correctly:
- **Replacement for `/dev/sda`**: Don't buy a 2TB drive. Buy with growth in mind for Theme A.
- **Phase 3 Pi**: Spec it so it can host Home Assistant later (Theme D), not just DNS. A Pi 4 4GB+ is the floor.
- **UPS sizing** (Phase 4): Plan for 4–5 nodes' eventual draw, not just today's single host.
- **Network**: When the eero mesh gets replaced/extended, choose gear that supports VLANs for Theme C tenant isolation.

### What This Vision Explicitly Rejects
- One-giant-server consolidation. Resilience requires separation.
- Cloud-first re-architecture. The principle is internet-optional, not internet-hostile — cloud as cold backup is fine; cloud as primary is not.
- Full Kubernetes migration of prod media stack. Plex/STARR's host networking + GPU passthrough requirements make K8s the wrong tool.

---

## 📊 **Current System Vitals**
- **Host**: mediaserver (192.168.1.11)
- **Uptime**: ~45 minutes (since 19:03 reboot)
- **Known Failing Parts**: `/dev/sda` (Seagate 2TB)
- **Network Dependency**: AdGuard (Docker) currently handles ALL home DNS.
