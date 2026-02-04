# Infrastructure Tier Scorecard (Current vs 90+ Target)

**Last Updated**: 2025-12-31
**Goal**: Achieve **90+** in each tier by executing the roadmap (not by inflating scores).

---

## Scoring Model (How scores are earned)

Each tier is scored **0–100** using these weighted signals:

- **Reliability / SLO readiness (30)**: predictable behavior, no recurring incidents, clean restarts
- **Security / least privilege (25)**: secrets, auth, least privilege, safe exposure
- **Observability (20)**: metrics, logs, dashboards, alerts, runbooks
- **Automation / IaC (15)**: reproducible, drift-controlled, documented change process
- **Capacity / Headroom (10)**: storage, CPU/RAM, network, buffering space

**90+ means**: stable, secure-by-default, observable, reproducible, with headroom.

---

## Tier 1 — Network & Connectivity

**Current Score: 72/100**

- **What’s holding it back**
  - Wi‑Fi extension/backhaul variability still impacts real workloads
  - Limited segmentation (IoT/cameras not strongly isolated yet)
  - No consistent QoS policy protecting “media traffic” during contention

**90+ Solution**
- Stable backhaul for `SC Home_Ext` (MoCA or Ethernet)
- Measurable QoS/bandwidth policies for external streaming vs local playback
- Segmentation plan (VLANs / “IoT isolation” baseline)

**Implementation**
- Sprint 2 EPIC 5 (backhaul plan + MoCA trial)
- Sprint 4 EPIC 9 (non-interference policy)

---

## Tier 2 — Compute (Server OS + Hardware)

**Current Score: 58/100**

- **What’s holding it back**
  - OS/kernel are outdated (security + driver stability risk)
  - USB topology pitfalls discovered (NIC + USB media drive path sensitivity)

**90+ Solution**
- OS upgrade to a currently supported LTS
- Normalize hardware topology (onboard NIC for Plex; avoid shared USB hub contention)

**Implementation**
- Sprint 1 EPIC 1 (Plex reliability)
- Phase 3 in `COMPREHENSIVE_FINAL_REVIEW.md` (OS upgrade)

---

## Tier 3 — Storage & Data (NAS + External + Mounts)

**Current Score: 45/100**

- **What’s holding it back**
  - Storage at/near full (blocks buffers, increases fragility)
  - CIFS/mount reliability risks have occurred historically

**90+ Solution**
- Headroom targets enforced (alerts + cleanup + lifecycle)
- Predictable mounts at boot + consistent paths for Docker

**Implementation**
- Sprint 1 EPIC 3 (headroom + alerts)
- Sprint 3 EPIC 7 (fstab + CIFS hardening)

---

## Tier 4 — Security (Identity, exposure, least privilege)

**Current Score: 55/100**

- **What’s holding it back**
  - Historical: root containers, privileged exporters, weak defaults (some still pending)
  - Home IoT/camera ecosystem constraints (apps depend on cloud)

**90+ Solution**
- Zero-root policy for containers
- Strong secrets + consistent credential handling
- Reduce public exposure surface; remote access via VPN

**Implementation**
- Sprint 1 EPIC 2 (hardening)
- Sprint 4 EPIC 8 (fortress mode constraints documented + mitigations)

---

## Tier 5 — Observability (Metrics, logs, alerting, runbooks)

**Current Score: 70/100**

- **What’s holding it back**
  - Monitoring exists but isn’t yet “incident answering” for Plex stalls
  - Alerting/SLOs not fully defined

**90+ Solution**
- Dashboard answers: “why is Plex stalling right now?”
- Alerts for disk headroom, container down, DNS failure

**Implementation**
- Sprint 3 EPIC 6 (SLO-driven dashboards + alerts)

---

## Tier 6 — Automation / IaC (Terraform + Ansible)

**Current Score: 60/100**

- **What’s holding it back**
  - Drift between “running” compose on server vs “proposed” repo configs
  - Terraform should be the authoritative manager for Docker (migration in progress)

**90+ Solution**
- Terraform is the single controller for Docker containers you care about
- Migration strategy documented; no half-managed stacks

**Implementation**
- Sprint 2 EPIC 4 (AdGuard via Terraform)
- `INFRASTRUCTURE_MANAGEMENT.md` “Terraform as source of truth” section

---

## Tier 7 — Media Delivery (Plex 4K local + external 1080p)

**Current Score: 62/100**

- **What’s holding it back**
  - Direct Play “freezing” events still observed; root cause includes client/backhaul/topology
  - Storage headroom blocks some fallback strategies (transcode buffers)

**90+ Solution**
- Gold-path playback: stable client + stable path + stable server topology
- External streams capped and isolated from local performance

**Implementation**
- Sprint 1 EPIC 1 (reliability)
- Sprint 4 EPIC 9 (external limits + QoS)
- Reference: `PLEX_PLAYBACK_FREEZING_INVESTIGATION.md`

---

## What “90+ across all tiers” looks like (definition)

You’re at **90+** when:
- A 4K local direct play session runs for **60+ minutes with zero freezes**
- One external 1080p stream does **not** impact local playback
- A WAN outage does not break local Plex playback and local DNS
- No root/privileged containers
- Storage headroom alerts exist and prevent “0 bytes free” incidents
- Terraform is the source-of-truth for Docker (for chosen stacks)


