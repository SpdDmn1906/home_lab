#!/bin/bash

# Home Lab Infrastructure as Code Deployment Script
# Automates the full Terraform + Ansible deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${BLUE}[$TIMESTAMP]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    # Check Terraform
    if ! command -v terraform >/dev/null 2>&1; then
        error "Terraform is not installed. Please install Terraform first."
    fi
    success "Terraform found: $(terraform version | head -1)"

    # Check Ansible
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        error "Ansible is not installed. Please install Ansible first."
    fi
    success "Ansible found: $(ansible-playbook --version | head -1)"

    # Check terraform.tfvars
    if [ ! -f "terraform/terraform.tfvars" ]; then
        warning "terraform.tfvars not found. Please copy terraform/terraform.tfvars.example to terraform/terraform.tfvars and configure your router passwords."
        exit 1
    fi
    success "Terraform variables file found"
}

# Phase 1: Terraform Planning
terraform_plan() {
    log "Phase 1: Terraform Planning"

    cd terraform

    echo "Initializing Terraform..."
    terraform init

    echo "Planning deployment..."
    if terraform plan -out=tfplan; then
        success "Terraform plan generated successfully"
    else
        error "Terraform plan failed"
    fi

    cd ..
}

# Phase 2: Terraform Apply
terraform_apply() {
    log "Phase 2: Terraform Apply"

    cd terraform

    echo "Applying Terraform configuration..."
    if terraform apply tfplan; then
        success "Terraform configuration applied successfully"
    else
        error "Terraform apply failed"
    fi

    cd ..
}

# Phase 3: Ansible Deployment
ansible_deploy() {
    log "Phase 3: Ansible Network Migration"

    cd ansible

    echo "Running network migration playbook..."
    if ansible-playbook -i inventory/hosts.ini playbooks/network-migration.yml; then
        success "Network migration completed successfully"
    else
        error "Network migration failed"
    fi

    cd ..
}

# Phase 4: Verification
verify_deployment() {
    log "Phase 4: Deployment Verification"

    cd ansible

    echo "Verifying deployment..."
    if ansible-playbook -i inventory/hosts.ini playbooks/verify-migration.yml; then
        success "Deployment verification completed"
    else
        warning "Deployment verification found issues - check logs"
    fi

    cd ..
}

# Rollback function
rollback() {
    warning "Starting rollback procedure..."

    cd ansible

    echo "Running rollback playbook..."
    if ansible-playbook -i inventory/hosts.ini playbooks/rollback-migration.yml; then
        success "Rollback completed successfully"
    else
        error "Rollback failed"
    fi

    cd ..
}

# Main deployment function
main() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    echo "==============================================="
    echo "🏠 HOME LAB INFRASTRUCTURE DEPLOYMENT"
    echo "==============================================="
    echo "Timestamp: $TIMESTAMP"
    echo "==============================================="

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --rollback)
                ROLLBACK=true
                shift
                ;;
            --skip-verification)
                SKIP_VERIFY=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done

    if [ "$ROLLBACK" = true ]; then
        echo "🔄 ROLLBACK MODE ENABLED"
        echo "This will revert network changes"
        read -p "Are you sure you want to rollback? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            echo "Rollback cancelled."
            exit 0
        fi
        rollback
        exit 0
    fi

    # Normal deployment flow
    check_prerequisites
    terraform_plan

    echo ""
    echo "📋 DEPLOYMENT PLAN READY"
    echo "The following changes will be made:"
    echo "- Xfinity Xfi: Bridge mode enabled"
    echo "- Asus Nighthawk: Primary router configured"
    echo "- Eero Mesh: Access point mode enabled"
    echo "- Unified network: 192.168.1.0/24"
    echo ""

    read -p "Do you want to proceed with deployment? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi

    terraform_apply
    ansible_deploy

    if [ "$SKIP_VERIFY" != true ]; then
        verify_deployment
    fi

    echo ""
    echo "==============================================="
    echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo "==============================================="
    echo ""
    echo "Next steps:"
    echo "1. Test Plex streaming from multiple devices"
    echo "2. Verify file transfers between all devices"
    echo "3. Check Grafana dashboards (http://192.168.1.11:3000)"
    echo "4. Update any static IP configurations"
    echo ""
    echo "If issues occur, rollback with:"
    echo "  ./deploy.sh --rollback"
    echo ""
    echo "Deployment logs saved in terraform/ and ansible/ directories"
}

# Show usage if requested
if [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then
    echo "Home Lab Infrastructure Deployment Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --rollback          Rollback network changes"
    echo "  --skip-verification Skip post-deployment verification"
    echo "  --help             Show this help message"
    echo ""
    echo "Prerequisites:"
    echo "  - Terraform installed"
    echo "  - Ansible installed"
    echo "  - terraform/terraform.tfvars configured"
    echo ""
    echo "For first-time setup:"
    echo "  1. Copy terraform/terraform.tfvars.example to terraform/terraform.tfvars"
    echo "  2. Edit terraform.tfvars with your router passwords"
    echo "  3. Run: $0"
    exit 0
fi

# Run main function
main "$@"
