# Home Lab Infrastructure as Code - Terraform Configuration
# Focus: manage Docker containers on the media server using Terraform.
#
# IMPORTANT:
# - Terraform can reliably manage **Docker resources** on the server.
# - Consumer-router config (VLAN/DHCP/etc.) typically requires vendor APIs; keep that in docs/Ansible.

terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "local" {}

data "local_file" "ansible_inventory" {
  filename = "../ansible/inventory/hosts.ini"
}

module "docker_services" {
  source = "./modules/docker"

  environment     = var.environment
  networks        = var.docker_networks
  network_subnets = var.docker_network_subnets
  volumes         = var.docker_volumes
  services        = var.docker_services

  depends_on = [data.local_file.ansible_inventory]
}

/*
module "adguard" {
  count  = var.features.enable_adguard ? 1 : 0
  source = "./modules/adguard"

  timezone       = var.system.timezone
  admin_username = var.adguard.admin_username
  admin_password = var.adguard.admin_password

  enable_unbound = true
  unbound_port   = 5335

  upstream_dns = [
    "1.1.1.1",
    "1.0.0.1",
    "8.8.8.8",
    "8.8.4.4"
  ]

  enable_dhcp = false

  lan_dns_records = [
    { hostname = "plex", ip = "192.168.1.11" },
    { hostname = "nas", ip = "192.168.1.20" },
    { hostname = "grafana", ip = "192.168.1.11" },
    { hostname = "prometheus", ip = "192.168.1.11" },
    { hostname = "adguard", ip = "192.168.1.11" }
  ]

  ipv4_address = "192.168.1.11"
}

module "parental_controls" {
  count  = var.features.enable_parental_controls ? 1 : 0
  source = "./modules/parental-controls"

  alert_email = var.monitoring.alert_email

  depends_on = [module.adguard]
}

module "remote_access" {
  count  = var.features.enable_remote_access ? 1 : 0
  source = "./modules/remote-access"

  enable_wireguard = true
  enable_guacamole = true
  enable_ssh_jump  = true

  enable_reverse_proxy = true
  letsencrypt_email    = var.monitoring.alert_email
}

module "ai_assistant" {
  count  = var.features.enable_ai_assistant ? 1 : 0
  source = "./modules/ai-assistant"

  enable_ollama          = true
  enable_voice_interface = true
  enable_web_interface   = true
  enable_home_assistant  = true
  enable_node_red        = true

  ollama_models = [
    "llama2:7b-chat",
    "mistral:7b-instruct",
    "codellama:7b-instruct"
  ]
}
*/

module "starr" {
  count  = var.features.enable_starr ? 1 : 0
  source = "./modules/starr"

  environment = var.environment
  timezone    = var.system.timezone
  puid        = var.starr.puid
  pgid        = var.starr.pgid

  # VPN Configuration
  vpn_service_provider = var.starr.vpn_service_provider
  vpn_server_regions   = var.starr.vpn_server_regions
  gluetun_config_path  = var.starr.gluetun_config_path

  # qBittorrent Configuration
  qbittorrent_config_path  = var.starr.qbittorrent_config_path
  qbittorrent_downloads_path = var.starr.qbittorrent_downloads_path
  qbittorrent_torrents_path = var.starr.qbittorrent_torrents_path
  external_media_path      = var.starr.external_media_path

  # Radarr Configuration
  radarr_config_path = var.starr.radarr_config_path
  media_root_path    = var.starr.media_root_path
  synology_path      = var.starr.synology_path

  # Sonarr Configuration
  sonarr_config_path = var.starr.sonarr_config_path

  # Prowlarr Configuration
  prowlarr_config_path = var.starr.prowlarr_config_path

  # FlareSolverr Configuration
  flaresolverr_config_path = var.starr.flaresolverr_config_path
}

output "docker_services" {
  description = "Docker services managed by Terraform"
  value       = module.docker_services.service_status
}

output "starr_services" {
  description = "STARR stack services managed by Terraform"
  value       = var.features.enable_starr ? module.starr[0].starr_services : {}
}