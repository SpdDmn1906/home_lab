# AdGuard Home with Unbound Setup Guide

**Date**: 2025-12-29
**Purpose**: Deploy AdGuard Home + Unbound for DNS filtering and recursive DNS resolution
**Status**: 📋 **Configuration Ready**

---

## 🎯 Overview

### Why AdGuard Home + Unbound?

**AdGuard Home Benefits:**
- ✅ Modern web interface with better UX
- ✅ Built-in DoH (DNS over HTTPS) and DoT (DNS over TLS) support
- ✅ More efficient filtering engine
- ✅ Better performance and lower resource usage
- ✅ Active development and frequent updates
- ✅ Native Prometheus metrics support

**Unbound Benefits:**
- ✅ Recursive DNS resolver (no reliance on external DNS servers)
- ✅ DNSSEC validation built-in
- ✅ DNS caching for faster resolution
- ✅ Privacy-focused (no external DNS queries)
- ✅ Better control over DNS resolution

**Combined Benefits:**
- ✅ Complete DNS independence (recursive + filtering)
- ✅ Better privacy (no DNS queries to third parties)
- ✅ Faster DNS resolution (caching + recursion)
- ✅ Enterprise-grade DNS infrastructure

---

## 🏗️ Architecture (Recommended for Your Use Case)

```
Internet
   ↓
[AdGuard Home] (Filtering + Blocking, runs on media server host ports)
   ↓ (Queries on Docker network)
[Unbound] (Recursive DNS Resolver, NOT exposed to LAN)
   ↓ (Root DNS Servers)
Internet DNS Root
```

**Flow:**
1. Device queries AdGuard Home (port 53)
2. AdGuard Home applies filtering/blocking rules
3. AdGuard Home queries Unbound (port 5335) for resolution
4. Unbound recursively resolves from root DNS servers
5. Response cached and returned to device

---

## 📋 Configuration

### Terraform Configuration

**In `terraform.tfvars`:**
```hcl
features = {
  enable_adguard = true
}

adguard = {
  admin_username = "admin"
  admin_password = "YOUR_SECURE_PASSWORD"
}
```

### Module Configuration

**Key Settings:**
- **Unbound Enabled**: Yes (recursive DNS)
- **DNS Port**: 53 (standard)
- **Web Interface**: Port 3000
- **HTTPS Interface**: Port 3001
- **DoH/DoT**: Port 853 (if enabled)

---

## 🔧 Deployment

### Step 1: Update Terraform Configuration

```bash
cd terraform

# Ensure Terraform is configured to deploy the AdGuard module
# (Module already created in terraform/modules/adguard/)
```

### Step 2: Deploy Infrastructure

```bash
# Initialize Terraform (if not already done)
terraform init

# Plan changes
terraform plan

# Apply configuration
terraform apply
```

### Step 3: Initial Setup

1. **Access AdGuard Home Web UI (on media server):**
   - `http://192.168.1.11:3000`
   - Note: In this repo’s implementation, AdGuard runs on the **media server host IP** (not a dedicated 192.168.1.40) unless you later add macvlan/extra IPs.

2. **Initial Configuration Wizard:**
   - Set admin username and password
   - Configure upstream DNS (will use Unbound automatically)
   - Set web interface port (3000)
   - Complete setup

3. **Verify Unbound Integration:**
   - Settings → DNS Settings
   - Upstream DNS should point to Unbound on the Docker network (ex: `unbound:53`)

---

## ⚙️ Configuration Details

### Unbound Configuration

**Recursive DNS Settings:**
- **Port**: 5335 (internal to AdGuard)
- **DNSSEC**: Enabled
- **Cache**: Enabled (1 hour min, 24 hours max)
- **Threads**: 4 (adjust based on CPU)
- **IPv4/IPv6**: Both enabled

**Benefits:**
- No reliance on external DNS providers
- Complete DNS privacy
- Faster resolution (cached results)
- DNSSEC validation

### AdGuard Home Configuration

**DNS Settings:**
- **Upstream DNS**: 127.0.0.1:5335 (Unbound)
- **Bootstrap DNS**: 1.1.1.1, 8.8.8.8 (for initial resolution)
- **Fallback DNS**: 1.1.1.1, 8.8.8.8 (if Unbound fails)
- **DNSSEC**: Enabled
- **EDNS Client Subnet**: Enabled
- **Fastest Address**: Enabled
- **Parallel Requests**: Enabled

**Filtering:**
- **Blocking Mode**: Default (NXDOMAIN)
- **Filtering**: Enabled
- **Blocklists**: Pre-configured (9 default lists)
- **Rate Limiting**: 20 queries/second (configurable)

**Query Logging:**
- **Enabled**: Yes
- **Rotation**: 24 hours
- **Memory Size**: 1000 entries

---

## 🔐 Router Configuration

### Configure Router DNS

**Asus Nighthawk:**
1. Access router: http://192.168.1.1
2. Navigate: LAN → DHCP Server
3. Set DNS servers:
   - Primary DNS: `192.168.1.11` (AdGuard Home running on media server)
   - Secondary DNS: `1.1.1.1` (fallback)
4. Save and apply

**Alternative: Per-Device Configuration**
- Set DNS manually on each device
   - Primary: `192.168.1.11`
- Secondary: `1.1.1.1`

---

## 📊 Local DNS Records

### Pre-Configured Records

AdGuard Home will automatically create DNS records for:

```
plex.homelab.local → 192.168.1.11
nas.homelab.local → 192.168.1.20
grafana.homelab.local → 192.168.1.11
prometheus.homelab.local → 192.168.1.11
adguard.homelab.local → 192.168.1.11
```

### Adding Custom Records

**Via Web UI:**
1. Settings → DNS Rewrites
2. Add domain → IP mapping
3. Save

**Via Terraform:**
```hcl
adguard = {
  lan_dns_records = [
    {
      hostname = "plex"
      ip       = "192.168.1.11"
    },
    # Add more records...
  ]
}
```

---

## 🚫 Ad Blocking

### Default Blocklists

Pre-configured blocklists include:
- StevenBlack hosts
- Malware domains
- Disconnect tracking/ad servers
- AdAway hosts
- AdGuard filters (mobile + spyware)
- Additional curated lists

**Total**: ~100,000+ blocked domains

### Managing Blocklists

**Via Web UI:**
1. Filters → DNS blocklists
2. Add custom blocklist URLs
3. Enable/disable specific lists
4. Update lists manually or automatically

**Custom Blocklists:**
- Add URL in AdGuard Home interface
- Or configure in Terraform variables

---

## 📈 Monitoring

### Prometheus Integration

**Metrics Endpoint:**
```
http://192.168.1.11:3000/control/metrics
```

**Prometheus Configuration:**
```yaml
scrape_configs:
  - job_name: 'adguard'
    static_configs:
      - targets: ['192.168.1.11:3000']
    metrics_path: '/control/metrics'
    scrape_interval: 30s
```

### Grafana Dashboards

**Available Dashboards:**
- AdGuard Home Stats
- DNS Query Statistics
- Blocked Domains
- Top Clients
- Query Log Analysis

---

## 🔄 Migration Notes

This repo assumes AdGuard Home is the DNS/ad-blocking solution.
If you previously used another DNS/ad-blocking tool, treat migration as an **operational change**:

1. Export any custom DNS records / rewrites you care about.
2. Prefer keeping DHCP on the router; only enable AdGuard DHCP intentionally.
3. Point router DNS (or client DNS) to AdGuard on `192.168.1.11`.
4. Verify resolution + filtering + local records.

---

## 📚 Related Documentation

- [HOMELAB_ADVANCED_FEATURES.md](HOMELAB_ADVANCED_FEATURES.md) - Updated for AdGuard Home
- [INFRASTRUCTURE_MANAGEMENT.md](INFRASTRUCTURE_MANAGEMENT.md) - Infrastructure as Code
- [DNS_SETUP_GUIDE.md](DNS_SETUP_GUIDE.md) - DNS configuration guide

---

## 🔗 External Resources

- [AdGuard Home Documentation](https://github.com/AdguardTeam/AdGuardHome/wiki)
- [Unbound Documentation](https://unbound.docs.nlnetlabs.nl/)
- [AdGuard Home GitHub](https://github.com/AdguardTeam/AdGuardHome)

---

**Status**: 📋 **READY FOR DEPLOYMENT**
**Priority**: Medium (DNS infrastructure enhancement)
**Timeline**: Deploy after critical fixes completed

