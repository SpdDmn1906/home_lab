# SSH Key Setup for Homelab Scripts

Replaces password-based SSH (`sshpass`) for scripts that reach the media server. Done 2026-08-01 after a plaintext SSH password was found committed in git history and rotated.

## Why
`sshpass -p "<password>"` requires the password to exist as literal text somewhere — a script, an env var default, a doc example — and literal text gets copy-pasted, committed, and leaked. An SSH key removes the password from the picture entirely: the private key never needs to appear as a string anywhere, and it's revocable independently of any account password.

## Setup

1. Generate a dedicated key (separate from any general-purpose key, so it can be revoked on its own):
   ```bash
   ssh-keygen -t ed25519 -C "homelab-scripts" -f ~/.ssh/id_ed25519_homelab -N ""
   ```
   No passphrase — this key is meant for non-interactive script use. The private key file's `600` permissions are the protection; never let this file leave the local machine (never commit it, never paste it).

2. Install the public key on the server (prompts for the account password once):
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519_homelab.pub <user>@192.168.1.11
   ```

3. Add a host alias in `~/.ssh/config` (`chmod 600` this file) so both the alias and the raw IP resolve to the key — scripts that hardcode the IP pick it up automatically, no code change needed:
   ```
   Host mediaserver 192.168.1.11
       HostName 192.168.1.11
       User <user>
       IdentityFile ~/.ssh/id_ed25519_homelab
       IdentitiesOnly yes
   ```

4. Verify: `ssh mediaserver` should drop into a shell with no password prompt.

## Scripts using this pattern
`scripts/check_scan_progress.sh`, `scripts/radarr_quick_refresh.sh` — both call `ssh mediaserver '...'` directly, no credentials in the script at all.

## Optional next hardening step
Once key-based login is confirmed working for everything that needs it, disable password authentication entirely on the server (`/etc/ssh/sshd_config`: `PasswordAuthentication no`, then `sudo systemctl reload sshd`) so a leaked account password can no longer grant SSH access on its own. Sequence this only after confirming key login works — test in a second session before closing the first, same rule as any SSH auth change.
