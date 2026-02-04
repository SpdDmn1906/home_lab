# Infrastructure as Code: Complete Home Lab Management

## Overview

Your home lab now implements **enterprise-grade Infrastructure as Code (IaC)** using Terraform and Ansible. This provides complete automation, version control, and professional management practices for your personal datacenter.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layers                     │
├─────────────────────────────────────────────────────────────┤
│  🏗️  Terraform (Infrastructure State Management)           │
│     • Network configuration (VLANs, DHCP, DNS)             │
│     • Docker service deployment                            │
│     • Security policies and firewall rules                 │
│     • Monitoring stack setup                               │
├─────────────────────────────────────────────────────────────┤
│  ⚙️  Ansible (Configuration Management)                     │
│     • Server hardening and security                        │
│     • Application deployment and configuration             │
│     • Backup system automation                             │
│     • Health monitoring and alerting                       │
├─────────────────────────────────────────────────────────────┤
│  🐳  Docker (Container Runtime)                             │
│     • Service isolation and portability                    │
│     • Easy scaling and updates                             │
│     • Resource management                                  │
├─────────────────────────────────────────────────────────────┤
│  📊  Monitoring & Observability                             │
│     • Prometheus metrics collection                        │
│     • Grafana dashboards and visualization                 │
│     • Alerting and notification system                     │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start Commands

### First-Time Setup
```bash
# Initialize everything
./infrastructure-manager.sh init

# Configure your environment
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy complete infrastructure
./infrastructure-manager.sh deploy
```

### Daily Operations
```bash
# Check status
./infrastructure-manager.sh status

# Plan changes
./infrastructure-manager.sh plan

# Apply changes
./infrastructure-manager.sh deploy

# Verify health
./infrastructure-manager.sh verify

# Backup state
./infrastructure-manager.sh backup
```

## Terraform Components

### Core Modules

**Network Module** (`terraform/modules/network/`)
- Interface configuration
- DHCP server setup
- DNS configuration
- Firewall rules
- VLAN management

**Docker Module** (`terraform/modules/docker/`)
- Container deployment
- Network creation
- Volume management
- Health monitoring

### Terraform as the Source of Truth for Docker (NEW)

**Problem**: Right now, you have a mix of “live docker-compose on the server” and “proposed configs in this repo.” That causes drift and makes troubleshooting harder.

**Solution**: Treat Terraform as the **authoritative manager** for Docker containers and networks going forward.

**Implementation (Recommended Migration)**
- **Phase A (Codify without breaking prod)**
  - Pick one stack to migrate first (start with **AdGuard**, then monitoring).
  - Define it in `terraform/terraform.tfvars` via `docker_networks`, `docker_services`, etc.
  - Apply and validate.
- **Phase B (Migrate existing compose stacks)**
  - For each container:
    - Stop/remove compose management for that stack
    - Recreate with Terraform using the same volumes and ports
  - Prefer this over `terraform import` for complex stacks (VPN sidecars, `network_mode: service:*`, etc.).

**Notes**
- Gluetun-style `network_mode: "service:gluetun"` stacks are doable but require careful container networking. Migrate these last.
- Avoid “half-managed” states (Terraform + docker-compose both manipulating the same container names).

**Monitoring Module** (`terraform/modules/monitoring/`)
- Prometheus configuration
- Grafana setup
- Alert rules
- Dashboard provisioning

**Security Module** (`terraform/modules/security/`)
- SSH hardening
- Firewall policies
- Access controls
- Security monitoring

**Backup Module** (`terraform/modules/backup/`)
- Backup scheduling
- Encryption setup
- Retention policies
- Verification

### State Management

Terraform maintains state in `terraform/terraform.tfstate`:
```bash
# View current state
cd terraform
terraform state list

# View specific resource
terraform state show docker_container.plex

# Backup state
terraform state pull > backup.tfstate
```

## Ansible Components

### Playbooks

**Infrastructure Setup** (`ansible/playbooks/infrastructure-setup.yml`)
- Complete system deployment
- Service configuration
- Security hardening
- Monitoring setup

**Network Migration** (`ansible/playbooks/network-migration.yml`)
- Router reconfiguration
- Network unification
- Device migration
- Verification

**Maintenance** (`ansible/playbooks/maintenance.yml`)
- System updates
- Service restarts
- Log rotation
- Health checks

### Roles

**Network Migration** (`ansible/roles/network-migration/`)
- Router configuration
- DHCP setup
- DNS configuration
- Firewall rules

**Monitoring Setup** (`ansible/roles/monitoring-setup/`)
- Prometheus deployment
- Grafana configuration
- Alertmanager setup
- Exporter installation

### Variables

**Infrastructure Variables** (`ansible/playbooks/vars/infrastructure.yml`)
- Service configurations
- Network settings
- Security policies
- Monitoring parameters

**Secrets Management** (`ansible/playbooks/vars/secrets.yml`)
- API keys
- Passwords
- Certificates
- Private keys

## Configuration Files

### Terraform Variables
```hcl
# terraform/terraform.tfvars
network = {
  unified_subnet = "192.168.1.0/24"
  gateway_ip     = "192.168.1.1"
  dhcp_range     = ["192.168.1.100", "192.168.1.200"]
  dns_servers    = ["192.168.1.1", "8.8.8.8"]
}

plex = {
  claim_token = "your-plex-claim-token"
}

grafana = {
  admin_password = "secure-password"
}
```

### Ansible Inventory
```ini
# ansible/inventory/hosts.ini
[local]
localhost ansible_connection=local

[media_server]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_user=homelab
```

## Deployment Workflow

### 1. Development/Testing
```bash
# Test changes locally
cd terraform
terraform plan
terraform apply -auto-approve

# Test Ansible changes
cd ansible
ansible-playbook -i inventory/hosts.ini --check playbooks/infrastructure-setup.yml
```

### 2. Production Deployment
```bash
# Use the unified script
./infrastructure-manager.sh plan
./infrastructure-manager.sh deploy
./infrastructure-manager.sh verify
```

### 3. Rollback Procedures
```bash
# Terraform rollback
cd terraform
terraform plan -destroy
terraform apply

# Ansible rollback
cd ansible
ansible-playbook playbooks/rollback.yml
```

## Monitoring Integration

### Terraform-Managed Monitoring
- Prometheus scrapes Terraform-managed services automatically
- Grafana dashboards provisioned via Terraform
- Alert rules defined in Terraform configuration

### Ansible-Managed Monitoring
- Exporters installed via Ansible
- Configuration files deployed by Ansible
- Health checks automated in Ansible

## Security Integration

### Infrastructure Security
- **Network**: VLAN isolation, firewall rules
- **Access**: SSH key-only authentication
- **Services**: Least privilege container configurations
- **Monitoring**: Security event alerting

### Secret Management
```bash
# Ansible Vault for secrets
ansible-vault encrypt ansible/playbooks/vars/secrets.yml

# Access during deployment
ansible-playbook --ask-vault-pass playbooks/infrastructure-setup.yml
```

## Backup and Recovery

### Infrastructure Backups
```bash
# Automated backups
./infrastructure-manager.sh backup

# Manual backup
cd terraform
terraform state pull > $(date +%Y%m%d)_terraform_backup.tfstate

cd ansible
tar czf ../backups/$(date +%Y%m%d)_ansible_backup.tar.gz .
```

### Disaster Recovery
```bash
# Restore from backup
cd terraform
terraform state push backup.tfstate

# Redeploy infrastructure
./infrastructure-manager.sh deploy
```

## Advanced Features

### Multi-Environment Support
```bash
# Development environment
terraform workspace select dev
terraform apply -var-file=dev.tfvars

# Production environment
terraform workspace select prod
terraform apply -var-file=prod.tfvars
```

### CI/CD Integration
```yaml
# .github/workflows/deploy.yml
name: Deploy Infrastructure
on: [push, pull_request]
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: hashicorp/terraform-github-actions@master
        with:
          tf_actions_version: 0.14.3
          tf_actions_subcommand: 'apply'
```

## Troubleshooting

### Terraform Issues
```bash
# Debug Terraform
export TF_LOG=DEBUG
terraform apply

# Fix state issues
terraform state list
terraform state rm <resource>
```

### Ansible Issues
```bash
# Debug Ansible
ansible-playbook -vvv playbooks/infrastructure-setup.yml

# Check syntax
ansible-playbook --syntax-check playbooks/infrastructure-setup.yml
```

### Common Issues

**State File Conflicts**:
```bash
terraform state pull
terraform state push fixed.tfstate
```

**Permission Issues**:
```bash
sudo chown -R $USER:$USER terraform/
sudo chown -R $USER:$USER ansible/
```

**Network Conflicts**:
```bash
# Check network status
./comprehensive_network_test.sh
```

## Performance Optimization

### Terraform Performance
- Use `terraform plan -parallelism=10` for faster planning
- Split large configurations into modules
- Use `terraform workspace` for environment isolation

### Ansible Performance
- Use `ansible.cfg` with connection multiplexing
- Implement fact caching
- Use async tasks for long-running operations

## Future Enhancements

### Planned Features
- **Kubernetes Integration**: Migrate from Docker Compose to K8s
- **Cloud Backup**: Offsite backup to cloud storage
- **Multi-Site**: Support for multiple home lab locations
- **Service Mesh**: Istio integration for advanced networking
- **GitOps**: Flux or ArgoCD for continuous deployment

### Extension Points
- Add new Terraform modules for additional services
- Create Ansible roles for custom applications
- Integrate with cloud providers for hybrid setups
- Implement automated testing for infrastructure changes

## Support and Resources

### Documentation
- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [Docker Documentation](https://docs.docker.com)

### Community Resources
- [Terraform Registry](https://registry.terraform.io)
- [Ansible Galaxy](https://galaxy.ansible.com)
- [HashiCorp Learn](https://learn.hashicorp.com)

### Getting Help
1. Check logs in `/var/log/homelab/`
2. Run `./infrastructure-manager.sh status`
3. Review Terraform state: `terraform state list`
4. Check Ansible facts: `ansible localhost -m setup`

---

**This Infrastructure as Code setup transforms your home lab into a professionally managed datacenter with enterprise-grade practices, complete automation, and production-level reliability.**


