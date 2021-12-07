# call existing resource group attributes examples:
# data.azurerm_resource_group.name
# data.azurerm_resource_group.location
data "azurerm_resource_group" "existing" {
    name = var.existing_resource_group_name
}
# call existing virtual network attributes examples:
# data.azurerm_virtual_network.name
# data.azurerm_virtual_network.location
# data.azurerm_virtual_network.address_space
# data.azurerm_virtual_network.dns_servers
# data.azurerm_virtual_network.guid
# data.azurerm_virtual_network.subnets
# data.azurerm_virtual_network.vnet_peerings
data "azurerm_virtual_network" "existing" {
    name                = var.existing_virtual_network_name
    resource_group_name = data.azurerm_resource_group.existing.name
}
# call existing subnet attributes examples:
# data.azurerm_subnet.id
# data.azurerm_subnet.address_prefixes
# data.azurerm_subnet.enforce_private_link_service_network_policies
# data.azurerm_subnet.network_security_group_id
# data.azurerm_subnet.route_table_id
# data.azurerm_subnet.service_endpoints
# data.azurerm_subnet.enforce_private_link_endpoint_network_policies
# data.azurerm_subnet.enforce_private_link_service_network_policies
data "azurerm_subnet" "existing" {
     name                 = var.existing_subnet_name
     virtual_network_name = data.azurerm_virtual_network.existing.name
     resource_group_name  = data.azurerm_resource_group.existing.name
}

data "azurerm_key_vault" "existing" {
  name                = "key-avd-lab-001"
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_key_vault_secret" "registration_token" {
  name         = "registration-token"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "addc_admin_password" {
  name         = "addc-admin-password"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "addc_admin_username" {
  name         = "addc-admin-username"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "addc_ou_path" {
  name         = "addc-ou-path"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "addc_domain" {
  name         = "addc-domain"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "mytest" {
  name         = "mytest"
  key_vault_id = data.azurerm_key_vault.existing.id
}