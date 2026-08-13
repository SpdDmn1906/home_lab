# Untrusted Device Isolation

**Purpose:** a repeatable pattern for putting a device you do **not** administer onto the home network without giving it visibility into everything else.

**Applies to:** employer-managed laptops, contractor or client hardware, loaner/RMA equipment, IoT and smart-home gear with opaque firmware, anything running a management agent whose policy you cannot inspect.

> **Design rule:** isolate, never interfere. The goal is that the device works exactly as its owner expects while seeing nothing but the internet.

---

## 1. Threat model — be precise, or you will over-build

Managed endpoints are usually chatty rather than predatory. Sizing the response to the actual risk keeps this a 15-minute job instead of a hardware project.

| Risk | Real? | Notes |
|---|---|---|
| **LAN enumeration / inventory** | ✅ **Yes — this is the actual exposure** | mDNS/Bonjour, SSDP, and ARP make hostnames, IPs, and open services discoverable by default. Descriptive device names are the leak |
| **Reading other devices' traffic** | ❌ Effectively no | A switched network is not a hub. Capturing a neighbour's traffic requires ARP spoofing; management agents do not do this |
| **Seeing the WAN/public IP** | ✅ Yes — **and isolation does not change this** | Same egress regardless of segment. Approximate geolocation is visible either way |
| **Seeing activity on the device itself** | ✅ Yes — **isolation does not change this** | Everything done *on* the device is in scope for its owner. **Behavioural separation matters more than any network control: keep personal activity off it entirely** |

**Conclusion:** isolation solves enumeration. It does not solve egress attribution or on-device visibility, and no network design will.

---

## 2. 🔴 What not to do

**Do not block the device's management, telemetry, or update endpoints** — not at the firewall, not in the DNS resolver, not with blocklists.

Two independent reasons:

1. **It breaks the device.** Collaboration suites, MDM check-ins, and endpoint-security agents fail in ways that surface as support tickets attributable to that device.
2. **It reads as circumvention.** Segmenting your own network is ordinary defensive practice. Selectively nulling a vendor's control plane is a different act, and it is the version that carries consequences.

Isolation is the better tool precisely because it is invisible: a device that cannot see your file server raises nothing, while a device whose telemetry is being interfered with raises something.

---

## 3. Isolation tiers

Pick the lowest tier that passes the verification in §4.

### Tier 1 — Guest SSID *(≈15 min, no cost)*

1. Enable the guest wireless network on the primary router.
2. **Disable "allow guests to access my local network"** (wording varies: *client isolation*, *AP isolation*, *intranet access*).
3. Join the untrusted device to that SSID only.
4. Leave DHCP/DNS at the router default — see §5.

**Limits:** consumer guest-mode isolation is frequently partial and is rarely logged per-client. **Assume nothing; run §4.**

### Tier 2 — Dedicated router on its own subnet *(≈$50–80)*

A travel router or spare AP plugged into a LAN port of the primary router, running its own DHCP scope on a different subnet.

- Creates a genuine layer-3 boundary — the untrusted device cannot even ARP the main LAN.
- Double NAT is irrelevant for outbound-only corporate workloads and VPN clients.
- Changes nothing in the production network; unplugging it fully reverts.

**Best value for a device that is only present part-time.**

### Tier 3 — VLANs *(hardware-dependent, treat as a project)*

Tagged VLANs with inter-VLAN traffic denied by default.

⚠️ **Requires VLAN-capable gear end to end** — router/firewall, managed switch, and APs that map SSID → VLAN. Typical consumer mesh and single-box routers do **not** qualify, and *"has a guest network"* is not the same capability.

**Confirm the exact router model before assuming this is a config change rather than a purchase.** Some vendor firmware exposes real VLAN-backed guest networks on newer models only.

---

## 4. Verification — the isolation is not real until it fails a reachability test

> **Absence of errors is not success.** A device that "seems fine" proves nothing. Assert the *failure* explicitly.

From a throwaway client (a phone works) joined to the **isolated** network, attempt to reach known-good hosts on the trusted LAN:

```bash
# Substitute real targets from the private notes file.
# EVERY one of these must FAIL.

ping -c 3 <trusted-host-ip>                 # expect: 100% packet loss
curl -m 5 http://<trusted-host-ip>:<port>/  # expect: timeout / no route
nc -vz -w 5 <nas-ip> 445                    # expect: refused or timed out

# Discovery must also come back empty:
dns-sd -B _services._dns-sd._udp local.      # macOS
avahi-browse -at                             # Linux

# And confirm the device still has working internet:
curl -sS -m 5 -o /dev/null -w '%{http_code}\n' https://example.com   # expect: 200
```

**If any LAN target answers, isolation is not in effect — escalate a tier.**

Re-run after any firmware update. Guest-mode behaviour has been known to reset silently.

---

## 5. Gotchas that defeat otherwise-correct setups

| Gotcha | Why it bites | Handling |
|---|---|---|
| **Mesh nodes in AP/bridge mode** | A mesh in bridge mode does **not** rebroadcast the primary router's guest SSID, and its own guest feature is typically disabled when it is not the router | The isolated SSID radiates from the primary router only. **Test signal from the seat where the device is actually used**, not next to the router |
| **Mesh-vendor guest network** | Requires the mesh to be the gateway; unavailable in AP mode | Use the primary router's guest network, or Tier 2 |
| **Overlay VPN subnet routes** | A mesh-VPN node advertising the LAN subnet re-exposes it to anything on the tailnet — routing straight past the segmentation | Never install the personal overlay client on the untrusted device; audit which nodes advertise subnet routes |
| **Household DNS resolver** | Pointing the device at the household resolver puts its lookups in your query log **and** risks blocklists breaking its tooling | Let the isolated segment use the router/ISP or a public resolver. Keep the untrusted device out of the household DNS path in both directions |
| **Wired fallback** | Plugging into any LAN port bypasses the wireless isolation entirely | Wireless-only for the device, or dedicate a physically separate port/segment |
| **Descriptive hostnames** | The main thing enumeration actually harvests | Avoid names describing function, owner, or contents on the trusted LAN |
| **Port-forwarded services** | Reachable from the isolated segment *via the WAN address* even when the LAN path is blocked | Expect this; it is not an isolation failure, but do not treat a forwarded port as private |

---

## 6. Recording the specifics

Device-specific detail — MAC addresses, assigned IPs, SSID names, agent behaviour, observed traffic — belongs in the **gitignored** notes file, not here:

```
docs/private/untrusted-devices.md          # gitignored, real values
docs/private/untrusted-devices.example.md  # tracked, placeholders only
```

**This repository is public.** Keep this guide free of employer names, hostnames, usernames, MAC addresses, and home filesystem paths.

---

*Pattern doc — no device-specific state. See the private notes file for what is actually deployed.*
