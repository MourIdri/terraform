resource "azurerm_virtual_network" "devtest-vnet" {
  name                = "${var.devtest-prefix}-vnet"
  location            = var.rg-location
  resource_group_name = var.rg-name
  address_space       = [var.devtest-vnet-address-space]

  tags = {
    environment = "DevTest"
  }
}

resource "azurerm_subnet" "spoke-app-subnet-001" {
  name                 = "snet-app-001"
  resource_group_name  = var.rg-name
  virtual_network_name = azurerm_virtual_network.devtest-vnet.name
  address_prefixes     = [var.app-subnet-address-space]
}

resource "azurerm_subnet" "spoke-db-subnet-001" {
  name                 = "snet-db-001"
  resource_group_name  = var.rg-name
  virtual_network_name = azurerm_virtual_network.devtest-vnet.name
  address_prefixes     = [var.db-subnet-address-space]
}
