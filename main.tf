# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_version = ">=0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

#  resource "azurerm_resource_group" "test" {
#    name     = var.rgName
#    location = var.location
#  }

#  resource "azurerm_virtual_network" "test" {
#    name                     = var.vNet
#    address_space            = ["10.0.0.0/22"]
#    location                 = azurerm_resource_group.test.location
#    resource_group_name = azurerm_resource_group.test.name
#  }

#  resource "azurerm_subnet" "test" {
#    name                     = var.subnetName
#    resource_group_name      = azurerm_resource_group.test.name
#    virtual_network_name     = azurerm_virtual_network.test.name
#    address_prefixes         = ["10.0.0.0/24"]
#  }

#  resource "azurerm_public_ip" "test" {
#    name                     = var.public_ip_name
#    location                 = data.azurerm_resource_group.existing.location
#    resource_group_name      = data.azurerm_resource_group.existing.name
#    allocation_method        = var.public_ip_allocation_method
#  }

#   resource "azurerm_lb" "test" {
#    name                = "loadBalancer"
#    location            = azurerm_resource_group.test.location
#    resource_group_name = azurerm_resource_group.test.name

#    frontend_ip_configuration {
#      name                 = "publicIPAddress"
#      public_ip_address_id = azurerm_public_ip.test.id
#    }
#  }

#  resource "azurerm_lb_backend_address_pool" "test" {
#    loadbalancer_id     = azurerm_lb.test.id
#    name                = "BackEndAddressPool"
#  }

resource "azurerm_network_interface" "test" {
  count               = length(var.vm_name_list)
  name                = format("%s-%s", var.network_interface_name, element(var.vm_name_list, count.index))
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name

  ip_configuration {
    name                          = var.network_interface_ip_config_name
    subnet_id                     = data.azurerm_subnet.existing.id
    private_ip_address_allocation = var.network_interface_ip_allocation_method
    private_ip_address = "10.0.0.${count.index+5}"
    #Dynamic, Static
  }
}

resource "azurerm_windows_virtual_machine" "test" {
  count               = length(var.vm_name_list)
  name                = element(var.vm_name_list, count.index)
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  network_interface_ids = [element(azurerm_network_interface.test.*.id, count.index)]

  os_disk {
    name                 = format("%s-%s", var.os_disk_name, element(var.vm_name_list, count.index))
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }
  
  source_image_reference {
    publisher = "microsoftwindowsdesktop"
    offer     = "office-365"
    sku       = "19h2-evd-o365pp"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "domjoin" {
  count                 = length(var.vm_name_list)
  name                  = "domjoin"
  virtual_machine_id    = element(azurerm_windows_virtual_machine.test.*.id, count.index)
  publisher             = "Microsoft.Compute"
  type                  = "JsonADDomainExtension"
  type_handler_version  = "1.3"

  settings = <<SETTINGS
  {
  "Name": "gtidevops.onmicrosoft.com",
  "OUPath": "${var.addc_ou_path}",
  "User": "${var.addc_admin_username}",
  "Restart": "true",
  "Options": "3"
  }
  SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
  {
  "Password": "${var.addc_admin_password}"
  }
PROTECTED_SETTINGS
} 


