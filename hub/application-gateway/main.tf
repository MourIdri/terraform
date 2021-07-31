resource "azurerm_public_ip" "appgw-pip" {
  name                = "pip-appgw"
  resource_group_name = var.rg-name
  location            = var.rg-location
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    environment = "Hub"
  }
}

#since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${var.vnet-name}-beap"
  frontend_port_name             = "${var.vnet-name}-feport"
  frontend_ip_configuration_name = "${var.vnet-name}-feip"
  http_setting_name              = "${var.vnet-name}-be-htst"
  listener_name                  = "${var.vnet-name}-httplstn"
  request_routing_rule_name      = "${var.vnet-name}-rqrt"
  redirect_configuration_name    = "${var.vnet-name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "agw-hub-01"
  resource_group_name = var.rg-name
  location            = var.rg-location

  tags = {
    environment = "Hub"
  }


  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  waf_configuration {
    enabled    = true
    firewall_mode = "Prevention"
    max_request_body_size_kb = 16
    rule_set_version  = 3.1
    rule_set_type = "OWASP"
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.appgw-snet-id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw-pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}
