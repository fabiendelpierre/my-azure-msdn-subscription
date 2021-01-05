resource "azurerm_resource_group" "msdn_sandbox" {
  name     = "${var.base_name}-rg"
  location = var.azure_region

  tags = local.tags
}

resource "azurerm_dns_zone" "msdn_sandbox" {
  name                = var.sandbox_domain_name
  resource_group_name = azurerm_resource_group.msdn_sandbox.name

  tags = local.tags
}

module "virtual_network" {
  source  = "app.terraform.io/fabiend/virtualnetwork/azurerm"
  version = "0.4.0"

  base_name = var.base_name

  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  location            = var.azure_region

  vnet_cidr = var.vnet_cidr

  tags = local.tags
}

module "key_vault" {
  source  = "app.terraform.io/fabiend/keyvault/azurerm"
  version = "0.1.0"

  base_name = var.base_name

  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  location            = var.azure_region

  authorized_entities   = var.authorized_entities
  authorized_cidrs      = var.authorized_cidrs
  authorized_subnet_ids = [module.virtual_network.subnet_id]

  tags = local.tags
}

module "vault_vm" {
  source = "./vault-vm"

  base_name = var.base_name

  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  location            = var.azure_region

  vnet_name      = module.virtual_network.vnet_name
  subnet_name    = module.virtual_network.subnet_name
  nsg_name       = module.virtual_network.nsg_name
  dns_zone_name  = azurerm_dns_zone.msdn_sandbox.name
  key_vault_name = module.key_vault.name

  my_ip_addresses = var.authorized_cidrs

  tags = local.tags
}