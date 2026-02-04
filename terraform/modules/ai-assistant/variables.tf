# AI Assistant Module Variables

variable "network_name" {
  description = "Docker network name"
  type        = string
  default     = "homelab"
}

variable "timezone" {
  description = "Timezone for the assistant"
  type        = string
  default     = "America/New_York"
}

# Ollama LLM Configuration
variable "enable_ollama" {
  description = "Enable Ollama LLM service"
  type        = bool
  default     = true
}

variable "ollama_data_path" {
  description = "Path for Ollama model data"
  type        = string
  default     = "/opt/ollama/models"
}

variable "ollama_max_models" {
  description = "Maximum number of models to keep loaded"
  type        = number
  default     = 3
}

variable "ollama_max_queue" {
  description = "Maximum queue size for requests"
  type        = number
  default     = 512
}

variable "enable_gpu" {
  description = "Enable GPU acceleration for LLM"
  type        = bool
  default     = false
}

variable "ollama_models" {
  description = "LLM models to preload"
  type        = list(string)
  default = [
    "llama2:7b",
    "codellama:7b",
    "mistral:7b"
  ]
}

# AI Assistant Backend
variable "assistant_config_path" {
  description = "Path for assistant configuration"
  type        = string
  default     = "/opt/ai-assistant/config"
}

variable "assistant_data_path" {
  description = "Path for assistant data and logs"
  type        = string
  default     = "/opt/ai-assistant/data"
}

variable "log_level" {
  description = "Logging level"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR"
  }
}

# Voice Interface
variable "enable_voice_interface" {
  description = "Enable voice interface with Rhasspy"
  type        = bool
  default     = true
}

variable "rhasspy_config_path" {
  description = "Path for Rhasspy configuration"
  type        = string
  default     = "/opt/rhasspy"
}

variable "wake_word" {
  description = "Wake word for voice activation"
  type        = string
  default     = "hey assistant"
}

# Web Interface
variable "enable_web_interface" {
  description = "Enable web-based interface"
  type        = bool
  default     = true
}

variable "web_interface_path" {
  description = "Path for web interface application"
  type        = string
  default     = "/opt/ai-assistant/web"
}

# Home Automation Integration
variable "enable_home_assistant" {
  description = "Enable Home Assistant integration"
  type        = bool
  default     = true
}

variable "home_assistant_config_path" {
  description = "Path for Home Assistant configuration"
  type        = string
  default     = "/opt/home-assistant"
}

variable "home_assistant_url" {
  description = "Home Assistant instance URL"
  type        = string
  default     = "http://home-assistant:8123"
}

variable "home_assistant_token" {
  description = "Home Assistant long-lived access token"
  type        = string
  sensitive   = true
}

# Node-RED Integration
variable "enable_node_red" {
  description = "Enable Node-RED for automation workflows"
  type        = bool
  default     = true
}

variable "node_red_data_path" {
  description = "Path for Node-RED data"
  type        = string
  default     = "/opt/node-red"
}

# External API Integrations
variable "openweather_api_key" {
  description = "OpenWeather API key for weather information"
  type        = string
  sensitive   = true
}

# Assistant Capabilities
variable "assistant_capabilities" {
  description = "Enabled assistant capabilities"
  type = object({
    home_control     = bool
    weather_info     = bool
    reminders        = bool
    music_control    = bool
    device_status    = bool
    security_alerts  = bool
    parental_control = bool
    system_monitoring = bool
  })
  default = {
    home_control      = true
    weather_info      = true
    reminders         = true
    music_control     = true
    device_status     = true
    security_alerts   = true
    parental_control  = true
    system_monitoring = true
  }
}

# Privacy and Security
variable "privacy_settings" {
  description = "Privacy and security settings"
  type = object({
    local_only           = bool
    no_cloud_services    = bool
    encrypted_storage    = bool
    voice_data_retention = string
    conversation_logging = bool
  })
  default = {
    local_only           = true
    no_cloud_services    = true
    encrypted_storage    = true
    voice_data_retention = "24h"
    conversation_logging = false
  }
}

# Hardware Resources
variable "resource_limits" {
  description = "Resource limits for AI services"
  type = object({
    ollama_cpu_limit    = string
    ollama_memory_limit = string
    assistant_cpu_limit = string
    assistant_memory_limit = string
  })
  default = {
    ollama_cpu_limit      = "4"
    ollama_memory_limit   = "8g"
    assistant_cpu_limit   = "2"
    assistant_memory_limit = "2g"
  }
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable monitoring for AI services"
  type        = bool
  default     = true
}


