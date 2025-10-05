locals {
  gateway_ip_config_name   = "gateway-ip-config"
  frontend_ip_config_name  = "frontend-ip-config"
  http_port_name           = "http-port"
  https_port_name          = "https-port"
  http_listener_name       = "http-listener"
  https_listener_name      = "https-listener"
  primary_backend_settings = "primary-backend-settings"
  primary_probe_name       = "primary-probe"
  http_to_https_redirect   = "http-to-https-redirect"

  # Standard ports
  http_port  = 80
  https_port = 443

  # Routing rule priorities
  primary_https_priority = 10
  primary_http_priority  = 100
  additional_http_base   = 20
  additional_https_base  = 30
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "agw" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = var.application_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.sku.capacity
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_config_name
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = local.http_port_name
    port = local.http_port
  }

  frontend_port {
    name = local.https_port_name
    port = local.https_port
  }

  dynamic "ssl_certificate" {
    for_each = length(var.ssl_certificate_pfx_base64) > 0 || (var.ssl_certificate_path != "" && var.ssl_certificate_path != null) ? [1] : []
    content {
      name     = var.ssl_certificate_name
      data     = length(var.ssl_certificate_pfx_base64) > 0 ? var.ssl_certificate_pfx_base64 : filebase64("${path.module}/${trim(var.ssl_certificate_path, "/")}")
      password = var.ssl_certificate_password
    }
  }

  ssl_policy {
    policy_type          = var.ssl_policy.policy_type
    min_protocol_version = var.ssl_policy.min_protocol_version
    cipher_suites        = var.ssl_policy.cipher_suites
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_config_name
    public_ip_address_id = azurerm_public_ip.agw.id
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_pools
    content {
      name = backend_address_pool.value.name
    }
  }

  # Primary health probe
  probe {
    name                                      = local.primary_probe_name
    protocol                                  = var.health_probe.protocol
    path                                      = var.health_probe.path
    pick_host_name_from_backend_http_settings = false
    host                                      = var.primary_backend_settings.host_name
    interval                                  = var.health_probe.interval
    timeout                                   = var.health_probe.timeout
    unhealthy_threshold                       = var.health_probe.unhealthy_threshold
    minimum_servers                           = 0
    match {
      status_code = var.health_probe.status_codes
    }
  }

  # Primary backend HTTP settings
  backend_http_settings {
    name                                = local.primary_backend_settings
    cookie_based_affinity               = "Disabled"
    port                                = var.primary_backend_settings.port
    protocol                            = var.primary_backend_settings.protocol
    request_timeout                     = var.primary_backend_settings.request_timeout
    probe_name                          = local.primary_probe_name
    host_name                           = var.primary_backend_settings.host_name
    pick_host_name_from_backend_address = false
  }

  # HTTP listener
  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_config_name
    frontend_port_name             = local.http_port_name
    protocol                       = "Http"
  }

  # HTTPS listener (only created when a certificate is provided)
  dynamic "http_listener" {
    for_each = length(var.ssl_certificate_pfx_base64) > 0 || (var.ssl_certificate_path != "" && var.ssl_certificate_path != null) ? [1] : []
    content {
      name                           = local.https_listener_name
      frontend_ip_configuration_name = local.frontend_ip_config_name
      frontend_port_name             = local.https_port_name
      ssl_certificate_name           = var.ssl_certificate_name
      protocol                       = "Https"
      host_name                      = var.primary_backend_settings.host_name
    }
  }

  # HTTP to HTTPS redirect (optional)
  # HTTP -> HTTPS redirect: only create when redirect enabled AND certificate present
  dynamic "redirect_configuration" {
    for_each = var.enable_http_to_https_redirect && (length(var.ssl_certificate_pfx_base64) > 0 || (var.ssl_certificate_path != "" && var.ssl_certificate_path != null)) ? [1] : []
    content {
      name                 = local.http_to_https_redirect
      redirect_type        = "Permanent"
      target_listener_name = local.https_listener_name
      include_path         = true
      include_query_string = true
    }
  }

  # Primary HTTPS routing rule
  # Primary HTTPS routing rule (only when cert exists)
  dynamic "request_routing_rule" {
    for_each = length(var.ssl_certificate_pfx_base64) > 0 || (var.ssl_certificate_path != "" && var.ssl_certificate_path != null) ? [1] : []
    content {
      name                       = "primary-https-rule"
      rule_type                  = "Basic"
      http_listener_name         = local.https_listener_name
      backend_address_pool_name  = var.backend_pools[0].name
      backend_http_settings_name = local.primary_backend_settings
      priority                   = local.primary_https_priority
    }
  }

  # Primary HTTP routing rule (redirect or route to backend)
  request_routing_rule {
    name                        = "primary-http-rule"
    rule_type                   = "Basic"
    http_listener_name          = local.http_listener_name
    backend_address_pool_name   = (!var.enable_http_to_https_redirect || (var.enable_http_to_https_redirect && !(length(var.ssl_certificate_pfx_base64) > 0 || (var.ssl_certificate_path != "" && var.ssl_certificate_path != null)))) ? var.backend_pools[0].name : null
    backend_http_settings_name  = (!var.enable_http_to_https_redirect || (var.enable_http_to_https_redirect && !(length(var.ssl_certificate_pfx_base64) > 0 || (var.ssl_certificate_path != "" && var.ssl_certificate_path != null)))) ? local.primary_backend_settings : null
    redirect_configuration_name = var.enable_http_to_https_redirect && (length(var.ssl_certificate_pfx_base64) > 0 || (var.ssl_certificate_path != "" && var.ssl_certificate_path != null)) ? local.http_to_https_redirect : null
    priority                    = local.primary_http_priority
  }

  # Dynamic HTTP listeners for additional hosts
  dynamic "http_listener" {
    for_each = var.additional_hosts
    content {
      name                           = "${http_listener.value.host_name}-http"
      frontend_ip_configuration_name = local.frontend_ip_config_name
      frontend_port_name             = local.http_port_name
      protocol                       = "Http"
      host_name                      = http_listener.value.host_name
    }
  }

  # Dynamic HTTPS listeners for additional hosts
  dynamic "http_listener" {
    for_each = var.additional_hosts
    content {
      name                           = "${http_listener.value.host_name}-https"
      frontend_ip_configuration_name = local.frontend_ip_config_name
      frontend_port_name             = local.https_port_name
      ssl_certificate_name           = var.ssl_certificate_name
      protocol                       = "Https"
      host_name                      = http_listener.value.host_name
    }
  }

  # Dynamic backend HTTP settings for additional hosts
  dynamic "backend_http_settings" {
    for_each = var.additional_hosts
    content {
      name                                = backend_http_settings.value.backend_settings_name
      cookie_based_affinity               = backend_http_settings.value.cookie_affinity ? "Enabled" : "Disabled"
      port                                = backend_http_settings.value.backend_port
      protocol                            = backend_http_settings.value.backend_protocol
      request_timeout                     = backend_http_settings.value.request_timeout
      probe_name                          = "${backend_http_settings.value.host_name}-probe"
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = false
      affinity_cookie_name                = backend_http_settings.value.cookie_affinity ? "ApplicationGatewayAffinity" : null
    }
  }

  # Dynamic health probes for additional hosts
  dynamic "probe" {
    for_each = var.additional_hosts
    content {
      name                                      = "${probe.value.host_name}-probe"
      protocol                                  = probe.value.backend_protocol
      path                                      = probe.value.health_probe_path
      pick_host_name_from_backend_http_settings = false
      host                                      = probe.value.host_name
      interval                                  = 30
      timeout                                   = 30
      unhealthy_threshold                       = 3
      minimum_servers                           = 0
      match {
        status_code = probe.value.health_probe_codes
      }
    }
  }

  # Dynamic HTTP routing rules for additional hosts
  dynamic "request_routing_rule" {
    for_each = var.additional_hosts
    content {
      name                       = "${request_routing_rule.value.host_name}-http-rule"
      rule_type                  = "Basic"
      http_listener_name         = "${request_routing_rule.value.host_name}-http"
      backend_address_pool_name  = var.backend_pools[0].name
      backend_http_settings_name = request_routing_rule.value.backend_settings_name
      priority                   = local.additional_http_base + request_routing_rule.value.priority_offset
    }
  }

  # Dynamic HTTPS routing rules for additional hosts
  dynamic "request_routing_rule" {
    for_each = var.additional_hosts
    content {
      name                       = "${request_routing_rule.value.host_name}-https-rule"
      rule_type                  = "Basic"
      http_listener_name         = "${request_routing_rule.value.host_name}-https"
      backend_address_pool_name  = var.backend_pools[0].name
      backend_http_settings_name = request_routing_rule.value.backend_settings_name
      priority                   = local.additional_https_base + request_routing_rule.value.priority_offset
    }
  }

  tags = var.tags
}
