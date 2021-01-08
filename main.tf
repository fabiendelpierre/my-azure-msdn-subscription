data "azurerm_client_config" "current" {}

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
  version = "0.2.1"

  base_name = var.base_name

  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  location            = var.azure_region
  authorized_entities = var.authorized_entities

  tags = local.tags
}

module "storage_account" {
  source  = "app.terraform.io/fabiend/storageaccount/azurerm"
  version = "0.3.0"

  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  location            = var.azure_region
  base_name           = var.base_name

  tags = local.tags
}

module "vault_vm" {
  source = "./vault-vm"

  base_name = var.base_name

  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  location            = var.azure_region

  vault_version  = var.vault_version
  vault_hostname = var.vault_hostname

  vnet_name      = module.virtual_network.vnet_name
  subnet_name    = module.virtual_network.subnet_name
  nsg_name       = module.virtual_network.nsg_name
  dns_zone_name  = azurerm_dns_zone.msdn_sandbox.name
  key_vault_name = module.key_vault.name

  my_ip_addresses = var.authorized_cidrs

  vm_admin_username   = var.vm_admin_username
  vm_admin_public_key = var.vm_admin_public_key
  acme_staging        = "true"

  dns_validation_subscription_id = data.azurerm_client_config.current.subscription_id
  azure_tenant_id                = data.azurerm_client_config.current.tenant_id
  azure_dns_client_id            = var.azure_dns_client_id
  azure_dns_client_secret        = var.azure_dns_client_secret

  storage_account_name       = module.storage_account.name
  storage_account_access_key = module.storage_account.primary_access_key
  azure_files_endpoint       = module.storage_account.files_endpoint
  azure_files_share_name     = module.storage_account.storage_share_name

  tags = local.tags
}