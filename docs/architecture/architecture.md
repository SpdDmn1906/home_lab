# Home Lab Architecture

**Last updated**: 2026-05-14
**Companion docs**: [Infrastructure Hardening Roadmap](../roadmap/INFRASTRUCTURE_HARDENING_ROADMAP.md) · [Hardware Roadmap](../roadmap/HARDWARE_ROADMAP.md)

---

## Guiding Principle: Internet-Optional Household

Fortress mode is the architectural north star: **every service important to the family must work without the public internet, and we own the data behind it.** This principle is not aspirational — it's the test every architectural decision is graded against.

Concretely:
- DNS resolution survives a media-host crash.
- Plex serves cached content when plex.tv is down (fortress guard).
- Photos, business files, and family data live on hardware we control.
- Future: voice assistants, security cameras, automation, AI assistance — all internet-optional.

What we explicitly reject:
- One-giant-server consolidation. Resilience requires separation.
- Cloud-first architectures. Cloud is fine for cold backup, not primary.
- Full Kubernetes migration of prod media stack. K8s is the wrong tool for host-networking + GPU passthrough workloads.

---

## Current State (2026-05)

### Network Topology
```
Comcast 2GB
    ↓
Xfinity Xfi Modem (bridge mode)
    ↓
Asus Nighthawk RAX50 (DHCP + DNS)
    ↓                    ↓                    ↓
"SC Home" WiFi      Eero Mesh (bridge,    Wired devices
  (Asus, primary)    3 nodes, "_Ext")     (NAS, cameras, etc.)
```
Single 192.168.1.0/24 subnet (eliminated double NAT). ~30+ devices.

### Compute & Storage
```
┌──────────────────────────────────────────────────────────┐
│ mediaserver (single Linux media host)                     │
│                                                          │
│  Docker stack:                                           │
│   • Plex Media Server (host networking)                  │
│   • STARR: Sonarr, Radarr, Prowlarr, Bazarr             │
│   • qBittorrent (+ FlareSolverr)                         │
│   • AdGuard Home (currently THE house DNS)               │
│   • Plex Fortress Guard (iptables watchdog)              │
│   • Monitoring: Prometheus, Grafana, Loki, Promtail,    │
│     cAdvisor, Node Exporter, Blackbox Exporter           │
│   • Log error scanner (textfile collector)               │
└──────────────────────────────────────────────────────────┘
        │                              │
        ▼                              ▼
   Synology NAS                External HDD (/dev/sda)
   (2-bay, 4 TB)              **FAILING — see roadmap**
   CIFS mount                  2 TB
```

### Single Points of Failure (SPOFs) Currently
| SPOF | Risk | Mitigation Phase |
|---|---|---|
| `/dev/sda` failing | Filesystem corruption, IO avalanche | Phase 2 (urgent) |
| AdGuard on media host | DNS dies when host dies → whole house offline | Phase 3 (Pi) |
| No UPS | Power loss = forced shutdown, possible data corruption | Phase 4 |
| Single ISP | No internet redundancy | Phase 6 (optional) |
| Single compute host | All Docker services share one fate | Phase 5 + 6 (multi-node) |
| Single NAS | RAID is not backup; offsite missing | Phase 6 (Theme A) |

---

## Target State (2-5 Year Horizon)

A small private cloud, **not** one bigger server. See [INFRASTRUCTURE_HARDENING_ROADMAP.md Phase 6](../roadmap/INFRASTRUCTURE_HARDENING_ROADMAP.md) for full vision.

### Target Topology
```
                 ┌─────────────────────────┐
                 │  VLAN-capable network   │
                 │  (Unifi or OPNsense)    │
                 └────────────┬────────────┘
                              │
        ┌─────────────────────┼─────────────────────────────┐
        │                     │                             │
        ▼                     ▼                             ▼
┌──────────────┐    ┌──────────────────┐         ┌──────────────────┐
│ mediaserver   │    │ Pi / control     │         │ AI / intelligence│
│              │    │ node             │         │ node (GPU)       │
│ • Plex       │    │ • AdGuard+Unbound│         │ • Ollama / vLLM  │
│ • STARR      │    │ • Home Assistant │         │ • Frigate (NVR)  │
│ • qBittorrent│    │ • Zigbee/Z-Wave  │         │ • Whisper/Piper  │
│ • Fortress   │    │ • Backup DNS     │         │   (voice)        │
│ • Monitoring │    └──────────────────┘         └──────────────────┘
└──────────────┘                                          │
        │                                                 │
        ▼                                                 ▼
┌──────────────────┐                              ┌──────────────────┐
│ Storage tier     │                              │ PoE camera mesh  │
│ • Synology       │                              │ (Reolink/Amcrest)│
│ • TrueNAS (8-bay)│ ◄────── 3-2-1 backup ───────┤ Local recording  │
│ • Offsite copy   │                              │ via Frigate      │
└──────────────────┘                              └──────────────────┘

       ┌──────────────────────────┐
       │ K3s / dev node           │
       │ • Wife's business stack  │
       │ • Dev/staging envs       │
       │ • ArgoCD (GitOps)        │
       │ • Ephemeral services     │
       └──────────────────────────┘

  All nodes joined via Tailscale mesh.
  Reproducible via Ansible roles.
```

### Physical Layout (12–15U Enclosed Rack)
```
┌────────────────────────────────────────┐
│ Cable mgmt / patch panel        (1U)   │
├────────────────────────────────────────┤
│ VLAN-capable switch             (1U)   │
├────────────────────────────────────────┤
│ PoE switch (cameras)            (1U)   │
├────────────────────────────────────────┤
│ Shelf: Pi (control node)        (1U)   │
├────────────────────────────────────────┤
│ Shelf: K3s mini-PC + AI node    (2U)   │
├────────────────────────────────────────┤
│ TrueNAS chassis (future)        (4U)   │
├────────────────────────────────────────┤
│ Rack PDU                        (1U)   │
├────────────────────────────────────────┤
│ UPS (1500VA, 2U rack-mount)     (2U)   │
└────────────────────────────────────────┘
        ~13U used, room to grow

Outside the rack (consumer form factor):
  • Synology NAS
  • mediaserver tower (existing media host)
```

### Tenant Boundaries
| Tenant | Boundary | Hardware Locality |
|---|---|---|
| **Family media** | Plex + STARR on `mediaserver` | Single host, Docker |
| **House services** | DNS, Home Assistant, automation | Pi / control node |
| **Family data** | Photos, documents, backups | NAS tier |
| **Wife's business** | Photography & stationary biz | K3s namespace + dedicated storage share |
| **Personal dev** | Web/mobile app projects | K3s namespace, ephemeral |
| **Kids' devices** | Per-device DNS policy, MDM | AdGuard profiles + network VLAN |
| **Intelligence** | LLM, voice, NVR inference | GPU node, NOT shared with Plex |
| **Cameras** | Recording + AI events | PoE mesh + GPU node |

---

## Why Multi-Node, Not Bigger Single Node

A single beefier server is the wrong answer for our principle:

1. **Fortress mode requires separation.** DNS on the same box as Plex means a Plex crash kills the family's internet. Already happened (2026-05-09 outage).
2. **Different workloads have different SLOs.** Media streaming wants quiet + cheap. AI inference wants a GPU and accepts noise. Cameras want write-heavy storage. Cramming them together creates resource contention, not "efficiency."
3. **Tenant isolation requires hardware boundaries.** Wife's business website and kids' device traffic should not be one `iptables` typo away from breaching prod media.
4. **Reproducibility requires roles, not snowflakes.** Ansible roles per node type (media, control, AI, K3s) is the clean abstraction.

---

## Service Dependency Map

### Critical Path (must work for fortress mode)
1. **DNS** → AdGuard on Pi (target) / AdGuard on `mediaserver` (current)
2. **Storage I/O** → NAS available, CIFS mounts healthy
3. **Plex** → host networking, GPU passthrough (if used), fortress guard active
4. **Power** → UPS for graceful shutdown

### Important but Not Critical
- STARR stack (paused acquisition is recoverable)
- Monitoring (visibility loss is degraded mode, not down)
- Automation, voice, AI (Phase 6)

---

## Decisions Already Made

| Decision | Reason |
|---|---|
| Plex stays on Docker, not K8s | Host networking + GPU + iptables fortress guard fight K8s patterns |
| AdGuard moves OFF media host to Pi | SPOF elimination (Phase 3) |
| Terraform-Docker is fine, no rewrite | It works; migration cost > benefit |
| Ansible is the reproducibility tool | More portable than per-service shell scripts |
| Tailscale, not VPN/port-forward | Zero inbound exposure, simplest mesh |
| Local-first for family data | Cloud as cold backup only |
| Used 3090 likely path for AI | Best $/VRAM for Ollama + Frigate (when time comes) |

---

## Open Architectural Questions

- **TrueNAS vs. expand Synology further** when current NAS fills. Likely TrueNAS for capacity tier, Synology for warm tier.
- **Network gear refresh trigger**: when does the eero mesh get retired for VLAN-capable gear? Probably when kids' devices proliferate or wife's business goes public-facing.
- **Cameras: full Frigate migration vs. hybrid**. Likely hybrid — keep some Nest for cloud accessibility, move outdoor + critical to Frigate-managed PoE.
- **Backup offsite strategy**: rotated drive vs. Backblaze B2 vs. relative's house via Tailscale. Cost vs. recovery time tradeoff.

These are deliberately not decided. Phase 6 is a vision, not a contract.

---

## See Also
- [Infrastructure Hardening Roadmap](../roadmap/INFRASTRUCTURE_HARDENING_ROADMAP.md) — phased execution plan
- [Hardware Roadmap](../roadmap/HARDWARE_ROADMAP.md) — purchasing sequence
- [Raspberry Pi DNS Setup](../guides/RASPBERRY_PI_DNS_SETUP.md) — Phase 3 build guide
- [UPS Deep Dive](../roadmap/ups-deep-dive.md) — Phase 4 sizing + NUT integration
- [ISP Assessment](./ISP-ASSESSMENT.md) — redundant internet analysis
- [Security Cameras](./security-cameras.md) — current camera setup
- [Gaming Network](./gaming-network.md) — PS5/Switch network considerations
- [Network Setup](./network-setup.md) — current network detail
- [Security Architecture](./security.md) — security model
