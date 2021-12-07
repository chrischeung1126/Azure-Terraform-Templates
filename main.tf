# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_version = ">=0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.51.0"
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
  count               = var.vm_count
  name                = format("nic01-%s-${count.index+1}", var.vm_name_prefix)
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name

  ip_configuration {
    name                          = "ipconfig01"
    subnet_id                     = data.azurerm_subnet.existing.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.0.${count.index+5}"
    #Dynamic, Static
  }
}

resource "azurerm_windows_virtual_machine" "test" {
  count               = var.vm_count
  name                = format("%s-${count.index+1}", var.vm_name_prefix)
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureadmin"
  admin_password      = "P@ssw0rdP@ssw0rd"
  network_interface_ids = [element(azurerm_network_interface.test.*.id, count.index)]

  os_disk {
    name                 = format("disk01-%s-${count.index+1}",var.vm_name_prefix)
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  source_image_reference {
    publisher = "microsoftwindowsdesktop"
    offer     = "office-365"
    sku       = "20h2-evd-o365pp"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "domjoin" {
  count                 =  var.vm_count
  name                  = "domainjoin"
  virtual_machine_id    = element(azurerm_windows_virtual_machine.test.*.id, count.index)
  publisher             = "Microsoft.Compute"
  type                  = "JsonADDomainExtension"
  type_handler_version  = "1.3"

  settings = <<SETTINGS
  {
  "Name": "${data.azurerm_key_vault_secret.addc_domain.value}",
  "OUPath": "${data.azurerm_key_vault_secret.addc_ou_path.value}",
  "User": "${data.azurerm_key_vault_secret.addc_admin_username.value}",
  "Restart": "true",
  "Options": "3"
  }
  SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
  {
  "Password": "${data.azurerm_key_vault_secret.addc_admin_password.value}"
  }
PROTECTED_SETTINGS
} 

resource "azurerm_virtual_machine_extension" "addRemoteDesktopHostPool" {
    count                = var.vm_count
    name                 = "install_avd_agent"
    virtual_machine_id   = element(azurerm_windows_virtual_machine.test.*.id, count.index)
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.9"
    depends_on           = [azurerm_virtual_machine_extension.domjoin]

   protected_settings = <<SETTINGS
   {
     "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.tf.rendered)}')) | Out-File -filepath testaddHostpool.ps1\" && powershell -ExecutionPolicy Unrestricted -File testaddHostpool.ps1 ${data.azurerm_key_vault_secret.registration_token.value}"
   }
   SETTINGS
  }

  data "template_file" "tf" {
      template = file("testaddHostpool.ps1")
  }


