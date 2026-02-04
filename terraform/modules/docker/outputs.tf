output "service_status" {
  description = "Docker services managed by Terraform"
  value = {
    for name, c in docker_container.services : name => {
      id     = c.id
      name   = c.name
      image  = c.image
      status = "managed_by_terraform"
    }
  }
}


