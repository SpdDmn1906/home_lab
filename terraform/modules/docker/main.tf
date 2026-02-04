# Docker Services Module
# Manages Docker containers and services

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Docker networks
resource "docker_network" "networks" {
  for_each = toset(var.networks)

  name = each.key
  driver = "bridge"

  ipam_config {
    subnet = lookup(var.network_subnets, each.key, "172.20.0.0/16")
  }
}

# Docker containers
resource "docker_container" "services" {
  for_each = var.services

  name  = each.key
  image = each.value.image

  # Ports
  dynamic "ports" {
    for_each = lookup(each.value, "ports", [])
    content {
      # Format supported: "external:internal" or "external:internal/udp"
      # Examples:
      # - "32400:32400"
      # - "53:53/udp"
      external = tonumber(split(":", split("/", ports.value)[0])[0])
      internal = tonumber(split(":", split("/", ports.value)[0])[1])
      protocol = length(split("/", ports.value)) > 1 ? split("/", ports.value)[1] : "tcp"
    }
  }

  # Environment variables (provider expects list(string) of "KEY=value")
  env = lookup(each.value, "environment", [])

  # Volumes
  dynamic "volumes" {
    for_each = lookup(each.value, "volumes", [])
    content {
      host_path      = split(":", volumes.value)[0]
      container_path = split(":", volumes.value)[1]
      read_only      = length(split(":", volumes.value)) > 2 ? split(":", volumes.value)[2] == "ro" : false
    }
  }

  # Networks
  dynamic "networks_advanced" {
    for_each = lookup(each.value, "networks", [])
    content {
      name = networks_advanced.value
    }
  }

  # Command
  command = lookup(each.value, "command", [])

  # Restart policy
  restart = lookup(each.value, "restart", "unless-stopped")

  # Labels
  dynamic "labels" {
    for_each = coalesce(lookup(each.value, "labels", {}), {})
    content {
      label = labels.key
      value = labels.value
    }
  }

  # Health check
  dynamic "healthcheck" {
    for_each = lookup(each.value, "healthcheck", null) != null ? [each.value.healthcheck] : []
    content {
      test     = healthcheck.value.test
      interval = lookup(healthcheck.value, "interval", "30s")
      timeout  = lookup(healthcheck.value, "timeout", "10s")
      retries  = lookup(healthcheck.value, "retries", 3)
    }
  }

  # Capabilities
  capabilities {
    add  = lookup(each.value, "cap_add", [])
    drop = lookup(each.value, "cap_drop", [])
  }

  # Security options
  security_opts = lookup(each.value, "security_opt", [])

  # User
  user = lookup(each.value, "user", null)

  # Working directory
  working_dir = lookup(each.value, "working_dir", null)

  # Dependencies
  depends_on = [
    docker_network.networks
  ]

  # Lifecycle management
  #
  # Terraform should be the authoritative manager for containers.
  # Do not ignore image/env changes by default, otherwise drift persists silently.
}

# Docker volumes
resource "docker_volume" "volumes" {
  for_each = var.volumes

  name = each.key

  labels {
    label = "environment"
    value = var.environment
  }
  labels {
    label = "managed_by"
    value = "terraform"
  }
}

# Service status monitoring
resource "local_file" "docker_compose_override" {
  filename = "${path.module}/docker-compose.override.yml"
  content = yamlencode({
    version = "3.8"
    services = {
      for name, service in var.services : name => {
        labels = [
          "traefik.enable=true",
          "traefik.http.routers.${name}.rule=Host(`${name}.homelab.local`)",
          "traefik.http.services.${name}.loadbalancer.server.port=${lookup(service, "internal_port", 80)}"
        ]
      }
    }
  })
}

# Generate service inventory
resource "local_file" "service_inventory" {
  filename = "${path.module}/service_inventory.json"
  content = jsonencode({
    timestamp = timestamp()
    environment = var.environment
    services = {
      for name, service in var.services : name => {
        image = service.image
        ports = lookup(service, "ports", [])
        status = "managed_by_terraform"
        networks = lookup(service, "networks", [])
        health = "unknown"
      }
    }
    networks = var.networks
    volumes = keys(var.volumes)
  })
}

# Service health monitoring (template optional; enable if templates/health_check.sh.tpl exists)
# resource "local_file" "health_check_script" {
#   filename = "${path.module}/health_check.sh"
#   content = templatefile("${path.module}/templates/health_check.sh.tpl", { services = keys(var.services) })
#   provisioner "local-exec" { command = "chmod +x ${self.filename}" }
# }


