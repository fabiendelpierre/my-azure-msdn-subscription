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

# Delegation to my sandbox DNS zone in AWS Route 53
resource "azurerm_dns_ns_record" "aws_sandbox" {
  name                = "aws"
  zone_name           = azurerm_dns_zone.msdn_sandbox.name
  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  ttl                 = 3600

  records = [
    "ns-1746.awsdns-26.co.uk",
    "ns-920.awsdns-51.net",
    "ns-449.awsdns-56.com",
    "ns-1440.awsdns-52.org.",
  ]

  tags = local.tags
}

resource "azurerm_virtual_network" "msdn_sandbox" {
  name                = "${var.base_name}-vnet"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  address_space       = [var.vnet_cidr]

  tags = local.tags
}

resource "azurerm_subnet" "msdn_sandbox1" {
  name                 = "${var.base_name}-vnet-subnet1"
  resource_group_name  = azurerm_resource_group.msdn_sandbox.name
  virtual_network_name = azurerm_virtual_network.msdn_sandbox.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 2, 0)]

  service_endpoints = [
    "Microsoft.AzureActiveDirectory",
    "Microsoft.ContainerRegistry",
    "Microsoft.KeyVault",
    "Microsoft.Storage",
  ]
}

resource "azurerm_network_security_group" "msdn_sandbox1" {
  name                = "${azurerm_subnet.msdn_sandbox1.name}-nsg"
  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  location            = var.azure_region

  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "msdn_sandbox1" {
  subnet_id                 = azurerm_subnet.msdn_sandbox1.id
  network_security_group_id = azurerm_network_security_group.msdn_sandbox1.id
}

resource "azurerm_network_security_group" "test" {
  name                = "${azurerm_subnet.msdn_sandbox1.name}-nsg-test"
  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  location            = var.azure_region

  tags = local.tags
}

# module "key_vault" {
#   source  = "app.terraform.io/fabiend/keyvault/azurerm"
#   version = "0.2.1"

#   base_name = var.base_name

#   resource_group_name = azurerm_resource_group.msdn_sandbox.name
#   location            = var.azure_region
#   authorized_entities = var.authorized_entities

#   tags = local.tags
# }

# module "storage_account" {
#   source  = "app.terraform.io/fabiend/storageaccount/azurerm"
#   version = "0.4.0"

#   resource_group_name = azurerm_resource_group.msdn_sandbox.name
#   location            = var.azure_region
#   base_name           = var.base_name

#   tags = local.tags
# }

# module "vault_vm" {
#   source  = "app.terraform.io/fabiend/hashicorpvault/azurerm"
#   version = "0.1.2"

#   base_name = var.base_name

#   resource_group_name = azurerm_resource_group.msdn_sandbox.name
#   location            = var.azure_region

#   vault_version  = var.vault_version
#   vault_hostname = var.vault_hostname

#   vnet_name      = module.virtual_network.vnet_name
#   subnet_name    = module.virtual_network.subnet_name
#   nsg_name       = module.virtual_network.nsg_name
#   dns_zone_name  = azurerm_dns_zone.msdn_sandbox.name
#   key_vault_name = module.key_vault.name

#   my_ip_addresses = var.authorized_cidrs

#   vm_admin_username   = var.vm_admin_username
#   vm_admin_public_key = var.vm_admin_public_key
#   acme_staging        = "false"

#   dns_validation_subscription_id = data.azurerm_client_config.current.subscription_id
#   azure_tenant_id                = data.azurerm_client_config.current.tenant_id
#   azure_dns_client_id            = var.azure_dns_client_id
#   azure_dns_client_secret        = var.azure_dns_client_secret

#   tags = local.tags
# }
