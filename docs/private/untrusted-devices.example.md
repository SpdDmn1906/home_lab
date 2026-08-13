# Untrusted Devices — Live Notes (TEMPLATE)

> **This `.example` file is TRACKED and must contain placeholders only.**
> The real file lives beside it as `untrusted-devices.md` and is **gitignored** —
> that is where employer names, MACs, IPs, SSIDs, and observed behaviour go.
>
> Pattern doc: [`../guides/untrusted-device-isolation.md`](../guides/untrusted-device-isolation.md)

---

## Device: <SHORT-LABEL>

| Field | Value |
|---|---|
| **Owner / administrator** | `<org or person who controls policy>` |
| **Hardware** | `<model, CPU, year>` |
| **OS + version** | `<os / build>` |
| **Arrived** | `<YYYY-MM-DD>` |
| **Present on network** | `<e.g. 2 days/week, permanent, occasional>` |
| **Isolation tier in effect** | `<1 guest SSID / 2 dedicated router / 3 VLAN>` |
| **SSID used** | `<ssid>` |
| **Assigned IP / subnet** | `<ip / cidr>` |
| **MAC** | `<mac>` |
| **DNS it resolves against** | `<resolver>` |

### Verification log
*Re-run §4 of the pattern doc after any firmware or policy change.*

| Date | Test | Expected | Result |
|---|---|---|---|
| `<YYYY-MM-DD>` | ping trusted host | fail | `<pass/fail>` |
| `<YYYY-MM-DD>` | curl trusted service port | fail | `<pass/fail>` |
| `<YYYY-MM-DD>` | mDNS browse | empty | `<pass/fail>` |
| `<YYYY-MM-DD>` | internet reachability | 200 | `<pass/fail>` |

### Management / agent behaviour observed
- `<agents present, check-in cadence, VPN or ZTNA client, disk encryption posture>`
- `<anything that changed after an update>`

### Open questions
- `<unresolved items>`

### Decisions
| Date | Decision | Why |
|---|---|---|
| `<YYYY-MM-DD>` | `<what was decided>` | `<reasoning>` |
