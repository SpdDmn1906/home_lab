variable "environment" {
  description = "Environment name (e.g., production)"
  type        = string
  default     = "production"
}

variable "networks" {
  description = "Docker networks to create"
  type        = list(string)
  default     = []
}

variable "network_subnets" {
  description = "Optional subnet per network"
  type        = map(string)
  default     = {}
}

variable "volumes" {
  description = "Named Docker volumes to create"
  type        = map(object({}))
  default     = {}
}

variable "services" {
  description = "Docker services to run (managed by Terraform)"
  type = map(object({
    image       = string
    ports       = optional(list(string))
    environment = optional(list(string))
    volumes     = optional(list(string))
    networks    = optional(list(string))
    command     = optional(list(string))
    restart     = optional(string)
    labels      = optional(map(string))
    healthcheck = optional(object({
      test     = list(string)
      interval = optional(string)
      timeout  = optional(string)
      retries  = optional(number)
    }))
    cap_add      = optional(list(string))
    cap_drop     = optional(list(string))
    security_opt = optional(list(string))
    user         = optional(string)
    working_dir  = optional(string)
  }))
  default = {}
}


