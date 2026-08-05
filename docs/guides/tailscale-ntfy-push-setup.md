# Tailscale + ntfy push notifications — setup and the two gotchas that broke it

Built 2026-08-05 during a real incident (failing `/dev/sda` took the STARR stack down, needed a full server restart to recover). Setting up Tailscale + ntfy push so future incidents actually page a phone, not just fire silently in Prometheus, took two non-obvious fixes after the pipeline *looked* fully correct at every layer.

## The setup

1. **Tailscale on the server and phone**, same tailnet: `curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up` on the server, the Tailscale app + same account login on the phone.
2. **ntfy subscription uses the server's Tailscale IP** (`tailscale ip -4`), not its LAN IP — this is what makes the subscription work both at home and away, since Tailscale meshes locally too.
3. **Alertmanager → ntfy** via a generic `webhook_configs` receiver (see `docker/alertmanager/alertmanager.yml`) — this part is unrelated to the two gotchas below and was already working before this incident.

## Gotcha 1 — Tailscale silently hijacks the host's DNS

`tailscale up` by default takes over the system resolver (`/etc/resolv.conf`) to support MagicDNS. On this box, that meant the host — and any Docker container without its own explicit DNS override — stopped using AdGuard and started forwarding through Tailscale's internal DNS proxy (`100.100.100.100`) instead. That proxy returned `SERVFAIL` for ordinary external lookups (e.g. `ntfy.sh`), breaking anything relying on default DNS forwarding, even though AdGuard itself was completely healthy the whole time.

**Fix:**
```bash
sudo tailscale set --accept-dns=false
```
Keeps full Tailscale connectivity, just stops it from overriding the system resolver. **Any new device added to the tailnet (Theme E: "every family device") needs this same flag**, or it'll silently repeat this exact failure.

One more trap this caused: Docker snapshots a container's DNS config into its own `/etc/resolv.conf` **at creation time** — it does not dynamically follow host changes. A container created while DNS was hijacked keeps using the broken config even after the host is fixed, until that specific container is restarted.

## Gotcha 2 — `NTFY_BASE_URL` must exactly match the address the app uses to reach the server

Per ntfy's own docs: the self-hosted server's `base-url` and the "Default Server" the app is actually configured to talk to **must match exactly**. The server embeds its own `base-url` in the poll request it sends upstream — that's the address the app is told to fetch the real message from once Apple's silent push wakes it up. If they don't match, the whole chain looks correct (no errors anywhere, in Alertmanager, in ntfy's logs, or on the topic itself) but nothing ever reaches the lock screen, because the app is being told to fetch from an address it can't currently reach.

In this case: `NTFY_BASE_URL` was still the LAN IP (`http://192.168.1.11:8095`) while the phone's subscription used the Tailscale IP (`http://100.100.168.37:8095`). Fixed by setting `NTFY_BASE_URL` to the same Tailscale IP as the subscription.

**Also required, separately, for any iOS push to work at all from a self-hosted instance:**
```
NTFY_UPSTREAM_BASE_URL=https://ntfy.sh
```
iOS can't maintain the kind of persistent background connection Android can — a self-hosted server has no path to Apple's APNs on its own, so it needs to relay the wake-up signal through `ntfy.sh` (which does), or push never arrives regardless of anything else being correct. Content stays on the self-hosted server; only a tiny poll signal (message ID) goes through `ntfy.sh`.

## Verification checklist (in order — this is the order that actually isolates the failure)

1. Does Alertmanager register the alert? `curl -s http://localhost:9093/api/v2/alerts`
2. Did the message land on the ntfy topic itself? `curl -s 'http://<host>:8095/<topic>/json?poll=1&since=5m'`
3. Any error in `docker logs ntfy` for that time window — specifically DNS/upstream relay failures?
4. **Does push work on the device at all, for anything?** Subscribe to a random topic on the public `ntfy.sh` directly (bypassing your server, Tailscale, DNS, everything) and publish to it. If that doesn't arrive either, stop debugging the self-hosted side — the problem is the device/app, not your server.
5. Only once #4 confirms push works in general: check the `NTFY_BASE_URL` vs. app-subscription-address match above.

Steps 1–3 all looking clean is **not** sufficient evidence the pipeline works — this incident got a fully "clean" reading at every one of those layers seven times in a row before the actual cause (step 5) was found.
