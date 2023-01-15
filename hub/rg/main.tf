resource "azurerm_resource_group" "hub-rg" {
  name     = "rg-${var.customer-name}-qtr-hub-01"
  location = var.hub-location
  tags = {
    environment = "Hub"
  }
}

