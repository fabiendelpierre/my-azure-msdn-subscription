resource "azurerm_virtual_network" "msdn" {
  name                = "${var.base_name}-vnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]

  tags = var.tags
}

resource "azurerm_subnet" "msdn1" {
  name                  = "${var.base_name}-vnet-subnet1"
  resource_group_name   = data.azurerm_resource_group.rg.name
  virtual_network_name  = azurerm_virtual_network.msdn.name
  address_prefixes      = [cidrsubnet(var.vnet_cidr, 2, 0)]
  service_endpoints     = [
    "Microsoft.AzureActiveDirectory",
    "Microsoft.ContainerRegistry",
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.Storage",
  ]
}