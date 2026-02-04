# Advanced Home Lab Features

## Overview

Your home lab now supports advanced features for network-wide ad blocking, parental controls, secure remote access, and AI assistance. These features build on your existing infrastructure to provide enterprise-grade capabilities.

## 🚫 1. AdGuard Home + Unbound (Recommended DNS + Ad Blocking)

### What It Does
- **Network-wide ad blocking** using DNS filtering
- **Recursive DNS** with Unbound (no third-party upstream required)
- **Custom DNS rewrites** for local services
- **Query logging and analytics**
- **Block malicious domains**
- **DoH/DoT support** (optional)

### Configuration

**Enable AdGuard Home:**
```bash
# In terraform.tfvars
features = {
  enable_adguard = true
}

adguard = {
  admin_username = "admin"
  admin_password = "your-secure-password"
}
```

**Deploy:**
```bash
./infrastructure-manager.sh deploy
```

### Access Points
- **Web Interface:** http://192.168.1.11:3000
- **DNS:** Configure router DHCP to use `192.168.1.11` as DNS server
- **Metrics:** `http://192.168.1.11:3000/control/metrics`

### Key Features

**Ad Blocking:**
- 100,000+ blocked domains
- Custom blocklists
- Regex filtering
- Whitelist capabilities

**DHCP (Optional):**
- IP address assignment
- Static IP reservations
- Network boot options

**Custom DNS:**
- Local service resolution
- Split DNS capabilities
- CNAME records

### Integration with Existing Services

**Parental Controls:**
- AdGuard supports per-client rules and DNS rewrites
- Time-based restrictions can be implemented, but requires AdGuard configuration (future enhancement in this repo)

**Monitoring:**
- Query logs integrated with Prometheus
- Grafana dashboards for ad blocking stats
- Alerting on high query volumes

## 👨‍👩‍👧‍👦 2. Parental Controls

### What It Does
- **Device monitoring** and time restrictions
- **Content filtering** for inappropriate sites
- **Usage tracking** and reporting
- **Remote device management**
- **Email alerts** for policy violations

### Configuration

**Children's Device Setup:**
```hcl
# In terraform.tfvars
restricted_devices = [
  {
    name          = "child1-ipad"
    mac           = "XX:XX:XX:XX:XX:XX"  # Get from device settings
    allowed_hours = "06:00-21:00"
    blocked_sites = ["youtube.com", "tiktok.com", "instagram.com"]
  },
  {
    name          = "child2-ipad"
    mac           = "XX:XX:XX:XX:XX:XX"
    allowed_hours = "06:00-21:00"
    blocked_sites = ["youtube.com", "tiktok.com", "instagram.com"]
  }
]
```

**Time Restrictions:**
```hcl
time_restrictions = [
  {
    device     = "child1-ipad"
    start_time = "06:00"
    end_time   = "21:00"
    days       = ["monday", "tuesday", "wednesday", "thursday", "friday"]
  }
]
```

### Access Points
- **Web Dashboard:** http://localhost:8082 (if enabled)
- **API:** REST API for remote management
- **Alerts:** Email notifications for violations

### Features

**Device Control:**
- MAC address-based identification
- Time-based internet access
- Bandwidth limiting
- Remote device shutdown

**Content Filtering:**
- Domain blocking
- Category-based filtering
- Safe search enforcement
- Custom allowlists

**Monitoring & Reporting:**
- Daily usage reports
- Screen time tracking
- Website visit logs
- Alert notifications

**Integration:**
- Works with AdGuard Home for DNS-based filtering
- Grafana dashboards for usage analytics
- Home Assistant integration for smart home controls

## 🔐 3. Secure Remote Access

### What It Does
- **VPN access** with WireGuard/OpenVPN
- **Remote desktop** capabilities
- **SSH jump host** for secure shell access
- **Reverse proxy** with SSL termination
- **Automatic SSL certificates**

### VPN Setup (WireGuard)

**Configuration:**
```bash
# Generate client configs after deployment
docker exec wireguard cat /config/peer_admin-laptop/peer_admin-laptop.conf
```

**Client Setup:**
1. Install WireGuard client on your device
2. Import the configuration file
3. Connect to access your home network remotely

### Remote Desktop Options

**Apache Guacamole (Web-based):**
- Access from any web browser
- RDP, VNC, SSH support
- No client software needed
- **URL:** http://localhost:8083

**NoMachine (Native performance):**
- High-performance remote desktop
- File transfer capabilities
- Audio support
- **URL:** http://localhost:4000

### SSH Access

**Secure Jump Host:**
- Port 2222 (non-standard for security)
- Key-based authentication only
- Access to internal services

### Reverse Proxy (Traefik)

**SSL Termination:**
- Automatic Let's Encrypt certificates
- Secure HTTPS access
- Load balancing
- Service discovery

**Example URLs:**
- https://plex.yourdomain.com
- https://grafana.yourdomain.com
- https://assistant.yourdomain.com

## 🤖 4. AI Assistant (Local)

### What It Does
- **Local LLM** processing (no cloud dependency)
- **Voice interface** with wake word detection
- **Home automation** integration
- **Web interface** for management
- **Privacy-focused** (all data stays local)

### Core Components

**Ollama (LLM Engine):**
- Runs local language models
- GPU acceleration support
- Multiple model support
- REST API interface

**Voice Interface (Rhasspy):**
- Wake word detection ("Hey Assistant")
- Speech-to-text processing
- Text-to-speech responses
- Intent recognition

**Backend Service:**
- Natural language processing
- Home automation control
- Weather integration
- Reminder and calendar functions

### Capabilities

**Home Control:**
- "Turn on the living room lights"
- "Set thermostat to 72 degrees"
- "Lock the front door"
- "What's the weather like?"

**Information:**
- "What's today's weather?"
- "Set a reminder for tomorrow"
- "How's the network doing?"
- "Play some music"

**System Monitoring:**
- "Check server status"
- "How much storage is left?"
- "Are there any alerts?"
- "Show me the security cameras"

### Privacy & Security

**Local Processing:**
- No cloud services used
- All voice data stays on your network
- No external API calls for core functions
- Encrypted local storage

**Access Control:**
- Wake word required for activation
- User authentication for sensitive commands
- Command logging (optional)
- Network isolation

### Hardware Requirements

**Minimum:**
- CPU: 4 cores
- RAM: 8GB
- Storage: 20GB for models

**Recommended:**
- CPU: 6+ cores
- RAM: 16GB+
- GPU: NVIDIA with CUDA support
- Storage: 50GB+ SSD

## 🛠️ Implementation Steps

### Phase 1: Network Infrastructure
```bash
# Complete network unification first
cat NETWORK_MIGRATION_PLAN.md
./infrastructure-manager.sh deploy
```

### Phase 2: AdGuard Home + Unbound Setup
```bash
# Enable AdGuard in terraform.tfvars
features = { enable_adguard = true }

# Deploy
./infrastructure-manager.sh plan
./infrastructure-manager.sh deploy

# Configure router DHCP to use AdGuard DNS
# DNS Server IP (AdGuard on media server): 192.168.1.11
```

### Phase 3: Parental Controls
```bash
# Configure device restrictions
# Add children's device MAC addresses
# Set time limits and blocked sites

./infrastructure-manager.sh deploy
```

### Phase 4: Remote Access
```bash
# Enable VPN and remote desktop
features = { enable_remote_access = true }

./infrastructure-manager.sh deploy

# Download VPN configs
docker exec wireguard cat /config/peer_admin-laptop/peer_admin-laptop.conf
```

### Phase 5: AI Assistant (Optional)
```bash
# Enable AI features (resource intensive)
features = { enable_ai_assistant = true }

./infrastructure-manager.sh deploy

# Wait for model downloads
# Access at http://localhost:8501
```

## 📊 Monitoring & Analytics

### AdGuard Analytics
- Blocked query percentages
- Top blocked domains
- Client usage statistics
- Query type analysis

### Parental Control Reports
- Daily/weekly screen time reports
- Blocked site attempts
- Device usage patterns
- Time compliance tracking

### Remote Access Monitoring
- VPN connection logs
- Remote desktop sessions
- SSH access attempts
- SSL certificate status

### AI Assistant Insights
- Most common queries
- Response accuracy
- Voice recognition success rate
- System performance metrics

## 🔧 Maintenance & Updates

### Regular Tasks

**Weekly:**
- Review parental control logs
- Update AdGuard blocklists
- Check VPN connection logs
- Monitor AI assistant performance

**Monthly:**
- Rotate VPN keys
- Update AI models
- Review blocked domains
- Audit remote access logs

### Security Updates

**AdGuard Home + Unbound:**
```bash
docker pull adguard/adguardhome:latest
docker pull mvance/unbound:latest
./infrastructure-manager.sh deploy
```

**AI Models:**
```bash
# Pull latest models
docker exec ollama ollama pull llama2:7b-chat
```

**SSL Certificates:**
- Automatic renewal via Traefik
- Manual renewal if needed

## 🚨 Troubleshooting

### AdGuard Issues
```bash
# Check logs
docker logs adguard

# Restart service
docker restart adguard

# Check DNS resolution
nslookup google.com 192.168.1.11
```

### Parental Controls
```bash
# Check device detection
docker logs parental-monitor

# Test time restrictions
docker exec parental-monitor python /config/test_restrictions.py
```

### Remote Access
```bash
# Check VPN status
docker logs wireguard

# Test remote desktop
curl http://localhost:8083
```

### AI Assistant
```bash
# Check Ollama status
docker logs ollama

# Test voice interface
curl http://localhost:12101/api/listen-for-command

# Check backend API
curl http://localhost:8000/health
```

## 📚 Resources

### Documentation
- [AdGuard Home Docs](https://github.com/AdguardTeam/AdGuardHome/wiki)
- [WireGuard Docs](https://www.wireguard.com/)
- [Ollama Docs](https://github.com/jmorganca/ollama)
- [Rhasspy Docs](https://rhasspy.readthedocs.io/)

### Community Support
- [AdGuard Home GitHub](https://github.com/AdguardTeam/AdGuardHome)
- [WireGuard Subreddit](https://reddit.com/r/WireGuard)
- [Home Assistant Community](https://community.home-assistant.io/)

---

**These advanced features transform your home lab into a comprehensive smart home platform with enterprise-grade security, parental controls, and AI capabilities - all running locally for maximum privacy and control.**


