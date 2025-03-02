resource "azurerm_linux_virtual_machine" "vm-jumpbox-1" {
  name                = "linjumpserver1"
  resource_group_name = var.rg-name
  location            = var.rg-location
  size                = "Standard_D2s_v4"
  admin_username      = var.linux-admin-userid
  admin_password      = var.linux-admin-password
  disable_password_authentication  = "false"

  network_interface_ids = [
    var.nic-linjumpserver1-id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "da" {
  name                       = "DAExtension"
  virtual_machine_id         =  azurerm_linux_virtual_machine.vm-jumpbox-1.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "workspaceId" : "${var.la-workspace-id}"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "workspaceKey" : "${var.la-workspace-key}"
    }
  PROTECTED_SETTINGS
}

#===================================================================
# Set Monitoring and Log Analytics Workspace
#===================================================================
resource "azurerm_virtual_machine_extension" "oms_mma02" {
  name                       = "test-OMSExtension"
 virtual_machine_id         =  azurerm_linux_virtual_machine.vm-jumpbox-1.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.12"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "workspaceId" : "${var.la-workspace-id}"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "workspaceKey" : "${var.la-workspace-key}"
    }
  PROTECTED_SETTINGS
}


resource "azurerm_windows_virtual_machine" "vm-jumpbox-2" {
  name                = "winjumpserver1"
  resource_group_name = var.rg-name
  location            = var.rg-location
  size                = "Standard_D2s_v4"
  admin_username      = var.windows-admin-userid
  admin_password      = var.windows-admin-password
  network_interface_ids = [
    var.nic-winjumpserver1-id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

#--------------------------------------------------------------
# Azure Log Analytics Workspace Agent Installation for windows
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "omsagentwin" {
  name                       = "OMS_Extension_Windows"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm-jumpbox-2.id 
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "workspaceId": "${var.la-workspace-id}"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
    "workspaceKey": "${var.la-workspace-key}"
    }
  PROTECTED_SETTINGS
}


resource "azurerm_virtual_machine_extension" "monitor-DependencyAgent-agent" {
  name                  = "DAExtensionWindows"
  virtual_machine_id    =  azurerm_windows_virtual_machine.vm-jumpbox-2.id
  publisher             = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                  = "DependencyAgentWindows"
  type_handler_version  = "9.5"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
        {
          "workspaceId": "${var.la-workspace-id}"
        }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
        {
          "workspaceKey": "{var.la-workspace-key}"
        }
  PROTECTED_SETTINGS
}


resource "azurerm_virtual_machine_extension" "antimalware-agent" {
    name                       = "AntimalwareAgentWindows"
    virtual_machine_id    =  azurerm_windows_virtual_machine.vm-jumpbox-2.id
    publisher                  = "Microsoft.Azure.Security"
    type                       = "IaaSAntimalware"
    type_handler_version       = "1.3"
    auto_upgrade_minor_version = "true"

    settings = <<SETTINGS
    {
      "AntimalwareEnabled": true,
      "RealtimeProtectionEnabled": "true",
      "ScheduledScanSettings": {
      "isEnabled": "true",
      "day": "1",
      "time": "120",
      "scanType": "Quick"
      },
      "Exclusions": {
      }
    }
  SETTINGS
}

