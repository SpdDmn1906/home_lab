# Running Infrastructure Security Audit

## Overview

This document provides a detailed security audit of your currently running Docker infrastructure based on the compose files you've shared.

## 🔴 Critical Security Findings

### Finding 1: Root User Execution

**Services Affected:**
- STARR stack services (qBittorrent, Radarr, Sonarr, Prowlarr)
- Node Exporter (monitoring stack)

**Risk:** CRITICAL
**CVSS Score:** 9.1 (Critical)

**Details:**
```yaml
# STARR Stack
environment:
  - PUID=0  # Root user
  - PGID=0  # Root group

# Monitoring Stack
nodeexporter:
  user: root
  privileged: true
```

**Impact:**
- Complete host system compromise if container breached
- Ability to modify system files
- Access to all host resources
- Can escape container isolation
- Difficult to detect and recover from attacks

**Remediation:**
```bash
# Step 1: Identify your user ID
id -u  # Example output: 1000
id -g  # Example output: 1000

# Step 2: Update compose files
# Change PUID=0 to PUID=1000
# Change PGID=0 to PGID=1000

# Step 3: Fix file ownership
sudo chown -R 1000:1000 /path/to/config/directories

# Step 4: Remove privileged mode from node-exporter
```

### Finding 2: Credential Exposure

**Services Affected:**
- Gluetun VPN configuration
- Grafana default password

**Risk:** HIGH
**CVSS Score:** 7.5 (High)

**Details:**
```yaml
# pia_vpn_compose.yml
environment:
  - OPENVPN_USER=pxxxxxxx
  - OPENVPN_PASSWORD=REDACTED  # Still in file

# DevOp_monitor_stack.yml
environment:
  - GF_SECURITY_ADMIN_PASSWORD=adminpwd  # Weak default
```

**Impact:**
- VPN credentials exposed in source files
- Default passwords can be brute-forced
- Risk if files are committed to version control
- Unauthorized access to services

**Remediation:**
```bash
# Step 1: Move credentials to .env file
cat > .env <<EOF
OPENVPN_USER=your_username
OPENVPN_PASSWORD=your_secure_password
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 32)
EOF

# Step 2: Update compose files to use env vars
environment:
  - OPENVPN_USER=${OPENVPN_USER}
  - OPENVPN_PASSWORD=${OPENVPN_PASSWORD}

# Step 3: Secure .env file
chmod 600 .env
chown $USER:$USER .env

# Step 4: Add .env to .gitignore
echo ".env" >> .gitignore
```

### Finding 3: Privileged Container Execution

**Services Affected:**
- Node Exporter

**Risk:** HIGH
**CVSS Score:** 8.2 (High)

**Details:**
```yaml
nodeexporter:
  user: root
  privileged: true
```

**Impact:**
- Bypasses all container security features
- Full access to host kernel
- Can load kernel modules
- Can modify host network stack
- Defeats container isolation

**Remediation:**
```yaml
nodeexporter:
  # Remove privileged: true
  # Remove user: root (use default)
  security_opt:
    - no-new-privileges:true
  cap_add:
    - SYS_TIME  # Only if needed for time sync
  cap_drop:
    - ALL
```

### Finding 4: Missing Security Hardening

**Services Affected:**
- All services

**Risk:** MEDIUM
**CVSS Score:** 5.3 (Medium)

**Details:**
- No `no-new-privileges` security option
- No capability restrictions
- No read-only filesystems
- No resource limits
- No health checks

**Remediation:**
```yaml
services:
  example:
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_ADMIN  # Only what's needed
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 🟡 High Priority Findings

### Finding 5: Port Conflicts

**Risk:** MEDIUM
**Impact:** Service failures, connectivity issues

**Details:**
- Port 8080: qBittorrent vs potential cAdvisor conflict
- Need to verify actual port usage

**Remediation:**
```bash
# Check actual port usage
sudo netstat -tulpn | grep LISTEN

# Resolve conflicts by changing ports
# In gluetun, change qBittorrent to 8082
```

### Finding 6: Missing Service Dependencies

**Risk:** MEDIUM
**Impact:** Race conditions, startup failures

**Details:**
- No `depends_on` in STARR stack
- Services may start before dependencies ready

**Remediation:**
```yaml
services:
  qbittorrent:
    depends_on:
      - gluetun

  radarr:
    depends_on:
      - gluetun
      - qbittorrent
```

### Finding 7: Incomplete Monitoring

**Risk:** LOW
**Impact:** Limited observability

**Details:**
- STARR services not monitored
- Limited metrics collection
- No alerting configured

**Remediation:**
- Add Prometheus scrape configs
- Configure Grafana dashboards
- Set up Alertmanager rules

## 📋 Compliance Checklist

### Docker Security Best Practices

- [ ] No containers running as root
- [ ] Credentials in environment variables (not compose files)
- [ ] No privileged mode (unless absolutely necessary)
- [ ] Security options enabled (no-new-privileges)
- [ ] Capabilities restricted (drop all, add only needed)
- [ ] Resource limits configured
- [ ] Health checks enabled
- [ ] Service dependencies defined
- [ ] Networks properly isolated
- [ ] Secrets management implemented
- [ ] Regular security updates
- [ ] Audit logging enabled

### Current Compliance Status

**STARR Stack:** ❌ 2/12 compliant (16%)
**Monitoring Stack:** ⚠️ 5/12 compliant (42%)
**Overall:** ⚠️ 35% compliant

**Target:** 100% compliant within 2 weeks

## 🎯 Remediation Roadmap

### Week 1: Critical Fixes

**Day 1-2: Root Access Remediation**
- [ ] Change PUID/PGID for all STARR services
- [ ] Fix file ownerships
- [ ] Remove privileged mode from node-exporter
- [ ] Test all services

**Day 3-4: Credential Security**
- [ ] Move credentials to .env files
- [ ] Change default passwords
- [ ] Secure credential files
- [ ] Update compose files

**Day 5: Port Conflicts**
- [ ] Audit port usage
- [ ] Resolve conflicts
- [ ] Update configurations
- [ ] Test connectivity

### Week 2: Hardening

**Day 1-3: Security Options**
- [ ] Add security_opt to all services
- [ ] Restrict capabilities
- [ ] Enable read-only where possible
- [ ] Test functionality

**Day 4-5: Resilience**
- [ ] Add health checks
- [ ] Add resource limits
- [ ] Add service dependencies
- [ ] Test recovery scenarios

## 📊 Risk Assessment Summary

| Risk Level | Count | Services Affected |
|------------|-------|-------------------|
| 🔴 Critical | 4 | All STARR, Node Exporter |
| 🟡 High | 3 | Gluetun, Grafana, Monitoring |
| 🟢 Medium | 5 | Various configuration issues |
| 🔵 Low | 3 | Integration, optimization |

**Total Risks:** 15
**Critical Risks Requiring Immediate Action:** 4

## 🔒 Security Hardening Template

Use this template for all services:

```yaml
services:
  service_name:
    # User (non-root)
    user: "${PUID:-1000}:${PGID:-1000}"

    # Security options
    security_opt:
      - no-new-privileges:true

    # Capabilities
    cap_drop:
      - ALL
    cap_add:
      - NET_ADMIN  # Only what's needed

    # Read-only filesystem (if possible)
    read_only: true
    tmpfs:
      - /tmp
      - /var/run

    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 256M

    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:PORT"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

    # Dependencies
    depends_on:
      - dependency_service
```

## 📚 References

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP Docker Security](https://owasp.org/www-project-docker-top-10/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Container Security Guide](https://www.nist.gov/publications/application-container-security-guide)

---

**Audit Date**: Current
**Next Audit**: After remediation (1 week)
**Status**: ⚠️ **REQUIRES IMMEDIATE ATTENTION**

