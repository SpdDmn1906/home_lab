# PIA Credential Rotation Runbook

Use this whenever the PIA VPN subscription is renewed, the password needs rotating (e.g. after any exposure), or the `qbittorrentvpn` tunnel has stopped authenticating. Written 2026-08-02 after a real rotation that hit two silent failure modes — both covered in Troubleshooting below.

## Before you start

- **Never paste the actual username/password into a chat, log, or screenshot.** Both are compromised the instant they're exposed, same as any other credential. Type them directly into the files below, not through an intermediary.
- `docker_container.qbittorrentvpn`'s `env` is wrapped in Terraform's `sensitive()` function (`terraform/modules/starr/main.tf`) specifically so `plan`/`apply` output never echoes the raw values — if a future edit to that file accidentally drops the `sensitive()` wrapper, re-add it before running anything, not after.
- **PIA requires the password to contain lowercase, uppercase, AND numbers.** A pure-hex or pure-symbol generator gets silently rejected — the WireGuard interface still comes up and looks fine, but the handshake with PIA's server never completes. This is the single most likely way this runbook goes sideways; see Troubleshooting.

## Steps

1. **Generate a new password** (on the server, or wherever you'll immediately copy it from — don't route it through any intermediary):
   ```bash
   tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24
   ```
   This guarantees a mix of upper/lower/numeric with zero special characters — sidesteps both the complexity requirement and any risk of an unescaped `/`, `+`, or `=` breaking PIA's auth call.

2. **Update the credential files directly on the server** (these are load-bearing for the live container — `terraform/modules/starr/main.tf` reads them via `file()` at container-creation time):
   ```bash
   nano /home/spddmn1906/Docker/config/data_gluetun/config/pia_user.txt
   nano /home/spddmn1906/Docker/config/data_gluetun/config/pia_pass.txt
   ```
   One value per file, no trailing content beyond the credential itself.

3. **Plan with a scoped target — never a bare `terraform plan`.** This repo's Terraform state also tracks a `docker_services` module (Grafana/Prometheus) that will try to create containers whose names collide with the real, separately-managed monitoring stack. Always scope to the STARR module:
   ```bash
   cd ~/home_lab/terraform
   terraform plan -target='module.starr[0]'
   ```

4. **Review the plan before applying.** Expect:
   - `env = (sensitive value) # forces replacement` on `qbittorrentvpn` — no raw credential text.
   - **All six** STARR containers (`qbittorrentvpn`, `radarr`, `sonarr`, `prowlarr`, `flaresolverr`, `bazarr`) showing `-/+ destroy and then create replacement` — not just qbittorrentvpn. This is expected: the other five have `network_mode` recorded against a container *ID* rather than the name `qbittorrentvpn`, which forces their replacement too, independent of the credential change.
   - Volumes recreated with **identical** host/container paths (nothing lost, just recreated).
   - Plan summary: `6 to add, 0 to change, 6 to destroy`. If you see `docker_services` or the `media` network in the plan, stop — you ran an unscoped plan by mistake.

5. **Apply:**
   ```bash
   terraform apply -target='module.starr[0]'
   ```
   If one of the five dependent containers errors trying to attach to `qbittorrentvpn` before it exists (no explicit Terraform dependency edge between them, since `network_mode` is a plain string, not a resource reference), just re-run the same apply command. Terraform is idempotent — a second pass finishes whatever didn't complete.

6. **Verify — don't trust "Apply complete" alone.** A container can be `Up` in Docker with a fully unauthenticated tunnel underneath it.
   ```bash
   docker exec qbittorrentvpn wg show
   ```
   Look for a `latest handshake:` line to exist at all, and `received` to show a real, growing byte count. `transfer: 0 B received` with no handshake line is a hard failure regardless of what the interface state says.

   Then confirm real traffic is actually routing through the tunnel:
   ```bash
   docker exec qbittorrentvpn curl -sS --max-time 8 https://ifconfig.me
   ```
   Should return a PIA exit IP, not your home IP. `curl: (28) Resolving timed out` here is a symptom of the handshake failure above, not a separate DNS problem — don't chase DNS config if `wg show` already shows 0 bytes received.

   Finally, confirm the whole stack settled:
   ```bash
   docker ps --format '{{.Names}}\t{{.Status}}' | grep -iE 'qbit|radarr|sonarr|prowlarr|flaresolverr|bazarr'
   ```

## Troubleshooting

**`wg show` shows the interface up but `0 B received`, no `latest handshake` line:**
The WireGuard interface coming up locally proves nothing about whether PIA's server ever accepted the key registration — that registration happens via PIA's API using your username/password *before* the tunnel exists. The two most likely causes, in order:
1. **Password complexity** — regenerate with `tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24` (see above) and re-apply.
2. **Special characters in the password broke the container's internal auth call** — same fix as above; the alphanumeric-only generator sidesteps this too.

**`docker logs qbittorrentvpn` doesn't show an obvious error:**
This image logs mostly repetitive DEBG noise and doesn't clearly surface PIA auth failures with an obvious keyword. Don't rely on `grep`-ing for "error"/"fail" — go straight to `wg show` for the ground-truth signal instead.

**A `terraform plan` or `apply` shows the raw credential in plaintext:**
Stop immediately, treat both values as compromised, and start this runbook over from step 1 with fresh credentials. Then check `terraform/modules/starr/main.tf` — the `VPN_USER`/`VPN_PASS` lines should be wrapped in `sensitive(...)`; if that wrapper is missing, someone reverted it.

## Related
- `terraform/modules/starr/main.tf` / `variables.tf` — the actual resource and `gluetun_config_path` variable.
- `terraform/terraform.tfvars` (gitignored, real values) and `.example` (tracked, placeholders) — both carry this same password-complexity note near the `starr` block.
- `docs/guides/ssh-key-setup.md` — same "never paste credentials, verify with ground truth not assumptions" discipline applied to SSH instead of PIA.
