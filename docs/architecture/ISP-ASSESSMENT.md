# ISP Assessment: Plans Meeting or Exceeding Current Performance

**Date:** 2026  
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

## Recommendation Summary

| Goal | Suggestion |
|------|------------|
| **Stay at current performance** | Xfinity 2 Gig already meets the bar; no change needed. |
| **Best upgrade path** | If fiber (Google, AT&T, Frontier, Verizon, Quantum) is available: 1 Gbps symmetric or 2 Gbps symmetric gives better upload than 2 Gbps cable and is often similar or better value. |
| **If you move or switch** | Choose a plan with **≥1 Gbps down** and **≥200 Mbps up** (or symmetric) to match or exceed current. Avoid plans with &lt;35 Mbps upload if you keep current Plex remote usage. |
| **When comparing** | Check: upload speed, data cap, modem/ONT (2.5G port for future-proofing), and contract/price lock. |

---

## Quick Reference: Current vs “Minimum” vs “Ideal”

| | Your current | Minimum (no regression) | Ideal (future-proof) |
|--|----------------|--------------------------|------------------------|
| **Download** | 2,000 Mbps | 1,000 Mbps | 2,000+ Mbps |
| **Upload** | 200 Mbps | 35 Mbps | 200 Mbps or symmetric |
| **Tech** | Cable (HFC) | Any | Fiber (symmetric) |

Availability for fiber and multi-gig varies by address. Use each provider’s address checker for exact plans and pricing at your location.
