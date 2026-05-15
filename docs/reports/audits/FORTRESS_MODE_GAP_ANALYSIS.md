# 🏰 Fortress Mode: Gap Analysis & Roadmap
**Date**: 2026-05-14
**Status**: ⚠️ TENT MODE DETECTED (High Vulnerability)

## 🎯 Executive Summary
The "Fortress Mode" architecture is logically sound but physically incomplete. While documentation suggests a resilient, local-first infrastructure, the underlying automation is missing, and hardware/software aging presents a significant risk of failure during the impending ISP disruption.

---

## 🚩 Critical Gaps ("The Tent Poles")

### 1. Automation Breakdown (Ansible "Ghost" Playbooks)
- **Finding**: `infrastructure-setup.yml` is an empty shell. It references 9+ task files (e.g., `tasks/network-config.yml`, `tasks/system-hardening.yml`) that do not exist in the repository.
- **Risk**: You cannot "deploy" or "rebuild" your fortress. If a config drifts during the outage, your management tools are useless.
- **Remediation**: Reconstruct the task files or consolidate logic into the main playbook.

### 2. Managed User Authentication (The PIN Barrier)
- **Finding**: Plex Managed Users require `plex.tv` for initial PIN validation and profile data. 
- **Risk**: Even with local networks allowed, your family will likely be locked out of their specific watch histories and "Continue Watching" lists. They may only be able to access the "Admin" account if it’s already logged in.
- **Mitigation**: Deploy the `plex-fortress-guard.sh` to trick the server into aggressive local caching.

### 3. DNS Failure State
- **Finding**: No local DNS record verification.
- **Risk**: Clients like Smart TVs or Mobile Apps often have hardcoded DNS or rely on the router. If the router loses WAN, it often stops responding to DNS queries entirely.
- **Remediation**: Force a local DNS override (AdGuard Home) or use IP-based access strictly.

---

## 🛠️ Remediation Roadmap

### Phase 0: Pre-Outage Survival (Next 45 Mins)
- [ ] **Manual Verification**: Run `curl http://192.168.1.11:32400/identity` from a laptop. If it fails, the "Fortress" is already breached.
- [ ] **Guard Activation**: Manually start the Fortress Guard script.
- [ ] **Account Prep**: Switch all critical devices to the Admin profile *now*.

### Phase 1: Ansible Reconstruction (Post-Outage)
- [ ] **Locate Missing Logic**: Determine if the `tasks/*.yml` files were lost in a previous migration or if they need to be written from scratch.
- [ ] **Role Cleanup**: Remove empty roles (`network-migration`, `monitoring-setup`) and replace with functional tasks.

### Phase 2: System Hardening
- [ ] **Ubuntu 24.04 Migration**: Replace the EOL 18.04 OS to support modern Docker and network features.
- [ ] **Storage Offloading**: Move STARR downloads to the external drive to prevent NAS paralysis.

---

## 📊 Reliability Scorecard

| Category | Score | Notes |
| :--- | :--- | :--- |
| **Plex Local Auth** | 7/10 | Subnet updated, but managed users are still at risk. |
| **Network Unification** | 9/10 | Architecture is solid, latency on Eero is the only major flaw. |
| **Automation** | 1/10 | Playbooks are currently non-functional (missing tasks). |
| **Storage Health** | 0/10 | CRITICAL BLOCKER. System is at high risk of I/O lockup. |
| **Hardware** | 4/10 | CPU aging; transcoding will kill the server. |

---

## 🔒 The "Plex Guard" Explained
The `plex-fortress-guard.sh` is your "Protocol 0". 
1. **Monitors**: It pings `plex.tv`.
2. **Action**: If `plex.tv` is unreachable or returns error codes, it uses `iptables` to **DROP** all traffic to Plex's authentication servers.
3. **Outcome**: Plex (the server) thinks the network is just "slow/timed out" rather than "disconnected." It will hold onto its cached authentication tokens for Managed Users much longer (up to weeks) instead of clearing the cache and forcing a login that will fail.
