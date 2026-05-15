# Hardware Roadmap

**Date**: 2026-05-14
**Status**: ACTIVE
**Companion to**: [INFRASTRUCTURE_HARDENING_ROADMAP.md](./INFRASTRUCTURE_HARDENING_ROADMAP.md)

This is the **single source of truth for hardware purchases**. Every node, drive, UPS, sensor, and accessory the home lab will buy lives here, sequenced against the phases in the infrastructure roadmap. Update this doc when you buy something or when priorities shift.

The guiding principle: **internet-optional household.** Don't buy hardware that only works when the cloud is up. Don't buy capacity for today when growth is named in Phase 6.

---

## 📦 Current Inventory

### Compute
| Node | Role | Notes |
|---|---|---|
| `mediaserver` (Linux desktop) | Media host: Plex, STARR, fortress guard, monitoring | Single point of failure today |
| Mac Pro (workstation) | Daily driver, photo editing | Not part of lab infra |

### Storage
| Device | Capacity | Role | State |
|---|---|---|---|
| Synology NAS (2-bay) | 4 TB | TV, movies, backups | Healthy |
| External HDD #1 | 2 TB | Movies / TV overflow | **FAILING — `/dev/sda`, 3,959+ reallocated sectors** |
| Mac Pro internal | — | Photo library / business files | Backup story incomplete |

### Network
- Xfinity Xfi modem (bridge mode)
- Asus Nighthawk RAX50 (primary router, DHCP, DNS)
- Amazon Eero mesh (3 nodes, bridge mode)
- Unified 192.168.1.0/24 subnet

### Security / IoT
- Nest cameras (1 outdoor + 2 indoor, cloud-bound)
- Eufy cameras (2 outdoor + Homebase hub, local-capable)
- Abode security system (2 motion sensors + 5 entry points)
- ~30 smart home devices (plugs, bulbs, LED strips)

### Power
- **No UPS currently** — explicit single point of failure

---

## 🛒 Purchase Sequence (mapped to roadmap phases)

### Phase 2 — Hardware Remediation (URGENT)

#### 2.1 Replacement Drive for `/dev/sda`
- **Don't buy 2TB.** Phase 6 storage growth is named — buy with headroom.
- **Recommended**: 8 TB CMR HDD, **NAS-rated** (WD Red Plus 8TB, Seagate IronWolf 8TB, or Toshiba N300 8TB).
- **Why CMR not SMR**: random writes in Plex/STARR usage patterns destroy SMR performance.
- **Why 8 TB not 4 TB**: cost per TB sweet spot in 2026; matches Synology bay expansion plan.
- **Why NAS-rated**: built for 24/7 vibration tolerance and bay-array migration. Lets us reuse this drive in the Synology or future TrueNAS in Phase 6.
- **Install internally in `mediaserver`, NOT in a USB enclosure**. SATA-to-USB bridges sometimes misrepresent sector size, which can block clean migration into a NAS pool later. Internal SATA install = the drive itself can be pulled and dropped into a NAS bay when the time comes.
- **Budget**: ~$170–200.
- **Pre-purchase task**: confirm chassis has a free SATA + power. If no free SATA port, that's a separate decision point — possibly skip this drive purchase and accelerate the Phase 6 NAS expansion instead.

> **Drive reuse path**: 8 TB internal → Plex media tier on `mediaserver` (replaces failed `/dev/sda`) → later pulled and added to Synology SHR pool (or TrueNAS RAIDZ2 vdev). NAS-rated CMR drives migrate cleanly between platforms; bought once, used for ~5–8 years across multiple roles.

#### 2.2 (Optional) Drive Enclosure for ddrescue
- Only if attempting `/dev/sda` recovery.
- **Recommended**: any single-bay USB 3.2 dock (~$30).
- Treat the original drive as write-once-read-once; clone it, then retire.

---

### Phase 3 — Architectural Decoupling (Raspberry Pi)

> **Design decision**: DNS and Home Assistant get **separate nodes**. They have different criticality (DNS down = whole house offline; HA down = lights stuck) and different change cadences (DNS is stable for months; HA updates weekly and occasionally breaks). Sharing one Pi means an HA upgrade can take down the family's internet. Two small nodes is the right answer.

#### 3.1 DNS Pi (the fortress-grade appliance)
- **Role**: AdGuard Home + Unbound. Nothing else. Keep it boring.
- **Hardware**: Raspberry Pi 4 Model B, **2 GB RAM** (DNS workload is tiny — don't oversize).
- **Power supply**: Official USB-C 5V/3A PSU (avoids under-voltage errors).
- **MicroSD**: 64 GB **high-endurance** card (SanDisk High Endurance or Samsung PRO Endurance).
- **Case**: Flirc aluminum passive case (silent, good thermals).
- **Ethernet cable**: mandatory. Never run DNS over WiFi.
- **Budget**: ~$95–110.
- **See**: [Raspberry Pi DNS Setup Guide](../guides/RASPBERRY_PI_DNS_SETUP.md).

#### 3.2 Home Assistant Node *(deferred to start of Theme D)*
- **Role**: Home Assistant Operating System (HA-OS), Zigbee/Z-Wave coordinator, automation logic, Frigate integration glue.
- **When to buy**: not yet. Buy when actually starting Theme D (Phase 6 automation) — not speculatively.
- **Hardware options** (pick when ready):
  - **Raspberry Pi 5, 8 GB**: ~$80 + accessories (~$140 total). Fine for moderate HA workloads.
  - **Home Assistant Green** (official appliance): ~$100. Plug-and-play, no SD card pain.
  - **Used mini-PC (Beelink/Minisforum/old NUC)**: ~$150–250. Best path if you also want it to run Frigate or Scrypted. SSD storage = no SD card wear concern.
- **Recommendation**: **mini-PC**, because it can later co-host Scrypted (camera bridge to phone apps — see 6.4) or run Frigate inference if you go the Coral TPU route. A Pi 5 8GB is the budget option.
- **Why NOT on the DNS Pi**: separation of concerns. HA gets updated weekly; DNS shouldn't be affected by HA's release cadence.

#### 3.3 (Deferred) Zigbee/Z-Wave Coordinator
- Hold until Theme D (automation) starts and the HA node (3.2) is online.
- **Recommended**: Sonoff Zigbee 3.0 USB Dongle Plus (ZBDongle-E, ~$25) — known good with Home Assistant ZHA.
- Plugs into the HA node, NOT the DNS Pi.

---

### Phase 4 — Resilience & Automation

#### 4.1 UPS (Uninterruptible Power Supply)
- **Critical**: protects against data corruption from power loss, the kind of low-glamour senior-engineer purchase that prevents most home-lab disasters.
- **Size for the future, not today**: Phase 6 names 4–5 nodes. Don't size for 300W; size for 600–800W draw.
- **Form factor decision (couples with 4.2)**: if going rack-mount path, pick the rack version of the same model. Don't buy a tower UPS now and replace it later.
- **Recommended (rack path)**: APC Smart-UPS SMT1500RM2U (rack-mount, 2U) or CyberPower OR1500LCDRM1U.
- **Recommended (tower path)**: APC Smart-UPS SMT1500 (tower) or CyberPower OR1500LCD.
  - Pure sine wave (matters for active-PFC PSUs in modern servers).
  - AVR (handles brownouts without burning battery).
  - 15–20 min runtime at expected load.
  - NUT-compatible for Prometheus integration.
- **Budget**: $300–400 (tower) / $350–450 (rack 2U).
- **Deep dive**: [ups-deep-dive.md](./ups-deep-dive.md) for sizing math, NUT setup, monitoring integration.

#### 4.2 Server Rack — Decision Point
- **When this becomes worth it**: roughly when you cross 3 pieces of network/server gear that *want* to live in a rack (UPS + PoE switch + future TrueNAS chassis is the natural trigger).
- **Honest tradeoff**: a rack is mostly *organization and cable management*, not capability. Don't buy one for the aesthetic — buy when you actually have rack-form gear to put in it.
- **Form factors to choose between**:

  | Option | Size | Cost | When it fits |
  |---|---|---|---|
  | **Open-frame mini rack (StarTech 12U)** | 12U, 19" | $100–150 | Closet/basement, ventilated, low noise concern |
  | **Enclosed half-height (Navepoint 12U/15U wall or floor)** | 12–15U, 19" | $200–350 | Residential — sound dampening + dust control |
  | **DeskPi RackMate T2 (10" mini rack)** | 8U, 10" | $200 | **Skip** — too small for standard 19" gear; trendy but cripples future fit |
  | **Full enterprise 22U+ rack** | 22U+, 19" | $400+ | Only if you have a dedicated room and high tolerance for noise |

- **Recommendation**: **Enclosed 12U or 15U wall-mount or floor rack** (Navepoint, Tripp Lite SR12UB, StarTech). Sized to hold UPS (2U) + future PoE switch (1U) + VLAN switch (1U) + TrueNAS chassis (4U) + 1–2 mini-PCs on shelves (2U) + cable mgmt (1–2U) = ~12U used, room to grow.
- **Why NOT a 10" mini rack**: most server/networking gear is 19". A 10" rack locks you out of all of it. Acceptable only for Pi-only setups.
- **What still won't fit in the rack**: existing Synology NAS (consumer form factor), tower desktop `mediaserver`. Plan for shelf or floor placement adjacent to the rack.
- **Budget**: $200–350 + ~$50 for accessories (shelves, cable mgmt arms, PDU bar, screws).

#### 4.3 Rack Accessories (only if buying the rack)
- **Rack shelves** (1–2): for non-rackmount gear like mini-PCs and the Pi. ~$25 each.
- **PDU (rack power distribution)**: basic 8-outlet rack PDU, ~$40. Not a UPS — sits between UPS and devices for tidy power distribution.
- **Cable management bars / Velcro ties / patch panel**: ~$30–50 total.
- **Optional rack KVM**: skip. SSH + Tailscale + IPMI (on capable boards) cover this without dedicated KVM hardware.

#### 4.4 (Optional) Spare High-Endurance SD Card for Pi
- Cheap insurance. Same model as 3.1, kept in drawer.
- **Budget**: ~$20.

---

### Phase 5 — Platform Maturity (career growth track)

#### 5.1 K3s / Dev Node *(only after Phase 1–4 stable)*
- **Two paths**, pick based on Theme C demand:
  - **Path A — Reuse Phase 3 Pi**: cheapest, fine for learning K3s manifests and ArgoCD. Will struggle with anything memory-heavy.
  - **Path B — Dedicated mini-PC**: Beelink SER5, Minisforum UM690, or used Intel NUC. 16–32 GB RAM, 500 GB NVMe. ~$300–500.
- **Recommendation**: skip this until you have a real workload (Theme C: wife's business stack, your dev environments). Learning K3s in a vacuum is portfolio theater.

---

### Phase 6 — North Star (2-5 year horizon)

These are flagged for **planning awareness**, not immediate purchase. Sequence drives Phase 2–5 sizing decisions.

#### 6.1 AI / Intelligence Node (Theme B)
- **The single biggest hardware decision in Phase 6.** Drives Frigate, Ollama, Home Assistant Voice all at once — but the right answer depends on whether you prioritize **one-box-does-everything** or **silence + simplicity**.
- **DO NOT** put this in the media host. GPU contention will kill Plex transcoding.

##### Path A — Used NVIDIA RTX 3090 in a custom PC *(one-box-does-everything)*
- 24 GB VRAM fits Ollama up to ~30B param Q4 models comfortably.
- Frigate runs TensorRT-accelerated inference on the same GPU — Frigate's preferred path.
- Whisper/Piper for voice also run on the same GPU.
- **Cost**: ~$700–900 (used 3090) + ~$400–600 (used Ryzen tower / new mini-ITX build) = **~$1,200–1,500 total**.
- **Downsides**: noise, power draw (350W under load), heat, takes rack/floor space. Needs a real chassis with airflow.
- **Best for**: maxing out capability per dollar, willing to tinker with PC hardware.

##### Path B — Mac Mini M4 Pro (or Mac Studio M4 Max) *(silent, simple, LLMs-focused)*
- **You're hearing about this for good reason.** Apple Silicon unified memory is genuinely excellent for LLM inference, and Ollama supports it natively via MLX.
- **Mac Mini M4 Pro, 64 GB unified**: ~$2,000. Runs Llama 3.x 70B Q4, Qwen 32B comfortably. Silent, ~15W idle.
- **Mac Studio M4 Max, 64 GB+ unified**: $2,000–3,500. More headroom for larger models, faster inference.
- **The catch — Frigate**: CoreML on Apple Silicon is dramatically weaker than CUDA/TensorRT for NVR object detection. Frigate works but at lower FPS / lower accuracy / fewer concurrent streams. **Mac Mini = LLMs only.** Frigate would need a separate box.
- **Skip the base M4 Mini (16 GB)**: too little memory for serious local LLMs.
- **Best for**: LLM-first, silence-first, will accept a separate small box for Frigate.

##### Path C — Hybrid: Mac Mini (LLMs) + small Frigate node
- Mac Mini M4 Pro 64 GB for Ollama + voice. ~$2,000.
- Small Frigate node: mini-PC (Beelink SER5 or Minisforum, ~$300) + **Google Coral M.2 TPU** ($80) OR small used NVIDIA card (GTX 1660 / RTX 3050, ~$150 used).
- **Total**: ~$2,400–2,500. Quiet, modular, two independent failure domains.
- **Best for**: prioritizing silence/simplicity AND wanting full Frigate capability.

##### Honest comparison

| Criterion | Path A (3090 PC) | Path B (Mac Mini Pro) | Path C (Hybrid) |
|---|---|---|---|
| Ollama / LLMs | Excellent | Excellent | Excellent |
| Frigate / NVR inference | Excellent | Weak | Excellent |
| Noise | Loud under load | Silent | Quiet |
| Power draw | 350W peak | 30W peak | 60W peak combined |
| Total cost | $1,200–1,500 | $2,000 | $2,400–2,500 |
| Failure domain | One box | One box, Frigate elsewhere | Two boxes |
| Career-relevance signal | NVIDIA/CUDA = industry standard | Apple Silicon ML = niche but growing | Both | 

##### Recommendation
- **If you can tolerate noise or have a basement/closet**: **Path A (used 3090)** wins on $/capability and is the standard industry stack.
- **If silence and "set and forget" matter more**: **Path C (Mac Mini + small Frigate node)** is the cleanest, most resilient setup, at higher cost.
- **Avoid pure Path B** unless you've already decided Frigate isn't your camera answer (e.g., UniFi Protect path — see 6.4).

#### 6.2 NAS Expansion (Theme A)

##### Tenant storage breakdown
Storage needs scale very differently by tenant. Size for the *sum*, not the average:

| Tenant | Workload | Approx. size at maturity | Backup tier |
|---|---|---|---|
| **Family media** (Plex) | Sequential reads, occasional writes | 6–20 TB | Local snapshots only (replaceable) |
| **Family photos** | Few large writes, many reads | 1–3 TB | **3-2-1 critical — irreplaceable** |
| **Wife's business** (photography + stationary) | Heavy writes (RAW files), client deliveries | 2–10 TB growing | **3-2-1 critical — legally + financially important** |
| **Personal dev work** | Small files, frequent writes, git repos | 100 GB–1 TB | Snapshots + offsite |
| **Camera recordings** | 24/7 writes, mostly auto-purged | 2–8 TB depending on retention | NOT backed up (transient) — separate drive in AI node |
| **System backups / VM snapshots** | Periodic large writes | 1–5 TB | Lives on NAS; offsite the critical subset |

**Total at maturity**: ~15–40 TB live, plus offsite copies of the critical subset (~5–15 TB).

##### Logical separation strategy
- **Separate shares per tenant**, with separate Linux/ACL permissions:
  - `/family-media` — read access for Plex, household streaming
  - `/family-photos` — household personal access, no business or media access
  - `/business` — wife's access (workstation + her devices); your access for admin only
  - `/dev` — your access; not shared
  - `/backups` — system-owned, not user-mounted
- **Why separate shares, not just folders**: enables per-share snapshot schedules, per-share replication, per-share encryption-at-rest keys, and per-share quotas.
- **Snapshot policy**: family-photos and business get hourly snapshots with long retention (90 days+). Media gets daily, short retention. Dev syncs to GitHub regardless.
- **Encryption-at-rest**: business share gets its own encryption key (separate fortress concern — protect against device theft or NAS theft).

##### Hardware path
- **Stage 1**: Add 2× 8 TB drives to existing Synology 2-bay (Synology SHR allows expansion). If 2-bay is full, replace one disk at a time with larger. ~$340–400.
- **Stage 2**: When Synology fills, build dedicated TrueNAS box.
  - Chassis: Jonsbo N3 (8-bay, residential-friendly noise) or used Supermicro 24-bay if going full enterprise.
  - CPU: Ryzen 5/7 (ECC support important for ZFS); 32–64 GB ECC RAM.
  - Start with 4× 12 TB drives in RAIDZ2; expand vdevs over time.
  - Budget: ~$1,200–1,800 for chassis + first drives.
- **Synology stays for** family-photos + business (mature, well-supported snapshots, easy DSM admin for non-technical wife access). **TrueNAS gets** family-media + dev + backups + larger growth. Two-tier strategy.

##### Offsite backup
- **Critical subset only** (family-photos + business): rotated external drive at a relative's house, OR Backblaze B2 (~$6/TB/month — for 5 TB of irreplaceable data, ~$30/month).
- **Don't try to offsite all 30+ TB** — most of it (Plex media) is replaceable, just inconvenient.
- **Test restores**: scheduled quarterly. A backup you've never restored from is not a backup.

#### 6.3 Automation Sensors & Actuators (Theme D)
- **Power monitoring**: Emporia Vue 2 with 8 CT clamps (~$140) — install in breaker panel.
- **Sprinklers**: Rachio 3 (smart) or OpenSprinkler (open-source, more flexible) — ~$200.
- **Lights / curtains**: pick a single ecosystem (Zigbee preferred for local-only). Aqara, IKEA Tradfri, Philips Hue (with bridge bypass).
- **Door/window sensors**: extend or replace Abode with Aqara Zigbee sensors that report to HA directly.
- **Smart locks**: Schlage Encode or Yale Assure with Z-Wave for HA integration.
- **Budget mindset**: don't bulk-buy. Add as automations are designed, not speculatively.

#### 6.4 Camera System Upgrade (Themes B + D)

##### Where existing cameras stand on fortress mode
- **Nest**: cloud-dependent. Loses recording AND live view when internet is down. Worst fortress-mode citizen.
- **Eufy + Homebase**: records locally to Homebase storage; LAN viewing works without internet. Remote viewing and event notifications need cloud. **Eufy is partially fortress-compliant** — keep these where wiring new cams is impractical.
- **Abode (security system, not cameras)**: keep as-is. Different category.

##### Decision: Frigate vs. UniFi Protect vs. Scrypted hybrid
This is the real fork. Each has tradeoffs.

| Approach | Cameras | UI quality (vs Nest) | Fortress mode | Lock-in | Cost |
|---|---|---|---|---|---|
| **Frigate** (with HA) | Any RTSP/ONVIF (Reolink, Amcrest, Dahua) | Web UI OK, not Nest-quality | Full local | Low — ONVIF is standard | $80–120/cam + GPU |
| **Frigate + Scrypted bridge** | Same as Frigate | **Native phone apps via HomeKit / Google Home — Nest-like** | Full local | Low | + ~$0 (Scrypted on Mini-PC) |
| **UniFi Protect** | UniFi cams only | **Excellent — Protect app is Nest-tier** | Full local | High — UniFi cams only | $130–250/cam + UniFi NVR |
| **Keep Nest** | Nest | Best UI, weakest fortress | None | Total cloud lock-in | Subscription |

**Recommendation**: **Frigate + Scrypted hybrid**.
- Frigate handles AI detection, NVR recording, automation events.
- **Scrypted** (runs on the HA node or AI node) bridges cameras to HomeKit / Google Home / native phone apps for the polished playback UX you like about Nest. Free, open source. This was the missing piece in my prior recommendation.
- You're not locked into a vendor's cameras.

##### Camera hardware
- **Reolink RLC-810A** (4K, PoE, ONVIF, decent low-light) — $80–110/cam. Mainstream Frigate-friendly choice.
- **Amcrest IP8M-2496EB** (4K, PoE, ONVIF) — similar price, similar quality.
- **For outdoor weather/durability**: spend up to ~$150/cam for IP66/IP67 rated models.
- **Do NOT** buy WiFi-only cameras for fortress mode — PoE means power + data on one cable, no batteries to die, no WiFi to flake.

##### PoE switch + cabling reality
- **PoE switch**: needs to be in the rack. TP-Link TL-SG1218MP (16-port + 2 SFP, ~$170) is the sane choice for 4–8 cameras + future PoE APs.
- **Cabling**: yes, this is real infrastructure work. You need **CAT6 or CAT6A runs from the rack to each camera location**. This is the painful part.
- **Mitigation**: when running cables, run them for **multiple purposes at once** — camera + AP backhaul + future use. One trip into the attic, not three. See section 6.7 (Structured Cabling) below.
- **Phasing**: don't try to rip out all Nest/Eufy at once. Add 2–3 strategic Frigate cams (front door, driveway, backyard), keep existing Nest/Eufy where wiring is impractical. Convert gradually.

##### Storage for camera recordings
- **NEVER** put camera recordings on the NAS media pool — 24/7 write amplification destroys HDDs designed for read-mostly workloads.
- **Dedicated drive**: 4–8 TB NAS-rated drive (WD Purple is purpose-built for surveillance — handles 24/7 writes), installed in the AI / Frigate node.
- Plan storage by: (number of cams) × (bitrate) × (retention days) — a Frigate calculator helps.

#### 6.5 Tenant Isolation Hardware (Theme C)
- **VLAN-capable switch**: Mikrotik CRS112-8P-4S, Unifi Switch Lite 8 PoE, or similar ~$130.
- **VLAN-capable AP/router**: when eero mesh hits end of life, replace with Unifi or OPNsense + Unifi APs for real VLAN support.
- **Why now**: needed before kids' devices + wife's biz + dev environments share the network at scale.

#### 6.6 (Optional) Redundant Internet
- 5G failover modem (Cradlepoint, Peplink, or Mikrotik with Quectel modem) — $200–400 plus a T-Mobile/Verizon Home Internet plan as backup.
- See [`docs/architecture/ISP-ASSESSMENT.md`](../architecture/ISP-ASSESSMENT.md) for the analysis triggering this.

#### 6.7 Structured Cabling & AV Distribution
The underrated infrastructure choice that *enables* almost everything else in Phase 6. Cables are cheap during a single dedicated run; expensive when running one cable at a time over months.

##### What needs cabling
| Purpose | From | To | Cable |
|---|---|---|---|
| PoE cameras | Rack | Each camera location | CAT6 or CAT6A |
| PoE AP backhaul | Rack | Each AP location (ceiling, attic) | CAT6 or CAT6A |
| Wired desktops/devices | Rack | Office, family room TV, etc. | CAT6 |
| PS5 / consoles | Rack-adjacent | PS5 location | CAT6 (wired ethernet beats WiFi every time) |
| TV HDMI (optional) | Rack-adjacent | Each TV | HDMI or HDBaseT-over-CAT6 |

##### Strategy: do it once, do it right
- **CAT6A everywhere** (not CAT5e). Cost difference is minimal during a fresh run; supports 10 GbE for the next 15 years.
- **Run extras**: pull 2 cables to each location even if you only need 1 today. Pulling a second cable later costs 10x the original run.
- **Terminate at a rack-mounted patch panel** (24-port or 48-port, ~$60). All runs land on the patch panel; switch ports connect via short patch cables. Standard practice, easy to troubleshoot.
- **Hire it out** for the actual cable pulling unless you enjoy crawling through attics. Reasonable cost; very different result from DIY.

##### PS5 + PS Portal + multi-TV setup (your specific ask)
Three problems to solve, three different approaches:

**1. PS5 itself — wired, near the rack**
- PS5 connects to the rack via CAT6. Done. Wired = best latency for online play.
- Where to put it: depends on whether you'll *also* use it locally for couch gaming. If yes, put it near the TV you use most. If no (purely a streaming source for PS Portal + remote TVs), put it in the rack room.

**2. PS Portal — lag-free WiFi**
- PS Portal is **WiFi-only** (no ethernet option). Lag comes from weak WiFi between Portal and AP.
- Solution: high-quality APs with **wired backhaul** placed strategically (one near where you sit, ideally <30 ft away with line-of-sight).
- **Hardware**: when eero mesh gets retired (Theme C trigger), replace with Unifi U6/U7 APs (PoE-powered, wired backhaul). 2–4 APs covers most homes.
- **Don't** rely on eero's wireless backhaul for PS Portal — wireless mesh backhaul adds latency. Wired backhaul to each AP is non-negotiable for low-lag streaming.

**3. Play PS5 on any TV — HDMI distribution**
Two paths, very different price points:

- **Path A — PS Remote Play on each TV** (cheap, slight lag): Apple TV / Google Chromecast / Fire TV on each TV running PS Remote Play. Same WiFi-quality-dependent latency as PS Portal. ~$50/TV.
- **Path B — Real HDMI matrix / HDBaseT** (zero lag, expensive): HDMI switch + HDBaseT extenders run HDMI signal over CAT6 to each TV. **Zero added latency**, identical to TV being directly connected.
  - **HDMI matrix**: Monoprice Blackbird 4x4 HDBaseT (~$1,200) or similar. Inputs: PS5, Apple TV, etc. Outputs: TV 1, TV 2, TV 3, TV 4.
  - **HDBaseT receivers**: one per TV (~$80 each).
  - Each TV gets one CAT6 run from the rack — same cable infrastructure as everything else.
  - **Total**: ~$1,500 for a 4-TV setup. Real money, but truly zero-lag any-game-on-any-TV.

**Recommendation**: start with **Path A** (cheap, PS Remote Play on Apple TVs) and only upgrade to **Path B** if Remote Play latency annoys you for specific games (twitch shooters, fighting games). Most casual gaming is fine on Remote Play.

##### Budget for cabling subproject
- **Structured cabling install** (8–12 drops): $800–2,000 if hired, $300 DIY (materials only).
- **Patch panel + keystone jacks**: $80–120.
- **PoE switch** (already in 6.4): $170.
- **APs** (4× Unifi U7 Pro): $720 + ~$100 PoE injectors if switch isn't PoE+.
- **HDMI distribution** (Path A): $50/TV.
- **HDMI distribution** (Path B): $1,500 for matrix + 4 receivers.

##### Why this matters for fortress mode
- Wired beats WiFi for *anything* you care about working reliably. Cameras, PS Portal AP backhaul, consoles, work-from-home laptops on docks — all should be wired.
- A wired backbone makes the wireless layer's job easier — fewer devices fighting for WiFi airtime.

---

## 💰 Rough Budget Summary

| Phase | Item | Range |
|---|---|---|
| 2 | 8 TB NAS-rated drive (internal SATA) | $170–200 |
| 3.1 | DNS Pi 4 2GB + accessories | $95–110 |
| 4 | UPS (1500VA, rack or tower) | $300–450 |
| 4 | Server rack (12–15U enclosed) + accessories | $250–400 |
| **Phase 2–4 total (near-term)** | | **~$815–1,160** |
| 3.2 | HA node (mini-PC) — deferred to Theme D start | $150–250 |
| 5 | (Optional) dev mini-PC | $300–500 |
| 6.1 | AI node — Path A (used 3090 PC build) | $1,200–1,500 |
| 6.1 | AI node — Path B (Mac Mini M4 Pro 64GB) | $2,000 |
| 6.1 | AI node — Path C (Mac Mini + Frigate mini-PC) | $2,400–2,500 |
| 6.2 | NAS expansion stage 1 (2× 8TB) | $340–400 |
| 6.2 | TrueNAS build stage 2 | $1,200–1,800 |
| 6.3 | Automation sensors (initial wave) | $200–400 |
| 6.4 | Camera system (3–4 PoE cams + dedicated WD Purple drive) | $500–800 |
| 6.5 | VLAN-capable switch + AP refresh (4× U7) | $1,000–1,400 |
| 6.6 | Redundant internet (optional) | $200–400 + monthly |
| 6.7 | Structured cabling install (8–12 drops) | $800–2,000 |
| 6.7 | HDMI distribution Path A (Remote Play) | $200 (4 TVs) |
| 6.7 | HDMI distribution Path B (HDBaseT matrix) | $1,500 (4 TVs) |

**Phase 6 spend is multi-year and gated on actual workloads materializing.** Don't pre-buy.

---

## 🚫 What We Are Explicitly NOT Buying

- **Consumer router upgrades for "performance"** — current eero mesh is fine for speed. Replacement decision is driven by VLAN/tenant-isolation needs (Theme C), not throughput.
- **More cloud storage subscriptions** — direction of travel is the opposite (Theme A).
- **A second Plex server for "redundancy"** — Plex isn't the SPOF that matters; DNS and storage are.
- **Fancy "AI-ready" appliances** — building from used GPU + commodity parts is dramatically more capable and cheaper.
- **Kubernetes-managed everything** — Plex/STARR/AdGuard stay on Docker on the host where they work.
- **A separate "Home Assistant box"** if Phase 3 Pi is spec'd correctly — Pi 4 4GB handles both DNS and HA comfortably.
- **10" mini-racks (DeskPi RackMate etc.)** — looks cute, locks out all standard 19" gear. Wrong tool for a multi-node lab.
- **Loud enterprise 1U "pizza box" servers** — 40mm screamer fans don't belong in a residential closet. Stick with tower-form or quiet mini-PCs even when rack-mounted on shelves.
- **Dedicated rack KVM hardware** — SSH + Tailscale + IPMI on capable boards cover all the same use cases without dedicated hardware.

---

## 🔄 When To Update This Doc

- After any purchase (record what was actually bought + serial/model in current inventory).
- When a Phase 6 theme starts moving to Phase 5 status (workload is real, time to spec).
- When a recommended item becomes unavailable or superseded.
- Quarterly review: is the sequence still right given what we've learned?
