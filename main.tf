resource "azurerm_resource_group" "msdn_sandbox" {
  name      = "${var.base_name}-rg"
  location  = var.azure_region

  tags = local.tags
}

resource "azurerm_dns_zone" "msdn_sandbox" {
  name                = var.sandbox_domain_name
  resource_group_name = azurerm_resource_group.msdn_sandbox.name

  tags = local.tags
}

module "virtual_network" {
  source  = "app.terraform.io/fabiend/virtualnetwork/azurerm"
  version = "0.2.0"

  base_name = var.base_name

  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  location            = var.azure_region

  vnet_cidr = var.vnet_cidr

  tags = local.tags
}