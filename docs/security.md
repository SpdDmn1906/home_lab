# Security Hardening Guide

## Overview

This guide provides security best practices for securing your home lab infrastructure. While this is a home environment, applying production-like security practices ensures better protection and prepares you for professional scenarios.

## Network Security

### Firewall Configuration

**Router Firewall:**
1. Enable firewall on router
2. Disable remote management (unless using VPN)
3. Close all unnecessary ports
4. Enable port forwarding only for required services
5. Use non-standard ports when possible (security through obscurity)

**Host Firewall (UFW - Ubuntu/Debian):**
```bash
# Install UFW if not present
sudo apt-get install ufw

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (be careful - don't lock yourself out!)
sudo ufw allow 22/tcp

# Allow Docker services (if needed externally)
# Only expose what's necessary
sudo ufw allow 32400/tcp comment 'Plex'

# Enable firewall
sudo ufw enable
sudo ufw status verbose
```

**Host Firewall (iptables - Advanced):**
```bash
# Basic iptables rules
# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (from specific IP if possible)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow Docker (adjust as needed)
iptables -A FORWARD -i docker0 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o docker0 -j ACCEPT

# Default deny
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Save rules (distribution-specific)
sudo iptables-save > /etc/iptables/rules.v4
```

### Network Segmentation

**VLAN Configuration:**
- Separate IoT devices into isolated VLAN
- Guest network on separate VLAN
- Main network for trusted devices only
- Firewall rules between VLANs

**Example VLAN Setup:**
```
VLAN 1 (192.168.1.0/24): Main network (trusted)
VLAN 10 (192.168.10.0/24): IoT devices (isolated)
VLAN 20 (192.168.20.0/24): Guest network (no internal access)
```

### VPN Setup (Recommended)

**Why VPN:**
- Secure remote access
- Encrypt all traffic
- Avoid exposing services directly to internet
- Access services from anywhere securely

**Options:**
1. **WireGuard** (Recommended - modern, fast, secure)
2. **OpenVPN** (Mature, widely supported)
3. **Tailscale** (Easy setup, mesh VPN)

**WireGuard Quick Setup:**
```bash
# Install WireGuard
sudo apt-get install wireguard

# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Configure server (wg0.conf)
[Interface]
Address = 10.0.0.1/24
PrivateKey = <server-private-key>
ListenPort = 51820

[Peer]
PublicKey = <client-public-key>
AllowedIPs = 10.0.0.2/32

# Start WireGuard
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

## Application Security

### Docker Security

**Run Containers as Non-Root:**
```yaml
services:
  plex:
    user: "1000:1000"  # Run as non-root user
```

**Resource Limits:**
```yaml
services:
  plex:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
```

**Read-Only Root Filesystem (when possible):**
```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
```

**Security Options:**
```yaml
services:
  app:
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
```

**Network Isolation:**
- Use Docker networks to isolate services
- Only expose necessary ports
- Use internal networks for service-to-service communication

### Service Authentication

**Strong Passwords:**
- Use password managers
- Generate strong, unique passwords
- Rotate passwords regularly
- Minimum 16 characters, mixed case, numbers, symbols

**API Keys:**
- Generate unique API keys for each service
- Store in environment variables (not in code)
- Rotate regularly
- Use secrets management

**Two-Factor Authentication (2FA):**
- Enable 2FA on all services that support it
- Use authenticator apps (not SMS)
- Backup recovery codes securely

### Secrets Management

**Environment Variables:**
```bash
# Never commit .env files
# Use .env.example as template
# Rotate secrets regularly
```

**Docker Secrets (Docker Swarm):**
```bash
# Create secret
echo "my-secret" | docker secret create my_secret -

# Use in service
services:
  app:
    secrets:
      - my_secret
```

**External Secrets Management:**
- HashiCorp Vault (advanced)
- AWS Secrets Manager (if using AWS)
- Kubernetes Secrets (if using K8s)

## System Security

### Operating System Hardening

**Regular Updates:**
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get upgrade -y

# RHEL/CentOS
sudo yum update -y

# Schedule automatic updates (optional)
sudo apt-get install unattended-upgrades
```

**SSH Hardening:**
```bash
# Edit /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no  # Use keys only
PubkeyAuthentication yes
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2

# Restart SSH
sudo systemctl restart sshd
```

**SSH Key Setup:**
```bash
# Generate key pair (on client)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy public key to server
ssh-copy-id user@server

# Test connection
ssh user@server
```

**Disable Unnecessary Services:**
```bash
# List running services
systemctl list-units --type=service --state=running

# Disable unnecessary services
sudo systemctl disable service-name
sudo systemctl stop service-name
```

**Fail2Ban Setup:**
```bash
# Install Fail2Ban
sudo apt-get install fail2ban

# Configure
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local

# Start and enable
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Logging and Monitoring

**Centralized Logging:**
- Use Loki + Promtail for log aggregation
- Review logs regularly
- Set up alerts for suspicious activity

**Security Monitoring:**
- Monitor failed login attempts
- Monitor unusual network activity
- Monitor file system changes
- Set up intrusion detection (optional)

**Audit Logging:**
```bash
# Enable auditd (Linux)
sudo apt-get install auditd
sudo systemctl enable auditd
sudo systemctl start auditd

# Configure audit rules
sudo nano /etc/audit/rules.d/audit.rules
```

## Data Security

### Encryption

**At Rest:**
- Encrypt sensitive data
- Use encrypted filesystems (LUKS)
- Encrypt backups

**In Transit:**
- Use HTTPS/TLS for all web services
- Use VPN for remote access
- Encrypt database connections

**Disk Encryption (LUKS):**
```bash
# Encrypt disk
sudo cryptsetup luksFormat /dev/sdb1
sudo cryptsetup luksOpen /dev/sdb1 encrypted_disk
sudo mkfs.ext4 /dev/mapper/encrypted_disk

# Mount
sudo mount /dev/mapper/encrypted_disk /mnt/encrypted
```

### Backup Security

**Secure Backups:**
- Encrypt backups
- Store backups in secure location
- Test backup restoration
- Use offsite backups for critical data

**Backup Encryption:**
```bash
# Encrypt backup
tar czf - /data | openssl enc -aes-256-cbc -salt -out backup.tar.gz.enc

# Decrypt backup
openssl enc -aes-256-cbc -d -in backup.tar.gz.enc | tar xzf -
```

## IoT Device Security

### Isolation

**Network Isolation:**
- Place IoT devices on separate VLAN
- Block IoT devices from accessing main network
- Allow internet access only (if needed)

**Device Hardening:**
- Change default passwords
- Disable unnecessary features
- Update firmware regularly
- Disable UPnP if not needed
- Review device permissions

### Security Camera Security

**Camera-Specific Security:**
```bash
# Disable unnecessary remote access
# Use strong passwords for camera accounts
# Enable two-factor authentication where available
# Regularly update camera firmware
# Use local storage when possible to reduce cloud exposure
```

**Nest Camera Security:**
- Review Google account privacy settings
- Enable facial recognition only for trusted family
- Regularly review access history
- Consider local storage options for sensitive areas

**Eufy Camera Security:**
- Change default Homebase password
- Enable local storage on Homebase
- Disable cloud storage if privacy is concern
- Regularly update Homebase firmware
- Use strong WiFi encryption

**Abode Security System:**
- Change default system PIN
- Enable professional monitoring if desired
- Regularly test sensors and connectivity
- Keep system firmware updated
- Review mobile app permissions

### Monitoring

**IoT Device Monitoring:**
- Monitor network traffic from IoT devices
- Alert on unusual activity
- Regular security audits
- Keep device inventory

## Incident Response

### Preparation

**Documentation:**
- Maintain asset inventory
- Document network topology
- Keep credentials secure (password manager)
- Document incident response procedures

**Backup Strategy:**
- Regular automated backups
- Test restore procedures
- Offsite backups for critical data
- Document backup locations and procedures

### Detection

**Signs of Compromise:**
- Unusual network activity
- Unexpected system behavior
- Failed login attempts
- Unauthorized file changes
- High resource usage from unknown processes

### Response Procedures

1. **Isolate:** Disconnect affected systems from network
2. **Assess:** Determine scope of compromise
3. **Contain:** Prevent further damage
4. **Eradicate:** Remove threat
5. **Recover:** Restore from clean backups
6. **Document:** Record incident and lessons learned

## Compliance and Best Practices

### Security Checklist

- [ ] Firewall enabled and configured
- [ ] All services updated
- [ ] Strong passwords/keys in use
- [ ] 2FA enabled where possible
- [ ] SSH hardened (keys only)
- [ ] Unnecessary services disabled
- [ ] Network segmentation implemented
- [ ] VPN configured for remote access
- [ ] Backups encrypted and tested
- [ ] Monitoring and logging enabled
- [ ] IoT devices isolated
- [ ] Security updates automated
- [ ] Incident response plan documented

### Regular Maintenance

**Weekly:**
- Review security logs
- Check for failed login attempts
- Review system updates

**Monthly:**
- Update all software
- Review firewall rules
- Audit user accounts
- Review backup integrity
- Security scan (optional)

**Quarterly:**
- Full security audit
- Review and update security policies
- Test incident response procedures
- Review and rotate credentials

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
