# ISP Assessment: Plans Meeting or Exceeding Current Performance

**Date:** 2026 · **Revised 2026-08-12** (fiber build started on the block; added the CGNAT/passthrough gates and a provider verdict)  
**Status:** 🎯 **Decision made — target AT&T Fiber, reject T-Mobile Fiber.** See [Recommendation Summary](#recommendation-summary-revised-2026-08-12).  
**Baseline:** Your current service (minimum requirement for any alternative)  
**Context:** Home lab with Plex (local 4K, remote 1080p), STARR stack, ~30 devices, Eero mesh, future 2.5G/10G (ASUS XG-C100C). See [network-setup.md](network-setup.md), [PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md](../troubleshooting/PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md).

---

## Your Current Performance (Minimum Bar)

| Item | Value |
|------|--------|
| **Provider** | Comcast Xfinity |
| **Plan** | 2 Gig Internet |
| **Download** | Up to **2,000 Mbps** (2 Gbps) |
| **Upload** | Up to **~200 Mbps** |
| **Technology** | Hybrid Fiber-Coax (HFC); last mile is coaxial |
| **Modem** | Xfinity Xfi (bridge mode) |
| **Data cap** | Unlimited on this tier (no overage) |
| **Typical use** | Plex remote capped at ~35 Mbps design; STARR downloads; multiple streams |

**Why upload matters for you:** Remote Plex (3–4× 1080p streams), seeding on private trackers, backups, and any future multi-gig upload (e.g., 2.5G LAN to internet). Your current **200 Mbps upload** is well above the ~35–40 Mbps we designed Plex around.

**Minimum requirement for this assessment:** Any alternative must offer **at least**:
- **Download:** 1,000 Mbps (1 Gbps) — acceptable; 2,000 Mbps preferred to match current.
- **Upload:** 200 Mbps preferred; **no less than 35 Mbps** for your current Plex/STARR design.

---

## 🔴 The Two Criteria That Actually Decide This (added 2026-08-12)

Speed tiers are the easy part and were the original focus of this doc. They are **not** what disqualifies an ISP for this lab. Two architectural criteria outrank raw Mbps:

### 1. Public IPv4 vs CGNAT — the hard gate

If the ISP puts you behind **carrier-grade NAT**, you have no routable inbound address and port forwarding silently stops meaning anything. What breaks here:

| Service | Impact under CGNAT |
|---|---|
| **Plex remote access** | 🔴 **Breaks.** The 32400 forward documented in [network-setup.md](network-setup.md) becomes inert. Plex falls back to **Relay, ~1–2 Mbps** — versus the 3–4 concurrent 1080p @ 10 Mbps design in [PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md](../troubleshooting/PLEX_4K_AND_FORTRESS_MODE_STRATEGY.md). |
| **Tailscale** | ⚠️ **Degrades.** Traverses CGNAT, but CGNAT-on-both-ends often fails direct connection and falls back to DERP relay — added latency, throttled throughput. Matters for `infra-mcp` (Phase 5c), which reaches every service over the tailnet. |
| **STARR / qBittorrent** | ✅ **Insulated.** Inbound rides the PIA port forward through the VPN gateway container, not the home WAN IP. |
| **Tailscale Funnel / Cloudflare Tunnel** | ✅ **Unaffected.** Outbound-initiated by design — this is why Theme E already specifies tunnels over port forwards. |

**Verification question to ask any ISP before signing:** *"Does residential service assign a public IPv4, or am I behind CGNAT — and what does a static/public IP cost?"* Do not accept a salesperson's "you can port forward" — ask for the CGNAT answer specifically.

### 2. Bridge / IP-passthrough support

The LAN design is **Xfinity modem in bridge → Asus RAX50 is the single router, DHCP, DNS, and firewall**, with double-NAT deliberately eliminated. Any ISP gateway that cannot bridge or pass the WAN IP through re-introduces double NAT and breaks that design.

- **AT&T** — BGW320-505 supports **IP Passthrough** (`Firewall > IP Passthrough > Allocation Mode: Passthrough`, `Mode: DHCPS-fixed`, select the Asus's MAC). Not a true bridge, but it hands the public IP to the Asus, which is what matters.
- **T-Mobile** — gateways are widely reported to have **no bridge/passthrough mode**. ⚠️ Sourcing is on the 5G gateway, not the fiber ONT — treat as unverified and confirm with the installer.

---

## 📊 Verdicts by Provider (2026-08-12)

| Provider | Public IPv4 | Bridge/passthrough | Symmetric | Verdict |
|---|---|---|---|---|
| **AT&T Fiber** | ✅ Default, no CGNAT | ✅ IP Passthrough | ✅ | ✅ **Target.** Meets both gates. |
| **Xfinity** (current) | ✅ | ✅ Bridge mode | ❌ (2000/200) | ✅ Works; overpaying for unusable download. |
| **T-Mobile Fiber** | ❌ **CGNAT default**, public IP is a **+$10/mo** add-on | ⚠️ Unverified, likely none | ✅ | ❌ **Rejected** on the CGNAT gate. |
| **5G Home Internet** (any carrier) | ❌ CGNAT | ❌ | ❌ | ❌ Failover only, never primary. |

---

## ⚠️ The Download Tier You Cannot Use

Line 76 of this doc already noted it; stating it plainly because it drives the buying decision:

**The Asus RAX50's 1G ports cap real WAN throughput at ~940 Mbps.** Any tier above 1 Gbps is unusable until the router is replaced. A 2 Gbps plan delivers exactly the same real-world throughput as a 1 Gbps plan on this hardware.

Consequence: **do not buy above 1 Gbps.** A 500/500 or 1000/1000 symmetric fiber tier is a strict upgrade over 2000/200 cable on this LAN — identical usable download, 2.5–5× the upload.

---

## Assessment: ISPs and Plans That Meet or Exceed

### Tier 1: Match or Beat 2 Gbps Down / 200 Mbps Up

| Provider | Plan | Download | Upload | Tech | Notes |
|----------|------|----------|--------|------|--------|
| **Comcast Xfinity** (current) | 2 Gig | 2,000 Mbps | ~200 Mbps | Cable (HFC) | No change; baseline. |
| **Google Fiber** | 2 Gig | 2,000 Mbps | **2,000 Mbps** (symmetric) | Fiber | ~$100/mo; **limited cities**. |
| **AT&T Fiber** | 2 Gbps / 5 Gbps | 2,000–5,000 Mbps | **Symmetric** | Fiber | Broader than Google; 2 Gbps+ tiers; incentives possible. |
| **Frontier Fiber** | Multi-gig | Up to 2,000+ Mbps | **Symmetric** | Fiber | Lower starting price; regional. |
| **Verizon Fios** | 1 Gig (max commonly listed) | 300–1,000 Mbps | **Symmetric** | Fiber | No 2 Gbps in most areas; 1 Gbps symmetric still strong. |
| **Quantum Fiber** (Lumen/CenturyLink) | Multi-gig | 200–8,000 Mbps | **Symmetric** | Fiber | “Price for Life”; availability varies. |

**Summary (Tier 1):** Fiber options (Google, AT&T, Frontier, Verizon, Quantum) give **symmetric** upload (same as download), so 1 Gbps fiber = 1,000/1,000 vs your 2,000/200. For Plex + STARR + future 2.5G, **1 Gbps symmetric is often better than 2 Gbps down / 200 up** because of upload headroom.

---

### Tier 2: At Least 1 Gbps Down / 35+ Mbps Up (Minimum Viable)

These meet your **minimum viable** requirement (fast downloads, enough upload for current Plex/STARR design):

| Provider | Plan | Download | Upload | Meets minimum? |
|----------|------|----------|--------|----------------|
| **Spectrum** | Internet GIG | 1,000 Mbps | 35 Mbps | Yes (upload at the line we designed for). |
| **Cox** | Gigablast (or equivalent 1 Gig) | 1,000 Mbps | Typically 35–50 Mbps | Yes, if upload ≥35 Mbps. |
| **Verizon Fios** | 500 Mbps / 1 Gig | 500–1,000 Mbps | **Symmetric** | Yes; fiber symmetric is a big plus. |
| **AT&T Fiber** | 300–500 Mbps | 300–500 Mbps | **Symmetric** | Yes; upload much higher than cable. |
| **Frontier Fiber** | 200+ Mbps | 200+ Mbps | **Symmetric** | Yes; check local max speed. |

**Cable caveat:** Spectrum and Cox 1 Gig often cap upload at **35 Mbps**. That matches what we set for Plex remote and STARR, but leaves little room for multiple heavy uploads (e.g., several 1080p streams + seeding). Prefer fiber at similar price where available.

---

### Tier 3: Future / Niche

- **Xfinity X-Class (DOCSIS 4.0):** Symmetric up to 2 Gbps; limited rollout (new builds, select areas).
- **Starlink / 5G Home:** Can hit 100–200+ Mbps; latency and reliability differ from fiber/cable; consider only if no good wired option.
- **Regional fiber (municipal, co-ops, local ISPs):** Often symmetric gig or multi-gig; check local availability.

---

## How This Ties to What We’ve Done

- **Network:** Single 192.168.1.0/24, Xfinity in bridge, Asus as router, Eero for mesh. Any ISP change is “swap WAN”; LAN and Plex/STARR design stay the same.
- **Plex:** Remote limited to 10 Mbps/1080p; “Internet upload speed” set to 35 Mbps. So **35 Mbps upload is the minimum** for current design; 200 Mbps gives large headroom.
- **STARR / Private trackers:** More upload improves ratio and peer performance; symmetric fiber is ideal.
- **Future 2.5G/10G:** Your ASUS XG-C100C is 10G/5G/2.5G. To use >1 Gbps to the internet, you need a plan and modem/ONT that deliver it (e.g., 2 Gig fiber or 2 Gig cable with 2.5G port). Current Xfinity 2 Gig can supply it; your Asus RAX50’s 1G ports are the current limiter, not the ISP.

---

## Recommendation Summary (revised 2026-08-12)

**Decision: target AT&T Fiber. Reject T-Mobile Fiber on the CGNAT gate.**

| Goal | Suggestion |
|------|------------|
| **Target plan** | **AT&T Fiber 500/500 or 1000/1000.** Both are a strict upgrade over 2000/200 on this LAN. Above 1 Gbps is wasted — see the RAX50 ceiling above. |
| **Reject** | **T-Mobile Fiber.** CGNAT by default breaks Plex remote access and degrades Tailscale; the public IP is a paid add-on that erases the price advantage. |
| **Do not buy** | Any tier >1 Gbps, and any router upgrade to chase multi-gig. The 1G ports are not a constraint worth spending to remove. |
| **When comparing** | In priority order: **(1) public IPv4 vs CGNAT · (2) bridge/passthrough · (3) upload speed · (4) data cap · (5) contract/price lock.** Download tier is last, not first. |

### Pre-Switch Verification Checklist

Do not cancel the incumbent until every item passes on the new circuit. Run a two-week overlap.

- [ ] Confirm **public IPv4, not CGNAT** — ask explicitly before ordering.
- [ ] Gateway in **IP Passthrough** to the Asus; confirm the Asus WAN shows the public IP, not a `192.168.x` / `100.64.x` address.
- [ ] Re-add the **32400 port forward**; Plex Settings → Remote Access reads **"Fully accessible"** (not "Relayed").
- [ ] Update Plex **"Internet upload speed"** to the new symmetric figure — currently set to 35 Mbps, which will throttle remote streams badly on fiber.
- [ ] `tailscale status` shows **`direct`**, not `relay`, from an off-LAN peer.
- [ ] AdGuard/Unbound still primary DNS; recursive resolution unaffected by the ISP change.
- [ ] Run a **fortress drill** — including the untested "does MagicDNS resolve during a WAN outage" question from the Phase 4 roadmap.
- [ ] Revisit **QoS** — the bandwidth allocations in `network-setup.md` and the Plex strategy doc are written against a ~200 Mbps upload budget and will need re-baselining.

> ⚠️ **This doc covers the technical criteria only.** Billing, bundled-service, and scheduling constraints are tracked separately and privately. Do not schedule a cutover from this doc alone.

---

## Quick Reference: Current vs “Minimum” vs “Ideal”

| | Your current | Minimum (no regression) | Ideal (future-proof) |
|--|----------------|--------------------------|------------------------|
| **Download** | 2,000 Mbps | 1,000 Mbps | 2,000+ Mbps |
| **Upload** | 200 Mbps | 35 Mbps | 200 Mbps or symmetric |
| **Tech** | Cable (HFC) | Any | Fiber (symmetric) |

Availability for fiber and multi-gig varies by address. Use each provider’s address checker for exact plans and pricing at your location.
