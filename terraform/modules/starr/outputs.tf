output "starr_services" {
  description = "STARR stack services managed by Terraform"
  value = {
    qbittorrentvpn = {
      id     = docker_container.qbittorrentvpn.id
      name   = docker_container.qbittorrentvpn.name
      status = "managed_by_terraform"
    }
    radarr = {
      id     = docker_container.radarr.id
      name   = docker_container.radarr.name
      status = "managed_by_terraform"
    }
    sonarr = {
      id     = docker_container.sonarr.id
      name   = docker_container.sonarr.name
      status = "managed_by_terraform"
    }
    prowlarr = {
      id     = docker_container.prowlarr.id
      name   = docker_container.prowlarr.name
      status = "managed_by_terraform"
    }
    flaresolverr = {
      id     = docker_container.flaresolverr.id
      name   = docker_container.flaresolverr.name
      status = "managed_by_terraform"
    }
    bazarr = {
      id     = docker_container.bazarr.id
      name   = docker_container.bazarr.name
      status = "managed_by_terraform"
    }
  }
}

output "service_urls" {
  description = "Web UI URLs for STARR services"
  value = {
    qbittorrent = "http://192.168.1.11:8080"
    radarr      = "http://192.168.1.11:7878"
    sonarr      = "http://192.168.1.11:8989"
    prowlarr    = "http://192.168.1.11:9696"
    flaresolverr = "http://192.168.1.11:8191"
    bazarr      = "http://192.168.1.11:6767"
  }
}
