#!/bin/bash

# Home Lab Infrastructure Manager
# Unified script to manage infrastructure with Terraform and Ansible

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
# This script lives in scripts/root_utils/, so the repo root is two levels up.
# terraform/ and ansible/ live at the repo root, not next to this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TERRAFORM_DIR="$REPO_ROOT/terraform"
ANSIBLE_DIR="$REPO_ROOT/ansible"
LOG_FILE="/var/log/homelab/infrastructure_$(date +%Y%m%d_%H%M%S).log"

# Functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${CYAN}ℹ${NC} $1" | tee -a "$LOG_FILE"
}

header() {
    echo -e "${PURPLE}================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}================================================${NC}"
}

# Prerequisites check
check_prerequisites() {
    header "Checking Prerequisites"

    # Check Terraform
    if ! command -v terraform >/dev/null 2>&1; then
        error "Terraform is not installed. Please install Terraform first."
        echo "Visit: https://www.terraform.io/downloads.html"
        exit 1
    fi
    success "Terraform $(terraform version | head -1 | cut -d' ' -f2) found"

    # Check Ansible
    if ! command -v ansible >/dev/null 2>&1; then
        error "Ansible is not installed. Please install Ansible first."
        echo "Run: pip install ansible"
        exit 1
    fi
    success "Ansible $(ansible --version | head -1 | cut -d' ' -f2) found"

    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        warning "Docker is not installed or not running"
        echo "Please ensure Docker is installed and running"
    else
        success "Docker $(docker --version | cut -d' ' -f3 | cut -d',' -f1) found"
    fi

    # Check Git
    if ! command -v git >/dev/null 2>&1; then
        warning "Git is not installed"
        echo "Git is recommended for version control"
    else
        success "Git $(git --version | cut -d' ' -f3) found"
    fi

    echo ""
}

# Initialize infrastructure
init_infrastructure() {
    header "Initializing Infrastructure"

    # Create log directory
    sudo mkdir -p /var/log/homelab
    sudo chown $USER:$USER /var/log/homelab

    # Initialize Terraform
    log "Initializing Terraform..."
    cd "$TERRAFORM_DIR"
    if [ ! -f ".terraform.lock.hcl" ]; then
        terraform init
        success "Terraform initialized"
    else
        info "Terraform already initialized"
    fi

    # Initialize Ansible
    log "Checking Ansible configuration..."
    cd "$ANSIBLE_DIR"
    if [ ! -f "inventory/hosts.ini" ]; then
        warning "Ansible inventory not found"
        echo "Creating basic inventory..."
        mkdir -p inventory
        cat > inventory/hosts.ini << EOF
[local]
localhost ansible_connection=local

[media_server]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
        success "Basic Ansible inventory created"
    else
        success "Ansible inventory found"
    fi

    cd "$SCRIPT_DIR"
    echo ""
}

# Plan infrastructure changes
plan_infrastructure() {
    header "Planning Infrastructure Changes"

    cd "$TERRAFORM_DIR"
    log "Running Terraform plan..."
    terraform plan -out=tfplan -var-file=terraform.tfvars 2>&1 | tee -a "$LOG_FILE"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        success "Terraform plan completed successfully"
        info "Review the plan above and run 'deploy' to apply changes"
    else
        error "Terraform plan failed"
    fi

    cd "$SCRIPT_DIR"
    echo ""
}

# Deploy infrastructure
deploy_infrastructure() {
    header "Deploying Infrastructure"

    # Terraform apply
    cd "$TERRAFORM_DIR"
    log "Applying Terraform configuration..."
    terraform apply -auto-approve tfplan 2>&1 | tee -a "$LOG_FILE"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        success "Terraform deployment completed"
    else
        error "Terraform deployment failed"
    fi

    # Ansible deployment
    cd "$ANSIBLE_DIR"
    log "Running Ansible infrastructure setup..."
    ansible-playbook -i inventory/hosts.ini playbooks/infrastructure-setup.yml 2>&1 | tee -a "$LOG_FILE"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        success "Ansible deployment completed"
    else
        error "Ansible deployment failed"
    fi

    cd "$SCRIPT_DIR"
    echo ""
}

# Verify deployment
verify_deployment() {
    header "Verifying Deployment"

    log "Running comprehensive health checks..."

    # Run network test
    NETWORK_TEST="$REPO_ROOT/scripts/diagnostics/comprehensive_network_test.sh"
    if [ -f "$NETWORK_TEST" ]; then
        "$NETWORK_TEST" | tee -a "$LOG_FILE"
    fi

    # Check Docker services
    log "Checking Docker services..."
    if command -v docker >/dev/null 2>&1; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tee -a "$LOG_FILE"
    fi

    # Check service endpoints
    log "Checking service endpoints..."
    services=(
        "http://localhost:3000/api/health:Grafana"
        "http://localhost:9090/-/healthy:Prometheus"
        "http://localhost:32400/web:Plex"
    )

    for service in "${services[@]}"; do
        url=$(echo $service | cut -d: -f1)
        name=$(echo $service | cut -d: -f2)

        if curl -s --max-time 5 "$url" >/dev/null 2>&1; then
            success "$name is accessible"
        else
            warning "$name is not accessible"
        fi
    done

    success "Verification completed"
    echo ""
}

# Backup infrastructure state
backup_infrastructure() {
    header "Backing Up Infrastructure State"

    BACKUP_DIR="/mnt/backup/infrastructure_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    log "Backing up Terraform state..."
    cp -r "$TERRAFORM_DIR/.terraform" "$BACKUP_DIR/terraform_state/"
    cp "$TERRAFORM_DIR/terraform.tfstate"* "$BACKUP_DIR/"

    log "Backing up Ansible configuration..."
    cp -r "$ANSIBLE_DIR" "$BACKUP_DIR/ansible_backup/"

    log "Backing up Docker configurations..."
    docker system info > "$BACKUP_DIR/docker_info.txt" 2>/dev/null || true
    docker ps -a --format json > "$BACKUP_DIR/docker_containers.json" 2>/dev/null || true

    success "Infrastructure backup completed: $BACKUP_DIR"
    echo ""
}

# Show status
show_status() {
    header "Infrastructure Status"

    echo "📊 Current Status:"
    echo ""

    # Terraform state
    if [ -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
        cd "$TERRAFORM_DIR"
        terraform state list 2>/dev/null | head -10
        cd "$SCRIPT_DIR"
    else
        echo "Terraform: Not initialized"
    fi

    echo ""

    # Docker services
    if command -v docker >/dev/null 2>&1; then
        echo "🐳 Docker Services:"
        docker ps --format "table {{.Names}}\t{{.Status}}" | head -10
    fi

    echo ""

    # Network status
    echo "🌐 Network Status:"
    ip route show | grep default | head -1
    echo "IP: $(hostname -I 2>/dev/null || echo 'Unknown')"

    echo ""

    # Disk usage
    echo "💾 Storage Status:"
    df -h / | tail -1

    echo ""
}

# Show help
show_help() {
    header "Home Lab Infrastructure Manager"

    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  init      Initialize infrastructure (Terraform + Ansible)"
    echo "  plan      Plan infrastructure changes (Terraform only)"
    echo "  deploy    Deploy infrastructure changes"
    echo "  verify    Verify deployment health"
    echo "  backup    Backup infrastructure state"
    echo "  status    Show current infrastructure status"
    echo "  destroy   Destroy infrastructure (CAUTION!)"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 init              # First-time setup"
    echo "  $0 plan && $0 deploy # Plan and deploy changes"
    echo "  $0 verify            # Check everything is working"
    echo ""
    echo "Configuration:"
    echo "  - Terraform: terraform/terraform.tfvars"
    echo "  - Ansible: ansible/playbooks/vars/"
    echo "  - Logs: /var/log/homelab/"
    echo ""
}

# Destroy infrastructure (CAUTION!)
destroy_infrastructure() {
    header "⚠️  DESTROYING INFRASTRUCTURE ⚠️"

    echo "This will destroy all managed infrastructure!"
    echo "This includes Docker containers, networks, and configurations."
    echo ""
    read -p "Are you sure? Type 'DESTROY' to confirm: " confirm

    if [ "$confirm" != "DESTROY" ]; then
        echo "Destroy cancelled."
        exit 0
    fi

    # Backup first
    backup_infrastructure

    # Terraform destroy
    cd "$TERRAFORM_DIR"
    log "Destroying Terraform resources..."
    terraform destroy -auto-approve 2>&1 | tee -a "$LOG_FILE"

    # Clean up Docker
    log "Cleaning up Docker resources..."
    docker system prune -af 2>/dev/null || true

    success "Infrastructure destroyed"
    warning "Backup created in /mnt/backup/"
    echo ""
}

# Main script logic
main() {
    case "${1:-help}" in
        "init")
            check_prerequisites
            init_infrastructure
            success "Infrastructure initialized successfully"
            echo "Next steps:"
            echo "1. Edit terraform/terraform.tfvars with your settings"
            echo "2. Run '$0 plan' to see planned changes"
            echo "3. Run '$0 deploy' to apply changes"
            ;;
        "plan")
            check_prerequisites
            plan_infrastructure
            ;;
        "deploy")
            check_prerequisites
            deploy_infrastructure
            verify_deployment
            ;;
        "verify")
            verify_deployment
            ;;
        "backup")
            backup_infrastructure
            ;;
        "status")
            show_status
            ;;
        "destroy")
            destroy_infrastructure
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"


