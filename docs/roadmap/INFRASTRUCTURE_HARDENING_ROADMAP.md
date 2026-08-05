# Infrastructure Hardening & Recovery Roadmap

**Date**: 2026-05-09
**Status**: ACTIVE
**Primary Goal**: Stabilize media server host (mediaserver) and decouple critical services (DNS) from high-IO media storage.

---

## ⚡ **Active Build Priorities (2026-06)**

The estate now spans three environments — this on-prem lab, a personal AWS account, and a Linode host running a live YouTube stream. Priorities this cycle are sequenced by one rule: **real production risk and genuine daily-use value first.**

1. **Production risk — still first.** Phase 2 (failing disk) and Phase 3 (single-node DNS SPOF) outrank everything below. A new project sitting on a fragile base is the wrong trade.
2. **`infra-mcp` — estate control plane (Phase 5c, flagship).** One read-only place to ask *"is the stream up? any lab alerts? what's my AWS spend?"* instead of three dashboards and three logins. Built lean on purpose: local, read-only, secrets kept out of git, internal services reached over Tailscale.
3. **Right-sized delivery for what I actually run.** Automate the janellechung-site deploy (hand-uploaded over FTP today → IaC + CI/CD on managed static hosting) and add monitoring/hardening for the Linode stream. **Right-sizing is the point:** managed platforms over a Kubernetes cluster unless a workload truly needs one — over-engineering a personal app is a red flag, not an achievement.
4. **Deferred.** Phase 5e/5f/5g (Paperless / Immich / Frigate) and the K3s cluster remain background work — real utility, lower leverage this cycle.

**Anti-goal (unchanged):** production stability and right-sizing beat project count.

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

- [x] **Physical Decommissioning of `/dev/sda`** (2026-08-05):
    - [x] Shut down server.
    - [x] Physically disconnect the SATA/Power cables from the 2TB Seagate (SN: 9WM7TB5T).
    - [x] Power up and verify system stability. Verified: all 18 containers back up healthy, `fstab` had zero references to the drive (nothing depended on it), no new SATA errors post-boot. Note: device names shifted — former `/dev/sdb` (OS/boot) is now `/dev/sda`; the failing drive's old `/dev/sda` identity no longer exists. Drive is now disconnected, in anti-static storage, pending replacement-drive purchase + ddrescue clone (see Data Recovery Plan below, still open) — this was triggered by a real incident: the drive's `FAILING_NOW` SMART state caused a full-system hang requiring a hard restart, not a routine decommission.
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
    - [ ] `/dev/sda` (and any future drive) SMART failure → Prometheus alert. **⚠️ 2026-08-05: this is no longer hypothetical — the failing drive's `FAILING_NOW` SMART state hung the whole box and forced a hard restart. This alert would have caught it in advance. Highest-value item in this list.**
    - [ ] CIFS mount lost (mountpoint missing in node-exporter filesystem metrics).
    - [ ] `plex_fortress_guard_state != 0` for >1h.
    - [ ] Container restart count increasing (`rate(container_start_time_seconds[15m]) > 0`).
    - [ ] Disk usage >85% on any local volume. **⚠️ 2026-08-05: `/external/media` was found at 100% full (13GB free of 2.2TB) during the same incident — this alert would have caught that too.**
- [ ] **Notification quality — Alertmanager → ntfy formatting** (added 2026-08-05, follow-up to the working push pipeline):
    - [ ] **Problem:** Alertmanager's generic `webhook_configs` can't template its payload, so notifications arrive as a raw JSON blob with the server URL as the title. Readable, but ugly and slow to parse on a lock screen at 3am.
    - [ ] **Fix:** insert a bridge between Alertmanager and ntfy that sets ntfy's `X-Title`/`X-Priority`/`X-Tags` headers from alert labels/annotations. Candidates: [`ntfy-alertmanager` (xenrox)](https://codeberg.org/xenrox/ntfy-alertmanager) — supports priority, tags, icons, and action buttons (e.g. a button to silence the alert directly from the notification); [`alertmanager-ntfy` (alexbakker)](https://github.com/alexbakker/alertmanager-ntfy) — Go templating for title/body, markdown support. Evaluate both, pick one.
    - [ ] **Payoff:** notification title becomes the actual alert name (`AdGuardSLOFastBurn`) instead of the server URL — this fixes the title *properly*, which MagicDNS below only cosmetically improves.
- [ ] **Enable Tailscale MagicDNS** (added 2026-08-05):
    - [ ] Enable at login.tailscale.com → DNS → Enable MagicDNS. Replaces raw tailnet IPs with hostnames (`ssh sc-base-lx`, `http://sc-base-lx:3000` for Grafana, etc.).
    - [ ] **Does NOT duplicate or undermine Phase 3.** Different namespace and scope: Phase 3 is LAN-wide DNS (filtering, recursive resolution, killing the single-node SPOF for every device in the house); MagicDNS only resolves tailnet peer names in the `.ts.net` namespace, does no filtering and no recursive resolution. Phase 3 needs no rework when AdGuard moves to the Pi.
    - [ ] **⚠️ Real conflict — apply `accept-dns` per device, never blanket.** MagicDNS is delivered by Tailscale managing `/etc/resolv.conf` — the exact mechanism disabled with `--accept-dns=false` on 2026-08-05 to stop it hijacking DNS from AdGuard. Correct split:
        - **Media server: keep `accept-dns=false`.** It doesn't need to resolve `sc-base-lx` — it *is* `sc-base-lx`. Preserves AdGuard as authoritative and avoids a layered dependency (host resolver → Tailscale proxy → AdGuard → running on that same host), which would lengthen the failure chain on the box that already went down once.
        - **Laptop / phone: leave `accept-dns` at default.** These are the devices that connect *to* things, so they're where MagicDNS actually pays off.
    - [ ] **⚠️ Hard dependency:** if the ntfy subscription is switched to a MagicDNS hostname, `NTFY_BASE_URL` **must** be changed to match it exactly, or iOS push silently breaks with zero errors anywhere in the pipeline. See `docs/guides/tailscale-ntfy-push-setup.md` — this cost an hour to diagnose the first time. (This works even with `accept-dns=false` on the server: the server only *advertises* that string, it never resolves it — the phone does.)
    - [ ] **Unverified, check before relying on it in fortress mode:** does MagicDNS still resolve during a WAN outage? Tailscale's coordination server is cloud-hosted, though the netmap is cached locally, so it *should* keep working offline — but this is an assumption, not a tested fact, and fortress mode ("internet-optional household") is a stated design principle. Test it during the next fortress drill.
    - [ ] Note: MagicDNS is DNS-layer only. It does **not** fix the raw-JSON notification body — that needs the bridge above.
- [ ] **Ansible "Bare Metal → Running Lab" Playbook**:
    - [ ] Goal: `ansible-playbook site.yml` on a fresh Ubuntu install reproduces the entire stack in <10 min.
    - [ ] Roles: `cifs_mount`, `docker_host`, `plex_gpu` (if hardware transcode is used), `adguard`, `starr_stack`, `fortress_guard`, `monitoring_stack`.
    - [ ] Acceptance test: blow away the VM, run playbook, Plex serves a movie.
- [ ] **OpenTofu migration** (added 2026-06-09):
    - [ ] Replace Terraform with OpenTofu as the IaC binary. HCL syntax and provider ecosystem are identical, so this is a tooling swap, not a rewrite.
    - [ ] Rationale: maintain OSS license clarity post-HashiCorp BSL change, stay aligned with current IaC ecosystem direction, and keep a clear, explainable reason for the switch.
    - [ ] Procedure documented in `docs/guides/OPENTOFU_K3S_MIGRATION.md` Part 1 (state backup → `tofu init -migrate-state` → verify zero-change plan → update `infrastructure-manager.sh` wrapper).
    - [ ] Rollback: copy state backup back, re-install Terraform, re-init. Symmetric because state file format is binary-compatible.
    - [ ] Acceptance test: `tofu plan` returns "No changes" and `tofu apply` returns "0 added, 0 changed, 0 destroyed" against existing Docker stack.
- [ ] **Self-hosted Git** (added 2026-06-10):
    - [ ] Deploy Gitea or GitLab CE as the canonical home for personal repos (`home_lab`, `home_lab_k3s`, future projects). Removes GitHub dependency for portfolio code while preserving GitHub mirror for visibility.
    - [ ] Recommend Gitea for lower resource footprint on home hardware; switch to GitLab CE if you want native CI/CD + container registry in one place.
    - [ ] Deploy as Docker container on the media host initially; migrate to K3s once 5a is stable.
    - [ ] Pair with a `git-mirror` cron that pushes selected repos to GitHub for hiring-manager visibility.
- [ ] **DR / backup-restore drill** (added 2026-06-10):
    - [ ] Quarterly cadence: pick one service, blow away its data, restore from backup, validate end-to-end.
    - [ ] Target rotation: Q1 paperless-ngx, Q2 immich, Q3 K3s cluster manifests, Q4 a Docker volume from the media host.
    - [ ] The point is testing the *restore*, not the *backup*. Track the elapsed wall-clock time and document gaps every drill.
    - [ ] Note: Resilience requirement before scaling Phase 5e (Paperless-ngx) and Phase 5f (Immich) intake. Untested backups are a regression of fortress mode.

---

## 🚀 **Phase 5: Platform Maturity Track**
*Goal: Build legitimate platform-engineering experience on top of a stable lab — without destabilizing Phase 1–4 work. Each project is fortress-mode-aligned (adds resilience or learning sandbox isolation) AND produces a portfolio artifact.*

**Rule of thumb**: Nothing in Phase 5 starts until Phase 2 (failing disk) and Phase 3 (DNS isolation) are complete. Production stability beats resume polish.

### 5a. K3s Sidecar Cluster *(separate node, not main host)* — **ACTIVE (2026-06-09)**
*Why this passes the smell test: a dedicated learning cluster doesn't put Plex at risk, and provides an isolation boundary for experimental workloads. The Pi from Phase 3 (or a second NUC) is the natural target.*

Bring-up procedure documented in `docs/guides/OPENTOFU_K3S_MIGRATION.md` Part 2.

- [ ] **Hardware**: Reuse Phase 3 Pi (DNS first, K3s second) OR a separate mini-PC.
- [ ] **Cluster bring-up**: Single-node K3s with `--disable traefik --disable servicelb` (use Tailscale + nginx-ingress instead).
- [ ] **What runs there (NEVER prod Plex/STARR)**:
    - [ ] Experimental services (LLM inference, n8n, Vaultwarden, etc.) where K8s patterns are appropriate.
    - [ ] Sealed Secrets demo (real-world secret management story).
    - [ ] Pod Disruption Budget + HPA examples on something throwaway.
- [ ] **Hard boundary**: Plex, STARR, AdGuard, fortress guard, monitoring **stay on Docker on the media host**. They have host networking, GPU passthrough, and host iptables requirements that fight K8s.
- [ ] **Write-up**: document *why* I chose hybrid Docker + K3s instead of a full migration — the decision rationale is the durable artifact, not the cluster itself.

### 5b. GitOps on the K3s Cluster (lean FluxCD)
*Why this passes the smell test: GitOps demonstrably works for K8s manifests; pairs naturally with 5a; does NOT require migrating prod stack.*

- [ ] **Evaluation step before install** (revised 2026-06-10): both FluxCD and ArgoCD work, but the home-lab evidence leans Flux: native OpenTofu bootstrap, lighter footprint, CLI-first, and pairs cleanly with Renovate bot for image-version auto-PRs. ArgoCD has the better UI if you prefer a dashboard. Pick one; do not run both. Document the decision rationale — the *why* behind Flux vs Argo.
- [ ] Install the chosen GitOps tool into the K3s cluster (5a).
- [ ] Manifests live in a separate `home_lab_k3s/` repo (or subfolder), watched by the GitOps tool.
- [ ] App-of-apps pattern for at least 3 workloads.
- [ ] Demonstrate: git push → automatic deploy → rollback via git revert.
- [ ] **Add Renovate bot** for automated image-version PRs. The pattern: cluster manifest references `image: foo:1.36`; Renovate sees `foo:1.42` upstream; auto-opens a PR to bump; you merge; GitOps reconciles. End-to-end automation story without losing the human approval gate.
- [ ] **Do not** try to GitOps the Docker-Compose stack. That's a different problem; if you want compose-GitOps later, look at `komodo` or `dockge`, not ArgoCD/FluxCD.

### 5c. `infra-mcp` — Estate Control Plane (MCP server) — **flagship**

**The need (plain terms).** The estate now spans three places: this on-prem lab, a personal AWS account, and a Linode host running a live YouTube stream. Checking health means three dashboards and three logins. I want **one read-only place to ask plain questions** — *"is the stream up? any lab alerts? what's my AWS spend this month?"* — and get one answer.

**What an MCP server is (no jargon).** A small program that sits between an AI client (Claude Desktop/Code, Cursor) and my systems. The AI can't touch the systems directly; the program hands it a fixed **menu** of safe, read-only questions it's allowed to ask, and answers each by calling the right API. Like a waiter: the AI orders off a set menu, the kitchen (my infra) stays behind the counter.

**Use cases — the questions it answers:**
- `estate.health_overview` — one-shot status across all three environments (the headline tool).
- `homelab.service_status` / `homelab.active_alerts` — Prometheus / Alertmanager.
- `homelab.media.find_duplicates` · `homelab.plex.profile_check` · `homelab.fortress.status` · `homelab.backup.verify` — the Sonarr/Radarr/Plex/fortress operations bash is genuinely bad at (JSON parsing, retries, concurrency).
- `aws.cost_summary` / `aws.resource_inventory` — month-to-date spend + a light resource list.
- `linode.stream_status` / `linode.instance_metrics` — is the stream process up, instance health.

**Design (lean on purpose):**
- **Python + the official `mcp` SDK** — Python is already the daily driver and agentic tooling is Python-heavy. One provider module per service (`homelab`, `aws`, `linode`).
- **Read-only in v1.** No destructive tools.
- **Local stdio transport** — the client launches it as a subprocess on my machine; it reaches services over **Tailscale** + cloud APIs. Zero extra infra, and internal services never touch the public internet.
- **Secrets stay out of git** (env / gitignored `.env`): a scoped **read-only** AWS principal (Cost Explorer + light describe/list), a read-only Linode token, the Tailscale-internal Prometheus URL.
- **Don't rewrite working bash.** `infrastructure-manager.sh` orchestrating docker/iptables/systemd is correct as-is; the MCP server fills bash's *weak* spots (structured API calls), not its strengths.

**Design tradeoffs — the "why," not just the "what":**
- **Read-only first vs. action tools.** Handing an LLM restart/redeploy power is a real risk, so v1 stays read-only. Guarded mutation (explicit allowlist + human confirmation) is a *possible* Phase 2 — only if it earns its keep.
- **Local stdio vs. hosted always-on.** Hosting it (HTTP, behind Tailscale on a lab host) makes it always-available but adds auth, exposure, and a thing to babysit. Not worth it for a single user; revisit only if I actually want remote or automated callers.
- **Few, well-described tools > many narrow ones.** The LLM chooses better from a short, clear menu. Cut before adding.
- **MCP vs. a Go CLI.** A Go CLI (`sb-lab`, single static binary, Ansible-installed) would solve the same bash gaps and is still defensible if I want Go — but MCP is the protocol modern agent tooling already speaks, so one implementation serves many clients. Pick one; don't build both.

**Right-sizing guard:** this is a personal, read-only control plane — not a product. If it grows past "answer read-only questions about my own estate," that's scope creep, not progress.

### 5d. Observability Maturity (Stretch)
*Why this passes the smell test: bridges 4 and 5; demonstrates "I don't just install Grafana, I instrument my own services."*

- [ ] Expose custom Prometheus metrics from `sb-lab` (e.g., `sb_lab_duplicate_count`, `sb_lab_profile_check_passed`).
- [ ] OpenTelemetry traces for `sb-lab` operations that span multiple API calls.
- [ ] Grafana dashboard pulling from both Prometheus (metrics) and Loki (logs) on the same time range — "single pane of glass" story.

### 5e. Paperless-ngx Document Stack on K3s
*Why this passes the smell test: real multi-service workload for the K3s cluster (better K3s smoke test than throwaway demos), genuine personal utility (replaces Google Drive / Dropbox for documents), and the first concrete implementation of the Phase 6 Theme A ("move away from consumer cloud for primary storage") and Theme B ("retrieval over family docs") visions.*

Two-stage rollout. Stage 1 ships without AI; Stage 2 waits until Theme B's GPU node exists.

**Stage 1: Vanilla Paperless-ngx (do now, post-K3s bring-up)**
- [ ] Deploy paperless-ngx stack on K3s: paperless-web + postgres + redis + tika + gotenberg.
- [ ] Persistent volumes: documents + originals + thumbnails on Synology NAS (CIFS-mounted PV or NFS). Configs/DB on local node SSD.
- [ ] Ingress via nginx-ingress (per 5a's ingress story). Tailscale Funnel for off-LAN access.
- [ ] CPU-based OCR (Paperless-ngx defaults: tesseract). Good enough for typed docs and decent handwriting.
- [ ] Backup discipline: paperless data dir is Tier-1 in 3-2-1 backup *before* first medical/tax document gets scanned.
- [ ] Auto-import workflow: a watch folder on the NAS that paperless-ngx polls; mobile scanner app (Scanbot, Genius Scan, or iOS Notes) drops PDFs into the folder; auto-tagging on ingest.

**Stage 2: Local AI integration (defer to Theme B)**
- [ ] Wait for the GPU node from Phase 6 Theme B. CPU-only LLM inference is too slow to actually use day-to-day; if Stage 2 ships without a GPU, the AI features will get abandoned.
- [ ] **Candidate runtime**: Ollama (model serving) + **Hermes Agent** (agent runtime layer from Nous Research) as the integration plane. Hermes Agent's selling points: skill distillation across repeated runs, persistent context, API-server pattern that bridges cleanly into paperless-ai or a custom integrator. Validate against the alternative (raw Ollama + paperless-ai direct) before committing.
- [ ] **ToS caveat (added 2026-06-10)**: Anthropic announced restrictions on third-party agentic harnesses (OpenClaw, Hermes Agent, etc.) using Claude *subscription plans* for inference. Hermes Agent + open-source models on Ollama is unaffected. Hermes Agent + Anthropic API (pay-per-token, not subscription plan) is also fine. The path to avoid: Hermes Agent pointed at Claude Code subscription plans — that's the surface Anthropic restricted.
- [ ] Use cases: better OCR cleanup on poorly-scanned originals, LLM-suggested document types and correspondents, semantic search across the corpus.
- [ ] Hard rule: no document content ever leaves the LAN. The whole pitch is "self-hosted, no cloud."

**Hard boundary**: this is *documents only*, not credentials (Vaultwarden's job) and not photos (Immich is Phase 5f). One stack, one purpose.

**Risk callouts**:
- Storage growth ~2-3x raw scanned size (originals + thumbnails + OCR text). Plan NAS capacity. Not a Stage 1 blocker; Synology handles the first 6+ months easily.
- Backup is the single most important thing here. If the paperless data dir is your *only* copy of an important scan, you've made the household more fragile, not less. Get backups right before scaling document intake.

**Design note**: the deliberate two-stage sequencing — ship a CPU / no-AI Stage 1, then add GPU-backed OCR/AI in Stage 2 once the hardware lands — is the point. Splitting a project around real hardware constraints beats forcing a CPU-only build nobody uses.

### 5f. Immich Photo Stack on K3s
*Why this passes the smell test: same architecture pattern as 5e (self-hosted alternative to consumer cloud, K3s as the runtime, NAS as durable storage), different data type. Hits the Phase 6 Theme A photos slice. Replaces iCloud Photos / Google Photos with a stack you control.*

Same two-stage shape as 5e. Stage 1 ships without AI; Stage 2 waits on the GPU node.

**Stage 1: Vanilla Immich (do after 5e ships)**
- [ ] Deploy Immich stack on K3s: immich-server + immich-machine-learning (CPU mode initially) + postgres (pgvector) + redis.
- [ ] Persistent volumes: photo library on Synology NAS via CIFS or NFS PV. Postgres DB on local node SSD (vector search latency suffers on network FS).
- [ ] Ingress via nginx-ingress + Tailscale Funnel for off-LAN access (so the iOS / Android Immich apps work from anywhere).
- [ ] Migrate from iCloud / Google Photos: bulk export → Immich import via mobile app or CLI. Run for both spouses; family albums shared via Immich's sharing model.
- [ ] Backup discipline: photo library is Tier-0 (irreplaceable). Synology snapshots + offsite (Backblaze B2 or a relative's NAS via Tailscale) on day 1. Don't ingest the first family photo until backup is proven.
- [ ] Sunset criteria for cloud: keep iCloud / Google Photos running in parallel for 30-60 days post-migration. Only cancel cloud subscriptions after Immich proves out across mobile upload, search, sharing, and one full backup-restore drill.

**Stage 2: ML features on GPU (defer to Theme B)**
- [ ] Move immich-machine-learning to GPU mode on the Theme B GPU node. Enables fast face recognition, smart search (CLIP), and reverse-image lookup at usable speeds.
- [ ] Validate face-recognition false-positive / false-negative rate before relying on it for album organization.
- [ ] Note: this is separate from Hermes Agent / Paperless-AI. Immich's ML is built-in, no agent runtime needed.

**Hard boundary**: photos only. No documents (that's 5e). No videos that aren't camera-roll (Plex's job). No backup of arbitrary file types (separate backup story).

**Risk callouts**:
- Photo library is the highest-value, hardest-to-replace data in the house. The single biggest risk is treating Immich as a backup tier when it is *primary storage*. Backup discipline outranks every other consideration.
- Mobile-app auto-upload is non-negotiable for spouse adoption. If the iOS app fights you, fix that first; nothing else matters if uploads don't happen on their own.
- CIFS PV latency can make initial library scans slow. Consider local SSD cache for hot thumbnails.

**Design note**: the same two-stage pattern as Paperless-ngx (5e), applied to a second data type — a deliberate, repeatable architecture for self-hosted alternatives to consumer cloud, not a one-off. The family-adoption / migration-from-cloud playbook is the harder, more interesting half.

### 5g. Frigate NVR (defer until 5e + 5f stable)
*Why this passes the smell test: AI-driven surveillance fits the "internet-optional household" principle, hits Phase 6 Theme B (AI-driven NVR with Frigate), Phase 6 Theme D (Home Assistant integration), and Phase 6 Theme C (kids' safety lens). Lower hardware bar than previously estimated — Coral USB TPU at ~$100 handles object detection on 4-8 cameras, no need for a $1500+ GPU. The "AI on cheap hardware" angle is a legitimate portfolio talking point for edge-AI-deployment roles.*

**Hardware bar (corrected 2026-06-10)**:
- Compute: Raspberry Pi 5 (with AI Hat+) for 2-4 cameras, OR an old desktop with Coral USB Accelerator ($100) for 4-8 cameras.
- Cameras: RTSP-capable. Cheap path: Reolink E1 Pro (~$56/each) — PTZ, no internet dependency, easy to firewall off entirely.
- Network: cameras on isolated VLAN (Theme C tenant isolation prerequisite — when VLAN segmentation lands).

**Stage 1: Wired + small deployment (do after 5e + 5f stable)**
- [ ] Choose hardware target: Pi 5 + AI Hat+ for low-camera-count start, OR a small mini-PC + Coral USB if you expect to scale past 4 cameras.
- [ ] Deploy Frigate via Docker Compose on the chosen node (NOT on `mediaserver` — same hard boundary as the K3s rule: AI/NVR cannot share hardware with Plex).
- [ ] Configure RTSP feeds, object detection on Coral TPU, recording to NAS.
- [ ] **Network discipline**: cameras on isolated VLAN, no internet egress. Frigate is the only thing on the LAN that talks to them.
- [ ] Tailscale for remote viewing (do NOT expose Frigate UI publicly).

**Stage 2: Home Assistant + facial recognition (later)**
- [ ] Integrate Frigate with Home Assistant for "person detected at front door" automation (Theme D).
- [ ] Enable facial recognition for family members; validate false-positive rate before relying on it for any automation.
- [ ] License plate recognition if needed (driveway camera scenario).

**Hard boundary**: Frigate replaces *cloud cameras* (Ring, Wyze, Nest), not Plex, not home automation core. One purpose: local AI-driven surveillance.

**Risk callouts**:
- Wireless cameras at scale will overwhelm your WiFi mesh (real lesson from NetworkChuck's deployment — 10 wireless cameras destroyed his network). Plan wired-first; reserve wireless for cameras that physically cannot be wired.
- Cell-phone-network-down failure mode: if you depend on Frigate for any safety-critical view, design the redundancy. A camera that only works when your home internet is up is not a safety tool.
- Storage for continuous recording grows fast. Budget NAS capacity and retention policy (motion-only vs continuous) before camera count grows.

**Design note**: fully local AI surveillance on ~$100 of edge hardware — a Coral TPU handles object detection for the cameras with no cloud dependency and no data leaving the LAN. Edge inference on commodity hardware, privacy by design.

---

### 5h. Right-Sized App Delivery & Multi-Environment Monitoring (AWS + Linode)

*The estate extends past the house: a personal AWS account and a Linode host running a live YouTube stream. Two genuine needs — ship the things I deploy by hand, and watch the things that have real uptime stakes.*

**janellechung-site — automate a real deploy.**
- **Need:** the site ships today by hand-uploading files over FTP to shared hosting — manual and error-prone.
- **Design:** managed static hosting (S3 + CloudFront, or Cloudflare Pages / Amplify) provisioned with Terraform, plus a GitHub Actions pipeline: push to `main` → build + validate (HTML/link check, security headers) → deploy → invalidate cache.
- **Tradeoff / right-sizing:** a static marketing site needs *static hosting* — not a server, and definitely not a container cluster. The whole value is "it deploys itself and costs cents." Effort goes into the pipeline and the checks, not into running infrastructure.

**Linode stream — monitor and harden what's actually in production.**
- **Need:** the live stream has real uptime stakes (stream drops → viewers drop), and today there's no alert if the stream process dies.
- **Design:** export host + process health to the lab's Prometheus (node_exporter + a small stream-up check), add a blackbox probe against the public stream endpoint, and alert on "stream down" the same way the lab alerts on anything else. Write the restart runbook.
- **Tradeoff:** the cheapest reliable win is *observability + a restart runbook*, not re-platforming the stream. Watch it first; automate recovery only if failures actually recur.

**Design philosophy for this section — right-sizing.** The right answer is usually the *least* infrastructure that meets the real need: managed platforms over a Kubernetes cluster unless a workload genuinely justifies one. If I want GitOps/cluster practice, it belongs on the existing lightweight K3s (5b) — not on a new managed cluster stood up to run a personal web app. Over-engineering a small workload is a red flag, not an achievement.

### 5i. YouTube Data API — liked-videos export script (Python learning build, added 2026-07-18)
*Why this passes the smell test: a small, self-contained Python build that teaches the Google Cloud API skills the estate already touches (5h's Linode host runs a live YouTube stream), against my own real data. No infra touched — it sits outside the Phase 2/3 stability gate and fits one Career & Homelab afternoon block per rung.*

**The need (plain terms).** My liked-videos list is locked behind my Google account — no way to export, search, or feed it into other tooling (e.g. a graphify knowledge graph). A plain API key can't read it: the liked-videos playlist (ID `LL`) is private, which is exactly why this is the right OAuth learning vehicle instead of another key-in-a-header exercise.

**What it teaches (the actual point):**
- [ ] **Rung 1 — Google Cloud setup**: create a GCP project, enable YouTube Data API v3, create an OAuth client (Desktop type), download `client_secret.json`. Understand API key vs OAuth — *why* private data needs user consent.
- [ ] **Rung 2 — the OAuth flow**: installed-app flow with `google-auth-oauthlib`, `youtube.readonly` scope, token cached locally so consent happens once. Watch the browser round-trip actually happen.
- [ ] **Rung 3 — pagination + quota**: `playlistItems.list` on playlist `LL`, walk `nextPageToken` to the end, count quota units spent (1/page against the 10,000/day default) — same pagination pattern as every AWS `NextToken` API sentinel already uses.
- [ ] **Rung 4 — output**: write CSV/JSON (title, channel, video ID, URL, liked-order position) to a local file. Stretch: `--since` filter, or hand the output to graphify.

**Where it lives:** `scripts/youtube/liked_videos_export.py`. **Secrets discipline:** `client_secret.json` + the cached OAuth token must be gitignored *before* the first auth run (`.gitignore` covers `*.env` but not these JSONs — add explicit entries). The export output is personal data too — keep it out of git like the AdGuard query logs.

**Right-sizing guard:** one script, stdlib + the two Google client libraries, no daemon, no schedule. If it grows a database or a dashboard, that's scope creep.

### 5j. Local-AI Independence — free harness + local models (added 2026-07-18)
*Why this passes the smell test: it's the Phase 6 "Internet-Optional Household" principle applied to AI tooling — a coding assistant that costs $0/month, obeys no provider's session limits or harness ToS, and keeps working when the WAN is down. It also gives the Local-AI Portfolio Strategy its first real deployment instead of a plan.*

**The need (plain terms).** Today's AI workflow is a paid Claude Code subscription with session limits (one graph build burned an entire session in July), provider ToS that restrict which harnesses may use subscription plans (see the 5e Stage 2 caveat), and zero function without internet. Fortress mode already assumes the WAN dies — the AI tooling should survive it too. The goal is a graceful degradation tier: cloud AI when it's worth paying for, local AI always available underneath.

**Steps (in order — each is one afternoon block):**
- [ ] **Hardware-reality check first.** Inventory what inference the estate can actually do today: `mediaserver` CPU + Intel iGPU, the K3s node's CPU. Benchmark 1–2 quantized coding models (7–14B class, e.g. current Qwen-Coder tier) with Ollama or llama.cpp — measure real tok/s before designing anything. Write the numbers down; they decide everything downstream.
- [ ] **Local model serving.** Stand up Ollama (or llama.cpp server) as a service — K3s sidecar is the intended home (5a already lists LLM inference as an experimental workload), Docker on the media host is the fallback. Expose the OpenAI-compatible endpoint over Tailscale only.
- [ ] **Free harness on top.** Point a free, open-source harness at the local endpoint via a base-URL change. First candidate: **jcode** (MIT, Rust, vetted 2026-07-18 — real project, ignore its marketing numbers); alternatives if it disappoints: OpenCode, Aider. Result: a coding agent with zero subscription and zero internet dependency.
- [ ] **Define the honest split.** Local models on this hardware will NOT match frontier cloud models — decide explicitly which work goes local (Python drills, small scripts, offline/fortress scenarios, anything privacy-sensitive) and which stays cloud-paid until the Theme B GPU node exists. Write the split down; revisit quarterly.
- [ ] **Watch item — the falling floor.** Expert-streaming engines (Colibrì-class: 744B MoE in 25 GB RAM off NVMe, vetted 2026-07-18 — real but ~0.05–0.1 tok/s cold on laptop hardware) are dropping the RAM/VRAM bar monthly. Re-run the "frontier-at-home" math when the Theme B GPU decision comes up; don't buy hardware against today's numbers.

**Right-sizing / no-spend guard:** no GPU purchase now — this phase runs entirely on existing hardware, and the GPU node stays a Theme B decision made on measured need, not enthusiasm. If local inference on current CPUs proves too slow to use, the deliverable is still real: the serving/harness plumbing is GPU-ready, and the benchmark numbers become the Theme B business case.

## 🧭 **Phase Ordering Rationale**
- Phases 1–3 are **non-negotiable prerequisites**. A failing disk and a single-node DNS dependency outrank every platform-maturity item below.
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
- **Concrete implementations of this theme**: Phase 5e (Paperless-ngx for documents), Phase 5f (Immich for photos). Future candidates: Vaultwarden for credentials, Joplin/Trilium for notes.

### Theme B — AI / Intelligence Layer
- Local LLM serving (Ollama / vLLM) for daily-use chat, retrieval over family docs, automation glue.
- **Candidate agent runtime layer**: Hermes Agent (Nous Research) on top of Ollama for persistent-context, skill-distilling agents — to be validated when the GPU node lands. Alternatives in this space include OpenClaw and raw Ollama + custom code; do not commit to a runtime until you've used it under real load.
- **Candidate dev-tooling**: route Claude Code through Ollama for local-LLM-backed coding agent (cost lever for heavy personal sessions + portfolio talking point). Independent of Hermes.
- Voice replacement for Amazon Echo: Home Assistant Voice (Whisper + Piper + local LLM) for fortress-mode-tolerant voice commands.
- AI-driven NVR for security cameras (Frigate with GPU/Coral inference).
- Hardware reality: requires GPU. Used 3090 (24GB VRAM) or Mac Studio with 64GB+ unified memory is the realistic entry point. Should NOT share hardware with Plex transcoding.

### Theme C — Tenant Isolation
- Wife's photography & stationary business: separate storage, separate backups, possibly separate hosting (website, file delivery to clients).
- Kids' devices: per-device DNS policies (AdGuard), screen time, MDM, content filtering. Already partial via AdGuard; needs structured profiles as devices proliferate.
- **Kids' devices AWAY from home — decision paused 2026-08-05, pick up here.** Question raised: should kids' devices join the Tailscale mesh so AdGuard filtering follows them off the home network? **Current recommendation: no — use Apple Screen Time (Family Sharing) / Google Family Link instead**, and keep AdGuard scoped to at-home filtering for devices that can't run those (TVs, consoles, IoT). Reasoning: (a) joining a tailnet does NOT extend filtering by itself — it needs a tailnet-wide DNS override *plus* an exit node to route all traffic home, with real bandwidth/latency cost; (b) a visible VPN toggle isn't tamper-resistant without genuine device lockdown (iOS Supervised mode via Apple Configurator, or devices bought through Apple Business/School Manager — a real logistical hurdle); (c) it would make home-infra uptime a dependency for the kids' internet access *everywhere*, widening the exact failure mode that took the stack down on 2026-08-05, and doing so *before* Phase 3 (redundant DNS) exists to make an AdGuard outage survivable. **Revisit if:** Phase 3 lands AND device supervision/MDM is actually in place AND there's a filtering need Screen Time/Family Link genuinely can't cover. The Tailscale technical plan was deliberately not written up — scope it then, not now.
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
- Private torrent trackers: VPN compliance + cross-seed + autobrr — tighter STARR stack discipline. Check each target tracker's specific VPN/seedbox rules before joining (some ban shared VPN IPs as a multi-accounting risk; some only whitelist specific seedbox providers).
- Seedbox migration (evaluated 2026-08-01, prompted by a PIA renewal decision): move qBittorrent off the home VPN-gateway container onto a paid seedbox (~$5–15/mo, comparable to the PIA subscription cost) — provider's ToS explicitly allows torrent traffic, removes home IP/bandwidth from the equation entirely, and eliminates the "VPN container health = whole STARR stack health" fragility of the current `binhex/arch-qbittorrentvpn` gateway pattern. Sonarr/Radarr/Prowlarr would point at the seedbox as a remote download client instead of sharing its network namespace; finished downloads pulled to the NAS via an `rclone mount`. Real re-architecture (network_mode + storage/hardlink model both change), not a one-line swap — not urgent. Renew PIA now to unblock the stack; take this on as unhurried follow-on infra work.

### Theme F — Media Stack Evaluation (open question, NOT a commitment)
*Goal: name the Jellyfin-vs-Plex question so it gets revisited deliberately, not drifted into.*

- Current state: Plex is deeply ingrained — fortress guard, GPU transcode, host networking, managed-user profiles, mobile-app habits across the family. Switching cost is non-trivial.
- Open question: is Jellyfin (open source, no licensing, no remote-access dependency on a third party) the right destination once fortress mode generalizes to the whole household?
- Pros of evaluating: aligns with "internet-optional household" principle (Plex's remote-access path depends on plex.tv); removes Plex Pass licensing cost; future-proofs against Plex policy changes that have repeatedly burned the self-host community.
- Cons of switching: family-adoption cost (kids' watch history, profiles, kids-app UX); GPU transcode parity needs verification; fortress guard logic is Plex-specific and would need a Jellyfin equivalent.
- Decision gate: not before Phase 5e + 5f ship. Photos and documents are higher-value migrations than re-platforming a working media stack. Revisit after at least one of {Plex Pass renewal, family-impacting Plex policy change, fortress guard rewrite for other reasons} forces the question.

### Target Hardware Footprint (2-5 years)
A realistic multi-node lab, NOT one giant box:

| Node | Role | Status |
|---|---|---|
| **`mediaserver`** (current) | Media host: Plex, STARR, fortress guard, qBittorrent | Existing |
| **NAS** (Synology + future TrueNAS) | Primary storage tier, family backups, photos | Existing, needs expansion |
| **Pi / control node** | DNS (AdGuard + Unbound), Home Assistant, automation hub | Phase 3 |
| **AI / intelligence node** (GPU box) | Ollama, Hermes Agent, Frigate, voice (Whisper/Piper) | Theme B + 5e Stage 2 + 5g Stage 2 |
| **K3s / dev node** | Wife's business stack, dev/staging, ephemeral services, Paperless-ngx, Immich, MCP server | Phase 5a + 5c + 5e + 5f + Theme C |
| **Frigate / edge-inference node** | Local AI NVR (Coral TPU + RTSP cameras) | Phase 5g |
| **Self-hosted Git node** | Gitea or GitLab CE for personal repos | Phase 4 (post-2026-06-10 add) |
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

---

## 🎯 **Local-AI Portfolio Strategy (2026-06-10)**

Threading the Phase 5 + Phase 6 projects into a coherent technical narrative — deliberate, deployment-focused local-AI work rather than scattered self-hosting.

**The framing:** "Edge AI is a $25B → $143B market growing at 21% CAGR. Most developers consume AI through cloud APIs; almost nobody knows how to deploy local AI inference on company hardware. I'm in the 18% of developers building AI integrations, and the 1-in-many that has run a multi-stage local AI pipeline against real personal data in a production-shaped home lab."

**The supporting evidence on the roadmap:**
- **Phase 5e Stage 2** — Paperless-ngx + Ollama + Hermes Agent for personal document retrieval. Demonstrates local LLM serving + agent runtime layer + privacy-preserving design.
- **Phase 5f Stage 2** — Immich + GPU-accelerated ML for face recognition and CLIP smart search. Demonstrates local computer vision deployment.
- **Phase 5g** — Frigate on Coral TPU for local AI surveillance. Demonstrates edge-inference deployment on commodity hardware, not flagship GPUs.
- **Phase 5c (MCP path)** — custom MCP server exposing home lab APIs. Demonstrates protocol-level understanding of agentic tooling.
- **Phase 6 Theme B (voice replacement)** — Home Assistant Voice with Whisper + Piper + local LLM. Demonstrates speech-to-text and TTS as production pipelines.

**The "boring use cases that actually work" lens:**
The local AI use cases that match or beat cloud are NOT the flashy ones. They're transcription (Whisper), narrow-tool agents, image classification, and OCR cleanup. Every concrete project above is in the "boring but works" category — none of them claim local LLM coding beats Claude, none claim 5-tool agentic chains work. The roadmap deliberately stays in the working zone.

**What this adds up to:**
By the time Phase 5e Stage 2, 5f Stage 2, and 5g are all running, the through-line is clear: "I deploy local AI on commodity hardware for privacy-sensitive use cases. I've made the build-vs-buy and CPU-vs-GPU decisions deliberately based on actual benchmarks, not vibes. I understand the protocol layer (MCP), the model layer (Ollama + open-source models), and the runtime layer (Hermes Agent or raw integrations) — and I have working systems against real personal data to show it."

The emphasis is deployment engineering, not research — practical local-AI delivery on commodity hardware for privacy-sensitive use cases.
