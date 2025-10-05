variable "application_gateway_name" {
  description = "Name of the Application Gateway"
  type        = string
}

variable "public_ip_name" {
  description = "Name of the Public IP for Application Gateway"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Application Gateway"
  type        = string
}

variable "sku" {
  description = "SKU configuration for Application Gateway"
  type = object({
    name     = string
    tier     = string
    capacity = number
  })
  default = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
}

variable "ssl_certificate_name" {
  description = "Name for the SSL certificate"
  type        = string
  default     = "primary-cert"
}

variable "ssl_certificate_path" {
  description = "Path to the SSL certificate PFX file relative to module path (optional). If you provide an absolute path or omit, prefer using ssl_certificate_pfx_base64 instead."
  type        = string
  default     = ""
}

variable "ssl_certificate_pfx_base64" {
  description = "Optional: base64-encoded PFX contents. If provided this will be used instead of reading a file with filebase64()."
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssl_certificate_password" {
  description = "Password for the SSL certificate"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssl_policy" {
  description = "SSL policy configuration. Use null for Azure default policy"
  type = object({
    policy_type          = string
    min_protocol_version = string
    cipher_suites        = list(string)
  })
  default = {
    policy_type          = "Custom"
    min_protocol_version = "TLSv1_2"
    cipher_suites = [
      "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
      "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
      "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA",
      "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"
    ]
  }
}

variable "backend_pools" {
  description = "List of backend address pools"
  type = list(object({
    name = string
  }))
  default = [
    { name = "default-pool" }
  ]
}

variable "primary_backend_settings" {
  description = "Primary backend HTTP settings configuration"
  type = object({
    port            = number
    protocol        = string
    request_timeout = number
    host_name       = string
  })
  default = {
    port            = 443
    protocol        = "Https"
    request_timeout = 60
    host_name       = "api.example.com"
  }
}

variable "health_probe" {
  description = "Health probe configuration for primary backend"
  type = object({
    protocol            = string
    path                = string
    interval            = number
    timeout             = number
    unhealthy_threshold = number
    status_codes        = list(string)
  })
  default = {
    protocol            = "Https"
    path                = "/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    status_codes        = ["200"]
  }
}

variable "additional_hosts" {
  description = "Additional hosts configuration for multi-domain support"
  type = list(object({
    host_name             = string
    backend_settings_name = string
    backend_port          = optional(number, 443)
    backend_protocol      = optional(string, "Https")
    request_timeout       = optional(number, 60)
    cookie_affinity       = optional(bool, false)
    health_probe_path     = optional(string, "/")
    health_probe_codes    = optional(list(string), ["200"])
    priority_offset       = number
  }))
  default = []
}

variable "enable_http_to_https_redirect" {
  description = "Enable HTTP to HTTPS redirect"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
